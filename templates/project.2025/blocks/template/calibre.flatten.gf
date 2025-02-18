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
# Filename: templates/project.2025/blocks/template/calibre.flatten.gf
# Purpose:  Batch design flatten flow
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
# Calibre Flatten GDS
########################################

gf_create_task -name Flatten
gf_set_task_command "bash run.bash"
gf_add_tool_commands -comment '#' -file "./tasks/$TASK_NAME/run.bash" '
    `@init_shell_environment`
    `@init_calibre_environment`
    
    # Dump environment variables
    env > ./reports/`$TASK_NAME`.env

    # Run the tool
    calibredrv ./scripts/`$TASK_NAME`.tcl
'

# Select GDS file with dummy structures
gf_choose_file_dir_task -variable GDS_OUT_FILE -keep -prompt "Choose GDS to use:" -files '
    ../work_*/*/out/Merge*/*.gds.gz
' -want -active -task_to_file '$RUN/out/$TASK/'$DESIGN_NAME'.gds.gz' -tasks '
    ../work_*/*/tasks/Merge*
'

# Delete previous results
gf_add_shell_commands -init "
    mkdir -p ./out/$TASK_NAME/
    rm -f ./out/$TASK_NAME/$DESIGN_NAME.flat.gds.gz ./out/$TASK_NAME/$DESIGN_NAME.flat.gds.gz.md5sum
"

# Shell commands to initialize environment
gf_add_shell_commands -init "
    $INIT_ENV
    $INIT_CALIBRE
"

# Do merge
gf_add_tool_commands -comment '#' -ext tcl '
    set top [layout create {'"$GDS_OUT_FILE"'} -dt_expand -preservePaths -preserveTextAttributes]
    $top flatten cell [$top topcell]
    $top gdsout {'"./out/$TASK_NAME/$DESIGN_NAME.flat.gds.gz"'}
'

# Shell commands to update MD5 sum
gf_add_shell_commands -post "
    md5sum ./out/$TASK_NAME/$DESIGN_NAME.flat.gds.gz > ./out/$TASK_NAME/$DESIGN_NAME.flat.gds.gz.md5sum
"

# Start task
gf_submit_task

########################################
# Generic Flow history
########################################

gf_create_task -name HistoryFlatten -mother Flatten
gf_set_task_command "../../../../../../tools/print_flow_history.pl ../.. -html ./reports/$TASK_NAME.html"
gf_submit_task -silent
