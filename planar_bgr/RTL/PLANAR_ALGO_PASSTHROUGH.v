`include "DEFINE.vh"

// Zero-delay handshake only: algo_done = load_done. Default TB uses PLANAR_ALGO_BGR_IDENTITY
// (real read/write on planar SRAMs + DONE before merge_start). Swap this in TESTBENCH if you
// want merge to start immediately after load without an algorithm pass.

module PLANAR_ALGO_PASSTHROUGH(
    load_done,
    algo_done
);

input  wire load_done;
output wire algo_done;

assign algo_done = load_done;

endmodule
