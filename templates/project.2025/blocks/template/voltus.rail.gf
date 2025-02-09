#!../../gflow/bin/gflow

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
# Filename: templates/project_template.2023/blocks/block_template/voltus.rail.gf
# Purpose:  Batch power and rail analysis flow
################################################################################

########################################
# Main options
########################################

# Project and block initialization scripts
gf_source -once "../../project.common.gf"
gf_source -once "../../project.voltus.gf"
gf_source -once "./block.common.gf"
gf_source -once "./block.voltus.gf"

########################################
# Static power calculation
########################################

gf_create_task -name StaticPower
gf_use_voltus

# Design data directory
gf_choose_file_dir_task -variable DATA_OUT_DIR -keep -prompt "Choose design data directory:" -dirs '
    ../work_*/*/out/DataOutPhysical*
' -want -active -task_to_file '$RUN/out/$TASK' -tasks '
    ../work_*/*/tasks/DataOutPhysical*
'

# SPEF directory
gf_choose_file_dir_task -variable SPEF_OUT_DIR -keep -prompt "Choose SPEF directory:" -dirs '
    ../work_*/*/out/Extraction*
' -want -active -task_to_file '$RUN/out/$TASK' -tasks '
    ../work_*/*/tasks/Extraction*
'

# Select scenario to calculate power
gf_choose -count 25 -keep -variable POWER_SCENARIO \
    -message "Which power scenario to run?" \
    -variants "$(echo "$POWER_SCENARIOS" | sed -e 's|^\s\+||g; s|\s\+$||g;')"

# TCL commands
gf_add_tool_commands '

    # Current design variables
    set LEF_FILES {`$CADENCE_TLEF_FILES` `$LEF_FILES`}

    set DESIGN_NAME {`$DESIGN_NAME`} 
    set POWER_SCENARIO {`$POWER_SCENARIO`}
    
    set DATA_OUT_DIR {`$DATA_OUT_DIR`}
    set SPEF_OUT_DIR {`$SPEF_OUT_DIR`}

    # Start metric collection
    `@collect_metrics`

    # Use separate Generic Config script
    source ./scripts/$TASK_NAME.gconfig.tcl

    # Design variables
    `@voltus_pre_init_variables`

    # Load MMMC configuration
    puts "Analysis view: {$STATIC_POWER_VIEW}"
    read_mmmc ./in/$TASK_NAME.mmmc.tcl
    
    # Load design files
    read_physical -lefs [join $LEF_FILES]
    read_netlist $DATA_OUT_DIR/$DESIGN_NAME.v.gz -top $DESIGN_NAME

    # Design initialization
    init_design

    # Load physical data
    read_def $DATA_OUT_DIR/$DESIGN_NAME.full.def.gz -skip_signal_nets 
    
    # Read parasitics
    set rc_corner [gconfig::get extract_corner_name -view $STATIC_POWER_VIEW]
    if {[file exists [set SPEF_FILE $SPEF_OUT_DIR/$DESIGN_NAME.$rc_corner.spef.gz]]} {
        puts "SPEF file: $SPEF_FILE"
        read_spef -extended -keep_star_node_location $SPEF_FILE
    } else {
        puts "\033\[41m \033\[0m SPEF file $SPEF_FILE not found"
        suspend
    }
    
    # Initialize tool environment
    `@voltus_post_init_design_project`
    `@voltus_post_init_variables`

    # Switch to propagated mode    
    set_interactive_constraint_mode [get_db [get_db constraint_modes -if {.is_setup||.is_hold}] .name]
    set_propagated_clock [get_clocks *]
    
    # Run analysis
    `@voltus_run_report_power_static`

    # Report collected metrics
    `@report_metrics`
        
    # Close interactive session
    exit
'

# Generic Config MMMC generation
gf_use_gconfig
gf_add_tool_commands '
    `@gconfig_project_settings`
    `@gconfig_settings_common`
    `@gconfig_cadence_mmmc_files`
    `@voltus_gconfig_design_settings`
    
    # Print out summary
    gconfig::show_variables
    gconfig::show_switches

    # Generate timing configuration
    try {
        gconfig::get_mmmc_commands -views [list $STATIC_POWER_VIEW] -dump_to_file ./in/$TASK_NAME.mmmc.tcl

    # Suspend on error
    } on error {result options} {
        exec rm -f ./in/$TASK_NAME.mmmc.tcl
        puts "\033\[41;31m \033\[0m $result"
        suspend
    }
