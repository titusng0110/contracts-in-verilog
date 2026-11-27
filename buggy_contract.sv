// ============================================================================
// File:        buggy_contract.sv
// Author:      Titus Ng (Ng Tsz Hin)
// Description: Pure Modular SaaS Agreement with Full Hohfeldian Rights/Duties Interface
// Assumptions: All clauses are facially valid and enforceable under General Contract Law.
// Target:      Formal Verification (SymbiYosys / Yosys SMTBMC)
// Architecture: Synchronous Discrete-Time Operationalized Nomodynamics
//               (No Runtime Reset: Contracts cannot be rebooted. Formation is S_0 at t=0.)
// ============================================================================

`default_nettype none

// ============================================================================
// PUBLIC LEGAL STANDING ENUMERATION
// ============================================================================
typedef enum logic [1:0] {
    STATE_ACTIVE         = 2'b00,
    STATE_DEFAULT_NOTICE = 2'b01,
    STATE_TERMINATED     = 2'b10
} ContractStates;

// ============================================================================
// FORMAL VERIFICATION EXPERIMENT TOGGLES:
// ============================================================================
// 1. Uncomment to apply the substantive Clause 5.4 Habitual Defaulter rule:
`define CLAUSE_5_4_PATCH_HABITUAL_DEFAULT_LOOPHOLE

