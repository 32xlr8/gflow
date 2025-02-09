#!../../gflow/bin/gflow

################################################################################
# Generic Flow v5.5.1 (February 2025)
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
# Filename: templates/project.2025/blocks/template/calibre.nvn.gf
# Purpose:  Batch netlist versus netlist flow
################################################################################

########################################
# Main options
########################################

# Project and block initialization scripts
gf_source -once "../../project.common.gf"
gf_source -once "../../project.calibre.gf"
gf_source -once "./block.common.gf"
gf_source -once "./block.calibre.gf"

########################################
# Calibre NVN
########################################

gf_create_task -name NVN
gf_use_calibre_lvs

# LVS run directory
gf_choose_file_dir_task -variable LVS_TASK_DIR -keep -prompt "Choose LVS task to use:" -want -tasks '
    ../work_*/*/tasks/LVS*
'
LVS_TASK=

# Create rules file with substituted values
gf_check_files $CALIBRE_LVS_RULES
gf_add_tool_commands -comment '' -ext rul "$(cat $CALIBRE_LVS_RULES)"

# Data preparation
gf_add_shell_commands -init "
    cp ../$LVS_TASK_DIR/lay.net ./out/$TASK_NAME.layout.netlist
    cat ./scripts/$(basename "$LVS_TASK_DIR").runset ./scripts/$TASK_NAME.nvn.runset > ./scripts/$TASK_NAME.runset
"

# Expand runset
gf_add_tool_commands -ext nvn.runset "
    *lvsRunWhat: NVN
    *lvsSpiceFile: ./out/$TASK_NAME.layout.netlist
"

# Run task
gf_submit_task -silent
