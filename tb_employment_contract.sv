`timescale 1ns/1ps

module tb_employment_contract;
    logic clk_day = 0;
    logic rst_n = 1;
    logic has_handed_in_resignation_letter = 0;
    logic company_accepts_early_release = 0;
    logic final_salary_paid = 0;

    logic        is_employed;
    logic        notice_period_active;
    logic [15:0] days_remaining_notice;
    logic [31:0] total_accrued_salary_usd;
    logic [1:0]  legal_obligation_code;
    logic        employment_terminated;

    int current_day = 1;

    employment_contract #(
        .NOTICE_DAYS(5),
        .DAILY_RATE_USD(250)
    ) uut (.*);

    always #5 clk_day = ~clk_day;

    function string decode_obligation(logic [1:0] code);
        case (code)
            2'b01:   return "ACCRUING REGULAR DAILY WAGE ($250/day)";
            2'b10:   return "ACCRUING NOTICE PERIOD WAGE ($250/day)";
            2'b11:   return "FINAL SEVERANCE / PAYCHECK PENDING";
            default: return "CONTRACT SETTLED & DISCHARGED ($0 OWED)";
        endcase
    endfunction

    task print_dashboard(string event_msg);
        $display("===FRAME===");
        $display("+------------------------------------------------------------------+");
        $display("|             HARDWARE-ENFORCED EMPLOYMENT CONTRACT                |");
        $display("+------------------------------------------------------------------+");
        $display(" TIMELINE            : CALENDAR DAY %0d", current_day);
        $display(" LATEST EVENT        : %s", event_msg);
        $display("--------------------------------------------------------------------");
        $display(" Employment Status   : %s", is_employed ? "ACTIVE EMPLOYEE [VALID]" : "TERMINATED [REVOKED]");
        $display(" Notice Countdown    : %0d days remaining", days_remaining_notice);
        $display(" Total Accrued Debt  : $%0d USD", total_accrued_salary_usd);
        $display(" Legal Obligation    : [%s]", decode_obligation(legal_obligation_code));
        $display(" Contract Finalized  : %s", employment_terminated ? "YES" : "NO");
        $display("+------------------------------------------------------------------+");
        $display(" [Executing on Silicon Logic Gates | 0.9s / Day]");
    endtask

    initial begin
        rst_n = 1; #5;
        rst_n = 0; #10;
        rst_n = 1; #1;
        print_dashboard("Contract Signed. Employment Commenced.");

        repeat (3) begin
            @(posedge clk_day);
            current_day++;
            #1;
            print_dashboard("Working standard day... earning $250.");
        end

        @(posedge clk_day);
        current_day++;
        has_handed_in_resignation_letter = 1;
        #1;
        print_dashboard("RESIGNATION HANDED IN! 5-Day Notice Clock Triggered.");

        @(posedge clk_day);
        has_handed_in_resignation_letter = 0;
        current_day++;
        #1;

        repeat(4) begin
            print_dashboard("Serving contractual notice period day by day...");
            @(posedge clk_day);
            current_day++;
            #1;
        end
        print_dashboard("Serving contractual notice period day by day...");

        @(posedge clk_day);
        current_day++;
        #1;
        print_dashboard("NOTICE EXPIRED! Access revoked. Badges deactivated.");

        repeat (2) begin
            @(posedge clk_day);
            current_day++;
            #1;
            print_dashboard("Awaiting Final Wire Settlement from Payroll...");
        end

        @(posedge clk_day);
        current_day++;
        final_salary_paid = 1;
        #1;
        print_dashboard("PAYROLL RECEIVED! Final settlement complete. $0 owed.");

        #10;
        $finish;
    end
endmodule
