################################################################################
# Generic Flow v5.5.3 (October 2025)
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
# Filename: templates/project.2025/blocks/template/scripts/route.flipchip.tcl
################################################################################

# RDL routing script for flip chip designs (gf_route_flipchip)

# Signal bumps       
reset_db flip_chip_*
set_db flip_chip_prevent_via_under_bump true
route_flip_chip -target connect_bump_to_pad -delete_existing_routes 

# Power bumps
set_db flip_chip_connect_power_cell_to_bump true
set_db flip_chip_multiple_connection default
route_flip_chip -nets <PLACEHOLDER> -target connect_bump_to_pad

# AP grid
<PLACEHOLDER>
set_db add_stripes_stacked_via_top_layer AP
set_db add_stripes_stacked_via_bottom_layer M11
delete_routes -layer {RV AP} -net $nets -shapes stripe
set x_stripe_half_width 30
set y_stripe_half_width 30
set x_stripe_forbidden_edge 60
set y_stripe_forbidden_edge 60
foreach bump [get_db bumps] {
    if {[lsearch -exact $nets [get_db $bump .net.name]]>=0} {

        # RV blockage around bumps
        create_route_blockage -layers RV -name block_rv_under_bumps -rects [list [list \
            [expr [get_db $bump .center.x]-$x_stripe_forbidden_edge] [expr [get_db $bump .center.y]-$y_stripe_forbidden_edge] \
            [expr [get_db $bump .center.x]+$x_stripe_forbidden_edge] [expr [get_db $bump .center.y]+$y_stripe_forbidden_edge] \
        ]]

        # AP blockage at bump corners
        create_route_blockage -layers AP -name block_up_under_bumps -rects [list \
            [expr [get_db $bump .center.x]-$x_stripe_forbidden_edge] [expr [get_db $bump .center.y]-$y_stripe_forbidden_edge] \
            [expr [get_db $bump .center.x]-$x_stripe_half_width] [expr [get_db $bump .center.y]-$y_stripe_half_width] \
        ]
        create_route_blockage -layers AP -name block_up_under_bumps -rects [list \
            [expr [get_db $bump .center.x]-$x_stripe_forbidden_edge] [expr [get_db $bump .center.y]+$y_stripe_forbidden_edge] \
            [expr [get_db $bump .center.x]-$x_stripe_half_width] [expr [get_db $bump .center.y]+$y_stripe_half_width] \
        ]
        create_route_blockage -layers AP -name block_up_under_bumps -rects [list \
            [expr [get_db $bump .center.x]+$x_stripe_forbidden_edge] [expr [get_db $bump .center.y]-$y_stripe_forbidden_edge] \
            [expr [get_db $bump .center.x]+$x_stripe_half_width] [expr [get_db $bump .center.y]-$y_stripe_half_width] \
        ]
        create_route_blockage -layers AP -name block_up_under_bumps -rects [list \
            [expr [get_db $bump .center.x]+$x_stripe_forbidden_edge] [expr [get_db $bump .center.y]+$y_stripe_forbidden_edge] \
            [expr [get_db $bump .center.x]+$x_stripe_half_width] [expr [get_db $bump .center.y]+$y_stripe_half_width] \
        ]

        # Horizontal stripes
        add_stripes -nets [get_db $bump .net.name] -layer AP -direction horizontal -start_from bottom \
            -start_offset 2.7 -width 9.6 -spacing 5.4 -set_to_set_distance 15.0 \
            -switch_layer_over_obs false -use_wire_group 0 -snap_wire_center_to_grid none \
            -pad_core_ring_top_layer_limit AP -pad_core_ring_bottom_layer_limit AP \
            -block_ring_top_layer_limit AP -block_ring_bottom_layer_limit AP \
            -area [list \
                [expr [get_db $bump .center.x]-95] [expr [get_db $bump .center.y]-90] \
                [expr [get_db $bump .center.x]+95] [expr [get_db $bump .center.y]+90] \
            ]

        # Vertical stripes
        add_stripes -nets [get_db $bump .net.name] -layer AP -direction vertical -start_from left \
            -start_offset 0.2 -width 9.6 -spacing 15.4 -set_to_set_distance 25.0 \
            -switch_layer_over_obs false -use_wire_group 0 -snap_wire_center_to_grid none \
            -pad_core_ring_top_layer_limit AP -pad_core_ring_bottom_layer_limit AP \
            -block_ring_top_layer_limit AP -block_ring_bottom_layer_limit AP \
            -area [list \
                [expr [get_db $bump .center.x]-80] [expr [get_db $bump .center.y]-87.5] \
                [expr [get_db $bump .center.x]+80] [expr [get_db $bump .center.y]+87.5] \
            ]
    }
}
delete_route_blockages -name block_rv_under_bumps
delete_route_blockages -name block_up_under_bumps
