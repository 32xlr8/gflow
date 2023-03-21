#!../../gflow/bin/gflow

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
# Filename: templates/project_template.2023/blocks/block_template/voltus.rail.gf
# Purpose:  Batch power and rail analysis flow
################################################################################

########################################
# Main options
########################################

# Project and block initialization scripts
gf_source "../../project.common.gf"
gf_source "../../project.voltus.gf"
gf_source "../../project.quantus.gf"
gf_source "../../project.innovus.gf"
gf_source "./block.common.gf"
gf_source "./block.files.gf"
gf_source "./block.voltus.gf"
gf_source "./block.quantus.gf"
gf_source "./block.innovus.gf"

########################################
# Static power calculation
########################################

gf_create_task -name StaticPower
gf_use_voltus

# Want for extraction to complete
gf_want_tasks Extraction -variable SPEF_TASK

# Select scenario to calculate power
gf_choose -count 25 -keep -variable POWER_SCENARIO \
    -message "Which power scenario to run?" \
    -variants "$(echo "$POWER_SCENARIOS" | sed -e 's|^\s\+||g; s|\s\+$||g;')"

# TCL commands
gf_add_tool_commands '

    # Current design variables
    set LEF_FILES {`$CADENCE_TLEF_FILES` `$LEF_FILES`}

    set SPEF_TASK {`$SPEF_TASK`}
    set SPEF_VIEW [lindex {`$POWER_SPEF_CORNER`} 0]
    
    set ANALYSIS_VIEW [lindex {`$STATIC_POWER_VIEW`} 0]

    set DESIGN_NAME {`$DESIGN_NAME`} 
    set POWER_NETS {`$VOLTUS_POWER_NETS`}
    set GROUND_NETS {`$VOLTUS_GROUND_NETS`}

    set VOLTUS_ICT_EM_RULE {`$VOLTUS_ICT_EM_RULE`}
    
    set POWER_SCENARIO {`$POWER_SCENARIO`}

    # Initialize Generic Config environment
    source ./scripts/$TASK_NAME.gconfig.tcl
    
    # Load MMMC configuration
    read_mmmc ./scripts/$TASK_NAME.mmmc.tcl
    
    # Load design files
    read_physical -lefs [join $LEF_FILES]
    read_netlist ./out/$MOTHER_TASK_NAME.v.gz -top $DESIGN_NAME
    read_def ./out/$MOTHER_TASK_NAME.full.def.gz -skip_signal_nets 

    # Design initialization
    init_design -top $DESIGN_NAME
    `@voltus_post_init_design_technology`

    # Print info
    puts "Extraction view: $SPEF_VIEW"
    puts "Power analysis view: $ANALYSIS_VIEW"
    
    # Switch to propagated mode    
    set_interactive_constraint_mode [get_db [get_db constraint_modes -if {.is_setup||.is_hold}] .name]
    set_propagated_clock [get_clocks *]
    
    # Read parasitics    
    read_spef ./out/$SPEF_TASK.[gconfig::get extract_corner_name -view $SPEF_VIEW].spef.gz
    
    # Run analysis
    `@voltus_run_report_power_static`

    # Close interactive session
    exit
'

# Separate Generic Config initialization script
gf_add_tool_commands -comment '#' -file ./scripts/$TASK_NAME.gconfig.tcl '
    `@init_gconfig`

    `@gconfig_technology_settings`
    `@gconfig_settings_common`

    `@gconfig_cadence_mmmc_files`
    
    # Generate MMMC configuration
    gconfig::get_mmmc_commands -views [list $ANALYSIS_VIEW] -dump_to_file ./scripts/$TASK_NAME.mmmc.tcl
'

# Run task
gf_add_status_marks '\(.*MHz\)'
gf_add_success_marks 'Voltus Power Analysis exited successfully'
gf_submit_task

########################################
# Dynamic power calculation
########################################

gf_create_task -name DynamicPower
gf_use_voltus

# Want for extraction to complete
gf_want_tasks Extraction -variable SPEF_TASK

