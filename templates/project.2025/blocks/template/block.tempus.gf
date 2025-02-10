################################################################################
# Generic Flow v5.5.1 (February 2025)
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
# Filename: templates/project.2025/blocks/template/block.tempus.gf
# Purpose:  Block-specific Tempus configuration and flow steps
################################################################################

gf_info "Loading block-specific Tempus steps ..."

################################################################################
# Flow options
################################################################################

# # Override all tasks resources
# gf_set_task_options -cpu 8 -mem 15

# # Override resources for interactive tasks
# gf_set_task_options 'Debug*' -cpu 4 -mem 10

# # Override resources for batch tasks
# gf_set_task_options STA -cpu 8 -mem 15
# gf_set_task_options TSO -cpu 8 -mem 15
# gf_set_task_options STA_* -cpu 4 -mem 15
# gf_set_task_options TempusOut_* -cpu 4 -mem 15

# Limit simultaneous tasks count
gf_set_task_options STA TSO TempusOut -group Heavy -parallel 1
gf_set_task_options STA_* -group STA -parallel 8
gf_set_task_options TempusOut_* -group TempusOut -parallel 8

# # Disable not needed tasks
# gf_set_task_options -disable STA
# gf_set_task_options -disable TSO

################################################################################
# Flow variables
################################################################################

# Set to "Y" to ignore IO timing
IGNORE_IO_TIMING=Y

# User-defined Tempus ECO scenarios
ECO_SCENARIOS='
    Swap: setup, hold
    Swap: leakage
    Swap: power
    Full: drv
    Full: setup
    Full: hold
    Full: leakage
    Full: power
    Full: area
    Full: setup hold
    Full: drv setup hold
'

# # Scenario to run (keep empty to select interactively)
# ECO_SCENARIO='<PLACEHOLDER>'

################################################################################
# Flow steps
################################################################################

# Design variables
gf_create_step -name tempus_gconfig_design_variables '

    # Choose analysis views patterns:
    # - {mode process voltage temperature rc_corner timing_check}
    set MMMC_VIEWS [regsub -all -line {^\s*\#.*\n} {
        {func tt 1p000v 85 ct s}
        {func tt 1p000v 85 ct h}

        {func ss 0p900v m40 cwt s} 
        {func ss 0p900v m40 rcwt s} 
        {func ss 0p900v 125 cwt s}
        {func ss 0p900v 125 rcwt s} 
        
        {func ss 0p900v m40 cw h} 
        {func ss 0p900v m40 rcw h} 
        {func ss 0p900v 125 cw h} 
        {func ss 0p900v 125 rcw h} 
        
        {func ff 1p100v m40 cb h} 
        {func ff 1p100v m40 cw h} 
        {func ff 1p100v 0 cb h} 
        {func ff 1p100v 0 cw h} 
        {func ff 1p100v 125 cb h} 
        {func ff 1p100v 125 cw h} 
        
        {func ff 1p100v m40 rcb h} 
        {func ff 1p100v m40 rcw h} 
        {func ff 1p100v 125 rcb h} 
        {func ff 1p100v 125 rcw h}
        
        {func ff 1p100v 0 rcb h} 
        {func ff 1p100v 0 rcw h}

        {func tt 1p000v 85 rcw p}
        {func ff 1p100v 125 rcw p}
    } {}]
    
    # SDF views
    set SDF_MAX_VIEW {func ss 0p900v m40 rcwt s}
    set SDF_MIN_VIEW {func ff 1p100v m40 cw h}
    set SDF_TYP_VIEW {func tt 1p000v 85 rcw p}
'

