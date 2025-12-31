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
# Filename: templates/project.2025/tools/tool_steps.innovus.gf
# Purpose:  Innovus steps to use in the Generic Flow
################################################################################

gf_info "Loading tool-specific Innovus steps ..."

################################################################################
# Timing analysis steps
################################################################################

# Reset ideal clock constraints
gf_create_step -name innovus_reset_ideal_clock_constraints '

    set_interactive_constraint_mode [get_db [get_db constraint_modes -if {.is_setup||.is_hold}] .name]

    # Reset ideal netork constraints
    reset_ideal_network [get_ports *]
    reset_ideal_network [get_pins -hierarchical *]

    # Reset latency
    reset_ideal_latency [get_ports *]
    reset_clock_latency [get_clocks *]
    set_interactive_constraint_mode {}
'

# Reset clocks to ideal mode
gf_create_step -name innovus_reset_propagated_clocks '
    set_interactive_constraint_mode [get_db [get_db constraint_modes -if {.is_setup||.is_hold}] .name]
    reset_propagated_clock [get_clocks *]
    set_interactive_constraint_mode {}
'

# Set clocks to propagated mode
gf_create_step -name innovus_set_propagated_clocks '
    set_interactive_constraint_mode [get_db [get_db constraint_modes -if {.is_setup||.is_hold}] .name]
    reset_propagated_clock [get_clocks *]
    set_propagated_clock [get_clocks *]
    set_interactive_constraint_mode {}
'

# Update IO latency
gf_create_step -name innovus_update_io_latency '
    `@innovus_reset_propagated_clocks`
    update_io_latency
'

################################################################################
# Floorplan interactive steps
################################################################################

# Power grid creation procedures
gf_create_step -name innovus_procs_power_grid '

    # Size bboxes
    proc gf_size_bboxes {bboxes delta} {
        set results {}
        foreach bbox $bboxes {
            lappend results [list \
                [expr [lindex $bbox 0] + ([lindex $delta 0])] \
                [expr [lindex $bbox 1] + ([lindex $delta 1])] \
                [expr [lindex $bbox 2] + ([lindex $delta 2])] \
                [expr [lindex $bbox 3] + ([lindex $delta 3])] \
            ]
        }
        return $results
    }

    # Horizontal stripe
    proc gf_rect_to_stripe_h {rect} {
        set y [expr 1.0*([lindex $rect 1]+[lindex $rect 3])*5/10]
        return [list [expr abs([lindex $rect 1]-[lindex $rect 3])] [list [lindex $rect 0] $y [lindex $rect 2] $y]]
    }
    proc gf_points_to_stripe_h {x1 y1 x2 y2} {
        return [gf_rect_to_stripe_h "$x1 $y1 $x2 $y2"]
    }

    # Vertical stripe
    proc gf_rect_to_stripe_v {rect} {
        set x [expr 1.0*([lindex $rect 0]+[lindex $rect 2])*5/10]
        return [list [expr abs([lindex $rect 0]-[lindex $rect 2])] [list $x [lindex $rect 1] $x [lindex $rect 3]]]
    }
    proc gf_points_to_stripe_v {x1 y1 x2 y2} {
        return [gf_rect_to_stripe_v "$x1 $y1 $x2 $y2"]
    }

    # Write def for specific net
    proc gf_write_special_route_def {net file shapes} {
        set FH [open "$file" "w"]
        puts $FH {VERSION 5.8 ;}
        puts $FH {DIVIDERCHAR "/" ;}
        puts $FH {BUSBITCHARS "[]" ;}
        puts $FH "DESIGN [get_db current_design .name] ;"
        puts $FH {UNITS DISTANCE MICRONS 1000 ;}
        puts $FH {}
        puts $FH "SPECIALNETS [llength $shapes] ;"
        puts $FH "- $net"
        set net_shapes {}
        foreach shape $shapes {
            if {$net == [lindex $shape 3]} {
                lappend net_shapes $shape
            }
        }
        foreach shape $net_shapes {
            set inst [lindex $shape 0]
            set layer [lindex $shape 1]
            set type [lindex $shape 2]
            # set net [lindex $shape 3]
            set stripe [lindex $shape 4]
            if {$inst == ""} {
                set r [lindex $stripe 1]
            } else {
                set r [concat [get_transform_shapes -inst $inst -local_pt [lindex $stripe 1]]]
                # create_marker -layer $layer -bbox [get_transform_shapes -inst $inst -local_pt $rect]
            }
            puts $FH "+ FIXED $layer [expr int([lindex $stripe 0]*1000+0.5)] + SHAPE $type ( [expr int([lindex $r 0]*1000+0.5)] [expr int([lindex $r 1]*1000+0.5)] ) ( [expr int([lindex $r 2]*1000+0.5)] [expr int([lindex $r 3]*1000+0.5)] )"
        }
        puts $FH {;}
        puts $FH {END SPECIALNETS}
        puts $FH {}
        puts $FH {END DESIGN}
        close $FH
    }

    # Write def for specific net
    proc gf_duplicate_routes {net_name shapes layer_name width {unit 10000}} {
        set FH [open "./.duplicate.def" "w"]
        puts $FH {VERSION 5.8 ;}
        puts $FH {DIVIDERCHAR "/" ;}
        puts $FH {BUSBITCHARS "[]" ;}
        puts $FH "DESIGN [get_db current_design .name] ;"
        puts $FH "UNITS DISTANCE MICRONS $unit ;"
        puts $FH {}
        puts $FH "SPECIALNETS [llength $shapes] ;"
        puts $FH "- $net_name"
        foreach shape $shapes {
            set path [get_db $shape .path]
            puts $FH "+ [get_db $shape .status] $layer_name [expr int($width*$unit)] + SHAPE [get_db $shape .shape] ( [expr int([lindex $path 0 0]*$unit)] [expr int([lindex $path 0 1]*$unit)] ) ( [expr int([lindex $path 1 0]*$unit)] [expr int([lindex $path 1 1]*$unit)] )"
        }
        puts $FH {;}
        puts $FH {END SPECIALNETS}
        puts $FH {}
        puts $FH {END DESIGN}
        close $FH
        read_def "./.duplicate.def"
    }

    # Resize list of bboxes
    proc gf_resize_bbox {bbox offsets} {
        return [list \
            [expr [lindex $bbox 0]+[lindex $offsets 0]] \
            [expr [lindex $bbox 1]+[lindex $offsets 1]] \
            [expr [lindex $bbox 2]+[lindex $offsets 2]] \
            [expr [lindex $bbox 3]+[lindex $offsets 3]] \
        ]
    }

    # Transform list of bboxes
    proc gf_transform_bbox {bbox indexes offsets} {
        return [list \
            [expr [lindex $bbox [lindex $indexes 0]]+[lindex $offsets 0]] \
            [expr [lindex $bbox [lindex $indexes 1]]+[lindex $offsets 1]] \
            [expr [lindex $bbox [lindex $indexes 2]]+[lindex $offsets 2]] \
            [expr [lindex $bbox [lindex $indexes 3]]+[lindex $offsets 3]] \
        ]
    }

    # Get areas where endcap cells placed
    proc gf_get_endcap_areas {} {
        set bboxes [get_db [get_db insts [get_db add_endcaps_prefix]*] .bbox]
        
        set indexes {}
        foreach bbox $bboxes {
            lappend indexes [list [list [lindex $bbox 0] [lindex $bbox 2]] $bbox]
        }
        
        set x {}
        set groups {}
        set group {}
        foreach index [lsort -index 0 $indexes] {
            if {$x != [lindex $index 0]} {
                set x [lindex $index 0]
                lappend groups $group
                set group {}
            }
            lappend group [lindex $index 1]
        }
        lappend groups $group
        
        set results {}
        foreach group $groups {
            if {[llength $group] > 1} {
                set y1 {}
                set y2 {}
                set count 0
                foreach bbox [lsort -real -index 1 $group] {
                    if {$y1 == {}} {
                        set y1 [lindex $bbox 1]
                    } else {
                        if {[expr (abs ($y2 - [lindex $bbox 1]))] > 1e-9} {
                            if {$count > 1} {lappend results [list [lindex $bbox 0] $y1 [lindex $bbox 2] $y2]}
                            set y1 [lindex $bbox 1]
                            set count 0
                        } 
                    }
                    set y2 [lindex $bbox 3]
                    incr count
                }
                if {$count > 1} {lappend results [list [lindex $bbox 0] $y1 [lindex $bbox 2] $y2]}
            }
        }
        
        return $results
    }

    # Create hard place blockages at design corners
    proc gf_init_corner_place_blockage {size name} {
        set x0 [get_db current_design .bbox.ll.x]
        set y0 [get_db current_design .bbox.ll.y]
        set x1 [get_db current_design .bbox.ur.x]
        set y1 [get_db current_design .bbox.ur.y]
        create_place_blockage -name blockage_corner -type hard -rects [list \
            [list $x0 $y0 [expr $x0+$size] [expr $y0+$size]] \
            [list $x0 $y1 [expr $x0+$size] [expr $y1-$size]] \
            [list $x1 $y0 [expr $x1-$size] [expr $y0+$size]] \
            [list $x1 $y1 [expr $x1-$size] [expr $y1-$size]] \
        ]
    }

    # Reset cells 
    set gf_check_legalization_insts {}
    proc gf_check_legalization_reset {} {
        upvar gf_check_legalization_insts gf_check_legalization_insts
        get_db insts .name gf_check_legalization_* -foreach {delete_inst -inst $object}
        if {[llength $gf_check_legalization_insts]} {
            unplace_obj [get_db $gf_check_legalization_insts .name]
        }
        set gf_check_legalization_insts {}
    }
    
    
    # Check standard cell legalization - all cells
    proc gf_check_legalization {{x ""} {y ""} {dx ""} {dy ""} {max_y ""} {site ""}} {
        if {$site == ""} {set site [get_db rows .site.name -u]}
        if {$x == ""} {set x [expr [get_db current_design .core_bbox.ll.x]+0.25*[get_db current_design .core_bbox.length]]}
        if {$y == ""} {set y [expr [get_db current_design .core_bbox.ll.y]+0.25*[get_db current_design .core_bbox.width]]}
        if {$max_y == ""} {set max_y [expr [get_db current_design .core_bbox.ur.y]-0.25*[get_db current_design .core_bbox.width]]}
        if {$dx == ""} {set dx [expr 25.0*[lindex [get_db [get_db sites $site] .size.x] 0]]}
        if {$dy == ""} {set dy [lindex [get_db [get_db sites $site] .size.y] 0]}

        set insts {}
        get_db insts .name gf_check_legalization_* -foreach {delete_inst -inst $object}
        foreach base_cell [get_db base_cells -if .site.name==$site] {
            set name [get_db $base_cell .name]
            create_inst -cell $name -inst gf_check_legalization_$name
            lappend insts inst:gf_check_legalization_$name
        }

        set xc $x; set yc $y
        foreach inst $insts {
            set_db $inst .location [list $xc $yc]
            set yc [expr $yc+$dy]
            if {$yc > $max_y} {
                set xc [expr $xc+$dx]
                set yc $y
            }
        }

        place_detail -inst [get_db $insts .name]
        check_place
    }

    # Check standard cell legalization - design cells only
    proc gf_check_legalization_design {{x ""} {y ""} {dx ""} {dy ""} {max_y ""} {site ""}} {
        upvar gf_check_legalization_insts gf_check_legalization_insts
        
        if {$site == ""} {set site [get_db rows .site.name -u]}
        if {$x == ""} {set x [expr [get_db current_design .core_bbox.ll.x]+0.25*[get_db current_design .core_bbox.length]]}
        if {$y == ""} {set y [expr [get_db current_design .core_bbox.ll.y]+0.25*[get_db current_design .core_bbox.width]]}
        if {$max_y == ""} {set max_y [expr [get_db current_design .core_bbox.ur.y]-0.25*[get_db current_design .core_bbox.width]]}
        if {$dx == ""} {set dx [expr 25.0*[lindex [get_db [get_db sites $site] .size.x] 0]]}
        if {$dy == ""} {set dy [lindex [get_db [get_db sites $site] .size.y] 0]}
        
        set insts {}
        foreach base_cell [get_db [get_db insts .base_cell -u] -if .site.name==$site] {
            if {[set inst [lindex [get_db insts -if .base_cell==$base_cell&&.place_status!=fixed] 0]] != ""} {
                lappend insts $inst
                lappend gf_check_legalization_insts $inst
            }
        }

        set xc $x; set yc $y
        foreach inst $insts {
            set_db $inst .location [list $xc $yc]
            set yc [expr $yc+$dy]
            if {$yc > $max_y} {
                set xc [expr $xc+$dx]
                set yc $y
            }
        }

        place_detail -inst [get_db $insts .name]
        check_place
    }
'

