################################################################################
# Generic Flow v5.5.3 (October 2025)
################################################################################
#
# Copyright 2011-2025 Gennady Kirpichev (https://github.com/32xlr8/gflow.git)
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
# Filename: templates/project.2025/blocks/template/block.genus.gf
# Purpose:  Block-specific Genus configuration and flow steps
################################################################################
# gf_source -once "../../project.modus.gf"
# gf_source -once "./block.modus.gf"

gf_info "Loading block-specific Genus steps ..."

################################################################################
# Flow options
################################################################################

# # Override all tasks resources
# gf_set_task_options -cpu 8 -mem 15

# # Override resources for interactive tasks
# gf_set_task_options DebugGenus -cpu 4 -mem 10

# # Override resources for batch tasks
# gf_set_task_options SynGen -cpu 8 -mem 15
# gf_set_task_options SynMap -cpu 8 -mem 15
# gf_set_task_options SynOpt -cpu 8 -mem 15
gf_set_task_options ReportSynGen -cpu 4 -mem 10
gf_set_task_options ReportSynMap -cpu 4 -mem 10
gf_set_task_options ReportSynOpt -cpu 4 -mem 10

# Limit simultaneous tasks count
gf_set_task_options ReportSynGen ReportSynMap ReportSynOpt -group Reports -parallel 1
# gf_set_task_options SynGen SynMap SynOpt -group Heavy -parallel 1

# # Disable not needed tasks
# gf_set_task_options -disable SynGen
# gf_set_task_options -disable SynMap
# gf_set_task_options -disable SynOpt
# gf_set_task_options -disable ReportSynGen
# gf_set_task_options -disable ReportSynMap
# gf_set_task_options -disable ReportSynOpt

################################################################################
# Flow variables
################################################################################

# Top cell name for elaboration
ELAB_DESIGN_NAME="$DESIGN_NAME"

# # Physical/logical synthesis
# PHYSICAL_MODE=Y
# PHYSICAL_MODE=N

################################################################################
# Synthesis flow steps
################################################################################

# Design variables
gf_create_step -name genus_gconfig_design_variables '

    # Choose analysis views patterns:
    # - {mode process voltage temperature rc_corner timing_check}
    set MMMC_VIEWS [regsub -all -line {^\s*\#.*\n} {
        {func ss 0p900v m40 cwt s}
    } {}]
'

# MMMC and OCV settings
gf_create_step -name genus_gconfig_design_settings '
    <PLACEHOLDER> Review frontend settings for synthesis

    # Design variables
    `@genus_gconfig_design_variables`
    
    # Choose standard cell libraries:
    # - nldm_libraries - NLDM (Liberty) + CDB (Celtic) files used for fast runtime
    # - ecsm_libraries - ECSM (Liberty) + AOCV/SOCV files used for precise delay calculation
    # - ccs_libraries - CCS (Liberty) + AOCV/SOCV files used for precise delay calculation
    # - lvf_libraries - LVF (Liberty) files used for most precise delay calculation
    gconfig::enable_switches nldm_libraries
    
    # Choose separate variation libraries (optional with ecsm_libraries or ccs_libraries):
    # - aocv_libraries - AOCV (advanced, SBOCV)
    # - socv_libraries - SOCV (statistical)
    # gconfig::enable_switches aocv_libraries
   
    # Choose derating scenarios (additional variations):
    # - flat_derates - used with NLDM (see process node documentation)
    # - no_derates - zero derates (optimistic for prototyping mode)
    # - user_derates - same as flat_derates, but user-specified values used (customize below)
    # - vt_derates - used with ESCM/CCS if additional Voltage/Temparature derates required (see standard cell documentation, customize IR-drop below)
    # - default_uncertainty - set clock uncertainty ignoring one set in SDC files
    gconfig::enable_switches flat_derates default_uncertainty

    # # Set IR-drop value for voltage and temperature OCV derates (when vt_derate switch enabled)
    # # It is recommended to set 40% of Static IR for setup and 80% for hold
    # <PLACEHOLDER>
    # gconfig::add_section {
    #     -when vt_derates {
    #         -views {* * * * * s} {$voltage_drop 20}
    #         -views {* * * * * h} {$voltage_drop 40}
    #     }
    # }

    # # Set user-specific derate values (when user_derates switch enabled)
    # gconfig::add_section {
    #     -when user_derates {
    #         -views {* * * * * s} {$cell_data +10.0}
    #     }
    # }
    
    # # Set PLL jitter value in ps
    # <PLACEHOLDER>
    # gconfig::add_section {
    #     -when default_uncertainty {
    #         $jitter 25
    #     }
    # }
    
    # # Optional: set user-specific clock uncertainty values for all clocks
    # <PLACEHOLDER>
    # gconfig::add_section {
    #     -when default_uncertainty {
    #         -views {* ss 0p900v * * *} {$process_uncertainty 0 $setup_uncertainty 100 $hold_uncertainty 50}
    #         -views {* ff 1p100v * * *} {$process_uncertainty 0 $setup_uncertainty 100 $hold_uncertainty 50}
    #     }
    # }