// 2. Uncomment to demonstrate the classic drafting error of forgetting
//    the cross-referencing "Subject to Clause 5.4" in Clauses 3.1 and 4.2!
//    (Watch SymbiYosys catch the cross-clause collision at Step 17):
`define FORGOT_SUBJECT_TO_CLAUSE_5_4


module buggy_contract #(
    parameter int unsigned BILLING_CYCLE_DAYS = 4, // Scaled down for rapid bounded verification
    parameter int unsigned CURE_WINDOW_DAYS   = 2  // Scaled down grace period
)(
    // Clock represents the inexorable progression of calendar days.
    // Notice: NO rst_n pin. Parties cannot unilaterally reboot an executed contract.
    input  logic          clk_day,

    // ========================================================================
    // PARTY INPUT ACTIONS (Manifestation of Will / Evidentiary Facts - Sein)
    // ========================================================================
    input  logic          fact_client_pays_on_due_date,
    input  logic          fact_provider_issues_default_notice,
    input  logic          fact_client_cures_default,
    input  logic          fact_provider_attempts_termination,

    // ========================================================================
    // COMPLETE BILL OF RIGHTS & OBLIGATIONS (Hohfeldian Interface - Sollen)
    // ========================================================================
    // Overall Public Legal Standing (Observable by Registry / Courts / Escrow)
    output ContractStates contract_state,

    // Clause 1: Periodic Payment Duties & Default Status
    output logic          c1_client_DUTY_to_pay,
    output logic          c1_fact_payment_default_active,

    // Clause 2: Default Notice Powers & Status
    output logic          c2_provider_POWER_to_serve_default_notice,
    output logic          c2_in_default_notice_status,

    // Clause 3: Cure Rights, Timers & Chronic Breach Record
    output logic          c3_client_POWER_to_cure,
    output logic [7:0]    c3_days_left_in_cure_period,
    `ifdef CLAUSE_5_4_PATCH_HABITUAL_DEFAULT_LOOPHOLE
    output logic [7:0]    c3_consecutive_default_count,
    `endif

    // Clause 4: Rectification Waivers & Restitution Entitlements
    output logic          c4_fact_default_waived,
    output logic          c4_client_CLAIM_to_active_reinstatement,

    // Clause 5: Termination Powers & Unlawful Termination Prohibitions
    output logic          c5_provider_POWER_to_terminate,
    output logic          c5_client_IMMUNITY_from_termination
);

    // Independent transition triggers owned exclusively by individual clauses
    logic c2_provider_tryto_serve_default_notice;
    logic c4_client_tryto_reinstate_to_active;
    logic c5_provider_tryto_terminate;

    // ========================================================================
    // CONTRACT FORMATION & EXECUTION (Initial Legal State S_0 at Inception)
    // ========================================================================
    // Jurisprudential Principle: Mutual Assent and Consideration bind the parties
    // at t=0 (The Effective Date). Sequential state elements are initialized once
    // at the origin of legal time.
    initial begin
        contract_state               = STATE_ACTIVE;
        cycle_day_counter            = 8'd0;
        c3_days_left_in_cure_period  = 8'd0;
        `ifdef CLAUSE_5_4_PATCH_HABITUAL_DEFAULT_LOOPHOLE
        c3_consecutive_default_count = 8'd0;
        `endif
    end

    `ifdef FORMAL
        // Temporal Invariant Harness: Guards $past() operators on the initial execution cycle
        reg f_past_valid = 1'b0;
        always_ff @(posedge clk_day) begin
            f_past_valid <= 1'b1;
        end

        // Legal Environment Assumptions (The "Reasonable Party" Framework)
        always_ff @(posedge clk_day) begin
            if (f_past_valid) begin
                // 1. Doctrine of Election: Cannot issue notice and demand termination simultaneously.
                assume (!(fact_provider_issues_default_notice && fact_provider_attempts_termination));

                // 2. Doctrine of Wrongful Notice: Notice requires an actual payment default.
                assume (!fact_provider_issues_default_notice || c1_fact_payment_default_active);

                // 3. Performance Consistency: Cannot pay on time and cure default on the same day.
                assume (!(fact_client_pays_on_due_date && fact_client_cures_default));

                // 4. Relevance of Cure: A cure payment is only tendered while default notice is active.
                assume (!fact_client_cures_default || (contract_state == STATE_DEFAULT_NOTICE));

                // 5. Functus Officio: Once terminated, contractual actions cease.
                if (contract_state == STATE_TERMINATED) begin
                    assume (!fact_client_pays_on_due_date);
                    assume (!fact_provider_issues_default_notice);
                    assume (!fact_client_cures_default);
                    assume (!fact_provider_attempts_termination);
                end
            end
        end
    `endif


    // ========================================================================
    // CLAUSE 1: PERIODIC PAYMENT OBLIGATION AND PAYMENT DUE DATE
    // ========================================================================
    // [Legal Clause Text]:
    // 1.1 The Client shall pay the recurring service fee on the final calendar
    //     day of each recurring billing cycle (BILLING_CYCLE_DAYS).
    // 1.2 Failure by the Client to remit payment on the designated due date
    //     shall constitute an automatic Payment Default under this Agreement.
    // ------------------------------------------------------------------------

    // --- SystemVerilog Logic: Clause 1 ---
    logic [7:0] cycle_day_counter;
    logic       payment_due_today;

    // [Implements Subclause 1.1]: Tracks billing cycle; asserts due date on the final day
    assign payment_due_today = (cycle_day_counter == (BILLING_CYCLE_DAYS - 1));

    always_ff @(posedge clk_day) begin
        if (contract_state == STATE_ACTIVE) begin
            if (cycle_day_counter >= (BILLING_CYCLE_DAYS - 1)) begin
                cycle_day_counter <= 8'd0;
            end else begin
                cycle_day_counter <= cycle_day_counter + 1'b1;
            end
        end
    end

    // [Exposes Pin]: The Client's affirmative duty to pay is active today
    assign c1_client_DUTY_to_pay = (contract_state == STATE_ACTIVE) && payment_due_today;

    // [Implements Subclause 1.2]: Non-payment on due date triggers payment default directly on output pin
    always_comb begin
        c1_fact_payment_default_active = 1'b0;
        if (c1_client_DUTY_to_pay && !fact_client_pays_on_due_date) begin
            c1_fact_payment_default_active = 1'b1;
        end
    end

    // --- Theorem Assertions: Clause 1 ---
    `ifdef FORMAL
        always_ff @(posedge clk_day) begin
            if (f_past_valid) begin

                // THEOREM 1.1 (Points to Subclause 1.1):
                // Timely remittance on the due date strictly satisfies the payment duty
                // and prevents the occurrence of an active Payment Default.
                if ($past(c1_client_DUTY_to_pay) && $past(fact_client_pays_on_due_date)) begin
                    assert (!$past(c1_fact_payment_default_active));
                end

                // THEOREM 1.2 (Points to Subclause 1.2):
                // Failure to remit when duty is active strictly asserts Payment Default.
                if ($past(c1_client_DUTY_to_pay) && !$past(fact_client_pays_on_due_date)) begin
                    assert ($past(c1_fact_payment_default_active));
                end

            end
        end
    `endif


    // ========================================================================
    // CLAUSE 2: NOTICE OF DEFAULT AND GRACE PERIOD INITIATION
    // ========================================================================
    // [Legal Clause Text]:
    // 2.1 In the event of a Payment Default, the Provider shall provide formal
    //     written notice of default to the Client (fact_provider_issues_default_notice).
    // 2.2 Issuance of written notice initiates a mandatory Grace Period of
    //     CURE_WINDOW_DAYS, transitioning the contract into Default Notice status.
    // ------------------------------------------------------------------------

    // --- SystemVerilog Logic: Clause 2 ---
    logic clause_3_decrements_cure_timer; // Driven by Clause 3.2 logic below

    // [Exposes Pin]: Provider legally possesses the power to issue notice upon active default
    assign c2_provider_POWER_to_serve_default_notice = (contract_state == STATE_ACTIVE) &&
                                                       c1_fact_payment_default_active;

    // [Implements Subclause 2.1]: Exclusive trigger initiating transition to Default Notice
    assign c2_provider_tryto_serve_default_notice = c2_provider_POWER_to_serve_default_notice &&
                                                   fact_provider_issues_default_notice;

    // [Exposes Pin]: Contractual status in Default Notice
    assign c2_in_default_notice_status = (contract_state == STATE_DEFAULT_NOTICE);

    // [Implements Subclause 2.2]: Directly drives Grace Period output register
    always_ff @(posedge clk_day) begin
        if (c2_provider_tryto_serve_default_notice) begin
            // [Subclause 2.2 Mandate]: Initiates Grace Period of CURE_WINDOW_DAYS
            c3_days_left_in_cure_period <= CURE_WINDOW_DAYS[7:0];
        end else if (clause_3_decrements_cure_timer) begin
            // Controlled strictly by Clause 3.2 logic below
            c3_days_left_in_cure_period <= c3_days_left_in_cure_period - 1'b1;
        end
    end

    // --- Theorem Assertions: Clause 2 ---
    `ifdef FORMAL
        always_ff @(posedge clk_day) begin
            if (f_past_valid) begin

                // THEOREM 2.1 (Points to Subclause 2.1):
                // Exercise of notice power initiates transition to Default Notice status.
                if ($past(c2_provider_tryto_serve_default_notice)) begin
                    assert (contract_state == STATE_DEFAULT_NOTICE);
                end

                // THEOREM 2.2 (Points to Subclause 2.2):
                // Entry into Default Notice strictly initializes Grace Period to CURE_WINDOW_DAYS.
                if ($past(contract_state == STATE_ACTIVE) && (contract_state == STATE_DEFAULT_NOTICE)) begin
                    assert (c3_days_left_in_cure_period == CURE_WINDOW_DAYS[7:0]);
                    assert (c2_in_default_notice_status);
                end

            end
        end
    `endif


    // ========================================================================
    // CLAUSE 3: RIGHT TO CURE AND CHRONIC DEFAULT TRACKING
    // ========================================================================
    // [Legal Clause Text]:
    // 3.1 The Client retains the contractual right to cure any Payment Default
    //     by remitting the outstanding sum prior to the expiration of the Grace
    //     Period (fact_client_cures_default), [provided that the Provider does not
    //     possess an overriding right of termination under Clause 5.]
    // 3.2 The remaining Grace Period shall decrement by one calendar day for
    //     each day served in Default Notice status.
    // 3.3 [INTRODUCED ONLY IN DRAFTING PATCH]: The occurrence of each default notice
    //     served shall be cumulatively tracked (consecutive_default_count).
    // ------------------------------------------------------------------------

    // --- SystemVerilog Logic: Subclause 3.1 ---
    logic clause_3_client_tenders_timely_cure;
    logic clause_3_valid_cure_tendered;

    // [Implements Subclause 3.1 - Factual Tender]:
    // Asserts when the Client actually sends cure payment while the Grace Period is running.
    assign clause_3_client_tenders_timely_cure = (contract_state == STATE_DEFAULT_NOTICE) &&
                                                 fact_client_cures_default &&
                                                 (c3_days_left_in_cure_period > 8'd0);

    // [Implements Subclause 3.1 - Legal Entitlement]:
    // The Client has the legal right to cure while in default notice, timer is alive,
    // AND provided the Provider does not possess an overriding right to terminate!
    `ifdef CLAUSE_5_4_PATCH_HABITUAL_DEFAULT_LOOPHOLE
        `ifdef FORGOT_SUBJECT_TO_CLAUSE_5_4
            // DRAFTING MALPRACTICE: Lawyer forgot the Clause 5 proviso!
            assign c3_client_POWER_to_cure = (contract_state == STATE_DEFAULT_NOTICE) && (c3_days_left_in_cure_period > 8'd0);
        `else
            // DRAFTING RIGOR: Subordinated to Clause 5 termination right
            assign c3_client_POWER_to_cure = (contract_state == STATE_DEFAULT_NOTICE) &&
                                             (c3_days_left_in_cure_period > 8'd0) &&
                                             !c5_provider_POWER_to_terminate;
        `endif
    `else
        // Unpatched naive boilerplate: no concept of Clause 5 overriding the cure right
        assign c3_client_POWER_to_cure = (contract_state == STATE_DEFAULT_NOTICE) && (c3_days_left_in_cure_period > 8'd0);
    `endif

    // [Implements Subclause 3.1 - Effective Legal Cure]:
    // A cure is legally valid only if the Client possessed the legal right to cure!
    assign clause_3_valid_cure_tendered = c3_client_POWER_to_cure && fact_client_cures_default;

    // [Implements Subclause 3.2]: Control signal commanding daily Grace Period countdown
    assign clause_3_decrements_cure_timer = (contract_state == STATE_DEFAULT_NOTICE) && (c3_days_left_in_cure_period > 8'd0);

    // [Implements Subclause 3.3]: ONLY exists when the drafting patch is active!
    `ifdef CLAUSE_5_4_PATCH_HABITUAL_DEFAULT_LOOPHOLE
        always_ff @(posedge clk_day) begin
            if (c2_provider_tryto_serve_default_notice) begin
                c3_consecutive_default_count <= c3_consecutive_default_count + 1'b1;
            end
        end
    `else
        // In the unpatched contract, Subclause 3.3 literally does not exist.
    `endif

    // --- Theorem Assertions: Clause 3 ---
    `ifdef FORMAL
        always_ff @(posedge clk_day) begin
            if (f_past_valid) begin

                // THEOREM 3.1 (Points to Subclause 3.1):
                // Tendering cure while cure right is active strictly asserts valid cure event.
                if (c3_client_POWER_to_cure && fact_client_cures_default) begin
                    assert (clause_3_valid_cure_tendered);
                end

                // THEOREM 3.2 (Points to Subclause 3.2):
                // Grace Period counter strictly decrements by 1 each day while remaining in default notice.
                if ($past(contract_state == STATE_DEFAULT_NOTICE) && (contract_state == STATE_DEFAULT_NOTICE) && ($past(c3_days_left_in_cure_period) > 8'd0)) begin
                    assert (c3_days_left_in_cure_period == ($past(c3_days_left_in_cure_period) - 1'b1));
                end

                `ifdef CLAUSE_5_4_PATCH_HABITUAL_DEFAULT_LOOPHOLE
                    // THEOREM 3.3 (Points to Subclause 3.3):
                    // When the patch is active, default record strictly increments by 1 on each notice.
                    if ($past(c2_provider_tryto_serve_default_notice)) begin
                        assert (c3_consecutive_default_count == ($past(c3_consecutive_default_count) + 1'b1));
                    end
                `endif

            end
        end
    `endif


    // ========================================================================
    // CLAUSE 4: EFFECT OF FULL CURE AND RESTITUTION
    // ========================================================================
    // [Legal Clause Text]:
    // 4.1 Upon receipt of the cure payment prior to the expiration of the Grace
    //     Period, the Payment Default shall be deemed fully cured, waived, and rectified
    //     (c4_fact_default_waived).
    // 4.2 [Subject to Clause 5 (Termination),] the contract shall immediately return
    //     to Active status, and the parties shall resume performance as if no default had occurred
    //     (c4_client_CLAIM_to_active_reinstatement).
    // ------------------------------------------------------------------------

    // --- SystemVerilog Logic: Clause 4 ---

    // [Implements Subclause 4.1]: Legal waiver and rectification of the default event
    assign c4_fact_default_waived = clause_3_valid_cure_tendered;

    // [Implements Subclause 4.2]: Entitlement to Active status is SUBJECT TO Clause 5!
    `ifdef CLAUSE_5_4_PATCH_HABITUAL_DEFAULT_LOOPHOLE
        `ifdef FORGOT_SUBJECT_TO_CLAUSE_5_4
            // --- DRAFTING MALPRACTICE (BUG INJECTED) ---
            // Lawyer forgot "Subject to Clause 5" in 4.2!
            // Blindly grants Active restitution even when Clause 5 is terminating!
            assign c4_client_CLAIM_to_active_reinstatement = c4_fact_default_waived;
        `else
            // --- DRAFTING RIGOR: SUBJECT TO CLAUSE 5 ---
            // Properly subordinated: Restitution granted ONLY IF Clause 5 termination is NOT active!
            assign c4_client_CLAIM_to_active_reinstatement = c4_fact_default_waived &&
                                                             !c5_provider_POWER_to_terminate;
        `endif
    `else
        // Unpatched naive boilerplate: no concept of Clause 5 overriding restitution
        assign c4_client_CLAIM_to_active_reinstatement = c4_fact_default_waived;
    `endif

    // [Trigger to State Arbiter]: Requests physical transition to STATE_ACTIVE
    assign c4_client_tryto_reinstate_to_active = c4_client_CLAIM_to_active_reinstatement;


    // --- Theorem Assertions: Clause 4 ---
    `ifdef FORMAL
        always_ff @(posedge clk_day) begin
            if (f_past_valid) begin

                // THEOREM 4.1 (Points to Subclause 4.1):
                // Legal rectification strictly extinguishes Default Notice standing on next day.
                if ($past(c4_fact_default_waived)) begin
                    assert (!c2_in_default_notice_status);
                end

                // THEOREM 4.2 (Points to Subclause 4.2):
                // Valid entitlement to restitution strictly guarantees restoration of Active standing!
                if ($past(c4_client_CLAIM_to_active_reinstatement)) begin
                    assert (contract_state == STATE_ACTIVE);
                end

            end
        end
    `endif


    // ========================================================================
    // CLAUSE 5: CONDITIONS PRECEDENT FOR PROVIDER TERMINATION
    // ========================================================================
    // [Legal Clause Text]:
    // 5.1 Subject to Clause 5.4, this Agreement shall automatically terminate
    //     upon the absolute expiration of the Grace Period without cure (cure_timer reaches 0).
    // 5.2 Any unilateral termination attempted by the Provider while the contract
    //     is in Active status is strictly void, prohibited, and rejected,
    //     except as expressly provided under Clause 5.4.
    // 5.3 Any unilateral termination attempted by the Provider while a cure is
    //     actively pending in the Grace Period (cure_timer > 0) is strictly void,
    //     prohibited, and rejected, except as expressly provided under Clause 5.4.
    // 5.4 [THE PATCH]: Notwithstanding Clauses 4.1, 4.2, 5.1, 5.2, and 5.3, if the Client
    //     accumulates three (3) or more Payment Defaults (consecutive_default_count >= 3),
    //     the Client's right to cure shall be permanently extinguished, and the Provider
    //     shall have the absolute right to terminate this Agreement immediately
    //     upon demand (fact_provider_attempts_termination).
    // ------------------------------------------------------------------------

    // --- SystemVerilog Logic: Clause 5 ---
    always_comb begin
        c5_provider_POWER_to_terminate      = 1'b0;
        c5_client_IMMUNITY_from_termination = 1'b0;

        `ifdef CLAUSE_5_4_PATCH_HABITUAL_DEFAULT_LOOPHOLE
            // [Implements Subclause 5.4]:
            if (c3_consecutive_default_count >= 8'd3) begin
                c5_provider_POWER_to_terminate = 1'b1;
            end else begin
                // [Implements Subclause 5.2]:
                if (contract_state == STATE_ACTIVE) begin
                    c5_client_IMMUNITY_from_termination = 1'b1;
                end

                // [Implements Subclause 5.3]:
                if ((contract_state == STATE_DEFAULT_NOTICE) && (c3_days_left_in_cure_period > 8'd0)) begin
                    c5_client_IMMUNITY_from_termination = 1'b1;
                end

                // [Implements Subclause 5.1]:
                if ((contract_state == STATE_DEFAULT_NOTICE) && (c3_days_left_in_cure_period == 8'd0)) begin
                    c5_provider_POWER_to_terminate = 1'b1;
                end
            end
        `else
            // [Implements Subclause 5.2 (Unpatched Boilerplate)]:
            if (contract_state == STATE_ACTIVE) begin
                c5_client_IMMUNITY_from_termination = 1'b1;
            end

            // [Implements Subclause 5.3 (Unpatched Boilerplate)]:
            if ((contract_state == STATE_DEFAULT_NOTICE) && (c3_days_left_in_cure_period > 8'd0)) begin
                c5_client_IMMUNITY_from_termination = 1'b1;
            end

            // [Implements Subclause 5.1 (Unpatched Boilerplate)]:
            if ((contract_state == STATE_DEFAULT_NOTICE) && (c3_days_left_in_cure_period == 8'd0)) begin
                c5_provider_POWER_to_terminate = 1'b1;
            end
        `endif
    end

    // [Implements Subclause 5.1 (Automatic) & Subclause 5.4 (Elective) Termination Triggers]:
    assign c5_provider_tryto_terminate =
        ((contract_state == STATE_DEFAULT_NOTICE) && (c3_days_left_in_cure_period == 8'd0))
        `ifdef CLAUSE_5_4_PATCH_HABITUAL_DEFAULT_LOOPHOLE
        || (c5_provider_POWER_to_terminate && fact_provider_attempts_termination)
        `endif
        ;


    // --- Theorem Assertions: Clause 5 ---
    `ifdef FORMAL
        always_ff @(posedge clk_day) begin
            if (f_past_valid) begin

                // THEOREM 5.1 (Points to Subclause 5.1):
                if ($past(contract_state == STATE_DEFAULT_NOTICE) && ($past(c3_days_left_in_cure_period) == 8'd0)) begin
                    assert ($past(c5_provider_POWER_to_terminate));
                    assert (contract_state == STATE_TERMINATED);
                end

                // THEOREM 5.2 (Points to Subclause 5.2):
                `ifdef CLAUSE_5_4_PATCH_HABITUAL_DEFAULT_LOOPHOLE
                if ($past(contract_state == STATE_ACTIVE) && ($past(c3_consecutive_default_count) < 8'd3)) begin
                    assert ($past(c5_client_IMMUNITY_from_termination));
                    assert (!$past(c5_provider_POWER_to_terminate));
                end
                `else
                if ($past(contract_state == STATE_ACTIVE)) begin
                    assert ($past(c5_client_IMMUNITY_from_termination));
                    assert (!$past(c5_provider_POWER_to_terminate));
                end
                `endif

                // THEOREM 5.3 (Points to Subclause 5.3):
                `ifdef CLAUSE_5_4_PATCH_HABITUAL_DEFAULT_LOOPHOLE
                if ($past(contract_state == STATE_DEFAULT_NOTICE) &&
                    ($past(c3_consecutive_default_count) < 8'd3) &&
                    ($past(c3_days_left_in_cure_period) > 8'd0)) begin
                    assert ($past(c5_client_IMMUNITY_from_termination));
                    assert (!$past(c5_provider_POWER_to_terminate));
                end
                `else
                if ($past(contract_state == STATE_DEFAULT_NOTICE) &&
                    ($past(c3_days_left_in_cure_period) > 8'd0)) begin
                    assert ($past(c5_client_IMMUNITY_from_termination));
                    assert (!$past(c5_provider_POWER_to_terminate));
                end
                `endif

                `ifdef CLAUSE_5_4_PATCH_HABITUAL_DEFAULT_LOOPHOLE
                    // THEOREM 5.4 (Points to Subclause 5.4):
                    if ($past(c3_consecutive_default_count >= 8'd3)) begin
                        assert ($past(c5_provider_POWER_to_terminate));
                        assert (!$past(c5_client_IMMUNITY_from_termination));
                    end
                `endif

            end
        end
    `endif


    // ========================================================================
    // PRIMARY STATE ARBITER (Neutral Execution Core)
    // Synchronous 1-Process State Machine driving output register directly
    // ========================================================================
    always_ff @(posedge clk_day) begin
        case (contract_state)
            STATE_ACTIVE: begin
                if (c5_provider_tryto_terminate) begin
                    contract_state <= STATE_TERMINATED;
                end else if (c2_provider_tryto_serve_default_notice) begin
                    contract_state <= STATE_DEFAULT_NOTICE;
                end
            end

            STATE_DEFAULT_NOTICE: begin
                if (c5_provider_tryto_terminate) begin
                    contract_state <= STATE_TERMINATED;
                end else if (c4_client_tryto_reinstate_to_active) begin
                    contract_state <= STATE_ACTIVE;
                end
            end

            STATE_TERMINATED: begin
                contract_state <= STATE_TERMINATED; // Absorbing sink state
            end

            default: contract_state <= STATE_ACTIVE;
        endcase
    end


    // ========================================================================
    // BILATERAL COMMERCIAL AUDIT SUITE (Pure Jurisprudential Verification)
    // ========================================================================
    `ifdef FORMAL
        always_ff @(posedge clk_day) begin
            if (f_past_valid) begin

                // ============================================================
                // PART 1: MANDATORY DUE PROCESS & FAIRNESS ASSERTS (The Rules)
                // ============================================================

                // ASSERT 1 (Borrower Due Process - No Peacetime Ambush):
                // "The Lender CANNOT have the right to terminate while the contract
                //  is in Active good standing!"
                `ifdef CLAUSE_5_4_PATCH_HABITUAL_DEFAULT_LOOPHOLE
                if ((contract_state == STATE_ACTIVE) && (c3_consecutive_default_count < 8'd3)) begin
                    assert (!c5_provider_POWER_to_terminate);
                    assert (c5_client_IMMUNITY_from_termination);
                end
                `else
                if (contract_state == STATE_ACTIVE) begin
                    assert (!c5_provider_POWER_to_terminate);
                    assert (c5_client_IMMUNITY_from_termination);
                end
                `endif

                // ASSERT 2 (Borrower Sacred Grace - Mutual Exclusivity):
                // "If the Borrower has the legal right to cure, the Lender
                //  CANNOT simultaneously have the legal right to terminate!"
                if (c3_client_POWER_to_cure) begin
                    assert (!c5_provider_POWER_to_terminate);
                    assert (c5_client_IMMUNITY_from_termination);
                end

                // ASSERT 3 (Borrower Performance Immunity):
                // "Timely payment on the due date strictly guarantees no default."
                if ($past(c1_client_DUTY_to_pay) && $past(fact_client_pays_on_due_date)) begin
                    assert (!$past(c1_fact_payment_default_active));
                end

                // ASSERT 4 (Lender Remedy Certainty - Timer Expiry):
                // "When the grace period expires without cure, the Lender MUST have the right to terminate."
                if (c2_in_default_notice_status && (c3_days_left_in_cure_period == 8'd0)) begin
                    assert (c5_provider_POWER_to_terminate);
                end

                // ASSERT 5 (Borrower Finality - Non-Resurrection):
                // "Once Terminated, the contract is dead and can never resurrect."
                if ($past(contract_state == STATE_TERMINATED)) begin
                    assert (contract_state == STATE_TERMINATED);
                    assert (contract_state != STATE_ACTIVE);
                    assert (!c2_in_default_notice_status);
                end


                // ============================================================
                // PART 2: REAL TRANSACTIONAL PATHWAYS (The "Covers")
                // ============================================================

                // SCENARIO 1 (The Primary Commercial Bargain):
                // "Can both parties perform on the due date peacefully and stay in good standing?"
                cover (
                    (contract_state == STATE_ACTIVE) &&
                    $past(c1_client_DUTY_to_pay) &&
                    $past(fact_client_pays_on_due_date)
                );

                // SCENARIO 2 (The Borrower's Due Process Pathway):
                // "Can a Client who defaulted successfully cure and restore the contract to Active?"
                cover (
                    c2_in_default_notice_status &&
                    fact_client_cures_default &&
                    c4_client_CLAIM_to_active_reinstatement
                );

                // SCENARIO 3 (The Unilateral Termination Test):
                // "If the Client tenders a TIMELY cure, can the Provider
                //  reject the cure and TERMINATE anyway?"
                cover (
                    $past(clause_3_client_tenders_timely_cure) &&
                    $past(fact_provider_attempts_termination) &&
                    (contract_state == STATE_TERMINATED)
                );

            end
        end
    `endif

endmodule
`default_nettype wire
