################################################################################
# Generic Flow v5.1 (May 2023)
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
# Filename: templates/project_template.2023/blocks/block_template/block.voltus.gf
# Purpose:  Block-specific Voltus configuration and flow steps
################################################################################

gf_info "Loading block-specific Voltus steps ..."

# # Override all tasks resources
# gf_set_task_options -cpu 8 -mem 15

# # Override resources for tasks
gf_set_task_options '*PGV' -cpu 1 -mem 15
# gf_set_task_options 'Debug*' -cpu 4 -mem 10
# gf_set_task_options '*Power' -cpu 8 -mem 15
# gf_set_task_options '*Rail' -cpu 8 -mem 15
# gf_set_task_options SignalEM -cpu 8 -mem 15

# Limit simultaneous tasks count
gf_set_task_options '*PGV' -group PGV -parallel 1
# gf_set_task_options '*Power' '*Rail' SignalEM -group Heavy -parallel 1

# Disable not needed PGV generation tasks
# gf_set_task_options -disable TechPGV
gf_set_task_options -disable CellsPGV
gf_set_task_options -disable MacrosPGV

# # Disable not needed power analysis tasks
# gf_set_task_options -disable StaticPower
# gf_set_task_options -disable StaticRail
gf_set_task_options -disable DynamicPower
gf_set_task_options -disable DynamicRail
gf_set_task_options -disable SignalEM

################################################################################
# Flow variables
################################################################################

# Static and dynamic power analysis scenarios
POWER_SCENARIOS='
    Switching activity 0.2
    Switching activity 0.4
    VCD: Default mode
'

# # Select scenario automatically
# POWER_SCENARIO="Switching activity 0.4"

################################################################################
# Flow steps
################################################################################

# MMMC and OCV settings
gf_create_step -name voltus_gconfig_design_settings '
    <PLACEHOLDER> Review signoff settings for power analysis
    
    # Choose analysis views patterns:
    # - {mode process voltage temperature rc_corner timing_check}
    #   - PGV_RC_CORNER - PGV generation extraction corner (worst RC parasitics)
    #   - SIGNAL_SPEF_CORNER - Signal nets extraction corner (best RC parasitics)
    #   - POWER_SPEF_CORNER - Power grid extraction corner (worst C parasitics)
    #   - STATIC_POWER_VIEW - Static power analysis view (worst cells currents)
    #   - DYNAMIC_POWER_VIEW - Dynamic power analysis view (worst cells currents)
    #   - STATIC_RAIL_VIEW - Static rail analysis view (worst RC parasitics)
    #   - DYNAMIC_RAIL_VIEW - Dynamic rail analysis view (worst RC parasitics)
    #   - SIGNAL_EM_VIEW - Signal electromigration analysis view (worst cells currents, worst C parasitics)
    
    set PGV_RC_CORNER {* * * 125 rcw *}
            
    set SIGNAL_SPEF_CORNER {* * * m40 rcb *}
    set POWER_SPEF_CORNER {* * * 125 cw *}

    set STATIC_POWER_VIEW {func ff 1p100v 125 cw h}
    set DYNAMIC_POWER_VIEW {func ff 1p100v 125 cw h}

    set STATIC_RAIL_VIEW {func ss 0p900v 125 rcw h}
    set DYNAMIC_RAIL_VIEW {func ss 0p900v 125 rcw h}

    set SIGNAL_EM_VIEW {func ff 1p100v 125 cw h}

    # Choose standard cell libraries:
    # - nldm_libraries - NLDM (Liberty) + CDB (Celtic) files used for fast runtime
    # - ecsm_libraries - ECSM (Liberty) + AOCV/SOCV files used for precise delay calculation
    # - ccs_libraries - CCS (Liberty) + AOCV/SOCV files used for precise delay calculation
    # - lvf_libraries - LVF (Liberty) files used for most precise delay calculation
    # - ecsm_p_libraries - ECSM-P (Liberty) files used for precise power calculation
    # - ccs_p_libraries - CCS-P (Liberty) files used for precise power calculation
    gconfig::enable_switches ccs_p_libraries
   
    # Choose derating scenarios (additional variations):
    # - flat_derates - used with NLDM (see process node documentation)
    # - no_derates - zero derates (optimistic for prototyping mode)
    # - user_derates - same as flat_derates, but user-specified values used (customize below)
    # - vt_derates - used with ESCM/CCS if additional Voltage/Temparature derates required (see standard cell documentation, customize IR-drop below)
    gconfig::enable_switches no_derates
