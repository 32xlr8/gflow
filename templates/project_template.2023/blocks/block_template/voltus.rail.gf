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
gf_source "./block.common.gf"
gf_source "./block.files.gf"
gf_source "./block.voltus.gf"

########################################
# Static power calculation
########################################

gf_create_task -name StaticPower
gf_use_voltus

# Choose configuration file
gf_choose_file_dir_task -variable VOLTUS_POWER_CONFIG_FILE -keep -prompt "Please select timing configuration file:" -files '
    ../data/*.timing.tcl
    ../data/*/*.timing.tcl
    ../work_*/*/out/ConfigSignoff*.power.tcl
'

# Choose configuration file
gf_choose_file_dir_task -variable VOLTUS_DATA_OUT_CONFIG_FILE -keep -prompt "Please select design configuration file:" -files '
    ../data/*.design.tcl
    ../data/*/*.design.tcl
    ../work_*/*/out/DataOutPhysical*.design.tcl
' -want -active -task_to_file '$RUN/out/$TASK.design.tcl' -tasks '
    ../work_*/*/tasks/DataOutPhysical*
'

# Choose configuration file
gf_choose_file_dir_task -variable VOLTUS_SPEF_CONFIG_FILE -keep -prompt "Please select design configuration file:" -files '
    ../data/*.design.tcl
    ../data/*/*.design.tcl
    ../work_*/*/out/Extraction*.design.tcl
' -want -active -task_to_file '$RUN/out/$TASK.design.tcl' -tasks '
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
    
    set POWER_CONFIG_FILE {`$VOLTUS_POWER_CONFIG_FILE`}
    set DATA_OUT_CONFIG_FILE {`$VOLTUS_DATA_OUT_CONFIG_FILE`}
    set SPEF_CONFIG_FILE {`$VOLTUS_SPEF_CONFIG_FILE`}

    # Load configuration variables
    source $POWER_CONFIG_FILE
    source $DATA_OUT_CONFIG_FILE
    source $SPEF_CONFIG_FILE

    # Design variables
    `@voltus_pre_init_variables`

    # Load MMMC configuration
    puts "MMMC file: $STATIC_POWER_VIEW_MMMC_FILE"
    read_mmmc $STATIC_POWER_VIEW_MMMC_FILE
    
    # Load design files
    read_physical -lefs [join $LEF_FILES]
    read_netlist $NETLIST_FILE -top $DESIGN_NAME
    read_def $DEF_FILE -skip_signal_nets 

    # Design initialization
    init_design
    `@voltus_post_init_design_technology`
    `@voltus_post_init_variables`
    
    # Switch to propagated mode    
    set_interactive_constraint_mode [get_db [get_db constraint_modes -if {.is_setup||.is_hold}] .name]
    set_propagated_clock [get_clocks *]
    
    # Read parasitics
    if {[file exists [set SPEF_FILE $SPEF_DIR/$SPEF_TASK_NAME.$POWER_SPEF_CORNER.spef.gz]]} {
        puts "SPEF file: $SPEF_FILE"
        read_spef $SPEF_FILE
    } else {
        puts "\033\[41m \033\[0m SPEF file $SPEF_FILE not found"
        suspend
    }
    
    # Run analysis
    `@voltus_run_report_power_static`

    # Close interactive session
    exit
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

# Choose configuration file
gf_choose_file_dir_task -variable VOLTUS_POWER_CONFIG_FILE -keep -prompt "Please select timing configuration file:" -files '
    ../data/*.timing.tcl
    ../data/*/*.timing.tcl
    ../work_*/*/out/ConfigSignoff*.power.tcl
'

# Choose configuration file
gf_choose_file_dir_task -variable VOLTUS_DATA_OUT_CONFIG_FILE -keep -prompt "Please select design configuration file:" -files '
    ../data/*.design.tcl
    ../data/*/*.design.tcl
    ../work_*/*/out/DataOutPhysical*.design.tcl
' -want -active -task_to_file '$RUN/out/$TASK.design.tcl' -tasks '
    ../work_*/*/tasks/DataOutPhysical*
'