# Objects manipulation procedures
gf_create_step -name innovus_procs_objects '

    # Print cells groups
    proc gf_base_cell_groups {{pattern *}} {
        foreach name [lsort -u [regsub -all {[0-9]+} [get_db base_cells .name $pattern] {*}]] { puts "$name {[get_db base_cells .name $name]}"}
    }

    # Initialize unplaced ports interactive procedure
    proc gf_init_ports_on_edge {layers {edge_in 0} {edge_out 2} {spacing 2}} {
        set assign_pins_edit_in_batch_value [get_db assign_pins_edit_in_batch]
        set_db assign_pins_edit_in_batch true
        
        set layers [get_db layers $layers]
        set hlayers [get_db [get_db $layers -if .direction==horizontal] .name]
        set vlayers [get_db [get_db $layers -if .direction==vertical] .name]
        
        if {$edge_in == $edge_out} {
            edit_pin -snap track \
                -edge $edge_in -spread_direction clockwise -spread_type center \
                -layer_horizontal $vlayers -layer_vertical $hlayers \
                -spacing $spacing -unit track \
                -fixed_pin 1 -fix_overlap 1 \
                -pin [get_db ports .name]
        } else {
            edit_pin -snap track \
                -edge $edge_in -spread_direction clockwise -spread_type center \
                -layer_horizontal $vlayers -layer_vertical $hlayers \
                -spacing $spacing -unit track \
                -fixed_pin 1 -fix_overlap 1 \
                -pin [get_db [get_db ports -if {.direction==in}] .name]
            edit_pin -snap track \
                -edge $edge_out -spread_direction clockwise -spread_type center \
                -layer_horizontal $vlayers -layer_vertical $hlayers \
                -spacing $spacing -unit track \
                -fixed_pin 1 -fix_overlap 1 \
                -pin [get_db [get_db ports -if {.direction==out}] .name]
        }
        set_db assign_pins_edit_in_batch $assign_pins_edit_in_batch_value
    }

    # Select next instances of same base cell as already selected
    proc gf_select_similar_instances_by_index {} {
        set selected_insts [get_db selected -if .obj_type==inst]
        set insts_to_select {}
        
        set patterns [get_db $selected_insts .name]

        # Already selected
        foreach inst $selected_insts {
            puts "\033\[34;44m \033\[0m $inst ..."
        }

        # Search patterns
        set depth 0
        set processed_patterns {}
        while {$patterns != {}} {
            set next_patterns {}
            
            # High priority patterns
            foreach pattern $patterns {
# puts "# $depth: $pattern"

                set parts [lreverse [split $pattern {/}]]
                if {[llength $parts] > $depth} {
                    # set part [regsub -all {[\[\]\.\_]+} [lindex $parts $depth] {?}]
                    set part [lindex $parts $depth]
                    set part_pattern [regsub -all {[\*0-9]+} $part {*}]
# puts "  # P: $part_pattern"
                    if {$part_pattern != $part} {
                        set next_pattern [join [lreverse [lreplace $parts $depth $depth $part_pattern]] {/}]
# puts "  # N: $next_pattern"
                        if {[lsearch -exact $processed_patterns $next_pattern] < 0} {
                            lappend processed_patterns $next_pattern
                            lappend next_patterns $next_pattern
                            if {[set hinst_name [file dirname $next_pattern]] == "."} {
                                set insts [get_db current_design .local_insts $next_pattern]
                            } else {
                                set insts [get_db -u [get_db hinsts -match_hier $hinst_name] .local_insts $next_pattern]
                            }
# puts "  # L: [llength $insts]"

                            # Prioritized selection
                            while {$part != [set part_pattern [regsub -all {\*\*+} [regsub {[0-9]+([^0-9]*$)} $part {*\1}] {*}]]} {
# puts "    # F: [join [lreverse [lreplace $parts $depth $depth $part_pattern]] {/}]"
                                foreach inst [get_db $insts [join [lreverse [lreplace $parts $depth $depth $part_pattern]] {/}]] {
# puts "    # I: $inst"
                                    if {[lsearch -exact $selected_insts $inst] < 0} {
                                        lappend insts_to_select $inst
# puts "    # [llength $insts_to_select]: $inst"
                                    }
                                }
                                if {$insts_to_select != {}} {break}
                                set part $part_pattern
                            }
                        }
                    }
                }
            }

            # Next depth processing
            if {$insts_to_select != {}} {break}
            set patterns $next_patterns
            incr depth
        }

        # Nothing to select
        if {$insts_to_select == {}} {
            puts "  No more instances to select"
            
        # Selection
        } else {

            # To be selected
            select_obj $insts_to_select
            foreach inst $insts_to_select {
                puts "\033\[32;42m \033\[0m $inst ..."
            }
            
            # Summary
            puts "  [llength $selected_insts] -> [expr [llength $selected_insts]+[llength $insts_to_select]] instances selected"
        }
    }

    # Select next instances of same base cell as already selected
    proc gf_select_similar_instances_by_cell {{include_subhierarchy 1}} {
        set selected_insts [get_db selected -if .obj_type==inst]
        set selected_cells [get_db $selected_insts .base_cell -u]
        set selected_parents [get_db $selected_insts .parent -u]
        set selected_hinsts [get_db $selected_parents -if .obj_type==hinst -u]
        set next_instances {}
        foreach inst $selected_insts {
            puts "\033\[34;44m \033\[0m $inst ..."
        }

        # Check candidated until first match
        while {($next_instances == {}) && ($selected_parents != "")} {
            foreach base_cell $selected_cells {

                # Same hinst
                if {$include_subhierarchy} {
                    foreach inst [get_db $selected_parents .insts -if .base_cell==$base_cell] {
                        if {[lsearch -exact $selected_insts $inst] < 0} {
                            puts "\033\[33;43m \033\[0m $inst ..."
                            lappend next_instances $inst
                        }
                    }

                # Same hinst and below
                } else {
                    foreach inst [get_db $selected_parents .local_insts -if .base_cell==$base_cell] {
                        if {[lsearch -exact $selected_insts $inst] < 0} {
                            puts "\033\[32;42m \033\[0m $inst ..."
                            lappend next_instances $inst
                        }
                    }
                }
            }
            set selected_parents [get_db $selected_hinsts .parent -u]
            set selected_hinsts [get_db $selected_parents -if .obj_type==hinst -u]
        }
        
        # Selection
        if {$next_instances == {}} {
            puts "  No more to select"
        } else {
            select_obj $next_instances
            puts "  [llength $selected_insts] -> [expr [llength $selected_insts]+[llength $next_instances]] instances selected"
        }
    }
    

    
    # Select all instances of same base cell as already selected
    proc gf_select_more_instances {} {
        foreach base_cell [get_db [get_db selected -if .obj_type==inst] .base_cell.name -u] {
            set condition ".base_cell.name==$base_cell"
            puts "\033\[34;44m \033\[0m Selecting all \033\[97m$condition\033\[0m instances ..."
            set instances [get_db insts -if "$condition"]
            puts "  [llength $instances] instances"
            select_obj $instances
        }
    }
    
    # Select all blockages of same name as already selected
    proc gf_select_more_place_blockages {} {
        set conditions {}
        foreach selected [get_db selected -if .obj_type==place_blockage] {
            set condition ".type==[get_db $selected .type]&&.name==[get_db $selected .name]"
            if {[lsearch -exact $conditions $condition] < 0} {
                lappend conditions $condition
            }
        }
        foreach condition $conditions {
            puts "\033\[34;44m \033\[0m Selecting all \033\[97m$condition\033\[0m place blockages ..."
            set blockages [get_db place_blockages -if "$condition"]
            puts "  [llength $blockages] place blockages"
            select_obj $blockages
        }
    }
    
    # Select more objects
    proc gf_select_more {} {
        gf_select_more_instances
        gf_select_more_place_blockages
    }
    
    # Get ports connected directly to core instances
    proc gf_get_io_core_nets {pad_site_class} {
        set pins [get_db [concat [get_db ports .net.drivers] [get_db ports .net.loads]] -if .obj_type==pin]
        get_db $pins -if .inst.base_cell.site.class!=$pad_site_class
    }
    
    # Select point in user-specific grid
    proc gf_gui_select_point_in_grid {xgrid {ygrid {}}} {
        if {$ygrid == {}} {set ygrid $xgrid}
        set point [gui_get_coord]
        set x [expr "round([lindex $point 0] / $xgrid) * $xgrid"]
        set y [expr "round([lindex $point 1] / $ygrid) * $ygrid"]
        puts "{$x $y}"
        return [list $x $y]
    }
    
    proc gf_gui_select_box_in_grid {xgrid {ygrid {}}} {
        if {$ygrid == {}} {set ygrid $xgrid}
        set point [gui_get_box]
        set x0 [expr "round([lindex $point 0] / $xgrid) * $xgrid"]
        set y0 [expr "round([lindex $point 1] / $ygrid) * $ygrid"]
        set x1 [expr "round([lindex $point 2] / $xgrid) * $xgrid"]
        set y1 [expr "round([lindex $point 3] / $ygrid) * $ygrid"]
        puts "{$x0 $y0 $x1 $y1}"
        return [list $x0 $y0 $x1 $y1]
    }

    # Align instances to grid
    proc gf_align_instances_to_grid {x y insts} {
        foreach inst $insts {
            set_db $inst .location [list \
                [expr "round([get_db $inst .location.x] / $x) * $x"] \
                [expr "round([get_db $inst .location.y] / $y) * $y"] \
            ]
        }
    }

    # Manual bump assignment procs
    proc gf_assign_next_bumps {{bumps {}}} {
        if {[llength $bumps]} {
            set ::bumps_to_assign $bumps
        }
        set count 0
        foreach bump [get_db [get_db selected -if .obj_type==bump] -if .net==""] {
            set nets [get_db bumps .net.name -u]
            foreach net $::bumps_to_assign {
                if {[lsearch -exact $nets $net]<0} {
                    puts "\033\[32;42m \033\[0m [get_db $bump .name] -> $net"
                    assign_signal_to_bump -bumps [get_db $bump .name] -net $net
                    incr count
                    break
                }
            }
        }
        if {$count<1} {
            if {[llength $::bumps_to_assign]} {
                puts "\033\[31;41m \033\[0m No more unassigned bumps"
            } else {
                puts "\033\[31;41m \033\[0m Please provide list of bumps to assign\nset ::bumps_to_assign {...}"
            }
        }
    }

    # Shortcut to unassign selected bump
    proc gf_unassign_selected_bumps {} {
        unassign_bumps -selected
    }

    # Swap several bumps
    proc gf_swap_bumps {{bumps {}}} {
        set bumps [get_db $bumps -if .obj_type==bump]
        if {$bumps == {}} {set bumps [get_db selected -if .obj_type==bump]}
        if {[llength $bumps] > 1} {
            set nets [get_db $bumps .net.name]
            lappend nets [lindex $nets 0]
            unassign_bumps -bumps [get_db $bumps .name]
            for {set i 1} {$i <= [llength $bumps]} {incr i} {
                assign_signal_to_bump -bumps [lindex [get_db $bumps .name] [expr $i-1]] -net [lindex $nets $i]
            }
        } else {
            error "Please select at least 2 bumps"
        }
    }

    # Get track color at selected position
    proc gf_get_track_pattern {position layer} {
        if {[get_db [get_db layers $layer] .direction] == "horizontal"} {
            set patterns [get_db track_patterns -if .direction==y&&.layers.name==$layer]
        } else {
            set patterns [get_db track_patterns -if .direction==x&&.layers.name==$layer]
        }
        set difference 0.0
        set result {}
        foreach pattern $patterns {
            set start [get_db $pattern .start]
            set step [get_db $pattern .step]
            set diff [expr {abs(round(($position-$start)/$step)*$step+$start-$position)}]
            if {($diff<$difference) || ($result=={})} {
                set difference $diff
                set result $pattern
            }
        }
        return $result
    }

    # Stick wires to the nearest track mask
    proc gf_colorize_wires {wires} {
        foreach wire $wires {
            if {[get_db $wire .layer.direction] == "horizontal"} {
                set position [expr ([get_db $wire .rect.ll.y]+[get_db $wire .rect.ur.y])/2.0]
            } else {
                set position [expr ([get_db $wire .rect.ll.x]+[get_db $wire .rect.ur.x])/2.0]
            }
            set_db $wire .mask [get_db [gf_get_track_pattern $position [get_db $wire .layer.name]] .mask]
        }
    }
'

