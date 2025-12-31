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
# Filename: templates/project.2025/blocks/template/scripts/init.pg.default.tcl
################################################################################

# Power grid creation script (gf_init_power_grid)

# (!) Note: 
# This is a mix of commands for different metal stacks
# Please remove unnecessary code manually

# Customization
<PLACEHOLDER>
set nets {VDD VSS}
set macro_area_threshold 100

# Macros detection
set macros [get_db insts -if .area>$macro_area_threshold]

# Use custom tracks
add_tracks -pitches [join {
    m1 vert 0.000 
    m2 horiz 0.000
}] -offset [join {
    m1 vert 0.000 
    m2 horiz 0.000
}] -width_pitch_pattern [join {
    m0 offset 0.0 
    width 0.000 pitch 0.000 
    {width 0.000 pitch 0.000 repeat 0}
    width 0.000 pitch 0.000
    width 0.000 pitch 0.000
    {width 0.000 pitch 0.000 repeat 0}
    width 0.000 pitch 0.000
}] -mask_pattern [join {
    m0 2 1 2 1 2 1 2 1 2 1
    m1 1 2 
    m2 2 1 
    m3 1 2
}]

# Remove existing follow pins, stripes and blockages
catch {delete_route_blockage -name add_stripe_blockage}
delete_routes -net $nets -status routed -shapes {ring stripe corewire followpin ring padring}
delete_pg_pins -net $nets

# Default special route options
reset_db route_special_*
set_db route_special_connect_broken_core_pin true
# set_db route_special_core_pin_stop_route CellPinEnd
# set_db route_special_core_pin_ignore_obs overlap_obs
set_db route_special_via_connect_to_shape noshape

# Default via generation options
reset_db generate_special_via_*
set_db generate_special_via_preferred_vias_only keep
set_db generate_special_via_allow_wire_shape_change false
set_db generate_special_via_opt_cross_via true

# Default stripes options
reset_db add_stripes_*
set_db add_stripes_spacing_type center_to_center
# set_db add_stripes_stop_at_last_wire_for_area 1
set_db add_stripes_opt_stripe_for_routing_track shift
set_db add_stripes_skip_via_on_wire_shape {iowire}
set_db add_stripes_remove_floating_stapling true
set_db add_stripes_stacked_via_bottom_layer 1
set_db add_stripes_stacked_via_top_layer 1

# Special PG vias
catch {
    create_via_definition -name PGVIA4 -bottom_layer M4 -cut_layer VIA4 -top_layer M5 \
        -bottom_rects {{-0.000 -0.000} {0.000 0.000}} \
        -top_rects {{-0.000 -0.000} {0.000 0.000}} \
        -cut_rects {{-0.000 -0.000} {-0.000 0.000} {-0.000 -0.000} {0.000 0.000} {0.000 -0.000} {0.000 0.000}}
}

# M1/M2 blockages over macros
create_route_blockage -name add_stripe_blockage -layer {M1 M2} \
    -rects [gf_size_bboxes [get_db $macros .bbox] {-0.000 -0.000 0.000 0.000}]

# M1 blockages at core edges
create_route_blockage -name add_stripe_blockage -layers {M1} -rects [join \
    [get_computed_shapes -output rect \
        [get_computed_shapes \
            [get_db rows .rect] \
            SIZE \
            0.000 \
        ] \
        ANDNOT \
        [get_computed_shapes \
            [get_computed_shapes \
                [get_db rows .rect] \
                SIZEY \
                -0.000 \
            ] \
            SIZEX \
            -0.000 \
        ] \
    ] \
]

