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
# Filename: templates/project_template.2023/blocks/block_template/innovus.out.gf
# Purpose:  Write out physical data
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

########################################
# Innovus data out
########################################

# Write out reference data
gf_create_task -name DataOutPhysical
gf_use_innovus

# Select Innovus database to analyze from latest available if $DATABASE is empty
gf_spacer
gf_choose_file_dir_task -variable DATABASE -keep -prompt "Please select database or active task:" -dirs '
    ../work_*/*/out/Route*.innovus.db
    ../work_*/*/out/Assemble*.innovus.db
    ../work_*/*/out/ECO*.innovus.db
' -want -active -task_to_file '$RUN/out/$TASK.innovus.db' -tasks '
    ../work_*/*/tasks/Route*
    ../work_*/*/tasks/ECO*
    ../work_*/*/tasks/Assemble*
' 

gf_info "Innovus database \e[32m$DATABASE\e[0m selected"

# TCL commands
gf_add_tool_commands '

    # Current design variables
    set DATABASE {`$DATABASE`}

    # Read input Innovus database
    read_db -no_timing $DATABASE
    
    # Top level design name
    set DESIGN_NAME [get_db current_design .name]

    # Remember database
    exec rm -Rf ./out/$TASK_NAME/
    exec mkdir ./out/$TASK_NAME/
    exec ln -nsf $DATABASE ./out/$TASK_NAME/$DESIGN_NAME.innovus.db

    # Add empty cell macros to add to GDS
    read_physical -add_lefs ./scripts/$TASK_NAME.empty_cells.lef

    # Write out design files
    `@innovus_procs_write_data`
    `@innovus_physical_out_design`

    # Exit interactive session
    exit
'

# Create LEF for empty cells to be added to GDS
gf_add_tool_commands -ext empty_cells.lef '`@innovus_data_out_empty_cells_lef`'

# Shell commands to update MD5 sum
gf_add_shell_commands -post "
    md5sum ./out/$TASK_NAME/*.gds.gz > ./out/$TASK_NAME.gds.gz.md5sum
"


# Task summary
gf_add_status_marks ^Writing
gf_add_status_marks 'ERROR:' 'WARNING:' 'no such file' 'cannot access' ' not found '

# Run task
gf_submit_task

########################################
# Innovus timing data out
########################################

# Write out reference data
gf_create_task -name DataOutTiming
gf_use_innovus

# Select Innovus database to analyze from latest available if $DATABASE is empty
gf_spacer
gf_choose_file_dir_task -variable DATABASE -keep -prompt "Please select database or active task:" -dirs '
    ../work_*/*/out/Route*.innovus.db
    ../work_*/*/out/Assemble*.innovus.db
    ../work_*/*/out/ECO*.innovus.db
' -want -active -task_to_file '$RUN/out/$TASK.innovus.db' -tasks '
    ../work_*/*/tasks/Route*
    ../work_*/*/tasks/ECO*
    ../work_*/*/tasks/Assemble*
' 

gf_info "Innovus database \e[32m$DATABASE\e[0m selected"

# TCL commands
gf_add_tool_commands '

    # Current design variables
    set DATABASE {`$DATABASE`}

    # Read input Innovus database
    read_db $DATABASE
    
    # Top level design name
    set DESIGN_NAME [get_db current_design .name]

    # Remember database
    exec rm -Rf ./out/$TASK_NAME/
    exec mkdir ./out/$TASK_NAME/
    exec ln -nsf $DATABASE ./out/$TASK_NAME/$DESIGN_NAME.innovus.db

    # Write out design files
    `@innovus_procs_write_data`
    `@innovus_timing_out_design`

    # Exit interactive session
    exit
'

# Create LEF for empty cells to be added to GDS
gf_add_tool_commands -ext empty_cells.lef '`@innovus_data_out_empty_cells_lef`'

# Shell commands to update MD5 sum
gf_add_shell_commands -post "
    md5sum ./out/$TASK_NAME/*.gds.gz > ./out/$TASK_NAME.gds.gz.md5sum
"


# Task summary
gf_add_status_marks ^Writing
gf_add_status_marks 'ERROR:' 'WARNING:' 'no such file' 'cannot access' ' not found '

# Run task
gf_submit_task
