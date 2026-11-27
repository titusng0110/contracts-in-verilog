// ============================================================================
// File:        buggy_contract.sv
// Author:      Titus Ng (Ng Tsz Hin)
// Description: Pure Modular SaaS Agreement with Full Hohfeldian Rights/Duties Interface
// Assumptions: All clauses are facially valid and enforceable under General Contract Law.
// Target:      Formal Verification (SymbiYosys / Yosys SMTBMC)
// ============================================================================

`default_nettype none

// ============================================================================
// FORMAL VERIFICATION EXPERIMENT TOGGLES:
// ============================================================================
// 1. Uncomment to apply the substantive Clause 5.4 Habitual Defaulter rule:
`define CLAUSE_5_4_PATCH_HABITUAL_DEFAULT_LOOPHOLE

// 2. Uncomment to demonstrate the classic drafting error of forgetting
//    the cross-referencing "Subject to Clause 5.4" in Clauses 3.1 and 4.2!
//    (Watch SymbiYosys catch the cross-clause collision at Step 17):
// `define FORGOT_SUBJECT_TO_CLAUSE_5_4


module buggy_contract #(
    parameter int unsigned BILLING_CYCLE_DAYS = 4, // Scaled down for rapid bounded verification
    parameter int unsigned CURE_WINDOW_DAYS   = 2  // Scaled down grace period
)(
    input  logic       clk_day,
    input  logic       rst_n,

    // ========================================================================
    // PARTY INPUT ACTIONS
    // ========================================================================
    input  logic       client_pays_on_due_date,
    input  logic       provider_issues_default_notice,
    input  logic       client_cures_default,
    input  logic       provider_attempts_termination,

    // ========================================================================
    // COMPLETE BILL OF RIGHTS & OBLIGATIONS (Clause-Specific Output Pins)
    // ========================================================================
    // Overall Contractual Standing
    output logic       contract_is_active,
    output logic       contract_is_terminated,

    // Clause 1: Periodic Payment Duties & Default Status
    output logic       clause_1_client_duty_to_pay_today,
    output logic       clause_1_payment_default_active,

    // Clause 2: Default Notice Powers & Status
    output logic       clause_2_provider_right_to_issue_notice,
    output logic       clause_2_in_default_notice_status,

    // Clause 3: Cure Rights, Timers & Chronic Breach Record
    output logic       clause_3_client_right_to_cure,
    output logic [7:0] clause_3_days_left_in_cure_period,
    output logic [7:0] clause_3_consecutive_default_count,

    // Clause 4: Rectification Waivers & Restitution Entitlements
    output logic       clause_4_payment_default_waived,
    output logic       clause_4_client_entitled_to_active_restitution,

    // Clause 5: Termination Powers & Unlawful Termination Prohibitions
    output logic       clause_5_provider_right_to_terminate,
    output logic       clause_5_provider_termination_prohibited
);

    // ------------------------------------------------------------------------
    // PRELIMINARY: Finite State Space & Formal Environment Setup
    // ------------------------------------------------------------------------
    typedef enum logic [1:0] {
        STATE_ACTIVE         = 2'b00,
        STATE_DEFAULT_NOTICE = 2'b01,
        STATE_TERMINATED     = 2'b10
    } contract_state_e;

    contract_state_e state      = STATE_ACTIVE;
    contract_state_e next_state = STATE_ACTIVE;

    // Independent transition triggers owned exclusively by individual clauses
    logic clause_2_initiates_default_notice;
    logic clause_4_restitutes_to_active;
    logic clause_5_initiates_termination;

    `ifdef FORMAL
        // Clocked reset harness: enforces reset at cycle 0, released at cycle 1
        reg f_past_valid = 1'b0;
        always_ff @(posedge clk_day) begin
            f_past_valid <= 1'b1;
            if (!f_past_valid) begin
                assume (!rst_n);
            end else begin
                assume (rst_n);
            end
        end

        // Legal Environment Assumptions (The "Reasonable Party" Framework)
        always_ff @(posedge clk_day) begin
            if (rst_n && f_past_valid) begin
                // 1. Doctrine of Election: Cannot issue notice and demand termination simultaneously.
                assume (!(provider_issues_default_notice && provider_attempts_termination));

                // 2. Doctrine of Wrongful Notice: Notice requires an actual payment default.
                assume (!provider_issues_default_notice || clause_1_payment_default_active);

                // 3. Performance Consistency: Cannot pay on time and cure default on the same day.
                assume (!(client_pays_on_due_date && client_cures_default));

                // In the Legal Environment Assumptions (Line 84):
                // 4. Relevance of Cure: A cure payment is only tendered while default notice is active.
                assume (!client_cures_default || (state == STATE_DEFAULT_NOTICE));

                // 5. Functus Officio: Once terminated, contractual actions cease.
                if (state == STATE_TERMINATED) begin
                    assume (!client_pays_on_due_date);
                    assume (!provider_issues_default_notice);
                    assume (!client_cures_default);
                    assume (!provider_attempts_termination);
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
    logic [7:0] cycle_day_counter = 8'd0;
    logic       payment_due_today;

    // [Implements Subclause 1.1]: Tracks billing cycle; asserts due date on the final day
    assign payment_due_today = (cycle_day_counter == (BILLING_CYCLE_DAYS - 1));

    always_ff @(posedge clk_day or negedge rst_n) begin
        if (!rst_n) begin
            cycle_day_counter <= 8'd0;
        end else if (state == STATE_ACTIVE) begin
            if (cycle_day_counter >= (BILLING_CYCLE_DAYS - 1)) begin
                cycle_day_counter <= 8'd0;
            end else begin
                cycle_day_counter <= cycle_day_counter + 1'b1;
            end
        end
    end

    // [Exposes Pin]: The Client's affirmative duty to pay is active today
    assign clause_1_client_duty_to_pay_today = (state == STATE_ACTIVE) && payment_due_today;

    // [Implements Subclause 1.2]: Non-payment on due date triggers payment default directly on output pin
    always_comb begin
        clause_1_payment_default_active = 1'b0;
        if (clause_1_client_duty_to_pay_today && !client_pays_on_due_date) begin
            clause_1_payment_default_active = 1'b1;
        end
    end

    // --- Theorem Assertions: Clause 1 ---
    `ifdef FORMAL
        always_ff @(posedge clk_day) begin
            if (rst_n && f_past_valid && $past(rst_n)) begin

                // THEOREM 1.1 (Points to Subclause 1.1):
                // Timely remittance on the due date strictly satisfies the payment duty
                // and prevents the occurrence of an active Payment Default.
                if ($past(clause_1_client_duty_to_pay_today) && $past(client_pays_on_due_date)) begin
                    assert (!$past(clause_1_payment_default_active));
                end

                // THEOREM 1.2 (Points to Subclause 1.2):
                // Failure to remit when duty is active strictly asserts Payment Default.
                if ($past(clause_1_client_duty_to_pay_today) && !$past(client_pays_on_due_date)) begin
                    assert ($past(clause_1_payment_default_active));
                end

            end
        end
    `endif


    // ========================================================================
    // CLAUSE 2: NOTICE OF DEFAULT AND GRACE PERIOD INITIATION
    // ========================================================================
    // [Legal Clause Text]:
    // 2.1 In the event of a Payment Default, the Provider shall provide formal
    //     written notice of default to the Client (provider_issues_default_notice).
    // 2.2 Issuance of written notice initiates a mandatory Grace Period of
    //     CURE_WINDOW_DAYS, transitioning the contract into Default Notice status.
    // ------------------------------------------------------------------------

    // --- SystemVerilog Logic: Clause 2 ---
    logic clause_3_decrements_cure_timer; // Driven by Clause 3.2 logic below

    // [Exposes Pin]: Provider legally possesses the power to issue notice upon active default
    assign clause_2_provider_right_to_issue_notice = (state == STATE_ACTIVE) &&
                                                     clause_1_payment_default_active;

    // [Implements Subclause 2.1]: Exclusive trigger initiating transition to Default Notice
    assign clause_2_initiates_default_notice = clause_2_provider_right_to_issue_notice &&
                                               provider_issues_default_notice;

    // [Exposes Pin]: Contractual status in Default Notice
    assign clause_2_in_default_notice_status = (state == STATE_DEFAULT_NOTICE);

    // [Implements Subclause 2.2]: Directly drives Grace Period output register
    always_ff @(posedge clk_day or negedge rst_n) begin
        if (!rst_n) begin
            clause_3_days_left_in_cure_period <= 8'd0;
        end else begin
            if (clause_2_initiates_default_notice) begin
                // [Subclause 2.2 Mandate]: Initiates Grace Period of CURE_WINDOW_DAYS
                clause_3_days_left_in_cure_period <= CURE_WINDOW_DAYS[7:0];
            end else if (clause_3_decrements_cure_timer) begin
                // Controlled strictly by Clause 3.2 logic below
                clause_3_days_left_in_cure_period <= clause_3_days_left_in_cure_period - 1'b1;
            end
        end
    end

    // --- Theorem Assertions: Clause 2 ---
    `ifdef FORMAL
        always_ff @(posedge clk_day) begin
            if (rst_n && f_past_valid && $past(rst_n)) begin

                // THEOREM 2.1 (Points to Subclause 2.1):
                // Exercise of notice power initiates transition to Default Notice status.
                if ($past(clause_2_initiates_default_notice)) begin
                    assert (state == STATE_DEFAULT_NOTICE);
                end

                // THEOREM 2.2 (Points to Subclause 2.2):
                // Entry into Default Notice strictly initializes Grace Period to CURE_WINDOW_DAYS.
                if ($past(state == STATE_ACTIVE) && (state == STATE_DEFAULT_NOTICE)) begin
                    assert (clause_3_days_left_in_cure_period == CURE_WINDOW_DAYS[7:0]);
                    assert (clause_2_in_default_notice_status);
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
    //     Period (client_cures_default), [provided that the Provider does not
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
    // (Notice: cure timer > 0 is baked directly into this wire!).
    assign clause_3_client_tenders_timely_cure = (state == STATE_DEFAULT_NOTICE) &&
                                                 client_cures_default &&
                                                 (clause_3_days_left_in_cure_period > 8'd0);

    // [Implements Subclause 3.1 - Legal Entitlement]:
    // The Client has the legal right to cure while in default notice, timer is alive,
    // AND provided the Provider does not possess an overriding right to terminate!
    `ifdef CLAUSE_5_4_PATCH_HABITUAL_DEFAULT_LOOPHOLE
        `ifdef FORGOT_SUBJECT_TO_CLAUSE_5_4
            // DRAFTING MALPRACTICE: Lawyer forgot the Clause 5 proviso!
            assign clause_3_client_right_to_cure = (state == STATE_DEFAULT_NOTICE) && (clause_3_days_left_in_cure_period > 8'd0);
        `else
            // DRAFTING RIGOR: Subordinated to Clause 5 termination right
            assign clause_3_client_right_to_cure = (state == STATE_DEFAULT_NOTICE) &&
                                                  (clause_3_days_left_in_cure_period > 8'd0) &&
                                                  !clause_5_provider_right_to_terminate;
        `endif
    `else
        // Unpatched naive boilerplate: no concept of Clause 5 overriding the cure right
        assign clause_3_client_right_to_cure = (state == STATE_DEFAULT_NOTICE) && (clause_3_days_left_in_cure_period > 8'd0);
    `endif

    // [Implements Subclause 3.1 - Effective Legal Cure]:
    // A cure is legally valid only if the Client possessed the legal right to cure!
    assign clause_3_valid_cure_tendered = clause_3_client_right_to_cure && client_cures_default;

    // [Implements Subclause 3.2]: Control signal commanding daily Grace Period countdown
    assign clause_3_decrements_cure_timer = (state == STATE_DEFAULT_NOTICE) && (clause_3_days_left_in_cure_period > 8'd0);

    // [Implements Subclause 3.3]: ONLY exists when the drafting patch is active!
    `ifdef CLAUSE_5_4_PATCH_HABITUAL_DEFAULT_LOOPHOLE
        always_ff @(posedge clk_day or negedge rst_n) begin
            if (!rst_n) begin
                clause_3_consecutive_default_count <= 8'd0;
            end else if (clause_2_initiates_default_notice) begin
                clause_3_consecutive_default_count <= clause_3_consecutive_default_count + 1'b1;
            end
        end
    `else
        // In the unpatched contract, Subclause 3.3 literally does not exist.
        assign clause_3_consecutive_default_count = 8'd0;
    `endif

    // --- Theorem Assertions: Clause 3 ---
    `ifdef FORMAL
        always_ff @(posedge clk_day) begin
            if (rst_n && f_past_valid && $past(rst_n)) begin

                // THEOREM 3.1 (Points to Subclause 3.1):
                // Tendering cure while cure right is active strictly asserts valid cure event.
                if (clause_3_client_right_to_cure && client_cures_default) begin
                    assert (clause_3_valid_cure_tendered);
                end

                // THEOREM 3.2 (Points to Subclause 3.2):
                // Grace Period counter strictly decrements by 1 each day while remaining in default notice.
                if ($past(state == STATE_DEFAULT_NOTICE) && (state == STATE_DEFAULT_NOTICE) && ($past(clause_3_days_left_in_cure_period) > 8'd0)) begin
                    assert (clause_3_days_left_in_cure_period == ($past(clause_3_days_left_in_cure_period) - 1'b1));
                end

                `ifdef CLAUSE_5_4_PATCH_HABITUAL_DEFAULT_LOOPHOLE
                    // THEOREM 3.3 (Points to Subclause 3.3):
                    // When the patch is active, default record strictly increments by 1 on each notice.
                    if ($past(clause_2_initiates_default_notice)) begin
                        assert (clause_3_consecutive_default_count == ($past(clause_3_consecutive_default_count) + 1'b1));
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
    //     (clause_4_payment_default_waived).
    // 4.2 [Subject to Clause 5 (Termination),] the contract shall immediately return
    //     to Active status, and the parties shall resume performance as if no default had occurred
    //     (clause_4_client_entitled_to_active_restitution).
    // ------------------------------------------------------------------------

    // --- SystemVerilog Logic: Clause 4 ---

    // [Implements Subclause 4.1]: Legal waiver and rectification of the default event
    assign clause_4_payment_default_waived = clause_3_valid_cure_tendered;

    // [Implements Subclause 4.2]: Entitlement to Active status is SUBJECT TO Clause 5!
    `ifdef CLAUSE_5_4_PATCH_HABITUAL_DEFAULT_LOOPHOLE
        `ifdef FORGOT_SUBJECT_TO_CLAUSE_5_4
            // --- DRAFTING MALPRACTICE (BUG INJECTED) ---
            // Lawyer forgot "Subject to Clause 5" in 4.2!
            // Blindly grants Active restitution even when Clause 5 is terminating!
            assign clause_4_client_entitled_to_active_restitution = clause_4_payment_default_waived;
        `else
            // --- DRAFTING RIGOR: SUBJECT TO CLAUSE 5 ---
            // Properly subordinated: Restitution granted ONLY IF Clause 5 termination is NOT active!
            assign clause_4_client_entitled_to_active_restitution = clause_4_payment_default_waived &&
                                                                   !clause_5_provider_right_to_terminate;
        `endif
    `else
        // Unpatched naive boilerplate: no concept of Clause 5 overriding restitution
        assign clause_4_client_entitled_to_active_restitution = clause_4_payment_default_waived;
    `endif

    // [Trigger to State Arbiter]: Requests physical transition to STATE_ACTIVE
    assign clause_4_restitutes_to_active = clause_4_client_entitled_to_active_restitution;


    // --- Theorem Assertions: Clause 4 ---
    `ifdef FORMAL
        always_ff @(posedge clk_day) begin
            if (rst_n && f_past_valid && $past(rst_n)) begin

                // THEOREM 4.1 (Points to Subclause 4.1):
                // Legal rectification strictly extinguishes Default Notice standing on next day.
                if ($past(clause_4_payment_default_waived)) begin
                    assert (!clause_2_in_default_notice_status);
                end

                // THEOREM 4.2 (Points to Subclause 4.2):
                // Valid entitlement to restitution strictly guarantees restoration of Active standing!
                if ($past(clause_4_client_entitled_to_active_restitution)) begin
                    assert (state == STATE_ACTIVE);
                    assert (contract_is_active);
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
    //     upon demand (provider_attempts_termination).
    // ------------------------------------------------------------------------

    // --- SystemVerilog Logic: Clause 5 ---
    // [Implements Subclauses 5.1, 5.2, 5.3, 5.4]: Directly drives output rights & disabilities
    always_comb begin
        clause_5_provider_right_to_terminate     = 1'b0;
        clause_5_provider_termination_prohibited = 1'b0;

        `ifdef CLAUSE_5_4_PATCH_HABITUAL_DEFAULT_LOOPHOLE
            // [Implements Subclause 5.4]:
            // If the chronic default threshold (>= 3) is reached, the right to terminate
            // is unconditionally unlocked and overrides all statutory protections.
            if (clause_3_consecutive_default_count >= 8'd3) begin
                clause_5_provider_right_to_terminate = 1'b1;
            end else begin
                // [Implements Subclause 5.2]:
                // Termination is strictly prohibited while contract is in Active status.
                if (state == STATE_ACTIVE) begin
                    clause_5_provider_termination_prohibited = 1'b1;
                end

                // [Implements Subclause 5.3]:
                // Termination is strictly prohibited while a cure is actively pending.
                if ((state == STATE_DEFAULT_NOTICE) && (clause_3_days_left_in_cure_period > 8'd0)) begin
                    clause_5_provider_termination_prohibited = 1'b1;
                end

                // [Implements Subclause 5.1]:
                // Expiration of Grace Period (cure_timer == 0) unlocks the termination right.
                if ((state == STATE_DEFAULT_NOTICE) && (clause_3_days_left_in_cure_period == 8'd0)) begin
                    clause_5_provider_right_to_terminate = 1'b1;
                end
            end
        `else
            // [Implements Subclause 5.2 (Unpatched Boilerplate)]:
            // Unconditionally prohibited from terminating during Active standing.
            if (state == STATE_ACTIVE) begin
                clause_5_provider_termination_prohibited = 1'b1;
            end

            // [Implements Subclause 5.3 (Unpatched Boilerplate)]:
            // Unconditionally prohibited from terminating while cure is pending.
            if ((state == STATE_DEFAULT_NOTICE) && (clause_3_days_left_in_cure_period > 8'd0)) begin
                clause_5_provider_termination_prohibited = 1'b1;
            end

            // [Implements Subclause 5.1 (Unpatched Boilerplate)]:
            // Termination right unlocked IF AND ONLY IF timer hits 0.
            if ((state == STATE_DEFAULT_NOTICE) && (clause_3_days_left_in_cure_period == 8'd0)) begin
                clause_5_provider_right_to_terminate = 1'b1;
            end
        `endif
    end

    // [Implements Subclause 5.1 (Automatic) & Subclause 5.4 (Elective) Termination Triggers]:
    // 1. Subclause 5.1 Mandate: Automatic dissolution upon grace period exhaustion (cure_timer == 0).
    // 2. Subclause 5.4 Mandate: Elective dissolution upon written demand by Provider when defaults >= 3.
    assign clause_5_initiates_termination =
        ((state == STATE_DEFAULT_NOTICE) && (clause_3_days_left_in_cure_period == 8'd0)) // [Subclause 5.1 Automatic Expiry]
        `ifdef CLAUSE_5_4_PATCH_HABITUAL_DEFAULT_LOOPHOLE
        || (clause_5_provider_right_to_terminate && provider_attempts_termination) // [Subclause 5.4 Elective Demand]
        `endif
        ;


    // --- Theorem Assertions: Clause 5 ---
    `ifdef FORMAL
        always_ff @(posedge clk_day) begin
            if (rst_n && f_past_valid && $past(rst_n)) begin

                // THEOREM 5.1 (Points to Subclause 5.1):
                // Uncured Grace Period expiration strictly causes AUTOMATIC termination on the next day!
                if ($past(state == STATE_DEFAULT_NOTICE) && ($past(clause_3_days_left_in_cure_period) == 8'd0)) begin
                    assert ($past(clause_5_provider_right_to_terminate));
                    assert (state == STATE_TERMINATED);
                end

                // THEOREM 5.2 (Points to Subclause 5.2):
                // In non-habitual default (< 3), termination power is strictly prohibited during Active status.
                if ($past(state == STATE_ACTIVE) && ($past(clause_3_consecutive_default_count) < 8'd3)) begin
                    assert ($past(clause_5_provider_termination_prohibited));
                    assert (!$past(clause_5_provider_right_to_terminate));
                end

                // THEOREM 5.3 (Points to Subclause 5.3):
                // In non-habitual default (< 3), termination power is strictly prohibited while cure is pending.
                if ($past(state == STATE_DEFAULT_NOTICE) &&
                    ($past(clause_3_consecutive_default_count) < 8'd3) &&
                    ($past(clause_3_days_left_in_cure_period) > 8'd0)) begin
                    assert ($past(clause_5_provider_termination_prohibited));
                    assert (!$past(clause_5_provider_right_to_terminate));
                end

                `ifdef CLAUSE_5_4_PATCH_HABITUAL_DEFAULT_LOOPHOLE
                    // THEOREM 5.4 (Points to Subclause 5.4):
                    // Upon reaching 3 defaults, provider strictly possesses the right to terminate.
                    if ($past(clause_3_consecutive_default_count >= 8'd3)) begin
                        assert ($past(clause_5_provider_right_to_terminate));
                        assert (!$past(clause_5_provider_termination_prohibited));
                    end
                `endif

            end
        end
    `endif



    // ========================================================================
    // PRIMARY STATE ARBITER (Neutral Execution Core)
    // ========================================================================
    // Arbitrates state transitions driven strictly by independent clause triggers
    // ------------------------------------------------------------------------
    always_comb begin
        next_state = state;

        case (state)
            STATE_ACTIVE: begin
                if (clause_5_initiates_termination) begin
                    next_state = STATE_TERMINATED;
                end else if (clause_2_initiates_default_notice) begin
                    next_state = STATE_DEFAULT_NOTICE;
                end
            end

            STATE_DEFAULT_NOTICE: begin
                if (clause_5_initiates_termination) begin
                    next_state = STATE_TERMINATED;
                end else if (clause_4_restitutes_to_active) begin
                    next_state = STATE_ACTIVE;
                end
            end

            STATE_TERMINATED: begin
                next_state = STATE_TERMINATED; // Absorbing sink state
            end

            default: next_state = STATE_ACTIVE;
        endcase
    end

    always_ff @(posedge clk_day or negedge rst_n) begin
        if (!rst_n) begin
            state <= STATE_ACTIVE;
        end else begin
            state <= next_state;
        end
    end

    // [Exposes Overall Status Pins]
    assign contract_is_active     = (state == STATE_ACTIVE);
    assign contract_is_terminated = (state == STATE_TERMINATED);

    // ========================================================================
    // BILATERAL COMMERCIAL AUDIT SUITE (Pure Jurisprudential Verification)
    // ========================================================================
    // Evaluates the fundamental balance of legal remedies between parties.
    // Zero artificial numbers, zero helper flags, zero timer hacks.
    // ========================================================================

    `ifdef FORMAL
        always_ff @(posedge clk_day) begin
            if (rst_n && f_past_valid) begin

                // ============================================================
                // PART 1: MANDATORY DUE PROCESS & FAIRNESS ASSERTS (The Rules)
                // ============================================================

                // ASSERT 1 (Borrower Due Process - No Peacetime Ambush):
                // "The Lender CANNOT have the right to terminate while the contract
                //  is in Active good standing!"
                if (contract_is_active && (clause_3_consecutive_default_count == 8'd0)) begin
                    assert (!clause_5_provider_right_to_terminate);
                    assert (clause_5_provider_termination_prohibited);
                end

                // ASSERT 2 (Borrower Sacred Grace - Mutual Exclusivity):
                // "If the Borrower has the legal right to cure, the Lender
                //  CANNOT simultaneously have the legal right to terminate!"
                if (clause_3_client_right_to_cure) begin
                    assert (!clause_5_provider_right_to_terminate);
                    assert (clause_5_provider_termination_prohibited);
                end

                // ASSERT 3 (Borrower Performance Immunity):
                // "Timely payment on the due date strictly guarantees no default."
                if ($past(clause_1_client_duty_to_pay_today) && $past(client_pays_on_due_date)) begin
                    assert (!$past(clause_1_payment_default_active));
                end

                // ASSERT 4 (Lender Remedy Certainty - Timer Expiry):
                // "When the grace period expires without cure, the Lender MUST have the right to terminate."
                if (clause_2_in_default_notice_status && (clause_3_days_left_in_cure_period == 8'd0)) begin
                    assert (clause_5_provider_right_to_terminate);
                end

                // ASSERT 5 (Borrower Finality - Non-Resurrection):
                // "Once Terminated, the contract is dead and can never resurrect."
                if ($past(contract_is_terminated)) begin
                    assert (contract_is_terminated);
                    assert (!contract_is_active);
                    assert (!clause_2_in_default_notice_status);
                end


                // ============================================================
                // PART 2: REAL TRANSACTIONAL PATHWAYS (The "Covers")
                // ============================================================

                // SCENARIO 1 (The Primary Commercial Bargain):
                // "Can both parties perform on the due date peacefully and stay in good standing?"
                // -> REACHED! Proves the contract works for honest parties.
                cover (
                    contract_is_active &&
                    $past(clause_1_client_duty_to_pay_today) &&
                    $past(client_pays_on_due_date)
                );

                // SCENARIO 2 (The Borrower's Due Process Pathway):
                // "Can a Client who defaulted successfully cure and restore the contract to Active?"
                // -> REACHED! Proves the cure mechanism works as intended.
                cover (
                    clause_2_in_default_notice_status &&
                    client_cures_default &&
                    clause_4_client_entitled_to_active_restitution
                );

                // SCENARIO 3 (The Unilateral Termination Test):
                // "If the Client tenders a TIMELY cure, can the Provider
                //  reject the cure and TERMINATE anyway?"
                //
                // - In UNPATCHED mode: UNREACHABLE (FAIL)!
                //   (Because unpatched contract FORCES the provider to accept every timely cure).
                // - In PATCHED mode: REACHED at Step 17 (PASS)!
                //   (Clause 5.4 gives the Provider the power to reject the timely cure).
                cover (
                    $past(clause_3_client_tenders_timely_cure) &&
                    $past(provider_attempts_termination) &&
                    contract_is_terminated
                );



            end
        end
    `endif




endmodule
`default_nettype wire