# Visual reports procedures
gf_create_step -name innovus_procs_reports '

    # Dont use cells
    proc gf_report_dont_use_cells {} {
        set cells_all [lsort [get_db base_cells -u]]
        set cells_used [get_db insts .base_cell -u]
        set cells_netlist_er {}
        set cells_netlist_ok {}
        foreach cell $cells_used {
            if {[get_db $cell .dont_use]} {
                lappend cells_netlist_er $cell
            } else {
                lappend cells_netlist_ok $cell
            }
        }
        puts "\[\033\[32m[gf_get_symbols [llength $cells_all] 80 0 {#} [llength $cells_netlist_ok]]\033\[31m[gf_get_symbols [llength $cells_all] 80 0 {X} [llength $cells_netlist_er]]\033\[0m[gf_get_symbols [llength $cells_all] 80 0 {.} [expr [llength $cells_all]-[llength $cells_used]]]\] \033\[32m[llength $cells_netlist_ok]\033\[0m/\033\[31m[llength $cells_netlist_er]\033\[0m of [llength $cells_all] active/dont_use cells used"
    }
    
    # Summary reports
    proc gf_report_simultaneous_time_design {dir} {

        # Enable simultaneous setup and hold analysis mode
        set_db timing_enable_simultaneous_setup_hold_mode true
        
        # Timing summary
        time_design -expanded_views -report_only -report_dir ./time_design -report_prefix timing
        exec mv ./time_design/timing.summary $dir/timing.late.summary
        exec mv ./time_design/timing_hold.summary $dir/timing.early.summary
        exec rm -Rf ./time_design
    }

    # Create timing reports
    proc gf_report_timing {dir {check late} {count_full 150} {count_all 1000} {count_short 10000}} {
    
        # All timing reports
        report_timing -$check -max_paths $count_all -path_type full_clock -split_delay > $dir/timing.$check.full.all.tarpt
        report_timing -$check -max_paths $count_all -output_format gtd > $dir/timing.$check.mtarpt
        report_timing -$check -max_paths $count_short -path_type endpoint > $dir/timing.$check.short.all.tarpt

        # Path groups reports
        if {[sizeof_collection [set path_groups [get_path_groups]]] > 0} {
            foreach_in_collection path_group [get_path_groups] {
                set group [get_db $path_group .name]
                report_timing -$check -max_paths $count_full -path_type full_clock -split_delay -group $group > $dir/timing.$check.full.group.$group.tarpt
                report_timing -$check -max_paths $count_short -path_type endpoint -group $group > $dir/timing.$check.short.group.$group.tarpt
            }

        # Register to register reports
        } else {
            if {![info exists ::gf_all_registers]} { set ::gf_all_registers [all_registers] }
            report_timing -$check -max_paths $count_full -path_type full_clock -split_delay -from $::gf_all_registers -to $::gf_all_registers > $dir/timing.$check.full.group.reg2reg.tarpt
            report_timing -$check -max_paths $count_short -path_type endpoint -from $::gf_all_registers -to $::gf_all_registers > $dir/timing.$check.short.group.reg2reg.tarpt
        }

        # Clock reports
        foreach clock [get_db clocks .base_name -u] {
            report_timing -$check -max_paths $count_full -path_type full_clock -split_delay -from $clock > $dir/timing.$check.full.clock.$clock.tarpt
            report_timing -$check -max_paths $count_short -path_type endpoint -from $clock > $dir/timing.$check.short.clock.$clock.tarpt
        }
    }
    
    # Create PBA timing reports
    proc gf_report_timing_pba {dir {check late} {count 1000}} {
        if {[get_db timing_analysis_aocv]} {
            report_timing -$check -max_paths $count -path_type full_clock -split_delay -retime aocv_path_slew_propagation > $dir/timing.$check.full.pba.tarpt
        } else {
            report_timing -$check -max_paths $count -path_type full_clock -split_delay -retime path_slew_propagation > $dir/timing.$check.full.pba.tarpt
        }
    }
    
    # Create worst timing reports
    proc gf_report_timing_worst {dir {check late} {count 1000}} {
        set collection [report_timing -$check -collection -max_paths $count]
        redirect $dir/worst.$check.worst.rpt {
            gf_report_timing_worst_slack $collection $count
            gf_report_timing_worst_path_delay $collection $count
            gf_report_timing_best_path_delay $collection $count
            gf_report_timing_worst_skew $collection $count
            gf_report_timing_worst_net_length $collection $count
            gf_report_timing_worst_delay $collection $count
            gf_report_timing_worst_delta_delay $collection $count
            gf_report_timing_worst_slew $collection $count
        }
    }

    # Create timing reports histogram
    proc gf_report_timing_histograms {dir {check late} {count 10000}} {
        set collection [report_timing -$check -collection -max_paths $count]
        redirect $dir/histograms.$check.histograms.rpt {
            gf_report_histogram_slack $collection
            gf_report_histogram_delay $collection
            gf_report_histogram_skew $collection
            gf_report_histogram_worst_manhattan_length $collection
            gf_report_histogram_worst_cell_delay $collection
            gf_report_histogram_slew $collection
            gf_report_histogram_datapath $collection
        }
    }

    # Returns bar line for {symbol value} pairs 
    proc gf_get_symbols {max_value spaces is_limit args} {
        set result ""
        foreach {symbol value} $args {
            if {$is_limit && ($value > $max_value)} {
                set count [expr $spaces-1]
            } else {
                set count [expr int(0.5+1.0*$value*$spaces/$max_value)]
            }
            for {set i 0} {$i<$count} {incr i} {
                set result "$result$symbol"
            }
            if {$is_limit && ($value > $max_value)} {
                set result "$result>"
            }
        }
        return $result
    }
    
    # Prints timing collection short report
    proc gf_report_timing_collection {collection {is_colored 0}} {
        set index 0
        if {$is_colored} {
            set skew_symbol "\033\[95;45m>\033\[0m"
            set cell_delay_symbol "\033\[92;42m#\033\[0m"
            set net_delay_symbol "\033\[93;43m*\033\[0m"
            set clock_symbol "\033\[96;46m-\033\[0m"
        } else {
            set skew_symbol ">"
            set cell_delay_symbol "#"
            set net_delay_symbol "*"
            set clock_symbol "-"
        }
        
        # Proceed paths one by one
        foreach_in_collection timing_path $collection {
            incr index

            set period [expr int(0.5+1000*[get_db $timing_path .period])]
            if {$period > 0} {
                set clock_period $period
            } else {
                set clock_period [expr int(0.5+1000*[get_db $timing_path .capturing_clock.period])]
            }
            set path_cell_delay [expr int(0.5+1000*[get_db $timing_path .path_cell_delay])]
            set path_net_delay [expr int(0.5+1000*[get_db $timing_path .path_net_delay])]
            set skew [expr int(0.5+1000*[get_db $timing_path .skew])]
            set slack [expr int(0.5+1000*[get_db $timing_path .slack])]

            # Path summary
            puts "($index) Slack: $slack; Delay: $path_cell_delay+$path_net_delay; Period: $clock_period; Skew: $skew; Points: [llength [get_db $timing_path .timing_points]]"

            # Delay histogram
            puts [gf_get_symbols $clock_period 50 0 $skew_symbol [expr -($skew)] $cell_delay_symbol $path_cell_delay $net_delay_symbol $path_net_delay]
            if {$period > 0} {
                puts [gf_get_symbols $clock_period 50 0 $skew_symbol $skew $clock_symbol $clock_period]
            }
            
            # Points
            puts "  From: [get_db $timing_path .launching_point.name]"
            puts "    To: [get_db $timing_path .capturing_point.name]"

            # Delay
            catch {
                set worst_point ""
                set worst_value 0.0
                foreach timing_point [get_db $timing_path .timing_points] {
                    if {[string is double [set value [get_db $timing_point .delay]]]} {
                        if {$worst_value < $value} {
                            set worst_value $value
                            set worst_point [get_db $timing_point .hierarchical_name]
                        }
                    }
                }
                if {$worst_point != ""} {
                    puts " Delay: [expr int(0.5+$worst_value*1000)] $worst_point"
                }
            }
            
            # Delta delay
            catch {
                set worst_point ""
                set worst_value 0.0
                foreach timing_point [get_db $timing_path .timing_points] {
                    if {[string is double [set value [get_db $timing_point .delta_delay]]]} {
                        if {$worst_value < $value} {
                            set worst_value $value
                            set worst_point [get_db $timing_point .hierarchical_name]
                        }
                    }
                }
                if {$worst_point != ""} {
                    puts " Delta: [expr int(0.5+$worst_value*1000)] $worst_point"
                }
            }
            
            # Slew
            catch {
                set worst_point ""
                set worst_value 0.0
                foreach timing_point [get_db $timing_path .timing_points] {
                    if {[string is double [set value [get_db $timing_point .slew]]]} {
                        if {$worst_value < $value} {
                            set worst_value $value
                            set worst_point [get_db $timing_point .hierarchical_name]
                        }
                    }
                }
                if {$worst_point != ""} {
                    puts "  Slew: [expr int(0.5+$worst_value*1000)] $worst_point"
                }
            }
            
            # Net length 
            puts "   Net: [expr int(0.5+[get_db $timing_path .worst_manhattan_length])] [get_db $timing_path .worst_manhattan_length_net_name]"
            
            puts ""
        }
    }

    # Worst timing slack
    proc gf_report_timing_worst_slack {collection {count 20}} {
        set values {}
        foreach_in_collection timing_path $collection {
            if {[string is double [set value [get_db $timing_path .slack]]]} {
                lappend values [list $value [get_db $timing_path .launching_point.name] [get_db $timing_path .capturing_point.name]]
            }
        }
        foreach result [lsort -index 0 -real -increasing $values] {
            incr index
            if {$index > $count} {break}
            puts "($index) Slack: [lindex $result 0]\n[lindex $result 1]\n[lindex $result 2]\n"
        }
    }

    # Worst path delay
    proc gf_report_timing_worst_path_delay {collection {count 20}} {
        set values {}
        foreach_in_collection timing_path $collection {
            if {[string is double [set value [get_db $timing_path .path_delay]]]} {
                lappend values [list $value [get_db $timing_path .launching_point.name] [get_db $timing_path .capturing_point.name]]
            }
        }
        foreach result [lsort -index 0 -real -decreasing $values] {
            incr index
            if {$index > $count} {break}
            puts "($index) Delay: [lindex $result 0]\n[lindex $result 1]\n[lindex $result 2]\n"
        }
    }

    # Worst path delay
    proc gf_report_timing_best_path_delay {collection {count 20}} {
        set values {}
        foreach_in_collection timing_path $collection {
            if {[string is double [set value [get_db $timing_path .path_delay]]]} {
                lappend values [list $value [get_db $timing_path .launching_point.name] [get_db $timing_path .capturing_point.name]]
            }
        }
        foreach result [lsort -index 0 -real -increasing $values] {
            incr index
            if {$index > $count} {break}
            puts "($index) Delay: [lindex $result 0]\n[lindex $result 1]\n[lindex $result 2]\n"
        }
    }

    # Worst skew
    proc gf_report_timing_worst_skew {collection {count 20}} {
        set values {}
        foreach_in_collection timing_path $collection {
            if {[string is double [set value [get_db $timing_path .skew]]]} {
                set sort_value [expr abs($value)]
                lappend values [list $sort_value $value [get_db $timing_path .launching_point.name] [get_db $timing_path .capturing_point.name]]
            }
        }
        foreach result [lsort -index 0 -real -decreasing $values] {
            incr index
            if {$index > $count} {break}
            puts "($index) Skew: [lindex $result 1]\n[lindex $result 2]\n[lindex $result 3]\n"
        }
    }

    # Worst net length
    proc gf_report_timing_worst_net_length {collection {count 20}} {
        set values {}
        foreach_in_collection timing_path $collection {
            if {[string is double [set value [get_db $timing_path .worst_manhattan_length]]]} {
                lappend values [list $value [get_db $timing_path .worst_manhattan_length_net_name]]
            }
        }
        foreach result [lsort -index 0 -real -decreasing $values] {
            incr index
            if {$index > $count} {break}
            puts "($index) Net length: [lindex $result 0] @ [lindex $result 1]"
        }
    }

    # Worst point delay
    proc gf_report_timing_worst_delay {collection {count 20}} {
        set values {}
        foreach timing_point [get_db $collection .timing_points] {
            if {[string is double [set value [get_db $timing_point .delay]]]} {
                lappend values [list $value [get_db $timing_point .hierarchical_name]]
            }
        }
        set results {}
        foreach result [lsort -index 0 -real -decreasing $values] {
            set result "[lindex $result 0] @ [lindex $result 1]"
            if {[lsearch -exact $results $result] < 0} {
                incr index
                if {$index > $count} {break}
                puts "($index) Delay: $result"
                lappend results $result
            }
        }
    }

    # Worst delta delay
    proc gf_report_timing_worst_delta_delay {collection {count 20}} {
        set values {}
        foreach timing_point [get_db $collection .timing_points] {
            if {[string is double [set value [get_db $timing_point .delta_delay]]]} {
                lappend values [list $value [get_db $timing_point .hierarchical_name]]
            }
        }
        set results {}
        foreach result [lsort -index 0 -real -decreasing $values] {
            set result "[lindex $result 0] @ [lindex $result 1]"
            if {[lsearch -exact $results $result] < 0} {
                incr index
                if {$index > $count} {break}
                puts "($index) Delta delay: $result"
                lappend results $result
            }
        }
    }

    # Worst slew
    proc gf_report_timing_worst_slew {collection {count 20}} {
        set values {}
        foreach timing_point [get_db $collection .timing_points] {
            if {[string is double [set value [get_db $timing_point .slew]]]} {
                lappend values [list $value [get_db $timing_point .hierarchical_name]]
            }
        }
        set results {}
        foreach result [lsort -index 0 -real -decreasing $values] {
            set result "[lindex $result 0] @ [lindex $result 1]"
            if {[lsearch -exact $results $result] < 0} {
                incr index
                if {$index > $count} {break}
                puts "($index) Slew: $result"
                lappend results $result
            }
        }
    }

    # Histogram reporting
    proc gf_report_histogram {values {spaces 80} {bins 10} {cut_ratio 0.0}} {

        # Filter and sort values
        set filtered_values {}
        foreach value $values {
            if {($value != "") && [string is double $value]} {
                lappend filtered_values $value
            }
        }
        
        # Data amount is not enough to report histogram
        if {[set count [llength [set values [lsort -increasing -real $filtered_values]]]] < 2} {
            puts "\033\[41m \033\[0m Not enough data to report histogram"

        # Report histogram
        } else {
        
            # Cut edge values
            if {$cut_ratio > 0.5} {set cut_ratio 0.0}
            if {$cut_ratio < 0.0} {set cut_ratio 0.0}
            set min_value [lindex $values [expr int($cut_ratio*($count-1))]]
            set max_value [lindex $values [expr int((1.0-$cut_ratio)*($count-1))]]

            # Calculate ranges
            set lvalue [lindex $values 0]
            set rvalue [lindex $values end]
            if {[llength $bins] < 2} {
                set step [expr 1.0/$bins*($max_value-$min_value)]
                set value $min_value
                set new_bins {}
                for {set i 1} {$i<$bins} {incr i} {
                    set value [expr $step+$value]
                    lappend new_bins $value
                }
                set bins $new_bins
            }

            # Calculate ranges
            set ranges {}
            foreach bin [concat [lsort -real -increasing $bins] $rvalue] {
                if {($lvalue < $bin) && ($bin <= $rvalue)} {
                    lappend ranges [list $lvalue $bin]
                    set lvalue $bin
                }
            }
            set ranges_count [llength $ranges]

            # Categorize values
            set categories {}
            set index 0
            set bin [lindex $ranges $index 1]
            set count 0
            foreach value $values {
                while {$value > $bin} {
                    if {$index >= $ranges_count} {break}
                    lappend categories $count
                    set count 0
                    incr index
                    set bin [lindex $ranges $index 1]
                }
                incr count
            }
            if {$count > 0} {lappend categories $count}

            # Detect number of digits
            set digits 8
            set value [expr 1000.0*$max_value]
            while {$value > 1.0} {
                set value [expr $value/10.0]
                set digits [expr $digits-1]
            }
            if {$digits < 0} {
                set digits 0
            }

            # Print histogram
            set title_length 0
            set max_count 1
            set histogram {}
            for {set i 0} {$i<$ranges_count} {incr i} {
                if {[set count [lindex $categories $i]] > $max_count} {set max_count $count}
                set title "[format "%0.${digits}f" [lindex $ranges $i 0]]:[format "%0.${digits}f" [lindex $ranges $i 1]]"
                if {$title_length < [string length $title]} {set title_length [string length $title]}
                lappend histogram [list $title $count]
            }
            for {set i 0} {$i<$ranges_count} {incr i} {
                set value [lindex $histogram $i 1]
                puts " [format "%${title_length}s" [lindex $histogram $i 0]] [gf_get_symbols $max_count $spaces 0 {#} $value {.} [expr $max_count-$value]] $value"
            }
        }
    }

    # Slack histogram
    proc gf_report_histogram_slack {collection {spaces 100} {bins 25} {cut_ratio 0.0}} {
        set values [get_db $collection .slack]

        puts "# Slack histogram ([llength $values] values)"
        gf_report_histogram $values $spaces $bins $cut_ratio; puts ""
    }

    # Path delay histogram
    proc gf_report_histogram_delay {collection {spaces 100} {bins 25} {cut_ratio 0.0}} {
        set values [get_db $collection .path_delay]

        puts "# Path delay histogram ([llength $values] values)"
        gf_report_histogram $values $spaces $bins $cut_ratio; puts ""
    }

    # Clock skew histogram
    proc gf_report_histogram_skew {collection {spaces 100} {bins 25} {cut_ratio 0.0}} {
        set values [get_db $collection .skew]
        
        puts "# Clock skew histogram ([llength $values] values)"
        gf_report_histogram $values $spaces $bins $cut_ratio; puts ""
    }

    # Worst manhattan net length histogram
    proc gf_report_histogram_worst_manhattan_length {collection {spaces 100} {bins {0 10 20 30 50 80 130 210 340 550 890 1440 2330}} {cut_ratio 0.0}} {
        set values [get_db $collection .worst_manhattan_length]

        puts "# Worst manhattan net length histogram ([llength $values] values)"
        gf_report_histogram $values $spaces $bins $cut_ratio; puts ""
    }

    # Worst cell delay histogram
    proc gf_report_histogram_worst_cell_delay {collection {spaces 100} {bins 25} {cut_ratio 0.0}} {
        set values [get_db $collection .worst_cell_delay]
        
        puts "# Worst cell delay histogram ([llength $values] values)"
        gf_report_histogram $values $spaces $bins $cut_ratio; puts ""
    }

    # Data path transition histogram
    proc gf_report_histogram_slew {collection {spaces 100} {bins 25} {cut_ratio 0.0}} {
        set values {}
        foreach_in_collection timing_path $collection {
            lappend values [get_db $timing_path .timing_points.slew]
        }
        set values [eval "concat $values"]
        
        puts "# Data path transition histogram ([llength $values] values)"
        gf_report_histogram $values $spaces $bins $cut_ratio; puts ""
    }

    # Data path histogram
    proc gf_report_histogram_datapath {collection {spaces 100} {bins 25} {cut_ratio 0.0}} {
        set values {}
        foreach_in_collection timing_path $collection {
            lappend values [llength [get_db $timing_path .timing_points]]
        }

        puts "# Data path histogram ([llength $values] values)"
        gf_report_histogram $values $spaces $bins $cut_ratio; puts ""
    }

    # IR-drop histogram
    proc gf_report_histogram_ivdd {{spaces 100} {bins 25} {cut_ratio 0.0}} {
        set values {}
        foreach inst [get_db insts] {
            lappend values [lindex [get_db $inst .rail_domain_voltage_drop] 3]
        }
        gf_report_histogram $values $spaces $bins $cut_ratio; puts ""
    }
    
    # Interactive IR-drop histogram
    proc gf_report_histogram_ivdd_gui {{spaces 100} {bins 25} {cut_ratio 0.0}} {
        set values {}
        foreach inst [get_obj_in_area -obj_type inst -area [gui_get_box]] {
            lappend values [lindex [get_db $inst .rail_domain_voltage_drop] 3]
        }
        gf_report_histogram $values $spaces $bins $cut_ratio; puts ""
    }
    
    # Report timing paths in groups
    proc gf_report_timing_groups {args} {
        set command "report_timing -collection $args"
        redirect paths.txt {
            foreach_in_collection path [eval $command] {
                set launching_pin [get_db $path .launching_point]
                if {[get_db $launching_pin] .obj_type==pin} {set launching_pin [lindex [get_db $path .timing_points.pin] 1]}
                puts "[get_db $path .slack]\t[get_db $path .path_delay]\t[get_db $launching_pin .name]\t[get_db $path .capturing_point.name]"
            }
        }
        puts [exec cat paths.txt | perl -e {
            my %paths; my %slacks;
            while (<STDIN>) {
                if (/^(\-?\d*\.?\d+)\t(\-?\d*\.?\d+)\t([^\t]+)\t([^\t]+)$/) {
                    my $slack = $1 * 1000;
                    my $delay = $2 * 1000;
                    my $from = $3; 
                    my $to = $4;

                    $from =~ s/\d+/\*/g;
                    $to =~ s/\d+/\*/g;

                    my $id = $from.":".$to;
                    $paths{$id}{F} = $from;
                    $paths{$id}{T} = $to;
                    $paths{$id}{count}++;
                    $paths{$id}{min} = $slack if (!defined $paths{$id}{min} || ($slack < $paths{$id}{min}));
                    $paths{$id}{max} = $slack if (!defined $paths{$id}{max} || ($slack > $paths{$id}{max}));
                    $paths{$id}{dmin} = $delay if (!defined $paths{$id}{dmin} || ($delay < $paths{$id}{dmin}));
                    $paths{$id}{dmax} = $delay if (!defined $paths{$id}{dmax} || ($delay > $paths{$id}{dmax}));
                }
            }
            my $count; my $limit = 10;
            $count = 0; 
            print "\e[32;42m \e[0m Worst $limit groups sorted by slack\n\n";
            foreach my $id (sort {$paths{$a}{min}<=>$paths{$b}{min}} keys %paths) {
                my @path_slacks = (sort {$a<=>$b} @{$paths{$from}{$to}{slacks}});
                print sprintf("\e[34;44m \e[0m Group %d: slack %0.0f .. %0.0f ps, delay %0.0f .. %0.0f ps, \e[1m%d\e[0m paths\n  %s\n  %s\n", ++$count, $paths{$id}{min}, $paths{$id}{max}, $paths{$id}{dmin}, $paths{$id}{dmax}, $paths{$id}{count}, $paths{$id}{F}, $paths{$id}{T});
                last if ($count == $limit);
            }
            $count = 0;
            print "\e[32;42m \e[0m Worst $limit groups sorted by paths count\n\n";
            foreach my $id (sort {$paths{$b}{count}<=>$paths{$a}{count}} keys %paths) {
                my @path_slacks = (sort {$a<=>$b} @{$paths{$from}{$to}{slacks}});
                print sprintf("\e[34;44m \e[0m Group %d: slack %0.0f .. %0.0f ps, delay %0.0f .. %0.0f ps, \e[1m%d\e[0m paths\n  %s\n  %s\n", ++$count, $paths{$id}{min}, $paths{$id}{max}, $paths{$id}{dmin}, $paths{$id}{dmax}, $paths{$id}{count}, $paths{$id}{F}, $paths{$id}{T});
                last if ($count == $limit);
            }
        }]
        rm paths.txt
    }
'

