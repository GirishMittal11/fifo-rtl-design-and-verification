
`timescale 1ns/1ps

module Testbench_fifo_async;

    parameter DATA_WIDTH = 8;
    parameter DEPTH = 16;
    parameter ADDRSIZE = $clog2(DEPTH);

    reg wclk = 0, rclk = 0;
    reg wrst_n, rrst_n;

    reg [DATA_WIDTH-1:0] w_data;
    reg winc, rinc;

    wire [DATA_WIDTH-1:0] r_data;
    wire rempty, wfull;

    integer i;
    integer errors = 0;

    // DUT
    fifo_async #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDRSIZE(ADDRSIZE)
    ) dut (
        .r_data(r_data),
        .rempty(rempty),
        .wfull(wfull),
        .w_data(w_data),
        .wclk(wclk),
        .winc(winc),
        .wrst_n(wrst_n),
        .rclk(rclk),
        .rinc(rinc),
        .rrst_n(rrst_n)
    );

    // Independent clocks
    always #5 wclk = ~wclk;  // 10 ns
    always #7 rclk = ~rclk;  // 14 ns


    initial begin

        $dumpfile("wave.vcd");
        $dumpvars(0, Testbench_fifo_async);

        // Initialize inputs
        wrst_n = 0;
        rrst_n = 0;
        w_data = 0;
        winc = 0;
        rinc = 0;

        // Release resets in respective clock domains
        @(negedge wclk);
        wrst_n = 1;

        @(negedge rclk);
        rrst_n = 1;

        // Allow clocked logic to settle
        repeat (2) @(posedge wclk);
        repeat (2) @(posedge rclk);
        #1;


        // TEST 1: Reset verification

        $display("\nTEST 1: Reset");

        if (rempty !== 1'b1) begin
            $display("ERROR: FIFO should be empty after reset");
            errors = errors + 1;
        end
        else
            $display("PASS: FIFO is empty after reset");

        if (wfull !== 1'b0) begin
            $display("ERROR: FIFO should not be full after reset");
            errors = errors + 1;
        end
        else
            $display("PASS: FIFO is not full after reset");


        // TEST 2: Write 16 entries

        $display("\nTEST 2: Fill FIFO");

        @(negedge wclk);

        for (i = 0; i < DEPTH; i = i + 1) begin

            w_data = i;
            winc = 1'b1;

            @(negedge wclk);

        end

        winc = 1'b0;

        // No wait needed: FULL has been updated
        // at the 16th write's rising clock edge.
        #1;

        if (wfull !== 1'b1) begin
            $display("ERROR: FIFO should be full after %0d writes", DEPTH);
            errors = errors + 1;
        end
        else
            $display("PASS: FIFO is full after %0d writes", DEPTH);


        // TEST 3: Overflow attempt

        $display("\nTEST 3: Overflow");

        w_data = 8'hC3;
        winc = 1'b1;

        @(negedge wclk);
        winc = 1'b0;

        #1;

        if (wfull !== 1'b1) begin
            $display("ERROR: Overflow protection failed");
            errors = errors + 1;
        end
        else
            $display("PASS: Overflow write blocked");


        // TEST 4: Read all 16 original entries

        $display("\nTEST 4: Read FIFO contents");

        // Write pointer must reach read domain
        wait (rempty === 1'b0);

        // Align first read request to falling edge
        @(negedge rclk);

        for (i = 0; i < DEPTH; i = i + 1) begin

            // Check data BEFORE advancing read pointer
            if (r_data !== i) begin
                $display("ERROR: Expected %0d, got %0d", i, r_data);
                errors = errors + 1;
            end
            else
                $display("PASS: r_data %0d", r_data);

            rinc = 1'b1;

            // Keep request high across next rising edge
            @(negedge rclk);
            rinc = 1'b0;

        end

        wait (rempty === 1'b1);
        #1;

        if (rempty !== 1'b1) begin
            $display("ERROR: FIFO should be empty after %0d reads", DEPTH);
            errors = errors + 1;
        end
        else
            $display("PASS: FIFO is empty after %0d reads", DEPTH);


        // TEST 5: Write after pointer wrap-around

        $display("\nTEST 5: Write after wrap-around");

        // Read pointer must reach write domain.
        // FULL may remain asserted temporarily.
        wait (wfull === 1'b0);

        @(negedge wclk);

        // First word
        w_data = 8'hAA;
        winc = 1'b1;

        @(negedge wclk);

        // Second word; write enable remains HIGH
        w_data = 8'hF0;

        @(negedge wclk);
        winc = 1'b0;


        // TEST 6: Read and verify new values

        $display("\nTEST 6: Read new values");

        // New write pointer must reach read domain
        wait (rempty === 1'b0);

        @(negedge rclk);

        // Check first word BEFORE reading
        if (r_data !== 8'hAA) begin
            $display("ERROR: Expected AA, got %h", r_data);
            errors = errors + 1;
        end
        else
            $display("PASS: First word AA received");

        // Read first word
        rinc = 1'b1;

        @(negedge rclk);
        rinc = 1'b0;

        // Check second word
        if (r_data !== 8'hF0) begin
            $display("ERROR: Expected F0, got %h", r_data);
            errors = errors + 1;
        end
        else
            $display("PASS: Second word F0 received");

        // Read second word
        rinc = 1'b1;

        @(negedge rclk);
        rinc = 1'b0;

        wait (rempty === 1'b1);
        #1;

        if (rempty !== 1'b1) begin
            $display("ERROR: FIFO should be empty");
            errors = errors + 1;
        end
        else
            $display("PASS: FIFO is empty after second read");


        // TEST 7: Underflow attempt

        $display("\nTEST 7: Underflow");

        @(negedge rclk);
        rinc = 1'b1;

        @(negedge rclk);
        rinc = 1'b0;

        #1;

        if (rempty !== 1'b1) begin
            $display("ERROR: Underflow protection failed");
            errors = errors + 1;
        end
        else
            $display("PASS: Underflow read blocked");


        // FINAL RESULT

        $display("\n====================================");

        if (errors == 0)
            $display("ALL DIRECTED TESTS PASSED");
        else
            $display("TEST FAILED: %0d errors", errors);

        $display("====================================\n");

        $finish;

    end


    // Timeout protection
    initial begin
        #100000;
        $fatal(1, "TIMEOUT: Testbench did not finish");
    end

endmodule
