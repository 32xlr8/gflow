#!../../gflow/bin/gflow

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
# Filename: templates/project.2025/blocks/template/tempus.out.split.views.gf
# Purpose:  Batch signoff timing data out with several tasks splitted by delay corners
################################################################################

########################################
# Main options
########################################

# Project and block initialization scripts
gf_source -once "../../project.common.gf"
gf_source -once "../../project.tempus.gf"
gf_source -once "./block.common.gf"
gf_source -once "./block.tempus.gf"

# Run tasks in silent mode
gf_set_task_options TempusOut_* -silent

# Spread tasks in time
WAIT_TIME_STEP=60

########################################
# Split tasks
########################################

# Spread tasks in time
[[ -n "$WAIT_TIME_STEP" ]] && WAIT_TIME=0

gf_create_task -name SplitTempusOut -restart
gf_set_task_command "sleep 10; grep -H set ./in/$TASK_NAME/*.tcl"

# Generic Config MMMC generation
gf_use_gconfig
gf_add_tool_commands -file "./tasks/$TASK_NAME/run.tcl" '
    set TASK_NAME {`$TASK_NAME`}
    set DIR "`$GF_RUN_DIR`/tasks/$TASK_NAME"
    cd $DIR

    # Initialize Generic Config 
    source "../../../../../../gflow/bin/gconfig.tcl"

    # Load MMMC procedures
    `@init_gconfig_mmmc`
    `@gconfig_project_settings`
    `@gconfig_settings_common`
    `@gconfig_cadence_mmmc_files`
    `@tempus_gconfig_design_settings`

    # Create groups based on input files
    set groups {}
    set grouped_masks {}
    foreach mask $MMMC_VIEWS {
        set group [join [list [lindex $mask 0]_ [lindex $mask 1] [lindex $mask 2] [lindex $mask 3] [lindex $mask 4] _[lindex $mask 5]] ""]
        if {[lsearch -exact $groups $group] < 0} {
            lappend groups $group
        }
        lappend grouped_masks [list $group $mask]
    }
    
    # Generate timing configuration
    exec mkdir -p ../../in/$TASK_NAME
    set FG [open ../../in/$TASK_NAME.groups "w"]
    foreach group $groups {
        set masks {}
        foreach grouped_mask $grouped_masks {
            if {[lindex $grouped_mask 0] == $group} {
                lappend masks [lindex $grouped_mask 1]
            }
        }
        set file "../../in/$TASK_NAME/$group.tcl"
        set FH [open $file "w"]
        puts $FH "set MMMC_VIEWS {$masks}"
        close $FH
        puts $FG "$group"
    }
    close $FG
