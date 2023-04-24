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
# Filename: templates/project_template.2023/blocks/block_template/tempus.gui.gf
# Purpose:  Interactive Tempus debug flow
################################################################################

########################################
# Main options
########################################

# Project and block initialization scripts
gf_source -once "../../project.common.gf"
gf_source -once "../../project.tempus.gf"
gf_source -once "./block.common.gf"
gf_source -once "./block.tempus.gf"

# Basic flow script options
gf_set_flow_options -continue -incr -auto_close -hide

########################################
# Tempus STA
########################################

gf_create_task -name DebugTempus
gf_use_tempus

# Innovus design database
gf_choose_file_dir_task -variable REF_TASK -keep -prompt "Choose reference STA task:" -tasks '
    ../work_*/*/tasks/STA*
'
gf_spacer

REF_RUN="$(dirname "$(dirname "$REF_TASK")")"
REF_TASK_NAME="$(basename "$REF_TASK")"

# Shell commands to initialize environment
gf_add_shell_commands -init "

    # Link required SPEF files
    for spef in $REF_RUN/out/*.spef.gz; do
        ln -nsf \$spef ./out/
    done
"

# TCL commands
gf_add_tool_commands '

    set REF_RUN {`$REF_RUN`}
    set REF_TASK_NAME {`$REF_TASK_NAME`}
    '"$(grep -e '^\s*set\s\+\(SPEF_TASKS\|MOTHER_TASK_NAME\)\s\+' "$REF_RUN/scripts/$REF_TASK_NAME.tcl")"'

    # Current design variables
    set LEF_FILES {`$CADENCE_TLEF_FILES` `$LEF_FILES`}
    set POWER_NETS {`$POWER_NETS_CORE` `$POWER_NETS_OTHER -optional`}
    set GROUND_NETS {`$GROUND_NETS_CORE` `$GROUND_NETS_OTHER -optional`}
    set IGNORE_IO_TIMING {`$IGNORE_IO_TIMING`}
    set MMMC_FILE {`$MMMC_FILE`}
    set OCV_FILE "[regsub {\.mmmc\.tcl$} $MMMC_FILE {}].ocv.tcl"

    # Ignore IMPESI-3490
    eval_legacy {setDelayCalMode -sgs2set abortCdbMmmcFlow:false}

    # Start metric collection
    `@collect_metrics`

    # Get top level design name from Innovus database
    source $REF_RUN/out/$MOTHER_TASK_NAME.init_tempus.tcl
    
    # Initialize power and ground nets
    set_db init_power_nets  [join $POWER_NETS]
    set_db init_ground_nets [join $GROUND_NETS]

    # Load MMMC configuration
    read_mmmc $MMMC_FILE

    # Read physical information defined in project config
    read_physical -lefs [join $LEF_FILES]
    
    # Load netlist
    read_netlist $REF_RUN/out/$MOTHER_TASK_NAME.v -top $DESIGN_NAME
    
    # Initialize design with MMMC configuration
    init_design
    
    # Generate and load OCV configuration
    reset_timing_derate
    source ./scripts/$TASK_NAME.ocv.tcl
    redirect ./reports/$TASK_NAME.derate.rpt {report_timing_derate}
    
    # Initialize tool environment
    `@tempus_post_init_design_project`
    `@tempus_post_init_design`

    # Read parasitics
    `@procs_tempus_read_data`
    gf_read_parasitics $SPEF_TASKS
    
    # Path groups for analysis
    if {[catch create_basic_path_groups]} {
        set registers [all_registers]
        group_path -name reg2reg -from $registers -to $registers
    }

    # Switch to propagated clocks mode
    if {$IGNORE_IO_TIMING == "Y"} {
        set_interactive_constraint_mode [get_db [get_db constraint_modes -if {.is_setup||.is_hold}] .name]
        reset_propagated_clock [get_clocks *] 
        set_propagated_clock [get_clocks *] 
        set_interactive_constraint_mode {}
    } else {
        update_io_latency
    }

    # Trace timing utility
    catch {
        source ../../../../../../gflow/bin/trace_timing.tcl
        proc gf_gui_trace_timing_highlight_selected {} {trace_timing -highlight -selected}
        gui_bind_key Shift+F8 -cmd "gf_gui_trace_timing_highlight_selected"
        puts "Use \[Shift+F8\] to trace timing through selected instance"
    }

    `@procs_tempus_reports`
    report_timing
'

# Run task
gf_submit_task
