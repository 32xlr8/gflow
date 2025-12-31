################################################################################
# Generic Flow v5.5.4 (December 2025)
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
# Filename: templates/project.2025/blocks/template/scripts/init.ports.tcl
################################################################################

# Place design ports script (gf_init_ports)

# Align macro ports
align_pins

# Batch mode on
set_db assign_pins_edit_in_batch true

# Clock port                
edit_pin -pin CLOCK -layer_vertical M7 -edge 0 -snap track -assign {0.000 0.000} -pin_width 0.000 -pin_depth 0.000

# Spread grouped ports
<PLACEHOLDER>
foreach ports [list \
    [get_db ports -if .name==pattern] \
] {
    edit_pin -snap track \
        -edge 0 \
        -spread_direction clockwise \
        -spread_type center \
        -layer_vertical M4 \
        -offset_start 0.0 \
        -spacing 8 -unit track \
        -fixed_pin 1 -fix_overlap 1 \
        -pin [get_db [get_db $ports -if .place_status==unplaced] .name]
}

# Projection of instance pins to vertical edge
<PLACEHOLDER>
foreach pin [list \
    [get_db pins instance_pin_patterns] \
] {
    set ports [get_db -u [concat [get_db $pin .net.drivers] [get_db $pin .net.loads]] -if .obj_type==port]
    if {![llength $ports]} {
        if {[get_db $pin .direction]=="in"} {
            set ports [get_db -u [all_fanin -to $pin] -if .obj_type==port]
        } elseif {[get_db $pin .direction]=="out"} {
            set ports [get_db -u [all_fanout -from $pin] -if .obj_type==port]
        }
    }
    edit_pin -snap track \
        -edge 0 \
        -layer_vertical M4 \
        -fixed_pin 1 -fix_overlap 1 \
        -assign [list [get_db current_design .bbox.ll.x] [get_db $pin .location]\
        -pin [get_db [get_db $ports -if .place_status==unplaced] .name]
}

# All the rest inputs
<PLACEHOLDER>
edit_pin -snap track \
    -edge 0 \
    -spread_direction clockwise \
    -spread_type center \
    -layer_vertical M4 \
    -offset_start 0.0 \
    -spacing 8 -unit track \
    -fixed_pin 1 -fix_overlap 1 \
    -pin [get_db [get_db ports -if .place_status==unplaced&&.direction==in] .name]

# All the rest outputs
edit_pin -snap track \
    -edge 2 \
    -spread_direction clockwise \
    -spread_type center \
    -layer_vertical M4 \
    -offset_start 0.0 \
    -spacing 8 -unit track \
    -fixed_pin 1 -fix_overlap 1 \
    -pin [get_db [get_db ports -if .place_status==unplaced&&.direction==out] .name]

# Batch mode off
set_db assign_pins_edit_in_batch false