# ECO automation procedures
gf_create_step -name innovus_procs_eco_common '

    # Get design parts to highlight
    proc gf_get_hinsts_to_highlight {{hinst {}} {threshold 0}} {
        if {$hinst == ""} {set hinst [get_db current_design]}

        # Highlight if threshold crossed
        if {$threshold <= 0} {set threshold [expr [get_db $hinst .area]/100]}
        if {$threshold < 1} {set threshold [expr [get_db $hinst .area]*$threshold]}
        
        # Check if childs are bigger than threshold
        set results {}
        if {[get_db $hinst .area] >= $threshold} {

            # Check childs
            foreach child [get_db $hinst .hinsts] {
                set results [concat $results [gf_get_hinsts_to_highlight $child $threshold]]
            }
            
            # Current hinst should b highlighted
            if {$results == {}} {
                set results $hinst
            }
        }
        
        return $results
    }

    # Highlight parts of the design
    proc gf_gui_highlight_design_parts {{area_threshold 0}} {
        get_db -u [gf_get_hinsts_to_highlight [get_db current_design] $area_threshold] -foreach { gui_highlight -auto_color $object }
    }
    
    # Select power vias with DRC based on the marker
    proc gf_select_follow_pin_vias_near_drc_markers {} {
        get_db current_design .markers -foreach {
            set line1 [lindex [get_db $object .bbox] 0]
            set line2 [list [lindex $line1 0] [lindex $line1 3] [lindex $line1 2] [lindex $line1 1]]
            gui_select -append -line $line1
            gui_select -append -line $line2
            deselect_obj [get_db selected -if .obj_type!=special_via]
        }
    }

    # Select vias of the same tipe as selected
    proc gf_select_same_vias {} {
        set selected_vias [get_db selected -if .obj_type==special_via]
        set modified_vias {}
        foreach via_def [get_db $selected_vias .via_def -u] {
            puts "\033\[42m \033\[0m Processing $via_def"
            foreach net [get_db $selected_vias .net -u] {
                puts "   \033\[42m \033\[0m Processing $net"
                set modified_vias [concat $modified_vias [get_db $net .special_vias -if .via_def==$via_def]]
            }
        }
        puts "   \033\[43m \033\[0m Total [llength $modified_vias] vias to modify"
        deselect_obj -all
        select_obj $modified_vias
        gui_highlight $modified_vias
    }

    # Scale via height for selected vias types
    proc gf_scale_same_vias {scalex scaley} {
        set selected_vias [get_db selected -if .obj_type==special_via]
        set modified_vias {}
        foreach via_def [get_db $selected_vias .via_def -u] {
            puts "\033\[42m \033\[0m Processing $via_def"
            foreach net [get_db $selected_vias .net -u] {
                puts "   \033\[42m \033\[0m Processing $net"
                set modified_vias [concat $modified_vias [get_db $net .special_vias -if .via_def==$via_def]]
            }
        }
        puts "   \033\[43m \033\[0m Total [llength $modified_vias] vias to modify"
        deselect_obj -all
        select_obj $modified_vias
        gui_highlight $modified_vias
        update_power_vias -selected_vias 1 -update_vias 1 -via_scale_height $scaley
        deselect_obj -all
    }

    # Get via objects under specified DRC marker
    proc gf_get_vias_by_marker {via_layer marker_type} {
        upvar vias vias
        upvar markers markers
        set vias {}
        set vias_next {}
        set markers {}
        set markers_next {}
        set counter 0
        foreach marker [get_db current_design .markers -if .user_type==$marker_type||.subtype==$marker_type] {
            set found_vias [get_db [get_obj_in_area -obj_type special_via -area [get_db $marker .bbox]] -if .via_def.cut_layer.name==$via_layer]
            if {$found_vias != {}} {
                set vias_next [concat $vias_next $found_vias]
                lappend markers_next $marker
            }
            incr counter
            if {[expr $counter % 10000] == 0} {
                puts "\033\[44m \033\[0m $counter markers processed ..."
                set vias [concat $vias $vias_next]
                set markers [concat $markers $markers_next]
                set vias_next {}
                set markers_next {}
            }
        }
        set vias [get_db -u [concat $vias $vias_next]]
        set markers [get_db -u [concat $markers $markers_next]]
        puts "\033\[44m \033\[0m Total [llength $markers] markers found. See \$markers variable."
        puts "\033\[44m \033\[0m Total [llength $vias] vias found. See \$vias variable"
        return $vias
    }
    
    # Get instances under specified DRC marker
    proc gf_get_insts_by_marker {cell_pattern marker_type} {
        upvar insts insts
        upvar markers markers
        set insts {}
        set insts_next {}
        set markers {}
        set markers_next {}
        set counter 0
        foreach marker [get_db current_design .markers -if .user_type==$marker_type||.subtype==$marker_type] {
            set found_insts [get_db [get_obj_in_area -obj_type inst -area [get_db $marker .bbox]] -if .base_cell.name==$cell_pattern]
            if {$found_insts != {}} {
                set insts_next [concat $insts_next $found_insts]
                lappend markers_next $marker
            }
            incr counter
            if {[expr $counter % 10000] == 0} {
                puts "\033\[44m \033\[0m $counter markers processed ..."
                set insts [concat $insts $insts_next]
                set markers [concat $markers $markers_next]
                set insts_next {}
                set markers_next {}
            }
        }
        set insts [get_db -u [concat $insts $insts_next]]
        set markers [get_db -u [concat $markers $markers_next]]
        puts "\033\[44m \033\[0m Total [llength $markers] markers found. See \$markers variable."
        puts "\033\[44m \033\[0m Total [llength $insts] insts found. See \$insts variable"
        return $insts
    }
    
    # Get routes under specified DRC marker
    proc gf_get_routes_by_marker {route_layer marker_type {shape stripe}} {
        upvar routes routes
        upvar markers markers
        set routes {}
        set routes_next {}
        set markers {}
        set markers_next {}
        set counter 0
        foreach marker [get_db current_design .markers -if .user_type==$marker_type] {
            set found_routes [get_db [get_obj_in_area -obj_type special_wire -area [get_db $marker .bbox]] -if .shape==$shape&&.layer.name==$route_layer]
            if {$found_routes != {}} {
                set routes_next [concat $routes_next $found_routes]
                lappend markers_next $marker
            }
            incr counter
            if {[expr $counter % 10000] == 0} {
                puts "\033\[44m \033\[0m $counter markers processed ..."
                set routes [concat $routes $routes_next]
                set markers [concat $markers $markers_next]
                set routes_next {}
                set markers_next {}
            }
        }
        set routes [get_db -u [concat $routes $routes_next]]
        set markers [get_db -u [concat $markers $markers_next]]
        puts "\033\[44m \033\[0m Total [llength $markers] markers found. See \$markers variable."
        puts "\033\[44m \033\[0m Total [llength $routes] routes found. See \$routes variable"
        return $routes
    }
    
    # Update vias applying user command
    proc gf_update_vias {vias {command {puts [llength [get_db selected]]}}} {
        gui_highlight $vias
        set changes {}
        foreach via_def [get_db $vias .via_def -u] {
            lappend changes [list $via_def [get_db $vias -if .via_def==$via_def]]
        }
        foreach change $changes {
            set via_def [lindex $change 0]
            set current_vias [lindex $change 1]
            puts "\033\[42m \033\[0m Processing [llength $current_vias] vias of $via_def ([get_db $via_def .cut_rows]x[get_db $via_def .cut_columns], [get_db $via_def .top_rects_mask.length]x[get_db $via_def .top_rects_mask.width]) ..."
            deselect_obj -all
            select_obj $current_vias
            eval $command
            puts {}
        }
        deselect_obj -all
    }
    
    # Create port objects covering selected pin shapes
    proc gf_create_ports_at_selected_pins {} {
        set_db assign_pins_edit_in_batch true
        foreach pin [get_db selected -if {.obj_type==pg_pin||.obj_type==pin}] {
        
            set port [lindex [get_db -u [concat [get_db $pin .net.drivers] [get_db $pin .net.loads] [get_db ports [get_db $pin .net.name]]] -if .obj_type==port] 0]
            if {$port == {}} {
                puts "\033\[41m \033\[0m No ports connected to pin [get_db $pin .name]"

            } else {
                puts "\033\[42m \033\[0m Pin [get_db $pin .name] connected to port [get_db $port .name]"
                if {[get_db $pin .obj_type] == {pg_pin}} {
                    foreach shape [get_db $pin .pg_base_pin.physical_pins.layer_shapes] {
                        set rect [lindex [get_transform_shapes -inst [get_db $pin .inst.name] -local_pt [get_db $shape .shapes.rect]] 0]
                        set command "create_pg_pin -geometry [get_db $shape .layer.name] $rect -name {[get_db $port .name]} -net {[get_db $port .net.name]}"
                        puts "   \033\[44m \033\[0m $command"
                        eval $command
                    }
                } else {
                    set command "edit_pin -layer [get_db $pin .layer.name] -assign [get_db $pin .location] -pin {[get_db $port .name]} -fixed_pin 1 -global_location -side inside -snap mgrid"
                    puts "   \033\[44m \033\[0m $command"
                    eval $command
                }
            }
        }
        set_db assign_pins_edit_in_batch false
    }

    # Create port objects inside selected bumps
    proc gf_create_ports_at_selected_bumps {} {
        set_db assign_pins_edit_in_batch true
        foreach bump [get_db selected -if {.obj_type==bump}] {
        
            set port [lindex [get_db -u [concat [get_db $bump .net.drivers] [get_db $bump .net.loads] [get_db ports [get_db $bump .net.name]]] -if .obj_type==port] 0]
            if {$port == {}} {
                puts "\033\[41m \033\[0m No ports connected to bump [get_db $bump .name]"

            } else {
                puts "\033\[42m \033\[0m Bump [get_db $bump .name] connected to port [get_db $port .name]"
                if {[get_db $bump .net.is_power] || [get_db $bump .net.is_ground] } {
                    set radius [expr "[get_db $bump .bbox.width] * 0.25"]
                    set rect [list [expr [get_db $bump .center.x] - $radius] [expr [get_db $bump .center.y] - $radius] [expr [get_db $bump .center.x] + $radius] [expr [get_db $bump .center.y] + $radius]]
                    set command "create_pg_pin -geometry [lindex [get_db $bump .base_cell.base_pins.layer.name] 0] $rect -name {[get_db $port .name]} -net {[get_db $port .net.name]}"
                    puts "   \033\[44m \033\[0m $command"
                    eval $command
                } else {
                    set command "edit_pin -layer [lindex [get_db $bump .base_cell.base_pins.layer.name] 0] -assign [get_db $bump .center] -pin {[get_db $port .name]} -fixed_pin 1 -global_location -side inside -snap mgrid"
                    puts "   \033\[44m \033\[0m $command"
                    eval $command
                }
            }
        }
        set_db assign_pins_edit_in_batch false
    }

    # Print wire statistic 
    proc gf_print_net_wire_statistic {pins net layer} {
        set wires [concat [get_db $net .special_wires -if .layer.name==$layer] [get_db $net .wires -if .layer.name==$layer]]
        if {[llength $pins] > 0} {
            set layer_pins [concat \
                [get_db [get_db $pins -if .obj_type==pg_pin] -if .pg_base_pin.physical_pins.layer_shapes.layer.name==$layer] \
                [get_db [get_db $pins -if .obj_type==pin] -if .base_pin.physical_pins.layer_shapes.layer.name==$layer] \
            ]
            if {[llength $layer_pins] > 0} {
                puts "  \033\[43m \033\[0m[format {%5s} $layer] [llength $layer_pins] {[get_db -u $layer_pins .obj_type]}"
                select_obj $layer_pins
            }
        }
        if {[llength $wires] == 0} {
            puts "  \033\[44m \033\[0m[format {%5s} $layer] 0"
        } else {
            puts "  \033\[46m \033\[0m[format {%5s} $layer] [llength $wires] {[get_db -u $wires .shape]} {[get_db -u $wires .status]} {[get_db -u $wires .obj_type]}"
        }
    }

    # Print via statistic 
    proc gf_print_net_via_statistic {net layer {threshold {}}} {
        set vias [concat [get_db $net .special_vias -if .via_def.cut_layer.name==$layer] [get_db $net .vias -if .via_def.cut_layer.name==$layer]]
        if {[llength $vias] == 0} {
            puts "  \033\[44m \033\[0m[format {%5s} $layer] 0"
        } else {
            set cuts 0
            foreach via $vias {
                set cuts [expr $cuts + [get_db $via .via_def.cut_rows] * [get_db $via .via_def.cut_columns]]

            }
            if {$threshold == {}} {
                    puts "  \033\[46m \033\[0m[format {%5s} $layer] [llength $vias] ($cuts) {[get_db -u $vias .shape]} {[get_db -u $vias .status]}"
            } elseif {$cuts < $threshold} {
                    puts "  \033\[41m \033\[0m[format {%5s} $layer] [llength $vias] ($cuts) {[get_db -u $vias .shape]} {[get_db -u $vias .status]}"
            } else {
                    puts "  \033\[42m \033\[0m[format {%5s} $layer] [llength $vias] ($cuts) {[get_db -u $vias .shape]} {[get_db -u $vias .status]}"
            }
        }
        
    }

    # Add vias for the nets identified after last statistic
    proc gf_add_net_vias {layer_bottom layer_top args} {
        upvar gf_show_net_statistic_pads gf_show_net_statistic_pads
        upvar gf_show_net_statistic_nets gf_show_net_statistic_nets
        set command "update_power_vias -nets {[get_db $gf_show_net_statistic_nets .name]} -bottom_layer $layer_bottom -top_layer $layer_top -add_vias 1 -skip_via_on_wire_status routed -orthogonal_only 0 $args"
        puts "\033\[44m \033\[0m $command"
        eval $command
        gf_show_net_statistic
    }
    
    # Re-create vias for specified nets
    proc gf_fix_power_via {nets layer_bottom layer_top} {
        update_power_vias -nets $nets -bottom_layer $layer_bottom -top_layer $layer_top -delete_vias 1
        update_power_vias -nets $nets -bottom_layer $layer_bottom -top_layer $layer_top -add_vias 1 
    }

    # Report clock relations with constrained paths betweeen clocks
    proc gf_report_interclock_relation {} {
        set clocks [get_clocks]
        set result {}
        lappend result "---------------------------------------------------"
        lappend result "Clock relations (clock_from -> clock_to)"
        lappend result "---------------------------------------------------"
        foreach clock_from [get_db clocks] {
            foreach clock_to [get_db clocks] {
                if {[llength [report_timing -from $clock_from -to $clock_to -collection]] > 0} {
                    lappend result [format "%20s -> %20s" [get_db $clock_from .name] [get_db $clock_to .name]]
                }
            }
        }
        puts [join $result "\n"]
    }

    # Report inputs not connected to the uotput pins
    proc gf_report_floating_gates {} {
        set results {}
        get_db [get_db nets -if .num_drivers==0&&!.is_ground&&!.is_power] .loads -foreach {lappend results $object}
        get_db -u $results -foreach {puts $object}
    }

    # Report flop fanout in the current design
    proc gf_report_flop_fanout {{insts {}} {limit 100}} {
        if {$insts == {}} {set insts [get_db insts -if .is_sequential]}
        foreach inst $insts {
            if {[get_db $inst .obj_type] == "inst"} { 
                if {[get_db $inst .is_sequential] == true} { 
                    set count 0
                    foreach pin [get_db $inst .pins -if .direction==out] {
                        set count [expr $count + [sizeof_collection [all_fanout -from [get_db $pin .name] -endpoints_only]]]
                    }
                    if {$count >= [expr $limit * 5]} {
                        print "\033\[41m \033\[0m $count [get_db $inst .name]"
                    } elseif {$count > [expr $limit * 2]} {
                        print "\033\[43m \033\[0m $count [get_db $inst .name]"
                    } elseif {$count >= $limit} {
                        print "\033\[42m \033\[0m $count [get_db $inst .name]"
                    }
                }
            }
        }
    }
    

    # Write out insts statistics matching pattern per hinst
    proc gf_report_hinst_pattern_statistics {file pattern {depth 5} {threshold 10}} {
        puts "\033\[36;46m \033\[0m Creating $file ..."
        
        # Statistics collection
        proc gf_report_hinst_pattern_statistics_recursive {hinst pattern depth tab threshold} {
            if {$depth>0} {
                set num_insts [llength [set insts [get_db $hinst .insts]]]
                if {[set num_matched [llength [eval "get_db \$insts $pattern"]]] >= $threshold} {
                    puts "$tab:[format {%3.0f%%} [expr 100.0*$num_matched/$num_insts]] = [format {%6d / %-6d} $num_matched $num_insts] [get_db $hinst .name] ([get_db $hinst .module.name])"
                    foreach hinst [get_db $hinst .local_hinsts] {
                        gf_report_hinst_pattern_statistics_recursive $hinst $pattern [expr $depth-1] "$tab  " $threshold
                    }
                }
            }
        }
        
        # Report generation
        redirect $file {
            set num_insts [llength [set insts [get_db current_design .insts]]]
            set num_matched [llength [eval "get_db \$insts $pattern"]]
            puts "[format {%3.0f%%} [expr 100.0*$num_matched/$num_insts]] $pattern = [format {%6d / %-6d} $num_matched $num_insts] [get_db current_design .name]"
            foreach hinst [get_db current_design .local_hinsts] {
                gf_report_hinst_pattern_statistics_recursive $hinst $pattern $depth "  " $threshold
            }
        }
    }
    
    # Fix glitches manually
    proc modify_net {name} {
        deselect_obj -all
        select_obj net:$name
        gui_zoom -selected
    }
    proc gf_eco_split_selected_net {buffer_cell} {
        set net [get_db selected -if .obj_type==net]
        if {[llength $net] == 1} {
            set result [eco_add_repeater -net [get_db $net .name] -cells $buffer_cell -relative_distance_to_sink 0.5]
            gui_highlight inst:[lindex $result 0]
        }
    }
'

################################################################################
# Data out steps
################################################################################

