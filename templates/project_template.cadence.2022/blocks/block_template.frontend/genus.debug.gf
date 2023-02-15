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
# Filename: templates/project_template.cadence.2022/blocks/block_template.frontend/genus.debug.gf
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

# General flow script options
gf_set_flow_options -hide -auto_close

########################################
# Automatical database selection
########################################

# Choose available Genus database
gf_choose_file_dir_task -variable DATABASE -keep -prompt "Please select database to load:" -files "
    ../work_*/*/out/*.genus.db
"
gf_spacer

########################################
# Genus interactive task
########################################

gf_create_task -name DebugGenus
gf_use_genus

# Load database
gf_add_tool_commands '
    
    # Read latest available database
    set DATABASE {`$DATABASE`}
    read_db $DATABASE

    # Top level design name
    set DESIGN_NAME [get_db current_design .name]
    
    # Initialize Generic Config environment
    source ./scripts/$TASK_NAME.gconfig.tcl
    
    # Load trace timing utility
    source ../../../../../../gflow/bin/trace_timing.tcl
    
    gui_show
'

# Separate Generic Config initialization script
gf_add_tool_commands -comment '#' -file ./scripts/$TASK_NAME.gconfig.tcl '
    `@init_gconfig`
    `@gconfig_technology_settings`
    `@gconfig_design_settings`

    `@gconfig_cadence_mmmc_files`

'

# Run task
gf_submit_task