# Choose configuration file
gf_choose_file_dir_task -variable VOLTUS_SPEF_CONFIG_FILE -keep -prompt "Please select design configuration file:" -files '
    ../data/*.design.tcl
    ../data/*/*.design.tcl
    ../work_*/*/out/Extraction*.design.tcl
' -want -active -task_to_file '$RUN/out/$TASK.design.tcl' -tasks '
    ../work_*/*/tasks/Extraction*
'

# Select PGV to analyze if empty
gf_choose_file_dir_task -variable VOLTUS_PGV_LIBS -keep -prompt "Please select PGV libraries:" -dirs '
    ../work_*/*/out/TechPGV*/*.cl
'
gf_info "PGV libraries: \e[32m$VOLTUS_PGV_LIBS\e[0m selected"

# TCL commands
gf_add_tool_commands '

    # Current design variables
    set LEF_FILES {`$CADENCE_TLEF_FILES` `$LEF_FILES`}
    set VOLTUS_PGV_LIBS [join {`$VOLTUS_PGV_LIBS`}]

    set DESIGN_NAME {`$DESIGN_NAME`} 
    set POWER_TASK {`$STATIC_POWER_TASK`}
    
    set POWER_CONFIG_FILE {`$VOLTUS_POWER_CONFIG_FILE`}
    set DATA_OUT_CONFIG_FILE {`$VOLTUS_DATA_OUT_CONFIG_FILE`}
    set SPEF_CONFIG_FILE {`$VOLTUS_SPEF_CONFIG_FILE`}

    # Load configuration variables
    source $POWER_CONFIG_FILE
    source $DATA_OUT_CONFIG_FILE
    source $SPEF_CONFIG_FILE

    # Design variables
    `@voltus_pre_init_variables`

    # Load MMMC configuration
    puts "QRC file: {$STATIC_RAIL_VIEW_TEMPERATURE $STATIC_RAIL_VIEW_QRC_FILE}"
    puts "MMMC file: $STATIC_RAIL_VIEW_MMMC_FILE"
    read_mmmc $STATIC_RAIL_VIEW_MMMC_FILE
    
    # Load design files
    read_physical -lefs [join $LEF_FILES]
    read_netlist $NETLIST_FILE -top $DESIGN_NAME
    read_def $DEF_FILE -skip_signal_nets 

    # Design initialization
    init_design
    `@voltus_post_init_design_technology`
    `@voltus_post_init_variables`

    # Switch to propagated mode    
    set_interactive_constraint_mode [get_db [get_db constraint_modes -if {.is_setup||.is_hold}] .name]
    set_propagated_clock [get_clocks *]
    
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
# Dynamic power calculation
########################################

gf_create_task -name DynamicPower
gf_use_voltus

# Choose configuration file
gf_choose_file_dir_task -variable VOLTUS_POWER_CONFIG_FILE -keep -prompt "Please select timing configuration file:" -files '
    ../data/*.timing.tcl
    ../data/*/*.timing.tcl
    ../work_*/*/out/ConfigSignoff*.power.tcl
'

# Choose configuration file
gf_choose_file_dir_task -variable VOLTUS_DATA_OUT_CONFIG_FILE -keep -prompt "Please select design configuration file:" -files '
    ../data/*.design.tcl
    ../data/*/*.design.tcl
    ../work_*/*/out/DataOutPhysical*.design.tcl
' -want -active -task_to_file '$RUN/out/$TASK.design.tcl' -tasks '
    ../work_*/*/tasks/DataOutPhysical*
'