# Data out gift procedures
gf_create_step -name innovus_procs_write_data '
  
    # Write out hcell file
    proc gf_write_hcell {file} {
        set FH [open $file w]
        foreach cell [get_db -u insts .base_cell.name] {
            puts $FH "$cell $cell"
        }
        close $FH
    }

    # Write out pin locations
    proc gf_write_pin_locations {file} {
        set FH [open $file w]
        foreach port [concat [get_db ports] [get_db ports [concat [get_db init_power_nets] [get_db init_ground_nets]]]] {
            set shapes [get_db $port .physical_pins.layer_shapes]
            set bumps [get_db bumps -if .net==[get_db $port .net]]
            if {($shapes == {}) && ($bumps == {})} {
                puts "\033\[41m \033\[0m Port [get_db $port .name] does not have layer shapes"
            } else {
                puts "\033\[42m \033\[0m Port [get_db $port .name]"
                foreach shape $shapes {
                    foreach rect [get_db $shape .shapes.rect] {
                        set x [format %.3f [expr ([lindex $rect 0] + [lindex $rect 2])/2]]
                        set y [format %.3f [expr ([lindex $rect 1] + [lindex $rect 3])/2]]
                        puts "  \033\[44m \033\[0m [get_db $shape .layer.name] $x $y"
                        puts $FH "LAYOUT TEXT \"[get_db $port .name]\" $x $y [get_db $shape .layer.name] [get_db current_design .name]"
                    }
                }
                foreach bump $bumps {
                    puts "  \033\[44m \033\[0m [get_db $bump .base_cell.base_pins.layer.name] [get_db $bump .center.x] [get_db $bump .center.y]"
                    puts $FH "LAYOUT TEXT \"[get_db $port .name]\" [get_db $bump .center.x] [get_db $bump .center.y] [get_db $bump .base_cell.base_pins.layer.name] [get_db current_design .name]"
                }
            }
        }
        close $FH
    }

    # Write out current sources coordinates
    proc gf_write_current_sources_locations {file_base_name {pitch 0.0}} {
        if {[catch {set pitch [expr 0.0+$pitch]}]} {set pitch 0.0} 
        set total_counter 0
        
        # Calculate locations for each power and ground net
        foreach net [concat [get_db init_power_nets] [get_db init_ground_nets]] {
            set locations {}

            # Based on PG pins coordinates
            if {[llength [set shapes [get_db [get_db ports $net] .physical_pins.layer_shapes]]]} {

                # Detect top layer        
                set layers [get_db $shapes .layer -u]
                set top_layer_name [get_db [lindex $layers 0] .name]
                set top_layer_index [get_db [lindex $layers 0] .route_index]
                foreach layer $layers {
                    if {[get_db $layer .route_index] > $top_layer_index} {
                        set top_layer_name [get_db $layer .name]
                        set top_layer_index [get_db $layer .route_index]
                    }
                }
                
                # Detect locations based on top layer pins
                foreach shape [get_db [get_db $shapes -if .layer.name==$top_layer_name] .shapes] {

                    # Distribute locations with specified pitch
                    if {$pitch>0.0} {
                        set x_length [expr abs([get_db $shape .rect.ur.x]-[get_db $shape .rect.ll.x])]
                        set y_length [expr abs([get_db $shape .rect.ur.y]-[get_db $shape .rect.ll.y])]
                        
                        # Horizontal
                        if {$x_length>$y_length} {
                            set x [expr [get_db $shape .rect.ll.x]+$pitch*abs($x_length/$pitch-int($x_length/$pitch))/2]
                            set y [expr ([get_db $shape .rect.ur.y]+[get_db $shape .rect.ll.y])/2]
                            
                            # Add locations
                            while {$x<[get_db $shape .rect.ur.x]} {
                                lappend locations "$x $y"
                                set x [expr $x+abs($pitch)]
                            }
                        
                        # Vertical
                        } else {
                            set x [expr ([get_db $shape .rect.ur.x]+[get_db $shape .rect.ll.x])/2]
                            set y [expr [get_db $shape .rect.ll.y]+$pitch*abs($y_length/$pitch-int($y_length/$pitch))/2]
                            
                            # Add locations
                            while {$y<[get_db $shape .rect.ur.y]} {
                                lappend locations "$x $y"
                                set y [expr $y+abs($pitch)]
                            }
                        }
                    
                    # Pin ends
                    } else {
                        lappend locations "[get_db $shape .rect.ll.x] [get_db $shape .rect.ll.y]"
                        lappend locations "[get_db $shape .rect.ur.x] [get_db $shape .rect.ur.y]"
                    }
                }
             
            # Based on upper layer via coordinates
            } else {

                # Detect top layer        
                set vias [get_db [get_db nets $net] .special_vias]
                set layers [get_db $vias .via_def.top_layer -u]
                set top_layer_name [get_db [lindex $layers 0] .name]
                set top_layer_index [get_db [lindex $layers 0] .route_index]
                foreach layer $layers {
                    if {[get_db $layer .route_index] > $top_layer_index} {
                        set top_layer_name [get_db $layer .name]
                        set top_layer_index [get_db $layer .route_index]
                    }
                }
                
                # Detect locations based on top layer vias
                foreach via [get_db $vias -if .via_def.top_layer.name==$top_layer_name] {
                    lappend locations [list \
                        [get_db $via .point.x] \
                        [get_db $via .point.y] \
                    ]
                }
            }
            
            # Write locations to file
            puts "Writing $file_base_name.$net.pp - [llength $locations] locations"
            set FH [open "$file_base_name.$net.pp" w]
            set counter 0
            foreach location $locations {
                incr total_counter
                incr counter
                puts $FH "${net}_${top_layer_name}_$counter [lindex $location 0] [lindex $location 1] $top_layer_name"
            }
            close $FH
        }
        puts "\n\033\[42m \033\[0m Total $total_counter locations written"
    }
'

################################################################################
# Gift steps
################################################################################

# Check if design contains cells with missing LIB/LEF data
gf_create_step -name innovus_check_missing_cells '
    set missing_cells [get_db -u [get_db hinsts -if .area==0&&.hinsts==""] .module.name]
    if {$missing_cells == {}} {
        puts "\033\[42m \033\[0m No missing cells found"
    } else {
        puts "\033\[44m \033\[0m Set variable below in ../block.search.gf and run ./files.search.gf to look for required files on disk.\n"
        puts "GF_SEARCH_CELLS='"'"'\n    [join $missing_cells "\n    "]\n'"'"'\n"
        puts "\033\[41m \033\[0m Total [llength $missing_cells] missing cells found.\n"
        sleep 5
    }
'

