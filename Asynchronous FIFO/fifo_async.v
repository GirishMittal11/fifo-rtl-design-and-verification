`timescale 1ns/1ps

module fifo_async #(
    parameter DATA_WIDTH = 8,
    parameter ADDRSIZE = 4)
    (
        output [DATA_WIDTH-1:0] r_data,
        output rempty,wfull,
        input [DATA_WIDTH-1:0] w_data,
        input wclk,winc,wrst_n,
        input rclk,rinc,rrst_n

    );

    wire [ADDRSIZE:0] wptr,rptr,rq2_wptr,wq2_rptr;
    wire [ADDRSIZE-1:0] waddr,raddr;

    sync_r2w #(.ADDRSIZE(ADDRSIZE)) sync_r2w(
        .wq2_rptr(wq2_rptr),
        .rptr(rptr),
        .wclk(wclk),
        .wrst_n(wrst_n)
    );

    sync_w2r #(.ADDRSIZE(ADDRSIZE)) sync_w2r(
        .rq2_wptr(rq2_wptr),
        .wptr(wptr),
        .rclk(rclk)
    );
    fifo_mem #(.DATA_WIDTH(DATA_WIDTH),.ADDRSIZE(ADDRSIZE)) fifo_mem(
        .r_data(r_data),
        .w_data(w_data),
        .waddr(waddr),
        .raddr(raddr),
        .wclken(winc),
        .wclk(wclk),
        .wfull(wfull)
    );

    wptr_full #(.ADDRSIZE(ADDRSIZE)) wptr_full(
        .wfull(wfull),
        .wptr(wptr),
        .waddr(waddr),
        .wq2_rptr(wq2_rptr),
        .winc(winc),
        .wclk(wclk),.wrst_n(wrst_n)
    );

    rptr_empty #(.ADDRSIZE(ADDRSIZE)) rptr_empty(
        .rempty(rempty),
        .rptr(rptr),
        .raddr(raddr),
        .rq2_wptr(rq2_wptr),
        .rclk(rclk),.rrst_n(rrst_n),.rinc(rinc)
    );

endmodule