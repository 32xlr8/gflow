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
# Filename: templates/project.2025/blocks/template/block.innovus.gf
# Purpose:  Block-specific Innovus configuration and flow steps
################################################################################

# # Load Quantus if high effort extraction used
# gf_source -once "../../project.quantus.gf"

gf_info "Loading block-specific Innovus steps ..."

################################################################################
# Flow options
################################################################################

# # Override all tasks resources
# gf_set_task_options -cpu 8 -mem 15

# # Override resources for interactive tasks
# gf_set_task_options Floorplan -cpu 4 -mem 15
# gf_set_task_options DebugInnovus -cpu 4 -mem 10
gf_set_task_options Metric -cpu 1 -mem 5 -local

# # Override resources for batch tasks
# gf_set_task_options Place -cpu 8 -mem 15
# gf_set_task_options Clock -cpu 8 -mem 15
# gf_set_task_options Route -cpu 16 -mem 15
# gf_set_task_options ReportPlace -cpu 4 -mem 10
# gf_set_task_options ReportClock -cpu 4 -mem 10
# gf_set_task_options ReportRoute -cpu 16 -mem 10
# gf_set_task_options InnovusOut -cpu 1 -mem 10

# Limit simultaneous tasks count
gf_set_task_options ReportPlace ReportClock ReportRoute -group Reports -parallel 1
# gf_set_task_options Place Clock Route -group Heavy -parallel 1

# # Disable not needed tasks
# gf_set_task_options -disable Place
# gf_set_task_options -disable Clock
# gf_set_task_options -disable Route
gf_set_task_options -disable Assemble
gf_set_task_options -disable ReportPlace
gf_set_task_options -disable ReportClock
# gf_set_task_options -disable ReportRoute
# gf_set_task_options -disable InnovusOut

################################################################################
# Flow variables
################################################################################

# # Optional: cells to exclude from netlist for simulation
# <PLACEHOLDER>
# LOGICAL_NETLIST_EXCLUDE_CELLS='PVDD* PVSS*'

# # Optional: cells to exclude from netlist for LVS
# <PLACEHOLDER>
# PHYSICAL_NETLIST_EXCLUDE_CELLS="*_DTCD_* *_ICOVL_* TAP* FILL* BOUNDARY* PRCUT* PFILLER* PCORNER* label ${DESIGN_NAME}_dummy_fill_inst"

################################################################################
# Basic flow steps
################################################################################

# Design variables
gf_create_step -name innovus_gconfig_design_variables '
    
    # Choose analysis views patterns:
    # - {mode process voltage temperature rc_corner timing_check}
    set MMMC_VIEWS [regsub -all -line {^\s*\#.*\n} {
        {func ss 0p900v m40 rcwt s}
        {func ss 0p900v 125 cwt s}
        {func ff 1p100v m40 cw h}
        {func ff 1p100v 125 cb h}
        {func tt 1p000v 125 rcw p}
    } {}]
    
    # SDF views
    set SDF_MAX_VIEW {func ss 0p900v m40 rcwt s}
    set SDF_MIN_VIEW {func ff 1p100v m40 cw h}
    set SDF_TYP_VIEW {func tt 1p000v 125 rcw p}
'

# MMMC and OCV settings
gf_create_step -name innovus_gconfig_design_settings '
    <PLACEHOLDER> Review backend settings for implementation
    
    # Design variables
    `@innovus_gconfig_design_variables`

    # Choose standard cell libraries:
    # - nldm_libraries - NLDM (Liberty) + CDB (Celtic) files used for fast runtime
    # - ecsm_libraries - ECSM (Liberty) + AOCV/SOCV files used for precise delay calculation
    # - ccs_libraries - CCS (Liberty) + AOCV/SOCV files used for precise delay calculation
    # - lvf_libraries - LVF (Liberty) files used for most precise delay calculation
    # - ldb_libraries - LDB (binary) files used to decrease database load runtime
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
    # <PLACEHOLDER>
    # gconfig::add_section {
    #     -when default_uncertainty {
    #         -views {* ss 0p900v * * *} {$process_uncertainty 0 $setup_uncertainty 100 $hold_uncertainty 50}
    #         -views {* ff 1p100v * * *} {$process_uncertainty 0 $setup_uncertainty 100 $hold_uncertainty 50}
    #     }
    # }
'

# Tool-specific procedures
gf_create_step -name innovus_procs_common '
    `@gconfig_procs_ocv`
    `@procs_stylus_db`
    `@innovus_procs_db`
    `@innovus_procs_fanin_fanout_magnify`
    `@innovus_procs_add_buffers`
    `@innovus_procs_align`
    `@innovus_procs_copy_place`
    `@innovus_procs_power_grid`
    `@innovus_procs_objects`
    `@innovus_procs_reports`

    # Useful bindkeys
    catch {gui_bind_key F7 -cmd "gf_select_similar_instances_by_index"}
    catch {gui_bind_key Shift+F7 -cmd "gf_select_similar_instances_by_cell 1"}
    catch {gui_bind_key Ctrl+Shift+F7 -cmd "gf_select_more_instances"}
    catch {gui_bind_key F6 -cmd "gf_assign_next_bumps"}
    catch {gui_bind_key Shift+F6 -cmd "gf_unassign_selected_bumps"}
    catch {gui_bind_key Ctrl+Shift+F6 -cmd "gf_swap_bumps"}
'

################################################################################
# Implementation flow steps
################################################################################

# Commands before reading design data
gf_create_step -name innovus_pre_read_libs '

    # # Tech LEF line end extension optimizm removal
    # set_db extract_rc_pre_route_force_lee_optimism_fix true

    # # SOCV settings before loading libraries
    # set_db timing_library_hold_sigma_multiplier 3.0
    # # set_db timing_library_hold_sigma_multiplier 0.0
    # set_db timing_library_setup_constraint_corner_sigma_multiplier 0.0
    # set_db timing_library_hold_constraint_corner_sigma_multiplier 0.0
    # # set_db timing_library_gen_hold_constraint_table_using_sigma_values sigma

    # # Spatial OCV settings before loading libraries
    # set_db timing_derate_spatial_distance_unit 1nm
    
    # # Do not add unneeded assigns
    # set_db init_no_new_assigns true
    
    # Uniquify netlist on load
    set_db init_design_uniquify true
'

# Global net connection step
gf_create_step -name innovus_connect_global_nets '
    delete_global_net_connections
    
    # Core power nets connections
    <PLACEHOLDER>
    connect_global_net VDD -type tie_hi -pin_base_name VDD -inst_base_name * 
    connect_global_net VDD -type pg_pin -pin_base_name VDD -inst_base_name * 
    # connect_global_net VDD -type pg_pin -pin_base_name VPP -inst_base_name * 

    # Core ground nets connections
    <PLACEHOLDER>
    connect_global_net VSS -type tie_lo -pin_base_name VSS -inst_base_name * 
    connect_global_net VSS -type pg_pin -pin_base_name VSS -inst_base_name *
    # connect_global_net VSS -type pg_pin -pin_base_name VBB -inst_base_name *
    
    # Global IO nets connections
    # <PLACEHOLDER>
    # connect_global_net VDDPST -type pg_pin -pin_base_name VDDPST -inst_base_name * 
    # connect_global_net VSSPST -type pg_pin -pin_base_name VSSPST -inst_base_name * 
    # connect_global_net POC -type pg_pin -pin_base_name POCCTRL -inst_base_name * 
    # connect_global_net ESD -type pg_pin -pin_base_name ESD -inst_base_name * 
    
    commit_global_net_rules

    # Report unconnected PG pins
    if {![get_db pg_pins -if .net=="" -foreach {puts "\033\[31;41m \033\[0m Unconnected $object"}]} {
        puts "\033\[32;42m \033\[0m No unconnected pg_pins"
    }
'

# Commands after design initialization in physical mode
gf_create_step -name innovus_post_init_design_physical_mode '
    `@innovus_post_init_design_physical_mode_project`

    <PLACEHOLDER> Review backend settings for floorplan

    # # Floorplan settings
    # set_db floorplan_initial_all_compatible_core_site_rows true
    # set_db floorplan_global_odd_even_sites_row_constraint 1
    # set_db floorplan_row_site_width odd  
    # set_db floorplan_row_site_height even
    # set_db floorplan_snap_core_grid finfet_manufacturing
    # set_db floorplan_snap_die_grid finfet_manufacturing
    # # set_db floorplan_snap_core_grid user_define
    # # set_db floorplan_snap_die_grid user_define
    # # set_db floorplan_user_define_grid {0.000 0.000 0.000 0.000}
    # set_db floorplan_check_types {basic color odd_even_site_row}
    # <PLACEHOLDER>
    # set_db floorplan_default_tech_site core
    
    # # Turbo cells support
    # <PLACEHOLDER>
    # update_inbound_cell_site \
    #     -p_filler hpcore \
    #     -n_filler hncore \
    #     -new core \
    #     -original ibcore \
    #     -vertical
    # set_db floorplan_default_tech_site hpcore

    # # Precise floorplan settings (see foundry documentation)
    # set_db floorplan_row_height_multiple 2
    # set_db floorplan_row_height_increment_corner_to_corner 4
    # set_db floorplan_row_height_increment_in_corner_to_corner 0
    # set_db floorplan_row_height_increment_in_corner_to_in_corner 4

    # # Leave two-site gap for standard cells without on-site filler
    # set_db place_detail_legalization_inst_gap 2

    # Decap and filler cells
    <PLACEHOLDER>
    # set_db add_fillers_check_drc false
    # set_db add_fillers_with_drc false
    set_db add_fillers_preserve_user_order true
    set_db add_fillers_cells [list \
        [get_db [get_db base_cells DCAP*] .name] \
        [get_db [get_db base_cells FILL*] .name] \
    ]
    set_db add_fillers_vertical_stack_exception_cell [concat \
        [get_db [get_db base_cells TAP*] .name] \
        [get_db [get_db base_cells FILL1BWP*] .name] \
        [get_db [get_db base_cells BOUNDARY*ROW*] .name] \
        [get_db [get_db base_cells BOUNDARY_LEFT*] .name] \
        [get_db [get_db base_cells BOUNDARY_RIGHT*] .name] \
    ]

    # # Precise filler options (see foundry recommendations)
    # <PLACEHOLDER>
    # set_db add_fillers_vertical_stack_repair_cell [get_db base_cells .name FILL1BWP*]
    # set_db add_fillers_vertical_stack_max_length 200
    # set_db add_fillers_avoid_abutment_patterns {1:1}
    # set_db add_fillers_swap_cell [join {
    #     {{FILL1BWP*EHVT FILL1NOBCMBWP*EHVT}}
    #     {{FILL1BWP*UHVT FILL1NOBCMBWP*UHVT}}
    #     {{FILL1BWP*HVT FILL1NOBCMBWP*HVT}}
    #     {{FILL1BWP*SVT FILL1NOBCMBWP*SVT}}
    #     {{FILL1BWP*LVTLL FILL1NOBCMBWP*LVTLL}}
    #     {{FILL1BWP*LVT FILL1NOBCMBWP*LVT}}
    #     {{FILL1BWP*ULVTLL FILL1NOBCMBWP*ULVTLL}}
    #     {{FILL1BWP*ULVT FILL1NOBCMBWP*ULVT}}
    #     {{FILL1BWP*ELVT FILL1NOBCMBWP*ELVT}}
    # }]
    
    # Boundary cells
    <PLACEHOLDER>
    set_db add_endcaps_left_edge   [get_db [get_db base_cells "BOUNDARY_RIGHT*"] .name]
    set_db add_endcaps_right_edge  [get_db [get_db base_cells "BOUNDARY_LEFT*"] .name]
    set_db add_endcaps_top_edge    [get_db [get_db base_cells "BOUNDARY_PROW4* BOUNDARY_PROW3* BOUNDARY_PROW2* BOUNDARY_PROW1*"] .name]
    set_db add_endcaps_bottom_edge [get_db [get_db base_cells "BOUNDARY_NROW4* BOUNDARY_NROW3* BOUNDARY_NROW2* BOUNDARY_NROW1*"] .name]

    set_db add_endcaps_left_top_corner_odd        [get_db [get_db base_cells "BOUNDARY_NCORNER*"] .name]
    set_db add_endcaps_right_top_corner_odd       [get_db [get_db base_cells "BOUNDARY_NCORNER*"] .name]
    set_db add_endcaps_left_bottom_corner_even    [get_db [get_db base_cells "BOUNDARY_NCORNER*"] .name]
    set_db add_endcaps_right_bottom_corner_even   [get_db [get_db base_cells "BOUNDARY_NCORNER*"] .name]
    
    set_db add_endcaps_left_top_corner_even       [get_db [get_db base_cells "BOUNDARY_PCORNER*"] .name]
    set_db add_endcaps_right_top_corner_even      [get_db [get_db base_cells "BOUNDARY_PCORNER*"] .name]
    set_db add_endcaps_left_bottom_corner_odd     [get_db [get_db base_cells "BOUNDARY_PCORNER*"] .name]
    set_db add_endcaps_right_bottom_corner_odd    [get_db [get_db base_cells "BOUNDARY_PCORNER*"] .name]

    set_db add_endcaps_left_top_edge_neighbor     [get_db [get_db base_cells "BOUNDARY_NROWRGAP*"] .name]
    set_db add_endcaps_left_bottom_edge_neighbor  [get_db [get_db base_cells "BOUNDARYNROWRGAP*"] .name]
    set_db add_endcaps_right_top_edge_neighbor    [get_db [get_db base_cells "BOUNDARYNROWRGAP*"] .name]
    set_db add_endcaps_right_bottom_edge_neighbor [get_db [get_db base_cells "BOUNDARYNROWRGAP*"] .name]

    set_db add_endcaps_left_top_edge              [get_db [get_db base_cells "FILL3*"] .name]
    set_db add_endcaps_right_top_edge             [get_db [get_db base_cells "FILL3*"] .name]
    set_db add_endcaps_left_bottom_edge           [get_db [get_db base_cells "FILL3*"] .name]
    set_db add_endcaps_right_bottom_edge          [get_db [get_db base_cells "FILL3*"] .name]

    set_db add_endcaps_flip_y true
    set_db add_endcaps_boundary_tap true

    # set_db add_endcaps_min_jog_height 2
    # set_db add_endcaps_min_jog_width 20  
    # set_db add_endcaps_min_horizontal_channel_width 4
    # set_db add_endcaps_min_vertical_channel_width 70

    # Well tap cells
    <PLACEHOLDER>
    set_db add_well_taps_bottom_tap_cell [get_db [get_db base_cells "BOUNDARY_NTAP*"] .name]
    set_db add_well_taps_top_tap_cell    [get_db [get_db base_cells "BOUNDARY_PTAP*"] .name]
    set_db add_well_taps_cell            [get_db [get_db base_cells "TAPCELL*"] .name]
    set_db add_well_taps_rule 50
    # set_db add_well_taps_in_row_offset 12
    # set_db add_well_taps_check_channel true

    # Precise well tap cells (see foundry recommendations)
    # set_db add_well_taps_disable_check_zone_at_boundary vdd
    # set_db add_well_taps_insert_cells {{TAPCELLFIN6* rule 10.0} {TAPCELL* rule 20.0}}

    # Tie cells
    <PLACEHOLDER>
    set_db add_tieoffs_cells [get_db [get_db base_cells "TIEL* TIEH*"] .name]
    set_db add_tieoffs_max_fanout 5
    set_db add_tieoffs_max_distance 50

    # Apply global net connections
    `@innovus_connect_global_nets`
