// ============================================================================
// File:        chisholm_contrary_to_duty.sv
// Author:      Titus Ng (Ng Tsz Hin)
// Description: Pure 0 Hz Combinational Decoder for Chisholm's Contrary-to-Duty
//              Paradox (1963)
// Reference:   Roderick M. Chisholm, "Contrary-to-Duty Imperatives and Deontic
//              Logic", Analysis, Vol. 24, No. 2 (1963), pp. 33-36.
// Architecture: Substantive Conduct Classification (No Clocks, Decoupled Modalities)
// Target:      Formal Verification (SymbiYosys / Combinational SAT)
// ============================================================================

`default_nettype none

typedef enum logic [1:0] {
    STANDING_PERFECT_COMPLIANCE       = 2'b00, // Goes and tells
    STANDING_BENIGN_FAILURE           = 2'b01, // Does not go, and honestly stays silent
    STANDING_INCOMPLETE_ASSISTANCE    = 2'b10, // Goes, but fails to tell (unannounced aid)
    STANDING_DECEPTIVE_ABANDONMENT    = 2'b11  // Does not go, but lies that he is coming!
} MoralStanding;

module chisholm_contrary_to_duty (
    // ========================================================================
    // EMPIRICAL INPUTS (Sein - What actually happened in the physical world)
    // ========================================================================
    input  logic         fact_man_goes_to_assist,     // Chisholm Fact 'a'
    input  logic         fact_man_tells_he_is_coming, // Chisholm Fact 'b'

    // ========================================================================
    // OPERATIVE NORMATIVE OUTPUTS (Sollen - Dynamic Legal/Moral Valuation)
    // ========================================================================
    output MoralStanding moral_standing,

    // Primary Objective Duty (Statement 1):
    output logic         man_DUTY_to_assist,

    // Secondary Communication Modalities (Statements 2 & 3):
    output logic         man_DUTY_to_tell,
    output logic         man_DUTY_not_to_tell,

    // Breaches of First-Order Duties:
    output logic         breach_of_assistance_duty,
    output logic         breach_of_communication_duty
);

    // ========================================================================
    // SUBSTANTIVE CLASSIFIER (0 Hz Pure Combinational Decoder)
    // ========================================================================
    always_comb begin
        // --------------------------------------------------------------------
        // [CHISHOLM STATEMENT 1]:
        // "It ought to be that a certain man go to the assistance of his neighbours"
        // In modal logic: O(a).
        // In hardware: This is the immutable baseline primary duty.
        // --------------------------------------------------------------------
        man_DUTY_to_assist        = 1'b1;
        breach_of_assistance_duty = man_DUTY_to_assist && !fact_man_goes_to_assist;

        // --------------------------------------------------------------------
        // [CHISHOLM STATEMENTS 2 & 3 - The Contrary-to-Duty Multiplexer]:
        //
        // [Statement 2]: "It ought to be that if he does go he tell them he is coming"
        // [Statement 3]: "If he does not go then he ought not to tell them he is coming"
        //
        // THE LOGICAL TYPE-ERROR OF 1963:
        // Modal logicians detached O(b) via Principle (I) while simultaneously
        // detaching O(~b) via factual detachment on ~a, causing O(b) && O(~b) to collide.
        //
        // THE HARDWARE TRUTH:
        // Statements 2 and 3 are mutually exclusive branches of a 2-to-1 MULTIPLEXER
        // gated by empirical fact 'a' (fact_man_goes_to_assist)!
        // --------------------------------------------------------------------
        if (fact_man_goes_to_assist) begin
            // Branch 2: He goes -> Communication is mandatory coordination:
            man_DUTY_to_tell     = 1'b1;
            man_DUTY_not_to_tell = 1'b0;
        end else begin
            // Branch 3: He does not go -> Telling would be deceptive fraud:
            man_DUTY_to_tell     = 1'b0;
            man_DUTY_not_to_tell = 1'b1;

            // ================================================================
            // UNCOMMENT THE FOLLOWING LINE TO TRIGGER CHISHOLM'S 1963 PARADOX:
            // ================================================================
            // man_DUTY_to_tell = 1'b1;
            // (The Standard Deontic Logic bug: unconditionally detaching O(b)
            //  from O(a) and O(a -> b) without checking physical reality ~a!)
        end

        // --------------------------------------------------------------------
        // EVALUATE COMPLIANCE WITH COMMUNICATION DUTIES
        // --------------------------------------------------------------------
        breach_of_communication_duty =
            (man_DUTY_to_tell     && !fact_man_tells_he_is_coming) ||
            (man_DUTY_not_to_tell &&  fact_man_tells_he_is_coming);

        // --------------------------------------------------------------------
        // CLASSIFY OVERALL COMPLIANCE STANDING
        // --------------------------------------------------------------------
        case ({fact_man_goes_to_assist, fact_man_tells_he_is_coming})
            2'b11:   moral_standing = STANDING_PERFECT_COMPLIANCE;
            2'b10:   moral_standing = STANDING_INCOMPLETE_ASSISTANCE;
            2'b00:   moral_standing = STANDING_BENIGN_FAILURE;
            2'b01:   moral_standing = STANDING_DECEPTIVE_ABANDONMENT;
            default: moral_standing = STANDING_BENIGN_FAILURE;
        endcase
    end

    // ========================================================================
    // FORMAL AUDIT SUITE (The Substantive Moral/Legal Specification)
    // ========================================================================
    `ifdef FORMAL
        always_comb begin
            // ================================================================
            // THEOREM 1 (The Refutation of Chisholm's Paradox - Axiom D):
            // Verbatim Chisholm Principle (II):
            // "It is not true to say, of any a, both that a ought to occur
            //  and that a ought not to occur."
            //
            // Proves that the circuit NEVER commands conflicting duties simultaneously!
            // ================================================================
            assert (!(man_DUTY_to_tell && man_DUTY_not_to_tell));

            // ================================================================
            // THEOREM 2 (Chisholm 1963 Fact Pattern: [Statement 4: He does not go]):
            // Verbatim Chisholm Scenario:
            // "(1) it ought to be that a; (2) it ought to be that if a then b;
            //  (3) if not-a, then it ought to be that not-b; and (4) not-a."
            //
            // Proves that under ~a:
            // 1. The duty NOT to tell is strictly active (man_DUTY_not_to_tell = 1).
            // 2. The duty to tell is DEAD (man_DUTY_to_tell = 0).
            // 3. Primary assistance duty is flagged as breached.
            // ================================================================
            if (!fact_man_goes_to_assist) begin
                assert (breach_of_assistance_duty);
                assert (man_DUTY_not_to_tell == 1'b1);
                assert (man_DUTY_to_tell     == 1'b0);
            end

            // ================================================================
            // THEOREM 3 (Ideal Trajectory Resolution):
            // If the man performs primary duty 'a', duty to tell 'b' is strictly asserted.
            // ================================================================
            if (fact_man_goes_to_assist) begin
                assert (!breach_of_assistance_duty);
                assert (man_DUTY_to_tell     == 1'b1);
                assert (man_DUTY_not_to_tell == 1'b0);
            end

            // ================================================================
            // THEOREM 4 (Deceptive Abandonment Invariant):
            // If the man fails to assist (~a) but tells his neighbours he is coming (b),
            // the system strictly convicts him of Deceptive Abandonment!
            // ================================================================
            if (!fact_man_goes_to_assist && fact_man_tells_he_is_coming) begin
                assert (breach_of_communication_duty);
                assert (moral_standing == STANDING_DECEPTIVE_ABANDONMENT);
            end

            // ================================================================
            // THEOREM 5 (Honest Failure Mitigation):
            // If the man cannot go (~a), and complies with the CTD duty by staying silent (~b),
            // his communication duty is fully satisfied (only primary assistance breached).
            // ================================================================
            if (!fact_man_goes_to_assist && !fact_man_tells_he_is_coming) begin
                assert (!breach_of_communication_duty);
                assert (moral_standing == STANDING_BENIGN_FAILURE);
            end
        end
    `endif

endmodule
`default_nettype wire
