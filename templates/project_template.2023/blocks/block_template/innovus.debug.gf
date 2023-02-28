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
# Filename: templates/project_template.2023/blocks/block_template/innovus.debug.gf
# Purpose:  Interactive implementation debug flow
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

# Basic flow script options
gf_set_flow_options -continue -incr -auto_close -hide

########################################
# Automatical database selection
########################################

# Choose available Innovus database
gf_choose_file_dir_task -variable DATABASE -keep -prompt "Please select database to load:" -dirs '
    ../work_*/*/out/*.innovus.db
    ../work_*/*/out/*.ispatial.db
'
gf_spacer

########################################
# Innovus interactive task
########################################

gf_create_task -name DebugInnovus
gf_use_innovus

# Ask user if need to load timing information
gf_spacer
gf_choose -variable TIMING_MODE -keys YN -time 30 -default Y -prompt "Do you want to read timing information (Y/N)?"
gf_spacer

# Load database
gf_add_tool_commands '

    # Current design variables
    set DATABASE {`$DATABASE`}
    set TIMING_MODE {`$TIMING_MODE`}

    # Pre-load settings
    `@innovus_pre_read_libs`

    # Read latest available database
    if {$TIMING_MODE == "Y"} {
        read_db $DATABASE
    } else {
        read_db -no_timing $DATABASE
    }

    # Top level design name
    set DESIGN_NAME [get_db current_design .name]
    
    # Common tool procedures
    `@innovus_procs_common`
    `@innovus_procs_interactive_design`
    `@innovus_procs_eco_design`

    # Load trace timing utility
    if {$TIMING_MODE == "Y"} {
        source ../../../../../../gflow/bin/trace_timing.tcl
        proc gf_gui_trace_timing_highlight_selected {} {trace_timing -highlight -selected}
        catch {gui_bind_key Shift+F8 -cmd "gf_gui_trace_timing_highlight_selected"}
    }

    set_layer_preference phyCell -color #555555
    gui_show
'

# Run task
gf_submit_task
