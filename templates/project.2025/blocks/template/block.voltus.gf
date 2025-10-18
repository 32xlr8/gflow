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
# Filename: templates/project.2025/blocks/template/block.voltus.gf
# Purpose:  Block-specific Voltus configuration and flow steps
################################################################################

gf_info "Loading block-specific Voltus steps ..."

# # Override all tasks resources
# gf_set_task_options -cpu 8 -mem 15

# # Override resources for tasks
gf_set_task_options TechPGV -cpu 1 -mem 15
gf_set_task_options CellsPGV -cpu 1 -mem 15
gf_set_task_options MacrosPGV -cpu 1 -mem 15
# gf_set_task_options DebugVoltus -cpu 4 -mem 10
# gf_set_task_options StaticPower -cpu 8 -mem 15
# gf_set_task_options StaticRail -cpu 8 -mem 15
# gf_set_task_options DynamicPower -cpu 8 -mem 15
# gf_set_task_options DynamicRail -cpu 8 -mem 15
# gf_set_task_options SignalEM -cpu 8 -mem 15

# Limit simultaneous tasks count
gf_set_task_options TechPGV CellsPGV MacrosPGV -group PGV -parallel 1
# gf_set_task_options StaticPower StaticRail DynamicPower DynamicRail SignalEM -group Heavy -parallel 1

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
    VCD: Default mode
    Switching activity 0.2
    Switching activity 0.4
'

# # Select scenario automatically
# POWER_SCENARIO="Switching activity 0.4"

################################################################################
# Flow steps
################################################################################

# MMMC and OCV settings for power and rail
gf_create_step -name voltus_gconfig_power_rail_design_settings '
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
    
    set PGV_RC_CORNER {* * * 125 rcw *}
            
    set SIGNAL_SPEF_CORNER {* * * m40 rcb *}
    set POWER_SPEF_CORNER {* * * 125 cw *}

    set STATIC_POWER_VIEW {func ff 1p100v 125 rcw p}
    set DYNAMIC_POWER_VIEW {func ff 1p100v 125 rcw p}

    set STATIC_RAIL_VIEW {func ff 1p100v 125 rcw p}
    set DYNAMIC_RAIL_VIEW {func ff 1p100v 125 rcw p}

    # Choose standard cell libraries:
    # - nldm_libraries - NLDM (Liberty) + CDB (Celtic) files used for fast runtime
    # - ecsm_libraries - ECSM (Liberty) + AOCV/SOCV files used for precise delay calculation
    # - ccs_libraries - CCS (Liberty) + AOCV/SOCV files used for precise delay calculation
    # - lvf_libraries - LVF (Liberty) files used for most precise delay calculation
    # - ldb_libraries - LDB compiled binary files for fast load
    # - ecsm_p_libraries - ECSM-P (Liberty) files used for precise power calculation
    # - ccs_p_libraries - CCS-P (Liberty) files used for precise power calculation
    gconfig::enable_switches ccs_p_libraries
   
    # Choose separate variation libraries (optional with ecsm_libraries or ccs_libraries):
    # - aocv_libraries - AOCV (advanced, SBOCV)
    # - socv_libraries - SOCV (statistical)
    gconfig::enable_switches aocv_libraries

    # Choose derating scenarios (additional variations):
    # - flat_derates - used with NLDM (see process node documentation)
    # - no_derates - zero derates (optimistic for prototyping mode)
    # - user_derates - same as flat_derates, but user-specified values used (customize below)
    # - vt_derates - used with ESCM/CCS if additional Voltage/Temparature derates required (see standard cell documentation, customize IR-drop below)
    gconfig::enable_switches vt_derates
'