# Select scenario to calculate power
gf_choose -count 25 -keep -variable POWER_SCENARIO \
    -message "Which power scenario to run?" \
    -variants "$(echo "$POWER_SCENARIOS" | sed -e 's|^\s\+||g; s|\s\+$||g;')"

# TCL commands
gf_add_tool_commands '

    # Current design variables
    set LEF_FILES {`$CADENCE_TLEF_FILES` `$LEF_FILES`}

    set SPEF_TASK {`$SPEF_TASK`}
    set SPEF_VIEW [lindex {`$POWER_SPEF_CORNER`} 0]
    set ANALYSIS_VIEW [lindex {`$DINAMIC_POWER_VIEW`} 0]

    set DESIGN_NAME {`$DESIGN_NAME`} 
    set POWER_NETS {`$VOLTUS_POWER_NETS`}
    set GROUND_NETS {`$VOLTUS_GROUND_NETS`}

    set VOLTUS_ICT_EM_RULE {`$VOLTUS_ICT_EM_RULE`}
    
    set POWER_SCENARIO {`$POWER_SCENARIO`}

    # Initialize Generic Config environment
    source ./scripts/$TASK_NAME.gconfig.tcl
    
    # Print info
    puts "Extraction view: $SPEF_VIEW"
    puts "Power analysis view: $ANALYSIS_VIEW"
    
    # Load MMMC configuration
    read_mmmc ./scripts/$TASK_NAME.mmmc.tcl
    
    # Load design files
    read_physical -lefs [join $LEF_FILES]
    read_netlist ./out/$MOTHER_TASK_NAME.v.gz -top $DESIGN_NAME
    read_def ./out/$MOTHER_TASK_NAME.full.def.gz -skip_signal_nets 

    # Design initialization
    init_design -top $DESIGN_NAME
    `@voltus_post_init_design_technology`
    
    # Switch to propagated mode    
    set_interactive_constraint_mode [get_db [get_db constraint_modes -if {.is_setup||.is_hold}] .name]
    set_propagated_clock [get_clocks *]
    
    # Read parasitics    
    read_spef ./out/$SPEF_TASK.[gconfig::get extract_corner_name -view $SPEF_VIEW].spef.gz
    
    # Run analysis
    `@voltus_run_report_power_dynamic`

    # Close interactive session
    exit
'

# Separate Generic Config initialization script
gf_add_tool_commands -comment '#' -file ./scripts/$TASK_NAME.gconfig.tcl '
    `@init_gconfig`

    `@gconfig_technology_settings`
    `@gconfig_settings_common`

    `@gconfig_cadence_mmmc_files`
    
    # Generate MMMC configuration
    gconfig::get_mmmc_commands -views [list $ANALYSIS_VIEW] -dump_to_file ./scripts/$TASK_NAME.mmmc.tcl
'

# Run task
gf_add_success_marks 'Voltus Power Analysis exited successfully'
gf_submit_task

########################################
# Static IR-drop calculation
########################################

gf_create_task -name StaticIR
gf_use_voltus

# Want for extraction and power analysis to complete
gf_want_tasks StaticPower -variable STATIC_POWER_TASK