'

# Commands after design initialization
gf_create_step -name innovus_post_init_design '
    `@innovus_post_init_design_physical_mode`

    <PLACEHOLDER> Review backend settings for implementation

    # Flow settings
    if {1} {
    
        # # Extreme flow
        # set_limited_access_feature <PLACEHOLDER>
        # set_db design_flow_effort extreme

        # # Enable early clock flow at placement
        # set_db design_early_clock_flow true

        # # For congested designs
        # set_db design_cong_effort high
        # set_db place_global_cong_effort high
        # set_db place_detail_wire_length_opt_effort high

        # # For timing-critical designs
        # set_db place_global_timing_effort high

        # # For power-critical designs
        # set_db place_detail_irdrop_aware_effort high
        # set_db design_power_effort high
        # set_db opt_power_effort high

        # # For area-critical designs
        # set_db opt_effort high
    }

    # Design and process settings
    if {1} {

        # # Must join pins
        # eval_legacy {setVar mustjoinallports_is_one_pin 1}

        # # Disable user and library data to data checks
        # set_db timing_disable_library_data_to_data_checks true
        # set_db timing_disable_user_data_to_data_checks    true
        
        # # Enable data to data optimization
        # set_db opt_enable_data_to_data_checks true

    }
    
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
        set_db timing_path_based_enable_new_max_borrow_mode true

        # General delay calculation settings
        set_db delaycal_equivalent_waveform_model propagation
        # set_db delaycal_equivalent_waveform_type simulation
        # set_db delaycal_enable_quiet_receivers_for_hold true
        # set_db delaycal_advanced_pin_cap_mode 2

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
        # set_db timing_report_fields {timing_point cell arc fanout load slew slew_mean slew_sigma pin_location delay_mean delay_sigma delay arrival_mean arrival_sigma arrival user_derate total_derate power_domain voltage phys_info}
        # set_db timing_report_fields {cell arc timing_point delay fanout load slew incr_delay arrival total_derate pin_location}
        # # set_db ui_precision_timing 6
        # set_limited_access_feature socv 1
        # set_db timing_analysis_socv true
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
        # set_timing_derate 0 -sigma -cell_check -early [get_lib_cells *BWP*]
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
        # set_db timing_spatial_derate_distance_mode bounding_box
        # # set_db timing_spatial_derate_chip_size 1000
        # # set_db timing_spatial_derate_distance_mode chip_size
    }
    
    # Placement settings
    if {1} {

        # # Use empty filler and allow 1 gap spacing during placement
        # set_db place_detail_use_no_diffusion_one_site_filler true

        # # Do not check follow pin vias and shapes
        # set_db design_ignore_followpin_vias true
        # set_db route_design_ignore_follow_pin_shapes true
        
        # # Strict legalization during optimization
        # set_db opt_honor_fences true

        # # Limit placement density
        # set_db place_global_uniform_density true
        # set_db place_global_max_density 0.6
        # set_db opt_max_density 0.8
        
        # # DPT settings
        # set_db place_detail_color_aware_legal true
        # set_db place_detail_use_check_drc true

        # # Place IO pins automatically
        # set_db place_global_place_io_pins true

        # # For standard cells with pins without half-pitch offset
        # set_db place_detail_allow_border_pin_abut true

        # Additional options
        set_db place_detail_swap_eeq_cells true

    }
    
    # Optimization settings
    if {1} {
    
        # MBFF settings
        # set_db opt_multi_bit_flop_opt true
        # set_db opt_multi_bit_combinational_opt true

        # # Leakage to dynamic power optimization ratio
        # set_db opt_leakage_to_dynamic_ratio 0.5
    
        # DRV fixing settings
        # set_db opt_area_recovery true
        # set_db opt_post_route_fix_clock_drv true
        set_db opt_fix_fanout_load true
        set_db opt_post_route_area_reclaim setup_aware
    }
    
    # Clock settings
    if {1} {
    
        # Cloning settings
        set_db budget_merge_clones true

        # # For congested designs
        # eval_legacy {set_ccopt_property call_cong_repair_during_final_implementation true}

        # Useful skew control
        # <PLACEHOLDER>
        # set_db opt_useful_skew false
        # set_db opt_useful_skew_pre_cts false
        set_db opt_useful_skew_ccopt medium
        set_db cts_target_skew 0.200

        # Disable clock tree latency update for top level
        <PLACEHOLDER> 
        set_db cts_update_clock_latency false
        # set_db cts_update_io_latency false
        set_db budget_write_latency_per_clock true

        # Avoid clock tree cells to be placed nearby
        <PLACEHOLDER>
        set_db cts_cell_halo_rows    2
        set_db cts_cell_halo_sites   4
        # set_db cts_cell_halo_x 5.0
        # set_db cts_cell_halo_y 1.0

        # # Limit maximum net length
        # <PLACEHOLDER>
        # set_db cts_max_source_to_sink_net_length_top 100.0
        # set_db cts_max_source_to_sink_net_length_trunk 100.0
        # set_db cts_max_source_to_sink_net_length_leaf 100.0
        
        # Limit maximum clock tree cells fanout
        <PLACEHOLDER>
        set_db cts_max_fanout 32
        
        # Technology-specific clock tree transition
        <PLACEHOLDER>
        set_db cts_target_max_transition_time 0.100

        # Create clock tree using inverters only
        set_db cts_use_inverters true
        
    }
    
    # Routing settings
    if {1} {

        # Layers
        <PLACEHOLDER>
        set_db design_bottom_routing_layer M2
        set_db design_top_routing_layer M8
        # set_db route_design_bottom_routing_layer 2
        # set_db route_design_top_routing_layer 8

        # # Via pillar
        # set_db route_design_detail_post_route_via_pillar_effort high
        
        # Routing settings
        # set_db add_route_vias_auto true
        set_db route_design_with_litho_driven true
        set_db route_design_with_timing_driven true
        set_db route_design_detail_use_multi_cut_via_effort medium
        # set_db route_design_detail_use_multi_cut_via_effort high
        
        # # Antenna fixing settings
        # set_db route_design_antenna_cell_name [get_db base_cells .name ANTENNA*]
        # set_db route_design_antenna_diode_insertion true
        # set_db route_design_diode_insertion_for_clock_nets true

        # Additional routing settings (see foundry recommendations)
        # set_db route_design_with_via_in_pin 1:1
        # eval_legacy {setNanoRouteMode -drouteStrictlyHonorObsInStandardCell true}
        # set_db check_drc_check_routing_halo true

        # Technology-specific shrink factor
        # <PLACEHOLDER>
        # set_db extract_rc_shrink_factor 0.9
        
        # # Metal stack-specific via priority
        # <PLACEHOLDER>
        # set_db route_design_via_weight [join {
        #     *VIA_A* -1, *VIA_B* 2, ...
        # }]
    }
    
    # Reporting settings
    if {1} {

        # Timing report settings
        set_db timing_time_unit 1ps
        set_table_style -no_frame
        
        # Save optimization timing reports uncompressed
        set_db opt_time_design_compress_reports false
    }
    
    # User constraints
    if {1} {
        # set_interactive_constraint_modes [all_constraint_modes -active]
        # set_max_fanout 30 [current_design]
        # set_max_transition [expr $PERIOD/3] [current_design]
        # set_clock_transition [expr $PERIOD/6] [get_clocks *]
        # set_interactive_constraint_modes {}
    }

    # # Remove dangling ports
    # delete_dangling_ports
'

