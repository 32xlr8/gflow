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
# Filename: templates/project_template.2023/blocks/block_template/voltus.pgv.gf
# Purpose:  Batch PGV generation flow
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
# Tech only PGV generation
########################################

gf_create_task -name TechPGV
gf_use_voltus

# TCL commands
gf_add_tool_commands '

    # Current design variables
    set LEF_FILES {`$CADENCE_TLEF_FILES` `$LEF_FILES`}
    set POWER_VIEW [lindex {`$PGV_SPEF_CORNER`} 0]

    # Initialize Generic Config environment
    source ./scripts/$TASK_NAME.gconfig.tcl
    
    # Read physical data
    read_physical -lefs $LEF_FILES

    # Stage-specific options    
    `@voltus_pre_write_pgv_tech_only`
        
    # Write out library
    write_pg_library -out_dir ./out/$TASK_NAME.cl
    
    # Exit interactive session
    exit
'

# Separate Generic Config initialization script
gf_add_tool_commands -comment '#' -file ./scripts/$TASK_NAME.gconfig.tcl '
    `@init_gconfig`

    `@gconfig_technology_settings`
    `@gconfig_settings_common`

    `@gconfig_cadence_mmmc_files`
'

# Layer map file
gf_add_tool_commands -comment '' -ext lef.map '`@lef_def_map_file`'

# Run task
gf_add_success_marks 'Finished PGV Library Generator'
gf_submit_task

########################################
# Standard cell PGV generation
########################################

gf_create_task -name CellsPGV
gf_use_voltus

# TCL commands
gf_add_tool_commands '

    # Current design variables
    set LEF_FILES {`$CADENCE_TLEF_FILES` `$LEF_FILES`}
    set POWER_VIEW [lindex {`$POWER_VIEWS`} 0]
    set VOLTUS_PGV_FILLER_CELLS {`$VOLTUS_PGV_FILLER_CELLS`}
    set VOLTUS_PGV_DECAP_CELLS {`$VOLTUS_PGV_DECAP_CELLS`}

    # Initialize Generic Config environment
    source ./scripts/$TASK_NAME.gconfig.tcl
    
    # Read physical data
    read_physical -lefs [join $LEF_FILES]

    # Stage-specific options    
    `@voltus_pre_write_pgv_standard_cells`

    # Write out library
    write_pg_library -out_dir ./out/$TASK_NAME.cl
    
    # Exit interactive session
    exit
'

# Separate Generic Config initialization script
gf_add_tool_commands -comment '#' -file ./scripts/$TASK_NAME.gconfig.tcl '
    `@init_gconfig`

    `@gconfig_technology_settings`
    `@gconfig_settings_common`

    `@gconfig_cadence_mmmc_files`
'

# Cell list and DCAP cells files
gf_add_tool_commands -comment '' -ext cells '`@pgv_standard_cell_list_file`'
gf_add_tool_commands -comment '' -ext dcap '`@pgv_standard_cell_decap_file`'

# Run task
gf_add_success_marks 'Finished PGV Library Generator'
gf_submit_task

########################################
# Macros PGV generation
########################################

gf_create_task -name MacrosPGV
gf_use_voltus

# TCL commands
gf_add_tool_commands '

    # Current design variables
    set LEF_FILES {`$CADENCE_TLEF_FILES` `$LEF_FILES`}
    set GDS_FILES {`$GDS_FILES`}
    set POWER_VIEWS {`$POWER_VIEWS`}
    set SPICE_MODELS {`$VOLTUS_PGV_SPICE_MODELS`}
    set SPICE_CORNERS {`$VOLTUS_PGV_SPICE_CORNERS`}
    set SPICE_SCALING {`$VOLTUS_PGV_SPICE_SCALING`}
    set SPICE_FILES {`$VOLTUS_PGV_SPICE_FILES`}

    # Initialize Generic Config environment
    source ./scripts/$TASK_NAME.gconfig.tcl
    
    # Read physical data
    read_physical -lefs [join $LEF_FILES]

    # Stage-specific options    
    `@voltus_pre_write_pgv_macros`

    # Block-specific settings
    `@init_block_voltus_pgv_macros`

    # Write out library
    write_pg_library -out_dir ./out/$TASK_NAME.cl
    
    # Exit interactive session
    exit
'

# Separate Generic Config initialization script
gf_add_tool_commands -comment '#' -file ./scripts/$TASK_NAME.gconfig.tcl '
    `@init_gconfig`

    `@gconfig_technology_settings`
    `@gconfig_settings_common`

    `@gconfig_cadence_mmmc_files`
'

# Cell list file
gf_add_tool_commands -comment '' -ext cells '`@pgv_macro_list_file`'
gf_add_tool_commands -comment '' -ext connect.map '`@pgv_layer_connect_file`'


# Run task
gf_add_success_marks 'Finished PGV Library Generator'
gf_submit_task
