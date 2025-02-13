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
# Filename: templates/project.2025/blocks/template/calibre.lvs.gf
# Purpose:  Batch layout versus schematic flow
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
# Calibre LVS
########################################

gf_create_task -name LVS

# Design data directory
gf_choose_file_dir_task -variable DATA_OUT_DIR -keep -prompt "Choose design data directory:" -dirs '
    ../work_*/*/out/InnovusOut*
' -want -active -task_to_file '$RUN/out/$TASK' -tasks '
    ../work_*/*/tasks/InnovusOut*
'

# GDS file
gf_choose_file_dir_task -variable GDS_OUT_FILE -keep -prompt "Choose GDS file:" -files '
    ../work_*/*/out/InnovusOut*/*.gds.gz
    ../work_*/*/out/Merge*/*.gds.gz
' -want -active -task_to_file '$RUN/out/$TASK/'"$DESIGN_NAME.gds.gz" -tasks '
    ../work_*/*/tasks/InnovusOut*
    ../work_*/*/tasks/Merge*
'

# Create rules file with substituted values
gf_check_files $CALIBRE_LVS_RULES
gf_add_tool_commands -comment '' -ext rul "$(cat $CALIBRE_LVS_RULES)"

# Data preparation
gf_create_step -name calibre_pre_lvs_bash "

    # Filter out commented port labels
    sed -e '\`$MAP_PORT_NAMES_SED_SCRIPT\`' '$DATA_OUT_DIR/$DESIGN_NAME.pins' > ./in/$TASK_NAME.pins
    sed -ie 's/^\s*#.*$//' ./scripts/$TASK_NAME.user.pins
    
    # Convert verilog to spice
    v2lvs -v '$DATA_OUT_DIR/$DESIGN_NAME.physical.v.gz' -o ./out/$TASK_NAME.sp -w 2
"
gf_use_calibre_lvs_batch

# Empty CDL for hierarchical database
gf_add_tool_commands -ext empty.sp '`@lvs_empty_cells_spice`'

# Default HCELL file
[[ -z "$HCELL_FILE" ]] && HCELL_FILE="$DATA_OUT_DIR/$DESIGN_NAME.hcell"

# Create runset
gf_add_tool_commands -ext runset "
    *lvsRulesFile: ./scripts/$TASK_NAME.rul
    *lvsIncludeFiles: ./in/$TASK_NAME.pins ./scripts/$TASK_NAME.user.pins
    *lvsLayoutPaths: $GDS_OUT_FILE
    *lvsLayoutPrimary: $DESIGN_NAME
    *lvsSourcePath: $(echo $CDL_FILES $PARTITIONS_CDL_FILES ./scripts/$TASK_NAME.empty.sp ./out/$TASK_NAME.sp) 
    *lvsSourcePrimary: $DESIGN_NAME
    *lvsUseHCells: 1
    *lvsHCellsFile: $HCELL_FILE
    *lvsDeviceFilterOptionsEnabled: 1
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