# MMMC and OCV settings
gf_create_step -name tempus_gconfig_design_settings '
    <PLACEHOLDER> Review signoff settings for timing analysis

    # Design variables
    `@tempus_gconfig_design_variables`
    
    # Choose standard cell libraries:
    # - nldm_libraries - NLDM (Liberty) + CDB (Celtic) files used for fast runtime
    # - ecsm_libraries - ECSM (Liberty) + AOCV/SOCV files used for precise delay calculation
    # - ccs_libraries - CCS (Liberty) + AOCV/SOCV files used for precise delay calculation
    # - lvf_libraries - LVF (Liberty) files used for most precise delay calculation
    gconfig::enable_switches ecsm_libraries
    
    # Choose separate variation libraries (optional with ecsm_libraries or ccs_libraries):
    # - aocv_libraries - AOCV (advanced, SBOCV)
    # - socv_libraries - SOCV (statistical)
    gconfig::enable_switches aocv_libraries
   
    # Choose derating scenarios (additional variations):
    # - flat_derates - used with NLDM (see process node documentation)
    # - no_derates - zero derates (optimistic for prototyping mode)
    # - user_derates - same as flat_derates, but user-specified values used (customize below)
    # - vt_derates - used with ESCM/CCS if additional Voltage/Temparature derates required (see standard cell documentation, customize IR-drop below)
    # - default_uncertainty - set clock uncertainty ignoring one set in SDC files
    gconfig::enable_switches vt_derates default_uncertainty

    # Set IR-drop value for voltage and temperature OCV derates (when vt_derate switch enabled)
    # It is recommended to set 40% of Static IR for setup and 80% for hold
    <PLACEHOLDER>
    gconfig::add_section {
        -when vt_derates {
            -views {* * * * * s} {$voltage_drop 20}
            -views {* * * * * h} {$voltage_drop 40}
        }
    }

    # # Set user-specific derate values (when user_derates switch enabled)
    # gconfig::add_section {
    #     -when user_derates {
    #         -views {* tt * * * s} {$cell_data +5.0 $cell_early -0.0 $cell_late +5.0}
    #         -views {* tt * * * h} {$cell_data -5.0 $cell_early -5.0 $cell_late +0.0}
    #         -views {* ss * * * s} {$cell_data +0.0 $cell_early -5.0 $cell_late +0.0}
    #         -views {* ss * * * h} {$cell_data -5.0 $cell_early -5.0 $cell_late +0.0}
    #         -views {* ff * * * h} {$cell_data -0.0 $cell_early -0.0 $cell_late +5.0}
    #     }
    # }
    
    # Set PLL jitter value in ps in default uncertainty mode
    <PLACEHOLDER>
    gconfig::add_section {
        -when default_uncertainty {
            $jitter 25
        }
    }
    
    # # Optional: set user-specific clock uncertainty values for all clocks
    # gconfig::add_section {
    #     -when default_uncertainty {
    #         -views {* ss 0p900v * * *} {$process_uncertainty 0 $setup_uncertainty <PLACEHOLDER>100 $hold_uncertainty <PLACEHOLDER>50}
    #         -views {* ff 1p100v * * *} {$process_uncertainty 0 $setup_uncertainty <PLACEHOLDER>100 $hold_uncertainty <PLACEHOLDER>50}
    #     }
    # }
    
    # Run in assembled mode
    gconfig::enable_switches assembled
'

# Tool-specific procedures
gf_create_step -name tempus_procs_common '
    `@gconfig_procs_ocv`
    `@procs_stylus_db`
'

# Commands before reading design data
gf_create_step -name tempus_pre_read_libs '

    # # Tech LEF line end extension optimizm removal
    # set_db extract_rc_pre_route_force_lee_optimism_fix true

    # # SOCV settings before loading libraries
    # set_db timing_library_hold_sigma_multiplier 3.0
    # # set_db timing_library_hold_sigma_multiplier 0.0
    # set_db timing_library_setup_constraint_corner_sigma_multiplier 0.0
    # set_db timing_library_hold_constraint_corner_sigma_multiplier 0.0
    # set_db timing_library_scale_aocv_to_socv_to_n_sigma 1
    # # set_db timing_library_gen_hold_constraint_table_using_sigma_values sigma

    # # Spatial OCV settings before loading libraries
    # set_db timing_derate_spatial_distance_unit 1nm

    # Ignore IMPESI-3490
    eval_legacy {setDelayCalMode -sgs2set abortCdbMmmcFlow:false}
'