'

# Commands before reading libraries
gf_create_step -name genus_pre_read_libs '

    # Verbosity level (1 - default, 3 - common, 11 - max)
    set_db information_level 3

    # Limit specific messages
    foreach message_id {CHNM-102 CWD-17 CWD-19 CWD-36} {
        set_db message:$message_id .max_print 20
        set_db message:$message_id .screen_max_print 20
    }
    
    # Limit all info and warning messages on the screen
    set_db set_db_verbose false
    set_db [get_db messages -if .severity==Info] .screen_max_print 0
    set_db [get_db messages -if .severity==Warning] .screen_max_print 20
    reset_db set_db_verbose
    
    # Unlimit specific messages in log file
    foreach message_id {CDFG-564} {
        set_db message:$message_id .max_print infinity
    }
    
    # # Timing settings
    # set_db timing_library_hold_sigma_multiplier 0.0
    # set_db timing_library_hold_constraint_corner_sigma_multiplier 0.0
'

# Read RTL files
gf_create_step -name genus_read_rtl '

    # Define directories containing HDL files
    set RTL_SEARCH_PATHS {`$RTL_SEARCH_PATHS -optional`}
    set_db init_hdl_search_path [join $RTL_SEARCH_PATHS]

    # RTL defines in block.common.gf
    set RTL_DEFINES [join {`$RTL_DEFINES -optional`}]

    # RTL files defined in block.common.gf
    set RTL_FILES [join {`$RTL_FILES -optional`}]

    # RTL files list defined in block.common.gf
    set RTL_FILES_LIST [join {`$RTL_FILES_LIST -optional`}]

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

    # Naming conventions
    # set_db hdl_parameterize_module_name false
    # set_db hdl_bus_wire_naming_style "%s[%d]"
    set_db hdl_array_naming_style "%s_%d"
    set_db hdl_generate_index_style "%s_%d"
    set_db hdl_instance_array_naming_style "%s_%d"
    set_db hdl_parameter_naming_style ""
    set_db uniquify_naming_style "%s_%d"
    # set_db bus_naming_style "%s[%d]"

    # # Flop settings
    # set_db optimize_constant_0_flops false
    # set_db optimize_constant_1_flops false
    # set_db optimize_merge_flops false

    # Read system verilog files
    if {[llength $RTL_FILES] > 0} {
        read_hdl -define $RTL_DEFINES -language sv $RTL_FILES
    }

    # Read system verilog files list
    foreach file $RTL_FILES_LIST {
        read_hdl -define $RTL_DEFINES -language sv -f $file
    }
    
    # # Custom set of files
    # <PLACEHOLDER>
    # read_hdl -define {DEFINE} top.v
    # read_hdl -language sv top.sv
    # read_hdl -language vhdl top.hdl
    # read_hdl -language sv top.sv -f file_list.f
'

