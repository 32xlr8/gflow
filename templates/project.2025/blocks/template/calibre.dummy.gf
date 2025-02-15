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
# Filename: templates/project.2025/blocks/template/calibre.dummy.gf
# Purpose:  Batch dummy fill flow
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
# Calibre dummy fill
########################################

gf_create_task -name Dummy
gf_use_calibre_env

# Select GDS file without dummy structures
gf_choose_file_dir_task -variable GDS_OUT_FILE -keep -prompt "Choose GDS to use:" -files '
    ../work_*/*/out/InnovusOut*/*.gds.gz
' -want -active -task_to_file '$RUN/out/$TASK/'$DESIGN_NAME'.gds.gz' -tasks '
    ../work_*/*/tasks/InnovusOut*
'

# # Option 1. Run using customized rules file
# gf_add_tool_commands "
#     
#     # Clean data
#     rm -f './out/$TASK_NAME.gds'  './out/$TASK_NAME.gds.gz'
#     
#     # Run the tool
#     calibre -drc -hier -turbo $GF_TASK_CPU ./scripts/$TASK_NAME.rul
#    
#     # GZIP result file
#     if [ -e './out/$TASK_NAME.gds' ]; then
#         rm -f './out/$TASK_NAME.gds.gz'
#         gzip './out/$TASK_NAME.gds'
#     fi
# "

# Option 2. Run using runset file
gf_add_tool_commands "
    # Clean data
    rm -f './out/$TASK_NAME.gds'  './out/$TASK_NAME.gds.gz'
    
    # Run the tool
    calibre -gui -drc -batch -runset ./scripts/$TASK_NAME.runset
    
    # GZIP result file
    if [ -e './out/$TASK_NAME.gds' ]; then
        rm -f './out/$TASK_NAME.gds.gz'
        gzip './out/$TASK_NAME.gds'
    fi
"

# Option 2: Runset customization
gf_add_tool_commands -comment '' -file "./scripts/$TASK_NAME.runset" '
    *drcRunDir: .
    *drcCellName: 0
    *drcStartRVE: 0
    *drcViewSummary: 0
    *drcSummaryFile: `$TASK_NAME`.sum
    *drcRulesFile: ./scripts/`$TASK_NAME`.rul
    *drcLayoutPaths: `$GDS_OUT_FILE`
    *drcLayoutPrimary: `$DESIGN_NAME`
    *drcResultsFile: ./out/`$TASK_NAME`.gds.gz
    *drcResultsFormat: GDSII
    *drcResultsCellSuffix: _dummy_fill
    *drcDRCMaxResultsAll: 1
    *cmnResolution: 5
    *cmnRunHyper: 1
    *cmnNumTurbo: `$GF_TASK_CPU`
    *cmnRunMT: 1
'

# Create rules file with substituted values
gf_check_files $CALIBRE_FILL_RULES
gf_add_tool_commands -comment '' -ext rul "$(cat $CALIBRE_FILL_RULES)"

# Check if task successfull
gf_add_success_marks 'DRC-H COMPLETED'
gf_add_status_marks 'TOTAL RESULTS' 'TOTAL RULECHECKS'

# Run task
gf_submit_task

########################################
# Calibre merge
########################################

# Describe task
gf_create_task -name Merge -mother Dummy
gf_use_calibre_env

# Run the tool
gf_add_tool_commands '
    calibredrv ./scripts/`$TASK_NAME`.tcl
'

# Select GDS file without dummy structures
gf_choose_file_dir_task -variable GDS_OUT_FILE -keep -prompt "Choose GDS to use:" -files '
    ../work_*/*/out/InnovusOut*/*.gds.gz
' -want -active -task_to_file '$RUN/out/$TASK/'$DESIGN_NAME'.gds.gz' -tasks '
    ../work_*/*/tasks/InnovusOut*
'

# Delete previous results
gf_add_shell_commands -init "
    mkdir -p ./out/$TASK_NAME/
    rm -f ./out/$TASK_NAME/$DESIGN_NAME.gds.gz ./out/$TASK_NAME/$DESIGN_NAME.gds.gz.md5sum
"

# Shell commands to initialize environment
gf_add_shell_commands -init "
    $INIT_ENV
    $INIT_CALIBRE
"

# Do merge
gf_add_tool_commands -comment '#' -ext tcl '
    set top [layout merge {'"$GDS_OUT_FILE"'} {'"./out/$MOTHER_TASK_NAME.gds.gz"'} 0 -mode rename -dt_expand]
    $top cellname '"$DESIGN_NAME"' '"$DESIGN_NAME"'_no_dummy_fill
    $top cellname TOP '"$DESIGN_NAME"'
    # $top delete cell TOP
    # $top create ref '"$DESIGN_NAME"' '"$DESIGN_NAME"'_dummy_fill 0 0 0 0 1.0
    $top gdsout {'"./out/$TASK_NAME/$DESIGN_NAME.gds.gz"'}
'

# Shell commands to update MD5 sum
gf_add_shell_commands -post "
    md5sum ./out/$TASK_NAME/$DESIGN_NAME.gds.gz > ./out/$TASK_NAME/$DESIGN_NAME.gds.gz.md5sum
"

# Start task
gf_submit_task