# Block-specific Tempus settings
gf_create_step -name tempus_post_init_design '
    <PLACEHOLDER> Review signoff settings for timing analysis

    # Library settings
    if {1} {
    
        # Timing analysis
        # set_db timing_cppr_threshold_ps 1
        set_db timing_analysis_cppr both
        set_db timing_analysis_type ocv

        # Additional timing analysis
        set_db timing_analysis_clock_gating true
        set_db timing_analysis_async_checks async
        # set_db timing_extract_model_non_borrowing_latch_path_as_setup true
        # set_db timing_extract_model_enable_worst_slew_based_model true
        # set_db timing_extract_model_accurate_auto_validation true
        # set_db timing_path_based_enable_required_time_pessimism_removal true
        # set_db timing_path_based_enable_new_latch_thru_mode true
        # set_db timing_path_based_enable_new_max_borrow_mode true
        # set_db timing_use_latch_time_borrow false
        # set_db timing_use_latch_early_launch_edge false
        # set_db timing_library_enable_cell_type_marking 1
        # eval_legacy {set timing_library_support_opposite_polarity_current_timing_ccs_wf 1}
        # set_db timing_apply_default_primary_input_assertion false
        # set_db timing_disable_output_as_clock_port true
        # set_db timing_disable_constant_propagation_for_sequential_cells true
        # set_db timing_disable_drv_report_on_constant_nets true
        set_db timing_report_unconstrained_paths true

        # General delay calculation settings
        set_db delaycal_equivalent_waveform_model propagation
        # set_db delaycal_equivalent_waveform_type simulation
        # set_db delaycal_enable_quiet_receivers_for_hold true
        # set_db delaycal_waveform_compression_mode clock_detailed
        # set_db delaycal_rc_reduction_adaptive_frequency_mode 3
        # set_db delaycal_eng_useViVoVdd true
        # set_db delaycal_advanced_pin_cap_mode 2
        # set_db delaycal_advanced_receiver_capacitance_mode true
        # set_db delaycal_accurate_receiver_out_load true

        # # Choice 1 of 3: AOCV libraries (see TSMCHOME/digital/Front_End/SBOCV/documents/GL_SBOCV_*.pdf)
        <PLACEHOLDER>
        # set_db timing_report_fields {cell arc delay incr_delay arrival required transition fanout load aocv_adj_stages aocv_derate user_derate annotation instance}
        # set_db timing_analysis_aocv true
        # set_db timing_extract_model_aocv_mode graph_based
        # set_db timing_aocv_analysis_mode combine_launch_capture
        # # set_db timing_aocv_analysis_mode separate_data_clock
        # # set_db timing_aocv_slack_threshold 0.0
        # set_db timing_enable_aocv_slack_based true

        # # Choice 2 of 3: LVF/SOCV libraries (see TSMCHOME/digital/Front_End/LVF/documents/GL_LVF_*.pdf)
        <PLACEHOLDER>
        # # set_db timing_report_fields {timing_point cell arc fanout load slew slew_mean slew_sigma pin_location delay_mean delay_sigma delay arrival_mean arrival_sigma arrival user_derate total_derate power_domain voltage phys_info}
        # set_db timing_report_fields {cell arc timing_point delay fanout load slew incr_delay arrival total_derate pin_location}
        # # set_db ui_precision_timing 6
        # # set_db timing_report_precision 6
        # set_limited_access_feature socv 1
        # set_db timing_analysis_socv true
        # set_db timing_library_update_libset_ssocv true
        # set_db timing_library_infer_socv_from_aocv true
        # set_db delaycal_accuracy_level 3
        # set_db delaycal_socv_accuracy_mode ultra
        # set_db delaycal_socv_machine_learning_level 11
        # set_db timing_nsigma_multiplier 3.0
        # # set_db timing_disable_retime_clock_path_slew_propagation false
        # set_db timing_socv_statistical_min_max_mode mean_and_three_sigma_bounded
        # set_db timing_report_enable_verbose_ssta_mode true
        # set_socv_reporting_nsigma_multiplier -setup 3 -hold 4.5
        # set_db delaycal_accuracy_level 3
        # set_db delaycal_socv_lvf_mode moments
        # set_db delaycal_socv_use_lvf_tables {delay slew constraint}
        # # set_db delaycal_socv_use_lvf_tables {all}
        # set_db timing_report_max_transition_check_using_nsigma_slew false
        # set_db timing_ssta_enable_nsigma_enumeration true
        # set_db timing_ssta_generate_sta_timing_report_format true
        # set_db timing_socv_rc_variation_mode true
        # set_socv_rc_variation_factor 0.1 -early
        # set_socv_rc_variation_factor 0.1 -late

        # Choice 3 of 3: Flat STA settings
        <PLACEHOLDER>
        set_db timing_report_fields {cell arc delay incr_delay arrival required transition fanout load user_derate annotation instance}

        # # Spatial OCV settings (see TSMCHOME/digital/Front_End/timing_margin/SPM)
        # set_db timing_enable_spatial_derate_mode true
        # # set_db timing_spatial_derate_chip_size 1000
        # # set_db timing_spatial_derate_distance_mode chip_size
        # set_db timing_spatial_derate_distance_mode bounding_box
        # set_db read_parasitics_enable_spef_transform 1
    }
    
    # Analyze setup and hold concurrently
    set_db timing_enable_simultaneous_setup_hold_mode true

    # Enable SI delay calculation and glitch reports
    set_db delaycal_enable_si true
    set_db si_delay_enable_report true
    set_db si_glitch_enable_report true
    # set_db si_delay_delta_annotation_mode lumpedOnNet
    # set_db si_delay_enable_logical_correlation true
    # set_db si_reselection_setup_slack 100e-12
    # set_db si_reselection_hold_slack 100e-12

    # # Pessimistic SI effect calculation
    # set_db si_use_infinite_timing_window true
    # set_db si_unconstrained_net_use_infinite_timing_window true
    # set_db si_glitch_input_threshold 0.30
    # set_db si_glitch_receiver_peak_limit 0.25
    # set_db si_glitch_receiver_clock_peak_limit 0.20

    # Report SI delay in separate column
    set_db si_delay_separate_on_data true

    # # Disable user and library data to data checks
    # set_db timing_disable_library_data_to_data_checks true
    # set_db timing_disable_user_data_to_data_checks    true

    # Dont use cells
    set_dont_use <PLACEHOLDER>* true
    set_dont_use <PLACEHOLDER>* false
    # set_dont_use *ULVT*BWP* false
    # set_dont_use *OPT*BWP* false
    # set_dont_use DEL*BWP* true
    # set_dont_use DCCK*BWP* true
    # set_dont_use CK*BWP* true
    # set_dont_use G*BWP* true
    # set_dont_use *D2?BWP* true
    # set_dont_use *D3?BWP* true

    # # Set dont touch objects
    # set_db [get_db insts {*_preserve *_preserved *_preserve_*}] .dont_touch $inst true
    # set_db [get_db nets {*_preserve *_preserved *_preserve_*}] .dont_touch $net true

    # # Disable PBA depth limit
    # set_db timing_path_based_enable_infinite_depth_mode true  