# Select PGV to analyze if empty
gf_choose_file_dir_task -variable VOLTUS_PGV_LIBS -keep -prompt "Please select PGV libraries:" -dirs '
    ../work_*/*/out/Tech*.cl
'
gf_info "Selected PGV libraries: \e[32m$VOLTUS_PGV_LIBS\e[0m selected"

# TCL commands
gf_add_tool_commands '

    # Current design variables
    set LEF_FILES {`$CADENCE_TLEF_FILES` `$LEF_FILES`}

    set POWER_TASK {`$STATIC_POWER_TASK`}
    set ANALYSIS_VIEW [lindex {`$STATIC_POWER_VIEW`} 0]

    set SPEF_VIEW [lindex {`$STATIC_RAIL_VIEW`} 0]

    set DESIGN_NAME {`$DESIGN_NAME`} 
    set POWER_NETS {`$VOLTUS_POWER_NETS`}
    set GROUND_NETS {`$VOLTUS_GROUND_NETS`}

    set VOLTUS_PGV_LIBS [eval glob [join {'"$(for dir in $VOLTUS_PGV_LIBS; do echo $dir/*.cl; done)"'}]]
    set VOLTUS_ICT_EM_RULE {`$VOLTUS_ICT_EM_RULE`}

    # Initialize Generic Config environment
    source ./scripts/$TASK_NAME.gconfig.tcl
    
    # Load MMMC configuration
    read_mmmc ./scripts/$TASK_NAME.mmmc.tcl
    
    # Load design files
    read_physical -lefs [join $LEF_FILES]
    read_netlist ./out/$MOTHER_TASK_NAME.v.gz -top $DESIGN_NAME
    read_def ./out/$MOTHER_TASK_NAME.full.def.gz -skip_signal_nets 

    # Design initialization
    init_design -top $DESIGN_NAME
    `@voltus_post_init_design_technology`
    
    # Print info
    puts "Extraction view: $SPEF_VIEW"
    puts "Power analysis view: $ANALYSIS_VIEW"
    
    # Switch to propagated mode    
    set_interactive_constraint_mode [get_db [get_db constraint_modes -if {.is_setup||.is_hold}] .name]
    set_propagated_clock [get_clocks *]
    
    # Internal variables
    set QRC_TECH_FILE [gconfig::get_files qrc -view $SPEF_VIEW]

    # Run analysis
    `@voltus_run_report_rail_static`
   
    # Leave session open for debug
    gui_show
    gui_set_power_rail_display -plot ivdd
'

# Separate Generic Config initialization script
gf_add_tool_commands -comment '#' -file ./scripts/$TASK_NAME.gconfig.tcl '
    `@init_gconfig`

    `@gconfig_technology_settings`
    `@gconfig_settings_common`

    `@gconfig_cadence_mmmc_files`
    
    # Generate MMMC configuration
    gconfig::get_mmmc_commands -views [list $ANALYSIS_VIEW] -dump_to_file ./scripts/$TASK_NAME.mmmc.tcl
'

# Run task
gf_submit_task

########################################
# Dynamic IR-drop calculation
########################################

gf_create_task -name DynamicIR
gf_use_voltus

# Want for extraction and power analysis to complete
gf_want_tasks DynamicPower -variable DYNAMIC_POWER_TASK

# Select PGV to analyze from latest available if empty
gf_choose_file_dir_task -variable VOLTUS_PGV_LIBS -keep -prompt "Please select PGV libraries:" -dirs '
    ../work_*/*/out/Tech*.cl
'
gf_info "PGV libraries \e[32m$VOLTUS_PGV_LIBS\e[0m selected"

# TCL commands
gf_add_tool_commands '

    # Current design variables
    set LEF_FILES {`$CADENCE_TLEF_FILES` `$LEF_FILES`}

    set POWER_TASK {`$DYNAMIC_POWER_TASK`}
    set ANALYSIS_VIEW [lindex {`$DINAMIC_POWER_VIEW`} 0]

    set SPEF_VIEW [lindex {`$DINAMIC_RAIL_VIEW`} 0]

    set DESIGN_NAME {`$DESIGN_NAME`} 
    set POWER_NETS {`$VOLTUS_POWER_NETS`}
    set GROUND_NETS {`$VOLTUS_GROUND_NETS`}

    set VOLTUS_PGV_LIBS [eval glob [join {'"$(for dir in $VOLTUS_PGV_LIBS; do echo $dir/*.cl; done)"'}]]

    # Initialize Generic Config environment
    source ./scripts/$TASK_NAME.gconfig.tcl
    
    # Load MMMC configuration
    read_mmmc ./scripts/$TASK_NAME.mmmc.tcl
    
    # Load design files
    read_physical -lefs [join $LEF_FILES]
    read_netlist ./out/$MOTHER_TASK_NAME.v.gz -top $DESIGN_NAME
    read_def ./out/$MOTHER_TASK_NAME.full.def.gz -skip_signal_nets 

    # Design initialization
    init_design -top $DESIGN_NAME
    `@voltus_post_init_design_technology`
    
    # Print info
    puts "Extraction view: $SPEF_VIEW"
    puts "Power analysis view: $ANALYSIS_VIEW"
    
    # Switch to propagated mode    
    set_interactive_constraint_mode [get_db [get_db constraint_modes -if {.is_setup||.is_hold}] .name]
    set_propagated_clock [get_clocks *]

    # Internal variables
    set QRC_TECH_FILE [gconfig::get_files qrc -view $SPEF_VIEW]

    # Run analysis
    `@voltus_run_report_rail_dynamic`

    # Leave session open for debug
    gui_show
    gui_set_power_rail_display -plot ivdd