'

# Run task
gf_add_status_marks '\(.*MHz\)'
gf_add_success_marks 'Voltus Power Analysis exited successfully'
gf_submit_task

########################################
# Static rail analysis
########################################

gf_create_task -name StaticRail
gf_use_voltus

# Want for extraction and power analysis to complete
gf_want_tasks StaticPower -variable STATIC_POWER_TASK

# Design data directory
gf_choose_file_dir_task -variable DATA_OUT_DIR -keep -prompt "Choose design data directory:" -dirs '
    ../work_*/*/out/DataOutPhysical*
' -want -active -task_to_file '$RUN/out/$TASK' -tasks '
    ../work_*/*/tasks/DataOutPhysical*
'

# Select PGV to analyze if empty
gf_choose_file_dir_task -variable VOLTUS_PGV_LIBS -keep -prompt "Choose PGV libraries:" -dirs '
    ../work_*/*/out/TechPGV*/*.cl
'

# TCL commands
gf_add_tool_commands '

    # Current design variables
    set LEF_FILES {`$CADENCE_TLEF_FILES` `$LEF_FILES`}
    set DATA_OUT_DIR {`$DATA_OUT_DIR`}
    set VOLTUS_PGV_LIBS [join {`$VOLTUS_PGV_LIBS`}]

    set DESIGN_NAME {`$DESIGN_NAME`} 
    set STATIC_POWER_TASK {`$STATIC_POWER_TASK`}

    # Start metric collection
    `@collect_metrics`

    # Use separate Generic Config script
    source ./scripts/$TASK_NAME.gconfig.tcl

    # Design variables
    `@voltus_pre_init_variables`

    # Link design files
    exec ln -nsf $DATA_OUT_DIR/$DESIGN_NAME.v.gz ./in/$TASK_NAME.v.gz
    exec ln -nsf $DATA_OUT_DIR/$DESIGN_NAME.full.def.gz ./in/$TASK_NAME.def.gz

    # Load MMMC configuration
    puts "Analysis view: {$STATIC_RAIL_VIEW}"
    read_mmmc ./in/$TASK_NAME.mmmc.tcl

    # Load design files
    read_physical -lefs [join $LEF_FILES]
    read_netlist $DATA_OUT_DIR/$DESIGN_NAME.v.gz -top $DESIGN_NAME

    # Design initialization
    init_design
    
    # Load physical data
    read_def $DATA_OUT_DIR/$DESIGN_NAME.full.def.gz -skip_signal_nets 

    # Initialize tool environment
    `@voltus_post_init_design_project`
    `@voltus_post_init_variables`

    # Switch to propagated mode    
    set_interactive_constraint_mode [get_db [get_db constraint_modes -if {.is_setup||.is_hold}] .name]
    set_propagated_clock [get_clocks *]
    
    # Run analysis
    `@voltus_run_report_rail_static`
   
    # Report collected metrics
    `@report_metrics`
    
    # Show GUI
    gui_show
    
    # Generate reports
    mkdir -p ./reports/$TASK_NAME
    
    # Unconnected
    gui_set_power_rail_display -plot unc -enable_voltage_sources true -legend nw
    gui_fit; write_to_gif ./reports/$TASK_NAME/unconnected.gif

    # Instance VDD - no limit
    gui_set_power_rail_display -plot ir -enable_voltage_sources true -legend nw
    gui_fit; write_to_gif ./reports/$TASK_NAME/ir.auto.gif
    
    # Instance VDD - no limit
    gui_set_power_rail_display -plot ivdd -enable_voltage_sources true -legend nw
    gui_fit; write_to_gif ./reports/$TASK_NAME/ivdd.auto.gif
    
    # Instance VDD  - auto range
    gui_set_power_rail_display -plot ivdd -enable_voltage_sources true -legend nw -range_min 0.0 -range_max [expr 1000.0*$IR_THRESHOLD_STATIC]
    gui_fit; write_to_gif ./reports/$TASK_NAME/ivdd.range.gif
    
    # Close interactive session
    exit
'

# Generic Config MMMC generation
gf_use_gconfig
gf_add_tool_commands '
    `@gconfig_project_settings`
    `@gconfig_settings_common`
    `@gconfig_cadence_mmmc_files`
    `@voltus_gconfig_design_settings`
    
    # Print out summary
    gconfig::show_variables
    gconfig::show_switches

    # Generate timing configuration
    try {
        gconfig::get_mmmc_commands -views [list $STATIC_RAIL_VIEW] -dump_to_file ./in/$TASK_NAME.mmmc.tcl

    # Suspend on error
    } on error {result options} {
        exec rm -f ./in/$TASK_NAME.mmmc.tcl
        puts "\033\[41;31m \033\[0m $result"
        suspend
    }
