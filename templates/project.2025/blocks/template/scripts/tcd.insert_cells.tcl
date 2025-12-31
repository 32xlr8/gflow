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
# Filename: templates/project.2025/blocks/template/scripts/tcd.insert_cells.tcl
################################################################################

# Insert TCD cells into the design
set tcd_patterns {*_TCD_* FEOL_* BEOL_* *DTCD_FEOL* *DTCD_BEOL* *_DTCD_*}
foreach cell [get_db base_cells $tcd_patterns] {get_db insts -if ".base_cell==$cell" -foreach {delete_inst -inst [get_db $object .name]}}
set index 1
foreach location {
    {600 980}
    {600 1640}
    {1470 980}
    {1470 1640}
} {
    incr index
    set tcd_insts {}
    foreach cell [get_db [get_db base_cells $tcd_patterns] .name] {
        create_inst -physical -status fixed -location $location -cell $cell -inst ${cell}_${index}
        lappend tcd_insts inst:${cell}_${index}
    }
    
    gf_align_instances_to_grid 0.048 0.090 $tcd_insts
    
    catch {delete_route_blockages -name block_under_tcd}
    foreach rect [get_db $tcd_insts .bbox -u] {
        create_route_blockage -layers {M1 VIA1 M2 VIA2 M3 VIA3 M4 VIA4 M5 VIA5 M6 VIA6 M7 VIA7 M8 VIA8 M9} -name block_under_tcd -rects [list [list \
            [expr [lindex $rect 0]-4.0] [expr [lindex $rect 1]-4.0] \
            [expr [lindex $rect 2]+4.0] [expr [lindex $rect 3]+4.0] \
        ]]
    }
}