'

# Separate Generic Config initialization script
gf_add_tool_commands -comment '#' -file ./scripts/$TASK_NAME.gconfig.tcl '
    `@init_gconfig`

    `@gconfig_technology_settings`
    `@gconfig_settings_common`

    `@gconfig_cadence_mmmc_files`
    
    # Generate MMMC configuration
    gconfig::get_mmmc_commands -views [list $ANALYSIS_VIEW] -dump_to_file ./scripts/$TASK_NAME.mmmc.tcl
'

# Run task
gf_submit_task

########################################
# EM calculation
########################################

gf_create_task -name SignalEM
gf_use_voltus

# Want for extraction and power analysis to complete
gf_want_tasks Extraction -variable SPEF_TASK

# TCL commands
gf_add_tool_commands '

    # Current design variables
    set LEF_FILES {`$CADENCE_TLEF_FILES` `$LEF_FILES`}

    set SPEF_TASK {`$SPEF_TASK`}
    set SPEF_VIEW [lindex {`$SIGNAL_SPEF_CORNER`} 0]

    set ANALYSIS_VIEW [lindex {`$SIGNAL_EM_VIEW`} 0]
    
    set QRC_TECH_EM {`$QRC_TECH_EM`}
    set VOLTUS_ICT_EM_RULE {`$VOLTUS_ICT_EM_RULE`}

    set DESIGN_NAME {`$DESIGN_NAME`} 

    # Initialize Generic Config environment
    source ./scripts/$TASK_NAME.gconfig.tcl
    
    # Load MMMC configuration
    read_mmmc ./scripts/$TASK_NAME.mmmc.tcl
    
    # Load design files
    read_physical -lefs [join $LEF_FILES]
    read_netlist ./out/$MOTHER_TASK_NAME.v.gz -top $DESIGN_NAME
    read_def ./out/$MOTHER_TASK_NAME.full.def.gz -skip_signal_nets 

    # Design initialization
    init_design -top $DESIGN_NAME
    `@voltus_post_init_design_technology`
    
    # Print info
    puts "Extraction view: $SPEF_VIEW"
    puts "Power analysis view: $ANALYSIS_VIEW"
    
    # Switch to propagated mode    
    set_interactive_constraint_mode [get_db [get_db constraint_modes -if {.is_setup||.is_hold}] .name]
    set_propagated_clock [get_clocks *]

    # Read parasitics    
    read_spef ./out/$SPEF_TASK.[gconfig::get extract_corner_name -view $SPEF_VIEW].spef.gz
    
    # Check EM violations
    `@voltus_run_signal_em`

    # Leave session open for debug
    gui_show
'

# Separate Generic Config initialization script
gf_add_tool_commands -comment '#' -file ./scripts/$TASK_NAME.gconfig.tcl '
    `@init_gconfig`

    `@gconfig_technology_settings`
    `@gconfig_settings_common`

    `@gconfig_cadence_mmmc_files`
    
    # Generate MMMC configuration
    gconfig::get_mmmc_commands -views [list $ANALYSIS_VIEW] -dump_to_file ./scripts/$TASK_NAME.mmmc.tcl
'

# Run task
gf_submit_task
