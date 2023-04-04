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
# Filename: templates/project_template.2023/blocks/block_template/genus.gui.gf
# Purpose:  Interactive synthesis debug flow
################################################################################

########################################
# Main options
########################################

# Project and block initialization scripts
gf_source "../../project.common.gf"
gf_source "../../project.genus.gf"
gf_source "./block.common.gf"
gf_source "./block.files.gf"
gf_source "./block.genus.gf"

# Basic flow script options
gf_set_flow_options -continue -incr -auto_close -hide

########################################
# Automatical database selection
########################################

# Choose available Genus database
gf_choose_file_dir_task -variable GENUS_DATABASE -keep -prompt "Choose database to load:" -files '
    ../work_*/*/out/*.genus.db
'
gf_spacer

########################################
# Genus interactive task
########################################

gf_create_task -name DebugGenus
gf_use_genus

# Load database
gf_add_tool_commands '
    
    # Read latest available database
    set GENUS_DATABASE {`$GENUS_DATABASE`}
    read_db $GENUS_DATABASE

    # Top level design name
    set DESIGN_NAME [get_db current_design .name]
    
    # Trace timing utility
    catch {
        source ../../../../../../gflow/bin/trace_timing.tcl
        proc gf_gui_trace_timing_highlight_selected {} {trace_timing -highlight -selected}
        gui_bind_key Shift+F8 -cmd "gf_gui_trace_timing_highlight_selected"
        puts "Use \[Shift+F8\] to trace timing through selected instance"
    }

    gui_show
'

# Run task
gf_submit_task