'

# Cells to use in signoff ECO
gf_create_step -name init_cells_tempus '

    # Clock tree cells
    set_db opt_signoff_clock_cell_list [join {
        <PLACEHOLDER>CLOCK_BUFFER_CELL_NAME
        <PLACEHOLDER>CLOCK_INVERTER_CELL_NAME
        <PLACEHOLDER>CLOCK_GATING_CELL_NAME
        <PLACEHOLDER>CLOCK_NAND_CELL_NAME
        <PLACEHOLDER>CLOCK_NOR_CELL_NAME
        <PLACEHOLDER>CLOCK_XNOR_CELL_NAME
        <PLACEHOLDER>CLOCK_AND_CELL_NAME
        <PLACEHOLDER>CLOCK_OR_CELL_NAME
        <PLACEHOLDER>CLOCK_XOR_CELL_NAME
    }]

    # Hold fixing cells
    set_db opt_signoff_buffer_cell_list [join {
        <PLACEHOLDER>DATA_DELAY_CELL_NAME
        <PLACEHOLDER>DATA_BUFFER_CELL_NAME
    }]

    # Decap and filler cells
    set_db add_fillers_cells [list \
        [get_db base_cells .name <PLACEHOLDER>DCAP*] \
        [get_db base_cells .name <PLACEHOLDER>FILL*] \
    ]
'

# STA analysis
gf_create_step -name tempus_sta_reports '
    exec mkdir -p ./reports/$TASK_NAME

    # Include SI into ECODB
    set_db opt_signoff_fix_glitch true
    set_db opt_signoff_fix_xtalk true

    # Create reports
    gf_check_timing
    gf_report_timing_late 150
    gf_report_timing_early 150
    gf_report_timing_late_pba 150
    gf_report_timing_early_pba 150
    gf_report_constraint_late
    gf_report_constraint_early
    # gf_report_noise
    # gf_report_timing_summary

    # Write ECO timing database for TSO flow
    set_db opt_signoff_write_eco_opt_db ./out/$TASK_NAME.tempus.eco.db
    write_eco_opt_db
