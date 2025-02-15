#!../../gflow/bin/gflow

################################################################################
# Generic Flow v5.5.2 (February 2025)
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
# Filename: templates/project.2025/blocks/template/innovus.gui.gf
# Purpose:  Interactive implementation debug flow
################################################################################

########################################
# Main options
########################################

# Project and block initialization scripts
gf_source -once "../../project.common.gf"
gf_source -once "../../project.innovus.gf"
gf_source -once "./block.common.gf"
gf_source -once "./block.innovus.gf"

# Basic flow script options
gf_set_flow_options -continue -incr -auto_close -hide

########################################
# Automatical database selection
########################################

# Innovus design database
gf_choose_file_dir_task -variable INNOVUS_DATABASE -prompt "Choose database to load:" -dirs '
    '"$INNOVUS_DATABASE"'
    ../work_*/*/out/*.ispatial.db
    ../work_*/*/out/*.innovus.db
    ../work_*/*/out/*/*.innovus.db
'
gf_spacer

########################################
# Innovus interactive task
########################################

gf_create_task -name DebugInnovus
gf_use_innovus

# Ask user if need to load timing information
gf_spacer
gf_choose -variable TIMING_MODE -keys YN -time 30 -default Y -prompt "Read timing information (Y/N)?"
gf_spacer

# Load database
gf_add_tool_commands '

    # Current design variables
    set INNOVUS_DATABASE {`$INNOVUS_DATABASE`}
    set TIMING_MODE {`$TIMING_MODE`}

    # Pre-load settings
    `@innovus_pre_read_libs`

    # Read latest available database
    if {$TIMING_MODE == "Y"} {
        read_db $INNOVUS_DATABASE
    } else {
        read_db -no_timing $INNOVUS_DATABASE
    }
    puts "Database: $INNOVUS_DATABASE"

    # Top level design name
    set DESIGN_NAME [get_db current_design .name]
    
    # Load common tool procedures
    source ./scripts/$TASK_NAME.procs.tcl

    # Trace timing utility
    if {$TIMING_MODE == "Y"} {
        catch {
            source ../../../../../../gflow/bin/trace_timing.tcl
            proc gf_gui_trace_timing_highlight_selected {} {trace_timing -highlight -selected}
            gui_bind_key Shift+F8 -cmd "gf_gui_trace_timing_highlight_selected"
            puts "Use \[Shift+F8\] to trace timing through selected instance"
        }
    }

    # GUI commands
    `@innovus_pre_gui -optional`
    
    gui_show
'

# Common tool procedures
gf_add_tool_commands -comment '#' -file ./scripts/$TASK_NAME.procs.tcl '
    `@innovus_procs_common`
    `@innovus_procs_interactive_design`
    `@innovus_procs_eco_design`
'

# Run task
gf_submit_task
