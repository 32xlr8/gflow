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
# Filename: templates/project.2025/blocks/template/voltus.pgv.gf
# Purpose:  Batch PGV generation flow
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
# Tech only PGV generation
########################################

gf_create_task -name TechPGV
gf_use_voltus

# TCL commands
gf_add_tool_commands '

    # Current design variables
    set LEF_FILES {`$CADENCE_TLEF_FILES` `$LEF_FILES` `$PARTITIONS_LEF_FILES -optional`}

    # Use separate Generic Config script
    source ./scripts/$TASK_NAME.gconfig.tcl

    # Design variables
    `@voltus_pre_init_design_variables`

    # Read physical data
    read_physical -lefs $LEF_FILES

    # Design variables
    `@voltus_post_init_design_variables`

    # Stage-specific options    
    `@voltus_pre_write_pgv_tech_only`

    # Print info
    puts "RC corner: {$PGV_RC_CORNER}"
        
    # Write out library
    write_pg_library -out_dir ./out/$TASK_NAME
    
    # Exit interactive session
    exit
'

# Generic Config MMMC generation
gf_use_gconfig
gf_add_tool_commands '
    `@gconfig_project_settings`
    `@gconfig_settings_common`
    `@gconfig_cadence_mmmc_files`
    `@voltus_gconfig_power_rail_design_settings`
'

# Layer map file
gf_add_tool_commands -comment '' -file ./in/$TASK_NAME.lef.map '`@voltus_pgv_lef_def_map_file`'
gf_add_tool_commands -comment '#' -file ./in/$TASK_NAME.libgen.cmd '`@voltus_pgv_command_file`'
gf_add_tool_commands -comment '#' -file ./in/$TASK_NAME.extract.cmd '`@voltus_pgv_extraction_command_file`'

# Run task
gf_add_failed_marks 'Library generation failed'
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
    set LEF_FILES {`$CADENCE_TLEF_FILES` `$LEF_FILES` `$PARTITIONS_LEF_FILES -optional`}

    # Use separate Generic Config script
    source ./scripts/$TASK_NAME.gconfig.tcl

    # Design variables
    `@voltus_pre_init_design_variables`

    # Read physical data
    read_physical -lefs [join $LEF_FILES]

    # Design variables
    `@voltus_post_init_design_variables`

    # Stage-specific options    
    `@voltus_pre_write_pgv_standard_cells`

    # Print info
    puts "RC corner: {$PGV_RC_CORNER}"

    # Write out library
    write_pg_library -out_dir ./out/$TASK_NAME
    
    # Exit interactive session
    exit
'

# Generic Config MMMC generation
gf_use_gconfig
gf_add_tool_commands '
    `@gconfig_project_settings`
    `@gconfig_settings_common`
    `@gconfig_cadence_mmmc_files`
    `@voltus_gconfig_power_rail_design_settings`
'

# Additional files
gf_add_tool_commands -comment '' -file ./in/$TASK_NAME.lef.map '`@voltus_pgv_lef_def_map_file`'
gf_add_tool_commands -comment '#' -file ./in/$TASK_NAME.libgen.cmd '`@voltus_pgv_command_file`'
gf_add_tool_commands -comment '#' -file ./in/$TASK_NAME.extract.cmd '`@voltus_pgv_extraction_command_file`'

# Run task
gf_add_failed_marks 'Library generation failed'
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
    set LEF_FILES {`$CADENCE_TLEF_FILES` `$LEF_FILES` `$PARTITIONS_LEF_FILES -optional`}

    # Use separate Generic Config script
    source ./scripts/$TASK_NAME.gconfig.tcl

    # Design variables
    `@voltus_pre_init_design_variables`

    # Read physical data
    read_physical -lefs [join $LEF_FILES]

    # Design variables
    `@voltus_post_init_design_variables`

    # Stage-specific options    
    `@voltus_pre_write_pgv_macros`

    # Block-specific settings
    `@init_block_voltus_pgv_macros`

    # Print info
    puts "RC corner: {$PGV_RC_CORNER}"

    # Write out library
    write_pg_library -out_dir ./out/$TASK_NAME
    
    # Exit interactive session
    exit
'

# Generic Config MMMC generation
gf_use_gconfig
gf_add_tool_commands '
    `@gconfig_project_settings`
    `@gconfig_settings_common`
    `@gconfig_cadence_mmmc_files`
    `@voltus_gconfig_power_rail_design_settings`
'

# Additional files
gf_add_tool_commands -comment '' -file ./in/$TASK_NAME.lef.map '`@voltus_pgv_lef_def_map_file`'
gf_add_tool_commands -comment '#' -file ./in/$TASK_NAME.libgen.cmd '`@voltus_pgv_command_file`'
gf_add_tool_commands -comment '#' -file ./in/$TASK_NAME.extract.cmd '`@voltus_pgv_extraction_command_file`'
gf_add_tool_commands -comment '' -file ./in/$TASK_NAME.connect.map '`@voltus_pgv_lef_gds_map_file`'

# Run task
gf_add_failed_marks 'Library generation failed'
gf_add_success_marks 'Finished PGV Library Generator'
gf_submit_task