# Choose configuration file
gf_choose_file_dir_task -variable VOLTUS_SPEF_CONFIG_FILE -keep -prompt "Please select design configuration file:" -files '
    ../data/*.design.tcl
    ../data/*/*.design.tcl
    ../work_*/*/out/Extraction*.design.tcl
' -want -active -task_to_file '$RUN/out/$TASK.design.tcl' -tasks '
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
    
    set POWER_CONFIG_FILE {`$VOLTUS_POWER_CONFIG_FILE`}
    set DATA_OUT_CONFIG_FILE {`$VOLTUS_DATA_OUT_CONFIG_FILE`}
    set SPEF_CONFIG_FILE {`$VOLTUS_SPEF_CONFIG_FILE`}

    # Load configuration variables
    source $POWER_CONFIG_FILE
    source $DATA_OUT_CONFIG_FILE
    source $SPEF_CONFIG_FILE

    # Design variables
    `@voltus_pre_init_variables`

    # Load MMMC configuration
    puts "MMMC file: $DYNAMIC_POWER_VIEW_MMMC_FILE"
    read_mmmc $DYNAMIC_POWER_VIEW_MMMC_FILE
    
    # Load design files
    read_physical -lefs [join $LEF_FILES]
    read_netlist $NETLIST_FILE -top $DESIGN_NAME
    read_def $DEF_FILE -skip_signal_nets 

    # Design initialization
    init_design
    `@voltus_post_init_design_technology`
    `@voltus_post_init_variables`

    # Switch to propagated mode    
    set_interactive_constraint_mode [get_db [get_db constraint_modes -if {.is_setup||.is_hold}] .name]
    set_propagated_clock [get_clocks *]
    
    # Read parasitics
    if {[file exists [set SPEF_FILE $SPEF_DIR/$SPEF_TASK_NAME.$POWER_SPEF_CORNER.spef.gz]]} {
        puts "SPEF file: $SPEF_FILE"
        read_spef $SPEF_FILE
    } else {
        puts "\033\[41m \033\[0m SPEF file $SPEF_FILE not found"
        suspend
    }
    
    # Run analysis
    `@voltus_run_report_power_dynamic`

    # Close interactive session
    exit
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

# Choose configuration file
gf_choose_file_dir_task -variable VOLTUS_POWER_CONFIG_FILE -keep -prompt "Please select timing configuration file:" -files '
    ../data/*.timing.tcl
    ../data/*/*.timing.tcl
    ../work_*/*/out/ConfigSignoff*.power.tcl
'

# Choose configuration file
gf_choose_file_dir_task -variable VOLTUS_DATA_OUT_CONFIG_FILE -keep -prompt "Please select design configuration file:" -files '
    ../data/*.design.tcl
    ../data/*/*.design.tcl
    ../work_*/*/out/DataOutPhysical*.design.tcl
' -want -active -task_to_file '$RUN/out/$TASK.design.tcl' -tasks '
    ../work_*/*/tasks/DataOutPhysical*
'

# Choose configuration file
gf_choose_file_dir_task -variable VOLTUS_SPEF_CONFIG_FILE -keep -prompt "Please select design configuration file:" -files '
    ../data/*.design.tcl
    ../data/*/*.design.tcl
    ../work_*/*/out/Extraction*.design.tcl
' -want -active -task_to_file '$RUN/out/$TASK.design.tcl' -tasks '
    ../work_*/*/tasks/Extraction*
'

# Select PGV to analyze if empty
gf_choose_file_dir_task -variable VOLTUS_PGV_LIBS -keep -prompt "Please select PGV libraries:" -dirs '
    ../work_*/*/out/TechPGV*/*.cl
'
gf_info "PGV libraries \e[32m$VOLTUS_PGV_LIBS\e[0m selected"

# TCL commands
gf_add_tool_commands '

    # Current design variables
    set LEF_FILES {`$CADENCE_TLEF_FILES` `$LEF_FILES`}
    set VOLTUS_PGV_LIBS [join {`$VOLTUS_PGV_LIBS`}]

    set DESIGN_NAME {`$DESIGN_NAME`} 
    set POWER_TASK {`$DYNAMIC_POWER_TASK`}
    
    set POWER_CONFIG_FILE {`$VOLTUS_POWER_CONFIG_FILE`}
    set DATA_OUT_CONFIG_FILE {`$VOLTUS_DATA_OUT_CONFIG_FILE`}
    set SPEF_CONFIG_FILE {`$VOLTUS_SPEF_CONFIG_FILE`}

    # Load configuration variables
    source $POWER_CONFIG_FILE
    source $DATA_OUT_CONFIG_FILE
    source $SPEF_CONFIG_FILE

    # Design variables
    `@voltus_pre_init_variables`

    # Load MMMC configuration
    puts "QRC file: {$DYNAMIC_RAIL_VIEW_TEMPERATURE $DYNAMIC_RAIL_VIEW_QRC_FILE}"
    puts "MMMC file: $DYNAMIC_RAIL_VIEW_MMMC_FILE"
    read_mmmc $DYNAMIC_RAIL_VIEW_MMMC_FILE
    
    # Load design files
    read_physical -lefs [join $LEF_FILES]
    read_netlist $NETLIST_FILE -top $DESIGN_NAME
    read_def $DEF_FILE -skip_signal_nets 

    # Design initialization
    init_design
    `@voltus_post_init_design_technology`
    `@voltus_post_init_variables`

    # Switch to propagated mode    
    set_interactive_constraint_mode [get_db [get_db constraint_modes -if {.is_setup||.is_hold}] .name]
    set_propagated_clock [get_clocks *]
    
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