# M2/M3 Core rings
reset_db add_rings_*
set_db add_rings_stacked_via_top_layer M3
set_db add_rings_skip_via_on_wire_shape {stripe blockring}
set_db add_rings_break_core_ring_io_list [get_db $macros .name]
add_rings -nets [concat $nets $nets $nets $nets] \
    -type core_rings -follow core \
    -layer {top M2 bottom M2 left M3 right M3} \
    -width {top 0.000 bottom 0.000 left 0.000 right 0.000} \
    -spacing {top 0.000 bottom 0.000 left 0.000 right 0.000} \
    -offset {top 0.000 bottom 0.000 left 0.000 right 0.000} \
    -threshold 0 -jog_distance 0 -use_wire_group 1 -snap_wire_center_to_grid none

# M1/M2 Pads routing
route_special \
    -connect {pad_pin} \
    -block_pin_target {nearest_target} \
    -pad_pin_layer_range {M1 M2} \
    -pad_pin_target {block_ring ring} \
    -pad_pin_port_connect {all_port all_geom} \
    -crossover_via_layer_range {M1 AP} \
    -target_via_layer_range {M1 AP} \
    -allow_layer_change 1 -layer_change_range {M1 M4} \
    -allow_jogging 0 \
    -nets $nets 

# M1 follow pins
route_special \
    -connect core_pin \
    -core_pin_layer M1 \
    -core_pin_width 0.000 \
    -allow_jogging 0 \
    -allow_layer_change 0 \
    -core_pin_target none \
    -nets $nets
#
# # Force follow pins masks
# set_db [get_db [get_db nets $nets] .special_wires -if .shape==followpin] .mask 1

# M2/M4 follow pins duplication (fast)
foreach net $nets {
    foreach shape [get_db net:$net .special_wires -if .shape==followpin] {
        create_shape -layer M2 -width 0.000 -shape followpin -status routed -net $net -path_segment [get_db $shape .path]
        create_shape -layer M4 -width 0.000 -shape followpin -status routed -net $net -path_segment [get_db $shape .path]
    }
}

# M2/M4 follow pins duplication (classic)
set_db add_stripes_stacked_via_bottom_layer M1
set_db add_stripes_stacked_via_top_layer M1
set_db edit_wire_shield_look_down_layers 0
set_db edit_wire_shield_look_up_layers 0
set_db edit_wire_layer_min M1
set_db edit_wire_layer_max M1
set_db edit_wire_drc_on false
deselect_obj -all
select_routes -shapes followpin -layer M1
edit_duplicate_routes -layer_horizontal M2
# edit_update_route_width -width_horizontal 0.000
# edit_resize_routes -keep_center_line 1 -direction y -side high -to 0.000
edit_duplicate_routes -layer_horizontal M4
# edit_update_route_width -width_horizontal 0.000
# edit_resize_routes -keep_center_line 1 -direction y -side high -to 0.000
reset_db edit_wire_drc_on
reset_db edit_wire_shield_look_down_layers
reset_db edit_wire_shield_look_up_layers
reset_db edit_wire_layer_min
reset_db edit_wire_layer_max

# Optional: colorize DPT layers
set_db [get_db net:VDD .special_wires -if .layer.name==M2] .mask 2
set_db [get_db net:VSS .special_wires -if .layer.name==M2] .mask 2
set_db [get_db net:VDD .special_wires -if .layer.name==M4] .mask 1
set_db [get_db net:VSS .special_wires -if .layer.name==M4] .mask 1

# Follow pin orthogonal vias
set_db add_stripes_skip_via_on_pin {pad block cover standardcell}
set_db add_stripes_skip_via_on_wire_shape {ring blockring corewire blockwire iowire padring fillwire noshape}
# set_db generate_special_via_rule_preference {VIA12*}
update_power_vias -selected_wires 1 -add_vias 1 -bottom_layer M1 -top_layer M2 -orthogonal_only 0
update_power_vias -selected_wires 1 -add_vias 1 -bottom_layer M1 -top_layer M2 -orthogonal_only 0 -split_long_via {0.000 0.000 0.000 0.000}
deselect_obj -all
reset_db add_stripes_skip_via_on_pin
reset_db add_stripes_skip_via_on_wire_shape
delete_markers -all

