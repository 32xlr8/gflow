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
# Filename: bin/trace_timing.tcl
# Purpose:  Innovus trace timing tool
################################################################################

################################################################################
# Trace timing utility namespace
################################################################################
namespace eval ns_trace_timing {

variable header \
"#############################################################################
# Generic Flow - Trace timing utility                                       #
#############################################################################
# Command:     trace_timing                                                 #
# Version:     v5.1 (May 2023)                                              #
# Developer:   Gennady Kirpichev <32xlr8\@gmail.com>                        #
#############################################################################"

# Parameters to show
variable all_show_parameters {arcs clock pin pin_clock pin_data view length length_worst length_total latency clock_id phase period skew io_delay input_delay output_delay delay delay_worst delay_total slew setup hold from to}
variable filter_show_parameters {pin_clock pin_data length_worst length_total input_delay output_delay delay_worst delay_total to setup hold from}

# Default option values
variable default_analysis_type -late
variable default_max_depth 3
variable default_trace_limit 5
variable default_print_limit 1

# Special variables
variable default_all_limit 500
variable default_target_limit 100
variable default_direction -through
variable default_point_list ref

# Usage section
variable usage {
Usage
-----
    trace_timing [-help] [-from {...}] [-to {...}] [-through {...}] [-all_through {...}]
                 [-priority [-from|-to|-through] {...}] [-filter]
                 [-target [<depth>] [-from|-to|-through] {...} [-target_limit <number>]]
                 [-selected] [-macros] [-inputs] [-outputs] [-ports] [-all_limit <number>]
                 [-max_depth <number>] [-trace_limit <number>] [-all] [-loop] [-trace_ports] [-separate]
                 [[-print_limit <number>] | [-print_all] | [-max_paths <number>]] [-verbose]
                 [-show $::ns_trace_timing::all_show_parameters] | [-show_all]
                 [-report [-format <list>]] [-highlight [slacks|direction|<float_value>] -worst -bad]
                 [-path_type <string>] [-path_group <string>][-view view] [-late] [-early] [-file <name> [-machine_readable]]

Variables
--------------------
    {...}    : objects or templates to trace
    <number> : positive number
    <depth>  : chain depth from the reference chain (default 0 means any depth)
    <list>   : list of values
    <string> : string value
    <name>   : file name

Trace object templates
----------------------
    -selected            : trace selected objects
    -macros              : trace macros
    -inputs              : trace input ports
    -outputs             : trace output ports
    -ports               : trace input and output ports

Trace timing options
--------------------
    -help               : display this help
    -from {...}         : reference points to trace from
    -to {...}           : reference points to trace to
    -through {...}      : reference points to trace through (default)
    -all_through {...}  : all paths to trace through
    -all                : trace all reference points
    -priority {...}     : trace priority objects first
    -target {...}       : target-based trace with extended limit (can be slow if target cannot be found)
    -loop               : stop trace if current point looped to the reference (default: no stop)
    -separate           : trace paths separately (can be slow)
    -filter             : filter results, leave only points with pair
    -trace_ports        : start trace from worst timing path including IO

Trace timing limits
-------------------
    -all_limit #      : limit reference paths count when -all option used (default: $::ns_trace_timing::default_all_limit)
    -trace_limit #    : number of paths to trace for each chain (defaut: $::ns_trace_timing::default_trace_limit)
    -target_limit #   : number of paths to trace in target modefor each chain (default: $::ns_trace_timing::default_target_limit)
    -max_depth #      : max path trace depth relative to the reference (default: $::ns_trace_timing::default_max_depth)
    -max_paths #      : number of paths to trace and print for each chain
                        (default: separate -trace_limit and -print_limit options used)

Report options
--------------
    -print_limit 1    : number of points to report (default: $::ns_trace_timing::default_print_limit)
    -print_all        : report all points
    -verbose          : show additional info
    -report           : report timing paths instead of chains (default: chain report)
    -machine_readable : write out report in machine readable format
    -file             : report results to file

Highlight paths options
-----------------------
    -highlight,
    -highlight slacks    : highlight chain report with colored slacks (default) or direction
    -highlight direction : highlight chain report with colors depending on chain direction
                           ('from' with green color, 'reference' with yellow, 'to' with blue).
    -highlight <value>   : highlight chain report with colored slacks, red color for
                           paths with slack less than 'value'.
    -bad                 : highlight red and yellow slacks only
    -worst               : highlight red slacks only (less than highlight value)

Supported report_timing options for analysis
--------------------------------------------
    -view, -late, -early, -path_group, -retime,
    -clock_from, -clock_to, -not_through,
    -min_slack, -max_slack, -nworst, -unique_pins

Supported options in report_timing mode
---------------------------------------
    -format, -path_type, -net, -machine_readable

Supported options in chain report mode
--------------------------------------
    -show {...}  : show parameters in chain mode
    -show_all    : show all parameters in chain mode

Parameters to show in chain mode (-show option)
-----------------------------------------------
    arcs         : number of cell arcs
    clock        : clock names
    view         : view names
    pin          : clock and data pin names
    pin_clock    : clock pin names
    pin_data     : data pin names
    length       : worst and total wire length
    length_worst : worst wire length
    length_total : total wire length
    latency      : clock latency
    clock_id     : clock insertion delay
    phase        : clock phase shift
    period       : clock period
    skew         : clock slew
    io_delay     : input and output delay constraints
    input_delay  : input delay constraints
    output_delay : output delay constraints
    delay        : worst and total path delay
    delay_worst  : worst element delay
    delay_total  : total path delay
    slew         : worst slew
    from         : worst slack from the begin points (can be slow)
    to           : worst slack to the end points (can be slow)
    setup        : worst setup timing for -early paths (can be slow)
    hold         : worst hold timing for -late paths (can be slow)

Chain report legend
-------------------
  ,-> Clock latency -> Capture points ("from" chains)
  '--,      Setup: Slacks
  ,=> Clock latency => Capture points (reference chain)
  |                    ... hidden points
  '==,      Setup: Slacks
  ,-> Clock latency <= Launch points (reference chain)
  '--,      Setup: Slacks
      Clock latency <- Launch points ("to" chains)

Useful examples
---------------
    trace_timing
    trace_timing -loop
    trace_timing -separate
    trace_timing -max_paths 1
    trace_timing -highlight -0.1
    trace_timing -priority -macros -highlight -0.1
    trace_timing -from -inputs -target -to -outputs
    trace_timing -all -selected -highlight
    trace_timing -all -ports -highlight -bad -max_depth 0 -all_limit 5000
    trace_timing -from -all -inputs -to -macros -highlight
    trace_timing -max_paths 10 -max_depth 2
    trace_timing -trace_limit 10 -separate
    trace_timing -trace_limit 10 -print_limit 2
    trace_timing -show {pin_data from to}
    trace_timing -show hold
    trace_timing -to top/reg -loop
    trace_timing -format {arc instance delay arrival} -file out.tarpt
    trace_timing -path_type full_clock -file out.tarpt
    trace_timing -path_group reg2reg -file out.tarpt
    trace_timing -machine_readable -file out.mtarpt
}

# Arrows: first point, middle point, last point
variable arrow_ncapt  {{{,} {,} {:} {:} {:}} {->} { -> }}
variable arrow_nlnch  {{{'} {:} {:} {'} { }} {--} { <- }}
variable arrow_rcapt  {{{,} {,} {|} {|} {|}} {=>} { => }}
variable arrow_rlnch  {{{'} {|} {|} {'} { }} {==} { <= }}

# Report section
variable report_header {Timing trace report
-------------------}

# Parameters to show
variable show_captions
array set show_captions {}

# Parameters classification
set analyzed_parameters {setup_to hold_to setup hold setup_from hold_from}
set standard_parameters {arcs view phase period skew slew delay_worst delay_total length_worst length_total}
set extended_parameters {clock clock_id pin_clock pin_data input_delay output_delay latency}

# Parameters with additional analysis
set show_captions(setup)        "Setup"
set show_captions(setup_from)   "Setup from"
set show_captions(setup_to)     "Setup to"
set show_captions(hold)         "Hold"
set show_captions(hold_from)    "Hold from"
set show_captions(hold_to)      "Hold to"

# Standard parameters
set show_captions(arcs)         "Data arcs"
set show_captions(view)         "Views"
set show_captions(phase)        "Phase shift"
set show_captions(period)       "Period"
set show_captions(skew)         "Skew"
set show_captions(slew)         "Worst slew"
set show_captions(delay_worst)  "Worst delay"
set show_captions(delay_total)  "Total delay"
set show_captions(length_worst) "Wire length (worst)"
set show_captions(length_total) "Wire length (total)"
set show_captions(input_delay)  "Input delay"
set show_captions(output_delay) "Output delay"

# Extended parameters
set show_captions(clock)        "Clock"
set show_captions(clock_id)     "Clock ID"
set show_captions(pin_clock)    "Clock pins"
set show_captions(pin_data)     "Data pins"
set show_captions(latency)      "Latency"

# Unknown value to show
variable default_show_value "---"

# Highlight slack colors
variable color_bad  red
variable color_norm yellow
variable color_good lightgreen

################################################################################
# Perl script to post-process machine-readable report
################################################################################
variable trtm_mtarpt_postprocess {
    my $file = shift;
    my $data = "";
    my $isHeader = 1;
    open FILE, $file;
    while (<FILE>) {
        if (/^PATH\s+\d+/ .. /^END_PATH\s+\d+/) {
            $isHeader = 0;
            $count++ if (/^PATH\s+\d+/);
            s/^((END_)?PATH)\s+\d+/$1." ".$count/e;
            $data .= $_;
        } elsif ($isHeader && /^\s*[^#]\S/) {
            $data .= $_;
        }
    }
    close FILE;
    open FILE, ">".$file;
    print FILE $data;
    close FILE;
}

################################################################################
# Print debug info
################################################################################
proc trtm_debug_info {caption {message {}}} {
    variable trtm_debug
    if { $trtm_debug } {
        if { $message == "" } {
            puts "# $caption"
        } else {
            puts "# $caption: $message"
        }
    }
}

################################################################################
# Print verbose info
################################################################################
proc trtm_verbose_info {{title ""} {print_message 1}} {
    upvar 1 options(-verbose) verbose
    upvar 1 options(-verbose_title) verbose_title

    if { $verbose } {

        # Report resources
        if { $verbose_title != "" } {
            report_resource -end $verbose_title
            set verbose_title ""
        }

        # Print empty line
        if { $title == "0" } {
            puts {}

        # Print title and start resurce monitoring
        } elseif { $title != "" } {
            set verbose_title $title
            if { $print_message } { puts "Running \"$verbose_title\" ..." }
            report_resource -start $verbose_title
        }
    }
}

################################################################################
# Get pin names from pin collections
################################################################################
proc trtm_get_pin_names {pin_list {default {}}} {
    set result {}
    foreach pin $pin_list {
        if { $pin == {} } {
            lappend result $default
        } else {
            lappend result [get_property $pin hierarchical_name]
        }
    }
    return $result
}

################################################################################
# Get instance names from pin collections
################################################################################
proc trtm_get_inst_names {pin_list {default {}}} {
    set result {}
    foreach pin $pin_list {
        set inst [file dirname [get_property $pin hierarchical_name]]
        if { $inst == "." } {
            lappend result $default
        } else {
            lappend result $inst
        }
    }
    return $result
}

################################################################################
# Save get property of each path
################################################################################
proc trtm_get_path_property {path property {default {}}} {
    if { $path == {} } {
        return $default
    } else {
        return [get_property $path $property]
    }
}

################################################################################
# Save get property of each path of the list
################################################################################
proc trtm_get_path_list_property {path_list property {default {}}} {
    set properties {}
    foreach path $path_list {
        lappend properties [trtm_get_path_property $path $property $default]
    }
    return $properties
}

################################################################################
# Get instance or pin names from pin collections
################################################################################
proc trtm_get_inst_or_port_names {pin_list} {
    set result {}
    foreach pin $pin_list {
        set pin [get_property $pin hierarchical_name]
        set inst [file dirname $pin]
        if { $inst == "." } {
            lappend result $pin
        } else {
            lappend result $inst
        }
    }
    return $result
}

################################################################################
# Convert path collection to list
################################################################################
proc trtm_path_collection_to_list {path_collection} {
    set path_list {}
    foreach_in_collection path $path_collection {
        lappend path_list $path
    }
    return $path_list
}

################################################################################
# Safe expand collections
################################################################################
proc trtm_expand_collections {collections} {
    set result {}
    foreach value $collections {
        catch {
            if { [regexp {^0x[0-9a-f]+$} $value] } {
                foreach_in_collection object $value {
                    lappend result $object
                }
#                lappend result [get_object_name $value]
            } else {
                lappend result $value
            }
        }
    }
    return [eval concat $result]
}

################################################################################
# Print path points
################################################################################
proc trtm_print_points {points print_limit} {
    set print_count 0
    set printed {}
    foreach point $points {
        if {$print_count < $print_limit} {
            if { $point != {} } {
                if { [lsearch -exact $printed $point] == -1 } {
                    lappend printed $point
                    puts "  $point"
                    incr print_count
                }
            }

        } elseif {$print_limit > 0} {
            puts "  ..."
            break
        }
    }
}

################################################################################
# Report formated value with sign
################################################################################
proc trtm_format_float {values} {
    set results {}
    foreach value $values {
        if { $value == {} } {
            lappend results $::ns_trace_timing::default_show_value
        } elseif { [string is double $value] } {
            lappend results [format "%+.3f" $value]
        } else {
            lappend results $value
        }
    }
    return $results
}

################################################################################
# Highlight objects of the chosen colors
################################################################################
proc trtm_highlight_path_lists {path_lists colors index threshold} {
    array set objects {}

    set norm_color [lindex $colors 0]
    set bad_color  [lindex $colors 1]
    set good_color [lindex $colors 2]
    set logic_color lightgrey

    set color $norm_color

    # Process each path list
    foreach path_list $path_lists {

        # Process each path in list
        foreach path $path_list {

            # Skip empty paths
            if { $path != {} } {

                # Select color based on the slack
                if { $threshold != "" } {
                    set slack [get_property $path slack]
                    set color $norm_color
                    catch {

                        # Positive threshold: red if slack < 0
                        if { $threshold > 0 } {
                            if { $slack > $threshold } {
                                set color $good_color

                            } elseif { $slack < 0 } {
                                set color $bad_color
                            }

                        # Negative threshold: green if slack > 0
                        } else {
                            if { $slack > 0 } {
                                set color $good_color

                            } elseif { $slack < $threshold } {
                                set color $bad_color
                            }
                        }
                    }
                }

                # Process selected colors only
                if { $color != "" } {

                    # Process each pin in the path
                    foreach_in_collection pin [get_property [get_property $path timing_points] pin] {

                        # Highlight nets of ports
                        if {[get_property $pin is_port]} {

                            # Nets to highlight
                            catch {
                                set nets [get_nets -of_object $pin]
                                if { [sizeof_collection $nets] > 0 } { lappend objects($color) $nets }
                            }

                        # Highlight nets and cells
                        } else {

                            # Cells to highlight
                            catch {
                                foreach_in_collection cell [get_cells -of_object $pin] {

                                    # Special color for combinational cells
                                    if { [get_property $cell is_combinational] == true } {
                                        lappend objects($logic_color) $cell

                                    } else {
                                        lappend objects($color) $cell
                                    }
                                }
                            }

                            # Do not highlight cell inputs
                            if { [get_property $pin direction] != "in" } {

                                # Nets to highlight
                                catch {
                                    set nets [get_nets -of_object $pin]
                                    if { [sizeof_collection $nets] > 0 } { lappend objects($color) $nets }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    # Colors to highlight
    if { $threshold != "" } {
        set colors [list $bad_color $norm_color $good_color]
    }

    # Add logic cells color
    lappend colors $logic_color

    # Sort colors by severity
    set ordered_colors {}
    foreach color $colors {
        if { [lsearch [array names objects] $color] != -1 } {
            lappend ordered_colors $color
        }
    }

    # Highlight object by color
    set highlighted_objects {}
    foreach color $ordered_colors {

        # Filter objects
        set to_highlight {}
        foreach object $objects($color) {
            set object_name [get_object_name $object]

            # If not highlighted yet
            if { [lsearch -exact $highlighted_objects $object_name] == -1 } {
                lappend highlighted_objects $object_name
                lappend to_highlight $object
            }
        }

        # Highlight objects without logging
        if { $to_highlight != {} } {
            catch { unlogCommand highlight }
            if {[info command gui_highlight] != {}} {
                catch {gui_highlight $to_highlight -index $index -color $color}
            } else {
                catch {highlight $to_highlight -index $index -color $color}
            }
            catch { logCommand highlight }
            incr index
        }
    }
}

################################################################################
# Get timing paths with priority
################################################################################
proc trtm_trace_path_collection {analysis_args priority_args point_args depth trace_limit target_limit target_found_var} {
    upvar $target_found_var target_found
    set path_collection {}

    # Target mode
    if {[lindex $priority_args 0 0] == 1} {
        set max_paths $target_limit

    # Priority and normal modes
    } else {
        set max_paths $trace_limit
    }

    # Trace in target, priority and normal modes
    foreach priority_arg [concat $priority_args {{0 0 {}}}] {

        if { [lindex $priority_arg 1] <= $depth } {
            set command [concat report_timing [join $analysis_args " "] \
                -max_paths $max_paths [join $point_args " "] [lindex $priority_arg 2] -collection]

            trtm_debug_info "Trace" $command

            # Run command without logging
            catch { unlogCommand report_timing }
            set path_collection [eval $command]
            catch { logCommand report_timing }
        }

        # Stop trace if paths found
        if { [sizeof_collection $path_collection] > 0 } {

            # Set trace stopped flag
            if { [lindex $priority_arg 0] } {
                trtm_debug_info "Target found" $path_collection\n
                set target_found [lindex $priority_arg 0]
            }
            break
        }
    }

    trtm_debug_info "Result" "$path_collection ([sizeof_collection $path_collection])\n"
    return $path_collection
}

################################################################################
# Get timing path list
################################################################################
proc trtm_trace_path_list {separate analysis_args priority_args trace_direction points depth trace_limit target_limit target_found_var} {
    upvar $target_found_var target_found

    # Separate point trace mode
    if { $separate } {
        set path_list {}
        foreach point $points {

            # Empty result for empty points
            if { $point == {} } {
                lappend path_list {}

            # Trace existing points
            } else {
                set path_collection [trtm_trace_path_collection $analysis_args $priority_args \
                    [list $trace_direction $point] $depth 1 1 target_found]

                if { [sizeof_collection $path_collection] > 0 } {
                    lappend path_list [index_collection $path_collection 0]

                } else {
                    lappend path_list {}
                }
            }
        }

        return $path_list

    # Group trace mode
    } else {
        set points [eval concat $points]

        # Check if there are points
        if { [llength $points] > 0 } {
            return [trtm_path_collection_to_list [trtm_trace_path_collection $analysis_args $priority_args \
                [list $trace_direction [list $points]] $depth $trace_limit $target_limit target_found]]

        # All points are empty
        } else {
            return {}
        }
    }

}

################################################################################
# Report timing path
################################################################################
proc trtm_report_path_list {max_paths analysis_args point_args} {

    # Command to report
    set command [concat report_timing -collection \
        [join $analysis_args " "] \
        [join $point_args " "] \
        -max_paths $max_paths \
    ]

    trtm_debug_info "Command" $command

    # Run command without logging
    catch { unlogCommand report_timing }
    set path_list [trtm_path_collection_to_list [eval $command]]
    catch { logCommand report_timing }

    trtm_debug_info "Result" "$path_list ([llength $path_list])\n"
    return $path_list
}

################################################################################
# Trace timing in one direction
################################################################################
proc trtm_trace_timing_chains {direction points_ref analysis_args priority_args max_depth trace_limit target_limit print_limit separate filter} {

    # Direction-dependent settings
    if { $direction == "TO" } {
        set trace_direction "-to"
        set trace_point "launching_point"

        set loop_direction "-from"
        set loop_point "capturing_point"

    } else {
        set trace_direction "-from"
        set trace_point "capturing_point"

        set loop_direction "-to"
        set loop_point "launching_point"
    }

    trtm_debug_info "Points to trace $trace_direction" \n[join [eval concat $points_ref] \n]\n

    # Current depth
    set depth 1

    # Target found flag
    set trace_code 0

    # Result
    set path_lists {}

    # Analysis memory
    set analyzed_points {}

    # Trace not needed
    if { $depth > $max_depth } {
        puts "\033\[33;43m \033\[0m No trace in $trace_direction direction because of -max_depth limit $max_depth."

    # Trace paths
    } else {

        # Trace first point (target_code can be 0, 1 or 2)
        set path_list [trtm_trace_path_list $separate $analysis_args $priority_args $trace_direction \
            $points_ref $depth $trace_limit $target_limit trace_code]

        # First trace is not succesful
        if {[llength [eval concat $path_list]] < 1} {
            puts "\033\[33;43m \033\[0m No timing paths in $trace_direction direction."

        # First trace is successful
        } else {

            # Active points are reference one
            set point_names [trtm_get_inst_or_port_names [trtm_get_path_list_property $path_list $loop_point]]

            # Push reference paths to result
            lappend path_lists $path_list
            lappend analyzed_points $point_names

            # Get active point names
            set point_names [trtm_get_inst_or_port_names [trtm_get_path_list_property $path_list $trace_point]]

            # Trace until target found
            while { $trace_code == 0 } {

                # Stop when points have been already analyzed
                if { [lsearch -exact $analyzed_points $point_names] >= 0 } {
                    set trace_code 3
                    break
                }

                # Stop when depth limit reached
                if { $depth >= $max_depth } {
                    set trace_code 4
                    break
                }

                # Push active points to result
                lappend analyzed_points $point_names

                # Points to trace: IO ports are empty
                set points [trtm_get_inst_names [trtm_get_path_list_property $path_list $trace_point]]
                trtm_debug_info "Points" \n[join [eval concat $points] \n]\n

                # Stop when no points to trace left
                if { [llength [eval concat $points]] < 1 } {
                    puts "\033\[37;47m \033\[0m No more paths to trace in $trace_direction direction."
                    break

                # Trace next point
                } else {
                    set path_list [trtm_trace_path_list $separate $analysis_args $priority_args \
                        $trace_direction $points $depth $trace_limit $target_limit trace_code]

                    # Stop when trace result is empty
                    if {[llength [eval concat $path_list]] < 1} {
                        puts "\033\[37;47m \033\[0m No more paths in $trace_direction direction."
                        break

                    # Push paths to result and update active point names
                    } else {
                        lappend path_lists $path_list
                        set point_names [trtm_get_inst_or_port_names [trtm_get_path_list_property $path_list $trace_point]]
                    }

                }

                incr depth

            }

            # Target found in target mode
            if { $trace_code == 1 } {
                puts "\033\[37;47m \033\[0m Target found in $trace_direction direction. Stopped at:"
                trtm_print_points $point_names $print_limit

            # Loop to the reference point
            } elseif { $trace_code == 2 } {
                puts "\033\[37;47m \033\[0m Loop to the reference point in $trace_direction direction. Stopped at:"
                trtm_print_points $point_names $print_limit

            # Loop to already analized point
            } elseif { $trace_code == 3 } {
                puts "\033\[37;47m \033\[0m Loop to already analyzed point in $trace_direction direction. Stopped at:"
                trtm_print_points $point_names $print_limit

            # Loop to already analized point
            } elseif { $trace_code == 4 } {
                puts "\033\[37;47m \033\[0m Depth limit reached in $trace_direction direction. Next points are:"
                trtm_print_points $point_names $print_limit
            }

            # Target not found in target mode
            if { ($trace_code != 1) && ([lindex $priority_args 0 0] == 1)} {
                puts "\n\033\[33;43m \033\[0m Target not found in $trace_direction direction. Use -target_limit option to expand search boundaries."
            }

            # Filter path lists
            if { $filter } {
                trtm_debug_info "Filtering results"

                set filtered_lists {}
                set filtered_points {}
                foreach path_list [lreverse $path_lists] {
                    if { $filtered_points == {} } {
                        set filtered_points [trtm_get_inst_or_port_names [trtm_get_path_list_property $path_list $trace_point]]
                    }

                    # Filter path list
                    set filtered_list [trtm_report_path_list $trace_limit $analysis_args [list \
                        $loop_direction [list $filtered_points] \
                        $trace_direction [list [trtm_get_inst_or_port_names [trtm_get_path_list_property $path_list $loop_point]]] \
                    ]]

                    lappend filtered_lists $filtered_list
                    set filtered_points [trtm_get_inst_or_port_names [trtm_get_path_list_property $filtered_list $loop_point]]
                }

                set path_lists [lreverse $filtered_lists]
            }
        }
    }

    return $path_lists
}

################################################################################
# Create timing chain report for path collection
################################################################################
proc trtm_return_chain_timing_points {path_list analysis_type print_limit arrows need_chain trace_point} {
    set points {}
    set print_index 0
    set hidden_flag 0

    # Report all not empty paths
    trtm_debug_info "Points" "$path_list ([llength $path_list])"
    foreach path $path_list {
        if { $path != {} } {
            # Append point if limit not achieved
            if {$print_index < $print_limit} {

                # Append point
                lappend points [join [list \
                    [format %7s [trtm_format_float [trtm_get_path_property $path ${trace_point}_clock_latency]]] \
                    [lindex $arrows 2] \
                    [trtm_get_inst_or_port_names [trtm_get_path_property $path ${trace_point}_point]] \
                ] ""]
                incr print_index

            # Stop when print limit achieved
            } else {
                set hidden_flag 1
                break
            }
        }
    }

    # Results variable
    set results {}

    # Add leading arrows
    set point_index 0
    set point_count [llength $points]

    # First point arrow
    if {$point_count == 1} {
        set arrow [lindex $arrows 0 0]
    } else {
        set arrow [lindex $arrows 0 1]
    }

    foreach point $points {
        lappend results "$arrow[lindex $arrows 1]$point"
        incr point_index

        # Last point arrow
        if {$point_count-1 == $point_index} {
            set arrow [lindex $arrows 0 3]
        } else {
            set arrow [lindex $arrows 0 2]
        }
    }

    # Hidden arrow
    set arrow [lindex $arrows 0 4]

    # Print hidden status
    if { $hidden_flag } {
        lappend results "[format %-14s $arrow]..."
    } elseif { $need_chain } {
        lappend results {}
    }

    return [join $results "\n"]
}

################################################################################
# Create timing chain report for path collection
################################################################################
proc trtm_return_chain_timing_parameters {path_list analysis_type print_limit arrows show_list} {
    set results {}
    array set show_values {}

    trtm_debug_info "Parameters" "$path_list ([llength $path_list])"

    # Does additional analysis required?
    set analysis_required 0
    foreach parameter $::ns_trace_timing::analyzed_parameters {
        if { [lsearch -exact $show_list $parameter] != -1 } {
            set analysis_required 1
            break
        }
    }

    # Additional analysis
    foreach parameter $::ns_trace_timing::analyzed_parameters {
        if {[lsearch -exact $show_list $parameter] != -1} {
            foreach path $path_list {

                # Path is empty
                if { $path == {} } {
                    lappend show_values($parameter) {}

                # Path exists
                } else {
                    set point_from [trtm_get_path_property [trtm_get_path_property $path "launching_point"] hierarchical_name]
                    set point_to [trtm_get_path_property [trtm_get_path_property $path "capturing_point"] hierarchical_name]

                    switch $parameter {
                        setup {
                            lappend show_values($parameter) \
                                [trtm_format_float [trtm_get_path_list_property [trtm_report_path_list 1 -late \
                                    [list -from $point_from -to $point_to] \
                                ] slack ]]
                        }
                        setup_from {
                            lappend show_values($parameter) \
                                [trtm_format_float [trtm_get_path_list_property [trtm_report_path_list 1 -late \
                                    [list -from $point_from] \
                                ] slack ]]
                        }
                        setup_to {
                            lappend show_values($parameter) \
                                [trtm_format_float [trtm_get_path_list_property [trtm_report_path_list 1 -late \
                                    [list -to $point_to] \
                                ] slack ]]
                        }
                        hold {
                            lappend show_values($parameter) \
                                [trtm_format_float [trtm_get_path_list_property [trtm_report_path_list 1 -early \
                                    [list -from $point_from -to $point_to] \
                                ] slack ]]
                        }
                        hold_from {
                            lappend show_values($parameter) \
                                [trtm_format_float [trtm_get_path_list_property [trtm_report_path_list 1 -early \
                                    [list -from $point_from] \
                                ] slack ]]
                        }
                        hold_to {
                            lappend show_values($parameter) \
                                [trtm_format_float [trtm_get_path_list_property [trtm_report_path_list 1 -early \
                                    [list -to $point_to] \
                                ] slack ]]
                        }
                    }
                }
            }
        }
    }

    # Path parameters
    foreach parameter $::ns_trace_timing::standard_parameters {
        switch $parameter {
            arcs {
                set show_values($parameter) [trtm_get_path_list_property $path_list num_cell_arcs $::ns_trace_timing::default_show_value]
            }
            view {
                set show_values($parameter) [trtm_get_path_list_property $path_list view_name $::ns_trace_timing::default_show_value]
            }
            phase {
                set show_values($parameter) [trtm_get_path_list_property $path_list phase_shift $::ns_trace_timing::default_show_value]
            }
            period {
                set show_values($parameter) [trtm_get_path_list_property $path_list period $::ns_trace_timing::default_show_value]
            }
            skew {
                set show_values($parameter) [trtm_format_float [trtm_get_path_list_property $path_list skew]]
            }
            slew {
                foreach path $path_list {
                    catch {
                        set slews [lsearch -all -inline -not -exact \
                            [trtm_get_path_property [trtm_get_path_property $path timing_points] slew "NA"] \
                        "NA"]
                        lappend show_values($parameter) [lindex [lsort -real -decreasing $slews] 0]
                    }
                }
            }
            delay_worst {
                set show_values($parameter) [trtm_get_path_list_property $path_list worst_delay $::ns_trace_timing::default_show_value]
            }
            delay_total {
                set show_values($parameter) [trtm_get_path_list_property $path_list path_delay $::ns_trace_timing::default_show_value]
            }
            length_worst {
                set show_values($parameter) [trtm_get_path_list_property $path_list worst_manhattan_length $::ns_trace_timing::default_show_value]
            }
            length_total {
                set show_values($parameter) [trtm_get_path_list_property $path_list cumulative_manhattan_length $::ns_trace_timing::default_show_value]
            }
        }
    }

    # Launch-capture parameters
    foreach parameter $::ns_trace_timing::extended_parameters {
        if {[lsearch -exact $show_list $parameter] != -1} {
           foreach path $path_list {

                # Empty value for not existing paths
                if { $path == {} } {
                    lappend show_values($parameter) $::ns_trace_timing::default_show_value

                # Path exists
                } else {
                    switch $parameter {
                        clock {
                            lappend show_values($parameter) [concat \
                                [trtm_get_path_property [trtm_get_path_property $path launching_clock] hierarchical_name $::ns_trace_timing::default_show_value] \
                                "=>" \
                                [trtm_get_path_property [trtm_get_path_property $path capturing_clock] hierarchical_name $::ns_trace_timing::default_show_value] \
                            ]
                        }
                        clock_id {
                            lappend show_values($parameter) [concat \
                                [trtm_format_float [trtm_get_path_property $path launching_clock_source_arrival_time +0.000]] \
                                "=>" \
                                [trtm_format_float [trtm_get_path_property $path capturing_clock_source_arrival_time +0.000]] \
                            ]
                        }
                        pin_clock {
                            set points [trtm_get_path_property $path timing_points]
                            lappend show_values($parameter) [concat \
                                [file tail [trtm_get_path_property [index_collection $points 0] hierarchical_name $::ns_trace_timing::default_show_value]] \
                                "=>" \
                                [file tail [trtm_get_path_property [trtm_get_path_property $path capturing_clock_pin] hierarchical_name $::ns_trace_timing::default_show_value]] \
                            ]
                        }
                        pin_data {
                            set points [trtm_get_path_property $path timing_points]
                            if { [sizeof_collection $points] > 1 } {
                                set lpin [index_collection $points 1]
                                if { [trtm_get_path_property $lpin direction "in"] == "in" } {
                                    set lpin [index_collection $points 0]
                                }
                                set lpin [file tail [trtm_get_path_property $lpin hierarchical_name $::ns_trace_timing::default_show_value]]
                                set cpin [file tail [trtm_get_path_property [trtm_get_path_property $path capturing_point] hierarchical_name $::ns_trace_timing::default_show_value]]

                                lappend show_values($parameter) [concat $lpin "=>" $cpin]
                            } else {
                                lappend show_values($parameter) $::ns_trace_timing::default_show_value
                            }
                        }
                        input_delay {
                            set delay [trtm_get_path_property $path launching_input_delay]
                            if { [string is double $delay] } {
                                lappend show_values($parameter) $delay
                            } else {
                                lappend show_values($parameter) $::ns_trace_timing::default_show_value
                            }
                        }
                        output_delay {
                            if { ([trtm_get_path_property $path check_type] == "external_delay") } {
                                lappend show_values($parameter) [trtm_get_path_property $path check_delay 0]
                            } else {
                                lappend show_values($parameter) $::ns_trace_timing::default_show_value
                            }
                        }
                        latency {
                            lappend show_values($parameter) [concat \
                                [trtm_format_float [trtm_get_path_property $path launching_clock_latency]] \
                                "=>" \
                                [trtm_format_float [trtm_get_path_property $path capturing_clock_latency]] \
                            ]
                        }
                    }
                }
            }
        }
    }

    # Process values
    foreach parameter $show_list {
        trtm_debug_info "Reporting" [list $parameter $show_values($parameter)]
        lappend results [join [list \
            [format %-7s [lindex $arrows 0 2]] \
            $::ns_trace_timing::show_captions($parameter) \
            ": " \
            [join $show_values($parameter) {, }] \
        ] ""]
    }

    # Analysis
    if { ($analysis_type == "-early") } {
        set analysis_name "hold"
    } else {
        set analysis_name "setup"
    }

    # Report slacks
    set slacks [trtm_format_float [trtm_get_path_list_property $path_list slack]]
    lappend results [join [list \
        [format %-7s [lindex $arrows 0 2]] \
        $::ns_trace_timing::show_captions($analysis_name) \
        ": " \
        [join $slacks {, }] \
    ] ""]

    return [join $results "\n"]
}

################################################################################
# Create normal timing report for path collection
################################################################################
proc trtm_return_full_timing_paths {path_list analysis_args report_args print_limit separate} {

    # Separate reports
    if { $separate } {
        set reports {}
        set path_num 0

        foreach path $path_list {
            incr path_num
            if { ($path  != {}) && ($path_num <= $print_limit) } {
                set points_from [trtm_get_pin_names [trtm_get_path_property $path launching_point]]
                set points_to   [trtm_get_pin_names [trtm_get_path_property $path capturing_point]]

                # Run command without logging
                catch { unlogCommand report_timing }
                redirect -variable report {
                    eval [concat report_timing [join $analysis_args " "] [join $report_args " "] \
                        -max_paths 1 -from [list $points_from] -to [list $points_to]]
                }
                catch { logCommand report_timing }

                # Change path number
                set report [regsub -line -all {^Path\s+\d+:} $report "Path $path_num:"]

                # Append path to reports
                set reports "$reports$report"
            }
        }

    # Full trace reports
    } else {
        set points_from [trtm_get_pin_names [trtm_get_path_list_property $path_list launching_point]]
        set points_to   [trtm_get_pin_names [trtm_get_path_list_property $path_list capturing_point]]

        # Run command without logging
        catch { unlogCommand report_timing }
        redirect -variable reports {
           eval [concat report_timing [join $analysis_args " "] [join $report_args " "] \
                -max_paths $print_limit -from [list $points_from] -to [list $points_to]]
        }
        catch { logCommand report_timing }
    }

    # Remove comments
    set reports [regsub -line -all {^\#.*$\n} $reports {}]

    # Remove empty lines
    set reports [regsub -line -all {^\s*$\n} $reports {}]

    # Show hidden paths notification
    if { [llength $path_list] > $print_limit } {
        set reports "$reports# Note: some paths have been hidden. Use -print_all option to show it.\n"
    }

    return $reports
}

################################################################################
# Trace timing utility
################################################################################
proc trace_timing {args} {

    # Points to analyze
    set active_direction $::ns_trace_timing::default_direction
    set active_point_list $::ns_trace_timing::default_point_list

    # Reference
    set ref_points(-to) {}
    set ref_points(-from) {}
    set ref_points(-through) {}

    # Priority
    set options(-priority) {}
    set priority_points(-to) {}
    set priority_points(-from) {}
    set priority_points(-through) {}

    # Trace
    set options(-target) {}
    set target_points(-to) {}
    set target_points(-from) {}
    set target_points(-through) {}

    # Trace limit for all paths
    set options(-all_limit) $::ns_trace_timing::default_all_limit

    # Check type
    set analysis_type $::ns_trace_timing::default_analysis_type

    # Maximum path depth
    set options(-max_depth) $::ns_trace_timing::default_max_depth

    # Number of paths to trace
    set options(-all) 0
    set options(-trace_limit) $::ns_trace_timing::default_trace_limit
    set options(-target_limit) $::ns_trace_timing::default_target_limit

    # Number of paths to print
    set options(-print_limit) $::ns_trace_timing::default_print_limit
    set options(-print_limit_ref) $::ns_trace_timing::default_print_limit

    # Need to stop when loop to the paths found
    set options(-loop) 0

    # Filter results
    set options(-filter) 0

    # Trace each worst point separately
    set options(-separate) 0

    # Trace also IO worst path
    set options(-trace_ports) 0

    # Report format
    set options(-report) 0
    set options(-highlight) ""
    set options(-slack_colors) [list $::ns_trace_timing::color_norm $::ns_trace_timing::color_bad $::ns_trace_timing::color_good]

    # Machine-readable format
    set options(-machine_readable) 0

    # Parameters to show
    set filter_show_parameters_needed 1
    set options(-show) {}

    # Global report options
    set options(-print_all) 0
    set options(-show_all) 0

    # File to print
    set options(-file) {}

    # Hidden debug mode
    variable trtm_debug 0

    # Verbose mode
    set options(-verbose) 0
    set options(-verbose_title) {}

    # Report timing arguments
    set report_args {}
    set all_args {}
    set analysis_args {}

    # Internal variables
    set help 0
    set errors {}
    set option {}
    set switch {}

    # Print header
    puts $::ns_trace_timing::header

    ####################################################################################################
    # Parse arguments
    ####################################################################################################
    foreach arg $args {

        # Switch
        if { $option == "" } {
            set switch $arg
        }

        # Option
        set next_arg_option ""
        while { $option != "" } {

            # Current argument is switch
            set switch ""

            # Option to apply for current argument
            set current_arg_option ""

            switch -glob $option {
                -file -

                -max_depth -
                -all_limit -

                -trace_limit -
                -target_limit {set options($option) $arg}

                -print_limit {set options($option) $arg; set options(-print_limit_ref) $arg}

                -max_paths {set options(-trace_limit) $arg; set options(-print_limit) $arg; set options(-print_limit_ref) $arg}

                -clock_from -
                -clock_to -

                -min_slack -
                -max_slack -
                -nworst -
                -retime -

                -view {lappend analysis_args [concat $option [list $arg]]}

                -path_group {set options(-trace_ports) 1; lappend analysis_args [concat $option [list $arg]]}

                -format -
                -path_type {set options(-report) 1; lappend report_args [concat $option [list $arg]]}

                -show {set options($option) [concat $options($option) $arg]; set filter_show_parameters_needed 0}

                -not_through -
                -all_through -
                -through -
                -from -
                -to {
                    if { [string first "-" $arg] == 0 } {
                        set switch $option
                    } else {
                        switch $active_point_list {
                            ref {lappend ${active_point_list}_points($option) $arg}
                            analysis {lappend analysis_args [concat $active_direction [list $arg]]}
                            priority {lappend ${active_point_list}_points($option) [list $options(-${active_point_list}) $arg]}
                            target {lappend ${active_point_list}_points($option) [list $options(-${active_point_list}) $arg]}
                        }
                        set active_point_list $::ns_trace_timing::default_point_list
                        set active_direction $::ns_trace_timing::default_direction
                    }
                }

                -target -
                -priority {

                    # This is number
                    if { [string is integer $arg] } {
                        if { $options(-max_depth) < $arg } { set options(-max_depth) $arg }
                        set options($option) $arg
                        set next_arg_option $option

                    # This is switch
                    } elseif { [string first "-" $arg] == 0 } {
                        set switch $option

                    # Default direction used
                    } else {
                        set current_arg_option $active_direction
                    }
                }

                -highlight {

                    # This is number
                    if { [string is double $arg] } {
                        set options($option) $arg

                    # This is switch
                    } elseif { [string first "-" $arg] == 0 } {
                        set switch $option

                    # This is option value
                    } else {
                        set options($option) $arg
                    }
                }

                default {lappend errors "\033\[31;41m \033\[0m Unsupported option: '$option'. Run 'trace_timing -help' for more info.\n"}
            }

            # All arguments
            lappend all_args [list $option $arg]

            # Repeat option for current argument
            set option $current_arg_option
        }

        # Option to apply to the next argument
        set option $next_arg_option

        # Switches
        if { $switch != "" } {
            switch -glob $arg {
                --  {break}
                -init {lappend errors "\033\[37;47m \033\[0m Trace timing utility is now available. Run 'trace_timing -help' for more info.\n"}
                -help {set help 1}

                -priority {
                    set options($arg) 0
                    set active_direction $::ns_trace_timing::default_direction
                    set active_point_list priority
                    set option $arg
                }
                -target {
                    set options($arg) 0
                    set active_direction $::ns_trace_timing::default_direction
                    set active_point_list target
                    set option $arg
                }

                -all_through {
                    set active_direction -through
                    set option $arg
                    set active_point_list analysis
                }
                -not_through {
                    set options(-trace_ports) 1
                    set active_direction -not_through
                    set option $arg
                    set active_point_list analysis
                }

                -through -
                -from -
                -to {set active_direction $arg; set option $arg}

                -debug {set trtm_debug 1}

                -verbose -

                -loop -
                -filter -
                -separate -
                -trace_ports -
                -all -

                -report -

                -print_all -
                -show_all {set options($arg) 1; set filter_show_parameters_needed 1}

                -macros -
                -inputs -
                -outputs -
                -ports -
                -selected {
                    set objects {}

                    # Selection
                    if { $arg == "-selected" } {
                        set count 0

                        # Common UI mode
                        if { [info commands dbGet] == {} } {
                            foreach object [get_db selected -if {.obj_type == inst || .obj_type == port}] {
                                if { $count < $options(-all_limit) } {
                                    lappend objects [get_db $object .name]
                                    incr count
                                }
                            }

                        # Legacy mode support
                        } else {
                            foreach object [dbGet selected -e] {
                                if { [lsearch {inst term} [dbGet $object.objType]] != -1 } {
                                    if { $count < $options(-all_limit) } {
                                        lappend objects [dbGet $object.name]
                                    }
                                    incr count
                                }
                            }
                        }

                        #Limit objects
                        if { $count > [llength $objects] } {
                            puts "\n\033\[33;43m \033\[0m Too many selected objects to trace. Only first [llength $objects] of $count will be analyzed. Use -all_limit option to increase the limit."
                        }

                    # Templates
                    } else {
                        switch $arg {
                            -macros {set objects [all_registers -macros]}
                            -inputs {set objects [all_inputs]}
                            -outputs {set objects [all_outputs]}
                            -ports {set objects [concat [all_inputs] [all_outputs]]}
                        }
                        if { [sizeof_collection $objects] < 1 } {
                            set objects {}
                        }
                    }

                    if { $objects == {} } {
                        puts "\n\033\[33;43m \033\[0m No valid objects to trace for $arg template."

                    # Apply arguments to the required list
                    } else {
                        switch $active_point_list {
                            ref {lappend ${active_point_list}_points($active_direction) $objects}
                            analysis {lappend analysis_args [concat $active_direction [list $objects]]}
                            priority {lappend ${active_point_list}_points($active_direction) [list $options(-${active_point_list}) $objects]}
                            target {lappend ${active_point_list}_points($active_direction) [list $options(-${active_point_list}) $objects]}
                        }

                        # Next list is default
                        set active_point_list $::ns_trace_timing::default_point_list
                        set active_direction $::ns_trace_timing::default_direction
                    }
                }

                -highlight {set options($arg) slacks; set option $arg}
                -worst {set options(-slack_colors) [list {} $::ns_trace_timing::color_bad {}]}
                -bad {set options(-slack_colors) [list $::ns_trace_timing::color_norm $::ns_trace_timing::color_bad {}]}

                -late {set analysis_type $arg}
                -early {set analysis_type $arg}

                -unique_pins {lappend analysis_args $arg}

                -net {lappend report_args $arg; set options(-report) 1}
                -machine_readable {lappend report_args $arg; set options(-report) 1; set options($arg) 1}

                -* {set option $arg}

                default {lappend errors "\033\[31;41m \033\[0m Incorrect option: '$arg'. Run 'trace_timing -help' for more info.\n"}
            }
            lappend all_args $arg
        }
    }

    # Analysis type
    lappend analysis_args $analysis_type

    # Print all paths
    if { $options(-print_all) } {
        set options(-print_limit) $options(-trace_limit)
        set options(-print_limit_ref) $options(-all_limit)
    }

    # Print all chain info
    if { $options(-show_all) } {
        set options(-show) $::ns_trace_timing::all_show_parameters
        if { $filter_show_parameters_needed } {
            foreach filter_parameter $::ns_trace_timing::filter_show_parameters {
                set options(-show) [lsearch -all -inline -not -exact $options(-show) $filter_parameter]
            }
        }
    }

    # Filter results in target mode
    if { $options(-target) != {} } {
        set options(-filter) 1
    }

    ####################################################################################################
    # Error checking
    ####################################################################################################

    # Incorrect print limit
    if { ![string is integer $options(-print_limit)] || ($options(-print_limit) < 1) } {
        lappend errors "\033\[31;41m \033\[0m Incorrect -print_limit value $options(-print_limit).\n"
    }

    # Initialize timer for verbose mode
    if { $options(-verbose) } {
        report_resource -start "trace_timing"
    }

    upvar timing_enable_simultaneous_setup_hold_mode timing_enable_simultaneous_setup_hold_mode
    if { ((($analysis_type == "-late") && ([lsearch -exact $options(-show) "hold"] >= 0)) ||
          (($analysis_type == "-early") && ([lsearch -exact $options(-show) "setup"] >= 0)))} {
        if {[info exists timing_enable_simultaneous_setup_hold_mode]} {
            if { !$timing_enable_simultaneous_setup_hold_mode } {
                lappend errors "\033\[31;41m \033\[0m Cannot run setup and hold analysis simultaneously because this mode disabled."
                lappend errors "  To enable it, please run:"
                lappend errors "    set_global timing_enable_simultaneous_setup_hold_mode true"
            }
        } elseif {[info command is_attribute] != {}} {
            if {[is_attribute timing_enable_simultaneous_setup_hold_mode -obj_type root]} {
                if {![get_db timing_enable_simultaneous_setup_hold_mode]} {
                    lappend errors "\033\[31;41m \033\[0m Cannot run setup and hold analysis simultaneously because this mode disabled."
                    lappend errors "  To enable it, please run:"
                    lappend errors "    set_db timing_enable_simultaneous_setup_hold_mode true"
                }
            }
        }
    }

     # Options that cannot be used at the same time
    if { $options(-separate) && ($options(-target) != "") } {
        lappend errors "\033\[31;41m \033\[0m Cannot use -separate and -target options at the same time.\n"
    } elseif { $options(-separate) && $options(-filter) } {
        lappend errors "\033\[31;41m \033\[0m Cannot use -separate and -filter options at the same time.\n"
    }

    # Priority point list is not correct
    if { $active_point_list != $::ns_trace_timing::default_point_list } {
        lappend errors "\033\[31;41m \033\[0m Incorrect usage of '-$active_point_list' option. Run 'trace_timing -help' for more info.\n"

    } elseif { [lsearch {{} -highlight -from -to -through} $option] == -1 } {
        lappend errors "\033\[31;41m \033\[0m Incorrect or not properly defined option '$option'. Run 'trace_timing -help' for more info.\n"
    }

    foreach parameter $options(-show) {
        if {[lsearch -exact $::ns_trace_timing::all_show_parameters $parameter] == -1} {
            lappend errors "\033\[31;41m \033\[0m incorrect parameter '$parameter' to show."
        }
    }

    if { $options(-machine_readable) && ($options(-file) == "")} {
        lappend errors "\033\[31;41m \033\[0m option -machine_readable requires file to save the results (please use '-file' option)."
    }

    ####################################################################################################
    # Process parameters to show
    ####################################################################################################
    set show_list {}

    # Determine analysis type
    if { ($analysis_type == "-early") } {
        set analysis_name "hold"
    } else {
        set analysis_name "setup"
    }

    # Expand show options
    foreach option $options(-show) {
        switch $option {
            setup -
            hold {
                set analysis_name $option
                lappend show_list $option
            }
            from -
            to {
                lappend show_list ${analysis_name}_${option}
            }
            pin {
                lappend show_list pin_clock
                lappend show_list pin_data
            }
            delay {
                lappend show_list delay_worst
                lappend show_list delay_total
            }
            length {
                lappend show_list length_worst
                lappend show_list length_total
            }
            io_delay {
                lappend show_list input_delay
                lappend show_list output_delay
            }
            default {lappend show_list $option}
        }
    }

    # Filter parameters
    if { ($analysis_type == "-early") } {
        set show_list [lsearch -all -inline -not -exact $show_list hold]

    } else {
        set show_list [lsearch -all -inline -not -exact $show_list setup]
    }

    ####################################################################################################
    # Debug info
    ####################################################################################################
    if { $trtm_debug } {

        puts "\n# Analysis arguments"
        foreach option $analysis_args {
            puts "[lindex $option 0] [list [lindex $option 1]]"
        }

        puts "\n# Options"
        foreach option [array names options] {
            puts "$option [list $options($option)]"
        }

        puts "\n# Reference points"
        foreach option [array names ref_points] {
            puts "$option [list $ref_points($option)]"
        }

        puts "\n# Priority points"
        foreach option [array names priority_points] {
            puts "$option [list $priority_points($option)]"
        }

        puts "\n# Target points"
        foreach option [array names target_points] {
            puts "$option [list $target_points($option)]"
        }

        puts {}

    }

    ####################################################################################################
    # Main code
    ####################################################################################################

    # Print out error messages
    if { $errors != {} } {
        puts {}
        puts [join $errors "\n"]
    }

    # All is ok
    if { $help } {
        puts [subst -nocommands -nobackslashes $::ns_trace_timing::usage]

    # All is ok
    } elseif { $errors == {} } {

        # Target found flag
        set target_found 0

        # Define trace directions
        set isTo [expr [llength $ref_points(-to)] > 0]
        set isFrom [expr [llength $ref_points(-from)] > 0]
        set isThrough [expr [llength $ref_points(-through)] > 0]

        # Arguments to trace reference
        set ref_args {}
        set priority_args {}
        foreach direction {-from -to -through} {

            # Target and priority arguments. First element is stop flag
            if { ($ref_points($direction) == {}) || ($direction == "-through") } {
                foreach point $target_points($direction) {
                    lappend priority_args [list 1 [lindex $point 0] [list $direction [lindex $point 1]]]
                }
                foreach point $priority_points($direction) {
                    lappend priority_args [list 0 [lindex $point 0] [list $direction [lindex $point 1]]]
                }
            } elseif { $direction != "-through" } {
                if { $target_points($direction) != {} } {
                    puts "\033\[33;43m \033\[0m Target $direction direction disabled because the reference $direction used."
                }
                if { $priority_points($direction) != {} } {
                    puts "\033\[33;43m \033\[0m Priority $direction direction disabled because the reference $direction used."
                }
            }

            # Reference arguments
            if { $ref_points($direction) != {} } {
                lappend ref_args [list $direction $ref_points($direction)]
            }
        }

        # Exclude ports if no points requested (trace registers only)
        if { !$options(-trace_ports) && ($ref_args == {}) } {
            lappend ref_args [list -not_through [list [all_inputs] [all_outputs]]]
        }

        # Arguments info
        trtm_debug_info "Reference args" \n[join $ref_args \n]\n
        trtm_debug_info "Priority args" \n[join $priority_args \n]\n
        trtm_verbose_info "Trace reference path"

        # Trace all objects mode
        if { $options(-all) } {

            # Special case for -from, -to and -through directions combination
            if { ($isFrom && $isTo) || ($isThrough && ($isFrom || $isTo)) || (!$isFrom && !$isTo && !$isThrough) } {
                puts "\n\033\[37;47m \033\[0m First $options(-all_limit) reference paths are going to be analyzed. Use -all_limit option to increase the limit."
                trtm_debug_info "Reference trace: all points\n"

                # Trace reference point
                set path_collection_ref [trtm_trace_path_collection $analysis_args $priority_args \
                    $ref_args 0 $options(-all_limit) $options(-target_limit) target_found]

            # Only one of -from, -to, -through directions used
            } else {
                if { $isFrom } {
                    set direction -from
                } elseif { $isTo } {
                    set direction -to
                } else {
                    set direction -through
                }

                trtm_debug_info "Reference trace: all points one by one\n"

                set path_collection_ref {}
                foreach point [trtm_expand_collections $ref_points($direction)] {

                    # Limit reached
                    if { [sizeof_collection $path_collection_ref] >= $options(-all_limit) } {
                        puts "\n\033\[33;43m \033\[0m Too many objects to trace $direction. Only first $options(-all_limit) will be analyzed. Use -all_limit option to increase the limit."
                        break

                    # Create collection
                    } else {
                        append_to_collection path_collection_ref [trtm_trace_path_collection $analysis_args $priority_args \
                            [list $direction [list $point]] 0 1 1 target_found]
                    }
                }
                set path_collection_ref [sort_collection $path_collection_ref slack]
            }

        # Standard trace
        } else {

            # Trace reference point
            trtm_debug_info "Reference trace: standard\n"
            set path_collection_ref [trtm_trace_path_collection $analysis_args $priority_args \
                $ref_args 0 $options(-trace_limit) $options(-target_limit) target_found]
        }

        # Convert path collection to list
        set path_list_ref [trtm_path_collection_to_list $path_collection_ref]
        trtm_debug_info "Reference paths" "$path_collection_ref ([sizeof_collection $path_collection_ref])"

        # Target found in target mode
        if { $target_found == 1 } {
            puts "\n\033\[37;47m \033\[0m Target found in reference paths."

        # Loop to the reference point
        } elseif { $target_found == 2 } {
            puts "\n\033\[37;47m \033\[0m Loop to the reference point in reference paths."
        }

        # Trace in both directions
        if { $target_found } {
            set isFrom 0
            set isTo 0

        } elseif { !$isFrom && !$isTo } {
            if { $active_direction != "-to"} { set isFrom 1 }
            if { $active_direction != "-from"} { set isTo 1 }
        }

        trtm_verbose_info
        puts {}

        # If path not found
        if {[llength $path_list_ref] < 1} {
            puts "\033\[33;43m \033\[0m No timing arcs found. Try -target or -trace_limit options.\n"

        # If path exists
        } else {

            # Launch and capture paths
            set points_launch  [trtm_get_inst_names [trtm_get_path_list_property $path_list_ref launching_point]]
            set points_capture [trtm_get_inst_names [trtm_get_path_list_property $path_list_ref capturing_point]]

            # Trace timing from
            if { $isFrom && ([llength $points_capture] > 0)} {
                trtm_verbose_info "Trace timing chains 'from'"

                # Priority trace
                set priority_args {}

                # Loop trace
                if { $options(-loop) } {
                    lappend priority_args [list 2 0 [list -to $points_launch]]
                }

                # Target and priority arguments
                foreach direction {-to -through} {
                    foreach point $target_points($direction) {
                        lappend priority_args [list 1 [lindex $point 0] [list $direction [lindex $point 1]]]
                    }
                    foreach point $priority_points($direction) {
                        lappend priority_args [list 0 [lindex $point 0] [list $direction [lindex $point 1]]]
                    }
                }

                # Do trace
                set path_lists_from [lreverse [trtm_trace_timing_chains \
                    "FROM" $points_capture $analysis_args $priority_args \
                    $options(-max_depth) $options(-trace_limit) $options(-target_limit) $options(-print_limit) \
                    $options(-separate) $options(-filter) \
                ]]
                trtm_verbose_info
                puts {}

            } else {
                set path_lists_from {}
            }

            # Trace timing to
            if { $isTo && ([llength $points_launch] > 0) } {

                # Priority trace
                set priority_args {}

                # Loop trace
                if { $options(-loop) } {
                    lappend priority_args [list 2 0 [list -from $points_capture]]
                }

                # Target and priority arguments
                foreach direction {-from -through} {
                    foreach point $target_points($direction) {
                        lappend priority_args [list 1 [lindex $point 0] [list $direction [lindex $point 1]]]
                    }
                    foreach point $priority_points($direction) {
                        lappend priority_args [list 0 [lindex $point 0] [list $direction [lindex $point 1]]]
                    }
                }

                # Do trace
                trtm_verbose_info "Trace timing chains 'to'"
                set path_lists_to [trtm_trace_timing_chains \
                    "TO" $points_launch $analysis_args $priority_args \
                    $options(-max_depth) $options(-trace_limit) $options(-target_limit) $options(-print_limit) \
                    $options(-separate) $options(-filter) \
                ]
                trtm_verbose_info
                puts {}

            } else {
                set path_lists_to {}
            }

            # Filter reference paths
            if { $options(-filter) && !$options(-all) } {

                # Capture points
               if { [llength $path_lists_from] > 0 } {
                    set points_capture [trtm_get_inst_or_port_names [trtm_get_path_list_property \
                        [lindex [lreverse $path_lists_from] 0] launching_point]]
                } else {
                    set points_capture [get_property $path_collection_ref capturing_point]
                }

                # Launch points
                if { [llength $path_lists_to] > 0 } {
                    set points_launch [trtm_get_inst_or_port_names [trtm_get_path_list_property \
                        [lindex $path_lists_to 0] capturing_point]]
                } else {
                    set points_launch [get_property $path_collection_ref launching_point]
                }

                # Filter reference
                if { ($points_launch != {}) && ($points_capture != {}) } {
                    set command [concat report_timing [join $analysis_args " "] \
                        -from [list $points_launch] -to [list $points_capture] \
                        -max_paths $options(-trace_limit) -collection]

                    trtm_debug_info "Filter reference" $command\n

                    # Run command without logging
                    catch { unlogCommand report_timing }
                    set path_collection_ref_filtered [eval $command]
                    catch { logCommand report_timing }

                    if { [sizeof_collection $path_collection_ref_filtered] > 0 } {
                        set path_collection_ref $path_collection_ref_filtered
                        set path_list_ref [trtm_path_collection_to_list $path_collection_ref]

                    # Cannot filter reference
                    } else {
                        puts "\033\[33;43m \033\[0m Cannot perform filtering of the reference chain because it does not connect -from and -to chains."
                        puts "      Try to narrow the reference point list.\n"
                    }
                }
            }

            # Chain report results
            if { ($options(-report) == 0) || ($options(-report) && ($options(-file) != ""))} {

                set results {}
                set chain_info {}

                # Append trace timing header
                lappend results $::ns_trace_timing::report_header
                set path_list_to_count [llength $path_lists_to]

                # Return chain from
                trtm_verbose_info "Report paths 'from'"
                foreach path_list $path_lists_from {
                    lappend results [trtm_return_chain_timing_points $path_list $analysis_type \
                        $options(-print_limit) $::ns_trace_timing::arrow_ncapt 0 "capturing"]
                    lappend results [trtm_return_chain_timing_parameters $path_list $analysis_type \
                        $options(-print_limit) $::ns_trace_timing::arrow_ncapt $show_list]
                    lappend results [trtm_return_chain_timing_points $path_list $analysis_type \
                        $options(-print_limit) $::ns_trace_timing::arrow_nlnch 1 "launching"]

                }
                trtm_verbose_info 0

                # Return reference chain
                trtm_verbose_info "Report reference path"
                lappend results [trtm_return_chain_timing_points $path_list_ref $analysis_type \
                    $options(-print_limit_ref) $::ns_trace_timing::arrow_rcapt 0 "capturing"]
                lappend results [trtm_return_chain_timing_parameters $path_list_ref $analysis_type \
                    $options(-print_limit_ref) $::ns_trace_timing::arrow_rcapt $show_list]
                lappend results [trtm_return_chain_timing_points $path_list_ref $analysis_type \
                    $options(-print_limit_ref) $::ns_trace_timing::arrow_rlnch [expr ($path_list_to_count > 0)] "launching"]
                trtm_verbose_info 0

                # Return chain to
                trtm_verbose_info "Report paths 'to'"
                set path_list_index 0
                foreach path_list $path_lists_to {
                    incr path_list_index
                    lappend results [trtm_return_chain_timing_points $path_list $analysis_type \
                        $options(-print_limit) $::ns_trace_timing::arrow_ncapt 0 "capturing"]
                    lappend results [trtm_return_chain_timing_parameters $path_list $analysis_type \
                        $options(-print_limit) $::ns_trace_timing::arrow_ncapt $show_list]
                    lappend results [trtm_return_chain_timing_points $path_list $analysis_type \
                        $options(-print_limit) $::ns_trace_timing::arrow_nlnch [expr ($path_list_to_count > $path_list_index)] "launching"]
                }
                trtm_verbose_info 0

                lappend results {}
                puts [join $results "\n"]
            }

            # Full timing report results
            if { $options(-report) } {
                set results {}

                # Return timing from
                trtm_verbose_info "Report paths 'from'"
                set chain_counter [llength $path_lists_from]
                foreach path_list $path_lists_from {
                    lappend results "##################################################"
                    lappend results "# Chain $chain_counter from the reference one"
                    lappend results "##################################################"
                    lappend results [trtm_return_full_timing_paths $path_list $analysis_args $report_args $options(-print_limit) $options(-separate)]

                    set chain_counter [expr $chain_counter-1]
                }
                trtm_verbose_info 0

                # Return reference timing
                trtm_verbose_info "Report reference paths"
                lappend results "##################################################"
                lappend results "# Reference chain"
                lappend results "##################################################"
                lappend results [trtm_return_full_timing_paths $path_list_ref $analysis_args $report_args $options(-print_limit_ref) 0]
                trtm_verbose_info 0

                # Return timing to
                set chain_counter 1
                trtm_verbose_info "Report paths 'to'"
                foreach path_list $path_lists_to {
                    lappend results "##################################################"
                    lappend results "# Chain $chain_counter to the reference one"
                    lappend results "##################################################"
                    lappend results [trtm_return_full_timing_paths $path_list $analysis_args $report_args $options(-print_limit) $options(-separate)]

                    incr chain_counter
                }
                trtm_verbose_info 0

            }

            # Print the results
            if { $options(-file) == "" } {
                if { $options(-report) } {
                    puts [join $results "\n"]
                }

            # ... to file
            } else {
                redirect $options(-file) {
                    puts "$::ns_trace_timing::header\n"
                    puts "##################################################"
                    puts "# Command line arguments:"
                    puts [join [list "##################################################" [join [split $args "-"] "\n#  -"]] ""]
                    puts {}

                    puts [join $results "\n"]
                }

                if { $options(-machine_readable) } {
                    puts "\033\[37;47m \033\[0m Post-processing machine-readable data..."
                    exec perl -e $::ns_trace_timing::trtm_mtarpt_postprocess $options(-file)
                }

                if { $options(-report) } {
                    if { $options(-machine_readable) } {
                        puts "\033\[37;47m \033\[0m Machine-readable report have been saved to '$options(-file)'.\n"
                    } else {
                        puts "\033\[37;47m \033\[0m Timing report have been saved to '$options(-file)'.\n"
                    }
                } else {
                    puts "\033\[37;47m \033\[0m Chain report have been saved to '$options(-file)'.\n"
                }
            }

            # Highlight paths in GUI
            if { $options(-highlight) != "" } {

                trtm_verbose_info "Highlight chains"

                catch {

                    # Clear previous highlight without logging
                    catch { unlogCommand dehighlight }
                    foreach index {10 11 12 13 14 15 16 17 18} {
                        if {[info command gui_clear_highlight]!={}} {
                            catch {gui_clear_highlight -index $index}
                        } else {
                            catch {dehighlight -index $index}
                        }
                    }
                    catch { logCommand dehighlight }

                    # Chain-based highlight
                    if { $options(-highlight) == "direction" } {
                        set threshold ""

                    # User defined slack threshold
                    } elseif { [string is double $options(-highlight)] } {
                        set threshold $options(-highlight)

                    # Auto slack threshold
                    } else {
                        set threshold [expr 0.5*[lindex [get_property $path_collection_ref slack] 0]]
                    }

                    # Status
                    if { $threshold != "" } {
                        if { $threshold > 0 } {
                            set threshold_status "red < 0"
                            if { [lsearch -exact $options(-slack_colors) $::ns_trace_timing::color_norm] != -1 } {
                                set threshold_status "$threshold_status < yellow"
                                if { [lsearch -exact $options(-slack_colors) $::ns_trace_timing::color_good] != -1 } {
                                    set threshold_status "$threshold_status < $threshold < green"
                                }
                            }
                        } else {
                            set threshold_status "red < $threshold"
                            if { [lsearch -exact $options(-slack_colors) $::ns_trace_timing::color_norm] != -1 } {
                                set threshold_status "$threshold_status < yellow"
                                if { [lsearch -exact $options(-slack_colors) $::ns_trace_timing::color_good] != -1 } {
                                    set threshold_status "$threshold_status < 0 < green"
                                }
                            }
                        }
                    }

                    # Highlight chains in direction mode
                    if { $threshold == "" } {
                        puts "\033\[37;47m \033\[0m Highlighting 'from' chains with green color..."
                        trtm_highlight_path_lists $path_lists_from lightgreen 10 $threshold

                        puts "\033\[37;47m \033\[0m Highlighting 'to' chains with blue color..."
                        trtm_highlight_path_lists $path_lists_to lightblue 13 $threshold

                        puts "\033\[37;47m \033\[0m Highlighting reference chain with yellow color..."
                        trtm_highlight_path_lists [list $path_list_ref] yellow 16 $threshold

                    # Highlight chains in slack-based mode
                    } else {
                        puts "\033\[37;47m \033\[0m Highlighting chains with slack-based colors ($threshold_status)..."
                        trtm_highlight_path_lists \
                            [concat $path_lists_from $path_lists_to $path_list_ref] \
                            $options(-slack_colors) 10 $threshold
                    }
                }

                trtm_verbose_info
                puts {}
            }
        }

        # Report TAT summary
        if { $options(-verbose) } {
            report_resource -end "trace_timing"
            puts {}
        }

    }
}

################################################################################
} # Trace timing utility namespace
################################################################################

################################################################################
# Enable auto-completion
################################################################################
alias trace_timing ns_trace_timing::trace_timing

catch { unlogCommand define_proc_arguments }
catch {
    define_proc_arguments trace_timing -define_args [subst -nocommands -nobackslashes {
        { -help "" "" boolean optional }

        { -all "" "" one_of_string {optional {values {-selected -ports -inputs -outputs -macros}}} }
        { -from  "" "" one_of_string {optional {values {-selected -ports -inputs -outputs -macros}}} }
        { -to "" "" one_of_string {optional {values {-selected -ports -inputs -outputs -macros}}} }
        { -through "" "" one_of_string {optional {values {-selected -ports -inputs -outputs -macros}}} }
        { -all_through "" "" one_of_string {optional {values {-selected -ports -inputs -outputs -macros}}} }

        { -priority "" "" one_of_string {optional {values {1 2 3 4 5 -from -to -through -selected -ports -inputs -outputs -macros}}} }
        { -target "" "" one_of_string {optional {values {1 2 3 4 5 -from -to -through -selected -ports -inputs -outputs -macros}}} }

        { -selected "" "" boolean optional }
        { -macros "" "" boolean optional }
        { -inputs "" "" boolean optional }
        { -outputs "" "" boolean optional }
        { -ports "" "" boolean optional }

        { -all_limit "" "" boolean optional }
        { -loop "" "" boolean optional }
        { -filter "" "" boolean optional }
        { -separate "" "" boolean optional }
        { -trace_ports "" "" boolean optional }
        { -max_depth "" "" one_of_string {optional {values {0 1 2 3 4 5}}} }
        { -trace_limit "" "" integer optional }
        { -target_limit "" "" integer optional }

        { -print_limit "" "" integer optional }
        { -max_paths "" "" integer optional }
        { -print_all "" "" boolean optional }
        { -show_all "" "" boolean optional }
        { -verbose "" "" boolean optional }
        { -highlight "" "" one_of_string {optional {values {slacks direction -0.1 -0.05 0 0.05 0.1}}} }
        { -bad "" "" boolean optional }
        { -worst "" "" boolean optional }

        { -late "" "" boolean optional }
        { -early "" "" boolean optional }
        { -unique_pins "" "" boolean optional }
        { -report "" "" boolean optional }
        { -net "" "" string optional }
        { -machine_readable "" "" boolean optional }

        { -clock_from "" "" string optional }
        { -clock_to "" "" string optional }
        { -not_through "" "" string optional }
        { -min_slack "" "" float optional }
        { -max_slack "" "" float optional }
        { -nworst "" "" float optional }
        { -retime "" "" boolean optional }
        { -view "" "" string optional }
        { -path_group "" "" one_of_string {optional {values {reg2reg reg2cgate default}}} }
        { -format "" ""  one_of_string {optional {values {adjustment annotation aocv_adj_stages aocv_derate aocv_weight arc arrival arrival_mean arrival_sigma cell delay delay_mean delay_sensitivity delay_sigma direction edge fanin fanout flags hpin incr_delay instance instance_location load net phase phys_info pin pin_load pin_location power_domain required retime_delay retime_delay_sensitivity retime_delay_sigma retime_transition_mean retime_transition retime_transition_sensitivity retime_transition_sigma stage_count stolen timing_point transition transition_mean transition_sensitivity user_derate when_cond transition_sigma wire_load wlmodel}}} }
        { -path_type "" "" one_of_string {optional {values {end end_slack_only full full_clock summary summary_slack_only}}} }
        { -show "" "" one_of_string {optional {values {$::ns_trace_timing::all_show_parameters}}} }

        { -file "" "" one_of_string {optional {values {trace.rpt trace.tarpt trace.mtarpt}}} }
    }]
}
catch { logCommand define_proc_arguments }

################################################################################
# Enable command logging and show init message
################################################################################

catch {logCommand trace_timing}
trace_timing -init
