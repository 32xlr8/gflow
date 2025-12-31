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
# Filename: templates/project.2025/blocks/template/calibre.gui.gf
# Purpose:  Interactive physical verification debug flow
################################################################################

########################################
# Main options
########################################

# Project and block initialization scripts
gf_source -once "../../project.common.gf"
gf_source -once "../../project.calibre.gf"
gf_source -once "./block.common.gf"
gf_source -once "./block.calibre.gf"

# Basic flow script options
gf_set_flow_options -continue -incr -auto_close -hide

########################################
# Automatical GDS selection
########################################

# Select GDS file without dummy structures
gf_choose_file_dir_task -variable GDS_OUT_FILE -keep -prompt "Choose GDS to debug:" -files '
    ../work_*/*/out/*/*.gds.gz
    ../work_*/*/out/*.gds.gz
    ../data/*/*.gds.gz
    ../data/*.gds.gz
    ../data/*/*.gds
    ../data/*.gds
'
gf_spacer

########################################
# Calibre workbench interactive task
########################################

gf_create_task -name DebugCalibre

# Ask user if need to open DRC/LVS sults
gf_spacer
gf_choose -variable START_RVE -keys DLN -time 30 -default N -prompt "Start RVE (Drc/Lvs/No)?"
gf_spacer

# Shell commands to run
gf_set_task_command "bash run.bash"
gf_add_tool_commands -comment '#' -file "./tasks/$TASK_NAME/run.bash" '
    `@init_shell_environment`
    `@init_calibre_environment`

    # Dump environment variables
    env > ./reports/`$TASK_NAME`.env
'

# Load DRC results
if [ "$START_RVE" == "D" ]; then
    gf_spacer
    gf_choose_file_dir_task -variable RVE_RESULTS -keep -prompt "Choose DRC results:" -files '
        ../work_*/*/out/*.results
    '
    gf_spacer
    gf_add_tool_commands "
        # Run the tool
        calibrewb '$GDS_OUT_FILE' -rve -drc '$(dirname "$RVE_RESULTS")'/*.results
    "

# Load LVS results
elif [ "$START_RVE" == "L" ]; then
    gf_spacer
    gf_choose_file_dir_task -variable RVE_RESULTS -keep -prompt "Choose LVS results:" -dirs '
        ../work_*/*/out/*.svdb
    '
    gf_spacer
    gf_add_tool_commands "
        # Run the tool
        calibrewb '$GDS_OUT_FILE' -rve -lvs '$RVE_RESULTS' '$DESIGN_NAME'
    "

# Open GDS
else
    gf_add_tool_commands "
        # Run the tool
        calibrewb '$GDS_OUT_FILE'
    "
fi

# Run task
gf_submit_task -silent