# M3 stripes (regular)
set_db add_stripes_stacked_via_bottom_layer M2
set_db add_stripes_stacked_via_top_layer M3
set_db add_stripes_skip_via_on_pin {pad block cover standardcell}
set_db add_stripes_route_over_rows_only true
set_db generate_special_via_rule_preference {VIA23_*}
add_stripes \
    -layer M3 \
    -direction horizontal \
    -width 0.000 \
    -spacing [expr 1*0.000] \
    -set_to_set_distance [expr 2*0.000] \
    -start_offset 0.000 \
    -snap_wire_center_to_grid grid \
    -nets $nets

# M3 stripes (stapling)
set_db add_stripes_stacked_via_bottom_layer M1
set_db add_stripes_stacked_via_top_layer M4
set_db add_stripes_skip_via_on_pin {pad block cover standardcell}
set_db add_stripes_route_over_rows_only true
set_db add_stripes_remove_floating_stapling true
set_db generate_special_via_rule_preference {VIA12_* VIA23_* VIA34_*}
add_stripes \
    -layer M3 \
    -direction vertical \
    -width 0.000 \
    -stapling {0.000 M2} \
    -set_to_set_distance [expr 0.000*NTRACKS] \
    -start_offset 0.000 \
    -snap_wire_center_to_grid grid \
    -nets $nets
#
# Delete PG pins in lower metals
delete_pg_pins -net $nets

# M5 stripes over endcaps
set_db add_stripes_stacked_via_bottom_layer M2
set_db add_stripes_stacked_via_top_layer M5
set_db add_stripes_skip_via_on_pin {pad cover standardcell}
foreach area [gf_get_endcap_areas] {
    set width 0.500
    set wspacingidth 0.500
    set insts [get_obj_in_area -area $area -obj_type inst]
    <PLACEHOLDER>
    set endcaps_left_count [llength [get_db $insts -if .base_cell.name==BOUNDARY_LEFT]]
    set endcaps_right_count [llength [get_db $insts -if .base_cell.name==BOUNDARY_RIGHT]]
    if {($endcaps_left_count >= 5) || ($endcaps_right_count >= 5)} {
        if {$endcaps_left_count < $endcaps_right_count} {
            set x2 [lindex $area 2]
            set x1 [expr $x2 - 2 * $width - $spacing]
        } else {
            set x1 [lindex $area 0]
            set x2 [expr $x1 + 2 * $width + $spacing]
        }
        set area [list $x1 [expr [lindex $area 1] - 0.1]  $x2 [expr [lindex $area 3] + 0.1]]
        create_marker -description "Endcap area for power stripes" -type "Endcap area" -bbox $area
        add_stripes \
            -number_of_sets 1 \
            -layer M5 \
            -width $spacing \
            -spacing $spacing  \
            -direction vertical \
            -snap_wire_center_to_grid grid \
            -area $area \
            -nets $nets
    }
}
get_db markers -if {.user_type==Endcap*} -foreach {
    create_route_blockage -layers M5 -name add_stripe_blockage -rects [get_db $object .bbox]
}
delete_markers -all

# M6 stripes over macros (orthogonal pins)
set_db add_stripes_stacked_via_bottom_layer M4
set_db add_stripes_stacked_via_top_layer M6
set_db add_stripes_skip_via_on_pin {pad cover standardcell}
set_db add_stripes_route_over_rows_only false
set_db add_stripes_orthogonal_only false
set_db generate_special_via_rule_preference {VIA45_* VIA56_*}
add_stripes \
    -layer M6 \
    -direction horizontal \
    -width 0.000 \
    -spacing [expr 1*0.000*NTRACKS] \
    -set_to_set_distance [expr 2*0.000*NTRACKS] \
    -start_offset 0.000 \
    -snap_wire_center_to_grid grid \
    -area [get_db $macros .bbox] \
    -nets $nets
reset_db add_stripes_orthogonal_only
# create_route_blockage -name add_stripe_blockage -layer {M5 M6} -rects [gf_size_bboxes [get_db $macros .bbox] {-0.000 -0.000 0.000 0.000}]