# Commands before design placement
gf_create_step -name innovus_pre_place '

    # Clock tree cells
    set_db cts_buffer_cells [get_db [get_db base_cells {
        <PLACEHOLDER>DCAP_CLOCK_BUFFER_CELL_NAME:DCCKB*LVT
    }] .name]
    set_db cts_inverter_cells [get_db [get_db base_cells {
        <PLACEHOLDER>DCAP_CLOCK_INVERTER_CELL_NAME:DCCKN*LVT
    }] .name]
    set_db cts_clock_gating_cells [get_db [get_db base_cells {
        <PLACEHOLDER>CLOCK_LATCH_HIGH_CELL_NAME:CKLHQ*LVT
        <PLACEHOLDER>CLOCK_LATCH_LOW_CELL_NAME:CKLNQ*LVT
    }] .name]
    set_db cts_logic_cells [get_db [get_db base_cells {
        <PLACEHOLDER>CLOCK_MUX_CELL_NAME:CKMUX2*LVT
        <PLACEHOLDER>CLOCK_NAND_CELL_NAME:CKND2*LVT
        <PLACEHOLDER>CLOCK_NOR_CELL_NAME:CKNR2*LVT
        <PLACEHOLDER>CLOCK_AND_CELL_NAME:CKAN2*LVT
        <PLACEHOLDER>CLOCK_OR_CELL_NAME:CKOR2*LVT
        <PLACEHOLDER>CLOCK_XOR_CELL_NAME:CKXOR2*LVT
        <PLACEHOLDER>DCAP_CLOCK_INVERTER_CELL_NAME:DCCKN*
    }] .name]

    # Hold fixing cells
    set_db opt_fix_hold_lib_cells [get_db [get_db base_cells {
        <PLACEHOLDER>DATA_DELAY_CELL_NAME:DEL*
        <PLACEHOLDER>DATA_BUFFER_CELL_NAME:BUFF*
    }] .name]

    # NDR for clock routing
    <PLACEHOLDER>
    create_route_rule -name CTS_S \
        -spacing_multiplier {M4:M8 2} \
        -min_cut {VIA1:VIA7 2}
    create_route_rule -name CTS_WS \
        -width_multiplier {M4:M6 2} \
        -spacing_multiplier {M4:M8 2} \
        -min_cut {VIA1:VIA7 2}

    # Route types for clock routing
    <PLACEHOLDER>
    create_route_type -name leaf_rule  -bottom_preferred_layer 5 -top_preferred_layer 6 -route_rule CTS_S
    create_route_type -name trunk_rule -bottom_preferred_layer 7 -top_preferred_layer 8 -route_rule CTS_WS -shield_net VSS
    create_route_type -name top_rule   -bottom_preferred_layer 7 -top_preferred_layer 8 -route_rule CTS_WS -shield_net VSS
    
    # # Via pillar
    # create_stack_via_rules \
    #     -via_pillar_bottom_layer M1 \
    #     -via_pillar_top_layers M4 \
    #     -match_pattern {(.*)(_D)([0-9]*)(\S*)} \
    #     -allow_finger_outside_cell 1 \
    #     -output_rule_lef_file ./in/$TASK_NAME.pillar.lef \
    #     -output_association_file ./in/$TASK_NAME.pillar.tcl \
    #     -process_node <PLACEHOLDER>n5
    # read_physical -add_lefs ./in/$TASK_NAME.pillar.lef
    # source ./in/$TASK_NAME.pillar.tcl

    # Use specified route rules for clock nets
    set_db cts_route_type_leaf   leaf_rule
    set_db cts_route_type_trunk  trunk_rule
    set_db cts_route_type_top    top_rule

    # # Clock and special cells
    <PLACEHOLDER>
    # set_dont_use CK*BWP* true
    # set_dont_use DCCK*BWP* true
    # set_dont_use DEL*BWP* true
    # set_dont_use G*BWP* true

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

    # # High effort optimization exceptions
    # set gf_high_effort_patterns {
    #     *OPT*BWP*
    #     *BWP*ULVT*
    #     *BWP*LVT*
    #     *D10BWP*
    #     *D11BWP*
    #     *D12BWP*
    #     *D13BWP*
    #     *D14BWP*
    #     *D15BWP*
    #     *D16BWP*
    # }
    #
    # # Set high effort optimization cells and mark them dont use
    # set_db opt_high_effort_lib_cells [get_db [get_db base_cells [join $gf_high_effort_patterns] -if !.dont_use] .name]
    # foreach pattern $gf_high_effort_patterns {set_dont_use $pattern true}

    # # Set dont touch objects
    # foreach inst [get_db [get_db insts  {*_preserve *_preserved *_preserve_*}] .name] {set_dont_touch $inst true}
    # foreach net [get_db [get_db nets  {*_preserve *_preserved *_preserve_*}] .name] {set_dont_touch $net true}

    # # Placement constraints    
    # set_db [get_db base_cells *] .left_padding 1

    # # Dont touch instances and modules
    # set_db [gf_get_insts <PLACEHOLDER>pattern] .dont_touch true
    # set_db [gf_get_hinsts <PLACEHOLDER>pattern] .dont_touch true
    
    # # Clock propagation exceptions
    # set_db pin:<PLACEHOLDER>/inst/pin .cts_sink_type stop
    # set_db pin:<PLACEHOLDER>/inst/pin .cts_sink_type ignore
    # set_db pin:<PLACEHOLDER>/inst/pin .cts_sink_type exclude

    # # Incorrect clock pins fix
    # foreach delay_corner_name [get_db delay_corners .name] {
    #     set_db pin:<PLACEHOLDER>/inst/pin .cts_capacitance_override -index "delay_corner $delay_corner_name" 1ff
    # }

    # # Dont touch port nets
    # set_db [get_db ports .net -if !.is_clock] .dont_touch true

    # # Skip routing attribute
    # set_db [get_db ports .net] .skip_routing true
    # set_db net:<PLACEHOLDER>name .skip_routing true
    
    # # Interactive constraints
    # set_interactive_constraint_mode [get_db [get_db constraint_modes -if {.is_setup||.is_hold}] .name]
    # 
    # # Set macro latency
    # # set_clock_latency -0.000 [get_pins */CLK]

    # # Add regions
    # create_guide -name * -area {*}
    # create_region -name * -area {*}
    # create_fence -name * -area {*}
    
    # RC factors
    set INNOVUS_RC_FACTORS [join {`$INNOVUS_RC_FACTORS -optional`}]
    if {[llength $INNOVUS_RC_FACTORS]} {source $INNOVUS_RC_FACTORS}

    # # Attach and spread IO buffers
    # if {1} {
    #     add_io_buffers \
    #         -suffix _GF_io_buffer \
    #         -in_cells <PLACEHOLDER>cell_for_inputs  \
    #         -out_cells <PLACEHOLDER>cell_for_outputs \
    #         -port -exclude_clock_nets
    # } else {
    #     gf_attach_io_buffers <PLACEHOLDER>cell_for_inputs <PLACEHOLDER>cell_for_outputs
    # }
    # set io_buffers [get_db insts *_GF_io_buffer]
    # create_inst_space_group -group_name GF_io_buffers -inst [get_db $io_buffers .name] -spacing_x 1.000 -spacing_y 1.000
    # set_db place_detail_check_inst_space_group true
    # set_db $io_buffers .place_status placed
    # place_detail -inst [get_db $io_buffers .name]
    # delete_inst_space_group -group_name GF_io_buffers
    # reset_db place_detail_check_inst_space_group
    # place_detail -inst [get_db $io_buffers .name]
    # set_db $io_buffers .place_status fixed
    # check_place
    #
    # # Fix IO port nets
    # set_db $io_buffers .dont_touch true
    # foreach net [get_db $io_buffers .pins.net] {
    #     if {[get_db ports [get_db $net .name]] != ""} {
    #         set_db $net .dont_touch true
    #         puts "Port net \033\[97m[get_db $net .name]\033\[0m: .dont_touch=[get_db $net .dont_touch]."
    #     }
    # }

    # # Add extra space to macro ports
    # foreach pin [get_db pins <PLACEHOLDER>*MEM*/A?[*]] {
    #     set_db $pin .net.preferred_extra_space 1
    # }

    # # Add extra space between specific instances
    # create_inst_space_group -group_name PLACEHOLDER -inst [get_db PLACEHOLDER .name] -spacing_x 1.000 -spacing_y 1.000
    # set_db place_detail_check_inst_space_group true

    # # Preplace instances
    # set preplaced {}
    #
    # # Speed up RAM clock pins
    # lappend preplaced [gf_bufferize_pins -buffer_cell <PLACEHOLDER>DCCKD4 -placed -pins [get_db pins */CLK]]
    #
    # # Add and preplace buffers for critical pins to balance delay
    # set pins_to_bufferize [get_db -if .net.name!=<PLACEHOLDER>FE*TIE* -u \
    #     [get_db [get_db ports "<PLACEHOLDER>PORTS*"] .net.drivers "*/<PLACEHOLDER>PAD"] \
    # .inst.pins "*/I"]
    #
    # # Bufferize selected pins
    # lappend preplaced [gf_bufferize_pins -buffer_cell <PLACEHOLDER>BUFFD6 -placed -pins $pins_to_bufferize]
    #
    # # Magnify instances to selected pins
    # lappend preplaced [list [gf_magnify_pin_fan_instances -pins $pins_to_bufferize]]
    #
    # # Legalize preplaced instances
    # set preplaced_insts [get_db -u [join $preplaced] -if .obj_type==inst]
    # if {$preplaced_insts != {}} {
    #     place_detail -inst [get_db $preplaced_insts .name]
    #     set_db $preplaced_insts .place_status fixed
    #     redirect { foreach driver $preplaced_insts {
    #         puts "puts {[get_db $driver .name] fixed at [get_db $driver .location] [get_db $driver .orient]}"
    #         puts "catch {place_inst [get_db $driver .name] [get_db $driver .location] [get_db $driver .orient] -fixed}"
    #         puts {}
    #     }} > ./scripts/$TASK_NAME.preplace.tcl
    # }

    # # Reset ideal network and clock tree latencies 
    # `@innovus_reset_ideal_clock_constraints`
    
    # # Default path groups
    # reset_path_group -all
    # create_basic_path_groups -expanded

    # # User-defined margins
    # set_path_adjust_group -name reg2reg -from [all_register] -to [all_register]
    # set_path_adjust -0.400 -view <PLACEHOLDER>analysis_view_name -path_adjust_group reg2reg -setup
    
    # # Write database between placement and optimization
    # set_db place_opt_post_place_tcl place_opt_post_place.tcl
    # puts "write_db ./out/$TASK_NAME.place_opt_post_place.innovus.db" > place_opt_post_place.tcl
    
    # Report tool options
    redirect ./reports/$TASK_NAME.settings.rpt {
        get_db place_*
        get_db opt_*
        get_db ccopt_*
        get_db route_*
    }
    
    # # Write intermediate database
    # write_db ./out/$TASK_NAME.intermediate.innovus.db
'

# Commands after design placement
gf_create_step -name innovus_post_place '

    # # Write out ILM
    # mkdir -p ./out/$TASK_NAME/
    # write_ilm -model_type timing -type_flex_ilm flexilm -opt_stage prects -overwrite -to_dir ./out/$TASK_NAME/$DESIGN_NAME.prects.ilm

    # # Write out LEF
    # if {[catch {set top_layer [get_db design_top_routing_layer]}]} {set top_layer [get_db route_design_top_routing_layer]}
    # set top_layer [lindex [lsort -integer -decreasing [concat [get_db [get_db layers $top_layer] .route_index] [get_db [get_db nets [concat [get_db init_power_nets] [get_db init_ground_nets]]] .special_wires.layer.route_index -u]]] 0]
    # write_lef_abstract ./out/$TASK_NAME.pg.lef -no_cut_obs -extract_block_obs -top_layer $top_layer -stripe_pins -pg_pin_layers $top_layer
    # write_lef_abstract ./out/$TASK_NAME.lef -no_cut_obs -extract_block_obs -top_layer $top_layer
'

# Commands before clock tree implementation
gf_create_step -name innovus_pre_clock '

    # # Sinks to balance and to ignore
    # set gf_balance_pins [get_db -u [gf_get_fanin_pins -to [get_db ports <PLACEHOLDER>PORTS*] -through <PLACEHOLDER>*/PAD */I */Z -patterns <PLACEHOLDER>*/S -verbose 1]]
    # set_db $gf_balance_pins .cts_sink_type stop
    # set gf_ignore_pins [get_db [get_db ports {<PLACEHOLDER>PORTS*}] .net.drivers.inst.pins -if .base_name==<PLACEHOLDER>I -u]
    # set_db $gf_ignore_pins .cts_sink_type ignore

    # # # Create ccopt specification
    # # create_clock_tree_spec
    #
    # # # Exclusive skew groups
    # # foreach mode [get_db constraint_modes .name] {
    # #     create_skew_group -name <PLACEHOLDER>name/$mode -target_skew <PLACEHOLDER>0.050 -exclusive_sinks [get_db $gf_balance_pins .name]
    # #     create_skew_group -name <PLACEHOLDER>name/$mode -target_skew <PLACEHOLDER>skew -exclusive_sinks <PLACEHOLDER>pins
    # # }
    #
    # # # Balance several skew groups
    # # create_skew_group -name balance_sg1_sg2 -balance_skew_groups {sg1 sg2} -target_skew <PLACEHOLDER>0.050

    # Prevent routing over macros
    # create_route_blockage -name clock_no_routing -layers {M4 VIA4 M5} -rects [gf_size_bboxes [get_db [get_db insts -if .area>100] .bbox] {-0.000 -0.000 +0.000 +0.000}]
    
    # Prevent routing near ports
    # create_route_blockage -name port_blockage -layers {M3 M5} -rects [gf_size_bboxes [get_db current_design .bbox] {-0.000 -0.000 +0.000 +0.000}]
'

# Commands after clock tree implementation
gf_create_step -name innovus_post_clock '

    # # Write out ILM
    # mkdir -p ./out/$TASK_NAME/
    # write_ilm -model_type timing -type_flex_ilm flexilm -opt_stage postcts -overwrite -to_dir ./out/$TASK_NAME/$DESIGN_NAME.postcts.ilm

    # # Delete route blockages created for clock
    # catch {delete_route_blockages -name clock_no_routing}
    
    # # Write intermediate database
    # write_db ./out/$TASK_NAME.intermediate.innovus.db
'