'

# Commands after design initialized
gf_create_step -name voltus_pre_init_variables '
    set DESIGN_NAME {`$DESIGN_NAME`}

    # Power/ground pins with voltage values pairs
    <PLACEHOLDER>
    set VOLTUS_POWER_NETS_PAIRS {
        VDD 0.000
    }
    set VOLTUS_GROUND_NETS_PAIRS {
        VSS 0
    }
    
    # IR-drop thresholds
    set IR_THRESHOLD_STATIC 0.015
    set IR_THRESHOLD_DYNAMIC 0.050
'

# Commands after design initialized
gf_create_step -name voltus_post_init_variables '

    # Filler and decap cells for PGV
    <PLACEHOLDER>
    set PGV_FILLER_CELLS [get_db base_cells .name FILL*]
    set PGV_DECAP_CELLS [get_db base_cells .name DCAP*]

    # List of global nets to analyze taken from net pairs
    set VOLTUS_POWER_NETS {}
    set VOLTUS_GROUND_NETS {}
    foreach {net value} $VOLTUS_POWER_NETS_PAIRS {lappend VOLTUS_POWER_NETS $net}
    foreach {net value} $VOLTUS_GROUND_NETS_PAIRS {lappend VOLTUS_GROUND_NETS $net}
'

# Commands after design initialized
gf_create_step -name voltus_post_init '
    `@voltus_post_init_variables`

    # Library settings
    if {1} {
    
        # Timing analysis
        set_db timing_analysis_cppr both
        set_db timing_analysis_type ocv
        # set_db timing_cppr_threshold_ps 1

        # Additional timing analysis
        set_db timing_analysis_clock_gating true
        set_db timing_analysis_async_checks async
        set_db timing_use_latch_time_borrow false

        # General delay calculation settings
        set_db delaycal_equivalent_waveform_model propagation
        # set_db delaycal_equivalent_waveform_type simulation
        # set_db delaycal_enable_quiet_receivers_for_hold true
        # set_db delaycal_advanced_pin_cap_mode true

        # # AOCV libraries (see TSMCHOME/digital/Front_End/SBOCV/documents/GL_SBOCV_*.pdf)
        <PLACEHOLDER> Choice 1 of 3
        # set_db timing_analysis_aocv true
        # set_db timing_extract_model_aocv_mode graph_based
        # set_db timing_aocv_analysis_mode combine_launch_capture
        # # set_db timing_aocv_analysis_mode separate_data_clock
        # # set_db timing_aocv_slack_threshold 0.0
        # set_db timing_enable_aocv_slack_based true

        # # LVF/SOCV libraries (see TSMCHOME/digital/Front_End/LVF/documents/GL_LVF_*.pdf)
        <PLACEHOLDER> Choice 2 of 3
        # # set_limited_access_feature socv 1
        # set_db timing_analysis_socv true
        # set_db delaycal_socv_accuracy_mode ultra
        # set_db delaycal_socv_machine_learning_level 1
        # set_db timing_nsigma_multiplier 3.0
        # # set_db timing_disable_retime_clock_path_slew_propagation false
        # set_db timing_socv_statistical_min_max_mode mean_and_three_sigma_bounded
        # set_db timing_report_enable_verbose_ssta_mode true
        # set_db delaycal_accuracy_level 3
        # set_db delaycal_socv_lvf_mode moments
        # set_db delaycal_socv_use_lvf_tables {delay slew constraint}
        # set_timing_derate 0 -sigma -cell_check -early [get_lib_cells *BWP*]
        # set_db timing_ssta_enable_nsigma_enumeration true
        # set_db timing_socv_rc_variation_mode true
        # set_socv_rc_variation_factor 0.1 -early
        # set_socv_rc_variation_factor 0.1 -late

        # Flat STA settings
        <PLACEHOLDER> Choice 3 of 3

        # # Spatial OCV settings (see TSMCHOME/digital/Front_End/timing_margin/SPM)
        # set_db timing_enable_spatial_derate_mode true
        # set_db timing_spatial_derate_chip_size 1000
        # set_db timing_spatial_derate_distance_mode bounding_box
    }
    
    # Advanced SI analysis settings (see foundry recommendations)
    # set_db si_analysis_type aae 
    # set_db si_delay_separate_on_data true
    # set_db si_delay_delta_annotation_mode lumpedOnNet
    # set_db si_individual_aggressor_simulation_filter true
    # set_db si_reselection all 
    # set_db si_glitch_input_voltage_high_threshold 0.2
    # set_db si_glitch_input_voltage_low_threshold 0.2
    set_db si_aggressor_alignment timing_aware_edge

    # SI settings
    set_db delaycal_enable_si true
    # set_db si_use_infinite_timing_window true
