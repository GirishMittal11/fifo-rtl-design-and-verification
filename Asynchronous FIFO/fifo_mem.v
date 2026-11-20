`timescale 1ns/1ps

module fifo_mem #(
    parameter DATA_WIDTH = 8, // mem data word width
    parameter ADDRSIZE = 4)       // Number of mem address bits
    ( input [DATA_WIDTH-1:0] w_data,
      output [DATA_WIDTH-1:0] r_data,
      input [ADDRSIZE-1:0] waddr,raddr,
      input wclk,wclken,wfull);
   
   `ifdef VENDORRAM
      // Instantiate vendor RAM here
      vendor_ram mem(
           .dout(r_data),
           .din(w_data),
           .clk(wclk),
           .wclken(wclken),
           .raddr(raddr),
           .waddr(waddr),
           .wclken_n(wfull)
      );

   `else
     // RTL verilog model 
     localparam DEPTH = 1 << ADDRSIZE;
     reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

     assign r_data = mem[raddr];

     always @(posedge wclk) begin
        if(wclken && !wfull)
              mem[waddr] <= w_data;
     end
   `endif
endmodule