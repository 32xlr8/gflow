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
# Filename: templates/project_template.2023/blocks/block_template/innovus.impl.gf
# Purpose:  Batch implementation flow
################################################################################

########################################
# Main options
########################################

# Project and block initialization scripts
gf_source "../../project.common.gf"
gf_source "../../project.innovus.gf"
gf_source "./block.common.gf"
gf_source "./block.files.gf"
gf_source "./block.innovus.gf"

# # Quantus required if high effort extraction used
# gf_source "../../project.quantus.gf"

########################################
# Innovus initialization and placement
########################################

gf_create_task -name Place
gf_use_innovus

# Choose netlist if not chosen
gf_choose_file_dir_task -variable NETLIST_FILES -keep -prompt 'Please select netlist to implement:' -files '
    ../data/*.v
    ../data/*.v.gz
    ../data/*/*.v
    ../data/*/*.v.gz
    ../work_*/*/out/SynMap*.v
    ../work_*/*/out/SynOpt*.v
' -want -active -task_to_file '$RUN/out/$TASK.v' -tasks '
    ../work_*/*/tasks/SynMap*
    ../work_*/*/tasks/SynOpt*
'

# Choose floorplan if not chosen
gf_choose_file_dir_task -variable FLOORPLAN_FILE -keep -prompt "Please select floorplan:" -files '
    ../data/*.fp
    ../data/*/*.fp
    ../work_*/*/out/*.fp
'

# Check netlist and floorplan are ready
gf_check_files "$FLOORPLAN_FILE"* "$NETLIST_FILES"

# Choose MMMC file
gf_choose_file_dir_task -variable MMMC_FILE -keep -prompt "Please select MMMC file:" -files '
    ../data/*.mmmc.tcl
    ../data/*/*.mmmc.tcl
    ../work_*/*/out/BackendMMMC*.mmmc.tcl
'

# Save input files
gf_add_shell_commands -init '
    mkdir -p ./in/$TASK_NAME/
    for file in `$NETLIST_FILES` `$FLOORPLAN_FILE` `$SCANDEF_FILE -optional` `$CPF_FILE -optional` `$UPF_FILE -optional`; do
        cp $file* ./in/$TASK_NAME/
    done
'

# TCL commands
gf_add_tool_commands '

    # Current design variables
    set LEF_FILES {`$CADENCE_TLEF_FILES` `$LEF_FILES`}
    set NETLIST_FILES {`$NETLIST_FILES`}
    set SCANDEF_FILE {`$SCANDEF_FILE -optional`}
    set LDB_MODE {`$LDB_MODE -optional`}
    set CPF_FILE {`$CPF_FILE -optional`}
    set UPF_FILE {`$UPF_FILE -optional`}
    set FLOORPLAN_FILE {`$FLOORPLAN_FILE`}
    set DESIGN_NAME {`$DESIGN_NAME`}
    set POWER_NETS {`$POWER_NETS_CORE` `$POWER_NETS_OTHER -optional`}
    set GROUND_NETS {`$GROUND_NETS_CORE` `$GROUND_NETS_OTHER -optional`}
    set MMMC_FILE {`$MMMC_FILE`}
    set OCV_FILE "[regsub {\.mmmc\.tcl$} $MMMC_FILE {}].ocv.tcl"

    # Common tool procedures
    `@innovus_procs_common`

    # Pre-load settings
    `@innovus_pre_read_libs`

    # Load MMMC configuration
    read_mmmc $MMMC_FILE

    # Initialize power and ground nets
    set_db init_power_nets [join $POWER_NETS]
    set_db init_ground_nets [join $GROUND_NETS]

    # Read physical information defined in project config
    read_physical -lefs [join $LEF_FILES]

    # Read netlist for current design
    read_netlist [join $NETLIST_FILES] -top $DESIGN_NAME

    # Initialize library and design information
    init_design

    # Read CPF power intent information
    if {[file exists $CPF_FILE]} {
        read_power_intent -cpf $CPF_FILE
    }

    # Read 1801 power intent information
    if {[file exists $UPF_FILE]} {
        read_power_intent -1801 $UPF_FILE
    }

    # Apply power intent
    if {[file exists $CPF_FILE] || [file exists $UPF_FILE]} {
        commit_power_intent
        foreach delay_corner [get_db delay_corners] {
            set timing_condition [get_db $delay_corner .late_timing_condition.name]
            foreach power_domain [get_db power_domains] {
                append timing_condition " [get_db $power_domain .name]@[get_db $delay_corner .late_timing_condition.name]"
            }
            update_delay_corner -name [get_db $delay_corner .name] -timing_condition $timing_condition
        }
        
    # Error if CPF is incorrect
    } elseif {$CPF_FILE != {}} {
        puts "\033\[41m \033\[0m CPF $CPF_FILE not found"
        suspend

    # Error if UPF is incorrect
    } elseif {$UPF_FILE != {}} {
        puts "\033\[41m \033\[0m UPF $UPF_FILE not found"
        suspend
    }    
    
    # Read floorplan
    read_floorplan $FLOORPLAN_FILE
    
    # Read scan chain info
    if {[file exists $SCANDEF_FILE]} {
        read_def $SCANDEF_FILE
        
    # Continue even if scan chains are empty
    } else {
        puts "\033\[43m \033\[0m Scan definition $SCANDEF_FILE not found"
        set_db place_global_ignore_scan false
    }
    
    # Stage-specific options    
    `@innovus_post_init_design`

    # Load OCV configuration
    reset_timing_derate
    source $OCV_FILE
    report_timing_derate > ./reports/$TASK_NAME.derate.rpt

    # Create initial metrics
    create_snapshot -name Init
    
    # Write Innovus database
    write_db ./out/$TASK_NAME.intermediate.innovus.db
    
    # Start metric collection
    `@collect_metrics`
    
    # Stage-specific options    
    `@innovus_pre_place`
    
    # Run placement
    set_db opt_new_inst_prefix Place
    place_opt_design -report_dir ./reports/$TASK_NAME -report_prefix place_opt_design
    reset_db opt_new_inst_prefix

    # Stage-specific options    
    `@innovus_post_place`
    
    # Report collected metrics
    `@report_metrics`
    
    # Write Innovus database
    if {$LDB_MODE == "Y"} {
        write_db -lib_to_ldb ./out/$TASK_NAME.innovus.db
    } else {
        write_db ./out/$TASK_NAME.innovus.db
    }

    # Close interactive session
    exit
'

# Display status
gf_add_status_marks -from 'Final .*Summary' -to 'Density:' WNS TNS max_tran -3 +3
gf_add_status_marks -from '\|.*max hotspot.*\|' -expr '[\|\+]' -to '^[^\|\+]*$' -1
gf_add_status_marks 'Could not legalize .* instances in the design'

# Failed if some files not found
gf_add_failed_marks 'ERROR:.\+No files'

# Run task
gf_submit_task

########################################
# Innovus clock implementation
########################################

gf_create_task -name Clock -mother Place
gf_use_innovus

# TCL commands
gf_add_tool_commands '

    # Pre-load settings
    `@innovus_pre_read_libs`

    # Load Innovus database
    read_db ./out/$MOTHER_TASK_NAME.innovus.db

    # Start metric collection
    `@collect_metrics`

    # Stage-specific options    
    `@innovus_pre_clock`
    
    # Insert dedicated tieoff cells
    if {[get_db add_tieoffs_cells] ne "" } {
        delete_tieoffs
        add_tieoffs -matching_power_domains true
    }

    # Run clock tree synthesis
    set_db opt_new_inst_prefix Clock
    ccopt_design -report_dir ./reports/$TASK_NAME -report_prefix ccopt_design
    reset_db opt_new_inst_prefix

    # Stage-specific options    
    `@innovus_post_clock`
    
    # Write Innovus database
    write_db ./out/$TASK_NAME.intermediate.innovus.db

    # Stage-specific options    
    `@innovus_pre_clock_opt_hold`
    
    # Perform postcts hold optimization
    set_db opt_new_inst_prefix ClockOptHold
    opt_design -post_cts -hold -report_dir ./reports/$TASK_NAME -report_prefix opt_design \
        -hold_violation_report ./reports/$TASK_NAME/opt_design.hold_violations
    reset_db opt_new_inst_prefix

    # Stage-specific options    
    `@innovus_post_clock_opt_hold`
    
    # Report collected metrics
    `@report_metrics`
        
    # Write Innovus database
    write_db ./out/$TASK_NAME.innovus.db

    # Close interactive session
    exit
'

# Display status
gf_add_status_marks -from 'CCOpt::Phase::PostConditioning done' -from 'Summary of all messages' 'IMPCCOPT-'
gf_add_status_marks -from 'CCOpt::Phase::PostConditioning done' -from 'Units' -1 '\S' -to '^\s*$'
gf_add_status_marks -from 'CCOpt::Phase::PostConditioning done' -from 'Inst Area' -1 '\S' -to '^\s*$'

# Display status
gf_add_status_marks -from 'Hold Opt .*Summary' -from 'Hold mode' -to 'All Paths:' -1 +1
gf_add_status_marks -from 'Final .*Summary' -to 'Density:' WNS TNS max_tran -3 +3
gf_add_status_marks -1 +3 -from 'End ccopt_design' 'max hotspot'
gf_add_status_marks -1 +3 -from 'HoldOpt .*finish' 'max hotspot'

# Run task
gf_submit_task

########################################
# Innovus routing
########################################

gf_create_task -name Route -mother_last
gf_use_innovus

# TCL commands
gf_add_tool_commands '

    # Pre-load settings
    `@innovus_pre_read_libs`

    # Load Innovus database
    read_db ./out/$MOTHER_TASK_NAME.innovus.db

    # Start metric collection
    `@collect_metrics`

    # Stage-specific Innovus options    
    `@innovus_pre_route`

    # Perform routing
    set_db opt_new_inst_prefix Route
    route_design -track_opt
    reset_db opt_new_inst_prefix

    # Write Innovus database
    write_db ./out/$TASK_NAME.intermediate.innovus.db
    
    # Perform post-route setup and hold optimization
    set_db opt_new_inst_prefix RouteOptSetupHold
    opt_design -post_route -setup -hold -report_dir ./reports/$TASK_NAME -report_prefix opt_design \
        -hold_violation_report ./reports/$TASK_NAME/opt_design.hold_violations
    reset_db opt_new_inst_prefix

    # Report collected metrics
    `@report_metrics`
        
    # Write Innovus database
    write_db ./out/$TASK_NAME.innovus.db
    
    # Close interactive session
    exit
'

# Display status
gf_add_status_marks -from 'Hold Opt .*Summary' -from 'Hold mode' -to 'All Paths:' -1 +1
gf_add_status_marks -from 'Final .*Summary' -to 'Density:' WNS TNS max_tran -3 +3
gf_add_status_marks 'number of DRC violations'

# Run task
gf_submit_task

########################################
# Innovus pre-cts reports task
########################################

gf_create_task -name ReportPlace -mother Place -group Reports -parallel 1
gf_use_innovus_batch

# TCL commands
gf_add_tool_commands '

    # Pre-load settings
    `@innovus_pre_read_libs`

    # Load Innovus database
    read_db ./out/$MOTHER_TASK_NAME.innovus.db
    
    # Start metric collection
    `@collect_metrics`

    # Create reports directory
    exec mkdir -p ./reports/$TASK_NAME
    
    # Design-specific reports
    `@innovus_design_reports_post_place`
    
    # Report collected metrics
    `@report_metrics`
'

# Print timing summary
gf_add_status_marks -from 'time_design Summary' -1 -from '(Setup|Hold) mode' -to 'Density:' -exclude '^\s*$'

# Submit task
gf_submit_task -silent

########################################
# Innovus post-clock reports tasks
########################################

gf_create_task -name ReportClock -mother Clock -group Reports -parallel 1
gf_use_innovus_batch

# TCL commands
gf_add_tool_commands '

    # Pre-load settings
    `@innovus_pre_read_libs`

    # Load Innovus database
    read_db ./out/$MOTHER_TASK_NAME.innovus.db

    # Start metric collection
    `@collect_metrics`

    # Create reports directory
    exec mkdir -p ./reports/$TASK_NAME
    
    # Design-specific reports
    `@innovus_design_reports_post_clock`

    # Report collected metrics
    `@report_metrics`
'

# Print timing summary
gf_add_status_marks -from 'time_design Summary' -1 -from '(Setup|Hold) mode' -to 'Density:' -exclude '^\s*$'

# Submit task
gf_submit_task -silent

########################################
# Innovus post-route reports task
########################################

gf_create_task -name ReportRoute -mother Route -group Reports -parallel 1
gf_use_innovus_batch

# TCL commands
gf_add_tool_commands '

    # Pre-load settings
    `@innovus_pre_read_libs`

    # Load Innovus database
    read_db ./out/$MOTHER_TASK_NAME.innovus.db

   # Start metric collection
    `@collect_metrics`

    # Create reports directory
    exec mkdir -p ./reports/$TASK_NAME
    
    # Design-specific reports
    `@innovus_design_reports_post_route`

    # Report collected metrics
    `@report_metrics`
'

# Print timing summary
gf_add_status_marks -from 'time_design Summary' -1 -from '(Setup|Hold) mode' -to 'Density:' -exclude '^\s*$'

# Submit task
gf_submit_task -silent
