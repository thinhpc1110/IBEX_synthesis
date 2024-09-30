module dmem_interface(
    // input signals in core
    input [31:0] i_data_addr,
    input [31:0] i_data_wdata,
    input i_exe_wmem,
    input i_exe_mem2reg,

    // input signals from dmem
    input data_gnt_i,
    input data_rvalid_i,
    input [31:0] data_rdata_i,
    input [6:0] data_rdata_intg_i,
    input data_err_i,

    // output signals to dmem
    output [31:0] data_req_o,
    output data_we_o,
    output [3:0] data_be_o,
    output [31:0] data_addr_o,
    output [31:0] data_wdata_o,
    output [31:0] data_wdata_intg_o,

    //output signal to core
    output [31:0] o_data_rdata
);
    wire [6:0] unsused_1;
    wire unsused_2;

    assign unused_1 = data_rdata_intg_i;
    assign unsused_2 = data_err_i;

    assign data_req_o = (i_exe_mem2reg | i_exe_wmem) ? 1'b1 : 1'b0;
    assign data_we_o = i_exe_wmem;
    assign data_addr_o = i_data_addr;
    assign data_wdata_o = i_data_wdata;
    assign data_be_o = 4'b1111; // Luan enter dump output 
    
    assign o_data_rdata = (data_gnt_i & data_rvalid_i) ? data_rdata_i : 32'b0;

endmodule




