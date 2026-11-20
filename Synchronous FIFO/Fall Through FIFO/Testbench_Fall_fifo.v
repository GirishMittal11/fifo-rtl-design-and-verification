`timescale 1ns/1ps

module Testbench_Fall_fifo;

parameter DATA_WIDTH = 8;
parameter DEPTH = 4;

reg clk=0, rst_n;
reg [DATA_WIDTH-1:0] w_data;
reg wr_en,rd_en;
wire empty,full;
wire [DATA_WIDTH-1:0] r_data;

FF_fifo     #(.DATA_WIDTH(DATA_WIDTH),.DEPTH(DEPTH))
          dut( .clk(clk),
               .rst_n(rst_n),
               .w_data(w_data),
               .wr_en(wr_en),
               .rd_en(rd_en),
               .empty(empty),
               .full(full),
               .r_data(r_data));

        integer i;

        // clock pulse

        always #5 clk = ~clk;
        
        initial begin
            $dumpfile("wave.vcd");
            $dumpvars(0,Testbench_Fall_fifo);
            

            wr_en=0;
            rd_en=0;


            rst_n = 0;
            @(negedge clk);
            rst_n = 1;

            if ( empty !== 1'b1)
                $display ("Error: FIFO should be empty after reset but is not");
                else
                $display ("Pass: Fifo is empty after reset");

            for (i=0; i<DEPTH; i=i+1) begin
                @(posedge clk);// check
                w_data = i;
                wr_en = 1;
               // @(negedge clk);
            end

            wr_en = 0;

            if ( !full )
                $display ("Error: fifo shd be full ");
            else
                $display ("Success");
            
            // check for overflow writing

            w_data = 8'b00000001;
            wr_en = 1;
            @(negedge clk);
            wr_en=0;

            for (i=0; i<DEPTH ; i=i+1) begin
             
                if ( r_data !== i ) begin
                    $display("Error : %d shd be equal to %d ",r_data,i);
                end

                rd_en=1;
                @(negedge clk);
                rd_en=0;

            end

            if(!empty)
               $display("Error , shd have become empty ");
            else
               $display("Success");

            $finish;
            
        end

endmodule