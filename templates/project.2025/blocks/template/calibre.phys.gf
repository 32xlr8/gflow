#!../../gflow/bin/gflow

################################################################################
# Generic Flow v5.1 (May 2023)
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
# Filename: templates/project_template.2023/blocks/block_template/calibre.phys.gf
# Purpose:  Batch physical verification flow
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
# Calibre Fill
########################################

gf_create_task -name Fill
gf_use_calibre_drc_batch

# Select Innovus database to analyze from latest available if $INNOVUS_DATABASE is empty
gf_spacer
gf_choose_file_dir_task -variable DATA_OUT_TASK -keep -prompt "Choose data out task:" -want -tasks '
    ../work_*/*/tasks/DataOutPhysical*
' 

gf_add_shell_commands -init "
    rm -f ./out/$TASK_NAME.gds
"

# Create runset
gf_save_files $CALIBRE_FILL_RULES -copy
    # *drcConfigureDFMDefaults: 1
    # *drcDFMDefaultsResultsFile: ./out/$TASK_NAME.gds
    # *drcDFMDefaultsResultsCellSuffix: _dummy_fill
gf_add_tool_commands -ext runset "
    *drcRulesFile: ./in/$(basename "$CALIBRE_FILL_RULES")
    *drcLayoutPaths: $DATA_OUT_TASK/out/$(basename "$DATA_OUT_TASK").gds.gz
    *drcLayoutPrimary: $DESIGN_NAME
    *drcResultsFile: ./out/$TASK_NAME.gds
    *drcResultsFormat: GDSII
    *drcResultsCellSuffix: _dummy_fill
    *drcDRCMaxResultsAll: 1
    *cmnResolution: 5
    *cmnRunHyper: 1
"

# Check if task successfull
gf_add_success_marks 'DRC-H COMPLETED'
gf_add_status_marks 'TOTAL RESULTS'

# Run task
gf_submit_task

########################################
# Calibre DRC
########################################

gf_create_task -name DRC -parallel $DRC_PARALLEL_TASKS -group DRC -mother $STREAM_OUT_TASK
gf_use_calibre_drc_batch

# Create runset
gf_save_files $CALIBRE_DRC_RULES -copy
gf_add_tool_commands -ext runset "
    *drcRulesFile: ./in/$(basename "$CALIBRE_DRC_RULES")
    *drcLayoutPaths: $DATA_OUT_TASK/out/$(basename "$DATA_OUT_TASK").gds.gz
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

gf_create_task -name Antenna -group DRC -mother $STREAM_OUT_TASK
gf_use_calibre_drc_batch

# Create runset
gf_save_files $CALIBRE_ANT_RULES -copy
gf_add_tool_commands -ext runset "
    *drcRulesFile: ./in/$(basename "$CALIBRE_ANT_RULES")
    *drcLayoutPaths: $DATA_OUT_TASK/out/$(basename "$DATA_OUT_TASK").gds.gz
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

gf_create_task -name Bumps -group DRC -mother $STREAM_OUT_TASK
gf_use_calibre_drc_batch

# Create runset
gf_save_files $CALIBRE_BUMP_RULES -copy
gf_add_tool_commands -ext runset "
    *drcRulesFile: ./in/$(basename "$CALIBRE_BUMP_RULES")
    *drcLayoutPaths: $DATA_OUT_TASK/out/$(basename "$DATA_OUT_TASK").gds.gz
    *drcLayoutPrimary: $DESIGN_NAME
    *drcResultsFile: ./out/$TASK_NAME.results
    *drcDRCMaxResultsAll: 1
    *cmnResolution: 5
"

# Run task
gf_submit_task

########################################
# Calibre LVS
########################################

gf_create_task -name LVS -mother $STREAM_OUT_TASK
gf_use_calibre_lvs_batch

gf_add_shell_commands -init "

    # Filter out commented port labels
    exec sed -e '\`$MAP_PORT_NAMES_SED_SCRIPT\`' '$DATA_OUT_TASK/out/$(basename "$DATA_OUT_TASK").pins' > ./out/$TASK_NAME.pins
    sed -ie 's/^\s*#.*$//' ./scripts/$TASK_NAME.user.pins
    
    # Convert verilog to spice
    v2lvs -v '$DATA_OUT_TASK/out/$(basename "$DATA_OUT_TASK").v.gz' -o ./out/$TASK_NAME.sp -w 2
"

# Empty CDL for hierarchical database
gf_add_tool_commands -ext empty.sp '
    `@innovus_data_out_empty_cells_spice`
'

# Default HCELL file
[[ -z "$HCELL_FILE" ]] && HCELL_FILE="$DATA_OUT_TASK/out/$(basename "$DATA_OUT_TASK").hcell"

# Create runset
gf_save_files $CALIBRE_LVS_RULES -copy
gf_add_tool_commands -ext runset "
    *lvsRulesFile: ./in/$(basename "$CALIBRE_LVS_RULES")
    *lvsIncludeFiles: ./out/$TASK_NAME.pins ./scripts/$TASK_NAME.user.pins
    *lvsLayoutPaths: $DATA_OUT_TASK/out/$(basename "$DATA_OUT_TASK").gds.gz
    *lvsLayoutPrimary: $DESIGN_NAME
    *lvsSourcePath: `$CDL_FILES` ./scripts/$TASK_NAME.empty.sp ./out/$TASK_NAME.sp) 
    *lvsSourcePrimary: $DESIGN_NAME
    *lvsUseHCells: 1
    *lvsHCellsFile: $HCELL_FILE
    *lvsDeviceFilterOptionsEnabled: 0
    *lvsLayoutDeviceFilterOptions: AB AE F G RC RE RG Q AC AD AF AH AG H I RB
    *lvsSourceDeviceFilterOptions: AB AE F G RC RE RG Q AC AD AF AH AG H I RB
    *lvsIgnorePorts: 1
    *lvsPowerNames: $(echo $POWER_NETS_CORE $POWER_NETS_OTHER)
    *lvsGroundNames: $(echo $GROUND_NETS_OTHER $GROUND_NETS_OTHER)
    *lvsRecognizeGates: NONE
    *lvsRecognizeGatesMixSubtypes: 1
    *lvsReduceSplitGates: 0
    *lvsRunERC: 1
    *lvsIsolateShorts: 1
    *lvsReportOptions: A B C D
    *lvsReportMaximumAll: 0
    *lvsReportMaximumCount: 1000
    *lvsAbortOnSupplyError: 0
    *cmnRunHyper: 1
    *cmnVConnectColon: 0
    *cmnVConnectReport: 1
    *cmnVConnectReportUnSatisfied: 1
    *cmnShowOptions: 1
"

# Virtual net connection
if [ -n "$LVS_VIRTUAL_NET_CONNECT" ]; then
    gf_add_tool_commands -ext runset "
        *lvsSVRFCmds: {LVS SPICE OVERRIDE GLOBALS YES} {VIRTUAL CONNECT NAME$(for net in $LVS_VIRTUAL_NET_CONNECT; do echo -n " \"$net\""; done)} {VIRTUAL CONNECT REPORT YES} {LVS REPORT OPTION S}
        *cmnVConnectNamesState: SOME
        *cmnVConnectNames:$(for net in $LVS_VIRTUAL_NET_CONNECT; do echo -n " \"$net\""; done)
    "
fi

# Include user pin labels
gf_add_tool_commands -ext user.pins '`@lvs_user_port_labels`'

# Display ERC and LVS results
gf_add_shell_commands -post "cat *.sum* ./reports/$TASK_NAME.report"
gf_add_status_mark '^RULECHECK .* = [1-9]' '^\s*Error:'

# Run task
gf_submit_task

########################################
# Calibre NVN
########################################

gf_create_task -name NVN
gf_use_calibre_lvs

gf_disable_task NVN

gf_wait_task -wait LVS -variable LVS_TASK

gf_add_shell_commands -init "
    cp ../$LVS_TASK/lay.net ./out/$TASK_NAME.layout.netlist
    cat ./scripts/$LVS_TASK.runset ./scripts/$TASK_NAME.nvn.runset > ./scripts/$TASK_NAME.runset
"

# Expand runset
gf_save_files $CALIBRE_LVS_RULES -copy
gf_add_tool_commands -ext nvn.runset "
    *lvsRunWhat: NVN
    *lvsSpiceFile: ./out/$TASK_NAME.layout.netlist
"

# Run task
gf_submit_task -silent