'

# LEF to DEF layer map file
gf_create_step -name voltus_pgv_lef_def_map_file '
    <PLACEHOLDER>
    metal  M0    lefdef   M0
    metal  M1    lefdef   M1
    ...
    via    VIA0  lefdef   VIA0
    via    VIA1  lefdef   VIA1
    ...
    via    RV    lefdef   RV
    metal  AP    lefdef   AP
'

# GDS layer mapping for PGV connectivity
gf_create_step -name voltus_pgv_layer_connect_file '
    <PLACEHOLDER>
    metal  M0    gds    30  1
    metal  M0    gds    30  2
    metal  M1    gds    31  0
    ...
    via    VIA0  gds    50  0
    via    VIA1  gds    51  0
    ...
    via    RV    gds    85  0
    metal  AP    gds    74  0
'

# Extraction command file for PGV generation
gf_create_step -name voltus_pgv_extraction_command_file '
    setvar extract_flat false
    <PLACEHOLDER>
    connect M0 VIA0 M1 VIA1 ... RV AP
'

# Engine variables
gf_create_step -name voltus_pgv_command_file '
    setvar keep_debug_files true
    # setvar use_lef_technology <PLACEHOLDER>macro.lef
'

# Commands before generating tech-only PGV models
gf_create_step -name voltus_pre_write_pgv_tech_only '

    # Tech only PGV settings
    set_pg_library_mode \
        -filler_cells $PGV_FILLER_CELLS \
        -decap_cells $PGV_DECAP_CELLS \
        -default_area_cap 0.01fF \
        -lef_layer_map ./in/$TASK_NAME.lef.map \
        -extraction_tech_file [gconfig::get_files qrc -view $PGV_RC_CORNER] \
        -temperature [gconfig::get temperature -view $PGV_RC_CORNER] \
        -current_distribution propagation \
        -cell_type techonly

    # PGV generation advanced options
    set_advanced_pg_library_mode \
        -pg_library_generation_command_file ./in/$TASK_NAME.libgen.cmd \
        -extraction_command_file ./in/$TASK_NAME.extract.cmd \
        -verbosity true
'

# Commands before generating PGV models for standard cells
gf_create_step -name voltus_pre_write_pgv_standard_cells '
    set VOLTUS_PGV_SPICE_MODELS {`$VOLTUS_PGV_SPICE_MODELS`}
    set VOLTUS_PGV_SPICE_CORNERS {`$VOLTUS_PGV_SPICE_CORNERS`}
    set VOLTUS_PGV_SPICE_FILES {`$VOLTUS_PGV_SPICE_FILES`}

    # Standard cells PGV settings
    set_pg_library_mode \
        -extraction_tech_file [gconfig::get_files qrc -view $PGV_RC_CORNER] \
        -temperature [gconfig::get temperature -view $PGV_RC_CORNER] \
        -spice_models $VOLTUS_PGV_SPICE_MODELS \
        -spice_corners $VOLTUS_PGV_SPICE_CORNERS \
        -spice_subckts $VOLTUS_PGV_SPICE_FILES \
        -power_pins $VOLTUS_POWER_NETS_PAIRS \
        -ground_pins $VOLTUS_GROUND_NETS \
        -cells_file ./in/$TASK_NAME.cells \
        -lef_layer_map ./in/$TASK_NAME.lef.map \
        -current_distribution propagation \
        -cell_type stdcells
    
    # # Optional decap file
    #     -cell_dcap_file ./in/$TASK_NAME.dcap \
    # redirect ./in/$TASK_NAME.dcap {puts {
    #    <PLACEHOLDER>
    #     DCAP1 10pF
    #     DCAP2 20pF
    #     ...
    # }}

    # # Optional power gate settings
    #     -powergate_parameters {{RING_SWITCH TVDD VDD {} {} {}}} \

    # Standard cells list
    redirect ./in/$TASK_NAME.cells {

        # Auto-generate the list based on cell area
        get_db [get_db base_cells -if .area<100.0] .name -foreach {puts $object}
    }

    # PGV generation advanced options
    set_advanced_pg_library_mode \
        -pg_library_generation_command_file ./in/$TASK_NAME.libgen.cmd \
        -extraction_command_file ./in/$TASK_NAME.extract.cmd \
        -verbosity true