# Common level procs
gf_create_step -name innovus_procs_db '

    # Write incremental database with unique name each 10 minutes
    set gf_db_date 0
    set gf_db_index 1
    proc gf_write_db {{tag {}}} {
        upvar gf_db_date gf_db_date
        upvar gf_db_index gf_db_index
        set base "./out/[regsub {^Debug} $::TASK_NAME {}]"
        if {$tag == {}} {
            if {($gf_db_date == 0) || ([expr [exec date +%s] - $gf_db_date] > 600)} {
                set gf_db_date [exec date +%s]
                while {[file exists $base.$gf_db_index.innovus.db]} {incr gf_db_index}
            }
            set tag $gf_db_index
        }
        puts "\033\[42m \033\[0m Writing database $base.$tag.innovus.db ..."
        write_db $base.$tag.innovus.db
    }
    
    # Write floorplan with unique name each 10 minutes
    set gf_fp_date 0
    set gf_fp_index 1
    proc gf_write_floorplan_local {{tag {}}} {
        upvar gf_fp_date gf_fp_date
        upvar gf_fp_index gf_fp_index
        set base "./out/$::TASK_NAME"
        if {$tag == {}} {
            if {($gf_fp_date == 0) || ([expr [exec date +%s] - $gf_fp_date] > 600)} {
                set gf_fp_date [exec date +%s]
                while {[file exists $base.$gf_fp_index.fp]} {incr gf_fp_index}
            }
            set tag $gf_fp_index
        }
        puts "\033\[42m \033\[0m Writing floorplan $base.$tag.fp ..."
        write_floorplan $base.$tag.fp
        set ::FLOORPLAN_FILE_LAST $base.$tag.fp
    }

    # Read floorplan and fix macros
    proc gf_read_and_fix_floorplan {{FLOORPLAN_FILE {}}} {
        if {$FLOORPLAN_FILE == ""} {
            set FLOORPLAN_FILE $::FLOORPLAN_FILE_LAST
        }
    
        # Macros detection
        get_db ports .name -foreach {puts $object} > fix_floorplan.txt
        get_db [get_db insts -if .area>100&&.base_cell.site==""] .name -foreach {puts $object} >> fix_floorplan.txt

        # Copy floorplan files to current directory
        eval "cp -v [glob $FLOORPLAN_FILE*] ."

        # Fix floorplan
        exec cat $FLOORPLAN_FILE | perl -e {
            my %expr;
            open FILE, "fix_floorplan.txt";
            while (<FILE>) {
                s/^\s+//;
                s/\s+$//;
                next if ($_ eq "");
                my $correct = $_;

                s|[\/\_\[\]]|[\/\_\\[\\]]|g;
                $expr{$_} = $correct;
                
                # print STDERR $_."\n";
                # print STDERR $correct."\n";
            }
            close FILE;

            my $data = "";
            $data .= $_ while (<STDIN>);
            foreach my $from (keys %expr) {
                my $to = $expr{$from};
                $data =~ s|$from|$to|gem;
            }

            print $data;
        } > fix_floorplan.fp

        # Read fixed floorplan
        read_floorplan fix_floorplan.fp
    }
    
    # Print last comnands
    proc gf_last_commands {} {
        ls -1tr ../../../*/tasks/*/*.logv* | tail -7 | perl -e {
            my %command;
            while (<STDIN>) {
                s/\s+$//;
                if (open FILE, $_) {
                    while (<FILE>) {
                        if (s/^\[(\d\d\/\d\d \d\d:\d\d:\d\d)\s+\w+\]\s*//) {
                            my $command_time = $1;
                            $commands{$command_time} = $_ if (s/^\@\w+\s+\d+\>\s//);
                        }
                    }
                    close FILE;
                }
            }
            my @command_times = sort keys %commands;
            my $i=0; $i = $#command_times - 20 if ($#command_times >= 20);
            while (
                $i <= $#command_times
            ) {
                print $commands{$command_times[$i]};
                $i++;
            }
        }
    }

    # Read global variables from database
    namespace eval gf_globals {
        variable commands {}
        proc setUserDataValue {global_name value} {
            lappend gf_globals::commands [list $global_name $value]
        }
        proc set {global_name value} {
            setUserDataValue $global_name $value
            rename set set_local
            uplevel 1 "set $global_name {$value}"
            rename set_local set
        }
        proc set_global {global_name value} {setUserDataValue $global_name $value}
        proc read {database_or_globals} {
            rename set set_local
            set gf_globals::commands {}
            set globals $database_or_globals
            if {[file isdirectory $database_or_globals]} {
                set globals [lindex [glob $database_or_globals/*.globals] 0]
            }
            rename set_local set
            source $globals
            llength $gf_globals::commands
        }
        proc get {global_name} {
            rename set set_local
            set index [lsearch $gf_globals::commands "$global_name *"]
            rename set_local set
            if {$index >= 0} {
                lindex $gf_globals::commands $index 1
            } else {
                error "Global $global_name is not defined"
            }
        }
        proc get_all {} {
            rename set set_local
            set result {}
            rename set_local set
            foreach command $gf_globals::commands {
                lappend result [lindex $command 0]
            }
            return $result
        }
        proc show {} {
            foreach command $gf_globals::commands {
                puts "\033\[44m \033\[0m [lindex $command 0] {[lindex $command 1]}"
            }
        }
    }
    proc gf_globals_read {database_or_globals} {gf_globals::read $database_or_globals}
    proc gf_globals_get {global_name} {gf_globals::get $global_name}
    proc gf_globals_get_all {} {gf_globals::get_all}
    proc gf_globals_show {} {gf_globals::show}
'

gf_create_step -name innovus_procs_fanin_fanout_magnify '
    # Procedures to browse fanin and fanout
    namespace eval gf {
    
        # Trace fanin and fanout pins
        proc get_fan_pins {args} {
            set from_objects {}
            set through_patterns {}
            set result_patterns {}
            set stop_patterns {}
            set max_depth 15
            set verbose 4

            # Fanin direction
            set from_dir "in"
            set to_dir "out"
            set to_type "drivers"

            # Parse command line
            set key "-from"
            foreach arg $args {

                # Keys
                if {[lsearch -exact {-from -to -through -patterns -stop -depth -verbose} $arg] != -1} {
                    set key $arg

                # Directions
                } elseif {$arg == {-fanin}} {
                        set from_dir "in"
                        set to_dir "out"
                        set to_type "drivers"
                } elseif {$arg == {-fanout}} {
                        set from_dir "out"
                        set to_dir "in"
                        set to_type "loads"

                # Incorrect key
                } elseif {[string match -* $arg]} {
                    puts "\033\[41m \033\[0m Incorrect $arg option."
                    return {}

                # Start objects
                } elseif {($key == {-from}) || ($key == {-to})} {
                    set from_objects [concat $from_objects $arg]

                # Trace-through pin patterns
                } elseif {$key == {-through}} {
                    set through_patterns [concat $through_patterns $arg]

                # Result pin patterns
                } elseif {$key == {-patterns}} {
                    set result_patterns [concat $result_patterns $arg]

                # Stop trace at pin patterns
                } elseif {$key == {-stop}} {
                    set stop_patterns [concat $stop_patterns $arg]

                # Verbose level
                } elseif {$key == {-verbose}} {
                    set verbose $arg
                    set key "-from"

                # Trace depth limit
                } elseif {$key == {-depth}} {
                    set max_depth $arg
                    set key "-from"
                }
            }

            # All pins to be returned by default
            if {$result_patterns=={}} {set result_patterns {*}}

            # Starting points should be provided
            if {$from_objects == {}} {
                puts "\033\[41m \033\[0m No objects to trace from found. Check -from option."
            }

            # Trace each starting point separately
            set results {}
            foreach object [get_db $from_objects] {

                # Starting pins
                if {$verbose > 0} {puts "\033\[44m \033\[0m Fan${from_dir} pins of $object ..."}
                if {[get_db $object .obj_type] == "port"} {
                    set pins [get_db $object .net.${to_type} -if .obj_type==pin]
                } elseif {[get_db $object .obj_type] == "net"} {
                    set pins [get_db $object .${to_type} -if .obj_type==pin]
                } elseif {[get_db $object .obj_type] == "pin"} {
                    set pins $object
                } else {
                    if {$verbose > 0} {puts " Unknown object type"}
                }

                # Trace the rest pins
                set processed_pins {}
                set counter 0
                set object_results {}
                while {($pins != {}) && ($counter < $max_depth)} {
                    incr counter
                    set next_pins {}

                    # Classify pins
                    foreach pin $pins {
                        set matched_through_pins {}
                        set matched_stop_pins {}
                        if {$through_patterns != {}} {set matched_through_pins [get_db $pin $through_patterns]}
                        if {$stop_patterns != {}} {set matched_stop_pins [get_db $pin $stop_patterns]}
                        #set matched_result_pins [get_db [get_db $pin -if .direction!=${from_dir}] $result_patterns]
                        set matched_result_pins [get_db $pin $result_patterns]

                        # Trace through
                        if {($pin == $object) || ($matched_through_pins != {}) && ($matched_stop_pins == {})} {
                            if {$counter == $max_depth} {
                                if {$verbose > 2} {puts "   \033\[43m \033\[0m $pin"}
                            } else {
                                if {$pin != $object} {
                                    if {$verbose > 3} {puts "   \033\[44m \033\[0m $pin"}
                                }
                                if {[get_db $pin .direction] != ${from_dir}} {
                                    lappend processed_pins $pin
                                    set next_pins [concat $next_pins [get_db $pin .inst.pins -if .direction!=${to_dir}]]
                                }
                                if {[get_db $pin .direction] != ${to_dir}} {
                                    lappend processed_pins $pin
                                    set next_pins [concat $next_pins [get_db $pin .net.${to_type} -if .obj_type==pin]]
                                }
                            }

                        # Stop at pin
                        } else {
                            lappend processed_pins $pin

                            # Result pin
                            if {$matched_result_pins != {}} {
                                lappend object_results $pin
                                if {$verbose > 0} {puts "   \033\[42m \033\[0m $pin"}

                            # Stop pin
                            } elseif {$matched_stop_pins != {}} {
                                if {$verbose > 1} {puts "   \033\[45m \033\[0m $pin"}

                            # Not classified pin
                            } else {
                                if {$verbose > 2} {puts "   \033\[46m \033\[0m $pin"}
                            }
                        }
                    }

                    # Filter the rest pins
                    set pins {}
                    foreach pin $next_pins {
                        if {[lsearch -exact $processed_pins $pin] == -1} {
                            lappend processed_pins $pin
                            lappend pins $pin
                        }
                    }
                }
                if {$object_results == {}} {
                    if {$verbose > 0} {puts "   \033\[41m \033\[0m No results found"}
                } else {
                    set results [concat $results $object_results]
                }
                if {$verbose > 0} {puts {}}
            }
            if {$verbose > 0} {puts {}}
            return [get_db -u $results]
        }

        # Magnify instances to the pins
        proc magnify_pin_fan_instances {args} {
            set results {}

            set pins {}
            set through_patterns {}
            set result_patterns {}
            set stop_patterns {}
            set max_depth 15
                set place_status {placed}
                set dont_touch {}
            set verbose 4

            # Parse command line
            set key "-pins"
            foreach arg $args {

                # Keys
                if {[lsearch -exact {-pins -through -patterns -stop -dont_touch -depth -verbose} $arg] != -1} {
                    set key $arg

                # Place status to set
                } elseif {$arg == {-placed}} {
                        set place_status placed
                } elseif {$arg == {-fixed}} {
                        set place_status fixed
                } elseif {$arg == {-soft_fixed}} {
                        set place_status soft_fixed

                # Incorrect key
                } elseif {[string match -* $arg]} {
                    puts "\033\[41m \033\[0m Incorrect $arg option."
                    return {}

                # Start objects
                } elseif {$key == {-pins}} {
                    set pins [concat $pins $arg]

                # Trace-through pin patterns
                } elseif {$key == {-through}} {
                    set through_patterns [concat $through_patterns $arg]

                # Result pin patterns
                } elseif {$key == {-patterns}} {
                    set result_patterns [concat $result_patterns $arg]

                # New created buffers status
                } elseif {$key == {-dont_touch}} {
                        set dont_touch $arg

                # Stop trace at pin patterns
                } elseif {$key == {-stop}} {
                    set stop_patterns [concat $stop_patterns $arg]

                # Verbose level
                } elseif {$key == {-verbose}} {
                    set verbose $arg
                    set key "-from"

                # Trace depth limit
                } elseif {$key == {-depth}} {
                    set max_depth $arg
                    set key "-from"
                }
            }

            # Options checks
            if {$pins == {}} {
                if {$verbose > 0} {puts "\033\[41m \033\[0m Option -pins is mandatory"}
                return {}
            }

            # Magnify instances to pins
            foreach pin $pins {
                if {$verbose > 0} {puts "\033\[44m \033\[0m Magnifying instances to $pin ..."}

                if {[get_db $pin .direction] == "in"} {
                    set inst_pins [gf::get_fan_pins -fanin -from $pin -through $through_patterns -patterns $result_patterns -stop $stop_patterns -verbose 0 -depth $max_depth]
                } elseif {[get_db $pin .direction] == "out"} {
                    set inst_pins [gf::get_fan_pins -fanout -from $pin -through $through_patterns -patterns $result_patterns -stop $stop_patterns -verbose 0 -depth $max_depth]
                } else {
                    if {$verbose > 0} {puts "   \033\[41m \033\[0m Cannot look for the instances in \"[get_db $pin .direction]\" direction."}
                }

                # Check for the instances
                if {$inst_pins == {}} {
                    if {$verbose > 0} {puts "   \033\[41m \033\[0m No instances found in \"[get_db $pin .direction]\" direction."}
                } else {
                    foreach inst_pin $inst_pins {
                        set inst [get_db $inst_pin .inst]
                        set orig_status [list [get_db $inst .dont_touch] [get_db $inst .place_status] [get_db $inst .location]]

                        place_inst $inst [get_db $pin .location]
                        set_db $inst .place_status $place_status
                        set_db $inst .dont_touch $dont_touch

                        set new_status [list [get_db $inst .dont_touch] [get_db $inst .place_status] [get_db $inst .location]]

                        set status {}
                        if {[lindex $orig_status 0] == [lindex $new_status 0]} {
                            append status " .dont_touch=[lindex $new_status 0]"
                        } else {
                            append status " .dont_touch=[lindex $orig_status 0]->[lindex $new_status 0]"
                        }
                        if {[lindex $orig_status 1] == [lindex $new_status 1]} {
                            append status " .place_status=[lindex $new_status 1]"
                        } else {
                            append status " .place_status=[lindex $orig_status 1]->[lindex $new_status 1]"
                        }
                        if {[lindex $orig_status 2] == [lindex $new_status 2]} {
                            append status " .location=[lindex $new_status 2]"
                        } else {
                            append status " .location=[lindex $orig_status 2]->[lindex $new_status 2]"
                        }
                        if {$orig_status == $new_status} {
                            if {$verbose > 1} {puts "   \033\[42m \033\[0m $inst"}
                        } else {
                            if {$verbose > 1} {puts "   \033\[43m \033\[0m $inst"}
                        }
                        if {$verbose > 3} {puts "       .base_cell=[get_db $inst .base_cell.name] .pin=[get_db $inst_pin .base_name]$status"}
                        lappend results $inst
                    }
                }
                if {$verbose > 0} {puts {}}
            }
            return $results
        }

    }

    catch {
        proc gf_get_fanin_pins {args} {eval "gf::get_fan_pins -fanin $args"}
        proc gf_get_fanout_pins {args} {eval "gf::get_fan_pins -fanout $args"}
        define_proc_arguments gf_get_fanin_pins -define_args {
            { -to "Objects to trace through" "" string required }
            { -patterns "Result pins patterns" "default is *" string optional }
            { -stop "Pins patterns to stop tracing at" "" string optional }
            { -through "Pins patterns to trace through" "" string optional }
            { -depth "Trace depth limit" "default is 15" integer optional}
            { -verbose "Verbosity level" "default is 4" integer optional }
        }
        define_proc_arguments gf_get_fanout_pins -define_args {
            { -from "Objects to trace through" "" string required }
            { -patterns "Result pins patterns" "default is *" string optional }
            { -stop "Pins patterns to stop tracing at" "" string optional }
            { -through "Pins patterns to trace through" "" string optional }
            { -depth "Trace depth limit" "default is 15" integer optional}
            { -verbose "Verbosity level" "default is 4" integer optional }
        }
    }

    catch {
        proc gf_magnify_pin_fan_instances {args} {eval "gf::magnify_pin_fan_instances $args"}
        define_proc_arguments gf_magnify_pin_fan_instances -define_args {
            { -pins "Pins to magnify to" "" string required }
            { -patterns "Result pins patterns" "default is *" string optional }
            { -stop "Pins patterns to stop tracing at" "" string optional }
            { -through "Pins patterns to trace through" "" string optional }
            { -depth "Instance trace depth limit" "default is 15" integer optional}
            { -placed "Place buffers and mark it as placed" "" boolean optional }
            { -fixed "Place buffers and mark it as fixed" "" boolean optional }
            { -soft_fixed "Place buffers and mark it as soft_fixed" "" boolean optional }
            { -dont_touch "Set instance dont touch status" "default is true" string fixed }
            { -verbose "Verbosity level" "default is 4" integer optional }
        }
    }
'

gf_create_step -name innovus_procs_add_buffers '
    # Procedures to add bufferization into the design
    namespace eval gf {

        # Add IO buffers and attach it to the ports
        proc attach_io_buffers {input_cell output_cell} {
            set not_io_buffers [get_db insts *_GF_io_buffer]
            add_io_buffers \
                -suffix _GF_io_buffer \
                -in_cells $input_cell \
                -out_cells $output_cell \
                -port -exclude_clock_nets \
                -status fixed

            # Get just added IO buffers
            set io_buffers {}
            foreach inst [get_db insts *_GF_io_buffer] {
                if {[lsearch -exact $not_io_buffers $inst] == -1} {
                    lappend io_buffers $inst
                }
            }

            # Fix IO buffers for placement and optimization
            foreach inst $io_buffers {
                set_db $inst .place_status fixed
                set_db $inst .dont_touch true
                puts "Added IO buffer \033\[97m[get_db $inst .name]\033\[0m: .dont_touch=[get_db $inst .dont_touch], .place_status=[get_db $inst .place_status]."
            }

            # Fix IO port nets
            set io_buffers_nets [get_db $io_buffers .pins.net]
            foreach net [get_db ports .net] {
                if {[lsearch -exact $io_buffers_nets $net] != -1} {
                    set_db $net .dont_touch true
                    puts "Port net \033\[97m[get_db $net .name]\033\[0m: .dont_touch=[get_db $net .dont_touch]."
                }
            }
        }

        # Add buffer cells to the endpoint to fix hold violations
        proc add_hold_buffers_to_endpoints {base_cell slack_threshold {max_paths 100}} {
            set results {}
            if {[get_db base_cells $base_cell] == {}} {
                puts "WARNING: Base cell $base_cell not found."

            } else {
                set timing_paths [report_timing -early -collection -max_slack $slack_threshold -max_paths $max_paths]

                if {[sizeof_collection $timing_paths] < 1} {
                    puts "WARNING: No hold violations with slack < $slack_threshold found."

                } else {
                    set last_prefix [get_db eco_prefix]
                    set last_honor_dont_use [get_db eco_honor_dont_use]

                    set_db eco_prefix GFH
                    set_db eco_honor_dont_use false

                    set_db eco_batch_mode true
                    foreach pin_name [get_db -u $timing_paths .capturing_point.name] {
                        lappend results [lindex [eco_add_repeater -pins $pin_name -cells $base_cell -relative_distance_to_sink 0.5] 0]
                    }
                    set_db eco_batch_mode false

                    set_db eco_honor_dont_use $last_honor_dont_use
                    set_db eco_prefix $last_prefix
                }
            }
            catch {gui_highlight $results}
            return $results
        }

        # Create buffer chains at the pins
        proc bufferize_pins {args} {
            set results {}

            set pins {}
            set pin_direction {}
            set opposite_pins {}
            set buffer_cell {}
            set buffer_count 1
            set place_status unplaced
            set inst_dont_touch true
            set inst_suffix "gf_buf_inst"
            set net_dont_touch true
            set net_suffix "gf_buf_net"
            set verbose 4
            set buffer_skip_check 0
            set macro_distance 0

            # Parse command line
            set key "-pins"
            foreach arg $args {

                # Keys
                if {[lsearch -exact {-pins -pin_direction -macro_distance -opposite_pins -buffer_cell -buffer_count -inst_dont_touch -inst_suffix -net_dont_touch -net_suffix -verbose} $arg] != -1} {
                    set key $arg

                # Place buffers
                } elseif {$arg == {-placed}} {
                        set place_status placed
                } elseif {$arg == {-fixed}} {
                        set place_status fixed
                } elseif {$arg == {-soft_fixed}} {
                        set place_status soft_fixed
                
                # Force buffer cell 
                } elseif {$arg == {-buffer_skip_check}} {
                    set buffer_skip_check 1

                # Incorrect key
                } elseif {[string match -* $arg]} {
                    error "Incorrect $arg option."

                # Pins to bufferize
                } elseif {$key == {-pins}} {
                    set pins [concat $pins $arg]

                # Opposite pins for buffer chains
                } elseif {$key == {-opposite_pins}} {
                    set opposite_pins [concat $pins $arg]

                # Buffer cell to use
                } elseif {$key == {-buffer_cell}} {
                    set buffer_cell $arg

                # Pin direction to force
                } elseif {$key == {-pin_direction}} {
                    set pin_direction $arg

                # Buffer chain length
                } elseif {$key == {-buffer_count}} {
                    set buffer_count $arg

                # New created buffers status
                } elseif {$key == {-inst_dont_touch}} {
                    set inst_dont_touch $arg
                } elseif {$key == {-inst_suffix}} {
                    set inst_suffix $arg

                # Distance from macros
                } elseif {$key == {-macro_distance}} {
                    set macro_distance $arg

                # New created nets status
                } elseif {$key == {-net_dont_touch}} {
                    set net_dont_touch $arg
                } elseif {$key == {-net_suffix}} {
                    set net_suffix $arg

                # Verbose level
                } elseif {$key == {-verbose}} {
                    set verbose $arg
                    set key "-from"
                }
            }

            # Options checks
            if {$pins == {}} {
                if {$verbose > 0} {puts "\033\[41m \033\[0m Option -pins is mandatory"}
                return {}
            }
            if {($opposite_pins != {}) && (($buffer_count < 2) || ($place_status=="unplaced"))} {
                if {$verbose > 1} {puts "\033\[43m \033\[0m Option -opposite_pins used only when -buffer_count is 2 or more and -place_status is not unplaced\n"}
            }

            # Check if cell is valid buffer
            if {[get_db base_cells $buffer_cell] != {}} {set buffer_cell [get_db base_cells $buffer_cell]}
            if {[get_db $buffer_cell] == {}} {
                if {$verbose > 0} {puts "\033\[41m \033\[0m Base cell $buffer_cell not found."}
                return {}
            }
            if {([get_db $buffer_cell .is_buffer] != true) && ($buffer_skip_check == 0)} {
                if {$verbose > 0} {puts "\033\[41m \033\[0m Base cell [get_db $buffer_cell .name] is not a buffer."}
                return {}
            } else {
                set buffer_cell_in_pin [get_db [get_db $buffer_cell .base_pins -if .direction==in] .base_name]
                set buffer_cell_out_pin [get_db [get_db $buffer_cell .base_pins -if .direction==out] .base_name]
                if {([llength $buffer_cell_in_pin] != 1) || ([llength $buffer_cell_out_pin] != 1)} {
                    if {$verbose > 0} {puts "\033\[41m \033\[0m Cannot detect input and output pins of $buffer_cell."}
                    return {}
                }
            }

            # Bufferize pins one by one
            foreach orig_pin $pins {

                # Get instance and net name prefix
#                set name_prefix [regsub -all {[\[\]]} [get_db $orig_pin .net.base_name] {}]
                set net_name [regsub -all {[\[\]]} [get_db $orig_pin .net.name] {}]
                if {$net_name == [regsub "_$net_suffix$" $net_name {}]} {
                    if {$verbose > 0} {puts "\033\[44m \033\[0m Bufferizing $orig_pin ..."}
                } else {
                    if {$verbose > 0} {puts "\033\[43m \033\[0m Rebufferizing $orig_pin ..."}
                    gf_unbufferize_pins -pins $orig_pin -inst_suffix $inst_suffix -net_suffix $net_suffix -verbose 0
                    set net_name [regsub "_$net_suffix$" [get_db $orig_pin .net.base_name] {}]
                }

                # Bufferize controls
                set buf_orig_pin_name {}
                set buf_new_pin_name {}
                set buf_opposite_direction {}

                # Original pin net
                set orig_net [get_db $orig_pin .net]
                if {$orig_net == {}} {
                    if {$verbose > 0} {puts "   \033\[41m \033\[0m No nets connected to $orig_pin"}

                # Bufferize to the input pin
                } elseif {([get_db $orig_pin .direction]=="in") || ($pin_direction == "in")} {
                    set buf_orig_pin_name $buffer_cell_in_pin
                    set buf_new_pin_name $buffer_cell_out_pin
                    set buf_opposite_direction out

                # Bufferize from the output pin
                } elseif {([get_db $orig_pin .direction]=="out") || ($pin_direction == "out")} {
                    set buf_orig_pin_name $buffer_cell_out_pin
                    set buf_new_pin_name $buffer_cell_in_pin
                    set buf_opposite_direction in

                } else {
                    if {$verbose > 0} {puts "\033\[41m \033\[0m Cannot bufferize pin [get_db $orig_pin .name] in [get_db $orig_pin .direction] direction."}
                }

                # Buferize in required direction
                if {$buf_opposite_direction != {}} {
                    set orig_net_name [get_db $orig_net .name]

                    # Original pin location
                    set opposite_pin {}
                    set location {}
                    set step {}

                    # Calculate buffer location
                    if {$place_status != "unplaced"} {
                        if {[get_db $orig_pin .inst.place_status] != "unplaced"} {set location [list [get_db $orig_pin .location.x] [get_db $orig_pin .location.y]]}

                        # Opposite pin location
                        if {$buffer_count > 1} {
                            set opposite_pin [get_db $opposite_pins -u -if ".direction==$buf_opposite_direction&&.net==$orig_net"]
                            if {[llength $opposite_pin] == 1} {
                                if {[get_db $opposite_pin .inst.place_status] != "unplaced"} {
                                    set step [list \
                                        [expr ([get_db $opposite_pin .location.x] - [lindex $location 0]) / ($buffer_count - 1)] \
                                        [expr ([get_db $opposite_pin .location.y] - [lindex $location 1]) / ($buffer_count - 1)] \
                                    ]
                                }
                            }
                        }
                    }

                    # Buffer suffix
                    set buffer_index 1
                    set buffer_suffix {}
                    if {$buffer_count > 1} {set buffer_suffix _${buffer_index}}

                    # Current pin to reconnect
                    set pin $orig_pin

                    # Add buffers
                    set count 1
                    while {$count <= $buffer_count} {

                        # Pin of hierarchical instance
                        if {([get_db $orig_pin .inst.parent.obj_type] == "inst") || ([get_db $orig_pin .inst.parent.obj_type] == "hinst")} {
                            set parent_name [get_db $orig_pin .inst.parent.name]
                            
                        # Pin of top level instance
                        } else {
                            set parent_name {}
                        }

                        # Get unique instance and net name
                        set name_prefix [get_db $orig_pin .inst.base_name]_[get_db $orig_pin .base_name]
                        while {([get_db insts [join [list ${parent_name} ${name_prefix}${buffer_suffix}_${inst_suffix}] "/"]] != {})
                            || ([get_db nets [join [list ${parent_name} ${name_prefix}${buffer_suffix}_${net_suffix}] "/"]] != {})} {
                            set buffer_index [expr $buffer_index + 1]
                            set buffer_suffix _${buffer_index}
                        }
                        set inst_name ${name_prefix}${buffer_suffix}_${inst_suffix}
                        set net_name ${name_prefix}${buffer_suffix}_${net_suffix}

                        # Create top level buffer instance
                        if {$parent_name == {}} {
                            create_inst -inst $inst_name -cell [get_db $buffer_cell .name]
                            set inst [get_db insts $inst_name]

                        # Create hierarchical buffer instance
                        } else {
                            create_inst -module [get_db $orig_pin .inst.parent.module.name] -inst $inst_name -cell [get_db $buffer_cell .name]
                            set inst [get_db insts ${parent_name}/$inst_name]
                        }
                        set inst_name [get_db $inst .name]
                        
                        # Create top level net
                        if {$parent_name == {}} {
                            create_net -name $net_name
                            set net [get_db nets $net_name]

                        # Create hierarchical net
                        } else {
                            create_net -module [get_db $orig_pin .inst.parent.module.name] -name $net_name
                            set net [get_db nets [get_db $orig_pin .inst.parent.name]/$net_name]
                        }
                        set net_name [get_db $net .name]

                        # Reconnect instances
                        disconnect_pin -inst [get_db $pin .inst.name] -pin [get_db $pin .base_name] -net $orig_net_name
                        connect_pin -inst $inst_name -pin $buf_orig_pin_name -net $orig_net_name
                        connect_pin -inst $inst_name -pin $buf_new_pin_name -net $net_name
                        connect_pin -inst [get_db $pin .inst.name] -pin [get_db $pin .base_name] -net $net_name
                        set pin [get_db $inst .pins */$buf_orig_pin_name]

                        # Set instance attributes
                        set_db $inst .dont_touch $inst_dont_touch
                        lappend results $inst
                        
                        # Set net attributes
                        set_db net:$net_name .dont_touch true
                        lappend results $net

                        # Place buffer instance to known location
                        if {$location != {}} {
                            set orient r0

                            set offset_x 0.0
                            set offset_y 0.0
                            if {($count == 1) && ($macro_distance > 0)} {
                                if {[get_db $inst .base_cell.area] < [expr {100*[get_db $orig_pin .inst.base_cell.area]}]} {
                                    
                                    set dt [expr {abs([get_db $orig_pin .location.y]-[get_db $orig_pin .inst.bbox.ur.y])}]
                                    set offset_y $macro_distance
                                    
                                    set d [expr {abs([get_db $orig_pin .location.y]-[get_db $orig_pin .inst.bbox.ll.y])}]
                                    if {$d < $dt} {
                                        set dt $d; set offset_x 0.0; set offset_y [expr {0 - $macro_distance}]
                                    }
                                    
                                    set d [expr {abs([get_db $orig_pin .location.x]-[get_db $orig_pin .inst.bbox.ll.x])}]
                                    if {$d < $dt} {
                                        set dt $d; set offset_x [expr {0 - $macro_distance - [get_db $inst .base_cell.bbox.length]}]; set offset_y 0.0
                                        set orient my
                                    }
                                    
                                    set d [expr {abs([get_db $orig_pin .location.x]-[get_db $orig_pin .inst.bbox.ur.x])}]
                                    if {$d < $dt} {
                                        set dt $d; set offset_x $macro_distance; set offset_y 0.0
                                    }
                                }
                            }

                            place_inst $inst_name [list [list \
                                [expr {[lindex $location 0] + $offset_x}] \
                                [expr {[lindex $location 1] + $offset_y}] \
                            ]]
                            set_db $inst .place_status $place_status
                            set_db $inst .orient $orient

                            if {$step == {}} {
                                set location {}
                            } else {
                                set location [list \
                                    [expr {[lindex $location 0] + [lindex $step 0]}] \
                                    [expr {[lindex $location 1] + [lindex $step 1]}] \
                                ]
                            }
                        }

                        # Net and buffer information
                        if {$verbose > 2} {puts "   \033\[42m \033\[0m $net"}
                        if {$verbose > 3} {puts "       .dont_touch=[get_db $net .dont_touch] .drivers={[get_db $net .drivers.base_name]} .loads={[get_db $net .loads.base_name]}"}
                        if {$verbose > 1} {puts "   \033\[42m \033\[0m $inst"}
                        if {$verbose > 3} {puts "       .base_cell=[get_db $inst .base_cell.name] .pins={$buffer_cell_in_pin $buffer_cell_out_pin} .place_status=[get_db $inst .place_status] .dont_touch=[get_db $inst .dont_touch] .location=[get_db $inst .location]"}

                        set count [expr $count+1]
                    }
                    if {$verbose > 0} {puts "   \033\[44m \033\[0m $orig_net"}
                    if {$verbose > 3} {puts "       .dont_touch=[get_db $inst .dont_touch] .drivers={[get_db $orig_net .drivers.base_name]} .loads={[get_db $orig_net .loads.base_name]}"}
                    if {[llength $opposite_pin] > 1} {
                        foreach object $opposite_pin {
                            if {$verbose > 0} {puts "   \033\[41m \033\[0m $object is not unique"}
                        }
                    } elseif {[llength $opposite_pin] == 1} {
                        if {[get_db $opposite_pin .inst.place_status] == "unplaced"} {
                            if {$verbose > 0} {puts "   \033\[41m \033\[0m $opposite_pin instance is not placed"}
                        } else {
                            if {$verbose > 2} {puts "   \033\[45m \033\[0m $opposite_pin"}
                            if {$verbose > 3} {puts "       .location=[get_db $opposite_pin .location]"}
                        }
                    }
                }
                if {$verbose > 0} {puts {}}
            }
            return $results
        }

        # Delete buffer chains at the pins
        proc unbufferize_pins {args} {
            set results {}

            set pins {}
            set inst_suffix "gf_buf_inst"
            set net_suffix "gf_buf_net"
            set verbose 4

            # Parse command line
            set key "-pins"
            foreach arg $args {

                # Keys
                if {[lsearch -exact {-pins -inst_suffix -net_suffix -verbose} $arg] != -1} {
                    set key $arg

                # Incorrect key
                } elseif {[string match -* $arg]} {
                    error "Incorrect $arg option."

                # Pins to bufferize
                } elseif {$key == {-pins}} {
                    set pins [concat $pins $arg]

                # Suffixes to proceed
                } elseif {$key == {-inst_suffix}} {
                        set inst_suffix $arg
                } elseif {$key == {-net_suffix}} {
                        set net_suffix $arg

                # Verbose level
                } elseif {$key == {-verbose}} {
                    set verbose $arg
                    set key "-from"
                }
            }

            # Options checks
            if {$pins == {}} {
                if {$verbose > 0} {puts "\033\[41m \033\[0m Option -pins is mandatory"}
                return {}
            }

            # Unbufferize pins one by one
            foreach orig_pin $pins {
                if {$verbose > 0} {puts "\033\[44m \033\[0m Unbufferizing $orig_pin ..."}

                # Get instance and net name prefix
                set need_delete 1
                set pin $orig_pin
                while {$need_delete} {
                    set net [get_db $pin .net]

                    # Check net match
                    if {[regexp "_$net_suffix$" [get_db $net .name]]} {
                        if {([llength [get_db $net .drivers]] == 1) && ([llength [get_db $net .loads]] == 1)} {
                            if {$verbose > 1} {puts "   \033\[42m \033\[0m $net"}
                        } else {
                            if {$verbose > 1} {puts "   \033\[43m \033\[0m $net"}
                            set need_delete 0
                        }
                    } else {
                        if {$verbose > 2} {puts "   \033\[44m \033\[0m $net"}
                        set need_delete 0
                    }
                    if {$verbose > 3} {puts "       .dont_touch=[get_db $net .dont_touch] .drivers={[get_db $net .drivers.base_name]} .loads={[get_db $net .loads.base_name]}"}

                    # Check inst match
                    if {$need_delete} {
                        set inst [get_db [concat [get_db $net .drivers] [get_db $net .loads]] .inst *_$inst_suffix]
                        if {[llength $inst] == 1} {
                            set target_net [get_db [get_db $inst .pins -if .net!=$net] .net]
                            if {[llength $target_net] == 1} {
                                if {$verbose > 2} {puts "   \033\[42m \033\[0m $inst"}
                            } else {
                                if {$verbose > 2} {puts "   \033\[41m \033\[0m $inst"}
                                set need_delete 0
                            }
                            if {$verbose > 3} {puts "       .base_cell=[get_db $inst .base_cell.name] .pins={[get_db $inst .pins.base_name]} .place_status=[get_db $inst .place_status] .dont_touch=[get_db $inst .dont_touch] .location=[get_db $inst .location]"}
                        } else {
                            if {$verbose > 2} {puts "   \033\[41m \033\[0m No instance *_$inst_suffix found"}
                            set need_delete 0
                        }
                    }

                    # Delete net and instance
                    if {$need_delete} {
                        foreach net_pin [concat [get_db $net .drivers] [get_db $net .loads]] {
                            disconnect_pin -inst [get_db $net_pin .inst.name] -pin [get_db $net_pin .base_name] -net [get_db $net .name]
                        }
                        foreach inst_pin [get_db $inst .pins -if ".net==$target_net"] {
                            disconnect_pin -inst [get_db $inst_pin .inst.name] -pin [get_db $inst_pin .base_name] -net [get_db $target_net .name]
                        }
                        connect_pin -inst [get_db $pin .inst.name] -pin [get_db $pin .base_name] -net [get_db $target_net .name]
                        if {[get_db $orig_pin .inst.parent.obj_type] == "inst"} {
                            delete_nets -module [get_db $inst .parent.module.name] [get_db $net .name]
                            delete_inst -module [get_db $inst .parent.module.name] -inst [get_db $inst .name]
                        } else {
                            delete_nets [get_db $net .name]
                            delete_inst -inst [get_db $inst .name]
                        }
                    }
                }
                if {$verbose > 0} {puts {}}
            }
            return $results
        }
    }
    
    catch {
        proc gf_attach_io_buffers {args} {eval "gf::attach_io_buffers $args"}
        proc gf_add_hold_buffers_to_endpoints {args} {eval "gf::add_hold_buffers_to_endpoints $args"}
        proc gf_bufferize_pins {args} {eval "gf::bufferize_pins $args"}
        proc gf_unbufferize_pins {args} {eval "gf::unbufferize_pins $args"}
        define_proc_arguments gf_bufferize_pins -define_args {
            { -pins "Pins to bufferize" "" string required }
            { -pin_direction "Force pin direction to in or out" "" string optional }
            { -macro_distance "Place instance in a specific distance outside macro" "" integer optional }
            { -opposite_pins "Opposite pins of the net to calculate placed buffers locations" "" string optional }
            { -buffer_cell "Buffer cell to use" "" string required }
            { -buffer_count "Number of buffers to add" "default is 1" string required }
            { -buffer_skip_check "Do not verify buffer cell .is_buffer property" "" boolean optional }
            { -placed "Place buffers and mark it as placed" "" boolean optional }
            { -fixed "Place buffers and mark it as fixed" "" boolean optional }
            { -soft_fixed "Place buffers and mark it as soft_fixed" "" boolean optional }
            { -inst_dont_touch "Set instance dont touch status" "default is true" string fixed }
            { -net_dont_touch "Set net dont touch status" "default is true" string fixed }
            { -inst_suffix "Suffix of inserted buffers names" "default is gf_buf_inst" string optional }
            { -net_suffix "Suffix of new net names" "default is gf_buf_net" string optional }
            { -verbose "Verbosity level" "default is 4" integer optional }
        }
        define_proc_arguments gf_unbufferize_pins -define_args {
            { -pins "Pins to unbufferize" "" string required }
            { -inst_suffix "Suffix of buffers to delete" "default is gf_buf_inst" string optional }
            { -net_suffix "Suffix nets to delete" "default is gf_buf_net" string optional }
            { -verbose "Verbosity level" "default is 4" integer optional }
        }
    }
    
    # Manual clock tree buffering
    proc gf_add_clock_tree_buffers {base_cell name pins dx dy} {
        set net_ext [get_db $pins .net -u]
        set dir [get_db $pins .direction -u]

        if {[llength $pins]<1} {
            puts "\033\[31;41m \033\[0m No pins to bufferize"
            return
        }

        if {[llength $dir]!=1} {
            puts "\033\[31;41m \033\[0m Pins have different directions:"
            foreach pin $pins {puts "  $pin => [get_db $pin .direction]"}
            return
        }

        if {[llength $net_ext]!=1} {
            puts "\033\[31;41m \033\[0m Pins connected to different nets:"
            foreach pin $pins {puts "  $pin => [get_db $pin .net]"}
            return
        }

        set pin_int [get_db $base_cell .base_pins -if .direction!=$dir]
        set pin_ext [get_db $base_cell .base_pins -if .direction==$dir]

        set inst_int [get_db insts ${name}_inst]
        set net_int [get_db nets ${name}_net]
        set is_exists 0
        if {"$inst_int$net_int" != ""} {
            puts "\033\[33;43m \033\[0m Net already bufferized:"
            set is_exists 1
        } else {
            set inst_int [create_inst -name ${name}_inst -base_cell [get_db $base_cell .name]]
            set net_int [create_net -name ${name}_net]
        }

        set x 0.0; set y 0.0
        foreach connection $pins {
            set x [expr $x+[get_db $connection .location.x]]
            set y [expr $y+[get_db $connection .location.y]]
            if {!$is_exists} {
                disconnect_pin -inst [get_db $connection .inst.name] -pin [get_db $connection .base_name] -net [get_db $net_ext .name]
                connect_pin -inst [get_db $connection .inst.name] -pin [get_db $connection .base_name] -net [get_db $net_int .name]
            }
        }
        set x [expr $x/[llength $pins]+$dx]
        set y [expr $y/[llength $pins]+$dy]

        if {!$is_exists} {
            puts "\033\[32;42m \033\[0m Net bufferized:"
            connect_pin -inst [get_db $inst_int .name] -pin [get_db $pin_ext .base_name] -net [get_db $net_ext .name]
            connect_pin -inst [get_db $inst_int .name] -pin [get_db $pin_int .base_name] -net [get_db $net_int .name]
        }

        set_db $inst_int .location [list $x $y]
        set_db $net_int .dont_touch true

        puts "  $net_ext"
        puts "  [get_db $inst_int .location] => $inst_int $base_cell [get_db $pin_ext .base_name] => [get_db $pin_int .base_name]"
        puts "  $net_int"
        foreach pin $pins {puts "  => $pin"}
    }