# Commands before post-clock hold fix
gf_create_step -name innovus_pre_clock_opt_hold '

    # Do not fix hold at interfaces
    # set_db opt_fix_hold_ignore_path_groups {in2reg in2out reg2out}
    set_db opt_fix_hold_ignore_path_groups {default}

    # # Allow setup TNS degradation
    # set_db opt_fix_hold_allow_setup_tns_degradation true

    # # Do not fix huge hold violations
    # set_db opt_fix_hold_slack_threshold -0.250

    # # Do not over-fix hold
    # set_db opt_hold_target_slack -0.025
'

# Commands after post-clock hold fix
gf_create_step -name innovus_post_clock_opt_hold '

    # Reset used earlier options
    reset_db opt_fix_hold_allow_setup_tns_degradation
    reset_db opt_fix_hold_slack_threshold
    reset_db opt_hold_target_slack
'

# Commands before routing
gf_create_step -name innovus_pre_route '

    # # Extraction settings (Quantus required)
    # set_db extract_rc_effort_level high

    # Add fillers with prefix (pre-route mode)
    set_db add_fillers_prefix {FILLER}
    add_fillers
    check_filler
    # add_fillers -fix_vertical_max_length_violation 
    # check_filler -vertical_stack_max_length
    
    # SI settings
    set_db delaycal_enable_si true
    set_db route_design_with_si_driven true
    set_db route_design_detail_post_route_spread_wire true
    # set_db si_delay_enable_report true
    # set_db si_glitch_enable_report true
    # set_db si_use_infinite_timing_window true

    # # Limit number of routing iterations for debug
    # set_db route_design_detail_end_iteration 3
'

# Commands after routing
gf_create_step -name innovus_post_route '

    # # Write out ILM
    # mkdir -p ./out/$TASK_NAME/
    # write_ilm -model_type timing -type_flex_ilm flexilm -opt_stage postroute -overwrite -to_dir ./out/$TASK_NAME/$DESIGN_NAME.postroute.ilm

    # SI settings
    # set_db route_design_detail_post_route_spread_wire false

    # Advanced SI analysis settings (see foundry recommendations)
    # set_db si_analysis_type aae 
    # set_db si_delay_separate_on_data true
    # set_db si_delay_delta_annotation_mode lumpedOnNet
    # set_db si_individual_aggressor_simulation_filter true
    # set_db si_reselection all 
    # set_db si_glitch_input_voltage_high_threshold 0.2
    # set_db si_glitch_input_voltage_low_threshold 0.2
    set_db si_aggressor_alignment timing_aware_edge

    # Update route engine options
    set_db extract_rc_engine post_route

    # Reset number of routing iterations
    if {[llength [get_db markers]] < 10000} {
        reset_db route_design_detail_end_iteration
    }
    
    # # Write intermediate database
    # write_db ./out/$TASK_NAME.intermediate.innovus.db
'

# Commands before post-route setup and hold optimization
gf_create_step -name innovus_pre_route_opt_setup_hold '
    
    # # Reset previous settings
    # reset_db opt_hold_target_slack

'

# Commands after post-route setup and hold optimization
gf_create_step -name innovus_post_route_opt_setup_hold '
    set INNOVUS_DFM_VIA_SWAP_SCRIPT {`$INNOVUS_DFM_VIA_SWAP_SCRIPT -optional`}
    
    # # Re-insert fillers by priority (post-route mode)
    # delete_filler
    # if {1} {
    #     foreach cells [get_db add_fillers_cells] {
    #         add_fillers -prefix FILLER -base_cells $cells
    #     }
    #     
    # # Re-insert fillers in single pass (post-route mode)
    # } else {
    #     add_fillers -prefix FILLER
    # }
    
    # # Fix left violations
    # check_filler
    # # add_fillers -fill_gap -prefix FILLER

    # DFM via replacement
    if {[file exists $INNOVUS_DFM_VIA_SWAP_SCRIPT]} {
        eval_legacy [subst {
            source {$INNOVUS_DFM_VIA_SWAP_SCRIPT}
        }]
    }
'

# Commands before assemble design
gf_create_step -name innovus_pre_assemble '
    # Reserved
'

# Commands before assemble design
gf_create_step -name innovus_post_assemble '

    # Uniquify assembled partitions
    foreach clone [get_db partitions .clone.name] {uniquify_partition -hinst $clone}
'

################################################################################
# Floorplanning flow steps
################################################################################

