module imem_interface(
  input [31:0] pc_addr_i,
  input  instr_gnt_i,
  input  instr_rvalid_i,
  input [31:0] instr_rdata_i,  // Data read from Imem
  input [6:0] instr_rdata_intg_i,
  input instr_err_i,

  output instr_req_o,
  output [31:0] instr_addr_o,
  output [31:0] instr_rdata_o // Data send into core
);

wire [31:0] unused_intg_i;
wire unused_err_i;

// unused input signal
assign unused_intg_i = instr_rdata_intg_i;
assign unused_err_i = instr_err_i;

assign instr_req_o = 1'b1;
assign instr_addr_o = pc_addr_i;
assign instr_rdata_o = (instr_gnt_i & instr_rvalid_i) ? instr_rdata_i : 32'b0;

endmodule




