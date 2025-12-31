#!../../gflow/bin/gflow

################################################################################
# Generic Flow v5.5.4 (December 2025)
################################################################################
#
# Copyright 2011-2025 Gennady Kirpichev
#
#    https://github.com/32xlr8/gflow.git
#    https://gitflic.ru/project/32xlr8/gflow
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
# Filename: templates/project.2025/blocks/template/innovus.out.gf
# Purpose:  Write out physical data
################################################################################

########################################
# Main options
########################################

# Project and block initialization scripts
gf_source -once "../../project.common.gf"
gf_source -once "../../project.innovus.gf"
gf_source -once "./block.common.gf"
gf_source -once "./block.innovus.gf"

########################################
# Innovus data out
########################################

# Write out reference data
gf_create_task -name InnovusOut
gf_use_innovus

# Innovus design database
gf_spacer
gf_choose_file_dir_task -variable INNOVUS_DATABASE -keep -prompt "Choose database or active task:" -dirs '
    ../work_*/*/out/Route*.innovus.db
    ../work_*/*/out/Assemble*.innovus.db
    ../work_*/*/out/ECO*.innovus.db
' -want -active -task_to_file '$RUN/out/$TASK.innovus.db' -tasks '
    ../work_*/*/tasks/Route*
    ../work_*/*/tasks/ECO*
    ../work_*/*/tasks/Assemble*
' 

# TCL commands
gf_add_tool_commands '

    # Current design variables
    set INNOVUS_DATABASE {`$INNOVUS_DATABASE`}

    # Read input Innovus database
    read_db -no_timing $INNOVUS_DATABASE
    puts "Database: $INNOVUS_DATABASE"
    
    # Top level design name
    set DESIGN_NAME [get_db current_design .name]

    # Remember database
    exec rm -Rf ./out/$TASK_NAME/
    exec mkdir ./out/$TASK_NAME/
    exec ln -nsf $INNOVUS_DATABASE ./out/$TASK_NAME/$DESIGN_NAME.innovus.db

    # Add empty cell macros to add to GDS
    read_physical -add_lefs ./in/$TASK_NAME.empty_cells.lef

    # Write out design files
    `@innovus_procs_write_data`
    `@innovus_data_out`

    # Exit interactive session
    exit
'

# Create LEF for empty cells to be added to GDS
gf_add_tool_commands -file ./in/$TASK_NAME.empty_cells.lef '`@innovus_data_out_empty_cells_lef`'

# Shell commands to update MD5 sum
gf_add_shell_commands -post "
    md5sum ./out/$TASK_NAME/*.gds.gz > ./out/$TASK_NAME.gds.gz.md5sum
"

# Task summary
gf_add_status_marks ^Writing
gf_add_status_marks 'ERROR:' 'WARNING:' 'no such file' 'cannot access' ' not found ' 'Master cell:'

# Run task
gf_submit_task

########################################
# Generic Flow history
########################################

gf_create_task -name HistoryInnovusOut -mother InnovusOut
gf_set_task_command "../../../../../../tools/print_flow_history.pl ../.. -html ./reports/$TASK_NAME.html"
gf_submit_task -silent
