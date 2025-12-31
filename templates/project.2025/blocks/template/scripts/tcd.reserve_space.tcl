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
# Filename: templates/project.2025/blocks/template/scripts/tcd.reserve_space.tcl
################################################################################

# Reserve space for TCD cells to use at dummy insertion stage
<PLACEHOLDER>
catch {delete_route_blockages -name blockage_for_dtcd}
set xgrid [get_db site:core .size.x]
set ygrid [get_db site:core .size.y]
foreach rect {
    {1000 1000 1020 1020}
} {
    create_place_blockage -type hard -name blockage_for_dtcd -rects [list \
        [expr "round([lindex $rect 0] / $xgrid) * $xgrid"] \
        [expr "round([lindex $rect 1] / $ygrid) * $ygrid"] \
        [expr "round([lindex $rect 2] / $xgrid) * $xgrid"] \
        [expr "round([lindex $rect 3] / $ygrid) * $ygrid"] \
    ]
    create_route_blockage -layers {M1 M2 M3 M4 M5 M6 M7 M8 M9} -name blockage_for_dtcd -rects [list \
        [expr "round([lindex $rect 0] / $xgrid + 6) * $xgrid"] \
        [expr "round([lindex $rect 1] / $ygrid + 1) * $ygrid"] \
        [expr "round([lindex $rect 2] / $xgrid - 6) * $xgrid"] \
        [expr "round([lindex $rect 3] / $ygrid - 1) * $ygrid"] \
    ]
}