# M5 stripes
set_db add_stripes_stacked_via_bottom_layer M4
set_db add_stripes_stacked_via_top_layer M5
set_db add_stripes_skip_via_on_pin {pad cover standardcell}
set_db generate_special_via_rule_preference {VIA45_*}
set_db add_stripes_route_over_rows_only false
add_stripes \
    -layer M5 \
    -direction vertical \
    -width 0.000 \
    -spacing [expr 1*0.000*NTRACKS] \
    -set_to_set_distance [expr 2*0.000*NTRACKS] \
    -start_offset 0.000 \
    -snap_wire_center_to_grid half_grid \
    -nets $nets

# M6 stripes
set_db add_stripes_stacked_via_bottom_layer M5
set_db add_stripes_stacked_via_top_layer M6
set_db generate_special_via_rule_preference {VIA56_*}
set_db add_stripes_skip_via_on_pin {pad cover standardcell}
set_db add_stripes_route_over_rows_only false
add_stripes \
    -layer M6 \
    -direction horizontal \
    -width 0.000 \
    -spacing [expr 1*0.000*NTRACKS] \
    -set_to_set_distance [expr 2*0.000*NTRACKS] \
    -start_offset 0.000 \
    -snap_wire_center_to_grid grid \
    -nets $nets

# Delete blockages over macros
catch {delete_route_blockage -name add_stripe_blockage}

# Update PG vias over macros
deselect_obj -all; select_obj $macros
reset_db generate_special_via_rule_preference
update_power_vias -bottom_layer M4 -top_layer M5 -delete_vias 1 -selected_blocks 1
update_power_vias -bottom_layer M4 -top_layer M5 -add_vias 1 -selected_blocks 1
deselect_obj -all

# Remove floating followpins and stripes
edit_trim_routes -layers {M0 M1 M2 M3 M4 M5} -nets $nets -type float

# Trim followpins and stripes
edit_trim_routes -layers {M1 M3} -nets $nets

# Update ring vias
foreach layer {6 7 8} {
    deselect_obj -all; select_routes -shape ring -layer M$layer
    update_power_vias -nets $nets -top_layer M$layer -bottom_layer M[expr $layer-1] -selected_wires 1 -add_vias 1
}
deselect_obj -all

# Update RV
foreach bump [get_db bumps] {
    create_route_blockage -layers RV -name block_rv_under_bumps -rects [list [list \
        [expr [get_db $bump .center.x]-60] [expr [get_db $bump .center.y]-60] \
        [expr [get_db $bump .center.x]+60] [expr [get_db $bump .center.y]+60] \
    ]]
}
deselect_obj -all
select_routes -layer {AP M11} -shapes stripe -nets $nets
update_power_vias -nets $nets -top_layer AP -bottom_layer M11 -between_selected_wires 1 -delete_vias 1
update_power_vias -nets $nets -top_layer AP -bottom_layer M11 -between_selected_wires 1 -add_vias 1
delete_route_blockages -name block_rv_under_bumps
deselect_obj -all

# Create PG ports (automatically)
<PLACEHOLDER>
deselect_obj -all
select_routes -layer M9 -nets $nets -shapes stripe
create_pg_pin -on_die -selected
deselect_obj -all

# Create PG ports in top layer
<PLACEHOLDER>
foreach stripe [get_obj_in_area -areas [get_db current_design .bbox] -layers M9 -obj_type special_wire] {
    if {[lsearch -exact $nets [set net_name [get_db $stripe .net.name]]] >= 0} {
        create_pg_pin -name $net_name -net $net_name -geometry [get_db $stripe .layer.name] [get_db $stripe .rect.ll.x] [get_db $stripe .rect.ll.y] [get_db $stripe .rect.ur.x] [get_db $stripe .rect.ur.y]
    }
}

# Colorize DPT layers
add_power_mesh_colors
