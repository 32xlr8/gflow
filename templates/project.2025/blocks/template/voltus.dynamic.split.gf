#!../../gflow/bin/gflow

################################################################################
# Generic Flow v5.5.4 (December 2025)
################################################################################
#
# Copyright 2011-2025 Gennady Kirpichev
#
#    https://github.com/32xlr8/gflow.git
#    https://gitflic.ru/project/32xlr8/gflow
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
# Filename: templates/project.2025/blocks/template/voltus.dynamic.gf
# Purpose:  Batch split dynamic power and rail analysis flow
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
# Dynamic power calculation
########################################

gf_create_task -name DynamicPower
gf_use_voltus

# Design data directory
gf_choose_file_dir_task -variable DATA_OUT_DIR -keep -prompt "Choose design data directory:" -dirs '
    ../work_*/*/out/InnovusOut*
' -want -active -task_to_file '$RUN/out/$TASK' -tasks '
    ../work_*/*/tasks/InnovusOut*
'

# SPEF directory
gf_choose_file_dir_task -variable SPEF_OUT_DIR -keep -prompt "Choose SPEF directory:" -dirs '
    ../work_*/*/out/QuantusOut*
' -want -active -task_to_file '$RUN/out/$TASK' -tasks '
    ../work_*/*/tasks/QuantusOut*
'

# Choose between TWF and default STA mode
gf_choose -keep -variable POWER_USE_TWF -keys YN -time 30 -default Y -prompt "Use signoff TWF files (Y/N)?"
if [ "$POWER_USE_TWF" == "Y" ]; then
    gf_choose_file_dir_task -variable TWF_OUT_DIR -keep -prompt "Choose TWF directory:" -dirs '
        ../work_*/*/out/TempusOut*
    ' -want -active -task_to_file '$RUN/out/$TASK' -tasks '
        ../work_*/*/tasks/TempusOut*
    '
else
    TWF_OUT_DIR=
fi

# Select scenario to calculate power
gf_choose -count 25 -keep -variable POWER_SCENARIO \
    -message "Which power scenario to run?" \
    -variants "$(echo "$POWER_SCENARIOS" | sed -e 's|^\s\+||g; s|\s\+$||g;')"


# Select PGV to analyze if empty
gf_choose_file_dir_task -variable VOLTUS_PGV_LIBS -keep -prompt "Choose PGV libraries:" -dirs '
    ../work_*/*/out/TechPGV*/*.cl
'