# Commands after design elaborated
gf_create_step -name genus_post_elaborate '
    
    # Update net and instance names
    update_names -force -inst -hnet -restricted {\[ \.} -convert_string "_"
    update_names -force -inst -hnet -restricted {\] \\} -convert_string ""
    # update_names -force -allowed ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_
    # update_names -force -max_length 1000

    # Switch to block design if elaborated from top
    if {$DESIGN_NAME != $ELAB_DESIGN_NAME} {
        write_db -all_root_attributes -to_file out/$TASK_NAME.$ELAB_DESIGN_NAME.genus.db
        create_derived_design -name $DESIGN_NAME [get_db module:$DESIGN_NAME .hinsts]
        current_design $DESIGN_NAME
        delete_obj design:$ELAB_DESIGN_NAME
        read_mmmc ./in/$TASK_NAME.mmmc.tcl
    }

    # Check if design has unresolved modules
    check_design -unresolved [get_db designs $DESIGN_NAME]

    # Blocks statistics reports
    `@genus_procs_reports`
    gf_report_hdl_parameters ./reports/$TASK_NAME.hdl_parameters.rpt
    gf_report_hinst_flops_statistics ./reports/$TASK_NAME.flops.rpt

    # Check if design has missing cells
    `@genus_check_missing_cells`
'

# Commands after design initialized
gf_create_step -name genus_post_init_design '
    <PLACEHOLDER> Review frontend settings for synthesis

    # set_db input_pragma_keyword {synopsys}

    # # Flop settings
    # set_db multibit_allow_unused_bits true

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
    # <PLACEHOLDER>
    # set_db design_bottom_routing_layer M2
    # set_db design_top_routing_layer M8
    set_db number_of_routing_layers 8
    
    # Create discrete clock-gating logic if no ICG cells defined in libraries
    set_db lp_insert_discrete_clock_gating_logic true
    
    # Clock gating
    set_db lp_insert_clock_gating true
    <PLACEHOLDER>
    set gf_clock_gating_cell [get_db base_cells {CLOCK_GATING_CELL_NAME}]
    set_db $gf_clock_gating_cell .dont_use false
    set_db current_design .lp_clock_gating_cell [get_db $gf_clock_gating_cell .name]

    # # Map clock logic to specific cells
    # <PLACEHOLDER>
    # set_db map_clock_tree true
    # set_db cts_buffer_cells [get_db base_cells [join {
    #     DCCKB*
    # }]]
    # set_db cts_inverter_cells [get_db base_cells [join {
    #     DCCKN*
    # }]]
    # set_db cts_clock_gating_cells [get_db base_cells [join {
    #     CKLHQ*
    #     CKLNQ*
    # }]]
    # set_db cts_logic_cells [get_db base_cells [join {
    #     CKMUX*
    #     CKND2*
    #     CKNR2*
    #     CKAN2*
    #     CKOR2*
    #     CKXOR2*
    # }]]

    # # Clock and special cells
    <PLACEHOLDER>
    # set_dont_use CK*BWP* true
    # set_dont_use DCCK*BWP* true
    # set_dont_use DEL*BWP* true
    # set_dont_use G*BWP* true
    # set_dont_use *OPT*BWP* true
    # set_dont_use *BWP*LVT* true
    # set_dont_use *BWP*ULVT* true

    # # Weak/strong drivers
    <PLACEHOLDER>
    # set_dont_use *D0BWP* true
    # set_dont_use *D0P*BWP* true
    # set_dont_use *D16BWP* true
    # set_dont_use *D17BWP* true
    # set_dont_use *D18BWP* true
    # set_dont_use *D19BWP* true
    # set_dont_use *D2?BWP* true
    # # set_dont_use *D3?BWP* true

    # # Problematic cells
    <PLACEHOLDER>
    # set_dont_use *MASK* true

    # Remove dont use attribute for clock gating cell
    set_db $gf_clock_gating_cell .dont_use false

    # # Force to map to scan flops
    # set_db current_design .dft_scan_map_mode force_all

    # Do not verbose set_db command
    set_db set_db_verbose false

    # Stylus database access procs
    `@procs_stylus_db`
    
    # # Dont touch instances
    # <PLACEHOLDER>
    # set_db [gf_get_insts pattern] .dont_touch map_size_ok
    # set_db [gf_get_insts pattern] .dont_touch true

    # # Dont touch modules
    # <PLACEHOLDER>
    # set_db [gf_get_hinsts pattern] .dont_touch true
    
    # # Excluded clock gating instances
    # <PLACEHOLDER>
    # set_db [gf_get_insts pattern] .lp_clock_gating_exclude true

    # # Excluded clock gating modules
    # <PLACEHOLDER>
    # set_db [gf_get_hinsts pattern] .lp_clock_gating_exclude true

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

    # # Write intermediate database
    # write_db ./out/$TASK_NAME.intermediate.genus.db