'

# Run task
gf_submit_task

########################################
# Dynamic power calculation
########################################

gf_create_task -name DynamicPower
gf_use_voltus

# Design data directory
gf_choose_file_dir_task -variable DATA_OUT_DIR -keep -prompt "Choose design data directory:" -dirs '
    ../work_*/*/out/DataOutPhysical*
' -want -active -task_to_file '$RUN/out/$TASK' -tasks '
    ../work_*/*/tasks/DataOutPhysical*
'

# SPEF directory
gf_choose_file_dir_task -variable SPEF_OUT_DIR -keep -prompt "Choose SPEF directory:" -dirs '
    ../work_*/*/out/Extraction*
' -want -active -task_to_file '$RUN/out/$TASK' -tasks '
    ../work_*/*/tasks/Extraction*
'

# Select scenario to calculate power
gf_choose -count 25 -keep -variable POWER_SCENARIO \
    -message "Which power scenario to run?" \
    -variants "$(echo "$POWER_SCENARIOS" | sed -e 's|^\s\+||g; s|\s\+$||g;')"

# TCL commands
gf_add_tool_commands '

    # Current design variables
    set LEF_FILES {`$CADENCE_TLEF_FILES` `$LEF_FILES`}

    set DESIGN_NAME {`$DESIGN_NAME`} 
    set POWER_SCENARIO {`$POWER_SCENARIO`}
    
    set DATA_OUT_DIR {`$DATA_OUT_DIR`}
    set SPEF_OUT_DIR {`$SPEF_OUT_DIR`}

    # Start metric collection
    `@collect_metrics`

    # Use separate Generic Config script
    source ./scripts/$TASK_NAME.gconfig.tcl

    # Design variables
    `@voltus_pre_init_variables`

    # Load MMMC configuration
    puts "Analysis view: {$DYNAMIC_POWER_VIEW}"
    read_mmmc ./in/$TASK_NAME.mmmc.tcl
    
    # Load design files
    read_physical -lefs [join $LEF_FILES]
    read_netlist $DATA_OUT_DIR/$DESIGN_NAME.v.gz -top $DESIGN_NAME
    
    # Design initialization
    init_design
    
    # Load physical data
    read_def $DATA_OUT_DIR/$DESIGN_NAME.full.def.gz -skip_signal_nets 

    # Read parasitics
    set rc_corner [gconfig::get extract_corner_name -view $DYNAMIC_POWER_VIEW]
    if {[file exists [set SPEF_FILE $SPEF_OUT_DIR/$DESIGN_NAME.$rc_corner.spef.gz]]} {
        puts "SPEF file: $SPEF_FILE"
        read_spef -extended -keep_star_node_location $SPEF_FILE
    } else {
        puts "\033\[41m \033\[0m SPEF file $SPEF_FILE not found"
        suspend
    }
    
    # Initialize tool environment
    `@voltus_post_init_design_project`
    `@voltus_post_init_variables`

    # Switch to propagated mode    
    set_interactive_constraint_mode [get_db [get_db constraint_modes -if {.is_setup||.is_hold}] .name]
    set_propagated_clock [get_clocks *]
    
    # Run analysis
    `@voltus_run_report_power_dynamic`

    # Report collected metrics
    `@report_metrics`
        
    # Close interactive session
    exit
'

# Generic Config MMMC generation
gf_use_gconfig
gf_add_tool_commands '
    `@gconfig_project_settings`
    `@gconfig_settings_common`
    `@gconfig_cadence_mmmc_files`
    `@voltus_gconfig_design_settings`
    
    # Print out summary
    gconfig::show_variables
    gconfig::show_switches

    # Generate timing configuration
    try {
        gconfig::get_mmmc_commands -views [list $DYNAMIC_POWER_VIEW] -dump_to_file ./in/$TASK_NAME.mmmc.tcl

    # Suspend on error
    } on error {result options} {
        exec rm -f ./in/$TASK_NAME.mmmc.tcl
        puts "\033\[41;31m \033\[0m $result"
        suspend
    }
'

