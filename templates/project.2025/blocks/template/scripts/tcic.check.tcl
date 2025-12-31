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
# Filename: templates/project.2025/blocks/template/scripts/tcic.check.tcl
################################################################################

# Check floorplan with TCIC rules
<PLACEHOLDER>
eval_legacy {
    source "*_tCIC_macro_usage_manager.tcl"
    source "*_tCIC_set_cip_variables.tcl"

    tCIC_set_design_cell_type <PLACEHOLDER>
    tCIC_set_max_DTCD_layer 11
    tCIC_reset_macro_usage
    tCIC_specify_macro_usage -usage SRAM -macro [get_db [get_db insts -if .base_cell.name==*] .name]
    
    Report macro usage
    tCIC_report_macro_usage
    
    convert_tCIC_to_ufc \
        -input_files "*_tCIC_*.tcl" \
        -ufc_file ./out/$TASK_NAME.ufc
    redirect { check_ufc ./out/$TASK_NAME.ufc } > "./reports/$TASK_NAME.tcic.log"
}
