// ============================================================
// Employment Contract with Explicit Power-On Initialization
// ============================================================

module employment_contract #(
    parameter int unsigned NOTICE_DAYS    = 5,
    parameter int unsigned DAILY_RATE_USD = 250 // $250 earned per day
)(
    input  logic        clk_day,
    input  logic        rst_n,

    input  logic        has_handed_in_resignation_letter,
    input  logic        company_accepts_early_release,
    input  logic        final_salary_paid,

    output logic        is_employed,
    output logic        notice_period_active,
    output logic [15:0] days_remaining_notice,
    output logic [31:0] total_accrued_salary_usd,
    output logic [1:0]  legal_obligation_code,
    output logic        employment_terminated
);

    typedef enum logic [1:0] {
        STATE_ACTIVE     = 2'b00,
        STATE_NOTICE     = 2'b01,
        STATE_TERMINATED = 2'b10
    } contract_state_e;

    // Power-on initial values prevent 'x'
    contract_state_e state          = STATE_ACTIVE;
    contract_state_e next_state     = STATE_ACTIVE;
    logic [15:0]     day_counter    = 16'd0;
    logic [31:0]     ledger_balance = 32'd0;

    assign total_accrued_salary_usd = ledger_balance;

    // ------------------------------------------------------------
    // 1. Clocked Logic: States & Dollar Accumulator
    // ------------------------------------------------------------
    always_ff @(posedge clk_day or negedge rst_n) begin
        if (!rst_n) begin
            state          <= STATE_ACTIVE;
            day_counter    <= 16'd0;
            ledger_balance <= 32'd0;
        end else begin
            state <= next_state;

            // Notice Countdown
            if (state == STATE_ACTIVE && next_state == STATE_NOTICE) begin
                day_counter <= NOTICE_DAYS[15:0];
            end else if (state == STATE_NOTICE && day_counter > 16'd0) begin
                day_counter <= day_counter - 1'b1;
            end else if (next_state == STATE_TERMINATED) begin
                day_counter <= 16'd0;
            end

            // FINANCIAL LEDGER (Accruing wages)
            if (final_salary_paid) begin
                ledger_balance <= 32'd0; // Cleared!
            end else if (state == STATE_ACTIVE || state == STATE_NOTICE) begin
                ledger_balance <= ledger_balance + DAILY_RATE_USD; // Earn $250/day
            end
        end
    end

    // ------------------------------------------------------------
    // 2. Next State Logic
    // ------------------------------------------------------------
    always_comb begin
        next_state = state;
        case (state)
            STATE_ACTIVE: begin
                if (has_handed_in_resignation_letter)
                    next_state = STATE_NOTICE;
            end
            STATE_NOTICE: begin
                if ((day_counter == 16'd1) || company_accepts_early_release)
                    next_state = STATE_TERMINATED;
            end
            STATE_TERMINATED: begin
                next_state = STATE_TERMINATED;
            end
            default: next_state = STATE_ACTIVE;
        endcase
    end

    // ------------------------------------------------------------
    // 3. Dynamic Legal Obligations
    // ------------------------------------------------------------
    always_comb begin
        is_employed           = 1'b0;
        notice_period_active  = 1'b0;
        days_remaining_notice = day_counter;
        employment_terminated = 1'b0;
        legal_obligation_code = 2'b00;

        case (state)
            STATE_ACTIVE: begin
                is_employed           = 1'b1;
                legal_obligation_code = 2'b01; // Accruing Regular Wage
            end

            STATE_NOTICE: begin
                is_employed           = 1'b1;
                notice_period_active  = 1'b1;
                legal_obligation_code = 2'b10; // Accruing Notice Wage
            end

            STATE_TERMINATED: begin
                employment_terminated = 1'b1;
                if (!final_salary_paid && ledger_balance > 0)
                    legal_obligation_code = 2'b11; // Final Severance Pending
                else
                    legal_obligation_code = 2'b00; // Discharged
            end
        endcase
    end

endmodule
