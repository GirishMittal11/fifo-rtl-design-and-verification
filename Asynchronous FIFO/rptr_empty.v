`timescale 1ns/1ps

module rptr_empty #(
    parameter ADDRSIZE = 4)
    (
    output reg rempty,
    output reg [ADDRSIZE:0] rptr,
    output [ADDRSIZE-1:0] raddr,
    input [ADDRSIZE:0] rq2_wptr,
    input rclk,rrst_n,rinc
);
 
    reg [ADDRSIZE:0] rbin,rbin_next,rgray_next;

    always @(posedge rclk or negedge rrst_n)
        if (!rrst_n) {rbin,rptr} <= 0;
        else         {rbin,rptr} <= {rbin_next,rgray_next};

    // GRAYSTYLE2 pointer

    assign raddr = rbin[ADDRSIZE-1:0];

    assign rbin_next = rbin + (rinc & ~rempty);
    assign rgray_next = (rbin_next >> 1) ^ rbin_next;

    // FIFO empty when the next rptr == synchronized wptr or on reset

    assign rempty_val = (rgray_next == rq2_wptr);

    always @(posedge rclk or negedge rrst_n)
        if (!rrst_n) rempty <= 1'b1;
        else         rempty <= rempty_val;
endmodule