# MMMC and OCV settings for signal electromigration
gf_create_step -name voltus_gconfig_electromigration_design_settings '
    <PLACEHOLDER> Review signoff settings for power analysis
    
    # Choose analysis views patterns:
    # - {mode process voltage temperature rc_corner timing_check}
    #   - SIGNAL_EM_VIEW - Signal electromigration analysis view (worst cells currents, worst C parasitics)
    
    set SIGNAL_EM_VIEW {func ff 1p100v 125 cw p}

    # Choose standard cell libraries:
    # - nldm_libraries - NLDM (Liberty) + CDB (Celtic) files used for fast runtime
    # - ecsm_libraries - ECSM (Liberty) + AOCV/SOCV files used for precise delay calculation
    # - ccs_libraries - CCS (Liberty) + AOCV/SOCV files used for precise delay calculation
    # - lvf_libraries - LVF (Liberty) files used for most precise delay calculation
    # - ldb_libraries - LDB compiled binary files for fast load
    # - ecsm_p_libraries - ECSM-P (Liberty) files used for precise power calculation
    # - ccs_p_libraries - CCS-P (Liberty) files used for precise power calculation
    gconfig::enable_switches ccs_libraries
   
    # Choose derating scenarios (additional variations):
    # - flat_derates - used with NLDM (see process node documentation)
    # - no_derates - zero derates (optimistic for prototyping mode)
    # - user_derates - same as flat_derates, but user-specified values used (customize below)
    # - vt_derates - used with ESCM/CCS if additional Voltage/Temparature derates required (see standard cell documentation, customize IR-drop below)
    gconfig::enable_switches no_derates
'

# Commands after design initialized
gf_create_step -name voltus_pre_init_design_variables '
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
    set IR_THRESHOLD_STATIC 0.020
    set IR_THRESHOLD_DYNAMIC 0.075

    # Dynamic rail options
    set DYNAMIC_RAIL_RESULTS_START_TIME 0.100ns

    # EM options
    set EM_TEMPERATURE 105
    set EM_DELTA_TEMPERATURE 5.0
    set EM_THRESHOLD 1.0
    set EM_LIFE_TIME 100000

    # Design-specific options
    set STOP_VIA VIA1
    set CLUSTER_VIA_RULE {{VIA1 1} {VIA2 1} .. {RV 1}}

    # Currents generation methods (peak or avg)
    set STATIC_POWER_CURRENT_METHOD "avg"
    set DYNAMIC_POWER_CURRENT_METHOD "avg"
'

