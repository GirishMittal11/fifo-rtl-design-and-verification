`timescale 1ns/1ps

module Testbench_Sync_Fifo;
    
    parameter DATA_WIDTH = 8;
    parameter DEPTH = 4;
    reg clk=0, rst_n;
    reg [DATA_WIDTH-1:0] w_data;
    reg wr_en,rd_en;
    wire empty,full;
    wire  [DATA_WIDTH-1:0] r_data;

    FF_fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .DEPTH(DEPTH)
        ) dut(
        .clk(clk),
        .rst_n(rst_n),
        .w_data(w_data),
        .wr_en(wr_en),
        .rd_en(rd_en),
        .empty(empty),
        .full(full),
        .r_data(r_data)
    );
    integer i;


    always #5 clk = ~clk;
    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, Testbench_Sync_Fifo);

        rst_n = 0;
        @(negedge clk);
        rst_n = 1;

        if ( empty !== 1'b1) 
            $display ("Error: FIFO should be empty after reset but is not");
    

        for (i=0; i<DEPTH; i=i+1) begin
            w_data = i;
            wr_en =1;
            @(negedge clk);
        end
        
        wr_en = 0;

        if (!full) 
            $display("Error: FIFO shd be full after writing %d depth entries ",DEPTH);
        else
            $display("Pass : FIFO is full after writing %d entries", DEPTH);
        
        // check for overflow writing
        w_data = 8'b11000011;
        wr_en  = 1;
        @(negedge clk);
        wr_en = 0;

        for ( i=0 ; i<DEPTH; i=i+1 ) begin
            rd_en = 1;
            @(negedge clk);
            rd_en = 0;
            if ( r_data !== i )
                $display ("Error : expected %0d but got %0d , overflow may have occured",i,r_data);
        end

        if (!empty)
            $display ("Error: FIFO shd be empty after reading depth entries");
        else
            $display ("Pass : FIFO is empty after reading %1d entries",DEPTH);
    
        $finish;
    end

endmodule