# Run task
gf_add_status_marks '\(.*MHz\)'
gf_add_success_marks 'Voltus Power Analysis exited successfully'
gf_submit_task

########################################
# Dynamic rail analysis
########################################

gf_create_task -name DynamicRail
gf_use_voltus

# Want for extraction and power analysis to complete
gf_want_tasks DynamicPower -variable DYNAMIC_POWER_TASK

# Design data directory
gf_choose_file_dir_task -variable DATA_OUT_DIR -keep -prompt "Choose design data directory:" -dirs '
    ../work_*/*/out/DataOutPhysical*
' -want -active -task_to_file '$RUN/out/$TASK' -tasks '
    ../work_*/*/tasks/DataOutPhysical*
'

# Select PGV to analyze if empty
gf_choose_file_dir_task -variable VOLTUS_PGV_LIBS -keep -prompt "Choose PGV libraries:" -dirs '
    ../work_*/*/out/TechPGV*/*.cl
'

# TCL commands
gf_add_tool_commands '

    # Current design variables
    set LEF_FILES {`$CADENCE_TLEF_FILES` `$LEF_FILES`}
    set DATA_OUT_DIR {`$DATA_OUT_DIR`}
    set VOLTUS_PGV_LIBS [join {`$VOLTUS_PGV_LIBS`}]

    set DESIGN_NAME {`$DESIGN_NAME`} 
    set DYNAMIC_POWER_TASK {`$DYNAMIC_POWER_TASK`}

    # Start metric collection
    `@collect_metrics`

    # Use separate Generic Config script
    source ./scripts/$TASK_NAME.gconfig.tcl

    # Design variables
    `@voltus_pre_init_variables`

    # Link design files
    exec ln -nsf $DATA_OUT_DIR/$DESIGN_NAME.v.gz ./in/$TASK_NAME.v.gz
    exec ln -nsf $DATA_OUT_DIR/$DESIGN_NAME.full.def.gz ./in/$TASK_NAME.def.gz

    # Load MMMC configuration
    puts "Analysis view: {$DYNAMIC_RAIL_VIEW}"
    read_mmmc ./in/$TASK_NAME.mmmc.tcl

    # Load design files
    read_physical -lefs [join $LEF_FILES]
    read_netlist $DATA_OUT_DIR/$DESIGN_NAME.v.gz -top $DESIGN_NAME

    # Design initialization
    init_design
    
    # Load physical data
    read_def $DATA_OUT_DIR/$DESIGN_NAME.full.def.gz -skip_signal_nets 

    # Initialize tool environment
    `@voltus_post_init_design_project`
    `@voltus_post_init_variables`

    # Switch to propagated mode    
    set_interactive_constraint_mode [get_db [get_db constraint_modes -if {.is_setup||.is_hold}] .name]
    set_propagated_clock [get_clocks *]
    
    # Run analysis
    `@voltus_run_report_rail_dynamic`

    # Report collected metrics
    `@report_metrics`
        
    # Show GUI
    gui_show
    
    # Generate reports
    mkdir -p ./reports/$TASK_NAME
    
    # Unconnected
    gui_set_power_rail_display -plot unc -enable_voltage_sources true -legend nw
    gui_fit; write_to_gif ./reports/$TASK_NAME/unconnected.gif

    # Instance VDD - no limit
    gui_set_power_rail_display -plot ir -enable_voltage_sources true -legend nw
    gui_fit; write_to_gif ./reports/$TASK_NAME/ir.auto.gif
    
    # Instance VDD - no limit
    gui_set_power_rail_display -plot ivdd -enable_voltage_sources true -legend nw
    gui_fit; write_to_gif ./reports/$TASK_NAME/ivdd.auto.gif
    
    # Instance VDD  - auto range
    gui_set_power_rail_display -plot ivdd -enable_voltage_sources true -legend nw -range_min 0.0 -range_max [expr 1000.0*$IR_THRESHOLD_DYNAMIC]
    gui_fit; write_to_gif ./reports/$TASK_NAME/ivdd.range.gif

    # Close interactive session
    exit
'

# Generic Config MMMC generation
gf_use_gconfig
gf_add_tool_commands '
    `@gconfig_project_settings`
    `@gconfig_settings_common`
    `@gconfig_cadence_mmmc_files`
    `@voltus_gconfig_design_settings`
    
    # Print out summary
    gconfig::show_variables
    gconfig::show_switches

    # Generate timing configuration
    try {
        gconfig::get_mmmc_commands -views [list $DYNAMIC_RAIL_VIEW] -dump_to_file ./in/$TASK_NAME.mmmc.tcl

    # Suspend on error
    } on error {result options} {
        exec rm -f ./in/$TASK_NAME.mmmc.tcl
        puts "\033\[41;31m \033\[0m $result"
        suspend
    }