'

# Commands before generating PGV models for macros
gf_create_step -name voltus_pre_write_pgv_macros '
    set GDS_FILES {`$GDS_FILES`}
    set VOLTUS_PGV_SPICE_MODELS {`$VOLTUS_PGV_SPICE_MODELS`}
    set VOLTUS_PGV_SPICE_CORNERS {`$VOLTUS_PGV_SPICE_CORNERS`}
    set VOLTUS_PGV_SPICE_FILES {`$VOLTUS_PGV_SPICE_FILES`}
    set VOLTUS_PGV_SPICE_SCALING {`$VOLTUS_PGV_SPICE_SCALING`}

    # Macro PGV settings
    set_pg_library_mode \
        -extraction_tech_file [gconfig::get_files qrc -view $PGV_RC_CORNER] \
        -temperature [gconfig::get temperature -view $PGV_RC_CORNER] \
        -stream_files [join $GDS_FILES] \
        -spice_models $VOLTUS_PGV_SPICE_MODELS \
        -spice_corners $VOLTUS_PGV_SPICE_CORNERS \
        -spice_subckts $VOLTUS_PGV_SPICE_FILES \
        -spice_subckts_xy_scaling $VOLTUS_PGV_SPICE_SCALING \
        -power_pins $VOLTUS_POWER_NETS_PAIRS \
        -ground_pins $VOLTUS_GROUND_NETS \
        -cells_file ./in/$TASK_NAME.cells \
        -lef_layer_map ./in/$TASK_NAME.lef.map \
        -stream_layer_map ./scripts/$TASK_NAME.connect.map \
        -cell_type macros

    # Macro cells list
    redirect ./in/$TASK_NAME.cells {
        
        # Auto-generate the list based on cell area
        get_db [get_db base_cells -if .area>100.0] .name -foreach {puts $object}
        
        # # User-defined macro list
        # foreach macro {
        #     MACRO1
        #     MACRO2
        # } {puts $macro}
    }

    # PGV generation advanced options
    set_advanced_pg_library_mode \
        -pg_library_generation_command_file ./in/$TASK_NAME.libgen.cmd \
        -extraction_command_file ./in/$TASK_NAME.extract.cmd \
        -verbosity true
'

# Commands before performing static power analysis
gf_create_step -name voltus_run_report_power_static '

    # Static power analysis settings
    set_db power_method static
    set_db power_write_static_currents true
    set_db power_ignore_control_signals false
    set_db power_read_rcdb true

    # Default activity analysis
    if {$POWER_SCENARIO == "Switching activity 0.2"} {
        set_default_switching_activity -input_activity 0.2
        set_default_switching_activity -sequential_activity 0.2
        set_default_switching_activity -clock_gates_output 2

    } elseif {$POWER_SCENARIO == "Switching activity 0.4"} {
        set_default_switching_activity -input_activity 0.4
        set_default_switching_activity -sequential_activity 0.4
        set_default_switching_activity -clock_gates_output 2

    # VCD-based analysis
    } elseif {$POWER_SCENARIO == "VCD: Default mode"} {
        read_activity_file <PLACEHOLDER>/PATH_TO/ACTIVITY_FILE.vcd -format <PLACEHOLDER>VCD \
            -scope <PLACEHOLDER>/design_instance/scope/in/vcd \
            -start <PLACEHOLDER>10ns -end <PLACEHOLDER>20ns
        set_db power_scale_to_sdc_clock_frequency true
        
    # Unknown scenario
    } else {
        error "Incorrect scenario: $POWER_SCENARIO"
    }

    # Generate power database
    set_power_output_dir ./out/$TASK_NAME.power
    redirect -tee ./reports/$TASK_NAME.power.rpt {report_power}
