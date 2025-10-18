#!../../gflow/bin/gflow

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
# Filename: templates/project.2025/blocks/template/voltus.sem.gf
# Purpose:  Batch signal electromigration flow
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
# Signal electromigration calculation
########################################

gf_create_task -name SignalEM
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

# TCL commands
gf_add_tool_commands '

    # Current design variables
    set LEF_FILES {`$CADENCE_TLEF_FILES` `$LEF_FILES` `$PARTITIONS_LEF_FILES -optional`}
    set CPF_FILE {`$CPF_FILE -optional`}
    set UPF_FILE {`$UPF_FILE -optional`}

    set DESIGN_NAME {`$DESIGN_NAME`} 
    
    set DATA_OUT_DIR {`$DATA_OUT_DIR`}
    set SPEF_OUT_DIR {`$SPEF_OUT_DIR`}
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
    exec ln -nsf $DATA_OUT_DIR/$DESIGN_NAME.full.def.gz ./in/$TASK_NAME.def.gz

    # Read physical files
    read_physical -lefs [join $LEF_FILES]
    
    # Read timing files
    puts "Analysis view: {$SIGNAL_EM_VIEW}"
    # set_power_lib_files [gconfig::get_files lib -view $SIGNAL_EM_VIEW]
    read_libs [gconfig::get_files lib -view $SIGNAL_EM_VIEW]
    
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
    read_sdc [gconfig::get_files sdc -view $SIGNAL_EM_VIEW]

    # Read design physical files
    set files $DATA_OUT_DIR/$DESIGN_NAME.full.def.gz
    foreach file $PARTITIONS_DEF_FILES {lappend files $file}
    foreach file $files {
        if {[file exists $file]} {
            puts "DEF file: $file"
        } else {
            puts "\033\[41m \033\[0m DEF file $file not found"
            suspend
        }
    }
    read_def $files

    # Read design parasitics files
    set rc_corner [gconfig::get extract_corner_name -view $SIGNAL_EM_VIEW]
    set files $SPEF_OUT_DIR/$DESIGN_NAME.$rc_corner.spef.gz
    foreach file [gconfig::get_files spef -view $SIGNAL_EM_VIEW] {lappend files $file}
    foreach file $files {
        if {[file exists $file]} {
            puts "SPEF file: $file"
        } else {
            puts "\033\[41m \033\[0m SPEF file $file not found"
            suspend
        }
    }
    # set_power_spef_files $files
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

    # Run signal electromigration analysis
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
    `@voltus_gconfig_electromigration_design_settings`
    
    # Print out summary
    gconfig::show_variables
    gconfig::show_switches
'

# Run task
gf_add_status_marks '\(.*MHz\)' '^Cell.*:' 'Files:' 'Coverage:' 'SPEF:' 'TWF:'
gf_add_success_marks 'Voltus EM Analysis exited successfully'
gf_add_status_marks 'There is no'
gf_add_status_marks 'No such file'
gf_add_failed_marks 'No such file'
gf_submit_task

########################################
# Generic Flow history
########################################

gf_create_task -name HistorySignalEM -mother SignalEM
gf_set_task_command "../../../../../../tools/print_flow_history.pl ../.. -html ./reports/$TASK_NAME.html"
gf_submit_task -silent