# Commands after design initialized
gf_create_step -name voltus_post_init_design_variables '

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
gf_create_step -name voltus_post_init_design '

    # Increase message limit
    set_message -limit 1000

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

        # # Choice 1 of 3: AOCV libraries (see TSMCHOME/digital/Front_End/SBOCV/documents/GL_SBOCV_*.pdf)
        <PLACEHOLDER>
        # set_db timing_analysis_aocv true
        # set_db timing_extract_model_aocv_mode graph_based
        # set_db timing_aocv_analysis_mode combine_launch_capture
        # # set_db timing_aocv_analysis_mode separate_data_clock
        # # set_db timing_aocv_slack_threshold 0.0
        # set_db timing_enable_aocv_slack_based true

        # # Choice 2 of 3: LVF/SOCV libraries (see TSMCHOME/digital/Front_End/LVF/documents/GL_LVF_*.pdf)
        <PLACEHOLDER>
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

        # Choice 3 of 3: Flat STA settings
        <PLACEHOLDER>

        # # Spatial OCV settings (see TSMCHOME/digital/Front_End/timing_margin/SPM)
        # set_db timing_enable_spatial_derate_mode true
        # set_db timing_spatial_derate_chip_size 1000
        # set_db timing_spatial_derate_distance_mode bounding_box
    }
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
gf_create_step -name voltus_pgv_lef_gds_map_file '
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
        -cell_type techonly \
        -power_pins $VOLTUS_POWER_NETS_PAIRS \
        -ground_pins $VOLTUS_GROUND_NETS \

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
    set GDS_FILES {`$GDS_FILES` `$PARTITIONS_GDS_FILES -optional`}
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
        -stream_layer_map ./in/$TASK_NAME.connect.map \
        -cell_type macros \
        -stop_via $STOP_VIA
        
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
    set VOLTUS_PGV_LIBS [join [concat {`$VOLTUS_PGV_LIBS`} [gconfig::get_files pgv -view $DYNAMIC_RAIL_VIEW]]]

    # Reset options
    set_power -reset
    reset_db -category power
    set_switching_activity -reset
    set_default_switching_activity -reset

    # Input files
    set_db power_grid_libraries $VOLTUS_PGV_LIBS
    set_db power_include_file [join {`$VOLTUS_STATIC_POWER_INCLUDE_FILE -optional`}]
    catch {set_db power_extractor_include [join {`$VOLTUS_EXTRACTOR_INCLUDE_FILE -optional`}]}

    # Libraries settings
    set_db power_library_preference ecsm_ccsp
    set_db power_disable_ecsm_interpolation true
    set_db power_multibit_flop_toggle_behavior sbff 
    # set_db power_honor_negative_energy true
    set_db power_use_lef_for_missing_cells true
    # set_db power_read_rcdb true

    # Analysis settings
    set_db power_method static
    set_db power_disable_static false
    set_db power_current_generation_method $STATIC_POWER_CURRENT_METHOD
    # set_db power_x_transition_factor 1.0
    # set_db power_z_transition_factor 1.0
    
    # Design settings
    <PlACEHOLDER>
    set_db power_default_frequency 1000.0
    set_db power_default_slew 0.150
    set_db power_default_supply_voltage [lindex $VOLTUS_POWER_NETS_PAIRS 1]
    # set_db power_ignore_control_signals false
    # set_db power_static_netlist def

    # Reporting options
    set_db power_report_idle_instances true
    set_db power_report_missing_input true
    set_db power_report_statistics true

    # Output data
    set_db power_write_static_currents true
    set_db power_write_db true

    # Power nets settings
    foreach {net value} $VOLTUS_POWER_NETS_PAIRS {
        set_pg_nets -force -net $net -voltage $value -threshold [expr -$IR_THRESHOLD_STATIC+$value]
    }
    foreach {net value} $VOLTUS_GROUND_NETS_PAIRS {
        set_pg_nets -force -net $net -voltage $value -threshold [expr $IR_THRESHOLD_STATIC+$value]
    }

    # Default activity analysis
    if {$POWER_SCENARIO == "Switching activity 0.2"} {
        set_default_switching_activity -input_activity 0.2
        set_default_switching_activity -sequential_activity 0.2
        set_default_switching_activity -clock_gates_output 2

    } elseif {$POWER_SCENARIO == "Switching activity 0.4"} {
        set_default_switching_activity -input_activity 0.4
        set_default_switching_activity -sequential_activity 0.4
        set_default_switching_activity -clock_gates_output 2

    # # VCD-based analysis
    # <PLACEHOLDER>
    # } elseif {$POWER_SCENARIO == "VCD: Default mode"} {
    #     read_activity_file /PATH_TO/ACTIVITY_FILE.vcd -format VCD \
    #         -scope /design_instance/scope/in/vcd \
    #         -start 10ns -end 20ns
    #     set_db power_scale_to_sdc_clock_frequency true
    #     set_db power_use_zero_delay_vector_file true
        
    # Unknown scenario
    } else {
        error "Incorrect scenario: $POWER_SCENARIO"
    }

    # Report tool options
    redirect ./reports/$TASK_NAME.settings.rpt {
        get_db power_*
    }

    # Generate power database
    set_power_output_dir ./out/$TASK_NAME.power
    redirect -tee ./reports/$TASK_NAME.power.rpt {report_power}
'