# Choose configuration file
gf_choose_file_dir_task -variable VOLTUS_POWER_CONFIG_FILE -keep -prompt "Please select timing configuration file:" -files '
    ../data/*.timing.tcl
    ../data/*/*.timing.tcl
    ../work_*/*/out/ConfigSignoff*.power.tcl
'

# Choose configuration file
gf_choose_file_dir_task -variable VOLTUS_DATA_OUT_CONFIG_FILE -keep -prompt "Please select design configuration file:" -files '
    ../data/*.design.tcl
    ../data/*/*.design.tcl
    ../work_*/*/out/DataOutPhysical*.design.tcl
' -want -active -task_to_file '$RUN/out/$TASK.design.tcl' -tasks '
    ../work_*/*/tasks/DataOutPhysical*
'

# Choose configuration file
gf_choose_file_dir_task -variable VOLTUS_SPEF_CONFIG_FILE -keep -prompt "Please select design configuration file:" -files '
    ../data/*.design.tcl
    ../data/*/*.design.tcl
    ../work_*/*/out/Extraction*.design.tcl
' -want -active -task_to_file '$RUN/out/$TASK.design.tcl' -tasks '
    ../work_*/*/tasks/Extraction*
'

# TCL commands
gf_add_tool_commands '

    # Current design variables
    set LEF_FILES {`$CADENCE_TLEF_FILES` `$LEF_FILES`}

    set DESIGN_NAME {`$DESIGN_NAME`} 
    
    set POWER_CONFIG_FILE {`$VOLTUS_POWER_CONFIG_FILE`}
    set DATA_OUT_CONFIG_FILE {`$VOLTUS_DATA_OUT_CONFIG_FILE`}
    set SPEF_CONFIG_FILE {`$VOLTUS_SPEF_CONFIG_FILE`}

    # Load configuration variables
    source $POWER_CONFIG_FILE
    source $DATA_OUT_CONFIG_FILE
    source $SPEF_CONFIG_FILE

    # Design variables
    `@voltus_pre_init_variables`

    # Load MMMC configuration
    puts "MMMC file: $SIGNAL_EM_VIEW_MMMC_FILE"
    read_mmmc $SIGNAL_EM_VIEW_MMMC_FILE
    
    # Load design files
    read_physical -lefs [join $LEF_FILES]
    read_netlist $NETLIST_FILE -top $DESIGN_NAME
    read_def $DEF_FILE -skip_signal_nets 

    # Design initialization
    init_design
    `@voltus_post_init_design_technology`
    `@voltus_post_init_variables`

    # Switch to propagated mode    
    set_interactive_constraint_mode [get_db [get_db constraint_modes -if {.is_setup||.is_hold}] .name]
    set_propagated_clock [get_clocks *]
    
    # Read parasitics
    if {[file exists [set SPEF_FILE $SPEF_DIR/$SPEF_TASK_NAME.$SIGNAL_SPEF_CORNER.spef.gz]]} {
        puts "SPEF file: $SPEF_FILE"
        read_spef $SPEF_FILE
    } else {
        puts "\033\[41m \033\[0m SPEF file $SPEF_FILE not found"
        suspend
    }
    
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
gf_add_status_marks 'No such file'
gf_add_failed_marks 'No such file'
gf_submit_task
