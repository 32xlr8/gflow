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
# Filename: templates/project_template.2023/blocks/block_template/block.tempus.gf
# Purpose:  Block-specific Tempus configuration and flow steps
################################################################################

gf_info "Loading block-specific Tempus steps ..."

# Disable data out task by default
gf_disable_task Data

################################################################################
# Flow variables
################################################################################

# # Specific MMMC file
# MMMC_FILE_STA=/path/to/ConfigSignoff*.timing.mmmc.tcl
# MMMC_FILE_ECO=/path/to/ConfigSignoff*.timing.mmmc.tcl

# # Innovus database to analyze (keep empty to select interactively)
# DATABASE="../../../innovus.be.0000/out/Route.innovus.db"
# DATABASE="../../../tempus.sta.0000/out/ECO.innovus.db"

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

# Set to "Y" to ignore IO timing
IGNORE_IO_TIMING=Y

# # Scenario to run (keep empty to select interactively)
# ECO_SCENARIO='<PLACEHOLDER>'

################################################################################
# Flow steps
################################################################################

# Block-specific Tempus settings
gf_create_step -name tempus_post_init_design '

    # Timing report table fields
    set_db timing_report_fields {cell arc delay incr_delay arrival required transition fanout load aocv_adj_stages aocv_derate user_derate annotation instance}
    # set_db timing_report_fields {cell arc delay incr_delay arrival required transition fanout load delay_sigma user_derate annotation instance}

    # Timing analysis
    # set_db timing_cppr_threshold_ps 1
    set_db timing_analysis_cppr both
    set_db timing_analysis_type ocv
    
    # Analyze setup and hold concurrently
    set_db timing_enable_simultaneous_setup_hold_mode true

    # General delay calculation settings
    set_db delaycal_equivalent_waveform_model propagation
    # set_db delaycal_equivalent_waveform_type simulation
    # set_db delaycal_enable_quiet_receivers_for_hold true
    # set_db delaycal_advanced_pin_cap_mode true
    # set_db delaycal_accurate_receiver_out_load true

    # # AOCV settings (see TSMCHOME/digital/Front_End/SBOCV/documents/GL_SBOCV_*.pdf)
    # set_db timing_analysis_aocv true
    # set_db timing_extract_model_aocv_mode graph_based
    # set_db timing_aocv_analysis_mode combine_launch_capture
    # # set_db timing_aocv_analysis_mode separate_data_clock
    # # set_db timing_aocv_slack_threshold 0.0
    # set_db timing_enable_aocv_slack_based true

    # # SOCV settings
    # set_db timing_analysis_socv true
    # # set_db timing_socv_rc_variation_mode true
    # set_db delaycal_socv_accuracy_mode high
    # set_db timing_nsigma_multiplier 3.0
    # set_db timing_disable_retime_clock_path_slew_propagation false
    # set_db timing_socv_statistical_min_max_mode mean_and_three_sigma_bounded
    
    # # LVF settings (see TSMCHOME/digital/Front_End/LVF/documents/GL_LVF_*.pdf)
    # set_db delaycal_socv_lvf_mode moments
    # # set_db delaycal_socv_use_lvf_tables {delay slew constraint}
    # # set_db timing_report_enable_verbose_ssta_mode true

    # # Spatial OCV settings (see TSMCHOME/digital/Front_End/timing_margin/SPM)
    # set_db timing_derate_spatial_distance_unit 1nm
    # set_db timing_enable_spatial_derate_mode true
    # set_db timing_spatial_derate_chip_size 1000
    # set_db timing_spatial_derate_distance_mode bounding_box

    # Enable SI delay calculation and glitch reports
    set_db delaycal_enable_si       true
    set_db si_glitch_enable_report  true

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
    # foreach inst [get_db [get_db insts  {*_preserve *_preserved *_preserve_*}] .name] {set_dont_touch $inst true}
    # foreach net [get_db [get_db nets  {*_preserve *_preserved *_preserve_*}] .name] {set_dont_touch $net true}

    # # Block-specific tempus configuration
    # set_db timing_path_based_enable_infinite_depth_mode true  

    # # Pessimistic SI effect calculation
    # set_db si_use_infinite_timing_window true
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
gf_create_step -name reports_sta_tempus '

    # Include SI into ECODB
    set_db opt_signoff_fix_glitch true
    set_db opt_signoff_fix_xtalk true

    # Create reports
    `@procs_tempus_reports`
    gf_check_timing
    gf_report_timing_late 150
    gf_report_timing_early 150
    gf_report_timing_late_pba 150
    gf_report_timing_early_pba 150
    gf_report_constraint_late
    gf_report_constraint_early
    gf_report_glitch
    # gf_report_timing_summary

    # Write ECO timing DB
    set_db opt_signoff_write_eco_opt_db ./out/$MOTHER_TASK_NAME.eco_db
    write_eco_opt_db
'

# Tempus ECO scenarios processing
gf_create_step -name run_opt_signoff '

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