'

# Tempus ECO scenarios processing
gf_create_step -name run_opt_signoff '

    # Take legal location into account
    set_db opt_signoff_legal_only true
    
    # Allow to fix hold if setup violated
    set_db opt_signoff_fix_hold_allow_setup_tns_degrade true

    # Optimize setup with hold
    set_db opt_signoff_fix_hold_allow_setup_optimization true

    # # Set optimization target
    # set_db opt_signoff_setup_target_slack -0.010

    # Default set of allowed operations
    set_db opt_signoff_add_inst true
    set_db opt_signoff_delete_inst true
    set_db opt_signoff_resize_inst true
    set_db opt_signoff_swap_inst true

    # Default set fixes
    set_db opt_signoff_fix_glitch false
    set_db opt_signoff_fix_xtalk false
    set_db opt_signoff_optimize_sequential_cells true
    
    switch $ECO_SCENARIO {
        "Swap: setup, hold" {
            set_db opt_signoff_add_inst false
            set_db opt_signoff_delete_inst false
            set_db opt_signoff_resize_inst false
            
            `@run_opt_signoff_setup`
            `@run_opt_signoff_hold`
        }
        "Swap: leakage" {
            set_db opt_signoff_add_inst false
            set_db opt_signoff_delete_inst false
            set_db opt_signoff_resize_inst false
            
            `@run_opt_signoff_leakage`
        }
        "Swap: power" {
            set_db opt_signoff_add_inst false
            set_db opt_signoff_delete_inst false
            set_db opt_signoff_resize_inst false
            
            `@run_opt_signoff_power`
        }
        "Full: drv" {
            set_db opt_signoff_fix_glitch true
            set_db opt_signoff_fix_xtalk true
            `@run_opt_signoff_drv`
        }
        "Full: setup" {
            `@run_opt_signoff_setup`
        }
        "Full: hold" {
            set_db opt_signoff_fix_glitch true
            set_db opt_signoff_fix_xtalk true

            `@run_opt_signoff_hold`
        }
        "Full: leakage" {
            `@run_opt_signoff_leakage`
        }
        "Full: power" {
            `@run_opt_signoff_power`
        }
        "Full: area" {
            `@run_opt_signoff_area`
        }
        "Full: setup hold" {
            set_db opt_signoff_fix_glitch true
            set_db opt_signoff_fix_xtalk true

            `@run_opt_signoff_setup`
            `@run_opt_signoff_hold`
        }
        "Full: drv setup hold" {
            set_db opt_signoff_fix_glitch true
            set_db opt_signoff_fix_xtalk true

            `@run_opt_signoff_drv`
            `@run_opt_signoff_setup`
            `@run_opt_signoff_hold`
        }
        default {
            puts "Incorrect ECO scenario selected: $ECO_SCENARIO"
            error 1
        }
    }
'

