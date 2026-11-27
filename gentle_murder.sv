// ============================================================================
// File:        gentle_murder.sv
// Author:      Titus Ng (Ng Tsz Hin)
// Description: Pure 0 Hz Combinational Decoder for Forrester's Paradox (1984)
// Architecture: Substantive Criminal Classification (No Clocks, No Dummy Pins)
// Target:      Formal Verification (SymbiYosys / Combinational SAT)
// ============================================================================

`default_nettype none

typedef enum logic [1:0] {
    STANDING_INNOCENT                 = 2'b00,
    STANDING_GUILTY_BASIC_MURDER      = 2'b01,
    STANDING_GUILTY_AGGRAVATED_MURDER = 2'b10
} CitizenStanding;

module gentle_murder (
    // ========================================================================
    // EMPIRICAL INPUTS (Sein - What happened in the real world)
    // ========================================================================
    input  logic           fact_citizen_kills,
    input  logic           fact_killing_is_gentle,

    // ========================================================================
    // OPERATIVE LEGAL OUTPUTS (Sollen - Dynamic Legal Valuation)
    // ========================================================================
    output CitizenStanding citizen_standing,
    output logic           citizen_IMMUNITY_from_punishment,
    output logic           state_POWER_to_punish_basic,
    output logic           state_POWER_to_punish_aggravated,
    output logic           citizen_DUTY_to_kill,
    output logic           citizen_DUTY_to_kill_gently
);

    // ========================================================================
    // SUBSTANTIVE CLASSIFIER (0 Hz Pure Combinational Decoder)
    // ========================================================================
    always_comb begin
        // 1. Classify Legal Standing:
        citizen_standing = STANDING_INNOCENT; // Default to Innocent
        citizen_DUTY_to_kill = 1'b0; // There is always no duty to kill
        citizen_DUTY_to_kill_gently = 1'b0; // There is always no duty to kill gently
        if (fact_citizen_kills) begin
            // UNCOMMENT the following line to trigger paradox
            // citizen_DUTY_to_kill_gently = 1'b1; // If the citizen kills, then they have a duty to kill gently.
            // an error of drafting by Forrester. The law NEVER said there is a duty to kill gently.
            // That's why it is a paradox! Will be caught by SimbiYosys.
            citizen_standing = fact_killing_is_gentle ?
                               STANDING_GUILTY_BASIC_MURDER :
                               STANDING_GUILTY_AGGRAVATED_MURDER; // gentle killing is merely a mitigating factor, still guilty of murder
        end

        // 2. Decode Operative Hohfeldian Entitlements:
        citizen_IMMUNITY_from_punishment = (citizen_standing == STANDING_INNOCENT);
        state_POWER_to_punish_basic      = (citizen_standing == STANDING_GUILTY_BASIC_MURDER);
        state_POWER_to_punish_aggravated = (citizen_standing == STANDING_GUILTY_AGGRAVATED_MURDER);
    end

    // ========================================================================
    // FORMAL AUDIT SUITE (The Substantive Legal Specification)
    // ========================================================================
    `ifdef FORMAL
        always_comb begin
            // THEOREM 1 (The Primary Prohibition Invariant):
            // The system formally guarantees that killing NEVER results in Innocence!
            if (fact_citizen_kills) begin
                assert (citizen_standing != STANDING_INNOCENT);
                assert (!citizen_IMMUNITY_from_punishment);
            end

            // THEOREM 2 (The Refutation of Forrester 1984):
            // Proves that "gentle killing" routes strictly to Basic Guilt,
            // never granting Immunity or escaping State punitive Power!
            if (fact_citizen_kills && fact_killing_is_gentle) begin
                assert (citizen_standing == STANDING_GUILTY_BASIC_MURDER);
                assert (state_POWER_to_punish_basic);
                assert (!state_POWER_to_punish_aggravated);
            end

            // THEOREM 3 (Aggravation Invariant):
            // Cruel killing strictly activates Aggravated State Power.
            if (fact_citizen_kills && !fact_killing_is_gentle) begin
                assert (citizen_standing == STANDING_GUILTY_AGGRAVATED_MURDER);
                assert (state_POWER_to_punish_aggravated);
            end

            // THEOREM 4 (The Paradox Invariant):
            // Under NO circumstances does a citizen EVER have a duty to kill!
            assert (citizen_DUTY_to_kill == 1'b0);
            assert (citizen_DUTY_to_kill_gently == 1'b0);
        end
    `endif

endmodule
`default_nettype wire
