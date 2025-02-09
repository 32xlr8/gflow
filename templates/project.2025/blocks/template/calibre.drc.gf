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
# Filename: templates/project.2025/blocks/template/calibre.drc.gf
# Purpose:  Batch design rules check flow
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
# Calibre DRC
########################################

gf_create_task -name DRC
gf_use_calibre_drc_batch

# Select GDS file without dummy structures
gf_choose_file_dir_task -variable GDS_OUT_FILE -keep -prompt "Choose GDS to use:" -files '
    ../work_*/*/out/InnovusOut*/*.gds.gz
    ../work_*/*/out/Merge*/*.gds.gz
' -want -active -task_to_file '$RUN/out/$TASK/'$DESIGN_NAME'.gds.gz' -tasks '
    ../work_*/*/tasks/InnovusOut*
    ../work_*/*/tasks/Merge*
'

# Create rules file with substituted values
gf_check_files $CALIBRE_DRC_RULES
gf_add_tool_commands -comment '' -ext rul "$(cat $CALIBRE_DRC_RULES)"

# Fix relative paths in reports
gf_add_shell_commands -post "
    sed -ie 's|\\(\\S\\+\\.density\\)\$|../tasks/$TASK_NAME/\1|' ./out/$TASK_NAME.results
"

# Create runset
gf_add_tool_commands -ext runset "
    *drcRulesFile: ./scripts/$TASK_NAME.rul
    *drcLayoutPaths: $GDS_OUT_FILE
    *drcLayoutPrimary: $DESIGN_NAME
    *drcResultsFile: ./out/$TASK_NAME.results
    *drcDRCMaxResultsAll: 1
    *cmnResolution: 5
    *cmnRunHyper: 1
"

# Run task
gf_submit_task

########################################
# Calibre Antenna
########################################

gf_create_task -name Antenna
gf_use_calibre_drc_batch

# Select GDS file without dummy structures
gf_choose_file_dir_task -variable GDS_OUT_FILE -keep -prompt "Choose GDS to use:" -files '
    ../work_*/*/out/InnovusOut*/*.gds.gz
    ../work_*/*/out/Merge*/*.gds.gz
' -want -active -task_to_file '$RUN/out/$TASK/'$DESIGN_NAME'.gds.gz' -tasks '
    ../work_*/*/tasks/InnovusOut*
    ../work_*/*/tasks/Merge*
'

# Create rules file with substituted values
gf_check_files $CALIBRE_ANT_RULES
gf_add_tool_commands -comment '' -ext rul "$(cat $CALIBRE_ANT_RULES)"

# Fix relative paths in reports
gf_add_shell_commands -post "
    sed -ie 's|\\(\\S\\+\\.density\\)\$|../tasks/$TASK_NAME/\1|' ./out/$TASK_NAME.results
"

# Create runset
gf_add_tool_commands -ext runset "
    *drcRulesFile: ./scripts/$TASK_NAME.rul
    *drcLayoutPaths: $GDS_OUT_FILE
    *drcLayoutPrimary: $DESIGN_NAME
    *drcResultsFile: ./out/$TASK_NAME.results
    *drcDRCMaxResultsAll: 1
    *cmnResolution: 5
"

# Run task
gf_submit_task

########################################
# Calibre bumps check
########################################

gf_create_task -name Bumps
gf_use_calibre_drc_batch

# Select GDS file without dummy structures
gf_choose_file_dir_task -variable GDS_OUT_FILE -keep -prompt "Choose GDS to use:" -files '
    ../work_*/*/out/InnovusOut*/*.gds.gz
    ../work_*/*/out/Merge*/*.gds.gz
' -want -active -task_to_file '$RUN/out/$TASK/'$DESIGN_NAME'.gds.gz' -tasks '
    ../work_*/*/tasks/InnovusOut*
    ../work_*/*/tasks/Merge*
'

# Create rules file with substituted values
gf_check_files $CALIBRE_BUMP_RULES
gf_add_tool_commands -comment '' -ext rul "$(cat $CALIBRE_BUMP_RULES)"

# Fix relative paths in reports
gf_add_shell_commands -post "
    sed -ie 's|\\(\\S\\+\\.density\\)\$|../tasks/$TASK_NAME/\1|' ./out/$TASK_NAME.results
"

# Create runset
gf_add_tool_commands -ext runset "
    *drcRulesFile: ./scripts/$TASK_NAME.rul
    *drcLayoutPaths: $GDS_OUT_FILE
    *drcLayoutPrimary: $DESIGN_NAME
    *drcResultsFile: ./out/$TASK_NAME.results
    *drcDRCMaxResultsAll: 1
    *cmnResolution: 5
"

# Run task
gf_submit_task
