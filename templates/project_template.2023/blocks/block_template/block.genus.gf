################################################################################
# Generic Flow v5.0 (February 2023)
################################################################################
#
# Copyright 2011-2023 Gennady Kirpichev (https://github.com/32xlr8/gflow.git)
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
################################################################################
# Filename: templates/project_template.2023/blocks/block_template/block.genus.gf
# Purpose:  Block-specific Genus configuration and flow steps
################################################################################

gf_info "Loading block-specific Genus steps ..."

################################################################################
# Flow options
################################################################################

# Override tasks resources
gf_set_task_options -cpu 8 -mem 15
# gf_set_task_options SynGen -cpu 8 -mem 15
# gf_set_task_options SynMap -cpu 8 -mem 15
# gf_set_task_options SynOpt -cpu 8 -mem 15

# # Specific floorplan used for physical synthesis
# FLOORPLAN_FILE=""

# # Specific MMMC file
# MMMC_FILE=/path/to/FrontendMMMC*.mmmc.tcl

# Top cell name for elaboration
ELAB_DESIGN_NAME="$DESIGN_NAME"

################################################################################
# Flow steps
################################################################################

# Commands before reading libraries
gf_create_step -name genus_pre_read_libs '

    # Verbosity level
    set_db information_level 9

    # Limit some messages
    foreach message_id {CHNM-102 CWD-17 CWD-19 CWD-36} {
        set_db message:$message_id .max_print 20
        set_db message:$message_id .screen_max_print 20
    }

    # # Timing settings
    # set_db timing_library_hold_sigma_multiplier 0.0
    # set_db timing_library_hold_constraint_corner_sigma_multiplier 0.0
'

# Read RTL files
gf_create_step -name genus_read_rtl '

    # Define directories containing HDL files
    set_db init_hdl_search_path {
        <PLACEHOLDER:../../../../../../data/hdl>
        <PLACEHOLDER:../../../../data/hdl>
    }

    # Read HDL settings
    set_db hdl_track_filename_row_col true 
    set_db hdl_error_on_logic_abstract true
    set_db hdl_error_on_blackbox true
    # set_db hdl_preserve_unused_flop true 
    # set_db hdl_preserve_unused_registers true

    # Default port values
    set_db hdl_unconnected_input_port_value 0
    set_db hdl_undriven_output_port_value 0
    set_db hdl_undriven_signal_value 0

    # # Flop settings
    # set_db optimize_constant_0_flops false
    # set_db optimize_constant_1_flops false

    # # RTL files
    # set RTL_FILES {
    #     file1.sv
    # }
    
    # # Read HDL files
    # read_hdl -define {<PLACEHOLDER:DEFINE>} <PLACEHOLDER.v>
    # read_hdl -language vhdl <PLACEHOLDER.hdl>
    # read_hdl -language sv <PLACEHOLDER.sv>
    # read_hdl -language sv <PLACEHOLDER.sv> -f <PLACEHOLDER.f>
    # read_hdl -language sv [join $RTL_FILES]
'

# Commands after design elaborated
gf_create_step -name genus_post_elaborate '
    
    # Update net and instance names
    update_names -force -max_length 1000
    update_names -force -allowed ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_
    update_names -force -inst -restricted {\[ \]} -convert_string "_"
    update_names -force -inst -restricted {\\} -convert_string ""
    update_names -force -hnet -restricted {\\} -convert_string ""
    update_names -force -hnet -restricted {\[ \]} -convert_string "_"

    # Switch to block design if elaborated from top
    if {$DESIGN_NAME != $ELAB_DESIGN_NAME} {
        write_db -all_root_attributes -to_file out/$TASK_NAME.$ELAB_DESIGN_NAME.genus.db
        create_derived_design -name $DESIGN_NAME [get_db module:$DESIGN_NAME .hinsts]
        current_design $DESIGN_NAME
        delete_obj design:$ELAB_DESIGN_NAME
        read_mmmc $MMMC_FILE
    }

    # Check if design has unresolved modules
    check_design -unresolved [get_db designs $DESIGN_NAME]

    # Check if design has missing cells
    `@genus_check_missing_cells`
'

