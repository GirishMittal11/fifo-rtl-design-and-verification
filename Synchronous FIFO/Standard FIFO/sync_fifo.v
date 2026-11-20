`timescale 1ns/1ps

module sync_fifo #(
    parameter DATA_WIDTH = 8 ,
    parameter DEPTH = 16 , // Must be a power of 2
    parameter ADDR_WIDTH = $clog2(DEPTH)
)(
    input    wire clk,rst_n,
    input    wire [DATA_WIDTH-1:0] w_data,
    input    wire wr_en,
    input    wire rd_en,
    output   wire empty,
    output   wire full,
    output   reg [DATA_WIDTH-1:0] r_data
);
reg [DATA_WIDTH-1:0] mem [DEPTH-1:0];
reg [ADDR_WIDTH:0] rd_ptr,wr_ptr;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        wr_ptr <= 0;
    else if (wr_en && !full) begin
        mem[wr_ptr[ADDR_WIDTH-1:0]] <= w_data;
        wr_ptr = wr_ptr + 1'b1;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        rd_ptr <= 0;
        r_data <= {DATA_WIDTH{1'b0}};
    end
    else if (rd_en && !empty) begin
        r_data <= mem[rd_ptr[ADDR_WIDTH-1:0]];
        rd_ptr = rd_ptr + 1'b1;
    end
end

assign full  =  (wr_ptr[ADDR_WIDTH] != rd_ptr[ADDR_WIDTH]) && (wr_ptr[ADDR_WIDTH-1:0] == rd_ptr[ADDR_WIDTH-1:0]);
assign empty =  (wr_ptr == rd_ptr);

endmodule