# Floorplan automation procedures
gf_create_step -name innovus_procs_interactive_design '

    # # Initialize tracks pattern
    # proc gf_init_tracks {} {
    #     add_tracks -pitches [join {
    #         m1 vert 0.000 
    #         m2 horiz 0.000
    #     }] -offset [join {
    #         m1 vert 0.000 
    #         m2 horiz 0.000
    #     }] -width_pitch_pattern [join {
    #         m0 offset 0.0 
    #         width 0.000 pitch 0.000 
    #         {width 0.000 pitch 0.000 repeat 0}
    #         width 0.000 pitch 0.000
    #         width 0.000 pitch 0.000
    #         {width 0.000 pitch 0.000 repeat 0}
    #         width 0.000 pitch 0.000
    #     }] -mask_pattern [join {
    #         m0 2 1 2 1 2 1 2 1 2 1
    #         m1 1 2 
    #         m2 2 1 
    #         m3 1 2
    #     }]
    # }
    
    # Add physical cells after floorplan modifications
    proc gf_init_rows {} {
        #set_layer_preference power -is_visible 0

        # # Delete existing core rows
        # foreach site [get_db [get_db rows .site -if .class==core -u] .name] {delete_row -site $site}

        # Initialize core rows
        # create_row -site core -area [get_db current_design .core_bbox]
        # create_row -site bcoreExt -area [get_db current_design .core_bbox]
        init_core_rows
        split_row
    }

    # Reset automatic placement blockages
    proc gf_reset_place_blockages {} {
        delete_obj [get_db place_blockages finishfp_*]
    }
    
    # Fill narrow channels with placement blockages
    proc gf_init_place_blockages {} {
        gf_reset_place_blockages
    
        # Placement blockages
        set_db finish_floorplan_active_objs {macro hard_blockage soft_blockage core}
        finish_floorplan -fill_place_blockage hard 5
        finish_floorplan -fill_place_blockage soft 30
        
        # # Delete blockages at the edges
        # deselect_obj -all
        # select_obj [get_db place_blockages finish* -if .rects.ll.x>=[expr [get_db current_design .core_bbox.ur.x]-30.0]]
        # select_obj [get_db place_blockages finish* -if .rects.ur.x<=[expr [get_db current_design .core_bbox.ll.x]+30.0]]
        # delete_selected_from_floorplan
    }   
    
    # Init macros placement halos
    proc gf_init_macros_locations_and_halos {} {
        set x0 [get_db current_design .core_bbox.ll.x]
        set y0 [get_db current_design .core_bbox.ll.y]
        
        set x_grid 0.000
        set y_grid 0.000
        
        set x_halo 0.000
        set y_halo 0.000
        
        # Align macros to the grid
        foreach macro [get_db insts -if .area>100] {
            set location [get_transform_shapes -inst $macro -local_pt {0 0}]
            set aligned_location [list \
                [expr $x0+$x_grid*int(0.5+([lindex $location 0]-$x0)/$x_grid)] \
                [expr $y0+$y_grid*int(0.5+([get_db $macro .location.y]-$y0)/$y_grid)] \
            ]
            set_db $macro .location [list \
                [expr ([get_db $macro .location.x]+[lindex $aligned_location 0]-[lindex $location 0])] \
                [expr ([get_db $macro .location.y]+[lindex $aligned_location 1]-[lindex $location 1])] \
            ]
        }

        # Align cell halos to the grid
        foreach cell [get_db -u [get_db insts -if .area>100] .base_cell] {
            set hl [expr "[get_db $cell .bbox.ll.x]-$x_grid*int(-0.5+([get_db $cell .bbox.ll.x]-$x_halo)/$x_grid)"]
            set hr [expr "$x_grid*int(0.5+([get_db $cell .bbox.ur.x]+$x_halo)/$x_grid)-[get_db $cell .bbox.ur.x]"]
            set hb [expr "[get_db $cell .bbox.ll.y]-$y_grid*int(-0.5+([get_db $cell .bbox.ll.y]-$y_halo)/$y_grid)"]
            set ht [expr "$y_grid*int(0.5+([get_db $cell .bbox.ur.y]+$y_halo)/$y_grid)-[get_db $cell .bbox.ur.y]"]
            
            puts "Halos: L=$hl R=$hr B=$hb T=$ht $cell"
            create_place_halo -orient r0 -cell [get_db $cell .name] -halo_deltas [list $hl $hb $hr $ht]
        }
    }
    
    # Flip left corner endcaps
    proc gf_flip_left_endcaps {cell_pattern} {
        set results {}
        get_db insts -if .base_cell.name==$cell_pattern -foreach {
            if {[get_db [get_obj_in_area -obj_type row -areas [list \
                [expr [get_db $object .bbox.ll.x] - [get_db $object .base_cell.site.size.x] / 2] \
                [expr [get_db $object .bbox.ll.y] + [get_db $object .base_cell.site.size.y] / 2] \
                [expr [get_db $object .bbox.ll.x] - [get_db $object .base_cell.site.size.x] / 2] \
                [expr [get_db $object .bbox.ll.y] + [get_db $object .base_cell.site.size.y] / 2] \
            ]] -if ".site==[get_db $object .base_cell.site]"] == {}} {
                lappend results $object
            }
        }
        get_db $results .name -u -foreach {flip_or_rotate_obj -flip my -objs $object}
        return $results
    }

    # Flip right corner endcaps
    proc gf_flip_right_endcaps {cell_pattern} {
        set results {}
        get_db insts -if .base_cell.name==$cell_pattern -foreach {
            if {[get_db [get_obj_in_area -obj_type row -areas [list \
                [expr [get_db $object .bbox.ur.x] + [get_db $object .base_cell.site.size.x] / 2] \
                [expr [get_db $object .bbox.ll.y] + [get_db $object .base_cell.site.size.y] / 2] \
                [expr [get_db $object .bbox.ur.x] + [get_db $object .base_cell.site.size.x] / 2] \
                [expr [get_db $object .bbox.ll.y] + [get_db $object .base_cell.site.size.y] / 2] \
            ]] -if ".site==[get_db $object .base_cell.site]"] == {}} {
                lappend results $object
            }
        }
        get_db $results .name -u -foreach {flip_or_rotate_obj -flip my -objs $object}
        return $results
    }

    # Delete physical cells before floorplan modifications
    proc gf_reset_physical_cells {} {
        delete_filler -prefix FILLER
        delete_filler -prefix ENDCAP
        delete_filler -prefix WELLTAP
    }

    # Add physical cells after floorplan modifications
    proc gf_init_physical_cells {} {

        # Delete physical cells
        gf_reset_physical_cells
        
        # Place boundary cells
        add_endcaps -prefix ENDCAP
        # <PLACEHOLDER>
        # gf_flip_left_endcaps BOUNDARY_?CORNER*
        # gf_flip_right_endcaps BOUNDARY_?CORNER*

        # Place well-tap cells
        <PLACEHOLDER>
        add_well_taps -prefix WELLTAP -checker_board -cell_interval 50

        # Run checks
        check_endcaps
        check_well_taps
    }

    # Init boundary nets
    proc gf_init_boundary_wires {} {
        delete_routes -net _BOUNDARY_*
        
        set_db finish_floorplan_active_objs die
        # <PLACEHOLDER>
        # add_dummy_boundary_wires -layer {M1 M2 M3 M4} -space {0.000 0.000 0.000 0.000} 
        finish_floorplan -add_boundary_blockage

        set_layer_preference eol -is_visible 1
        set_db finish_floorplan_active_objs row
        finish_floorplan -add_boundary_end_of_line_blockage

        check_floorplan
    }

    # Initialize placement halo
    proc gf_init_halo {} {
        # gf_init_macros_locations_and_halos
        create_route_halo -all_blocks -space 0.000 -bottom_layer M1 -top_layer M5
        create_place_halo -all_blocks -orient R90 -halo_deltas {0.000 0.000 0.000 0.000}
    }

    # Snap blocks
    proc gf_snap_insts {insts} {
        set xoffset 0.000
        set yoffset 0.000
        set xsnap 0.000
        set ysnap 0.000
        foreach inst $insts {
            set location [get_transform_shapes -local_pt "$xoffset $yoffset" -inst [get_db $inst]]
            set offset [list \
                [expr int([lindex $location 0]/$xsnap+0.5)*$xsnap-[lindex $location 0]+[get_db current_design .core_bbox.ll.x]] \
                [expr int([lindex $location 1]/$ysnap+0.5)*$ysnap-[lindex $location 1]+[get_db current_design .core_bbox.ll.y]] \
            ]
            if {([expr abs([lindex $offset 0])]>1e-9) || ([expr abs([lindex $offset 1])]>1e-9)} {
                set new_location [list \
                    [expr [get_db $inst .location.x]+[lindex $offset 0]] \
                    [expr [get_db $inst .location.y]+[lindex $offset 1]] \
                ]
                puts "\033\[33;43m \033\[0m $inst moved from [get_db $inst .location] to {$new_location}"
                set_db $inst .location $new_location
            } else {
                puts "\033\[32;42m \033\[0m $inst left at [get_db $inst .location]"
            }
        }
    }
    proc gf_snap_selected_blocks {} { gf_snap_insts [get_db selected -if .area>100] }
    proc gf_snap_all_blocks {} { gf_snap_insts [get_db insts -if .area>100] }

    # Unplace all ports
    proc gf_reset_ports {} {
        set_partition_pin_status -status unplaced -quiet \
            -partition [get_db current_design .name] \
            -pins [get_db ports .name]
    }
    
    # Design-specific ports initialization
    proc gf_init_ports {} {
        gf_reset_ports
    
        # Batch mode on
        set_db assign_pins_edit_in_batch true
    
        # Align macro ports
        align_pins
        # # Clock port                
        # edit_pin -pin CLOCK -layer_vertical M7 -edge 0 -snap track -assign {0.000 0.000} -pin_width 0.000 -pin_depth 0.000

        # # Spread grouped ports
        # <PLACEHOLDER>
        # foreach ports [list \
        #     [get_db ports -if .name==pattern] \
        # ] {
        #     edit_pin -snap track \
        #         -edge 0 \
        #         -spread_direction clockwise \
        #         -spread_type center \
        #         -layer_vertical M4 \
        #         -offset_start 0.0 \
        #         -spacing 8 -unit track \
        #         -fixed_pin 1 -fix_overlap 1 \
        #         -pin [get_db [get_db $ports -if .place_status==unplaced] .name]
        # }
    
        # # Projection of instance pins to vertical edge
        # <PLACEHOLDER>
        # foreach pin [list \
        #     [get_db pins instance_pin_patterns] \
        # ] {
        #     set ports [get_db -u [concat [get_db $pin .net.drivers] [get_db $pin .net.loads]] -if .obj_type==port]
        #     if {![llength $ports]} {
        #         if {[get_db $pin .direction]=="in"} {
        #             set ports [get_db -u [all_fanin -to $pin] -if .obj_type==port]
        #         } elseif {[get_db $pin .direction]=="out"} {
        #             set ports [get_db -u [all_fanout -from $pin] -if .obj_type==port]
        #         }
        #     }
        #     edit_pin -snap track \
        #         -edge 0 \
        #         -layer_vertical M4 \
        #         -fixed_pin 1 -fix_overlap 1 \
        #         -assign [list [get_db current_design .bbox.ll.x] [get_db $pin .location]\
        #         -pin [get_db [get_db $ports -if .place_status==unplaced] .name]
        # }
    
        # # All the rest inputs
        # <PLACEHOLDER>
        # edit_pin -snap track \
        #     -edge 0 \
        #     -spread_direction clockwise \
        #     -spread_type center \
        #     -layer_vertical M4 \
        #     -offset_start 0.0 \
        #     -spacing 8 -unit track \
        #     -fixed_pin 1 -fix_overlap 1 \
        #     -pin [get_db [get_db ports -if .place_status==unplaced&&.direction==in] .name]
        # # All the rest outputs
        # edit_pin -snap track \
        #     -edge 2 \
        #     -spread_direction clockwise \
        #     -spread_type center \
        #     -layer_vertical M4 \
        #     -offset_start 0.0 \
        #     -spacing 8 -unit track \
        #     -fixed_pin 1 -fix_overlap 1 \
        #     -pin [get_db [get_db ports -if .place_status==unplaced&&.direction==out] .name]

        # Batch mode off
        set_db assign_pins_edit_in_batch false
    }

    # Initialize power grid in all layers
    proc gf_init_power_grid_M4 {} {

        # # Customization
        # <PLACEHOLDER>
        # set nets {VDD VSS}
        
        # (!) Note: 
        # This is a mix of commands for different metal stacks
        # Please remove unnecessary code manually
        
        # # Use custom tracks
        # gf_init_tracks

        # # Remove existing follow pins, stripes and blockages
        # catch {delete_route_blockage -name add_stripe_blockage}
        # delete_routes -net $nets -status routed -shapes {ring stripe corewire followpin ring padring}
        # delete_pg_pins -net $nets

        # # Default via generation options
        # reset_db generate_special_via_*
        # set_db generate_special_via_preferred_vias_only keep
        # set_db generate_special_via_allow_wire_shape_change false
        # set_db generate_special_via_opt_cross_via true

        # # Default add stripes options
        # reset_db add_stripes_*
        # set_db add_stripes_spacing_type center_to_center
        # # set_db add_stripes_stop_at_last_wire_for_area 1
        # set_db add_stripes_opt_stripe_for_routing_track shift
        # set_db add_stripes_skip_via_on_wire_shape {iowire}
        
        # # Special PG vias
        # catch {
        #     create_via_definition -name PGVIA4 -bottom_layer M4 -cut_layer VIA4 -top_layer M5 \
        #         -bottom_rects {{-0.000 -0.000} {0.000 0.000}} \
        #         -top_rects {{-0.000 -0.000} {0.000 0.000}} \
        #         -cut_rects {{-0.000 -0.000} {-0.000 0.000} {-0.000 -0.000} {0.000 0.000} {0.000 -0.000} {0.000 0.000}}
        # }

        # # M1/M2 blockages over macros
        # create_route_blockage -name add_stripe_blockage -layer {M1 M2} \
        #     -rects [gf_size_bboxes [get_db $macros .bbox] {-0.000 -0.000 0.000 0.000}]

        # # M1 blockages at core edges
        # create_route_blockage -name add_stripe_blockage -layers {M1} -rects [join \
        #     [get_computed_shapes -output rect \
        #         [get_computed_shapes \
        #             [get_db rows .rect] \
        #             SIZE \
        #             0.000 \
        #         ] \
        #         ANDNOT \
        #         [get_computed_shapes \
        #             [get_computed_shapes \
        #                 [get_db rows .rect] \
        #                 SIZEY \
        #                 -0.000 \
        #             ] \
        #             SIZEX \
        #             -0.000 \
        #         ] \
        #     ] \
        # ]
        
        # # M2/M3 Core rings
        # reset_db add_rings_*
        # set_db add_rings_stacked_via_top_layer M3
        # set_db add_rings_skip_via_on_wire_shape {stripe blockring}
        # set_db add_rings_break_core_ring_io_list [get_db $macros .name]
        # add_rings -nets [concat $nets $nets $nets $nets] \
        #     -type core_rings -follow core \
        #     -layer {top M2 bottom M2 left M3 right M3} \
        #     -width {top 0.000 bottom 0.000 left 0.000 right 0.000} \
        #     -spacing {top 0.000 bottom 0.000 left 0.000 right 0.000} \
        #     -offset {top 0.000 bottom 0.000 left 0.000 right 0.000} \
        #     -threshold 0 -jog_distance 0 -use_wire_group 1 -snap_wire_center_to_grid none
        
        # # M1/M2 Pads routing
        # reset_db route_special_*
        # route_special \
        #     -connect {pad_pin} \
        #     -block_pin_target {nearest_target} \
        #     -pad_pin_layer_range {M1 M2} \
        #     -pad_pin_target {block_ring ring} \
        #     -pad_pin_port_connect {all_port all_geom} \
        #     -crossover_via_layer_range {M1 AP} \
        #     -target_via_layer_range {M1 AP} \
        #     -allow_layer_change 1 -layer_change_range {M1 M4} \
        #     -allow_jogging 0 \
        #     -nets $nets 
        
        # # M1 follow pins
        # reset_db route_special_*
        # set_db route_special_connect_broken_core_pin true
        # # set_db route_special_core_pin_stop_route CellPinEnd
        # # set_db route_special_core_pin_ignore_obs overlap_obs
        # set_db route_special_via_connect_to_shape noshape
        # route_special \
        #     -connect core_pin \
        #     -core_pin_layer M1 \
        #     -core_pin_width 0.000 \
        #     -allow_jogging 0 \
        #     -allow_layer_change 0 \
        #     -core_pin_target none \
        #     -nets $nets
        #
        # # # Force follow pins masks
        # # set_db [get_db [get_db nets $nets] .special_wires -if .shape==followpin] .mask 1
        
        # # M2/M4 follow pins duplication (fast)
        # foreach net $nets {
        #     foreach shape [get_db net:$net .special_wires -if .shape==followpin] {
        #         create_shape -layer M2 -width 0.000 -shape followpin -status routed -net $net -path_segment [get_db $shape .path]
        #         create_shape -layer M4 -width 0.000 -shape followpin -status routed -net $net -path_segment [get_db $shape .path]
        #     }
        # }
        
        # # M2/M4 follow pins duplication (classic)
        # set_db add_stripes_stacked_via_bottom_layer M1
        # set_db add_stripes_stacked_via_top_layer M1
        # set_db edit_wire_shield_look_down_layers 0
        # set_db edit_wire_shield_look_up_layers 0
        # set_db edit_wire_layer_min M1
        # set_db edit_wire_layer_max M1
        # set_db edit_wire_drc_on false
        # deselect_obj -all
        # select_routes -shapes followpin -layer M1
        # edit_duplicate_routes -layer_horizontal M2
        # # edit_update_route_width -width_horizontal 0.000
        # # edit_resize_routes -keep_center_line 1 -direction y -side high -to 0.000
        # edit_duplicate_routes -layer_horizontal M4
        # # edit_update_route_width -width_horizontal 0.000
        # # edit_resize_routes -keep_center_line 1 -direction y -side high -to 0.000
        # reset_db edit_wire_drc_on
        # reset_db edit_wire_shield_look_down_layers
        # reset_db edit_wire_shield_look_up_layers
        # reset_db edit_wire_layer_min
        # reset_db edit_wire_layer_max

        # # Optional: colorize DPT layers
        # set_db [get_db net:VDD .special_wires -if .layer.name==M2] .mask 2
        # set_db [get_db net:VSS .special_wires -if .layer.name==M2] .mask 2
        # set_db [get_db net:VDD .special_wires -if .layer.name==M4] .mask 1
        # set_db [get_db net:VSS .special_wires -if .layer.name==M4] .mask 1

        # # Follow pin orthogonal vias
        # set_db add_stripes_skip_via_on_pin {pad block cover standardcell}
        # set_db add_stripes_skip_via_on_wire_shape {ring blockring corewire blockwire iowire padring fillwire noshape}
        # # set_db generate_special_via_rule_preference {VIA12*}
        # update_power_vias -selected_wires 1 -add_vias 1 -bottom_layer M1 -top_layer M2 -orthogonal_only 0
        # update_power_vias -selected_wires 1 -add_vias 1 -bottom_layer M1 -top_layer M2 -orthogonal_only 0 -split_long_via {0.000 0.000 0.000 0.000}
        # deselect_obj -all
        # reset_db add_stripes_skip_via_on_pin
        # reset_db add_stripes_skip_via_on_wire_shape
        # delete_markers -all

        # # M3 stripes (regular)
        # set_db add_stripes_stacked_via_bottom_layer M2
        # set_db add_stripes_stacked_via_top_layer M3
        # set_db add_stripes_skip_via_on_pin {pad block cover standardcell}
        # set_db add_stripes_route_over_rows_only true
        # set_db generate_special_via_rule_preference {VIA23_*}
        # add_stripes \
        #     -layer M3 \
        #     -direction horizontal \
        #     -width 0.000 \
        #     -spacing [expr 1*0.000] \
        #     -set_to_set_distance [expr 2*0.000] \
        #     -start_offset 0.000 \
        #     -snap_wire_center_to_grid grid \
        #     -nets $nets

        # # M3 stripes (stapling)
        # set_db add_stripes_stacked_via_bottom_layer M1
        # set_db add_stripes_stacked_via_top_layer M4
        # set_db add_stripes_skip_via_on_pin {pad block cover standardcell}
        # set_db add_stripes_route_over_rows_only true
        # set_db add_stripes_remove_floating_stapling true
        # set_db generate_special_via_rule_preference {VIA12_* VIA23_* VIA34_*}
        # add_stripes \
        #     -layer M3 \
        #     -direction vertical \
        #     -width 0.000 \
        #     -stapling {0.000 M2} \
        #     -set_to_set_distance [expr 0.000*NTRACKS] \
        #     -start_offset 0.000 \
        #     -snap_wire_center_to_grid grid \
        #     -nets $nets
        #
        # # Delete PG pins in lower metals
        # delete_pg_pins -net $nets
    }
    
    # Initialize power grid in all layers
    proc gf_init_power_grid_M6 {} {
        gf_init_power_grid_M4
    
        # # Customization
        # <PLACEHOLDER>
        # set nets {VDD VSS}
        # set macro_area_threshold 100
        
        # # Macros detection
        # set macros [get_db insts -if .area>$macro_area_threshold]
        
        # # M5 stripes over endcaps
        # set_db add_stripes_stacked_via_bottom_layer M2
        # set_db add_stripes_stacked_via_top_layer M5
        # set_db add_stripes_skip_via_on_pin {pad cover standardcell}
        # foreach area [gf_get_endcap_areas] {
        #     set width 0.500
        #     set wspacingidth 0.500
        #     set insts [get_obj_in_area -area $area -obj_type inst]
        #     <PLACEHOLDER>
        #     set endcaps_left_count [llength [get_db $insts -if .base_cell.name==BOUNDARY_LEFT]]
        #     set endcaps_right_count [llength [get_db $insts -if .base_cell.name==BOUNDARY_RIGHT]]
        #     if {($endcaps_left_count >= 5) || ($endcaps_right_count >= 5)} {
        #         if {$endcaps_left_count < $endcaps_right_count} {
        #             set x2 [lindex $area 2]
        #             set x1 [expr $x2 - 2 * $width - $spacing]
        #         } else {
        #             set x1 [lindex $area 0]
        #             set x2 [expr $x1 + 2 * $width + $spacing]
        #         }
        #         set area [list $x1 [expr [lindex $area 1] - 0.1]  $x2 [expr [lindex $area 3] + 0.1]]
        #         create_marker -description "Endcap area for power stripes" -type "Endcap area" -bbox $area
        #         add_stripes \
        #             -number_of_sets 1 \
        #             -layer M5 \
        #             -width $spacing \
        #             -spacing $spacing  \
        #             -direction vertical \
        #             -snap_wire_center_to_grid grid \
        #             -area $area \
        #             -nets $nets
        #     }
        # }
        # get_db markers -if {.user_type==Endcap*} -foreach {
        #     create_route_blockage -layers M5 -name add_stripe_blockage -rects [get_db $object .bbox]
        # }
        # delete_markers -all

        # # M6 stripes over macros (orthogonal pins)
        # set_db add_stripes_stacked_via_bottom_layer M4
        # set_db add_stripes_stacked_via_top_layer M6
        # set_db add_stripes_skip_via_on_pin {pad cover standardcell}
        # set_db add_stripes_route_over_rows_only false
        # set_db add_stripes_orthogonal_only false
        # set_db generate_special_via_rule_preference {VIA45_* VIA56_*}
        # add_stripes \
        #     -layer M6 \
        #     -direction horizontal \
        #     -width 0.000 \
        #     -spacing [expr 1*0.000*NTRACKS] \
        #     -set_to_set_distance [expr 2*0.000*NTRACKS] \
        #     -start_offset 0.000 \
        #     -snap_wire_center_to_grid grid \
        #     -area [get_db $macros .bbox] \
        #     -nets $nets
        # reset_db add_stripes_orthogonal_only
        # # create_route_blockage -name add_stripe_blockage -layer {M5 M6} -rects [gf_size_bboxes [get_db $macros .bbox] {-0.000 -0.000 0.000 0.000}]
        
        # # M5 stripes
        # set_db add_stripes_stacked_via_bottom_layer M4
        # set_db add_stripes_stacked_via_top_layer M5
        # set_db add_stripes_skip_via_on_pin {pad cover standardcell}
        # set_db generate_special_via_rule_preference {VIA45_*}
        # set_db add_stripes_route_over_rows_only false
        # add_stripes \
        #     -layer M5 \
        #     -direction vertical \
        #     -width 0.000 \
        #     -spacing [expr 1*0.000*NTRACKS] \
        #     -set_to_set_distance [expr 2*0.000*NTRACKS] \
        #     -start_offset 0.000 \
        #     -snap_wire_center_to_grid half_grid \
        #     -nets $nets

        # # M6 stripes
        # set_db add_stripes_stacked_via_bottom_layer M5
        # set_db add_stripes_stacked_via_top_layer M6
        # set_db generate_special_via_rule_preference {VIA56_*}
        # set_db add_stripes_skip_via_on_pin {pad cover standardcell}
        # set_db add_stripes_route_over_rows_only false
        # add_stripes \
        #     -layer M6 \
        #     -direction horizontal \
        #     -width 0.000 \
        #     -spacing [expr 1*0.000*NTRACKS] \
        #     -set_to_set_distance [expr 2*0.000*NTRACKS] \
        #     -start_offset 0.000 \
        #     -snap_wire_center_to_grid grid \
        #     -nets $nets

        # # Delete blockages over macros
        # catch {delete_route_blockage -name add_stripe_blockage}
        
        # # Update PG vias over macros
        # deselect_obj -all; select_obj $macros
        # reset_db generate_special_via_rule_preference
        # update_power_vias -bottom_layer M4 -top_layer M5 -delete_vias 1 -selected_blocks 1
        # update_power_vias -bottom_layer M4 -top_layer M5 -add_vias 1 -selected_blocks 1
        # deselect_obj -all

        # # Remove floating followpins and stripes
        # edit_trim_routes -layers {M0 M1 M2 M3 M4 M5} -nets $nets -type float
        
        # # Trim followpins and stripes
        # edit_trim_routes -layers {M1 M3} -nets $nets

        # # Update ring vias
        # foreach layer {6 7 8} {
        #     deselect_obj -all; select_routes -shape ring -layer M$layer
        #     update_power_vias -nets $nets -top_layer M$layer -bottom_layer M[expr $layer-1] -selected_wires 1 -add_vias 1
        # }
        # deselect_obj -all
        
        # # Update RV
        # foreach bump [get_db bumps] {
        #     create_route_blockage -layers RV -name block_rv_under_bumps -rects [list [list \
        #         [expr [get_db $bump .center.x]-60] [expr [get_db $bump .center.y]-60] \
        #         [expr [get_db $bump .center.x]+60] [expr [get_db $bump .center.y]+60] \
        #     ]]
        # }
        # deselect_obj -all
        # select_routes -layer {AP M11} -shapes stripe -nets $nets
        # update_power_vias -nets $nets -top_layer AP -bottom_layer M11 -between_selected_wires 1 -delete_vias 1
        # update_power_vias -nets $nets -top_layer AP -bottom_layer M11 -between_selected_wires 1 -add_vias 1
        # delete_route_blockages -name block_rv_under_bumps
        # deselect_obj -all

        # # Create PG ports (automatically)
        # <PLACEHOLDER>
        # deselect_obj -all
        # select_routes -layer M9 -nets $nets -shapes stripe
        # create_pg_pin -on_die -selected
        # deselect_obj -all

        # # Create PG ports in top layer
        # <PLACEHOLDER>
        # foreach stripe [get_obj_in_area -areas [get_db current_design .bbox] -layers M9 -obj_type special_wire] {
        #     if {[lsearch -exact $nets [set net_name [get_db $stripe .net.name]]] >= 0} {
        #         create_pg_pin -name $net_name -net $net_name -geometry [get_db $stripe .layer.name] [get_db $stripe .rect.ll.x] [get_db $stripe .rect.ll.y] [get_db $stripe .rect.ur.x] [get_db $stripe .rect.ur.y]
        #     }
        # }

        # # Colorize DPT layers
        # add_power_mesh_colors
    }

    # Initialize IO rows
    proc gf_init_io_rows {} {
        # delete_row -site pad
        # delete_row -site corner
        
        # IO rows
        # <PLACEHOLDER>
        # create_io_row -side N -begin_offset 20 -end_offset 20 -row_margin 20 -site pad
        # create_io_row -side S -begin_offset 20 -end_offset 20 -row_margin 20 -site pad
        # create_io_row -side E -begin_offset 20 -end_offset 20 -row_margin 20 -site pad
        # create_io_row -side W -begin_offset 20 -end_offset 20 -row_margin 20 -site pad
        
        # Corner rows
        # <PLACEHOLDER>
        # create_io_row -corner BL -x_offset 20 -y_offset 20 -site corner
        # create_io_row -corner BR -x_offset 20 -y_offset 20 -site corner
        # create_io_row -corner TL -x_offset 20 -y_offset 20 -site corner
        # create_io_row -corner TR -x_offset 20 -y_offset 20 -site corner
    }

    # Insert IO fillers
    proc gf_init_io_fillers {} {
        catch {delete_io_fillers -cell [get_db [get_db [get_db base_cells -if .site.class==pad *FILL*] -invert {*A *A_G}] .name]}
        add_io_fillers -cells [get_db [get_db [get_db base_cells -if .site.class==pad *FILL*] -invert {*A *A_G}] .name]
    }
    
    # Route top metal
    proc gf_route_flipchip {} {
        
        # # Signal bumps       
        # reset_db flip_chip_*
        # set_db flip_chip_prevent_via_under_bump true
        # route_flip_chip -target connect_bump_to_pad -delete_existing_routes 

        # # Power bumps
        # set_db flip_chip_connect_power_cell_to_bump true
        # set_db flip_chip_multiple_connection default
        # route_flip_chip -nets <PLACEHOLDER> -target connect_bump_to_pad

        # # AP grid
        # set_db add_stripes_stacked_via_top_layer AP
        # set_db add_stripes_stacked_via_bottom_layer M11
        # delete_routes -layer {RV AP} -net $nets -shapes stripe
        # set x_stripe_half_width 30
        # set y_stripe_half_width 30
        # set x_stripe_forbidden_edge 60
        # set y_stripe_forbidden_edge 60
        # foreach bump [get_db bumps] {
        #     if {[lsearch -exact $nets [get_db $bump .net.name]]>=0} {
        # 
        #         # RV blockage around bumps
        #         create_route_blockage -layers RV -name block_rv_under_bumps -rects [list [list \
        #             [expr [get_db $bump .center.x]-$x_stripe_forbidden_edge] [expr [get_db $bump .center.y]-$y_stripe_forbidden_edge] \
        #             [expr [get_db $bump .center.x]+$x_stripe_forbidden_edge] [expr [get_db $bump .center.y]+$y_stripe_forbidden_edge] \
        #         ]]
        # 
        #         # AP blockage at bump corners
        #         create_route_blockage -layers AP -name block_up_under_bumps -rects [list \
        #             [expr [get_db $bump .center.x]-$x_stripe_forbidden_edge] [expr [get_db $bump .center.y]-$y_stripe_forbidden_edge] \
        #             [expr [get_db $bump .center.x]-$x_stripe_half_width] [expr [get_db $bump .center.y]-$y_stripe_half_width] \
        #         ]
        #         create_route_blockage -layers AP -name block_up_under_bumps -rects [list \
        #             [expr [get_db $bump .center.x]-$x_stripe_forbidden_edge] [expr [get_db $bump .center.y]+$y_stripe_forbidden_edge] \
        #             [expr [get_db $bump .center.x]-$x_stripe_half_width] [expr [get_db $bump .center.y]+$y_stripe_half_width] \
        #         ]
        #         create_route_blockage -layers AP -name block_up_under_bumps -rects [list \
        #             [expr [get_db $bump .center.x]+$x_stripe_forbidden_edge] [expr [get_db $bump .center.y]-$y_stripe_forbidden_edge] \
        #             [expr [get_db $bump .center.x]+$x_stripe_half_width] [expr [get_db $bump .center.y]-$y_stripe_half_width] \
        #         ]
        #         create_route_blockage -layers AP -name block_up_under_bumps -rects [list \
        #             [expr [get_db $bump .center.x]+$x_stripe_forbidden_edge] [expr [get_db $bump .center.y]+$y_stripe_forbidden_edge] \
        #             [expr [get_db $bump .center.x]+$x_stripe_half_width] [expr [get_db $bump .center.y]+$y_stripe_half_width] \
        #         ]
        # 
        #         # Horizontal stripes
        #         add_stripes -nets [get_db $bump .net.name] -layer AP -direction horizontal -start_from bottom \
        #             -start_offset 2.7 -width 9.6 -spacing 5.4 -set_to_set_distance 15.0 \
        #             -switch_layer_over_obs false -use_wire_group 0 -snap_wire_center_to_grid none \
        #             -pad_core_ring_top_layer_limit AP -pad_core_ring_bottom_layer_limit AP \
        #             -block_ring_top_layer_limit AP -block_ring_bottom_layer_limit AP \
        #             -area [list \
        #                 [expr [get_db $bump .center.x]-95] [expr [get_db $bump .center.y]-90] \
        #                 [expr [get_db $bump .center.x]+95] [expr [get_db $bump .center.y]+90] \
        #             ]
        # 
        #         # Vertical stripes
        #         add_stripes -nets [get_db $bump .net.name] -layer AP -direction vertical -start_from left \
        #             -start_offset 0.2 -width 9.6 -spacing 15.4 -set_to_set_distance 25.0 \
        #             -switch_layer_over_obs false -use_wire_group 0 -snap_wire_center_to_grid none \
        #             -pad_core_ring_top_layer_limit AP -pad_core_ring_bottom_layer_limit AP \
        #             -block_ring_top_layer_limit AP -block_ring_bottom_layer_limit AP \
        #             -area [list \
        #                 [expr [get_db $bump .center.x]-80] [expr [get_db $bump .center.y]-87.5] \
        #                 [expr [get_db $bump .center.x]+80] [expr [get_db $bump .center.y]+87.5] \
        #             ]
        #     }
        # }
        # delete_route_blockages -name block_rv_under_bumps
        # delete_route_blockages -name block_up_under_bumps
    }
    
    # proc gf_reserve_space_for_tcd {} {
    #     <PLACEHOLDER>
    #     catch {delete_route_blockages -name blockage_for_dtcd}
    #     set xgrid [get_db site:core .size.x]
    #     set ygrid [get_db site:core .size.y]
    #     foreach rect {
    #         {1000 1000 1020 1020}
    #     } {
    #         create_place_blockage -type hard -name blockage_for_dtcd -rects [list \
    #             [expr "round([lindex $rect 0] / $xgrid) * $xgrid"] \
    #             [expr "round([lindex $rect 1] / $ygrid) * $ygrid"] \
    #             [expr "round([lindex $rect 2] / $xgrid) * $xgrid"] \
    #             [expr "round([lindex $rect 3] / $ygrid) * $ygrid"] \
    #         ]
    #         create_route_blockage -layers {M1 M2 M3 M4 M5 M6 M7 M8 M9} -name blockage_for_dtcd -rects [list \
    #             [expr "round([lindex $rect 0] / $xgrid + 6) * $xgrid"] \
    #             [expr "round([lindex $rect 1] / $ygrid + 1) * $ygrid"] \
    #             [expr "round([lindex $rect 2] / $xgrid - 6) * $xgrid"] \
    #             [expr "round([lindex $rect 3] / $ygrid - 1) * $ygrid"] \
    #         ]
    #     }
    # }
    
    # # Insert TCD cells into the design
    # proc gf_insert_tcd_cells {} {
        # set tcd_patterns {*_TCD_* FEOL_* BEOL_* *DTCD_FEOL* *DTCD_BEOL* *_DTCD_*}
        # foreach cell [get_db base_cells $tcd_patterns] {get_db insts -if ".base_cell==$cell" -foreach {delete_inst -inst [get_db $object .name]}}
        # set index 1
        # foreach location {
            # {600 980}
            # {600 1640}
            # {1470 980}
            # {1470 1640}
        # } {
            # incr index
            # set tcd_insts {}
            # foreach cell [get_db [get_db base_cells $tcd_patterns] .name] {
                # create_inst -physical -status fixed -location $location -cell $cell -inst ${cell}_${index}
                # lappend tcd_insts inst:${cell}_${index}
            # }
            
            # gf_align_instances_to_grid 0.048 0.090 $tcd_insts
            
            # catch {delete_route_blockages -name block_under_tcd}
            # foreach rect [get_db $tcd_insts .bbox -u] {
                # create_route_blockage -layers {M1 VIA1 M2 VIA2 M3 VIA3 M4 VIA4 M5 VIA5 M6 VIA6 M7 VIA7 M8 VIA8 M9} -name block_under_tcd -rects [list [list \
                    # [expr [lindex $rect 0]-4.0] [expr [lindex $rect 1]-4.0] \
                    # [expr [lindex $rect 2]+4.0] [expr [lindex $rect 3]+4.0] \
                # ]]
            # }
        # }
    # }
    
    # # Check floorplan
    # proc gf_run_tcic {} {
    #     eval_legacy {
    #         source "*_tCIC_macro_usage_manager.tcl"
    #         source "*_tCIC_set_cip_variables.tcl"
    #     
    #         tCIC_set_design_cell_type <PLACEHOLDER>
    #         tCIC_set_max_DTCD_layer 11
    #         tCIC_reset_macro_usage
    #         tCIC_specify_macro_usage -usage TSMC_SRAM -macro [get_db [get_db insts -if .base_cell.name==*] .name]
    #         
    #         # Report macro usage
    #         tCIC_report_macro_usage
    #         
    #         convert_tCIC_to_ufc \
    #             -input_files "*_tCIC_*.tcl" \
    #             -ufc_file ./out/$TASK_NAME.ufc
    #         redirect { check_ufc ./out/$TASK_NAME.ufc } > "./reports/$TASK_NAME.tcic.log"
    #     }
    # }

    # Finalize and save floorplan
    proc gf_finish_floorplan {} {
        gui_hide
        
        # gf_reserve_space_for_tcd
        
        # gf_init_io_rows
        # gf_init_io_fillers
        
        gf_init_tracks
        
        gf_init_rows
        gf_init_place_blockages
        gf_init_rows
        
        gf_init_physical_cells
        
        # gf_init_boundary_wires
        
        gf_reset_ports
        gf_init_power_grid
        gf_init_ports
        
        gf_write_floorplan_local
        
        redirect ./reports/$::TASK_NAME.rpt {check_floorplan}
        cat ./reports/$::TASK_NAME.rpt
        
        gui_show
    }

