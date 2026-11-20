`timescale 1ns/1ps

module FF_fifo #(
    parameter DATA_WIDTH = 8 ,
    parameter DEPTH = 16 ,
    parameter counter_width = $clog2(DEPTH+1)
)(
    input   wire clk,rst_n,
    input   wire [DATA_WIDTH-1:0] w_data,
    input   wire wr_en ,
    input   wire rd_en,
    output  wire empty,
    output  wire full,
    output  wire [DATA_WIDTH-1:0] r_data

);

// storage and control
reg [DATA_WIDTH-1:0] mem [DEPTH-1:0];
reg [counter_width-1:0] count;

integer i;

// status flags
assign full  = (count == DEPTH);
assign empty = (count == 0);

// accepted operation based on status flags
assign wr_accept = wr_en && !full;
assign rd_accept = rd_en && !empty;

// Fall through output 
// the oldest word is at mem[DEPTH-1] and the newest word is at mem[0]

assign r_data = mem[DEPTH-1];

// sequential control & data movement

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        count <= 0;
    end

    else begin

        case ({wr_accept,rd_accept})
            
            // write only

            2'b10:begin

                // insert at the nearest free slot 
                // toward the input side

                mem[DEPTH-1-count] <= w_data;
                count <= count + 1'b1;

            end
            
            // read only 
            2'b01:begin

                // shift all the words toward the output side

                for ( i=DEPTH-1 ; i>0 ; i=i-1)begin
                    if ( i>DEPTH-count) begin
                        mem[i]<=mem[i-1];
                    end
                end

                mem[DEPTH-count] <= {DATA_WIDTH{1'b0}};
                count <= count - 1'b1;

            end

            // write and read only

            2'b11:begin
                
                for ( i=DEPTH-1 ; i>0 ; i=i-1) begin
                    if ( i> DEPTH-count ) begin
                        mem[i] <= mem[i-1];
                    end
                end

                mem[DEPTH-count] <= w_data;

                // one read and one write so no counter update

                
            end

            default : begin
                // hold current state
            end
        endcase
    end
end

endmodule