'

# Run task
gf_submit_task

########################################
# EM calculation
########################################

gf_create_task -name SignalEM
gf_use_voltus

# Design data directory
gf_choose_file_dir_task -variable DATA_OUT_DIR -keep -prompt "Choose design data directory:" -dirs '
    ../work_*/*/out/DataOutPhysical*
' -want -active -task_to_file '$RUN/out/$TASK' -tasks '
    ../work_*/*/tasks/DataOutPhysical*
'

# SPEF directory
gf_choose_file_dir_task -variable SPEF_OUT_DIR -keep -prompt "Choose SPEF directory:" -dirs '
    ../work_*/*/out/Extraction*
' -want -active -task_to_file '$RUN/out/$TASK' -tasks '
    ../work_*/*/tasks/Extraction*
'

# Select PGV to analyze if empty
gf_choose_file_dir_task -variable VOLTUS_PGV_LIBS -keep -prompt "Choose PGV libraries:" -dirs '
    ../work_*/*/out/TechPGV*/*.cl
'

# TCL commands
gf_add_tool_commands '

    # Current design variables
    set LEF_FILES {`$CADENCE_TLEF_FILES` `$LEF_FILES`}
    set DATA_OUT_DIR {`$DATA_OUT_DIR`}
    set SPEF_OUT_DIR {`$SPEF_OUT_DIR`}
    set VOLTUS_PGV_LIBS [join {`$VOLTUS_PGV_LIBS`}]

    set DESIGN_NAME {`$DESIGN_NAME`} 

    # Start metric collection
    `@collect_metrics`

    # Use separate Generic Config script
    source ./scripts/$TASK_NAME.gconfig.tcl

    # Design variables
    `@voltus_pre_init_variables`

    # Load MMMC configuration
    puts "Analysis view: {$SIGNAL_EM_VIEW}"
    read_mmmc ./in/$TASK_NAME.mmmc.tcl

    # Load design files
    read_physical -lefs [join $LEF_FILES]
    read_netlist $DATA_OUT_DIR/$DESIGN_NAME.v.gz -top $DESIGN_NAME

    # Design initialization
    init_design
    
    # Load physical data
    read_def $DATA_OUT_DIR/$DESIGN_NAME.full.def.gz -skip_signal_nets 

    # Switch to propagated mode    
    set_interactive_constraint_mode [get_db [get_db constraint_modes -if {.is_setup||.is_hold}] .name]
    set_propagated_clock [get_clocks *]
    
    # Read parasitics
    set rc_corner [gconfig::get extract_corner_name -view $SIGNAL_EM_VIEW]
    if {[file exists [set SPEF_FILE $SPEF_OUT_DIR/$DESIGN_NAME.$rc_corner.spef.gz]]} {
        puts "SPEF file: $SPEF_FILE"
        read_spef -extended -keep_star_node_location $SPEF_FILE
    } else {
        puts "\033\[41m \033\[0m SPEF file $SPEF_FILE not found"
        suspend
    }
    
    # Initialize tool environment
    `@voltus_post_init_design_project`
    `@voltus_post_init_variables`

    # Check EM violations
    `@voltus_run_signal_em`

    # Report collected metrics
    `@report_metrics`

    # Close interactive session
    exit
'

# Generic Config MMMC generation
gf_use_gconfig
gf_add_tool_commands '
    `@gconfig_project_settings`
    `@gconfig_settings_common`
    `@gconfig_cadence_mmmc_files`
    `@voltus_gconfig_design_settings`
    
    # Print out summary
    gconfig::show_variables
    gconfig::show_switches

    # Generate timing configuration
    try {
        gconfig::get_mmmc_commands -views [list $SIGNAL_EM_VIEW] -dump_to_file ./in/$TASK_NAME.mmmc.tcl

    # Suspend on error
    } on error {result options} {
        exec rm -f ./in/$TASK_NAME.mmmc.tcl
        puts "\033\[41;31m \033\[0m $result"
        suspend
    }
'
# Run task
gf_add_status_marks 'No such file'
gf_add_failed_marks 'No such file'
gf_submit_task