'
if [ -z "$GF_SKIP_TASK" ]; then
    rm -f $GF_RUN_DIR/in/$TASK_NAME/*.tcl $GF_RUN_DIR/in/$TASK_NAME.*.init.tcl
    tclsh $GF_RUN_DIR/tasks/$TASK_NAME/run.tcl
fi

# Statuses
gf_add_status_marks 'tcl:set'

# Run task
SPLIT_TASK_NAME=$TASK_NAME
gf_submit_task

########################################
# Tempus data out
########################################
for GROUP in $(cat $GF_RUN_DIR/in/$SPLIT_TASK_NAME.groups); do

gf_create_task -name TempusOut_$GROUP -mother SplitTempusOut
gf_use_tempus

# Spread tasks in time
if [ -n "$WAIT_TIME_STEP" -a -z "$GF_SKIP_TASK" ]; then
    gf_wait_time $WAIT_TIME
    WAIT_TIME=$((WAIT_TIME+$WAIT_TIME_STEP))
fi

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

    set DESIGN_NAME {`$DESIGN_NAME`} 
    set POWER_NETS {`$POWER_NETS_CORE` `$POWER_NETS_OTHER -optional`}
    set GROUND_NETS {`$GROUND_NETS_CORE` `$GROUND_NETS_OTHER -optional`}

    set DATA_OUT_DIR {`$DATA_OUT_DIR`}
    set SPEF_OUT_DIR {`$SPEF_OUT_DIR`}
    set PARTITIONS_NETLIST_FILES {`$PARTITIONS_NETLIST_FILES -optional`}
    
    set IGNORE_IO_TIMING {`$IGNORE_IO_TIMING`}

    # Use separate Generic Config script
    source ./scripts/$TASK_NAME.gconfig.tcl

    # Load common tool procedures
    source ./scripts/$TASK_NAME.procs.tcl

    # Pre-load settings
    `@tempus_pre_read_libs`
    
    # Initialize power and ground nets
    set_db init_power_nets [join $POWER_NETS]
    set_db init_ground_nets [join $GROUND_NETS]

    # Load MMMC configuration
    read_mmmc ./in/$TASK_NAME.mmmc.tcl

    # Read physical information defined in project config
    read_physical -lefs [join $LEF_FILES]
    
    # Read netlist files
    set files $DATA_OUT_DIR/$DESIGN_NAME.v.gz
    foreach file $PARTITIONS_NETLIST_FILES {lappend files $file}
    foreach file $files {
        if {[file exists $file]} {
            puts "Netlist file: $file"
            lappend files $file
        } else {
            puts "\033\[41m \033\[0m Netlist file $file not found"
            suspend
        }
    }
    read_netlist $files -top $DESIGN_NAME

    # Initialize design with MMMC configuration
    init_design
    
    # Load OCV configuration
    redirect -tee ./reports/$TASK_NAME.ocv.rpt {
        reset_timing_derate
        source ./in/$TASK_NAME.ocv.tcl
    }
    redirect ./reports/$TASK_NAME.derate.rpt {report_timing_derate}
    
    # Initialize tool environment
    `@tempus_post_init_design_project`
    `@tempus_post_init_design`
    `@procs_tempus_reports`

    # Read design parasitics files
    set processed {}; set missing 0
    foreach view $MMMC_VIEWS {
        set rc_corner [gconfig::get extract_corner_name -view $view]
        if {[lsearch -exact $processed $rc_corner] < 0} {
            lappend processed $rc_corner
            set files $SPEF_OUT_DIR/$DESIGN_NAME.$rc_corner.spef.gz
            foreach file [gconfig::get_files spef -view $view] {lappend files $file}
            foreach file $files {
                if {[file exists $file]} {
                    puts "SPEF file: $file"
                } else {
                    puts "\033\[41m \033\[0m SPEF file $file not found"
                    incr missing
                }
            }
            if {$missing == 0} {
                read_spef -rc_corner $rc_corner $files
            }
        }
    }
    if {$missing > 0} {
        puts "\033\[41m \033\[0m SPEF files not found for some RC corners"
        suspend
    }
    report_annotated_parasitics > ./reports/$TASK_NAME.annotation.rpt
    puts [exec cat ./reports/$TASK_NAME.annotation.rpt]
    
    # Switch to propagated clocks mode
    if {$IGNORE_IO_TIMING == "Y"} {
        set_interactive_constraint_mode [get_db [get_db constraint_modes -if {.is_setup||.is_hold}] .name]
        reset_propagated_clock [get_clocks *] 
        set_propagated_clock [get_clocks *] 
        set_interactive_constraint_mode {}
    } else {
        update_io_latency
    }

    # Perform timing update
    update_timing -full

    # Write out STA files
    set ORIGINAL_TASK_NAME $TASK_NAME
    set TASK_NAME [regsub {_\w+} $TASK_NAME {}]
    exec mkdir -p ./reports/$TASK_NAME
    `@tempus_data_out`
    set TASK_NAME $ORIGINAL_TASK_NAME
    
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
    `@tempus_gconfig_design_settings`
    
    # Print out summary
    gconfig::show_variables
    gconfig::show_switches

    # Load split configuration
    source ./in/`$MOTHER_TASK_NAME`/`$GROUP`.tcl

    # Generate timing configuration
    try {
        gconfig::get_ocv_commands -views $MMMC_VIEWS -dump_to_file ./in/$TASK_NAME.ocv.tcl
        gconfig::get_mmmc_commands -views $MMMC_VIEWS -all_active -dump_to_file ./in/$TASK_NAME.mmmc.tcl

    # Suspend on error
    } on error {result options} {
        exec rm -f ./in/$TASK_NAME.ocv.tcl ./in/$TASK_NAME.mmmc.tcl
        puts "\033\[41;31m \033\[0m $result"
        suspend
    }
'

# Common tool procedures
gf_add_tool_commands -comment '#' -file ./scripts/$TASK_NAME.procs.tcl '
    `@tempus_procs_common`
    `@procs_tempus_read_data`
'

# Statuses
gf_add_status_marks '^\s*Writing'
gf_add_status_marks '^\w+\s+file:'

# Failed if some files not found
gf_add_failed_marks '^\*\*ERROR:.+file\s+not'

# Run task
gf_submit_task

done

########################################
# Summary task
########################################

gf_create_task -name TempusOut -mother SplitTempusOut
gf_want_tasks TempusOut_*
gf_set_task_command "tclsh ./scripts/$TASK_NAME.tcl"

# Generic Config MMMC generation
gf_add_tool_commands -file "./scripts/$TASK_NAME.tcl" -comment '#' '
    set TASK_NAME {`$TASK_NAME`}

    # Initialize Generic Config 
    source "../../../../../../gflow/bin/gconfig.tcl"

    # Load MMMC procedures
    `@init_gconfig_mmmc`
    `@gconfig_project_settings`
    `@gconfig_settings_common`
    `@gconfig_cadence_mmmc_files`
    `@tempus_gconfig_design_settings`

    # Print report_timing summary
    `@procs_tempus_reports`
    foreach view $MMMC_VIEWS {
        catch {
            foreach file [glob ./reports/$TASK_NAME/*.gba.reg2reg.[gconfig::get analysis_view_name -view $view].tarpt] {
                puts "[gf_print_report_timing_summary $file] @ [file tail $file]"
            }
        }
    }
'

# Statuses
gf_add_status_marks '^[^\"]*WNS .* AVG .* of .* violated'

# Run task
gf_submit_task
