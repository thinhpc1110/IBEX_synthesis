create_clock -name clk_i -period $my_period [get_ports $my_clk]
set_clock_uncertainty $my_uncertainty [get_clocks $my_clk]
set_input_transition .01 [all_inputs]
set_input_delay -max 0.008 [get_ports $all_in_ex_clk] -clock [get_clocks $my_clk]
set_output_delay -max 0.008 [get_ports $all_out] -clock [get_clocks $my_clk]
set_load [expr [load_of sky130_fd_sc_hd__tt_100C_1v80/sky130_fd_sc_hd__dfxtp_1/D] * 1] [all_outputs]
set_driving_cell  -lib_cell sky130_fd_sc_hd__dfxtp_1 -pin Q $all_in_ex_clk