'

# Procedures to fix DRC violations
gf_create_step -name innovus_procs_align '

    # GUI instance alignment
    namespace eval gf {

        # Align specific instance to reference one
        proc align_instance {reference instance direction space flip} {

            # Instance orientation
            set orient [get_db $reference .orient]
            if {$flip} {
                switch -exact $direction {
                    l -
                    r -
                    left -
                    right {
                        switch -exact $orient {
                            r0 {set orient my}
                            r90 {set orient mx90}
                            r180 {set orient mx}
                            r270 {set orient my90}
                            mx {set orient r180}
                            mx90 {set orient r90}
                            my {set orient r0}
                            my90 {set orient r270}
                        }
                    }
                    u -
                    d -
                    up -
                    down {
                        switch -exact $orient {
                            r0 {set orient mx}
                            r90 {set orient my90}
                            r180 {set orient my}
                            r270 {set orient mx90}
                            mx {set orient r0}
                            mx90 {set orient r270}
                            my {set orient r180}
                            my90 {set orient r90}
                        }
                    }
                    default {
                        error "\033\[41m \033\[0m Incorrect direction $direction. Should be {left right up down}"
                    }
                }
            }
            set_db $instance .orient $orient
            
            # Move instance
            switch -exact $direction {
                l -
                left {
                    move_obj $instance -point [list \
                        [expr [get_db $instance .location.x] + [get_db $reference .bbox.ll.x] - $space - [get_db $instance .bbox.ur.x]] \
                        [get_db $reference .location.y] \
                    ]
                }
                r -
                right {
                    move_obj $instance -point [list \
                        [expr [get_db $instance .location.x] + [get_db $reference .bbox.ur.x] + $space - [get_db $instance .bbox.ll.x]] \
                        [get_db $reference .location.y] \
                    ]
                }
                u -
                up {
                    move_obj $instance -point [list \
                        [get_db $reference .location.x] \
                        [expr [get_db $instance .location.y] + [get_db $reference .bbox.ur.y] + $space - [get_db $instance .bbox.ll.y]] \
                    ]
                }
                d -
                down {
                    move_obj $instance -point [list \
                        [get_db $reference .location.x] \
                        [expr [get_db $instance .location.y] + [get_db $reference .bbox.ll.y] - $space - [get_db $instance .bbox.ur.y]] \
                    ]
                }
            }
        }

        proc gui_select_similar_macros {{macros {}}} {
            set macros [get_db $macros -if {.obj_type==inst&&(.is_macro||.is_black_box)}]
            if {$macros == {}} {set macros [get_db selected -if {.obj_type==inst&&(.is_macro||.is_black_box)}]}
            while {$macros == {}} {
                set point [gui_get_coord]
                if {$point == {}} {break}
                set macros [lindex [get_db [get_obj_in_area -area [concat $point $point] -obj_type inst] -if .is_macro||.is_black_box] 0]
            }
            
            # Patterns
            set patterns {}
            foreach macro $macros {
                set pattern [regsub -all {[0-9]+} [get_db $macro .name] {*}]
                if {[lsearch -index 0 -exact $patterns $pattern] == -1} {
                    lappend patterns $pattern
                    lappend patterns [get_db $macros $pattern]
                }
            }
            
            # Similar instances
            set similar [eval get_db insts [dict keys $patterns]]
            
            # Check similar
            dict for {pattern instances} $patterns {
                set groups {}
                set is_multiple 0
                foreach instance $instances {
                    set index 2
                    set next 1
                    set start -2
                    set ref_name [get_db $instance .name]
                    while {$next != {}} {
                        set next [regexp -inline -start $start {[^0-9]*[0-9]+} $ref_name]
                        if {$next == {}} {break}
                        lappend groups [list $index [get_db $similar [regsub -start $start {[0-9]+} $ref_name {*}]]]
                        set start [expr $start + [string length $next]]
                        if {$index > 2} {set is_multiple 1}
                        incr index
                    }
                }
                
                # Need to make choice
                if {$is_multiple} {
                    lappend groups [list 1 [get_db $similar $pattern]]
               
                    # Highlight similar
                    gui_clear_highlight $similar
                    foreach group [lreverse $groups] {
                        gui_highlight -index [lindex $group 0] [lindex $group 1]
                    }
                    
                    # Select instance from group
                    set index {}
                    while {$index == {}} {
                        set point [gui_get_coord]
                        if {$point == {}} {break}
                        
                        # Identify group
                        foreach instance [get_db [get_obj_in_area -area [concat $point $point] -obj_type inst] -if .is_macro||.is_black_box] {
                            if {$instance != {}} {
                                foreach group $groups {
                                    if {[lsearch -exact [lindex $group 1] $instance] != -1} {
                                        set index [lindex $group 0]
                                        break
                                    }
                                }
                            }
                            if {$index != {}} {break}
                        }
                    }
                } else {
                    set index 1
                }
            
                # Select instances in group
                gui_clear_highlight $similar
                if {$index != {}} {
                    foreach group $groups {
                        if {$index == [lindex $group 0]} {
                            select_obj [lindex $group 1]
                        }
                    }
                }
            }
        }
        
        # Align instances in given direction
        # List of spaces/flips can be used to use custom space patter
        # Infinite number of instances to be aligned if count is 0 until user press Esc

        variable gui_align_highlight_index {}
        variable gui_align_instances {}

        # Align instances interactively
        proc gui_align {args} {
            set direction "right"
            set spaces 0
            set flips 0
            set count 0
            set reference {}
            set gf::gui_align_instances {}
            set gf::gui_align_highlight_index {}

            # Parse options
            set keys [dict keys $args]
            set values [dict values $args]
            for {set i 0} {$i<[llength $keys]} {incr i} {
                switch -exact [lindex $keys $i] {
                    -dir -
                    -direction {
                        set direction [lindex $values $i]
                    }
                    -space -
                    -spaces {
                        set spaces [lindex $values $i]
                    }
                    -flip -
                    -flips {
                        set flips [lindex $values $i]
                    }
                    -count {
                        set count [lindex $values $i]
                    }
                    -ref -
                    -reference {
                        set reference [lindex $values $i]
                    }
                    -insts -
                    -instances {
                        set gf::gui_align_instances [lindex $values $i]
                    }
                    -index {
                        set gf::gui_align_highlight_index [lindex $values $i]
                    }
                    default {
                        error "\033\[41m \033\[0m Incorrect option [lindex $keys $i]."
                    }
                }
            }

            # Select reference
            if {$reference == {}} {
                if {$gf::gui_align_instances != {}} {
                    set reference [lindex $gf::gui_align_instances 0]
                    set gf::gui_align_instances [lrange $gf::gui_align_instances 1 [llength $gf::gui_align_instances]]
                } else {
                    set reference [lindex [get_db selected -if {.obj_type==inst&&(.is_macro||.is_black_box)}] 0]
                }
            }
            while {$reference == {}} {
                set point [gui_get_coord]
                if {$point == {}} {break}
                set reference [lindex [get_db [get_obj_in_area -area [concat $point $point] -obj_type inst] -if .is_macro||.is_black_box] 0]
            }
            
            # Align instances one by one
            set counter 0
            set point {}
            set results {}
            lappend results $reference
            if {$reference != {}} {
                set ref_name [get_db $reference .name]
                set similar [get_db insts [regsub -all {[0-9]+} $ref_name {*}]]
                
                set instance {}
                while {($counter < $count-1) || ($count == 0)} {
                
                    # Check similar
                    set groups {}
                    set next 1
                    set start -2
                    while 1 {
                        set next [regexp -inline -start $start {[^0-9]*[0-9]+} $ref_name]
                        if {$next == {}} {break}
                        lappend groups [get_db $similar [regsub -start $start {[0-9]+} $ref_name {*}]]
                        set start [expr $start + [string length $next]]
                    }

                    # Highlight similar
                    gui_clear_highlight $similar
                    set color 2
                    foreach group [lreverse $groups] {
                        gui_highlight -index $color $group
                        incr color
                    }
                    if {$gf::gui_align_highlight_index != {}} {
                        gui_highlight -color lightgreen [lindex $groups $gf::gui_align_highlight_index]
                    }
                    
                    # Highlight reference
                    gui_highlight -index 1 $reference
                    gui_redraw
                    
                    # Select instance to align
                    if {$gf::gui_align_instances != {}} {
                        set point {=}
                        set instance [lindex $gf::gui_align_instances 0]
                        set gf::gui_align_instances [lrange $gf::gui_align_instances 1 [llength $gf::gui_align_instances]]
                    } else {
                        set point [gui_get_coord]
                        if {$point == {}} {break}
                        set instances [get_db [get_obj_in_area -area [concat $point $point] -obj_type inst] -if .is_macro||.is_black_box]
                        set instance [lindex $instances 0]
                        if {$instance == $reference} {set instance [lindex $instances 1]}
                    }
                    
                    # Align instance
                    if {$instance != {}} {
                        set space [lindex $spaces [expr $counter % [llength $spaces]]]
                        set flip [lindex $flips [expr $counter % [llength $flips]]]
                        align_instance $reference $instance $direction $space $flip
                        set reference $instance
                        lappend results $reference
                        set ref_name [get_db $reference .name]
                        if {$gf::gui_align_highlight_index == {}} {
                            set index 0
                            foreach group $groups {
                                if {[lsearch -exact $group $ref_name] != -1} {
                                    set gf::gui_align_highlight_index $index
                                    break
                                }
                                incr index
                            }
                        }
                        incr counter
                    }
                }
                gui_clear_highlight $similar
                gui_redraw
            }
            if {$point == {}} {return {}} else {return $results}
        }

        # Align instances in 2D mode (list of {$direction $spaces $flips $count})
        proc gui_align_2d {args} {

            set direction_1d "right"
            set spaces_1d 0
            set flips_1d 0
            set count_1d 2
           
            if {$spaces_1d == {}} {set spaces_1d 0}
            if {$flips_1d == {}} {set flips_1d 0}
            if {$count_1d == {}} {set count_1d 2}
            
            set direction_2d "up"
            set spaces_2d 0
            set flips_2d 0
            set count_2d 0
           
            set reference {}
            set gf::gui_align_instances {}
            set highlight_index {}

            # Parse options
            set keys [dict keys $args]
            set values [dict values $args]
            for {set i 0} {$i<[llength $keys]} {incr i} {
                switch -exact [lindex $keys $i] {
                    -dir1 -
                    -direction1 {
                        set direction_1d [lindex $values $i]
                    }
                    -space1 -
                    -spaces1 {
                        set spaces_1d [lindex $values $i]
                    }
                    -flip1 -
                    -flips1 {
                        set flips_1d [lindex $values $i]
                    }
                    -count1 {
                        set count_1d [lindex $values $i]
                    }
                    -dir2 -
                    -direction2 {
                        set direction_2d [lindex $values $i]
                    }
                    -space2 -
                    -spaces2 {
                        set spaces_2d [lindex $values $i]
                    }
                    -flip2 -
                    -flips2 {
                        set flips_2d [lindex $values $i]
                    }
                    -count2 {
                        set count_2d [lindex $values $i]
                    }
                    -ref -
                    -reference {
                        set reference [lindex $values $i]
                    }
                    -insts -
                    -instances {
                        set gf::gui_align_instances [lindex $values $i]
                    }
                    -index {
                        set highlight_index [lindex $values $i]
                    }
                    default {
                        error "\033\[41m \033\[0m Incorrect option [lindex $keys $i]."
                    }
                }
            }

            # Select reference
            if {$reference == {}} {
                if {$gf::gui_align_instances != {}} {
                    set reference [lindex $gf::gui_align_instances 0]
                    set gf::gui_align_instances [lrange $gf::gui_align_instances 1 [llength $gf::gui_align_instances]]
                } else {
                    set reference [lindex [get_db selected -if {.obj_type==inst&&(.is_macro||.is_black_box)}] 0]
                }
            }
            while {$reference == {}} {
                set point [gui_get_coord]
                if {$point == {}} {break}
                set reference [lindex [get_db [get_obj_in_area -area [concat $point $point] -obj_type inst] -if .is_macro||.is_black_box] 0]
            }
            
            # Align in 2D mode
            set i 1
            set results {}
            while {($reference != {}) && (($i < $count_2d) || ($count_2d == 0))} {
                set result [gf::gui_align -direction $direction_1d -spaces $spaces_1d -flips $flips_1d -count $count_1d -reference $reference -instances $gf::gui_align_instances -index $highlight_index]
                set highlight_index $gf::gui_align_highlight_index

                if {$result == {}} {break}
                lappend results $result
                set reference [lindex [gf::gui_align -direction $direction_2d -spaces $spaces_2d -flips $flips_2d -count 2 -reference $reference -instances $gf::gui_align_instances] end]
                
                incr i
            }
            if {$reference != {}} {
                set result [gf::gui_align -direction $direction_1d -spaces $spaces_1d -flips $flips_1d -count $count_1d -reference $reference -instances $gf::gui_align_instances -index $highlight_index]
                lappend results $result
                return $results
            } else {
                return {}
            }
        }
    }
    catch {
        proc gf_gui_align {args} {eval "gf::gui_align $args"}
        proc gf_gui_align_2d {args} {eval "gf::gui_align_2d $args"}
        proc gf_gui_select_similar_macros {args} {gf::gui_select_similar_macros $args}

        define_proc_arguments gf_gui_align -define_args {
            { -direction "Direction to align" "" one_of_string {required {values {left right up down}}} }
            { -spaces "Spaces between instances (cycled list)" "default is 0" integer optional }
            { -flips "Flip next instance (cycled list)" "default is false" boolean optional }
            { -count "Total number of instances to align" "default is unlimited" integer optional }
            { -reference "Reference instance to align to" "will be requested if empty" string optional }
            { -instances "List of instances to align" "will be requested if empty" string optional }
        }
        define_proc_arguments gf_gui_align_2d -define_args {
            { -direction1 "1st direction to align" "" one_of_string {required {values {left right up down}}} }
            { -spaces1 "Spaces between instances in 1st direction (cycled list)" "default is 0" integer optional }
            { -flips1 "Flip next instance in 1st direction (cycled list)" "default is false" boolean optional }
            { -count1 "Total number of instances in 1st direction to align" "default is unlimited" integer optional }
            { -direction2 "2nd direction to align" "" one_of_string {required {values {left right up down}}} }
            { -spaces2 "Spaces between instances in 2nd direction (cycled list)" "default is 0" integer optional }
            { -flips2 "Flip next instance in 2nd direction (cycled list)" "default is false" boolean optional }
            { -count2 "Total number of instances in 2nd direction to align" "default is unlimited" integer optional }
            { -reference "Reference instance to align to" "will be requested if empty" string optional }
            { -instances "List of instances to align" "will be requested if empty" string optional }
        }
    }