'

# Commands before performing static rail analysis
gf_create_step -name voltus_run_report_rail_static '
    set VOLTUS_PGV_LIBS {`$VOLTUS_PGV_LIBS`}
    set VOLTUS_ICT_EM_RULE {`$VOLTUS_ICT_EM_RULE`}

    # Static rail analysis settings
    set_rail_analysis_mode \
        -extraction_tech_file [gconfig::get_files qrc -view $STATIC_RAIL_VIEW] \
        -temperature [gconfig::get temperature -view $STATIC_RAIL_VIEW] \
        -power_grid_libraries [join $VOLTUS_PGV_LIBS] \
        -ict_em_models [join $VOLTUS_ICT_EM_RULE] \
        -accuracy hd -method static -ignore_shorts true
   
    # Power nets settings
    foreach {net value} $VOLTUS_POWER_NETS_PAIRS {
        set_pg_nets -force -net $net -voltage $value -threshold [expr -$IR_THRESHOLD_STATIC+$value]
    }
    foreach {net value} $VOLTUS_GROUND_NETS_PAIRS {
        set_pg_nets -force -net $net -voltage $value -threshold [expr $IR_THRESHOLD_STATIC+$value]
    }

    # Option 1: Tap coordinates files generated in data out task
    foreach net [concat $VOLTUS_POWER_NETS $VOLTUS_GROUND_NETS] {
        set_power_pads -format xy -net $net -file $DATA_OUT_DIR/$DESIGN_NAME.$net.pp
    }
    # # Option 2: Tap coordinates files specified manually
    # set_power_pads -format xy -net VDD -file /PATH/TO/VDD.pp
    # set_power_pads -format xy -net VSS -file /PATH/TO/VSS.pp

    # Power data
    set power_files {}
    foreach net [concat $VOLTUS_POWER_NETS $VOLTUS_GROUND_NETS] {
        lappend power_files ./out/$STATIC_POWER_TASK.power/static_${net}.ptiavg
    }
    set_power_data -format current -scale 1 $power_files

    # Analyze IR-drop
    set_rail_analysis_domain -domain_name PDCore -power_nets $VOLTUS_POWER_NETS -ground_nets $VOLTUS_GROUND_NETS
    report_rail -type domain -output_dir ./out/$TASK_NAME.rail PDCore
    
    # Open latest directory
    ::read_power_rail_results -rail_directory [exec sed -ne {s|^.*Run directory\s*:\s*./out/|./out/|p} [get_db log_file]] -instance_voltage_window {timing whole} -instance_voltage_method {worst best avg worstavg}
'

# Commands before performing dynamic power analysis
gf_create_step -name voltus_run_report_power_dynamic '

    # Dynamic power analysis settings
    set_db power_write_static_currents true
    set_db power_honor_negative_energy true
    set_db power_ignore_control_signals false
    set_db power_read_rcdb true
    set_db power_disable_static false

    # Default activity analysis
    if {$POWER_SCENARIO == "Switching activity 0.2"} {
        set_default_switching_activity -input_activity 0.2
        set_default_switching_activity -sequential_activity 0.2
        set_default_switching_activity -clock_gates_output 2
        set_db power_method dynamic_vectorless
        set_dynamic_power_simulation -resolution 10ps -period 10ns

    } elseif {$POWER_SCENARIO == "Switching activity 0.4"} {
        set_default_switching_activity -input_activity 0.4
        set_default_switching_activity -sequential_activity 0.4
        set_default_switching_activity -clock_gates_output 2
        set_db power_method dynamic_vectorless
        set_dynamic_power_simulation -resolution 10ps -period 10ns

    # VCD-based analysis
    } elseif {$POWER_SCENARIO == "VCD: Default mode"} {
        read_activity_file <PLACEHOLDER>/PATH_TO/ACTIVITY_FILE.vcd -format <PLACEHOLDER>VCD \
            -scope <PLACEHOLDER>/design_instance/scope/in/vcd \
            -start <PLACEHOLDER>10ns -end <PLACEHOLDER>20ns
        set_db power_method dynamic_vectorbased
        set_dynamic_power_simulation -resolution <PLACEHOLDER>10ps

    # Unknown scenario
    } else {
        error "Incorrect scenario: $POWER_SCENARIO"
    }

    # Generate power database
    set_power_output_dir ./out/$TASK_NAME.power
    redirect -tee ./reports/$TASK_NAME.power.rpt {report_power}