# Commands to create block-specific timing files
gf_create_step -name tempus_data_out '
    mkdir -p ./out/$TASK_NAME/
    mkdir -p ./reports/$TASK_NAME.GTD/

    # Registers
    set regs [all_registers]

    # Create timing reports
    set processed_views {}
    foreach MMMC_VIEW $MMMC_VIEWS {
        set view [gconfig::get analysis_view_name -view $MMMC_VIEW]
        if {[lsearch -exact $processed_views $view] < 0} {
            lappend processed_views $view

            # Late paths for setup views
            if {[lsearch -exact [gconfig::get check -view $MMMC_VIEW] "s"] >= 0} {

                puts "Writing timing reports ./reports/$TASK_NAME/late.*.$view.tarpt ..."
                report_timing -late -path_type full_clock -from $regs -to $regs -view $view -max_paths 500 > ./reports/$TASK_NAME/late.gba.reg2reg.$view.tarpt
                report_timing -late -path_type endpoint -from $regs -to $regs -view $view -max_paths 10000 -max_slack 0 > ./reports/$TASK_NAME/late.violated.reg2reg.$view.tarpt
                foreach clock [get_db clocks .base_name -u] {report_timing -late -path_type full_clock -from $clock -view $view -max_paths 250 > ./reports/$TASK_NAME/late.clock.full.[regsub -all {/} $clock {.}].$view.tarpt}
                foreach clock [get_db clocks .base_name -u] {report_timing -late -path_type endpoint -from $clock -view $view -max_paths 10000 -max_slack 0 > ./reports/$TASK_NAME/late.clock.violated.[regsub -all {/} $clock {.}].$view.tarpt}

                puts "Writing timing reports ./reports/$TASK_NAME.GTD/late.*.$view.mtarpt ..."
                report_timing -late -output_format gtd -from $regs -to $regs -view $view -max_paths 500 > ./reports/$TASK_NAME.GTD/late.worst.reg2reg.$view.mtarpt
                report_timing -late -output_format gtd -from $regs -to $regs -view $view -max_paths 10000 -max_slack 0 > ./reports/$TASK_NAME.GTD/late.violated.reg2reg.$view.mtarpt

                puts "  [gf_print_report_timing_summary ./reports/$TASK_NAME/late.gba.reg2reg.$view.tarpt] @ late.gba.reg2reg.$view.tarpt"
            }

            # Early paths for hold views
            if {[lsearch -exact [gconfig::get check -view $MMMC_VIEW] "h"] >= 0} {

                puts "Writing timing reports ./reports/$TASK_NAME/early.*.$view.tarpt ..."
                report_timing -early -path_type full_clock -from $regs -to $regs -view $view -max_paths 500 > ./reports/$TASK_NAME/early.gba.reg2reg.$view.tarpt
                report_timing -early -path_type endpoint -from $regs -to $regs -view $view -max_paths 10000 -max_slack 0 > ./reports/$TASK_NAME/early.violated.reg2reg.$view.tarpt
                foreach clock [get_db clocks .base_name -u] {report_timing -early -path_type full_clock -from $clock -view $view -max_paths 250 > ./reports/$TASK_NAME/early.clock.full.[regsub -all {/} $clock {.}].$view.tarpt}
                foreach clock [get_db clocks .base_name -u] {report_timing -early -path_type endpoint -from $clock -view $view -max_paths 10000 -max_slack 0 > ./reports/$TASK_NAME/early.clock.violated.[regsub -all {/} $clock {.}].$view.tarpt}

                puts "Writing timing reports ./reports/$TASK_NAME.GTD/early.*.$view.mtarpt ..."
                report_timing -early -output_format gtd -from $regs -to $regs -view $view -max_paths 500 > ./reports/$TASK_NAME.GTD/early.worst.reg2reg.$view.mtarpt
                report_timing -early -output_format gtd -from $regs -to $regs -view $view -max_paths 10000 -max_slack 0 > ./reports/$TASK_NAME.GTD/early.violated.reg2reg.$view.mtarpt

                puts "  [gf_print_report_timing_summary ./reports/$TASK_NAME/early.gba.reg2reg.$view.tarpt] @ early.gba.reg2reg.$view.tarpt"
            }

            # TWF for power views
            if {[lsearch -exact [gconfig::get check -view $MMMC_VIEW] "p"] >= 0} {
                set view [gconfig::get analysis_view_name -view $MMMC_VIEW]
                puts "Writing ./out/$TASK_NAME/$DESIGN_NAME.$view.twf.gz ..."
                write_timing_windows \
                    -pin \
                    -power_compatible \
                    -ssta_sigma_multiplier 3 \
                    -view $view ./out/$TASK_NAME/$DESIGN_NAME.$view.twf.gz
            }
            
            # LIB for timing and power views
            puts "Writing ./out/$TASK_NAME/$DESIGN_NAME.$view.lib ..."
            write_timing_model \
                -include_power_ground \
                -input_transitions {0.002, 0.010, 0.025, 0.050, 0.100, 0.200, 0.500} \
                -output_loads {0.000, 0.010, 0.025, 0.050, 0.100, 0.200, 0.500} \
                -view $view ./out/$TASK_NAME/$DESIGN_NAME.$view.lib
        }
    }

    # Write out SDF for block level simulation
    write_sdf ./out/$TASK_NAME/$DESIGN_NAME.sdf.gz \
        -min_view [gconfig::get analysis_view_name -view $SDF_MIN_VIEW] \
        -typical_view [gconfig::get analysis_view_name -view $SDF_TYP_VIEW] \
        -max_view [gconfig::get analysis_view_name -view $SDF_MAX_VIEW] \
        -edges noedge -interconnect all -no_derate \
        -version 3.0
'
