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

# Choose configuration file
gf_choose_file_dir_task -variable VOLTUS_POWER_CONFIG_FILE -keep -prompt "Please select power configuration file:" -files '
    ../data/*.timing.tcl
    ../data/*/*.timing.tcl
    ../work_*/*/out/ConfigSignoff*.power.tcl
'
gf_info "Power config file \e[32m$VOLTUS_POWER_CONFIG_FILE\e[0m selected"

# TCL commands
gf_add_tool_commands '

    # Current design variables
    set LEF_FILES {`$CADENCE_TLEF_FILES` `$LEF_FILES`}
    set POWER_CONFIG_FILE {`$VOLTUS_POWER_CONFIG_FILE`}

    # Load configuration variables
    source $POWER_CONFIG_FILE

    # Read physical data
    read_physical -lefs $LEF_FILES

    # Design variables
    `@voltus_post_init_variables`

    # Stage-specific options    
    `@voltus_pre_write_pgv_tech_only`

    # Print info
    puts "QRC file: {$PGV_RC_CORNER_TEMPERATURE $PGV_RC_CORNER_QRC_FILE}"
        
    # Write out library
    write_pg_library -out_dir ./out/$TASK_NAME
    
    # Exit interactive session
    exit
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

# Choose configuration file
gf_choose_file_dir_task -variable VOLTUS_POWER_CONFIG_FILE -keep -prompt "Please select power configuration file:" -files '
    ../data/*.timing.tcl
    ../data/*/*.timing.tcl
    ../work_*/*/out/ConfigSignoff*.power.tcl
'
gf_info "Power config file \e[32m$VOLTUS_POWER_CONFIG_FILE\e[0m selected"

# TCL commands
gf_add_tool_commands '

    # Current design variables
    set LEF_FILES {`$CADENCE_TLEF_FILES` `$LEF_FILES`}
    set POWER_CONFIG_FILE {`$VOLTUS_POWER_CONFIG_FILE`}

    # Load configuration variables
    source $POWER_CONFIG_FILE

    # Read physical data
    read_physical -lefs [join $LEF_FILES]

    # Design variables
    `@voltus_post_init_variables`

    # Stage-specific options    
    `@voltus_pre_write_pgv_standard_cells`

    # Print info
    puts "QRC file: {$PGV_RC_CORNER_TEMPERATURE $PGV_RC_CORNER_QRC_FILE}"

    # Write out library
    write_pg_library -out_dir ./out/$TASK_NAME
    
    # Exit interactive session
    exit
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

# Choose configuration file
gf_choose_file_dir_task -variable VOLTUS_POWER_CONFIG_FILE -keep -prompt "Please select power configuration file:" -files '
    ../data/*.timing.tcl
    ../data/*/*.timing.tcl
    ../work_*/*/out/ConfigSignoff*.power.tcl
'
gf_info "Power config file \e[32m$VOLTUS_POWER_CONFIG_FILE\e[0m selected"

# TCL commands
gf_add_tool_commands '

    # Current design variables
    set LEF_FILES {`$CADENCE_TLEF_FILES` `$LEF_FILES`}
    set GDS_FILES {`$GDS_FILES`}
    set SPICE_MODELS {`$VOLTUS_PGV_SPICE_MODELS`}
    set SPICE_CORNERS {`$VOLTUS_PGV_SPICE_CORNERS`}
    set SPICE_SCALING {`$VOLTUS_PGV_SPICE_SCALING`}
    set SPICE_FILES {`$VOLTUS_PGV_SPICE_FILES`}
    set POWER_CONFIG_FILE {`$VOLTUS_POWER_CONFIG_FILE`}

    # Load configuration variables
    source $POWER_CONFIG_FILE

    # Read physical data
    read_physical -lefs [join $LEF_FILES]

    # Design variables
    `@voltus_post_init_variables`

    # Stage-specific options    
    `@voltus_pre_write_pgv_macros`

    # Block-specific settings
    `@init_block_voltus_pgv_macros`

    # Print info
    puts "QRC file: {$PGV_RC_CORNER_TEMPERATURE $PGV_RC_CORNER_QRC_FILE}"

    # Write out library
    write_pg_library -out_dir ./out/$TASK_NAME
    
    # Exit interactive session
    exit
'

# Additional files
gf_add_tool_commands -comment '' -file ./in/$TASK_NAME.lef.map '`@voltus_pgv_lef_def_map_file`'
gf_add_tool_commands -comment '#' -file ./in/$TASK_NAME.libgen.cmd '`@voltus_pgv_command_file`'
gf_add_tool_commands -comment '#' -file ./in/$TASK_NAME.extract.cmd '`@voltus_pgv_extraction_command_file`'
gf_add_tool_commands -comment '' -file ./in/$TASK_NAME.connect.map '`@voltus_pgv_layer_connect_file`'

# Run task
gf_add_failed_marks 'Library generation failed'
gf_add_success_marks 'Finished PGV Library Generator'
gf_submit_task