'

################################################################################
# Report flow steps
################################################################################

# Pre-clock design stage reports
gf_create_step -name innovus_design_reports_post_place '

    # Set of pre-clock reports in simultaneous setup and hold mode
    gf_report_simultaneous_time_design ./reports/$TASK_NAME

    # Late timing
    gf_report_timing ./reports/$TASK_NAME late 150 1000 10000
    gf_report_timing_worst ./reports/$TASK_NAME late 1000
    gf_report_timing_histograms ./reports/$TASK_NAME late 10000
'

# Pre-route design stage reports
gf_create_step -name innovus_design_reports_post_clock '

    # Set of post-clock reports in simultaneous setup and hold mode
    `@innovus_report_clock_timing`
    gf_report_simultaneous_time_design ./reports/$TASK_NAME

    # Late timing
    gf_report_timing ./reports/$TASK_NAME late 150 1000 10000
    gf_report_timing_worst ./reports/$TASK_NAME late 1000
    gf_report_timing_histograms ./reports/$TASK_NAME late 10000

    # Early timing
    gf_report_timing ./reports/$TASK_NAME early 150 1000 10000
    gf_report_timing_worst ./reports/$TASK_NAME early 1000
    gf_report_timing_histograms ./reports/$TASK_NAME early 10000
'