# Commands before performing static rail analysis
gf_create_step -name voltus_run_report_rail_static '
    set VOLTUS_PGV_LIBS [join [concat {`$VOLTUS_PGV_LIBS`} [gconfig::get_files pgv -view $DYNAMIC_RAIL_VIEW]]]

    # Reset options
    set_power_pads -reset
    set_power_data -reset

    # EM rules (-ict_em_models with high priority)
    set VOLTUS_EM_OPTION "-ict_em_models"
    set VOLTUS_EM_RULES [join {`$VOLTUS_ICT_EM_MODELS -optional`}]
    if {$VOLTUS_EM_RULES == ""} {
        set VOLTUS_EM_RULES [join {`$VOLTUS_EM_MODELS -optional`}]
        if {$VOLTUS_EM_RULES != ""} {
            set VOLTUS_EM_OPTION "-em_models"
        }
    }

    # Static rail analysis settings
    set_rail_analysis_config \
        -extraction_tech_file [gconfig::get_files qrc -view $STATIC_RAIL_VIEW] \
            -temperature [gconfig::get temperature -view $STATIC_RAIL_VIEW] \
        -power_grid_libraries $VOLTUS_PGV_LIBS \
        -cluster_via_rule $CLUSTER_VIA_RULE \
            -cluster_via_size 1 \
            -cluster_via1_ports false \
        -em_peak_analysis true \
            -process_techgen_em_rules false \
            -em_temperature $EM_TEMPERATURE \
            -em_threshold $EM_THRESHOLD \
            $VOLTUS_EM_OPTION $VOLTUS_EM_RULES \
            -lifetime $EM_LIFE_TIME \
        -enable_manufacturing_effects true \
        -enable_rlrp_analysis true \
            -rlrp_detail_report true \
            -enable_reff_analysis true \
            -rlrp_eval_nodes port \
        -ignore_incomplete_net true \
        -ignore_nets_without_voltage_sources true \
        -ignore_shorts true \
            -report_shorts true \
        -verbosity true \
        -method static \
            -accuracy hd

        # # Alternative options
            # -process_techgen_em_rules true \

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

    # # Option 3: Tap coordinates of bumps
    # foreach net [concat $VOLTUS_POWER_NETS $VOLTUS_GROUND_NETS] {
    #     redirect ./$DESIGN_NAME.$net.pp {
    #         set i 0
    #         foreach bump [get_db bumps -if .net.name==${net}] {
    #             incr i; puts "${net}_${i} [get_db $bump .center.x] [get_db $bump .center.y] [get_db $bump .port.layer.name]"
    #         }
    #     }
    #     set_power_pads -format xy -net $net -file ./$DESIGN_NAME.$net.pp
    # }

    # Power data
    set power_files {}
    foreach net [concat $VOLTUS_POWER_NETS $VOLTUS_GROUND_NETS] {
        lappend power_files ./out/$POWER_TASK_NAME.power/static_[regsub -all {/} $net {_}].pti${STATIC_POWER_CURRENT_METHOD}
    }
    set_power_data -format current -scale 1 $power_files

    # Report tool options
    redirect ./reports/$TASK_NAME.settings.rpt {
        get_rail_analysis_config
        get_db power_*
    }

    # Analyze IR-drop
    set_rail_analysis_domain -domain_name PDCore -power_nets $VOLTUS_POWER_NETS -ground_nets $VOLTUS_GROUND_NETS
    report_rail -type domain -output_dir ./out/$TASK_NAME.rail PDCore

    # Open latest directory
    set results_directories [concat \
        [exec sed -ne {s|^.*Run directory\s*:\s*./out/|./out/|ip} [get_db log_file]] \
        [exec sed -ne {s|^.*State directory\s*:\s*out/|./out/|ip} [get_db log_file]] \
    ]
    ::read_power_rail_results -rail_directory [lindex $results_directories 0] -instance_voltage_window {timing whole} -instance_voltage_method {worst best avg worstavg}

    # # Clean power data
    # exec rm -Rf ./out/$POWER_TASK_NAME.power/PTIData
'