'

# Placement save and restore procs
gf_create_step -name innovus_procs_copy_place '
    proc gf_write_inst_placement_script {file hierarchy {insts {}}} {
        set hierarchy [regsub "^[get_db current_design .name]/" [regsub {/$} $hierarchy ""] ""]
        set results ""
        set count 0
        if {$insts == ""} {set insts [get_db [get_db hinsts $hierarchy] .insts]}
        foreach inst $insts {
            if {[get_db $inst .obj_type] == "inst"} {
                set inst_name [get_db $inst .name]
                if {[string match $hierarchy/* $inst_name]} {
                    set inst_name [string replace [get_db $inst .name] 0 [string length $hierarchy] ""]
                    append results "gf_place_instance {$hierarchy} {$inst_name} [get_db $inst .location]\n"
                    incr count
                } else {
                    puts "\033\[41m \033\[0m $inst is not inside $hierarchy hierarchy."
                }
            } else {
                puts "\033\[43m \033\[0m Unsupported $inst skipped."
            }
        }
        if {$count > 0} {
            set fh [open "$file" "w"]
            puts $fh "$results"
            close $fh
            puts "\033\[42m \033\[0m Total $count instances written to $file."
        } else {
            puts "\033\[41m \033\[0m Nothing to save."
        }
    }

    proc gf_read_inst_placement_script {file hierarchy dx dy args} {
        set hierarchy [regsub "^[get_db current_design .name]/" [regsub {/$} $hierarchy ""] ""]
        set results {}
        set total 0
        proc gf_place_instance {orig_hierarchy inst_name location} {
            upvar hierarchy hierarchy
            uplevel 1 {incr total}
            upvar results results
            upvar dx dx
            upvar dy dy
            upvar args args
            set inst [get_db insts $hierarchy/$inst_name]
            if {$inst == ""} {
                puts "\033\[41m \033\[0m Instance inst:$hierarchy/$inst_name not found."
            } else {
                eval "place_inst {[get_db $inst .name]} [expr $dx+[lindex $location 0]] [expr $dy+[lindex $location 1]] $args"
                #puts "\033\[42m \033\[0m Instance $inst placed at [get_db $inst .location]."
                lappend results $inst
            }
        }
        source $file
        if {[llength $results] > 0} {
            puts "\033\[42m \033\[0m Total [llength $results] of $total instances placed."
        } else {
            puts "\033\[41m \033\[0m No instances placed."
        }
        gui_redraw
        return $results
    }

    proc gf_read_select_inst_placement_script {file hierarchy} {
        set hierarchy [regsub "^[get_db current_design .name]/" [regsub {/$} $hierarchy ""] ""]
        set results {}
        set total 0
        proc gf_place_instance {orig_hierarchy inst_name location} {
            upvar hierarchy hierarchy
            uplevel 1 {incr total}
            upvar results results
            upvar dx dx
            upvar dy dy
            upvar args args
            set inst [get_db insts $hierarchy/$inst_name]
            if {$inst == ""} {
                puts "\033\[41m \033\[0m Instance inst:$hierarchy/$inst_name not found."
            } else {
                select_obj $inst
                lappend results $inst
            }
        }
        source $file
        if {[llength $results] > 0} {
            puts "\033\[42m \033\[0m Total [llength $results] of $total instances selected."
        } else {
            puts "\033\[41m \033\[0m No instances selected."
        }
        gui_redraw
        return [llength $results]
    }

    # Save object locations relative to first one
    proc gf_get_insts_locations {{hierarchy {}} {insts {}}} {
        if {$insts == {}} {set insts [get_db selected]}
        set x0 [get_db [lindex $insts 0] .location.x]
        set y0 [get_db [lindex $insts 0] .location.y]
        set results {}
        foreach inst $insts {
            set inst_name [get_db $inst .name]
            if {$hierarchy != {}} {set inst_name [regsub "^$hierarchy" $inst_name {}]}
            lappend results [list \
                $inst_name \
                [expr [get_db $inst .location.x] - $x0] \
                [expr [get_db $inst .location.y] - $y0] \
                [get_db $inst .orient] \
            ]
        }
        return $results
    }
    
    # Restore object locations relative to first one
    proc gf_set_insts_locations {locations {hierarchy {}}} {
        set x0 [get_db "inst:$hierarchy[lindex $locations 0 0]" .location.x]
        set y0 [get_db "inst:$hierarchy[lindex $locations 0 0]" .location.y]
        foreach location $locations {
            set inst "inst:$hierarchy[lindex $location 0]"
            set_db $inst .location [list [expr [lindex $location 1] + $x0] [expr [lindex $location 2] + $y0]]
            set_db $inst .orient [lindex $location 3]
            select_obj $inst
        } 
    }

    # Dump bump and pad coordinates
    proc gf_get_bumps_locations {{bumps {}}} {
        set results {}
        if {$bumps == {}} {set bumps [get_db selected]}
        if {$bumps == {}} {set bumps [get_db bumps]}
        foreach bump [get_db $bumps -if .obj_type==bump] {
            set net [get_db $bump .net]
            set pads [concat [get_db $net .loads] [get_db $net .drivers]]
            set pad [get_db [lindex $pads 0] .inst]
            if {$pad!={}} {
                lappend results [list \
                    [get_db $bump .name] \
                    [get_db $bump .net.name] \
                    [get_db $bump .location] \
                    [get_db $pad .name] \
                    [get_db $pad .location] \
                    [get_db $pad .orient] \
                ]
            }
        }
        return $results
    }

    # Dump bump and pad coordinates
    proc gf_set_bumps_locations {{records {}}} {
        foreach record $records {
            set bump [get_db bumps [lindex $record 0]]
            set net [get_db nets [lindex $record 1]]
            if {[get_db $net] == {}} {
                puts "\033\[41m \033\[0m Net \033\[97mnet:[lindex $record 1]\033\[0m not found in the design"
            } else {
                if {[lindex $record 1] != [get_db $bump .net.name]} {
                    puts "\033\[43m \033\[0m Bump [get_db $bump .name] net \033\[97m[get_db $bump .net]\033\[0m does not match original \033\[97m$net\033\[0m one"
                }
                if {[lindex $record 2] != [get_db $bump .location]} {
                    puts "\033\[43m \033\[0m Bump [get_db $bump .name] location \033\[97m[get_db $bump .location]\033\[0m does not match original \033\[97m[lindex $record 2]\033\[0m one"
                }

                set pads [concat [get_db $net .loads] [get_db $net .drivers]]
                set pad [lindex $pads 0]
                if {$pad !={}} {
                    set pad [get_db $pad .inst]
                    if {[lindex $record 3] != [get_db $pad .name]} {
                        puts "\033\[43m \033\[0m Pad \033\[97m[get_db $pad .name]\033\[0m name does not match original \033\[97m[lindex $record 3]\033\[0m one"
                    }
                    if {[lindex $record 4] != [get_db $pad .location]} {
                        puts "\033\[42m \033\[0m Pad \033\[97m[get_db $pad .name]\033\[0m moved from \033\[97m[get_db $pad .location]\033\[0m to \033\[97m[lindex $record 4]\033\[0m"
                        set_db $pad .location [lindex $record 4 0]
                    }
                    if {[lindex $record 5] != [get_db $pad .orient]} {
                        puts "\033\[42m \033\[0m Pad \033\[97m[get_db $pad .name]\033\[0m orient changed from \033\[97m[get_db $pad .orient]\033\[0m to \033\[97m[lindex $record 5]\033\[0m"
                        set_db $pad .orient [lindex $record 5]
                    }
                    gui_highlight $pad
                }
                gui_highlight $bump
            }
        }
    }

'
