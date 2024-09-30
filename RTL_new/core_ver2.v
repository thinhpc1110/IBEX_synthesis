module core_ver2(

    
    input clk_i, rst_ni,
    input instr_gnt_i,
    input instr_rvalid_i,
    input [31:0] instr_rdata_i,  // Data read from Imem
    input [6:0] instr_rdata_intg_i,
    input instr_err_i,
    output instr_req_o,
    output [31:0] instr_addr_o,

    input                          test_en_i,     // enable all clock gates for testing
    input                          ram_cfg_i,

    input  [31:0]                  hart_id_i,
    input  [31:0]                  boot_addr_i,

    // Data memory interface
    output                         data_req_o,
    input                          data_gnt_i,
    input                          data_rvalid_i,
    output                         data_we_o,
    output [3:0]                   data_be_o,
    output [31:0]                  data_addr_o,
    output [31:0]                  data_wdata_o,
    output [6:0]                   data_wdata_intg_o,
    input  [31:0]                  data_rdata_i,
    input  [6:0]                   data_rdata_intg_i,
    input                          data_err_i

    // // // Interrupt inputs
    // input                          irq_software_i,
    // input                          irq_timer_i,
    // input                          irq_external_i,
    // input  [14:0]                  irq_fast_i,
    // input                          irq_nm_i,       // non-maskeable interrupt

    // // Scrambling Interface
    // input                          scramble_key_valid_i,
    // input  [SCRAMBLE_KEY_W-1:0]    scramble_key_i,
    // input  [SCRAMBLE_NONCE_W-1:0]  scramble_nonce_i,
    // output                         scramble_req_o,

    // // Debug Interface
    // input                          debug_req_i,
    // output                         crash_dump_o,
    // output                         double_fault_seen_o
);

    /**** Signal Declarations ****/

    /** IF Stage **/
    // pc signals
    wire [31:0] pc_next;                              // next value for pc
    wire [31:0] if_pc;
    wire [31:0] if_p4;                                // pc+4
    /**************/

    /** ID Stage **/
    // id instr
    wire [31:0] id_instr;

    // immediate decoder signal 
    wire [31:0] imm_val; // hold immediate value from instr

    // Instruction Signals
    wire [6:0] opcode = id_instr[6:0];
    wire [4:0] rd     = id_instr[11:7];
    wire [4:0] rs1    = id_instr[19:15];
    wire [4:0] rs2    = id_instr[24:20];
    wire [2:0] funct3 = id_instr[14:12];
    wire [6:0] funct7 = id_instr[31:25];

    // pc signals
    wire [31:0] id_pc;                           // pc
    wire [31:0] id_p4;                           // pc+4
    
    wire [31:0] jalr_branch_inputb;                // output of 2:1 MUX that chooses between p4 and reg_rdata1
    wire [31:0] jal_pc;                            // pc for jal
    wire [31:0] jalr_branch_pc;                    // pc for branch or jalr

    // comparator input b
    wire [31:0] compare_inputb;

    // forward input a/b for alu
    wire [1:0] fwda, fwdb;

    // ALU Signal
    wire [4:0] aluc;
    wire [31:0] id_regdata1, id_regdata2; // outputs of 4x1 MUXs for alu inputs

    // control unit signals
    wire [1:0] pcsrc;
    wire mem2reg, wmem, aluimm, wreg, jal, jalr, signext, auipc, ls_b, ls_h, load_signext, not_stall, flush, slt_instr, compare_lt, compare_eq, compare_signed, compare_imm;
    
    // Regfile signals
    wire [31:0] reg_wdata;
    wire [31:0] reg_rdata1, reg_rdata2; // read data from reg file
    wire [31:0] dmem_mod; // modified dmem data
    /**************/
    
    /** EXE Stage **/
    wire [31:0] alu_r;
    wire [31:0] alu_inputa;
    wire [31:0] alu_inputb;
    wire [31:0] exe_data;
    wire [31:0] exe_p4;
    
    // Control signals 
    wire exe_mem2reg, exe_wmem, exe_aluimm, exe_slt_instr, exe_wreg, exe_auipc, exe_lsb, exe_lsh, exe_loadsignext, exe_jal;
    wire [4:0] exe_aluc;
    // Data signals      
    wire exe_lt;
    wire [31:0] lt_32bit; // bit 0 is exe_lt, while rest of bits are set to 0
    assign lt_32bit[31:1] = 31'b0;
    wire [4:0] exe_rd;
    wire [31:0] exe_pc, exe_dmem, exe_regdata1, exe_regdata2, exe_imm;
    /**************/

    /** MEM Stage **/
    // Control signals
    wire mem_mem2reg, mem_wmem, mem_wreg, mem_lsb, mem_lsh, mem_loadsignext;
    // Data 
    wire [4:0] mem_rd;
    wire [31:0] mem_data, mem_dmem, mod_rd_dmem;
    /**************/

    /** WB Stage **/
    wire [31:0] wb_data; // temp wire to wreg_mux
    // Control signals
    wire wb_mem2reg, wb_wreg, wb_jal;
    // Data 
    wire [4:0] wb_rd;
    wire [31:0] wb_alu, wb_dmem;
    /**************/
    wire [31:0] i_instr_c;

    /*****************************/
    wire [31:0] mod_pc;
    wire [31:0] instr_rdata;   // imem_inf  -> core

    wire [31:0] data_rdata_modified;


    /********************************************* IF STAGE *********************************************/
    /********************** PC REG *********************/
    // pc reg
    pc_reg pc_pipeline_reg(
        .i_clk(clk_i), .i_resetn(rst_ni),
        .i_we(not_stall),
        .i_pc(pc_next),
        .o_pc(if_pc)
    );
    /***********************************************/
    
    // pc modifier
    pc_modifier pc_modifier(
        .pc_in(if_pc),
        .modified_pc(mod_pc)
    );

    // imem_interface
    imem_interface imem_interface(
        .pc_addr_i(mod_pc),
        .instr_gnt_i(instr_gnt_i),
        .instr_rvalid_i(instr_rvalid_i),
        .instr_rdata_i(instr_rdata_i),
        .instr_rdata_intg_i(instr_rdata_intg_i),
        .instr_err_i(instr_err_i), 
        .instr_req_o(instr_req_o),
        .instr_addr_o(instr_addr_o),
        .instr_rdata_o(instr_rdata)
    );

    // get p4 (pc+4)
    adder p4_adder(
        .a(mod_pc), .b(32'h4), // 32-bit inputs
        .sum(if_p4)            // sum result
    );
    
    // 3:1 MUX to select next pc
    mux_3to1 next_pc_mux (
        .inputA(if_p4), .inputB(jalr_branch_pc), .inputC(jal_pc),
        .select(pcsrc),
        .selected_out(pc_next)
    ); 

    /****************************************************************************************************/
	 wire unsused_1, unsused_2;
    compressed_decoder compressed_decoder(
        .instr_i(instr_rdata),
        .instr_o(i_instr_c),
        .is_compressed_o(unused_1),
        .illegal_instr_o(unused_2)
    );
    
    /********************************************* ID STAGE *********************************************/
    /********************** IF/ID REG *********************/
    if_id_reg if_id_pipeline_reg (
        .i_clk(clk_i), .i_resetn(rst_ni),
        .i_we(not_stall),
        .i_flush(flush),
        .i_if_p4(if_p4), .i_if_pc(mod_pc), .i_if_instr(i_instr_c),
        .o_id_p4(id_p4), .o_id_pc(id_pc), .o_id_instr(id_instr)
    );
    /******************************************************/

    /********************** CONTROL UNIT **********************/
    control_unit controller(
        // from instr mem
        .i_resetn(rst_ni),
        .opcode(opcode),
        .funct3(funct3),
        .funct7(funct7),
        .rs1(rs1), .rs2(rs2),
        // from datapath
        .i_compare_lt(compare_lt), .i_compare_eq(compare_eq),
        .i_mem_wreg(mem_wreg), .i_mem_mem2reg(mem_mem2reg), .i_exe_wreg(exe_wreg), .i_exe_mem2reg(exe_mem2reg),     
        .i_mem_rd(mem_rd), .i_exe_rd(exe_rd),
        // to datapath
        .o_not_stall(not_stall), .o_flush(flush),
        .aluc(aluc),
        .pcsrc(pcsrc),
        .o_fwda(fwda), .o_fwdb(fwdb),
        .o_wmem(wmem), .o_wreg(wreg),
        .mem2reg(mem2reg), .aluimm(aluimm), .jal(jal), .jalr(jalr), .signext(signext), .auipc(auipc), .ls_b(ls_b), .ls_h(ls_h), .load_signext(load_signext), .slt_instr(slt_instr), .compare_signed(compare_signed), .compare_imm(compare_imm)
    );
    /**********************************************************/

    /********************** COMPARE UNIT **********************/
    assign compare_inputb = compare_imm ? imm_val : id_regdata2;

    comparator compare_unit (
        .a(id_regdata1), .b(compare_inputb), .unsigned_op(~compare_signed),
        .o_a_lt_b(compare_lt), .o_a_eq_b(compare_eq) // output a less-than b and a equal-to b
    );
    /**********************************************************/
    
    /********************** IMMEDIATE DECODER **********************/
    // Get immediate value based on opcode 
    imm_decode immediate_decoder (
        .i_instr(id_instr),
        .i_opcode(opcode),
        .i_signext(signext),
        .o_imm_val(imm_val)
    );
    /**************************************************************/

    // jal pc 
    adder jal_pc_adder (
        .a(imm_val), .b(id_pc),
        .sum(jal_pc)
    ); 

    // Inputb for adder
    assign jalr_branch_inputb = jalr ? id_regdata1 : id_pc; 

    // add imm to pc (branch) or reg_data1 (jalr). 
    adder br_jalr_adder (  
        .a(imm_val), .b(jalr_branch_inputb),
        .sum(jalr_branch_pc)
    );

    // 4x1 MUXs for data forwarding
    mux_4to1 fwda_mux (
        .inputA(reg_rdata1), .inputB(exe_data), .inputC(mem_data), .inputD(mod_rd_dmem),
        .select(fwda),
        .selected_out(id_regdata1)
    );

    mux_4to1 fwdb_mux (
        .inputA(reg_rdata2), .inputB(exe_data), .inputC(mem_data), .inputD(mod_rd_dmem),
        .select(fwdb),
        .selected_out(id_regdata2)
    );
    /****************************************************************************************************/


    /********************************************* EXE STAGE ********************************************/
    /********************** ID/EXE REG *********************/
    id_exe_reg id_exe_pipeline_reg (
        .i_clk(clk_i), .i_resetn(rst_ni),
        // Control signals from ID stage
        .i_id_mem2reg(mem2reg), .i_id_wmem(wmem), .i_id_aluc(aluc), .i_id_aluimm(aluimm), .i_id_slt_instr(slt_instr), .i_id_wreg(wreg), .i_id_jal(jal), .i_id_auipc(auipc), .i_id_lsb(ls_b), .i_id_lsh(ls_h), .i_id_loadsignext(load_signext),
        // Data from ID stage 
        .i_id_lt(compare_lt),          
        .i_id_pc(id_pc), .i_id_regdata1(id_regdata1), .i_id_regdata2(id_regdata2), .i_id_rd(rd), .i_id_imm(imm_val), .i_id_p4(id_p4),
        // Control signals to EXE stage
        .o_exe_mem2reg(exe_mem2reg), .o_exe_wmem(exe_wmem), .o_exe_aluc(exe_aluc), .o_exe_aluimm(exe_aluimm), .o_exe_slt_instr(exe_slt_instr), .o_exe_wreg(exe_wreg), .o_exe_auipc(exe_auipc), .o_exe_lsb(exe_lsb), .o_exe_lsh(exe_lsh), .o_exe_loadsignext(exe_loadsignext), .o_exe_jal(exe_jal),
        // Data to EXE stage
        .o_exe_pc(exe_pc), .o_exe_regdata1(exe_regdata1), .o_exe_regdata2(exe_regdata2), .o_exe_rd(exe_rd), .o_exe_imm(exe_imm), .o_exe_p4(exe_p4), .o_exe_lt(exe_lt)
    );
    /********************** ALU **********************/
    // input a mux
    assign alu_inputa = exe_auipc ? (exe_pc-4) : exe_regdata1;
    
    // input b mux
    assign alu_inputb = exe_aluimm ? exe_imm : exe_regdata2;
    
    alu alu_unit(
        .a(alu_inputa), .b(alu_inputb),
        .aluc(exe_aluc),
        .result(alu_r)
    );

    assign lt_32bit[0] = exe_lt;
    // mux to select alu output, slt compare result, or pc+4 as write-back data
    mux_3to1 exe_data_mux (
        .inputA(alu_r), .inputB(lt_32bit), .inputC(exe_p4),
        .select({exe_jal, exe_slt_instr}),
        .selected_out(exe_data)
    );
    /*************************************************/
    
    /********************** STORE MODIFIER **********************/
    store_modifier store_unit (
        .sb(exe_lsb), .sh(exe_lsh), 
        .data_in(exe_regdata2),
        .data_out(exe_dmem)
    );
    /************************************************************/
    /****************************************************************************************************/
    

    /********************************************* MEM STAGE ********************************************/
    /********************** EXE/MEM REG *********************/
    exe_mem_reg exe_mem_pipeline_reg (
        .i_clk(clk_i), .i_resetn(rst_ni),
        // Control signals from EXE stage
        .i_exe_mem2reg(exe_mem2reg), .i_exe_wmem(exe_wmem), .i_exe_wreg(exe_wreg), .i_exe_lsb(exe_lsb), .i_exe_lsh(exe_lsh), .i_exe_loadsignext(exe_loadsignext),
        // Data from EXE stage 
        .i_exe_data(exe_data), .i_exe_rd(exe_rd), .i_exe_dmem(exe_dmem), 
        // Control signals to MEM stage
        .o_mem_mem2reg(mem_mem2reg), .o_mem_wmem(mem_wmem), .o_mem_wreg(mem_wreg), .o_mem_lsb(mem_lsb), .o_mem_lsh(mem_lsh), .o_mem_loadsignext(mem_loadsignext),
        // Data to MEM stage
        .o_mem_data(mem_data), .o_mem_rd(mem_rd), .o_mem_dmem(mem_dmem)
    );
    /***************************DMEM INTERFACE*****************************/
    dmem_interface dmem_interface(
        .i_data_addr(mem_data),
        .i_data_wdata(mem_dmem),
        .i_exe_wmem(mem_wmem),
        .i_exe_mem2reg(mem_mem2reg),

        .data_gnt_i(data_gnt_i),
        .data_rvalid_i(data_rvalid_i),
        .data_rdata_i(data_rdata_i),
        .data_rdata_intg_i(data_rdata_intg_i),
        .data_err_i(data_err_i),

    // output signals to dmem
        .data_req_o(data_req_o),
        .data_we_o(data_we_o),
        .data_be_o(data_be_o),
        .data_addr_o(data_addr_o),
        .data_wdata_o(data_wdata_o),
        .data_wdata_intg_o(data_wdata_intg_o),

    //output signal to core
        .o_data_rdata(data_rdata_modified)
    );


    /*********************** LOAD MODIFIER **********************/
    load_modifier load_unit (
        .lb(mem_lsb), .lh(mem_lsh), .load_signext(mem_loadsignext),
        .data_in(data_rdata_modified),
        .data_out(mod_rd_dmem)
    );
    /************************************************************/
    /****************************************************************************************************/


    /********************************************* WB STAGE ********************************************/
    /********************** MEM/WB REG *********************/
    mem_wb_reg mem_wb_pipeline_reg (
        .i_clk(clk_i), .i_resetn(rst_ni),
        // Control signals from MEM stage
        .i_mem_mem2reg(mem_mem2reg), .i_mem_wreg(mem_wreg), 
        // Data from MEM stage
        .i_mem_data(mem_data), .i_mem_rd(mem_rd), .i_rd_dmem(mod_rd_dmem),
        // Control signals to WB stage
        .o_wb_mem2reg(wb_mem2reg), .o_wb_wreg(wb_wreg),
        // Data to WB stage
        .o_wb_data(wb_data), .o_wb_rd(wb_rd), .o_wb_dmem(wb_dmem)
    );
    /*******************************************************/

    /********************** REGFILE **********************/
    assign reg_wdata = wb_mem2reg ? wb_dmem : wb_data;
    wire [31:0] core_reg_file [0:31]; // Huy debug
    regfile register_file (
        .clk(~clk_i), .resetn(rst_ni),
        .rs1(rs1), .rs2(rs2), .rd(wb_rd), // register source 1, 2; register destination
        .reg_write(wb_wreg),
        .write_data(reg_wdata),
        .read_data1(reg_rdata1), .read_data2(reg_rdata2),
        .core_reg_file(core_reg_file)
    );
    /*****************************************************/
    /****************************************************************************************************/
    

    /********************** OUTPUTS **********************/
    // assign data_we_o = mem_wmem;
    // assign data_addr_o = mem_data;
    // assign data_wdata_o = mem_dmem; 
    /*****************************************************/

endmodule