'

# Commands before generic synthesis
gf_create_step -name genus_pre_syn_gen '

    # Flow effort
    # set_db syn_generic_effort high
'

# Commands after mapping
gf_create_step -name genus_post_syn_gen '

    # # Write out LEC do file
    # write_lec_data -file_name ./out/$TASK_NAME.lec.data
'

# Commands before mapping
gf_create_step -name genus_pre_syn_map '

    # Flow effort
    # set_db syn_map_effort high
'

# Commands after mapping
gf_create_step -name genus_post_syn_map '

    # Blocks statistics reports
    `@genus_procs_reports`
    gf_report_hinst_flops_statistics ./reports/$TASK_NAME.flops.rpt

    # Write out LEC scripts
    write_do_lec -golden_design rtl -revised_design fv_map > ./out/$TASK_NAME.lec.do
    # write_lec_data -file_name ./out/$TASK_NAME.lec.data
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
'

################################################################################
# Report flow steps
################################################################################

# Post-generic synthesis Genus reports
gf_create_step -name genus_design_reports_post_syn_gen '
    write_reports -directory ./reports/$TASK_NAME -tag summary
    
    redirect ./reports/$TASK_NAME/datapath.rpt {report_dp}
    redirect ./reports/$TASK_NAME/logic_levels_histogram.rpt {report_logic_levels_histogram -bars 10 -skip_buffer -skip_inverter -threshold 10 -detail}
    
    redirect ./reports/$TASK_NAME/check_floorplan.rpt {check_floorplan -detailed}
    redirect ./reports/$TASK_NAME/check_timing_intent.rpt {check_timing_intent -verbose}
    redirect ./reports/$TASK_NAME/check_design.rpt {check_design -all [get_db current_design .name]}
    
    redirect ./reports/$TASK_NAME/timing.500.tarpt {report_timing -fields {+ timing_point arc cell delay transition fanout load} -max_paths 500}
    redirect ./reports/$TASK_NAME/timing.end.tarpt {report_timing -path_type endpoint -max_paths 1000}
    redirect ./reports/$TASK_NAME/timing.lint.tarpt {report_timing -lint -verbose}

    redirect ./reports/$TASK_NAME/messages.rpt {report_messages}
'

# Post-mapping Genus reports
gf_create_step -name genus_design_reports_post_syn_map '
    write_reports -directory ./reports/$TASK_NAME -tag summary
    
    redirect ./reports/$TASK_NAME/datapath.rpt {report_dp}
    redirect ./reports/$TASK_NAME/logic_levels_histogram.rpt {report_logic_levels_histogram -bars 10 -skip_buffer -skip_inverter -threshold 10 -detail}
    
    redirect ./reports/$TASK_NAME/check_floorplan.rpt {check_floorplan -detailed}
    redirect ./reports/$TASK_NAME/check_timing_intent.rpt {check_timing_intent -verbose}
    redirect ./reports/$TASK_NAME/check_design.rpt {check_design -all [get_db current_design .name]}
    
    redirect ./reports/$TASK_NAME/timing.500.tarpt {report_timing -fields {+ timing_point arc cell delay transition fanout load} -max_paths 500}
    redirect ./reports/$TASK_NAME/timing.end.tarpt {report_timing -path_type endpoint -max_paths 1000}
    redirect ./reports/$TASK_NAME/timing.lint.tarpt {report_timing -lint -verbose}

    redirect ./reports/$TASK_NAME/clock_gating.tarpt {report_clock_gating}

    redirect ./reports/$TASK_NAME/power.modules.tarpt {report_power -levels 1}
    redirect ./reports/$TASK_NAME/power.gates.tarpt {report_gates -power}

    # Write out SDF and SDC
    foreach view [get_db [get_db analysis_views -if .is_setup] .name] {
        write_sdc -view $view > ./out/$TASK_NAME.$view.sdc
        write_sdf -view $view -edges check_edge -interconn interconnect -nonegchecks > ./out/$TASK_NAME.$view.sdf
    }

    redirect ./reports/$TASK_NAME/messages.rpt {report_messages}
'
