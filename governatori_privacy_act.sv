// ============================================================================
// File:        governatori_privacy_act.sv
// Author:      Titus Ng (Ng Tsz Hin)
// Description: Pure 0 Hz Combinational Decoder for Guido Governatori's
//              Privacy Act Paradox (2014)
// Architecture: Substantive Statutory Classification (No Clocks, Decoupled Sections)
// Target:      Formal Verification (SymbiYosys / Combinational SAT)
// ============================================================================

`default_nettype none

typedef enum logic [1:0] {
    STANDING_COMPLIANT          = 2'b00,
    STANDING_VIOLATION_PERSONAL = 2'b01,
    STANDING_VIOLATION_MEDICAL  = 2'b10
} EntityStanding;

module governatori_privacy_act (
    // ========================================================================
    // EMPIRICAL INPUTS (Sein - What happened in the real world)
    // ========================================================================
    input  logic          fact_court_order_authorizes_personal_data,   // Event C
    input  logic          fact_entity_collects_personal_data,          // Event A
    input  logic          fact_entity_destroys_personal_before_access, // Event B (Rectification)
    input  logic          fact_entity_collects_medical_data,           // Event D

    // ========================================================================
    // OPERATIVE LEGAL OUTPUTS (Sollen - Dynamic Legal Valuation)
    // ========================================================================
    output EntityStanding entity_standing,
    output logic          entity_PRIVILEGE_to_collect_personal_data,
    output logic          entity_PRIVILEGE_to_collect_medical_data,
    output logic          entity_IMMUNITY_from_personal_data_penalty,
    output logic          state_POWER_to_penalize_personal_data,
    output logic          state_POWER_to_penalize_medical_data
);

    // ========================================================================
    // SUBSTANTIVE CLASSIFIER (0 Hz Pure Combinational Decoder)
    // ========================================================================
    always_comb begin
        // --------------------------------------------------------------------
        // INITIAL DEFAULT BASELINE
        // --------------------------------------------------------------------
        entity_standing                            = STANDING_COMPLIANT;
        entity_PRIVILEGE_to_collect_personal_data  = 1'b0;
        entity_PRIVILEGE_to_collect_medical_data   = 1'b0;
        entity_IMMUNITY_from_personal_data_penalty = 1'b1; // Default immune (Hohfeldian correlative of No-Power)
        state_POWER_to_penalize_personal_data      = 1'b0;
        state_POWER_to_penalize_medical_data       = 1'b0;

        // ====================================================================
        // SECTION 1: PROHIBITION ON PERSONAL INFORMATION
        // [Governatori Section 1 Text]:
        // "The collection of personal information is forbidden, unless acting
        //  on a court order authorising it."
        // ====================================================================
        if (fact_court_order_authorizes_personal_data) begin
            entity_PRIVILEGE_to_collect_personal_data = 1'b1;
        end

        if (fact_entity_collects_personal_data && !entity_PRIVILEGE_to_collect_personal_data) begin
            // Unauthorized collection constitutes a prima facie statutory breach:
            entity_IMMUNITY_from_personal_data_penalty = 1'b0;
            state_POWER_to_penalize_personal_data      = 1'b1;
            entity_standing                            = STANDING_VIOLATION_PERSONAL;
        end

        // ====================================================================
        // SECTION 2: STATUTORY DEFENSE FOR PERSONAL INFORMATION
        // [Governatori Section 2 Text]:
        // "The destruction of illegally collected personal information before
        //  accessing it is a defence against the illegal collection of the
        //  personal information."
        // ====================================================================
        if (state_POWER_to_penalize_personal_data && fact_entity_destroys_personal_before_access) begin
            // Statutory defense succeeds: dismisses charge, wipes penalty power, restores immunity
            state_POWER_to_penalize_personal_data      = 1'b0;
            entity_IMMUNITY_from_personal_data_penalty = 1'b1;
            entity_standing                            = STANDING_COMPLIANT;

            // UNCOMMENT the following line to trigger Governatori's paradox:
            // entity_PRIVILEGE_to_collect_personal_data = 1'b1; // The logic flaw: conflating defense with permission!
        end

        // ====================================================================
        // SECTION 3: CONDITIONAL PROHIBITION ON MEDICAL INFORMATION
        // [Governatori Section 3 Text]:
        // "The collection of medical information is forbidden, unless the entity
        //  collecting the medical information is permitted to collect personal
        //  information."
        // ====================================================================
        entity_PRIVILEGE_to_collect_medical_data = entity_PRIVILEGE_to_collect_personal_data;

        if (fact_entity_collects_medical_data && !entity_PRIVILEGE_to_collect_medical_data) begin
            state_POWER_to_penalize_medical_data = 1'b1;
            entity_standing                      = STANDING_VIOLATION_MEDICAL;
        end
    end

    // ========================================================================
    // FORMAL AUDIT SUITE (The Substantive Statutory Specification)
    // ========================================================================
    `ifdef FORMAL
        always_comb begin
            // THEOREM 1 (The Sovereign Authorization Invariant):
            // A valid court order strictly confers privileges and guarantees lawful compliance.
            if (fact_court_order_authorizes_personal_data) begin
                assert (entity_PRIVILEGE_to_collect_personal_data);
                assert (entity_PRIVILEGE_to_collect_medical_data);
                assert (!state_POWER_to_penalize_personal_data);
                assert (!state_POWER_to_penalize_medical_data);
                assert (entity_standing == STANDING_COMPLIANT);
            end

            // THEOREM 2 (The Refutation of Governatori 2014):
            // If the entity steals personal data, destroys it, and steals medical data:
            // S.2 dismisses personal penalty, BUT S.3 strictly activates state power
            // to penalize medical breach, routing standing to STANDING_VIOLATION_MEDICAL!
            if (!fact_court_order_authorizes_personal_data &&
                 fact_entity_collects_personal_data &&
                 fact_entity_destroys_personal_before_access &&
                 fact_entity_collects_medical_data) begin
                assert (entity_IMMUNITY_from_personal_data_penalty);
                assert (!state_POWER_to_penalize_personal_data);
                assert (state_POWER_to_penalize_medical_data);
                assert (entity_standing == STANDING_VIOLATION_MEDICAL);
            end

            // THEOREM 3 (Anti-Laundering Invariant):
            // Destroying illegally collected data shall NEVER assert an affirmative privilege!
            if (!fact_court_order_authorizes_personal_data) begin
                assert (entity_PRIVILEGE_to_collect_personal_data == 1'b0);
                assert (entity_PRIVILEGE_to_collect_medical_data  == 1'b0);
            end
        end
    `endif

endmodule
`default_nettype wire
