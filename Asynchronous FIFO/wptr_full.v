`timescale 1ns/1ps

module wptr_full #(
    parameter ADDRSIZE = 4)
    (
    output reg wfull,
    output reg [ADDRSIZE:0] wptr,
    output [ADDRSIZE-1:0] waddr,
    input [ADDRSIZE:0] wq2_rptr,
    input wclk,wrst_n,winc
);

    reg [ADDRSIZE:0] wbin,wbin_next,wgray_next;
    
    always @(posedge wclk or negedge wrst_n)
        if(!wrst_n) {wbin,wptr} <= 0;
        else        {wbin,wptr} <= {wbin_next,wgray_next};

    // GRAYSTYLE2 pointer

    assign waddr = wbin[ADDRSIZE-1:0];

    assign wbin_next  = wbin +(winc & ~wfull);
    assign wgray_next = wbin_next ^ (wbin_next >> 1);

    // FIFO full when first two MSB are different and rest are same

    assign wfull_val = (wgray_next[ADDRSIZE:0] == {~wq2_rptr[ADDRSIZE:ADDRSIZE-1],wq2_rptr[ADDRSIZE-2:0]});

    always @(posedge wclk or negedge wrst_n)
        if (!wrst_n) wfull <= 1'b0;
        else         wfull <= wfull_val;
endmodule