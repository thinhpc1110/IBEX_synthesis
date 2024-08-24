
set fd_sclib ../../sky130_fd_sc_hd/lib
set osu_t18lib ../../sky130_osu_sc_t18/18T_hs/lib
set_db init_lib_search_path [list $fd_sclib $osu_t18lib ]

set search_path [list "./" ]
lappend search_path $fd_sclib
lappend search_path $osu_t18lib 
lappend search_path /home/usr8/work_space/sky130_cds/synth/rtl_IBEX


set_db init_hdl_search_path $search_path


read_libs [list sky130_fd_sc_hd__tt_100C_1v80.lib sky130_osu_sc_18T_hs_tt_1P80_100C.ccs.lib]
 


set my_verilog_files [list prim_assert.sv ibex_alu.sv ibex_branch_predict.sv ibex_compressed_decoder.sv ibex_controller.sv ibex_cs_registers.sv ibex_csr.sv ibex_counter.sv ibex_decoder.sv ibex_ex_block.sv ibex_fetch_fifo.sv ibex_id_stage.sv ibex_if_stage.sv ibex_load_store_unit.sv ibex_multdiv_fast.sv ibex_multdiv_slow.sv ibex_prefetch_buffer.sv ibex_pmp.sv ibex_wb_stage.sv ibex_dummy_instr.sv ibex_core.sv] 
set my_toplevel "ibex_core"
# Enable clock gating

set_db lp_insert_clock_gating true 
set_db lp_clock_gating_prefix string
set_db design_power_effort high
# RTL power analysis

#set_db hdl_track_filename_row_col true 
#set_db lp_power_unit mW 

read_hdl -language sv  $my_verilog_files
elaborate $my_toplevel


set my_clock_pin "clk_i"
set my_clk_freq_MHz 250
set my_period [expr 1000 / $my_clk_freq_MHz]
set my_uncertainty [expr .1 * $my_period]


set find_clock $my_clock_pin
if {  $find_clock != [list] } {
    echo "Found clock!"
    set my_clk $my_clock_pin
} 

set all_in_ex_clk [remove_from_collection [all_inputs] [get_ports "clk_i"]]
set all_out [all_outputs]

read_sdc IBEX.sdc



set_db syn_generic_effort high
set_db syn_map_effort high
set_db syn_opt_effort extreme

syn_generic
syn_map
syn_opt

write_hdl > ibex.v
write_sdc > ibex.sdc
write_sdf -timescale ns -nonegchecks -recrem split -edges check_edge  -setuphold split > ibex.sdf
write_do_lec -golden_design rtl -revised_design ibex.v -top ibex_core > lec.tcl
# Report Timing
set filename [format "%s%s%s" "reports_IBEX_gating_2/" $my_toplevel "_timing.rep"]
redirect $filename { report_timing -nets -nworst 1}
# Report Area
set filename [format "%s%s%s" "reports_IBEX_gating_2/" $my_toplevel "_area.rep"]
redirect $filename { report_area}
# Report QoR
set filename [format "%s%s%s" "reports_IBEX_gating_2/" $my_toplevel "_qor.rep"]
redirect $filename { report_qor}
# Report Clocks
set filename [format "%s%s%s" "reports_IBEX_gating_2/" $my_toplevel "_clocks.rep"]
redirect $filename { report_clocks}
# Report Timing Summary
set filename [format "%s%s%s" "reports_IBEX_gating_2/" $my_toplevel "_timing_summary.rep"]
redirect $filename { report_timing_summary}
# Report Power
set filename [format "%s%s%s" "reports_IBEX_gating_2/" $my_toplevel "_power.rep"]
redirect $filename { report_power}
# Report Clock gating
set filename [format "%s%s%s" "reports_IBEX_gating_2/" $my_toplevel "_clock_gating.rep"]
redirect $filename { report_clock_gating}

exit