# Commands before performing dynamic power analysis
gf_create_step -name voltus_run_report_power_dynamic '
    set VOLTUS_PGV_LIBS [join [concat {`$VOLTUS_PGV_LIBS`} [gconfig::get_files pgv -view $DYNAMIC_RAIL_VIEW]]]

    # Reset options
    set_power -reset
    reset_db -category power
    set_switching_activity -reset
    set_default_switching_activity -reset

    # Input files
    set_db power_grid_libraries $VOLTUS_PGV_LIBS
    set_db power_include_file [join {`$VOLTUS_DYNAMIC_POWER_INCLUDE_FILE -optional`}]
    catch {set_db power_extractor_include [join {`$VOLTUS_EXTRACTOR_INCLUDE_FILE -optional`}]}
    
    # Libraries settings
    # set_db power_library_preference ecsm_ccsp
    # set_db power_disable_ecsm_interpolation true
    set_db power_multibit_flop_toggle_behavior sbff 
    set_db power_honor_negative_energy true
    set_db power_use_lef_for_missing_cells true
    # set_db power_read_rcdb true

    # Analysis settings
    set_db power_disable_static false
    set_db power_current_generation_method $DYNAMIC_POWER_CURRENT_METHOD
    # set_db power_x_transition_factor 1.0
    # set_db power_z_transition_factor 1.0

    # Design settings
    <PlACEHOLDER>
    set_db power_default_frequency 1000.0
    set_db power_default_slew 0.150
    set_db power_default_supply_voltage [lindex $VOLTUS_POWER_NETS_PAIRS 1]
    # set_db power_ignore_control_signals false
    # set_db power_static_netlist def

    # Reporting options
    set_db power_report_idle_instances true
    set_db power_report_missing_input true
    set_db power_report_statistics true

    # Output data
    # set_db power_write_static_currents true
    # set_db power_write_dynamic_currents true 
    set_db power_write_db true

    # Power nets settings
    foreach {net value} $VOLTUS_POWER_NETS_PAIRS {
        set_pg_nets -force -net $net -voltage $value -threshold [expr -$IR_THRESHOLD_DYNAMIC+$value]
    }
    foreach {net value} $VOLTUS_GROUND_NETS_PAIRS {
        set_pg_nets -force -net $net -voltage $value -threshold [expr $IR_THRESHOLD_DYNAMIC+$value]
    }

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

    # # VCD-based analysis
    # <PLACEHOLDER>
    # } elseif {$POWER_SCENARIO == "VCD: Default mode"} {
    #     read_activity_file /PATH_TO/ACTIVITY_FILE.vcd -format VCD \
    #         -scope /design_instance/scope/in/vcd \
    #         -start 10ns -end 20ns
    #     set_db power_method dynamic_vectorbased
    #     set_dynamic_power_simulation -resolution 10ps
    #     set_db power_scale_to_sdc_clock_frequency true
    #     set_db power_use_zero_delay_vector_file true

    # Unknown scenario
    } else {
        error "Incorrect scenario: $POWER_SCENARIO"
    }

    # Report tool options
    redirect ./reports/$TASK_NAME.settings.rpt {
        get_db power_*
    }

    # Generate power database
    set_power_output_dir ./out/$TASK_NAME.power
    redirect -tee ./reports/$TASK_NAME.power.rpt {report_power}
'