# TCL commands
gf_add_tool_commands '

    # Current design variables
    set LEF_FILES {`$CADENCE_TLEF_FILES` `$LEF_FILES` `$PARTITIONS_LEF_FILES -optional`}
    set CPF_FILE {`$CPF_FILE -optional`}
    set UPF_FILE {`$UPF_FILE -optional`}

    set DESIGN_NAME {`$DESIGN_NAME`} 
    set POWER_SCENARIO {`$POWER_SCENARIO`}
    
    set DATA_OUT_DIR {`$DATA_OUT_DIR`}
    set SPEF_OUT_DIR {`$SPEF_OUT_DIR`}
    set TWF_OUT_DIR {`$TWF_OUT_DIR -optional`}
    set PARTITIONS_NETLIST_FILES {`$PARTITIONS_NETLIST_FILES -optional`}
    set PARTITIONS_DEF_FILES {`$PARTITIONS_DEF_FILES -optional`}
    
    # Start metric collection
    `@collect_metrics`

    # Use separate Generic Config script
    source ./scripts/$TASK_NAME.gconfig.tcl

    # Design variables
    `@voltus_pre_init_design_variables`

    # Link design files
    exec ln -nsf $DATA_OUT_DIR/$DESIGN_NAME.v.gz ./in/$TASK_NAME.v.gz
    exec ln -nsf $DATA_OUT_DIR/$DESIGN_NAME.def.gz ./in/$TASK_NAME.def.gz

    # Read physical files
    read_physical -lefs [join $LEF_FILES]
    
    # Read timing files
    puts "Analysis view: {$DYNAMIC_POWER_VIEW}"
    # set_power_lib_files [gconfig::get_files lib -view $DYNAMIC_POWER_VIEW]
    read_libs [gconfig::get_files lib -view $DYNAMIC_POWER_VIEW]
    
    # Read netlist files
    set files $DATA_OUT_DIR/$DESIGN_NAME.v.gz
    foreach file $PARTITIONS_NETLIST_FILES {lappend files $file}
    foreach file $files {
        if {[file exists $file]} {
            puts "Netlist file: $file"
        } else {
            puts "\033\[41m \033\[0m Netlist file $file not found"
            suspend
        }
    }
    read_netlist $files -top $DESIGN_NAME
    puts "Netlist files: [join $files]"

    # Design initialization
    init_design
    `@voltus_post_init_design_project`
    `@voltus_post_init_design_variables`
    `@voltus_post_init_design`

    # Read constraints    
    read_sdc [gconfig::get_files sdc -view $DYNAMIC_POWER_VIEW]

    # Read design timing files
    if {[llength $TWF_OUT_DIR]} {
        set view [gconfig::get analysis_view_name -view $DYNAMIC_POWER_VIEW]
        if {[file exists [set file $TWF_OUT_DIR/$DESIGN_NAME.$view.twf.gz]]} {
            puts "TWF file: $file"
            read_twf -view [lindex [get_db analysis_views .name] 0] -verbose $file
        } else {
            puts "\033\[41m \033\[0m TWF file $file not found"
            suspend
        }
        foreach file [gconfig::get_files twf -view $DYNAMIC_POWER_VIEW] {
            set cell [regsub {\..*$} [file tail $file] {}]
            if {[file exists $file]} {
                puts "TWF file: $file"
                read_twf -cell $cell -view [lindex [get_db analysis_views .name] 0] -verbose $file
            } else {
                puts "\033\[41m \033\[0m TWF file $file not found"
                suspend
            }
        }
    }
       
    # Read design physical files
    set files $DATA_OUT_DIR/$DESIGN_NAME.def.gz
    foreach file $PARTITIONS_DEF_FILES {lappend files $file}
    foreach file $files {
        if {[file exists $file]} {
            puts "DEF file: $file"
        } else {
            puts "\033\[41m \033\[0m DEF file $file not found"
            suspend
        }
    }
    # set_power_def_files $files
    read_def $files -skip_signal_nets 

    # Read design parasitics files
    set rc_corner [gconfig::get extract_corner_name -view $DYNAMIC_POWER_VIEW]
    set files $SPEF_OUT_DIR/$DESIGN_NAME.$rc_corner.spef.gz
    foreach file [gconfig::get_files spef -view $DYNAMIC_POWER_VIEW] {lappend files $file}
    foreach file $files {
        if {[file exists $file]} {
            puts "SPEF file: $file"
        } else {
            puts "\033\[41m \033\[0m SPEF file $file not found"
            suspend
        }
    }
    # set_power_spef_files $files
    # read_spef -decoupled -extended -keep_star_node_location $files
    read_spef -extended -keep_star_node_location $files
    report_annotated_parasitics > ./reports/$TASK_NAME.annotation.rpt
    puts [exec cat ./reports/$TASK_NAME.annotation.rpt]
    
    # Read CPF power intent information
    if {[llength $CPF_FILE]} {
        read_power_intent -cpf $CPF_FILE
    }

    # Read 1801 power intent information
    if {[llength $UPF_FILE]} {
        read_power_intent -1801 $UPF_FILE
    }

    # Switch to propagated mode    
    set_interactive_constraint_mode [get_db [get_db constraint_modes -if {.is_setup||.is_hold}] .name]
    set_propagated_clock [get_clocks *]

    # Run power analysis
    exec rm -Rf ./out/$TASK_NAME.power/
    `@voltus_run_report_power_dynamic`
    
    # Report missing power data
    catch {foreach file [glob ./out/$TASK_NAME.power/*missing*] {exec grep {:} $file}}

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
    `@voltus_gconfig_power_rail_design_settings`
    
    # Print out summary
    gconfig::show_variables
    gconfig::show_switches
'

# Run task
gf_add_status_marks '\(.*MHz\)' '^Cell.*:' 'Files:' 'Coverage:' 'SPEF:' 'TWF:'
gf_add_success_marks 'Voltus Power Analysis exited successfully'
gf_add_status_marks 'No such file'
gf_add_failed_marks 'No such file'
gf_submit_task

########################################
# Dynamic rail calculation
########################################

gf_create_task -name DynamicRail
gf_use_voltus

# Want for extraction and power analysis to complete
gf_want_tasks DynamicPower -variable DYNAMIC_POWER_TASK

# Design data directory
gf_choose_file_dir_task -variable DATA_OUT_DIR -keep -prompt "Choose design data directory:" -dirs '
    ../work_*/*/out/InnovusOut*
' -want -active -task_to_file '$RUN/out/$TASK' -tasks '
    ../work_*/*/tasks/InnovusOut*
'

# Select PGV to analyze if empty
gf_choose_file_dir_task -variable VOLTUS_PGV_LIBS -keep -prompt "Choose PGV libraries:" -dirs '
    ../work_*/*/out/TechPGV*/*.cl
'

# TCL commands
gf_add_tool_commands '

    # Current design variables
    set LEF_FILES {`$CADENCE_TLEF_FILES` `$LEF_FILES` `$PARTITIONS_LEF_FILES -optional`}
    set DATA_OUT_DIR {`$DATA_OUT_DIR`}

    set DESIGN_NAME {`$DESIGN_NAME`} 
    set POWER_TASK_NAME {`$DYNAMIC_POWER_TASK`}
    
    set SPEF_OUT_DIR {`$SPEF_OUT_DIR`}
    set TWF_OUT_DIR {`$TWF_OUT_DIR -optional`}
    set PARTITIONS_NETLIST_FILES {`$PARTITIONS_NETLIST_FILES -optional`}
    set PARTITIONS_DEF_FILES {`$PARTITIONS_DEF_FILES -optional`}
    
    # Start metric collection
    `@collect_metrics`

    # Use separate Generic Config script
    source ./scripts/$TASK_NAME.gconfig.tcl

    # Design variables
    `@voltus_pre_init_design_variables`

    # Link design files
    exec ln -nsf $DATA_OUT_DIR/$DESIGN_NAME.v.gz ./in/$TASK_NAME.v.gz
    exec ln -nsf $DATA_OUT_DIR/$DESIGN_NAME.def.gz ./in/$TASK_NAME.def.gz

    # Load MMMC configuration
    puts "Analysis view: {$DYNAMIC_RAIL_VIEW}"

    # Read physical files
    read_physical -lefs [join $LEF_FILES]
    
    # Read netlist files
    set files $DATA_OUT_DIR/$DESIGN_NAME.v.gz
    foreach file $PARTITIONS_NETLIST_FILES {lappend files $file}
    foreach file $files {
        if {[file exists $file]} {
            puts "Netlist file: $file"
        } else {
            puts "\033\[41m \033\[0m Netlist file $file not found"
            suspend
        }
    }
    read_netlist $files -top $DESIGN_NAME
    puts "Netlist files: [join $files]"

    # Design initialization
    init_design
    `@voltus_post_init_design_project`
    `@voltus_post_init_design_variables`
    `@voltus_post_init_design`

    # Read design physical files
    set files $DATA_OUT_DIR/$DESIGN_NAME.def.gz
    foreach file $PARTITIONS_DEF_FILES {lappend files $file}
    foreach file $files {
        if {[file exists $file]} {
            puts "DEF file: $file"
        } else {
            puts "\033\[41m \033\[0m DEF file $file not found"
            suspend
        }
    }
    # set_power_def_files $files
    read_def $files -skip_signal_nets 

    # Run rail analysis
    exec rm -Rf ./out/$TASK_NAME.rail/
    `@voltus_run_report_rail_dynamic`

    # Report collected metrics
    `@report_metrics`
    
    # Open latest directory
    set rail_directories [concat \
        [exec sed -ne {s|^.*Run directory\s*:\s*./out/|./out/|ip} [get_db log_file]] \
        [exec sed -ne {s|^.*State directory\s*:\s*out/|./out/|ip} [get_db log_file]] \
    ]
    ::read_power_rail_results -power_db ./out/$POWER_TASK_NAME.power/power.db -rail_directory [lindex $rail_directories 0] -instance_voltage_window {timing whole} -instance_voltage_method {worst best avg worstavg}
    
    # Generate reports
    mkdir -p ./reports/$TASK_NAME

    # Activity
    gui_set_power_rail_display -plot activity -enable_voltage_sources false -legend nw
    gui_fit; write_to_gif ./reports/$TASK_NAME/activity.auto.gif
    
    # Transition
    gui_set_power_rail_display -plot td -enable_voltage_sources false -legend nw
    gui_fit; write_to_gif ./reports/$TASK_NAME/td.auto.gif

    # Unconnected
    gui_set_power_rail_display -plot unc -enable_voltage_sources false -legend nw
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
    
    # Leave session open for debug
    gui_show
    gui_set_power_rail_display -plot ivdd -enable_voltage_sources true

    # Close interactive session
    exit
'

# Generic Config MMMC generation
gf_use_gconfig
gf_add_tool_commands '
    `@gconfig_project_settings`
    `@gconfig_settings_common`
    `@gconfig_cadence_mmmc_files`
    `@voltus_gconfig_power_rail_design_settings`
    
    # Print out summary
    gconfig::show_variables
    gconfig::show_switches
'

# Run task
gf_add_status_marks '\(.*MHz\)' '^Cell.*:' 'Files:' 'Coverage:' 'SPEF:' 'TWF:'
gf_add_success_marks 'Voltus Power Analysis exited successfully'
gf_add_status_marks 'No such file'
gf_add_failed_marks 'No such file'
gf_submit_task

########################################
# Generic Flow history
########################################

gf_create_task -name HistoryDynamicRail -mother DynamicRail
gf_set_task_command "../../../../../../tools/print_flow_history.pl ../.. -html ./reports/$TASK_NAME.html"
gf_submit_task -silent