'

# Commands before performing dynamic rail analysis
gf_create_step -name voltus_run_report_rail_dynamic '
    set VOLTUS_PGV_LIBS {`$VOLTUS_PGV_LIBS`}
    set VOLTUS_ICT_EM_RULE {`$VOLTUS_ICT_EM_RULE`}

    # Dynamic rail analysis settings
    set_rail_analysis_mode \
        -extraction_tech_file [gconfig::get_files qrc -view $DYNAMIC_RAIL_VIEW] \
        -temperature [gconfig::get temperature -view $DYNAMIC_RAIL_VIEW] \
        -power_grid_libraries [join $VOLTUS_PGV_LIBS] \
        -ict_em_models [join $VOLTUS_ICT_EM_RULE] \
        -accuracy hd -method dynamic -ignore_shorts true -limit_number_of_steps false
   
    # # Optional GIF creation
    #     -write_movies true \
   
    # Power nets settings
    foreach {net value} $VOLTUS_POWER_NETS_PAIRS {
        set_pg_nets -force -net $net -voltage $value -threshold [expr -$IR_THRESHOLD_DYNAMIC+$value]
    }
    foreach {net value} $VOLTUS_GROUND_NETS_PAIRS {
        set_pg_nets -force -net $net -voltage $value -threshold [expr $IR_THRESHOLD_DYNAMIC+$value]
    }

    # Option 1: Tap coordinates files generated in data out task
    foreach net [concat $VOLTUS_POWER_NETS $VOLTUS_GROUND_NETS] {
        set_power_pads -format xy -net $net -file $DATA_OUT_DIR/$DESIGN_NAME.$net.pp
    }
    # # Option 2: Tap coordinates files specified manually
    # set_power_pads -format xy -net VDD -file /PATH/TO/VDD.pp
    # set_power_pads -format xy -net VSS -file /PATH/TO/VSS.pp

    # Power data
    set power_files {}
    foreach net [concat $VOLTUS_POWER_NETS $VOLTUS_GROUND_NETS] {
        lappend power_files ./out/$DYNAMIC_POWER_TASK.power/dynamic_${net}.ptiavg
    }
    set_power_data -format current -scale 1 $power_files

    # Analyze IR-drop
    set_rail_analysis_domain -domain_name PDCore -power_nets $VOLTUS_POWER_NETS -ground_nets $VOLTUS_GROUND_NETS
    report_rail -type domain -output_dir ./out/$TASK_NAME.rail PDCore
    
    # Open latest directory
    ::read_power_rail_results -rail_directory [exec sed -ne {s|^.*Run directory\s*:\s*./out/|./out/|p} [get_db log_file]] -instance_voltage_window {timing whole} -instance_voltage_method {worst best avg worstavg}
'

# Commands before performing dynamic rail analysis
gf_create_step -name voltus_run_signal_em '
    set VOLTUS_ICT_EM_RULE {`$VOLTUS_ICT_EM_RULE`}

    # Signal EM analysis settings
    set_default_switching_activity -input_activity <PLACEHOLDER>0.2
    set_default_switching_activity -sequential_activity <PLACEHOLDER>0.2
    set_default_switching_activity -clock_gates_output <PLACEHOLDER>2

    # Run analysis
    check_ac_limits \
        -ict_em_models [join $VOLTUS_ICT_EM_RULE] \
        -method peak 
'