# Commands before performing dynamic rail analysis
gf_create_step -name voltus_run_report_rail_dynamic '
    set VOLTUS_PGV_LIBS [join [concat {`$VOLTUS_PGV_LIBS`} [gconfig::get_files pgv -view $DYNAMIC_RAIL_VIEW]]]

    # Reset options
    set_power_pads -reset
    set_power_data -reset

    # Dynamic rail analysis settings
    set_rail_analysis_config \
        -extraction_tech_file [gconfig::get_files qrc -view $DYNAMIC_RAIL_VIEW] \
            -temperature [gconfig::get temperature -view $DYNAMIC_RAIL_VIEW] \
        -power_grid_libraries $VOLTUS_PGV_LIBS \
        -cluster_via_rule $CLUSTER_VIA_RULE \
            -cluster_via_size 1 \
            -cluster_via1_ports false \
        -ignore_decaps false \
            -decap_cell_list $PGV_DECAP_CELLS \
            -filler_cell_list $PGV_FILLER_CELLS \
        -enable_manufacturing_effects true \
        -enable_rlrp_analysis true \
            -rlrp_eval_nodes port \
        -eiv_method worstavg \
            -eiv_eval_window both \
            -eiv_eval_nodes port \
            -eiv_pin_based_report true \
        -ignore_incomplete_net true \
        -ignore_nets_without_voltage_sources true \
        -ignore_shorts true \
            -report_shorts true \
        -verbosity true \
        -method dynamic \
            -record_results_start_time $DYNAMIC_RAIL_RESULTS_START_TIME \
            -limit_number_of_steps false \
            -accuracy hd

    # # Additional options
    #     -write_movies true \
    #     -enable_xp true \
    #     -write_voltage_waveforms true \

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

    # # Option 3: Tap coordinates of bumps
    # foreach net [concat $VOLTUS_POWER_NETS $VOLTUS_GROUND_NETS] {
    #     redirect ./$DESIGN_NAME.$net.pp {
    #         set i 0
    #         foreach bump [get_db bumps -if .net.name==${net}] {
    #             incr i; puts "${net}_${i} [get_db $bump .center.x] [get_db $bump .center.y] [get_db $bump .port.layer.name]"
    #         }
    #     }
    #     set_power_pads -format xy -net $net -file ./$DESIGN_NAME.$net.pp
    # }

    # Power data
    set power_files {}
    foreach net [concat $VOLTUS_POWER_NETS $VOLTUS_GROUND_NETS] {
        lappend power_files ./out/$POWER_TASK_NAME.power/dynamic_[regsub -all {/} $net {_}].pti${DYNAMIC_POWER_CURRENT_METHOD}
    }
    set_power_data -format current -scale 1 $power_files

    # Report tool options
    redirect ./reports/$TASK_NAME.settings.rpt {
        get_rail_analysis_config
        get_db power_*
    }

    # Analyze IR-drop
    set_rail_analysis_domain -domain_name PDCore -power_nets $VOLTUS_POWER_NETS -ground_nets $VOLTUS_GROUND_NETS
    report_rail -type domain -output_dir ./out/$TASK_NAME.rail PDCore

    # Clean power data
    # exec rm -Rf ./out/$POWER_TASK_NAME.power/PTIData
'

# Commands before performing dynamic rail analysis
gf_create_step -name voltus_run_signal_em '

    # Reset options
    set_power -reset
    set_switching_activity -reset
    set_default_switching_activity -reset

    set_db check_ac_limit_view [get_db [get_db analysis_views  -if .is_setup] .name]
    set_db check_ac_limit_extraction_tech_file [gconfig::get_files qrc -view $SIGNAL_EM_VIEW]
    set_db check_ac_limit_method {avg peak rms}
    set_db check_ac_limit_effort_level high
    set_db check_ac_limit_out_file ./reports/$TASK_NAME.rpt
    set_db check_ac_limit_report_db true
    set_db check_ac_limit_use_db_freq true
    set_db check_ac_limit_lifetime $EM_LIFE_TIME
    set_db check_ac_limit_em_temperature $EM_TEMPERATURE
    set_db check_ac_limit_delta_temperature $EM_DELTA_TEMPERATURE
    set_db check_ac_limit_em_threshold $EM_THRESHOLD
    set_db check_ac_limit_current_scale_factor {{rms 1} {peak 1} {avg 1 } }
    set_db check_ac_limit_em_limit_scale_factor {{rms 1} {peak 1} {avg 1} }    

    # Default activity analysis
    set_default_switching_activity -input_activity 1.0
    set_default_switching_activity -sequential_activity 1.0
    set_default_switching_activity -clock_gates_output 2.0

    # Propagate and read back activities
    propagate_activity -set_net_frequency true
    write_tcf ./out/$TASK_NAME.tcf
    read_activity_file -format tcf -write_net_freq true ./out/$TASK_NAME.tcf

    # Report tool options
    redirect ./reports/$TASK_NAME.settings.rpt {
        get_db check_ac_*
    }

    # Run analysis
    set VOLTUS_ICT_EM_MODELS {`$VOLTUS_ICT_EM_MODELS -optional`}
    if {$VOLTUS_ICT_EM_MODELS != ""} {
        set_db check_ac_limit_ict_em_models $VOLTUS_ICT_EM_MODELS
    } else {
        set_db check_ac_limit_use_qrc_tech true
    }
    check_ac_limits -detailed -out_file ./reports/$TASK_NAME.rpt
'

# Commands before open GUI for debug
gf_create_step -name voltus_pre_gui '

    # Instance VDD - no limit
    gui_set_power_rail_display -plot ivdd -enable_voltage_sources true -legend nw
    gui_fit
'