# Post-route design stage reports
gf_create_step -name innovus_design_reports_post_route '
    set LOGICAL_NETLIST_EXCLUDE_CELLS {`$LOGICAL_NETLIST_EXCLUDE_CELLS -optional`}

    # Enable noise reporting
    set_db si_delay_enable_report true
    set_db si_glitch_enable_report true

    # Set of post-route reports in simultaneous setup and hold mode
    gf_report_simultaneous_time_design ./reports/$TASK_NAME

    # Late timing
    gf_report_timing ./reports/$TASK_NAME late 150 1000 10000
    # gf_report_timing_pba ./reports/$TASK_NAME late 1000
    gf_report_timing_worst ./reports/$TASK_NAME late 1000
    gf_report_timing_histograms ./reports/$TASK_NAME late 10000

    # Early timing
    gf_report_timing ./reports/$TASK_NAME early 150 1000 10000
    # gf_report_timing_pba ./reports/$TASK_NAME early 1000
    gf_report_timing_worst ./reports/$TASK_NAME early 1000
    gf_report_timing_histograms ./reports/$TASK_NAME early 10000

    # Design
    redirect ./reports/$TASK_NAME/design.area.rpt {report_area -min_count 1000}
    redirect ./reports/$TASK_NAME/design.gates.rpt {report_gate_count -level 5}
    
    # Clocks
    redirect ./reports/$TASK_NAME/clocks.list.rpt {report_clocks}
    redirect ./reports/$TASK_NAME/clocks.summary.rpt {report_clock_timing -type summary}
    redirect ./reports/$TASK_NAME/clocks.latency.rpt {report_clock_timing -type latency}
    redirect ./reports/$TASK_NAME/clocks.skew.rpt {report_clock_timing -type skew}
    
    # Timing checks
    redirect ./reports/$TASK_NAME/check.timing.rpt {check_timing -verbose}
    redirect ./reports/$TASK_NAME/check.coverage.rpt {report_analysis_coverage}
    redirect ./reports/$TASK_NAME/check.coverage.violated.rpt {report_analysis_coverage -verbose violated}
    redirect ./reports/$TASK_NAME/check.coverage.untested.rpt {report_analysis_coverage -verbose untested}
    redirect ./reports/$TASK_NAME/constraints.violated.rpt {report_constraint -all_violators}

    # Power, noise
    redirect ./reports/$TASK_NAME/power.rpt {report_power -no_wrap}
    # redirect ./reports/$TASK_NAME/noise.check.rpt {check_noise -all -verbose}
    # catch "redirect ./reports/$TASK_NAME/noise.rpt {report_noise}"

    # Routing
    check_drc -out_file ./reports/$TASK_NAME/route.drc.rpt
    check_connectivity -out_file ./reports/$TASK_NAME/route.open.rpt
    check_process_antenna -out_file ./reports/$TASK_NAME/route.antenna.rpt
    check_filler -out_file ./reports/$TASK_NAME/route.fillers.rpt
    # check_metal_density -report ./reports/$TASK_NAME/route.metal_density.rpt
    # check_cut_density -out_file ./reports/$TASK_NAME/route.cut_density.rpt

    # Write out SDF and netlist for block level simulation
    write_sdf ./out/$TASK_NAME.sdf \
        -min_view [gconfig::get analysis_view_name -view $SDF_MIN_VIEW] \
        -typical_view [gconfig::get analysis_view_name -view $SDF_TYP_VIEW] \
        -max_view [gconfig::get analysis_view_name -view $SDF_MAX_VIEW] \
        -edges noedge -interconnect all -no_derate \
        -version 3.0
    write_netlist -top_module_first -top_module $DESIGN_NAME \
        -exclude_insts_of_cells [get_db [get_db base_cells $LOGICAL_NETLIST_EXCLUDE_CELLS] .name] \
        ./out/$TASK_NAME.v

    # Write out RC factors for pre to post route correlation
    report_rc_factors -blocks_template medium -pre_route true -out_file ./out/$TASK_NAME.rc_factors.tcl

    # SPEF
    foreach rc_corner [get_db rc_corners .name] {
        write_parasitics -spef_file ./out/$TASK_NAME/$DESIGN_NAME.$rc_corner.spef.gz -rc_corner $rc_corner
    }

    # Detect unique views
    set setup_views [get_db [get_db analysis_views -if .is_setup] .name]
    set hold_views [get_db [get_db analysis_views -if .is_hold] .name]
    set merged_views {}
    foreach view [concat $setup_views $hold_views] {
        if {[lsearch -exact $merged_views $view] == -1} {
            lappend merged_views $view
        }
    }
    
    # Activate all views
    set_analysis_view -setup $merged_views -hold $merged_views

    # Write liberty models
    foreach view $merged_views {
        puts "Writing ./out/$TASK_NAME/$DESIGN_NAME.$view.lib ..."
        write_timing_model \
            -include_power_ground \
            -input_transitions {0.002, 0.010, 0.025, 0.050, 0.100, 0.200, 0.500} \
            -output_loads {0.000, 0.010, 0.025, 0.050, 0.100, 0.200, 0.500} \
            -view $view ./out/$TASK_NAME/$DESIGN_NAME.$view.lib
    }
'

################################################################################
# Data creation steps
################################################################################