# Commands after design initialized
gf_create_step -name genus_post_init_design '
    # set_db input_pragma_keyword {synopsys}

    # # Flop settings
    #set_db multibit_allow_unused_bits true

    # Non-scan flops insertion
    set_db use_scan_seqs_for_non_dft false

    # Report settings
    # set_db qos_report_power true 

    # Library settings
    set_db time_recovery_arcs true
    set_db timing_use_ecsm_pin_capacitance true
    set_db lef_add_power_and_ground_pins false

    # Preserve hierarchy
    set_db auto_ungroup none
    set_db print_ports_nets_preserved_for_cb true

    # Routing options
    set_db design_bottom_routing_layer <PLACEHOLDER:M1>
    set_db design_top_routing_layer <PLACEHOLDER:M10>
    set_db number_of_routing_layers <PLACEHOLDER:10>
    
    # Create discrete clock-gating logic if no ICG cells defined in libraries
    set_db lp_insert_discrete_clock_gating_logic true
    
    # Clock gating
    set_db lp_insert_clock_gating true
    set gf_clock_gating_cell [get_db base_cells {<PLACEHOLDER:CLOCK_GATING_CELL_NAME>}]
    set_db $gf_clock_gating_cell .dont_use false
    set_db current_design .lp_clock_gating_cell [get_db $gf_clock_gating_cell .name]

    # Map clock logic to specific cells
    <PLACEHOLDER> set_db map_clock_tree true
    set_db cts_buffer_cells [get_db base_cells [join {
        DCCKB*
    }]]
    set_db cts_inverter_cells [get_db base_cells [join {
        DCCKN*
    }]]
    set_db cts_clock_gating_cells [get_db base_cells [join {
        CKLHQ*
        CKLNQ*
    }]]
    set_db cts_logic_cells [get_db base_cells [join {
        CKMUX*
        CKND2*
        CKNR2*
        CKAN2*
        CKOR2*
        CKXOR2*
    }]]

    # Dont use cells
    set_dont_use <PLACEHOLDER:*> true
    set_dont_use <PLACEHOLDER:*> false
    # set_dont_use <PLACEHOLDER:CK*BWP*> true
    # set_dont_use <PLACEHOLDER:DCCK*BWP*> true
    # set_dont_use <PLACEHOLDER:DEL*BWP*> true
    # set_dont_use <PLACEHOLDER:G*BWP*> true
    # set_dont_use <PLACEHOLDER:*OPT*BWP*> true
    # set_dont_use <PLACEHOLDER:*D16?BWP*> true
    # set_dont_use <PLACEHOLDER:*D18?BWP*> true
    # set_dont_use <PLACEHOLDER:*D2?BWP*> true
    # # set_dont_use <PLACEHOLDER:*D3?BWP*> true
    # set_dont_use <PLACEHOLDER:*BWP*ULVT*> true

    # # Force to map to scan flops
    # set_db current_design .dft_scan_map_mode force_all

    # Do not verbose set_db command
    set_db set_db_verbose false

    # Stylus database access procs
    `@procs_stylus_db`
    # # Dont touch instances
    # set_db [gf_get_insts <PLACEHOLDER:pattern>] .dont_touch map_size_ok
    # set_db [gf_get_insts <PLACEHOLDER:pattern>] .dont_touch true

    # # Dont touch modules
    # set_db [gf_get_hinsts <PLACEHOLDER:pattern>] .dont_touch true
    
    # # Excluded clock gating instances
    # set_db [gf_get_insts <PLACEHOLDER:pattern>] .lp_clock_gating_exclude true

    # # Excluded clock gating modules
    # set_db [gf_get_hinsts <PLACEHOLDER:pattern>] .lp_clock_gating_exclude true

    # Default verbose set_db command
    reset_db set_db_verbose

    # # Interactive constraints
    # set_interactive_constraint_mode [get_db [get_db constraint_modes -if {.is_setup||.is_hold}] .name]
    # 
    # # Set macro latency
    # # set_clock_latency -0.000 [get_pins */CLK]
    # 
    # # Update clock gating margin
    # #set_clock_gating_check -setup 0.100

'

# Commands before generic synthesis
gf_create_step -name genus_pre_syn_gen '

    # Flow effort
    # set_db syn_generic_effort high
    
    # Report timing summary
    check_timing_intent
'

# Commands after mapping
gf_create_step -name genus_post_syn_gen '

    # # Write out LEC do file
    # write_lec_data -file_name ./out/$TASK_NAME.lec.data
    
    # # Dump reports
    # report_timing -max_paths 500 > ./reports/$TASK_NAME.tarpt
    # report_timing -lint -verbose > ./reports/$TASK_NAME.lint
    # # report_summary -directory ./reports/$TASK_NAME
'

# Commands before mapping
gf_create_step -name genus_pre_syn_map '

    # Flow effort
    # set_db syn_map_effort high
'

# Commands after mapping
gf_create_step -name genus_post_syn_map '

    # Write out LEC scripts
    write_do_lec -golden_design rtl -revised_design fv_map > ./out/$TASK_NAME.lec.do
    # write_lec_data -file_name ./out/$TASK_NAME.lec.data
    
    # # Dump reports
    # report_timing -max_paths 500 > ./reports/$TASK_NAME.tarpt
    # report_timing -lint -verbose > ./reports/$TASK_NAME.lint
    # # report_summary -directory ./reports/$TASK_NAME

    # # Write out SDF and SDC
    # foreach view [get_db analysis_views -if .is_setup] {
    #     # write_sdf -view $view -edges check_edge -interconn interconnect -nonegchecks > ./out/$TASK_NAME.[get_db $view .name].sdf
    #     write_sdc -view $view > ./out/$TASK_NAME.[get_db $view .name].sdc
    # }
    
'

# Commands before optimization
gf_create_step -name genus_pre_syn_opt '

    # Flow effort
    # set_db syn_opt_effort high
'

# Commands after optimization
gf_create_step -name genus_post_syn_opt '

    # Write out LEC scripts
    write_do_lec -golden_design rtl -revised_design ./out/$TASK_NAME.v > ./out/$TASK_NAME.lec.do
    # write_lec_data -file_name ./out/$TASK_NAME.lec.data

    # # Dump reports
    # report_timing -max_paths 500 > ./reports/$TASK_NAME.tarpt
    # report_timing -lint -verbose > ./reports/$TASK_NAME.lint
    # # report_summary -directory ./reports/$TASK_NAME
    # report_clock_gating > ./reports/$TASK_NAME.clock_gating.tarpt
    # report_power -depth 0 > ./reports/$TASK_NAME.power.tarpt
    # report_gates -power > ./reports/$TASK_NAME.power_gates.tarpt
    
    # # Write out SDF and SDC
    # foreach view [get_db [get_db analysis_views -if .is_setup] .name] {
    #     # write_sdf -view $view -edges check_edge -interconn interconnect -nonegchecks > ./out/$TASK_NAME.$view.sdf
    #     write_sdc -view $view > ./out/$TASK_NAME.$view.sdc
    # }
'
