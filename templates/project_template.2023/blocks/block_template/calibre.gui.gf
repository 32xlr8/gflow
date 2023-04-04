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
# Filename: templates/project_template.2023/blocks/block_template/calibre.gui.gf
# Purpose:  Interactive physical verification debug flow
################################################################################

########################################
# Main options
########################################

# Project and block initialization scripts
gf_source "../../project.common.gf"
gf_source "../../project.calibre.gf"
gf_source "./block.common.gf"
gf_source "./block.files.gf"
gf_source "./block.calibre.gf"

# Basic flow script options
gf_set_flow_options -continue -incr -auto_close -hide

########################################
# Automatical GDS selection
########################################

# Choose available GDS
gf_choose_file_dir_task -variable GDS -keep -prompt "Choose GDS to load:" -files '
    ../work_*/*/out/*.gds.gz
'
gf_spacer

########################################
# Calibre workbench interactive task
########################################

gf_create_task -name DebugCalibre

# Ask user if need to open DRC/LVS results
gf_spacer
gf_choose -variable START_RVE -keys YN -time 30 -default N -prompt "Do you want to start RVE (Y/N)?"
gf_spacer

# Load GDS
if [ "$START_RVE" == "Y" ]; then
    RVE_OPTIONS=""

    for file in $(ls -1trd $(dirname "$GDS")/../*/*.svdb/ 2> /dev/null || :); do
        RVE_OPTIONS="$RVE_OPTIONS -rve -lvs '$file' '$DESIGN_NAME'"
    done

    for file in $(ls -1trd $(dirname "$GDS")/../*/{,*/}*.results 2> /dev/null || :); do
        RVE_OPTIONS="$RVE_OPTIONS -rve -drc '$file'"
    done

    gf_set_task_command "calibrewb '$GDS' $RVE_OPTIONS"
else
    gf_set_task_command "calibrewb '$GDS'"
fi

# Run task
gf_submit_task -silent