# Commands to create block-specific data
gf_create_step -name innovus_data_out '
    set PHYSICAL_NETLIST_EXCLUDE_CELLS {`$PHYSICAL_NETLIST_EXCLUDE_CELLS -optional`}
    set LOGICAL_NETLIST_EXCLUDE_CELLS {`$LOGICAL_NETLIST_EXCLUDE_CELLS -optional`}
    set INNOVUS_GDS_UNITS {`$INNOVUS_GDS_UNITS`}
    set INNOVUS_GDS_LAYER_MAP_FILE [join {`$INNOVUS_GDS_LAYER_MAP_FILE`}]
    set GDS_FILES [join {`$GDS_FILES` `$PARTITIONS_GDS_FILES -optional`}]

    ##################################################
    # Netlist manipulations
    ##################################################

    # # Create missing PG ports
    # foreach net [concat [get_db init_power_nets] [get_db init_ground_nets]] {
    #     if {[get_db ports $net] == ""} {
    #         create_pg_pin -name $net -net $net
    #     }
    # }
    
    # Fix empty modules issues
    delete_assigns -ignore_port_constraints
    delete_empty_hinsts

    # # Update global nets connection
    # `@connect_global_nets`

    # # Naming conventions
    # update_names -module -suffix [get_db current_design .name]

    # Write original netlist
    write_netlist ./out/$TASK_NAME/$DESIGN_NAME.v.gz
    
    # Write physical netlist for LVS
    set exclude_cells [get_db [get_db base_cells $PHYSICAL_NETLIST_EXCLUDE_CELLS] .name]
    if {[llength $exclude_cells] > 0} {
        write_netlist -keep_all_backslash -flatten_bus -exclude_leaf_cells \
            -exclude_insts_of_cells $exclude_cells  \
            -phys -include_pg_ports -include_phys_insts \
            -top_module $DESIGN_NAME \
            ./out/$TASK_NAME/$DESIGN_NAME.physical.v.gz
    } else {
        write_netlist -keep_all_backslash -flatten_bus -exclude_leaf_cells \
            -phys -include_pg_ports -include_phys_insts \
            -top_module $DESIGN_NAME \
            ./out/$TASK_NAME/$DESIGN_NAME.physical.v.gz
    }

    # Write logical netlist for STA
    set exclude_cells [get_db [get_db base_cells $LOGICAL_NETLIST_EXCLUDE_CELLS] .name]
    if {[llength $exclude_cells] > 0} {
        write_netlist -keep_all_backslash -flatten_bus -exclude_leaf_cells \
            -exclude_insts_of_cells $exclude_cells \
            -top_module_first -top_module $DESIGN_NAME \
            ./out/$TASK_NAME/$DESIGN_NAME.logical.v.gz
    } else {
        write_netlist -keep_all_backslash -flatten_bus -exclude_leaf_cells \
            -top_module_first -top_module $DESIGN_NAME \
            ./out/$TASK_NAME/$DESIGN_NAME.logical.v.gz
    }

    # Write out LEF for hierarchical design
    if {[catch {set top_layer [get_db design_top_routing_layer]}]} {set top_layer [get_db route_design_top_routing_layer]}
    set top_layer [lindex [lsort -integer -decreasing [concat [get_db [get_db layers $top_layer] .route_index] [get_db [get_db nets [concat [get_db init_power_nets] [get_db init_ground_nets]]] .special_wires.layer.route_index -u]]] 0]
    write_lef_abstract ./out/$TASK_NAME/$DESIGN_NAME.lef -no_cut_obs -extract_block_obs -top_layer $top_layer -stripe_pins -pg_pin_layers $top_layer

    # Write lite DEF for STA/ECO
    write_def -netlist ./out/$TASK_NAME/$DESIGN_NAME.lite.def.gz

    # Write full DEF for parasitics extraction and signal electromigration analysis
    write_def -scan_chain -netlist -floorplan -io_row -routing -routing_to_special_net -with_shield -all_layers ./out/$TASK_NAME/$DESIGN_NAME.full.def.gz

    ##################################################
    # Design manipulations
    ##################################################

    # # Uniquify cell names in GDS
    # set_db write_stream_cell_name_prefix [get_db current_design .name]
    # set_db write_stream_uniquify_cell_names_prefix true
    set_db write_stream_via_names true

    # # Remove DTCD to let them be inserted by fill utility
    # get_db insts .name <PLACEHOLDER>*DTCD_?EOL* -foreach {delete_inst -inst $object}

    # # Add user cells like chip labels
    # create_inst -physical -inst <PLACEHOLDER>label_inst -cell <PLACEHOLDER>label -location {<PLACEHOLDER>0.000 0.000} -orient r0 -status fixed

    # # Add dummy fill cells if Innovus used to merge GDS with metal fill
    # create_inst -physical -inst ${DESIGN_NAME}_dummy_fill_inst -cell ${DESIGN_NAME}_dummy_fill -location {0.000 0.000} -orient r0 -status fixed
    
    # Write out GDS for LVS
    write_stream -mode ALL -output_macros -uniquify_cell_names -die_area_as_boundary \
        -unit $INNOVUS_GDS_UNITS \
        -map_file $INNOVUS_GDS_LAYER_MAP_FILE \
        -merge $GDS_FILES \
        ./out/$TASK_NAME/$DESIGN_NAME.gds.gz
    
    # Write out hcell file and pin locations for LVS
    gf_write_hcell ./out/$TASK_NAME/$DESIGN_NAME.hcell
    gf_write_pin_locations ./out/$TASK_NAME/$DESIGN_NAME.pins
    
    # Write current sources coordinates for power grid analysis
    gf_write_current_sources_locations ./out/$TASK_NAME/$DESIGN_NAME <PLACEHOLDER>200.0
'

# Empty cells LEF for StreamOut
gf_create_step -name innovus_data_out_empty_cells_lef '
    VERSION 5.4 ;
        NAMESCASESENSITIVE ON ;
        BUSBITCHARS "[]" ;
        DIVIDERCHAR "/" ;
        MACRO `$DESIGN_NAME`_dummy_fill
            CLASS COVER ;
            FOREIGN `$DESIGN_NAME`_dummy_fill 0.000 0.000 ;
            ORIGIN 0.000 0.000 ;
            SIZE 10.000 BY 10.00 ;
            SYMMETRY X Y ;
        END `$DESIGN_NAME`_dummy_fill
        MACRO <PLACEHOLDER>label
            CLASS COVER ;
            FOREIGN <PLACEHOLDER>label 0.000 0.000 ;
            ORIGIN 0.000 0.000 ;
            SIZE 10.000 BY 10.00 ;
            SYMMETRY X Y ;
        END <PLACEHOLDER>label
    END LIBRARY
'

################################################################################
# Interactive flow steps
################################################################################

# Commands before interactive floorplanning
gf_create_step -name innovus_pre_floorplan '
    set_db finish_floorplan_active_objs {macro hard_blockage soft_blockage core}
    set_preference InstanceText InstanceMaster
    set_preference ShowNetNameWithLayerColor 1
'

# Commands before open GUI for debug
gf_create_step -name innovus_pre_gui '

    # Dim physical cells
    set_layer_preference phyCell -color #555555

    # # Hide metal layers
    # set_layer_preference node_layer -is_visible 0
    # set_layer_preference pgPower -is_visible 0
    # set_layer_preference pgGround -is_visible 0
    # get_db [get_db layers -if .type==cut] .name -foreach {set_layer_preference $object -is_visible 1}

    # Highlight cells by type
    proc gf_highlight_cells {} {
    
        # Highlight cells modified at different design stages
        gui_highlight -pattern none -color "#30BB30" [get_db insts -if .base_name==Place*]
        gui_highlight -pattern none -color "#60DD60" [get_db insts -if .base_name==Clock*]
        gui_highlight -pattern none -color "#90FF90" [get_db insts -if .base_name==Route*]

        # Highlight optimization cells
        gui_highlight -pattern none -color "#9090FF" [get_db insts *PHC*]
        gui_highlight -pattern none -color "#6060DD" [get_db insts -if .base_name==Clock*PHC*]

        gui_highlight -pattern none -color "#FF3030" [get_db insts -if .base_name==Place*&&.base_cell.dont_use]
        gui_highlight -pattern none -color "#FF6060" [get_db insts -if .base_name==Clock*&&.base_cell.dont_use]
        gui_highlight -pattern none -color "#FF9090" [get_db insts -if .base_name==Route*&&.base_cell.dont_use]

        gui_highlight -pattern none -color "#FF60FF" [get_db insts -if .base_name==Clock*PHC*&&.base_cell.dont_use]
        gui_highlight -pattern none -color "#FF90FF" [get_db insts -if .base_name==Route*PHC*&&.base_cell.dont_use]

        # Highlight clock tree cells
        gui_highlight -pattern none -color "#FFFF90" [get_db insts -if .base_name==CTS_*]
        gui_highlight -pattern none -color "#FFFFFF" [get_db insts -if .base_name==*REGSLICE*]

        # Highlight physical cells
        gui_highlight -pattern none -color "#3070FF" [get_db insts -if .base_name==LTIEL*]
        gui_highlight -pattern none -color "#7030FF" [get_db insts -if .base_name==LTIEH*]
        gui_highlight -pattern none -color "#406080" [get_db insts -if .base_name==WELL*]
        gui_highlight -pattern none -color "#408060" [get_db insts -if .base_name==END*]
    }

'

# Interactive ECO procedures
gf_create_step -name innovus_procs_eco_design '
    
    # Tool-specific procedures
    `@innovus_procs_eco_common`

    # # Fix followpin vias between M1 and M2
    # proc gf_fix_followpin_drc {} {
    #     check_drc -range 1:2 -limit 1000000
    #     route_eco -fix_drc
    # }

    # # Fix poly direction in pads
    # proc gf_fix_io_ring {} {
    #     set_db eco_honor_dont_use false
    #     set_db eco_honor_dont_touch false
    #     set_db eco_honor_fixed_status false
    #     set_db eco_update_timing false
    #     set_db eco_refine_place false
    #     set_db eco_batch_mode true
    #     
    #     foreach pad [get_db insts -if .base_cell.site.class==pad] {
    #         if {[lsearch -exact {r90 r270 mx90 my90} [get_db $pad .orient]] >= 0} {
    #             if {[regexp {_V$} [get_db $pad .base_cell.name]]} {
    #                 puts $pad
    #                 gui_highlight $pad
    #                 eco_update_cell -insts [get_db $pad .name] -cells [regsub {_V$} [get_db $pad .base_cell.name] {_H}]
    #             }
    #         } else {
    #             if {[regexp {_H$} [get_db $pad .base_cell.name]]} {
    #                 puts $pad
    #                 gui_highlight $pad
    #                 eco_update_cell -insts [get_db $pad .name] -cells [regsub {_H$} [get_db $pad .base_cell.name] {_V}]
    #             }
    #         }
    #     }
    #     
    #     set_db eco_batch_mode false
    #     reset_db eco_honor_dont_use
    #     reset_db eco_honor_dont_touch
    #     reset_db eco_honor_fixed_status 
    #     reset_db eco_update_timing 
    #     reset_db eco_refine_place
    # }
'

################################################################################
# Concurrent macro placement flow steps
################################################################################

# Macro placement flow
gf_create_step -name innovus_concurrent_macro_placement '
    
    # Switch floorplan view
    gui_show
    gui_fit
    gui_set_draw_view fplan
    
    # # Clean floorplan
    # gui_hide
    # delete_markers -all 
    # unplace_obj -all
    # deselect_obj -all; select_obj [get_db place_blockages finishfp_place_blkg*]; delete_selected_from_floorplan 
    # deselect_obj -all; select_obj [get_db place_blockages ENDCAP_blk*]; delete_selected_from_floorplan 
    # gf_init_tracks
    # gf_init_rows
    # delete_filler -prefix ENDCAP
    # delete_filler -prefix WELLTAP
    # delete_routes
    # gui_show
    # 
    # # Manual initial floorplan editing
    # set_macro_place_constraint -min_space_to_core <PLACEHOLDER>0.000 -min_space_to_macro <PLACEHOLDER>0.000 -avoid_abut_macro_edge_with_pins true
    # 
    # # Concurrent macro placement
    # gui_hide
    # place_design -concurrent_macros
    # gui_show
    # 
    # # Review and fix automatic macro placement
    # suspend
    # 
    # # Finalize placement
    # unplace_obj -insts
    # place_macro_detail
    # set_db [get_db insts -if .is_black_box] .place_status fixed
    # delete_place_halo -all_macros; finish_floorplan -add_halo <PLACEHOLDER>0.000
    # finish_floorplan -fill_place_blockage hard <PLACEHOLDER>0.000
    # finish_floorplan -fill_place_blockage soft <PLACEHOLDER>0.000
    # gf_write_floorplan_local
    # 
    # # Check the result
    # suspend
    # 
    # # Finalize rows, physical instances, power grid and save floorplan
    # gf_finish_floorplan
'
