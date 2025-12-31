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
# Filename: bin/gconfig.tcl
# Purpose:  Generic Configuration toolkit
################################################################################

# Generic configuration namespace
catch {namespace delete gconfig}
namespace eval gconfig {

    # ------------------
    # Internal functions
    # ------------------

    # Result variables
    variable search_paths {}
    variable total_tests 0
    variable passed_results {}
    variable failed_results {}
    variable new_results {}
    variable test_output {}
    variable test_result {}
    variable test_compare {}

    # Configuration basic test command
    proc test_command {command {reference_result {}}} {
        set gconfig::total_tests [expr $gconfig::total_tests + 1]
        
        # Command
        puts "\033\[34m$command\033\[0m"
        uplevel 0 {
            rename puts gconfig::puts_original
        }
        
        # Evaluate command
        catch {
            set gconfig::test_output {}
            proc puts args {
                append gconfig::test_output [lindex $args end]
                if {[lsearch -regexp $args {^-nonewline}] < 0} {
                    append gconfig::test_output "\n"
                }
                return {}
            }

            # Run command
            set start_time [clock clicks]
            set finish_time $start_time
            uplevel "set gconfig::test_result \[eval {$command}\]"
            set finish_time [clock clicks]
        } {
            puts "\033\[31;41m \033\[0m Command is incorrect."
        }
        
        uplevel 0 {
            rename puts {}
            rename gconfig::puts_original puts
        }
        
        set result $gconfig::test_result
        if {[regexp "^\{\{" $result]} {
            set result "  [join $result "\n  "]"
        }
        
        # Check reference
        set full_result $gconfig::test_output$result
        set escaped_result $full_result
        set escaped_result [regsub -all {\\} $escaped_result {\\\\}]
        set escaped_result [regsub -all {\033} $escaped_result {\\033}]
        set escaped_result [regsub -all {\"} $escaped_result {\"}]
        set escaped_result [regsub -all {\n} $escaped_result {\n}]
        set escaped_result [regsub -all {\$} $escaped_result {\$}]
        set escaped_result [regsub -all {\[} $escaped_result {\\[}]
        set escaped_result [regsub -all {\]} $escaped_result {\\]}]
        
        if {$full_result == $reference_result} {
            puts [regsub -all -line {^} $full_result "\033\[32;42m \033\[0m "]
            lappend gconfig::passed_results [list $command $escaped_result $full_result]
        } else {
            if {$reference_result == {}} {
                lappend gconfig::new_results [list $command $escaped_result $full_result]
                puts "\033\[35m\"$escaped_result\"\033\[0m"
                puts "[regsub -all -line {^} $full_result "\033\[33;43m \033\[0m "]"
            } else {
                lappend gconfig::failed_results [list $command $escaped_result $reference_result $full_result]
                puts "\033\[35m\"$escaped_result\"\033\[0m"
                puts "[regsub -all -line {^} $reference_result "\033\[33;43m \033\[0m "]"
                puts "[regsub -all -line {^} $full_result "\033\[31;41m \033\[0m "]"
            }
        }

        puts "\033\[34m[expr ($finish_time-$start_time)/1000.0]ms\033\[0m\n"
        
        return $gconfig::test_result
    }

    # Compare reference and tested results
    proc test_summary {args} {

        # Print comparizn data when needed
        if {[lsearch -exact $args {-compare}] != -1} {
            if {[llength $gconfig::failed_results] > 0} {
                print_title {Test compare - reference results}
                foreach result $gconfig::failed_results {
                    puts "\033\[34m[lindex $result 0]\033\[0m"
                    puts "[lindex $result 2]\n"
                }
                
                print_title {Test compare - current results}
                foreach result $gconfig::failed_results {
                    puts "\033\[34m[lindex $result 0]\033\[0m"
                    puts "[lindex $result 3]\n"
                }
            }
        }
        
        print_title {Test summary}
        puts " Total: \033\[94m$gconfig::total_tests\033\[0m"
        puts "Passed: \033\[92m[llength $gconfig::passed_results]\033\[0m"
        puts "Failed: \033\[91m[llength $gconfig::failed_results]\033\[0m"
        puts "   New: \033\[93m[llength $gconfig::new_results]\033\[0m"
        puts {}
        
        # foreach result $gconfig::failed_results {
            # puts "\033\[34m[lindex $result 0]\033\[0m"
            # puts "[regsub -all -line {^} [lindex $result 3] "\033\[31;41m \033\[0m "]\n"
        # }

        # print_title {New}
        # foreach result $gconfig::new_results {
            # puts "\033\[34m[lindex $result 0]\033\[0m"
            # puts "[regsub -all -line {^} [lindex $result 2] "\033\[33;43m \033\[0m "]\n"
        # }
        
        set gconfig::total_tests 0
        set gconfig::failed_results {}
        set gconfig::new_results {}
        set gconfig::test_output {}
        set gconfig::test_result {}
    }

    variable messages {}

    # Set file search paths
    proc set_search_paths {paths} {
        set gconfig::search_paths $paths
    }

    # Parse command line arguments
    proc parse_arguments {options default_parameter parameters multiple_parameters args} {
        set results {}
        set key {}
        set next_key {}
        set only_first_default [expr {[lsearch -exact [concat $parameters $multiple_parameters] $default_parameter] == -1}]
        foreach arg $args {
            if {$key == ""} {
                if {[lsearch -exact $options $arg] != -1} {
                    lappend results $arg
                } elseif {[lsearch -exact $parameters $arg] != -1} {
                    set key $arg
                    set next_key {}
                } elseif {[lsearch -exact $multiple_parameters $arg] != -1} {
                    set key $arg
                    set next_key $arg
                } elseif {$next_key != {}} {
                    lappend results [list $next_key $arg]
                } elseif {($default_parameter != {}) && (($results == {}) || !$only_first_default)} {
                    lappend results [list $default_parameter $arg]
                } else {
                    print_message {ERROR} "Incorrect \033\[91m$arg\033\[0m option"
                }
            } else {
                lappend results [list $key $arg]
                set key {}
            }
        }
        return $results
    }

    # Parse command line arguments
    proc parse_proc_arguments {args} {
        set parameters {}
        set options {}
        set arguments {}
        foreach arg_pair [eval "parse_arguments {} -arguments {-parameters -options} {-arguments} $args"] {
            set arg [lindex $arg_pair 0]
            if {$arg == {-parameters}} {
                set parameters [concat $parameters [lindex $arg_pair 1]]

            # Multiple switches can be activated in the group
            } elseif {$arg == {-options}} {
                set options [concat $options [lindex $arg_pair 1]]

            # Arguments
            } else {
                set arguments [concat $arguments [lindex $arg_pair 1]]
            }
        }
        return [eval "parse_arguments {$options} {} {$parameters} {} $arguments"]
    }

    # Return colorized condition for messages
    proc colorize_condition {condition} {
        if {($condition == {}) || ($condition == "default")} {
            return {}
        } else {
            return "\033\[94m[regsub -all {, } $condition "\033\[0m, \033\[94m"]\033\[0m"
        }
    }

    # Create filtering message
    proc create_filter_message {condition mask} {
        set condition [colorize_condition [lindex $condition 0]]
        set mask [lindex $mask 2]
        if {($condition != {}) && ($mask != {})} {
            return " (condition $condition, mask {\033\[97m$mask\033\[0m})"
        } elseif {$condition != {}} {
            return " (condition $condition)"
        } elseif {$mask != {}} {
            return " (mask {\033\[97m$mask\033\[0m})"
        } else {
            return {}
        }
    }

    # Check if errors took place after the last check
    variable error_count 0
    variable warning_count 0
    proc get_error_count {} {
        set result $gconfig::error_count
        set gconfig::error_count 0
        return $result
    }
    proc get_warning_count {} {
        set result $gconfig::warning_count
        set gconfig::warning_count 0
        return $result
    }

    # Print message
    variable print_message_mode {print}
    proc print_message {type message} {
        if {$type == {ERROR}} {
            set result "\033\[31;41m \033\[0m "
            incr gconfig::error_count
        } elseif {$type == {WARNING}} {
            set result "\033\[33;43m \033\[0m "
            incr gconfig::warning_count
        } elseif {$type == {INFO}} {
            set result "\033\[37;47m \033\[0m "
        } else {
            set result "$type:"
        }

        # Append message
        append result " $message"
        
        # Queue only unique message
        if {$gconfig::print_message_mode == {queue}} {
            if {[lsearch -exact $gconfig::messages $result] == -1} {
                lappend gconfig::messages $result
                return $result
            } else {
                return {}
            }
            
        # Print message immediately
        } else {
            puts $result
            return {}
        }
    }

    # Print messages in queue
    proc queue_messages {} {
        print_messages
        set gconfig::messages {}
        set gconfig::print_message_mode {queue}
    }

    # Print messages in queue
    proc print_messages {} {
        foreach message $gconfig::messages {
            puts $message
        }
        set gconfig::messages {}
        set gconfig::print_message_mode {print}
    }

    # Remove color from text
    proc remove_color {text} {
        return [regsub -all "\033\\\[\[0-9;\]+m" $text {}]
    }

    # Print title
    proc print_title {title} {
        set title [remove_color $title]
        set divider "===="
        set length 0
        set needed_length [string length $title]
        while {$length < $needed_length} {
            append divider "="
            incr length
        }
        puts $divider
        puts "  \033\[97m$title\033\[0m"
        puts $divider\n
    }

    # Print title
    proc print_subtitle {subtitle} {
        set divider "----"
        set length 0
        set needed_length [string length [remove_color $subtitle]]
        while {$length < $needed_length} {
            append divider "-"
            incr length
        }
        puts $divider
        puts "  $subtitle"
        puts $divider\n
    }

    # Filter groups by index and value
    proc filter_groups {groups index value} {
        set results {}
        foreach group $groups {
            if {[lindex $group $index] == $value} {
                lappend results $group
            }
        }
        return $results
    }

    # ---------------
    # Manage switches
    # ---------------

    # Internal variables
    variable defined_switches {}
    variable active_switches {}
    variable switch_groups {}

    # Define user switches
    proc define_switches {args} {
        set results {}

        # Command line arguments
        set multiple {single}
        set required {required}
        set group {}

        # Parse arguments
        foreach arg_pair [eval "parse_arguments {-single -multiple -required -optional} -switches {-group -group_name} {-switch -switches} $args"] {
            set arg [lindex $arg_pair 0]
            if {[lsearch -exact {-group -group_name} $arg] != -1} {
                set group [lindex $arg_pair 1]

            } elseif {$arg == {-single}} {
                set multiple {single}

            # Multiple switches can be activated in the group
            } elseif {$arg == {-multiple}} {
                set multiple {multiple}

            # At least one of the switches should be active in the group
            } elseif {$arg == {-required}} {
                set required {required}

            # Switches can be active in the group but not should
            } elseif {$arg == {-optional}} {
                set required {optional}

            } else {
                if {$group == {}} {
                    set group {default}
                    set multiple {multiple}
                    set required {optional}
                }
                foreach switch [lindex $arg_pair 1] {
                
                    # New switch
                    if {[lsearch -exact $gconfig::defined_switches $switch] == -1} {
                        if {[check_switch_name $switch] != {}} {
                            lappend results $switch
                            lappend gconfig::defined_switches $switch
                            lappend gconfig::switch_groups [list $switch $group $required $multiple]
                        }

                    # Switch defined several times
                    } else {
                        print_message {WARNING} "Switch \033\[91m$switch\033\[0m already defined."
                    }
                }
                set multiple {single}
                set required {required}
                set group {}
            }
        }

        return $results
    }

    # Check if switch defined
    proc check_switch {switch_name} {
        if {[lsearch -exact $gconfig::defined_switches $switch_name] == -1} {
            print_message {WARNING} "Switch \033\[91m$switch_name\033\[0m is not defined. Use gconfig::\033\[97mdefine_switches\033\[0m command to define."
            return {}
        } else {
            return $switch_name
        }
    }

    # Check if switch enabled
    proc is_switch_enabled {switch_name} {
        check_switch $switch_name
        return [expr {[lsearch -exact $gconfig::active_switches $switch_name] != -1}]
    }

    # Check switch name
    proc check_switch_name {name} {
        if {[regexp {^[0-9a-zA-Z\_]+$} $name]} {
            return $name
        } else {
            print_message {ERROR} "Switch \033\[91m$name\033\[0m name should contain only alphanumeric characters."
            return {}
        }
    }

    # Enable switches
    proc enable_switches {args} {
        set results {}

        # Show switches when no arguments used
        if {$args == {}} {
            set results [show_switches]

        # Parse arguments
        } else {
            set silent 0
            set switch_patterns {}
            set group_patterns {}
            foreach arg_pair [eval "parse_arguments {-silent} -switches {-group} {-switch -switches} $args"] {
                if {[lindex $arg_pair 0] == {-silent}} {
                    set silent 1

                # Switch groups
                } elseif {[lindex $arg_pair 0] == {-group}} {
                    foreach switch_group $gconfig::switch_groups {
                        if {[string match [lindex $arg_pair 1] [lindex $switch_group 1]]} {
                            lappend switch_patterns [lindex $switch_group 0]
                        }
                    }

                # Switch patterns
                } else {
                    lappend switch_patterns [lindex $arg_pair 1]
                }
            }

            # Check switch patterns
            foreach switch_pattern $switch_patterns {
            
                # Check if switch already disabled
                set is_matched 0
                foreach switch $gconfig::defined_switches {
                    if {[string match $switch_pattern $switch]} {
                        if {[is_switch_enabled $switch]} {
                            if {!$silent} {print_message {INFO} "Switch \033\[97m$switch\033\[0m already enabled."}
                            
                        # Enable switch once
                        } else {

                            # Check all groups where switch used
                            foreach switch_group [filter_groups $gconfig::switch_groups 0 $switch] {

                                # Disable single switches in the same switch group
                                if {[lindex $switch_group 3] == {single}} {
                                    foreach other_group [filter_groups $gconfig::switch_groups 1 [lindex $switch_group 1]] {
                                        if {[lindex $other_group 0] != $switch} {
                                            if {[is_switch_enabled [lindex $other_group 0]]} {
                                                disable_switches [lindex $other_group 0]
                                            }
                                        }
                                    }
                                }
                            }
                            if {!$silent} {print_message {INFO} "Switch \033\[97m$switch\033\[0m enabled."}
                            lappend results $switch
                            lappend gconfig::active_switches $switch
                        }
                        set is_matched 1
                    }
                }
                
                # Not matched switch warning
                if {!$is_matched} {
                    if {[regexp {[\*\?]} $switch_pattern]} {
                        if {!$silent} {
                            print_message {WARNING} "No switches matching pattern \033\[91m$switch_pattern\033\[0m defined. Use gconfig::\033\[97mdefine_switches\033\[0m command to define."
                        }
                    } else {
                        if {!$silent} {
                            print_message {INFO} "Switch \033\[97m$switch_pattern\033\[0m enabled."
                            print_message {WARNING} "Switch \033\[91m$switch_pattern\033\[0m is not defined. Use gconfig::\033\[97mdefine_switches\033\[0m command to define."
                        }
                        lappend results $switch_pattern
                        lappend gconfig::active_switches $switch_pattern
                    }
                }
            }
        }

        return $results
    }

    # Disable switches
    proc disable_switches {args} {
        set results {}

        # Show switches when no arguments used
        if {$args == {}} {
            set results [show_switches]

        # Parse arguments
        } else {
            set silent 0
            set switch_patterns {}
            set group_patterns {}
            foreach arg_pair [eval "parse_arguments {-silent} -switches {-group} {-switch -switches} $args"] {
                if {[lindex $arg_pair 0] == {-silent}} {
                    set silent 1

                # Switch groups
                } elseif {[lindex $arg_pair 0] == {-group}} {
                    foreach switch_group $gconfig::switch_groups {
                        if {[string match [lindex $arg_pair 1] [lindex $switch_group 1]]} {
                            lappend switch_patterns [lindex $switch_group 0]
                        }
                    }

                # Switch patterns
                } else {
                    lappend switch_patterns [lindex $arg_pair 1]
                }
            }

            # Check switch patterns
            foreach switch_pattern $switch_patterns {
            
                # Check if switch already disabled
                set is_matched 0
                foreach switch $gconfig::defined_switches {
                    if {[string match $switch_pattern $switch]} {
                        if {![is_switch_enabled $switch]} {
                            if {!$silent} {print_message {INFO} "Switch \033\[97m$switch\033\[0m already disabled."}
                        }
                        set is_matched 1
                    }
                }
                
                # Remove switch from active list
                set updated_switches {}
                foreach switch $gconfig::active_switches {
                
                    # Disable matched switch
                    if {[string match $switch_pattern $switch]} {
                        if {!$silent} {print_message {INFO} "Switch \033\[97m$switch\033\[0m disabled."}
                        lappend results $switch
                        
                    # Leave not matched switch as is
                    } else {
                        lappend updated_switches $switch
                    }
                }
                set gconfig::active_switches $updated_switches
                
                # Not matched switch warning
                if {!$is_matched && !$silent} {
                    if {[regexp {[\*\?]} $switch_pattern]} {
                        print_message {WARNING} "No switches matching pattern \033\[91m$switch_pattern\033\[0m defined. Use gconfig::\033\[97mdefine_switches\033\[0m command to define."
                    } else {
                        print_message {WARNING} "Switch \033\[91m$switch_pattern\033\[0m is not defined. Use gconfig::\033\[97mdefine_switches\033\[0m command to define."
                    }
                }
            }
        }

        return $results
    }

    # Check if switches enabled correctly
    proc check_switches {} {

        # Group switches
        set groups {}
        set result 1
        foreach switch_group $gconfig::switch_groups {
            set group_name [lindex $switch_group 1]

            # Check each group once
            if {[lsearch -exact $groups $group_name] == -1} {
                lappend groups $group_name

                # Process each group record
                set is_single 0
                set is_required 0
                set active_switches {}
                set all_switches {}
                foreach group_rec [filter_groups $gconfig::switch_groups 1 $group_name] {
                    set current_switch [lindex $group_rec 0]

                    # Required switch group
                    if {[lindex $group_rec 2] == {required}} {
                        set is_required 1
                    }

                    # Single switch group
                    if {[lindex $group_rec 3] == {single}} {
                        set is_single 1
                    }

                    # Remember switch if active
                    if {[is_switch_enabled $current_switch]} {
                        lappend active_switches $current_switch
                    }

                    lappend all_switches $current_switch
                }

                # Only one switch should be enabled in the group
                if {$is_single && ([llength $active_switches] > 1)} {
                    print_message {ERROR} "Only one of \033\[97m$all_switches\033\[0m switches can be enabled in the group \033\[91m$group_name\033\[0m at the same time."
                    set result 0
                }

                # At least one switch should be enabled in required group
                if {$is_required && ([llength $active_switches] < 1)} {
                    print_message {ERROR} "At least one of \033\[97m$all_switches\033\[0m switches should be enabled in the group \033\[91m$group_name\033\[0m."
                    set result 0
                }
            }
        }

        return $result
    }

    # Reset switches to their defaults
    proc reset_switches {} {

        # Activate default switches
        set gconfig::defined_switches {}
        set gconfig::active_switches {}
        set gconfig::switch_groups {}

        # Define default switch
        define_switches default
        enable_switches -silent default

        return $gconfig::defined_switches
    }

    # Print switch information
    proc show_switches {} {
        print_subtitle "All defined and \033\[7menabled\033\[0m switches"
        check_switches

        # Group switches
        set groups {}
        set printed {}
        foreach switch_group $gconfig::switch_groups {
            set group_name [lindex $switch_group 1]

            # Check each group once
            if {[lsearch -exact $groups $group_name] == -1} {
                lappend groups $group_name

                # Group info message
                if {$group_name == {default}} {
                    set message "\033\[97mUngrouped switches:\033\[0m\n "
                } else {
                    set message "\033\[97m$group_name:\033\[0m\n "
                }
                set line " "

                # Process each group
                foreach group_rec [filter_groups $gconfig::switch_groups 1 $group_name] {
                    set switch [lindex $group_rec 0]

                    # New line when long
                    if {[string length $line] > 100} {
                        append message "\n "
                        set line " "
                    }

                    # Highlight active switch
                    if {[is_switch_enabled $switch]} {
                        append message " \033\[7m$switch\033\[0m"
                    } else {
                        append message " $switch"
                    }
                    lappend printed $switch
                    append line " $switch"

                }

                # Print info
                puts "$message\n"
            }
        }

        # Unknown and default switches
        set message ""
        set line " "
        foreach switch $gconfig::active_switches {
            if {[lsearch -exact $printed $switch] == -1} {
                lappend printed $switch

                # New line when long
                if {[string length $line] > 100} {
                    append message "\n "
                    set line " "
                }

                # Highlight other switch
                append message " \033\[97m$switch\033\[0m"
                append line " $switch"
            }
        }
        if {$message != {}} {
            puts "Other enabled switches:\n $message\n"
        }
    }

    # ----------------
    # Manage variables
    # ----------------

    # Internal variables
    variable defined_variables {}
    variable undefined_variables {}
    variable variable_groups {}

    # Check variable name
    proc is_variable_defined {name} {
        if {[lsearch -exact $gconfig::defined_variables $name] != -1} {
            return 1
        } else {
            return 0
        }
    }

    # Check variable name
    proc check_variable_name {name} {
        if {[regexp {^[a-zA-Z][0-9a-zA-Z_]*$} $name]} {
            return $name
        } else {
            print_message {ERROR} "Variable name \033\[91m$name\033\[0m should contain only alphanumeric characters."
            return {}
        }
    }

    # Check if variable defined
    proc check_variable {variable} {

        # Not defined
        if {[lsearch -exact [concat $gconfig::defined_variables $gconfig::undefined_variables] $variable] == -1} {
            print_message {WARNING} "Variable \033\[91m$variable\033\[0m is not defined. Use gconfig::\033\[97mdefine_variables\033\[0m command to define."
            lappend gconfig::undefined_variables $variable
        }

        return $variable
    }

    # Reset variables to their defaults
    proc reset_variables {} {

        # Define default variables
        set gconfig::defined_variables {}
        set gconfig::undefined_variables {}
        set gconfig::variable_groups {}

        return $gconfig::defined_variables
    }

    # Define user variables
    proc define_variables {args} {
        set results {}

        # Command line arguments
        set group {}

        # Parse arguments
        foreach arg_pair [eval "parse_arguments {} -variables {-group -group_name} {-variable -variables} $args"] {
            set arg [lindex $arg_pair 0]
            if {[lsearch -exact {-group -group_name} $arg] != -1} {
                set group [lindex $arg_pair 1]

            # Process each variable in the group
            } else {
                foreach variable [lindex $arg_pair 1] {

                    # Trim first '$' symbol
                    set variable [regsub {^\$} $variable {}]

                    # New variable
                    if {[lsearch -exact $gconfig::defined_variables $variable] == -1} {
                        if {[check_variable_name $variable] != {}} {
                            lappend results $variable
                            lappend gconfig::defined_variables $variable
                            lappend gconfig::variable_groups [list $variable $group]

                            # Update undefined variables
                            set undefined_variables {}
                            foreach undefined_variable $gconfig::undefined_variables {
                                if {$undefined_variable != $variable} {
                                    lappend undefined_variables $undefined_variable
                                }
                            }
                            set gconfig::undefined_variables $undefined_variables
                        }

                    # Variable defined several times
                    } else {
                        print_message {WARNING} "Variable \033\[91m$variable\033\[0m already defined."
                    }
                }
            }
        }

        return $results
    }

    # Get all variables in the expression
    proc get_variables {expression} {
        set variables {}

        # Drop escaped variables
        set expression [regsub -all {\\\$} $expression {}]

        # Replace expressions in condition
        foreach variable [concat \
            [regexp -all -inline {\$[0-9a-zA-Z_]+\M} $expression] \
            [regexp -all -inline {\$\{[0-9a-zA-Z_]+\}} $expression] \
        ] {
            set variable [regsub -all {[\$\{\}]} $variable {}]
            if {[lsearch -exact $variables $variable] == -1} {
                lappend variables $variable
            }
        }

        return $variables
    }

    # Get all variables in the expression
    proc replace_variable {expression variable value} {

        # Skip escaped variables
        set expression [regsub -all {\\\$} $expression {$!}]

        # Substitute variables in expression
        set expression [regsub -all "\\\$$variable\\M" $expression $value]
        set expression [regsub -all "\\\$\\{$variable\\}" $expression $value]

        # Revert escaped variables
        set expression [regsub -all {\$\!} $expression {\\$}]

        return $expression
    }

    # Colorize variables
    proc colorize_variables {expression {variables {}} {variable_color {}} {default_color {}}} {

        # Default values
        if {$variables == {}} {set variables {{[0-9a-zA-Z_]+}}}
        if {$variable_color == {}} {set variable_color "\033\[0;91m"}
        if {$default_color == {}} {set default_color "\033\[0;1m"}

        foreach variable $variables {

            # Skip escaped variables
            set expression [regsub -all {\\\$} $expression {$!}]

            set expression [regsub -all "\\\$$variable\\M" $expression "$variable_color\\0$default_color"]
            set expression [regsub -all "\\\$\\{$variable\\}" $expression "$variable_color\\0$default_color"]

            # Revert escaped variables
            set expression [regsub -all {\$\!} $expression {\\$}]
        }

        return "$default_color$expression\033\[0m"
    }

    # Merge masks
    proc merge_types {types} {
        set result {}

        # Keep last no-empty type
        foreach type $types {
            if {$type != {}} {
                set result $type
            }
        }
        return $result
    }

    # Print variable information
    proc show_variables {} {
        print_subtitle "All defined variables"

        # Group variables
        set groups {}
        set printed {}
        foreach variable_group $gconfig::variable_groups {
            set group_name [lindex $variable_group 1]

            # Check each group once
            if {[lsearch -exact $groups $group_name] == -1} {
                lappend groups $group_name

                # Group info message
                if {$group_name == {}} {
                    puts "\033\[97mUncategorized variables\033\[0m:"
                } else {
                    puts "\033\[97m$group_name\033\[0m:"
                }

                # Process each group
                foreach group_rec [filter_groups $gconfig::variable_groups 1 $group_name] {
                    set variable [lindex $group_rec 0]

                    # Print variable
                    puts "  $variable"
                    lappend printed $variable
                }

                # Print info
                puts {}
            }
        }

        # Undefined variables
        set message ""
        foreach variable $gconfig::undefined_variables {
            if {[lsearch -exact $printed $variable] == -1} {
                lappend printed $variable
                append message "  \033\[91m$variable\033\[0m\n"
            }
        }
        if {$message != {}} {
            puts "\033\[97mUndefined variables\033\[0m:\n$message"
        }
    }

    # -------------------
    # Condition functions
    # -------------------

    # Create condition from the expression
    proc create_condition {expression {boolean {}}} {

        # Empty mask
        if {$expression == {}} {
            return {}

        } else {
            if {$boolean == {}} {
                set boolean [regsub -all {\$\@} [regsub -all {\m[0-9a-zA-Z_]+\M} $expression {@\0}] {$}]
            }
            return [list $expression $boolean]
        }
    }

    # Append condition to the current one
    proc merge_conditions {conditions operator {separator {}}} {
        set result {}

        # Default separator is the same as an operator
        if {$separator == {}} {set separator " $operator "}

        # Escape special characters in separator
        set separator [regsub -all {\|} $separator {\|}]
        set separator [regsub -all {\&} $separator {\&}]

        # Extract unique conditions
        set unique_conditions {}
        foreach condition $conditions {
           if {($condition != {}) && ([lsearch -exact $unique_conditions $condition] == -1)} {
                lappend unique_conditions $condition
            }
        }

        # Merge all unique conditions
        set unmerged_condition_names {}
        set unmerged_condition_exprs {}
        foreach condition $unique_conditions {
            # Add only unique text
            foreach condition_name [split [regsub -all $separator [lindex $condition 0] "@@"] "@@"] {
                if {($condition_name != {}) && ([lsearch -exact $unmerged_condition_names $condition_name] == -1)} {
                    lappend unmerged_condition_names $condition_name
                }
            }

            # Add expression
            lappend unmerged_condition_exprs "\([lindex $condition 1]\)"
        }

        # Merge result
        if {[llength $unique_conditions] > 1} {
            set result [list [join $unmerged_condition_names $separator] [join $unmerged_condition_exprs $operator]]
        } elseif {[llength $unique_conditions] == 1} {
            set result [list [lindex $unique_conditions 0 0] [lindex $unique_conditions 0 1]]
        } else {
            set result {}
        }

       return $result
    }

    # --------------
    # Mask functions
    # --------------

    # Create mask
    proc create_mask {mask_pattern {evaluated_mask {}} {combination {}}} {

        # Fix mask triple
        if {$evaluated_mask == {}} {set evaluated_mask $mask_pattern}
        if {$combination == {}} {set combination $evaluated_mask}

        if {($mask_pattern == {}) && ($evaluated_mask == {}) && ($combination == {})} {
            return {}
        } else {
            return [list $mask_pattern $evaluated_mask $combination]
        }
    }

    # Group masks patterns
    proc group_mask_patterns {pattern1 pattern2} {

        # Get unique pattern list for each mask index
        set index 0
        set result {}
        while {($index < [llength $pattern1]) || ($index < [llength $pattern2])} {
            set merged [lindex $pattern1 $index]
            foreach value [lindex $pattern2 $index] {
                if {[lsearch -exact $merged $value] == -1} {
                    lappend merged $value
                }
            }
            lappend result $merged
            incr index
        }

        return $result
    }

    # Ungroup mask pattern
    proc ungroup_mask_pattern {pattern} {
        set results {}

        # Process each pattern index
        foreach variants $pattern {
            if {[llength $results] == 0} {
                foreach variant $variants {
                    lappend results [list $variant]
                }
            } else {
                set new_results {}
                foreach variant $variants {
                    foreach result $results {
                        lappend new_results [concat $result [list $variant]]
                    }
                }
                set results $new_results
            }
        }
        return $results
    }

    # Merge mask patterns
    proc merge_mask_patterns {pattern1 pattern2} {

        # Get unique pattern list for each mask index
        set index 0
        set result {}
        while {($index < [llength $pattern1]) || ($index < [llength $pattern2])} {
            set pattern {}

            # Result mask value is empty
            if {([lindex $pattern1 $index] == {*}) || ([lindex $pattern1 $index] == {})} {
                set pattern [lindex $pattern2 $index]

            # Pattern value is empty
            } elseif {([lindex $pattern2 $index] == {*}) || ([lindex $pattern2 $index] == {})} {
                set pattern [lindex $pattern1 $index]

            # Merge patterns
            } else {
                foreach variant [concat [lindex $pattern1 $index] [lindex $pattern2 $index]] {
                    if {([lsearch -exact [lindex $pattern1 $index] $variant] != -1) && ([lsearch -exact [lindex $pattern2 $index] $variant] != -1)} {
                        if {[lsearch $pattern $variant] == -1} {
                            lappend pattern $variant
                        }
                    }
                }
            }

            # Add pattern
            if {$pattern == {}} {
                lappend result {*}
            } else {
                lappend result $pattern
            }

            incr index
        }

        return $result
    }

    # Check if masks match and returns merged mask
    proc compare_mask_patterns {pattern1 pattern2} {

        # Replace wildcards
        set index 0
        set result_pattern1 {}
        set result_pattern2 {}
        while {($index < [llength $pattern1]) || ($index < [llength $pattern2])} {
            set value1 [lindex $pattern1 $index]
            set value2 [lindex $pattern2 $index]

            if {$value1 == {}} {set value1 {*}}
            if {$value2 == {}} {set value2 {*}}

            # Wildcard in the first pattern
            if {[regexp {\*} $value1] || ([lsearch -exact $value1 $value2] != -1)} {
                lappend result_pattern1 $value2
                lappend result_pattern2 $value2

            # Wildcard in the second pattern
            } elseif {[regexp {\*} $value2] || ([lsearch -exact $value2 $value1] != -1)} {
                lappend result_pattern1 $value1
                lappend result_pattern2 $value1

            # Patterns value
            } else {
                lappend result_pattern1 $value1
                lappend result_pattern2 $value2
            }
            incr index
        }

        # Matched masks
        if {$result_pattern1 == $result_pattern2} {
            return $result_pattern1

        # Do not match
        } else {
            return {}
        }

    }

    # Process masks with function
    proc process_masks {masks function} {
        set result {}

        # Process every mask
        foreach mask $masks {

            # Process every mask pattern
            set index 0
            set patterns {}
            while {($index < [llength $result]) || ($index < [llength $mask])} {
                lappend patterns [$function [lindex $result $index] [lindex $mask $index]]
                incr index
            }

            # Get unique pattern list for each mask index
            set result $patterns
        }

        return $result
    }

    # Group masks
    proc group_masks {masks} {
        return [process_masks $masks group_mask_patterns]
    }

    # Merge masks
    proc merge_masks {masks} {
        set result {}
        foreach pattern [process_masks $masks merge_mask_patterns] {

            # Keep first pattern mask untouched
            if {$result == {}} {
                set result [list [lindex $masks 0 0]]

            # Merge the rest values
            } else {
                lappend result $pattern
            }
        }
        return $result
    }

    # Check if masks match and returns merged mask
    proc compare_masks {masks} {
        return [process_masks $masks compare_mask_patterns]
    }

    # Check if mask is to be redefined
    proc is_mask_redefined {from_mask to_mask} {
        set from_pattern {}
        set to_pattern {}

        # Preprocess from mask
        foreach value [lindex $from_mask 0] {
            if {($value == {}) || ($value == {*})} {
                lappend from_pattern {*}
            } else {
                lappend from_pattern $value
            }
        }

        # Preprocess to mask
        foreach value [lindex $to_mask 0] {
            if {($value == {}) || ($value == {*})} {
                lappend to_pattern {*}
            } else {
                lappend to_pattern $value
            }
        }

        # Same patterns consider to be redefined
        if {$from_pattern == $to_pattern} {
            set result 1

        # Different patterns considered as redefined if to redefined from default
        } else {
            set result 0

            # Check each value in the pattern
            set index 0
            foreach from_value $from_pattern {
                set to_value [lindex $to_pattern $index]
                if {($from_value != {*}) && ($from_value != $to_value)} {set result 1}
                incr index
            }
        }

        return $result
    }

    # Auto name combination
    proc auto_name_combination {mask patterns {condition {}}} {

        # Form values
        set values {}
        foreach value [lindex $mask 1] {
            if {([llength $value] == 0) || ([lindex $value 0] == {*})} {
                lappend values {}
            } else {
                lappend values [lindex $value 0]
            }
            unset value
        }

        # Patterns that matches the condition
        set approved_pattern {}
        set approved_score 500

        # Check if patterns match the condition
        foreach pattern $patterns {
            set indexes [regsub -all {\@} [regexp -inline -all {\@[0-9]+} $pattern] {}]

            # Calculate pattern score
            set score 1000
            set index 0
            foreach value $values {

                # Value is not empty
                if {$value != {}} {

                    # Pattern does not contain value
                    if {[lsearch -exact $indexes $index] == -1} {
                        set score [expr $score-1000]

                    # Pattern contains value
                    } else {
                        set score [expr $score+1]
                    }

                # Pattern contains value but value is empty
                } elseif {[lsearch -exact $indexes $index] != -1} {
                    set score [expr $score-1]
                }

                incr index
            }

            # Add pattern with higher score
            if {$score > $approved_score} {
                set approved_pattern $pattern
                set approved_score $score
            }
        }

        # Empty combination
        if {[eval concat $values] == {}} {
            set result {default}

        # No patterns approved
        } elseif {$approved_pattern == {}} {
            set result [join [eval concat $values] "_"]

        # one of the patterns approved
        } else {

            # Replace pattern with combination values
            set result [subst [regsub -all {\@([0-9]+)} $approved_pattern {[lindex $values \1]}]]
        }

        return $result
    }

    # -----------------
    # Record functions
    # -----------------

    # Parse content
    proc create_record {condition mask type variable value} {
        return [list $condition $mask $type $variable $value]
    }

    # Reset all records
    proc reset_records {} {
        set gconfig::records {}
        set gconfig::filtered_records_args {}
    }

    # Get condition from the record
    proc get_record_condition {record {index {}}} {
        if {$index == {}} {
            return [lindex $record 0]
        } else {
            return [lindex $record 0 $index]
        }
    }

    # Get mask from the record
    proc get_record_mask {record {index {}}} {
        if {$index == {}} {
            return [lindex $record 1]
        } else {
            return [lindex $record 1 $index]
        }
    }

    # Get effective mask from the record
    proc get_record_mask_effective {record} {
        return [get_record_mask $record 1]
    }

    # Get combinations from the record
    proc get_record_combinations {record} {
        return [ungroup_mask_pattern [get_record_mask $record 2]]
    }

    # Get type from the record
    proc get_record_type {record} {
        return [lindex $record 2]
    }

    # Get variable from the record
    proc get_record_variable {record} {
        return [lindex $record 3]
    }

    # Get value from the record
    proc get_record_value {record} {
        return [lindex $record 4]
    }

    # Get indexed elements from records
    proc get_records_index {records index} {
    
        # Return records
        if {$index == {}} {
            return $records

        # Return values by index only
        } else {
            set results {}
            foreach record $records {
                set results [concat $results [lindex $record $index]]
            }
            return $results
        }
    }

    # ------------------
    # Records filtering
    # ------------------

    # Get variable dependencies { {variable {used variables}} ... }
    proc get_variable_dependencies {records} {

        # Fill variable definitions
        set variable_defs {}
        foreach record $records {
            lappend variable_defs [list \
                [get_record_variable $record] \
                [concat [get_variables [get_record_condition $record]] [get_variables [get_record_value $record]]] \
            ]
        }

        # Merge variable definitions
        set merged_defs {}
        set processed_variables {}
        foreach variable_def $variable_defs {
            set current_variable [lindex $variable_def 0]

            # Process each variable only once
            if {[lsearch -exact $processed_variables $current_variable] == -1} {
                lappend processed_variables $current_variable

                # Process every definition of current variable
                set dependent_variables {}
                foreach current_def $variable_defs {
                    if {[lindex $current_def 0] == $current_variable} {

                        # Add dependencies
                        foreach dependent_variable [lindex $current_def 1] {
                            if {$dependent_variable != $current_variable} {
                                if {[lsearch -exact $dependent_variables $dependent_variable] == -1} {
                                    lappend dependent_variables $dependent_variable
                                }
                            }
                        }
                    }
                }
                lappend merged_defs [list $current_variable $dependent_variables]
            }
        }
        return $merged_defs
    }

    # Put variables dependencies in evaluation order { {variable {used variables}} ... }
    proc order_variable_dependencies {dependencies} {
    
        # Order variable definitions
        set rest_defs {}
        set next_defs $dependencies
        set ordered_defs {}
        set ordered_variables {}

        # Proceed while changes take place
        while {$next_defs != $rest_defs} {
            set rest_defs $next_defs
            set next_defs {}

            # Process each variable
            foreach variable_def $rest_defs {
                set current_variable [lindex $variable_def 0]
                if {[lsearch -exact $ordered_variables $current_variable] == -1} {

                    # Chech if all dependent variables already ordered
                    set are_all_ordered 1
                    foreach dependent_variable [lindex $variable_def 1] {
                        if {[lsearch -exact $ordered_variables $dependent_variable] == -1} {
                            set are_all_ordered 0

                            # Break recursion loops
                            foreach recurse_def $rest_defs {
                                if {[lindex $recurse_def 0] == $dependent_variable} {
                                    if {[lsearch -exact [lindex $recurse_def 1] $current_variable] != -1} {
                                        set are_all_ordered 1
                                    }
                                }
                            }
                            if {!$are_all_ordered} {break}
                        }
                    }

                    # Order variable if no more dependency
                    if {$are_all_ordered} {
                        lappend ordered_variables $current_variable
                        lappend ordered_defs $variable_def
                    } else {
                        lappend next_defs $variable_def
                    }
                }
            }
        }
        return [concat $ordered_defs $next_defs]
    }

    # Evaluate condition
    proc substitute_condition {record switches variables} {

        # Check condition
        set condition [get_record_condition $record 1]

        # Replace variables with defined flag
        foreach variable [get_variables $condition] {
            set condition [replace_variable $condition $variable \
                [expr {[lsearch -exact $variables $variable] != -1}] \
            ]
        }

        # Replace switches with enabled flag
        foreach switch [regexp -inline -all {@[0-9a-zA-Z\_]+\M} $condition] {
            set condition [regsub -all "$switch\\M" $condition \
                [expr {[lsearch -exact $switches [regsub {^@} $switch {}]] != -1}] \
            ]
        }

        return $condition
    }

    # Filter records by index valus
    proc filter_records_by_index {records indexes operator match_value {result_index {}}} {
        set results {}
        foreach record $records {
            if {[expr "{[lindex $record $indexes]} $operator {$match_value}"]} {
                lappend results $record
            }
        }
        return [get_records_index $results $result_index]
    }

    # Filter records by mask
    proc filter_records_by_mask {records mask {result_index {}}} {

        # No filtering required
        if {$mask == {}} {
            set results $records
        
        # Filter records
        } else {
            set results {}
            foreach record $records {

                # Check mask match
                set matched_mask [compare_mask_patterns $mask [get_record_mask $record 2]]
                if {$matched_mask != {}} {
                    lappend results [create_record \
                        [get_record_condition $record] \
                        [create_mask [get_record_mask $record 0] [get_record_mask $record 1] $matched_mask] \
                        [get_record_type $record] \
                        [get_record_variable $record] \
                        [get_record_value $record] \
                    ]
                }
            }
        }
        return [get_records_index $results $result_index]
    }

    # Filter records by variable
    proc filter_records_by_variables {records variables {result_index {}}} {
        set results {}
    
        # No filtering required
        if {$variables == {}} {
            set results $records
        
        # Filter records
        } else {
            foreach record $records {
                if {[lsearch -exact $variables [get_record_variable $record]] != -1} {
                    lappend results $record
                }
            }
        }
        return [get_records_index $results $result_index]
    }

    # Filter records
    variable filtered_records_args {}
    variable filtered_records_cache {}
    proc filter_records {records switches mask variables is_follow} {

        # Check if value is cached
        set filter_args [list $records $switches $mask $variables $is_follow]
        if {$gconfig::filtered_records_args == $filter_args} {
            return $gconfig::filtered_records_cache
        }
        
        # Filter records by mask first
        set records [filter_records_by_mask $records $mask]

        # Filter records by variables
        if {$is_follow} {
            set ordered_dependencies [order_variable_dependencies [get_variable_dependencies $records]]
            
            # Order records
            set filtered_records {}
            if {$variables == {}} {
                # Order records by required variables
                foreach dependency $ordered_dependencies {
                    set filtered_records [concat $filtered_records [filter_records_by_variables $records [lindex $dependency 0]]]
                }
            
            # Follow dependencies while new variables to evaluate found
            } else {
                set follow_mode 1
                set current_dependencies $ordered_dependencies
                set current_variables $variables
                while {$follow_mode} {
                    set follow_mode 0
                     
                    # Follow matching dependencies once
                    set next_dependencies {}
                    foreach dependency $current_dependencies {
                        if {[lsearch -exact $current_variables [lindex $dependency 0]] != -1} {
                        
                            # Add variables once and need another pass
                            foreach variable [lindex $dependency 1] {
                                if {[lsearch -exact $current_variables $variable] == -1} {
                                    lappend current_variables $variable
                                    set follow_mode 1
                                }
                            }
                        
                        # Not matched dependency to proceed next
                        } else {
                            lappend next_dependencies $dependency
                        }
                    }
                    
                    # Process the rest dependencies
                    set current_dependencies $next_dependencies
                }

                # Order records by required variables
                foreach dependency $ordered_dependencies {
                    set variable [lindex $dependency 0]
                    if {[lsearch -exact $current_variables $variable] != -1} {
                        set filtered_records [concat $filtered_records [filter_records_by_variables $records $variable]]
                    }
                }
            }
            set records $filtered_records
            
        # Filter records by variables
        } else {
            set records [filter_records_by_variables $records $variables]
        }

        # Filter records by switches
        if {$switches != {}} {
            set filtered_records {}
            set filtered_variables {}
            foreach record $records {
                set is_record_active 1
                
                # Check conditions
                if {[catch {set is_record_active [expr [substitute_condition $record $switches $filtered_variables]]}]} {
                    print_message {ERROR} "Specified \033\[91m[get_record_condition $record 0]\033\[0m condition is incorrect. Should be a \033\[97mlogical expression\033\[0m with switch or variable names."
                    set is_record_active 0
                }
                if {$is_record_active} {
                    lappend filtered_records $record
                    lappend filtered_variables [get_record_variable $record]
                }
            }
            set records $filtered_records
        }
        
        set gconfig::filtered_records_args $filter_args
        set gconfig::filtered_records_cache $records
        return $records
    }

    # -------------------
    # Records operations
    # -------------------

    # Group records
    proc group_records {records {key_indexes 3}} {
        set result_groups {}

        # Process each record
        set processed_groups {}
        foreach reference_record $records {

            # Process each group only once
            set group [lindex $reference_record $key_indexes]
            set group_records {}
            if {[lsearch -exact $processed_groups $group] == -1} {
                lappend processed_groups $group

                # Process records with same group
                foreach current_record $records {
                    if {[lindex $current_record $key_indexes] == $group} {
                        lappend group_records $current_record
                    }
                }
                lappend result_groups [list $group $group_records]
            }
        }
        return $result_groups
    }

    # Check if records can be merged by variable
    proc check_records_mergable {records} {
        set variables {}
        set mask_patterns {}
        
        # Fast variable check
        set last_variable {}
        set last_mask_pattern {}
        foreach record $records {
            
            # Check variable names
            set variable [get_record_variable $record]
            if {$variable != $last_variable} {
                lappend variables $variable
                set last_variable $variable
            }

            # Check masks
            set mask_pattern [get_record_mask $record 2]
            if {[merge_mask_patterns $last_mask_pattern $mask_pattern] != $last_mask_pattern} {
                lappend mask_patterns $mask_pattern
                set last_mask_pattern $mask_pattern
            }
        }
        
        # Successful flag
        set is_ok 0
        
        # Several variables cannot be merged
        if {[llength $variables] > 1} {
            set unique_variables {}
            foreach variable $variables {
                set variable "\033\[97m$variable\033\[0m"
                if {[lsearch -exact $unique_variables $variable] == -1} {
                    lappend unique_variables $variable
                }
            }
            print_message {ERROR} "Please clarify \033\[91mvariable\033\[0m: [join $unique_variables {, }]."

        # Incompatible masks cannot be merged
        } elseif {[llength $mask_patterns] > 1} {
            set unique_mask_patterns {}
            foreach mask_pattern $mask_patterns {
                set mask_pattern "\{\033\[97m$mask_pattern\033\[0m\}"
                if {[lsearch -exact $unique_mask_patterns $mask_pattern] == -1} {
                    lappend unique_mask_patterns $mask_pattern
                }
            }
            print_message {ERROR} "Please clarify \033\[91m[lindex $variables 0]\033\[0m mask: [join $unique_mask_patterns ", "]."

        # All is ok
        } else {
            set is_ok 1
        }
        
        return $is_ok
    }

    # Merge records
    variable last_merge_error 0
    proc merge_records {records {action {-merge}}} {
        set result {}

        # Check action
        if {[lsearch -exact {-merge -redefine -last} $action] == -1} {
            print_message {WARNING} "Incorrect action \033\[91m$action\033\[0m. Use one of \033\[97m-merge\033\[0m, \033\[97m-redefine\033\[0m or \033\[97m-last\033\[0m arguments."
            set action {-merge}
        }
        
        # Check possibility to merge
        if {[check_records_mergable $records]} {
            set gconfig::last_merge_error 0

            # Process each record
            set all_conditions {}
            set all_masks {}
            set all_types {}
            set variable {}
            set all_values {}
            foreach record $records {
                set condition [get_record_condition $record]
                set mask [get_record_mask $record]
                set type [get_record_type $record]
                set variable [get_record_variable $record]
                set value [get_record_value $record]

                # Redefine mode
                if {($action != {-merge}) && ($type != {-merge})} {
                
                    # Redefined warning
                    if {$action != {-last}} {
                        set last_condition [lindex $all_conditions end 0]
                        set last_mask [lindex $all_masks end]
                        set last_value [lindex $all_values end]
                        
                        # Value have been changed
                        if {($last_value != $value) && ($last_value != {})} {
                        
                            # Mask have been redefined
                            if {[is_mask_redefined $last_mask $mask]} {
                                # print_message {WARNING} "Variable \033\[97m$variable\033\[0m[create_filter_message $last_condition $last_mask] redefined from \033\[97m$last_value\033\[0m to \033\[97m$value\033\[0m[create_filter_message $condition $mask]."
                                print_message {WARNING} "Variable \033\[97m$variable\033\[0m redefined from \033\[97m$last_value\033\[0m to \033\[97m$value\033\[0m[create_filter_message $condition $mask]."
                            }
                        }
                    }

                    # Redefine record
                    set all_conditions [list $condition]
                    set all_masks [list $mask]
                    set all_types [list $type]
                    set all_values [list $value]
                
                # Merge mode
                } else {
                    lappend all_conditions $condition
                    lappend all_masks $mask
                    lappend all_types $type
                    lappend all_values $value
                }
            }

            # # Merge the rest conditions
            # if { $variable != {}} {
                # set result [create_record \
                    # [merge_conditions $all_conditions {&} {, }] \
                    # [merge_masks $all_masks] \
                    # [merge_types $all_types] \
                    # $variable \
                    # [join $all_values "\n"] \
                # ]
            # }
            
            # Merge variable information
            if { $variable != {}} {
                set result [create_record \
                    [merge_conditions $all_conditions {&} {, }] \
                    [merge_masks $all_masks] \
                    [merge_types $all_types] \
                    $variable \
                    [join $all_values "\n"] \
                ]
            }
        
        # Cannot merge flag
        } else {
            # set result [create_record {} {} {} [get_record_variable [lindex $records 0]] {}]
            set gconfig::last_merge_error 1
        }

        return $result
    }

    # Populate variable variants
    proc combine_variable_records {variable_records {groups {}}} {
        set current_record {}
        set rest_records {}
        set results {}

        # First variable to be processed
        foreach variable_record $variable_records {
            if {$current_record == {}} {
                set current_record $variable_record

            # Rest variables to the queue
            } else {
                lappend rest_records $variable_record
            }
        }

        # Process each value
        foreach value [get_record_value $current_record] {
            set new_record [create_record \
                [get_record_condition $current_record] \
                [get_record_mask $current_record] \
                [get_record_type $current_record] \
                [get_record_variable $current_record] \
                $value \
            ]

            # Last variable
            if {$rest_records == {}} {
                lappend results [concat $groups [list $new_record]]

            # More variables require processing
            } else {
                set results [concat $results [combine_variable_records $rest_records [concat $groups [list $new_record]]]]
            }
        }

        return $results
    }

    # Join two lists
    proc join_lists {list1 list2 {delimiter {}}} {
        set result {}
        foreach value1 $list1 {
            foreach value2 $list2 {
                lappend result "$value1$delimiter$value2"
            }
        }
        return $result
    }

    # -------------------
    # Records evaluation
    # -------------------

    # Evaluate variable records
    proc evaluate_record_variables {record variable_records} {
        set results {}

        # Is record file combination
        set is_files_record [expr {[get_record_type $record] == {-files}}]

        # Get variables used in current value
        set used_variables [get_variables [get_record_value $record]]

        # Look for variable values
        set used_variable_records {}
        foreach variable_name $used_variables {

            # Get used variable record
            if {$is_files_record} {
                set used_variable_record [merge_records \
                    [filter_records_by_index $variable_records 3 == $variable_name] \
                    -merge \
                ]
                
                # Filter identical variants
                set filtered_values {}
                set used_values [get_record_value $used_variable_record]
                foreach value $used_values {
                    if {[lsearch -exact $filtered_values $value] == -1} {
                        lappend filtered_values $value
                    }
                }
                if {$filtered_values != $used_values} {
                    set used_variable_record [create_record \
                        [get_record_condition $used_variable_record] \
                        [get_record_mask $used_variable_record] \
                        [get_record_type $used_variable_record] \
                        [get_record_variable $used_variable_record] \
                        $filtered_values \
                    ]
                }

            # Regular variables
            } else {
                set used_variable_record [merge_records \
                    [filter_records_by_index $variable_records 3 == $variable_name] \
                    -redefine \
                ]
            }

            # Variable should be defined
            if {$used_variable_record == {}} {
                set expression [get_record_value $record]
                if {[regexp {\s} $expression]} {
                    set expression "{$expression}"
                }
                # print_message {ERROR} "Undefined variable \033\[91m$variable_name\033\[0m in \033\[97m[get_record_variable $record]\033\[0m[create_filter_message [get_record_condition $record] [get_record_mask $record]] expression [colorize_variables $expression {} "\033\[97m" "\033\[0m"]."
                print_message {ERROR} "Check switches of variable \033\[91m$variable_name\033\[0m in \033\[97m[get_record_variable $record]\033\[0m expression[create_filter_message [get_record_condition $record] [get_record_mask $record]] [colorize_variables $expression {} "\033\[97m" "\033\[0m"]."

            # All variables should be defined
            } else {
                lappend used_variable_records $used_variable_record
            }
        }

        # Combine variables for file search
        if {$is_files_record} {
            set used_variable_groups [combine_variable_records $used_variable_records]

            # File without substitutions
            if {$used_variable_groups == {}} {
                set used_variable_groups {{}}
            }

        # Create a group from used variables
        } else {
            set used_variable_groups [list $used_variable_records]
        }

        # Process all variables in the group
        foreach group $used_variable_groups {

            # Merged record values
            set current_condition [get_record_condition $record]
            set current_mask [get_record_mask $record]
            set current_value [get_record_value $record]

            # Substitute variable values
            foreach variable_record $group {

                # Update condition
                set current_condition [merge_conditions [list [get_record_condition $variable_record] $current_condition] {&} {, }]

                # Update mask
                set current_mask [merge_masks [list \
                    $current_mask \
                    [get_record_mask $variable_record] \
                ]]

                # Update value
                set current_value [replace_variable \
                    $current_value \
                    [get_record_variable $variable_record] \
                    [get_record_value $variable_record] \
                ]
            }

            # Flag if record is valid
            set is_value_valid 1

            # Check if file exists
            if {$is_files_record} {
                # set is_value_valid [file exists $current_value]
                # foreach search_path $gconfig::search_paths {
                #     if {!$is_value_valid} {
                #         set is_value_valid [file exists $search_path/$current_value]
                #         set current_value $search_path/$current_value
                #     }
                # }
                set files ""; catch {set files [glob $current_value]}
                if {[set is_value_valid [llength $files]]} {
                    set current_value $files
                }
                foreach search_path $gconfig::search_paths {
                    if {!$is_value_valid} {
                        catch {set files [glob $search_path/$current_value]}
                        if {[set is_value_valid [llength $files]]} {
                            set current_value $files
                        }
                    }
                }
            }

            # Add valid record
            if {$is_value_valid} {
                lappend results [create_record \
                    $current_condition \
                    $current_mask \
                    [get_record_type $record] \
                    [get_record_variable $record] \
                    $current_value \
                ]
            }
        }

        return $results
    }

    # Follow variables in the records to combine masks
    proc auto_name_records {records} {

        # No auto-name records
        set auto_records [filter_records_by_index $records 2 == {-auto_name}]
        if {$auto_records == {}} {
            return {}

        # Auto-name records exist
        } else {

            # Initialize variable dependency hash
            set dependency_hash {}
            foreach record $records {
                set ref_variable [get_record_variable $record]
                set values $ref_variable
                foreach variable [get_variables [get_record_value $record]] {
                    if {[lsearch -exact $values $variable] == -1} {
                        lappend values $variable
                    }
                }
                lappend dependency_hash [list [get_record_type $record] $ref_variable $values]
            }

            # Initialize variable dependency hash
            set updated_hash {}
            foreach ref_tripple $dependency_hash {
                set ref_type [lindex $ref_tripple 0]
                set ref_variable [lindex $ref_tripple 1]
                set ref_values [lindex $ref_tripple 2]
                set values {}

                # Auto-name variable
                if {[lindex $ref_tripple 0] == {-auto_name}} {

                    # Check other variables containing reference one
                    foreach other_tripple $dependency_hash {

                        # Reference auto-name variable linked with other
                        if {[lsearch -exact $ref_values [lindex $other_tripple 1]] != -1} {

                            # Add variables to the ref values
                            foreach variable [lindex $other_tripple 2] {
                                if {($variable != $ref_variable) && ([lsearch -exact $values $variable] == -1)} {
                                    lappend values $variable
                                }
                            }
                        }
                    }
                    lappend updated_hash [list $ref_type $ref_variable $values]

                # Normal variable - leave as is
                } else {
                    lappend updated_hash [list $ref_type $ref_variable $ref_values]
                }
            }
            set dependency_hash $updated_hash

            # Follow auto-name variables
            set changed 1
            while {$changed > 0} {
                set changed 0

                # Follow dependencies
                set updated_hash {}
                foreach ref_tripple $dependency_hash {
                    set ref_type [lindex $ref_tripple 0]
                    set ref_variable [lindex $ref_tripple 1]
                    set values [lindex $ref_tripple 2]

                    # Add variables to the ref values
                    foreach value $values {
                        foreach var_tripple $dependency_hash {
                            if {[lindex $var_tripple 1] == $value} {

                                # Add variables to the ref values
                                foreach variable [lindex $var_tripple 2] {
                                    if {($variable != $ref_variable) && ([lsearch -exact $values $variable] == -1)} {
                                        lappend values $variable
                                        incr changed
                                    }
                                }
                            }
                        }
                    }

                    lappend updated_hash [list $ref_type $ref_variable $values]
                }

                set dependency_hash $updated_hash
            }

            # Merge names of normal variables
            set results {}
            foreach group [group_records $auto_records 3] {
                set reference_record [merge_records [lindex $group 1] -merge]
                set reference_variable [get_record_variable $reference_record]

                # Unmerged conditions and mask
                set unmerged_conditions {}
                set unmerged_masks {}

                # Reference condition and mask areto be merged first
                lappend unmerged_conditions [get_record_condition $reference_record]
                lappend unmerged_masks [get_record_mask $reference_record]

                # Look for dependent variables
                set dependent_variables {}
                foreach variable_pair $dependency_hash {
                    if {[lindex $variable_pair 1] == $reference_variable} {
                        set dependent_variables [lindex $variable_pair 2]
                    }
                }

                # Add data to merge
                foreach dependent_record $records {
                    set dependent_variable [get_record_variable $dependent_record]
                    if {[lsearch -exact $dependent_variables $dependent_variable] != -1} {
                        lappend unmerged_conditions [get_record_condition $dependent_record]
                        lappend unmerged_masks [get_record_mask $dependent_record]
                    }
                }

                # Append result record
                set merged_condition [merge_conditions $unmerged_conditions {&} {, }]
                set merged_mask [merge_masks $unmerged_masks]

                lappend results [create_record \
                    $merged_condition \
                    $merged_mask \
                    {-auto_name} \
                    [get_record_variable $reference_record] \
                    [auto_name_combination $merged_mask {@0 @5 @4_@3 @1@2@3@4 @0_@1@2@3@4 @1@2@3@4_@5 @0_@1@2@3@4_@5 @1@2@3@4@5 @0_@1@2@3@4@5 @1@2@3@4@5_@6 @0_@1@2@3@4@5_@6} $merged_condition] \
                ]
            }
        }

        return $results
    }

    # Evaluate variable records
    proc evaluate_records {records} {
        set result_records {}

        # Add evaluated auto name records into result list
        set done_records [auto_name_records $records]


        # Process active records
        foreach record $records {


            # Drop auto-name records
            if {[get_record_type $record] != {-auto_name}} {
                set evaluated_records [evaluate_record_variables $record $done_records]

                # File records
                if {[get_record_type $record] == {-files}} {

                    # Create colored file pattern
                    set file_pattern [get_record_value $record]
                    if {[llength $evaluated_records] != 1} {
                        if {[string length $file_pattern] > 100} {
                            set new_line "\n  "
                        } else {
                            set new_line { }
                        }
                        set file_pattern [colorize_variables $file_pattern {} "\033\[97m" "\033\[0m"]
                    }

                    # No files found
                    set dependent_variables [get_variables [get_record_value $record]]
                    if {[llength $evaluated_records] == 0} {
                        set message_type {ERROR}

                        # No variables
                        if {$dependent_variables == {}} {
                            set message "\033\[91mNo file\033\[0m name \033\[97m[get_record_variable $record]\033\[0m[create_filter_message [get_record_condition $record] [get_record_mask $record]] found$new_line\033\[97m[get_record_value $record]\033\[0m"

                        # Parameterized file name
                        } else {
                            set message "\033\[91mNo files\033\[0m match \033\[97m[get_record_variable $record]\033\[0m[create_filter_message [get_record_condition $record] [get_record_mask $record]] pattern$new_line$file_pattern\n"
                        }

                    # Several files found
                    } elseif {[llength $evaluated_records] > 1} {
                        set message_type {WARNING}
                        
                        set message "\033\[91mSeveral files\033\[0m match \033\[97m[get_record_variable $record]\033\[0m pattern[create_filter_message [get_record_condition $record] [get_record_mask $record]]:\n    $file_pattern\n\n  First found file used:\n"
                        set is_first 1
                        foreach evaluated_record $evaluated_records {
                            if {$is_first} {
                                append message "    \033\[97m[get_record_value $evaluated_record]\033\[0m\n"
                            } else {
                                append message "    [get_record_value $evaluated_record]\n"
                            }
                            set is_first 0
                        }
                    }

                    # Print map variables info
                    if {[llength $evaluated_records] != 1} {
                        if {!$gconfig::last_merge_error && ($dependent_variables != {})} {
                            append message "\n  Following variable variants have been checked:\n"
                            foreach variable $dependent_variables {
                                append message "    \033\[97m$variable\033\[0m <= {[filter_records_by_index $done_records 3 == $variable 4]}\n"
                            }
                        }
                        print_message $message_type $message
                    }

                    # Merge with first value
                    if {[llength $evaluated_records] > 0} {
                        set evaluated_record [merge_records [concat \
                            [filter_records_by_index $done_records 3 == [get_record_variable $record]] \
                            [list [lindex $evaluated_records 0]] \
                        ] -merge]
                        set done_records [concat \
                            [filter_records_by_index $done_records 3 != [get_record_variable $record]] \
                            [list $evaluated_record] \
                        ]
                    }

                # Append first value
                } else {
                    if {[llength $evaluated_records] > 0} {
                        lappend done_records [lindex $evaluated_records 0]
                    }
                }
            }
        }

        return $done_records
    }

    # Print records
    proc show_records {records {title {}}} {
        check_switches

        # Print title
        if {$title != {}} {
            print_title $title
        }

        # Message to print
        set messages {}

        # Check every record
        set last_record {}
        foreach record $records {
            if {$record != {}} {

                # Can merge lines?
                set can_merge 1
                set can_merge [expr {$can_merge && ([get_record_condition $record 0] == [get_record_condition $last_record 0])}]
                set can_merge [expr {$can_merge && ([get_record_mask $record] == [get_record_mask $last_record])}]
                set can_merge [expr {$can_merge && ([get_record_type $record] == [get_record_type $last_record])}]
                set can_merge [expr {$can_merge && ![regexp "\n" [get_record_value $record]]}]

                # First part
                set first_part_text {}
                set first_part_data {}
                
                # Condition
                set condition [colorize_condition [get_record_condition $record 0]]
                if {$condition != {}} {
                    lappend first_part_text $condition
                    lappend first_part_data [get_record_condition $record 0]
                }
                
                # Mask
                if {[get_record_mask $record] != {}} {

                    # Combination
                    lappend first_part_text "{\033\[97m[get_record_mask $record 2]\033\[0m}"
                    lappend first_part_data "{[get_record_mask $record 2]}"

                    # Original mask
                    if {[get_record_mask $record 0] != [get_record_mask $record 2]} {
                        lappend first_part_text "/ {[get_record_mask $record 0]}"
                        lappend first_part_data "/ {[get_record_mask $record 0]}"
                    }

                    # Merged mask
                    if {[get_record_mask $record 1] != [get_record_mask $record 0]} {
                        lappend first_part_text "=> {[get_record_mask $record 1]}"
                        lappend first_part_data "=> {[get_record_mask $record 1]}"
                    }

                }

                # Variable type
                if {[get_record_type $record] != {}} {
                    lappend first_part_text [get_record_type $record]
                    lappend first_part_data [get_record_type $record]
                }

                # Join text from the list
                set first_part_text [join $first_part_text { }]
                set first_part_data [join $first_part_data { }]

                # Value
                set record_value [get_record_value $record]
                set record_value [regsub "^\\s*\\n" $record_value {}]
                set record_value [regsub "\\n\\s*\$" $record_value {}]

                # Multi-line value - new line
                if {[regexp "\n" $record_value]} {
                    set record_value [regsub -all -line {^\s*} $record_value {    }]

                    append first_part_text "\n  \033\[32m[get_record_variable $record] = \{\033\[0m"
                    set first_part_data "  [get_record_variable $record] = \{"

                    set second_part_text "$record_value\n  \033\[32m\}\033\[0m"
                    set second_part_data "$record_value\n  \}"

                # Single line list
                } elseif {[regexp {\s+} $record_value] || ($record_value == {})} {
                    set second_part_text "\033\[32m[get_record_variable $record] = {\033\[0m$record_value\033\[32m}\033\[0m"
                    set second_part_data "[get_record_variable $record] = \{$record_value\}"

                # Single line variable
                } else {
                    set second_part_text "\033\[32m[get_record_variable $record] = \033\[0m$record_value"
                    set second_part_data "[get_record_variable $record] = $record_value"
                }

                # Add record
                lappend messages [list \
                    $can_merge \
                    [list [string length $first_part_data] $first_part_text] \
                    [list [string length $second_part_data] $second_part_text] \
                ]

                set last_record $record
            }
        }

        # Dump last value
        lappend messages {}

        # Process messages
        set current_message {}
        set merged_messages {}
        set last_message {}
        foreach message $messages {

            # Can merge
            if {[lindex $message 0] == 1} {
                if {$current_message == {}} {
                    set current_message $message
                } else {

                    # Long / short values separators
                    if {([lindex $last_message 2 0] > 70) || ([lindex $message 2 0] > 70)} {
                        set separator "\n"
                    } else {
                        set separator { }
                    }

                    # Merge messages
                    set current_message [list \
                       0 \
                       [lindex $current_message 1] \
                       [list [expr {[lindex $current_message 2 0] + [lindex $message 2 0]}] "[lindex $current_message 2 1]$separator[lindex $message 2 1]"] \
                    ]
                }

            # Cannot merge
            } else {

                # Dump value
                if {$current_message != {}} {
                    if {([lindex $current_message 1 0] + [lindex $current_message 2 0]) > 150} {
                        puts "[lindex $current_message 1 1]"
                        if {[regexp "\n" [lindex $current_message 2 1]]} {
                            puts "[lindex $current_message 2 1]\n"
                        } else {
                            puts "  [lindex $current_message 2 1]\n"
                        }
                    } elseif {[lindex $current_message 1 0] > 0} {
                        puts "[lindex $current_message 1 1] [lindex $current_message 2 1]"
                    } else {
                        puts [lindex $current_message 2 1]
                    }
                }
                set current_message $message
            }
            set last_message $message
        }

        puts {}
    }

    # ----------------
    # Content functions
    # ----------------

    # Internal variables
    variable records {}
    variable last_records {}

    # Parse content
    proc parse_content {content {mask {}} {condition {}} {type {}} {variable {}}} {

        # Results
        set results {}
        
        # Current content variables
        set is_condition 0
        set is_mask 0

        # Set current variables to defaults
        set current_condition $condition
        set current_mask $mask
        set current_type $type
        set current_variable $variable

        # The content is variable value
        if {($current_variable != {}) && ![regexp {\s(-when|-if|-mask|-views|-files|-auto_name|-subst|-merge)\s} " $content "]} {

            # Do not add empty condition
            if {$current_condition == {} } {
                set current_condition {default 1}
            }

            # Files type is list
            if {$current_type == {-files}} {
                set values $content
            } else {
                set values [list $content]
            }

            # Add new records
            set current_mask [create_mask $current_mask]
            foreach value $values {
                # if {![regexp {^\s*$} $value]} {
                    lappend results [create_record \
                        $current_condition \
                        $current_mask \
                        $current_type \
                        $current_variable \
                        $value \
                    ]
                # }
            }

        # Proceed hierarchical content
        } else {

            # Cut out inline comments
            set content [regsub -line -all {\s*(^|[^\\])#.+$} $content {}]

            # Process every content record
            if {[catch {foreach record $content {

                # Record is condition key word
                if {[lsearch -exact {-when -if} $record] != -1} {
                    set is_condition 1
                    set is_mask 0

                # Record is mask key word
                } elseif {[lsearch -exact {-mask -views} $record] != -1} {
                    set is_condition 0
                    set is_mask 1

                # Record is variable type
                } elseif {[lsearch -exact {-files -auto_name -subst -merge} $record] != -1} {
                    set current_type $record

                # Record is condition
                } elseif {$is_condition} {
                    set is_condition 0

                    # Check used switches and variables
                    foreach word [regexp -all -inline {[\$0-9a-zA-Z\_][0-9a-zA-Z\_]*\M} $record] {
                        if {[regexp {^\$} $word]} {
                            check_variable [regsub {^\$} $word {}]
                        } else {
                            check_switch $word
                        }
                    }

                    # Update condition
                    set current_condition [merge_conditions [list $condition [create_condition $record]] {&} { & }]

                # Record is mask
                } elseif {$is_mask} {
                    set is_mask 0

                    # set current_mask $record
                    set current_mask [merge_mask_patterns [merge_mask_patterns $record $mask] $record]

                # Variable definition
                # {($current_type != {-auto_name}) && ($current_variable == "") && ([llength $record] == 1)}
                } elseif {($current_variable == "") && ![regexp {\s} $record]} {
                    if {[regexp {^-} $record]} {
                        print_message {ERROR} "Incorrect option \033\[91m$record\033\[0m used[create_filter_message $current_condition $current_mask]"
                        break
                    } else {
                        set current_variable [regsub -all {[\$\{\}]} $record {}]
                        set current_variable [check_variable $current_variable]
                        set current_variable [check_variable_name $current_variable]
                    }

                # Variable content
                } else {

                    # Record is content to parse recursive
                    set results [concat $results [parse_content $record $current_mask $current_condition $current_type $current_variable]]

                    # Reset arguments to defaults
                    set current_condition $condition
                    set current_variable $variable
                    set current_type $type
                    set current_mask $mask
                }

            # Syntax error
            }}]} {
                print_message {ERROR} "Syntax error in content \033\[91m$record\033\[0m[create_filter_message $current_condition $current_mask]" 
            }
        }
        return $results
    }

    # Add variable values
    proc add_values {variable content {type {}}} {

        # Enable message queue mode
        queue_messages

        # Result records
        set result [parse_content $content {} {} $type $variable]

        # Add records if not empty
        if {$result != {}} {
            set gconfig::last_records $gconfig::records
            set gconfig::records [concat $gconfig::last_records $result]
            set gconfig::filtered_records_args {}
        }

        # Dump queued messages
        print_messages

        return $result
    }

    # Add variable values
    proc add {variable content {type {}}} {
        return [add_values $variable $content $type]
    }

    # Add files
    proc add_files {variable content} {
        return [add_values $variable $content -files]
    }

    # Add section
    proc add_section {args} {
        
        # Result records
        set result {}

        # Enable message queue mode
        queue_messages

        # Parse arguments
        set mask {}
        set condition {}
        set type {}
        set variable {}
        foreach arg_pair [eval "parse_arguments {} -content {-variable -mask -view -type -when} {-content} $args"] {
            set arg [lindex $arg_pair 0]
            if {[lsearch -exact {-mask -view} $arg] != -1} {
                set mask [lindex $arg_pair 1]
            } elseif {$arg == {-when}} {
                set condition [lindex $arg_pair 1]
            } elseif {$arg == {-type}} {
                set type [lindex $arg_pair 1]
            } elseif {$arg == {-variable}} {
                set variable [lindex $arg_pair 1]
            } else {
                set result [concat $result \
                    [parse_content [lindex $arg_pair 1] $mask $condition $type $variable] \
                ]
            }
        }

        # Add records if not empty
        if {$result != {}} {
            set gconfig::last_records $gconfig::records
            set gconfig::records [concat $gconfig::last_records $result]
            set gconfig::filtered_records_args {}
        }

        # Dump queued messages
        print_messages

        return $result
    }

    # Undo last section
    proc undo {} {
        set gconfig::records $gconfig::last_records
        set gconfig::filtered_records_args {}
    }

    # ----------------
    # Config functions
    # ----------------

    # Reset defaults
    proc reset {} {
        reset_switches
        reset_variables
        reset_records
        return 1
    }

    # Reset defaults
    proc delete {args} {
    
        # Parse arguments
        set variables {}
        set condition {}
        set mask {}
        foreach arg_pair [eval "parse_arguments {} -variables {-mask -condition} {-variable -variables} $args"] {
            set arg [lindex $arg_pair 0]

            # Variable patterns to match
            if {[lsearch -exact {-variable -variables} $arg] != -1} {
                foreach variable [lindex $arg_pair 1] {
                    set added 0
                    foreach defined_variable [concat $gconfig::defined_variables $gconfig::undefined_variables] {
                        if {[string match $variable $defined_variable]} {
                            lappend variables $defined_variable
                            set added 1
                        }
                    }
                    if {$added == 0} {
                        print_message {WARNING} "No defined variables match \033\[91m$variable\033\[0m pattern."
                        lappend variables $variable
                    }
                }
                
            # Masks to apply
            } elseif {$arg == {-mask}} {
                set mask [lindex $arg_pair 1]
                
            # Conditions to delete
            } elseif {$arg == {-condition}} {
                set condition [regsub -all { } [lindex $arg_pair 1] {}]
            }    
        }

        # Variables to delete
        set skipped_variables {}
        set processed_variables {}

        # Check input parameters
        if {[concat $variables $mask $condition] == {}} {
            print_message {ERROR} "Please specify at least one variable, mask or condition to delete values."
        
        # Clear variables
        } else {

            # Filter records
            set new_records {}
            foreach record $gconfig::records {
                set is_deleted 0
                set record_variable [get_record_variable $record]
                if {($variables == {}) || ([lsearch -exact $variables $record_variable] != -1)} {
                    set record_mask [get_record_mask $record 2]
                    if {($mask == {}) || ([compare_mask_patterns $record_mask $mask] == $record_mask)} {
                        if {($condition == {}) || ($condition == [regsub -all { } [get_record_condition $record 0] {}])} {
                            set is_deleted 1
                        }
                    }
                    if {$is_deleted} {
                        if {[lsearch -exact $processed_variables $record_variable] == -1} {
                            lappend processed_variables $record_variable
                        }
                    }
                }
                if {!$is_deleted} {
                    if {[lsearch -exact $skipped_variables $record_variable] == -1} {
                        lappend skipped_variables $record_variable
                    }
                    lappend new_records $record
                }
            }
            

            # Apply changes
            if {$gconfig::records != $new_records} {
                set gconfig::last_records $gconfig::records
                set gconfig::records $new_records
                set gconfig::filtered_records_args {}
                
            # No changes
            } else {
                print_message {WARNING} "No changes made."
            }
        }
        
        return $processed_variables
    }

    # Get config records
    proc get_records {args} {

        # Parse arguments
        set records {}
        set switches {}
        set masks {}
        set types {}
        set variables {}
        set evaluate 0
        foreach arg_pair [eval "parse_arguments {-eval -evaluate} -variables {-mask -view -type} {-variable -variables -masks -switches -views -records} $args"] {

            # Records
            set arg [lindex $arg_pair 0]
            if {$arg == {-records}} {
                set records [concat $records [lindex $arg_pair 1]]
                
            # Mask filters
            } elseif {[lsearch -exact {-mask -view} $arg] != -1} {
                # lappend masks [lindex $arg_pair 1]
                set masks [concat $masks [ungroup_mask_pattern [lindex $arg_pair 1]]]
            } elseif {[lsearch -exact {-masks -views} $arg] != -1} {
                foreach mask [lindex $arg_pair 1] {
                    set masks [concat $masks [ungroup_mask_pattern $mask]]
                }
                
            # Active switches
            } elseif {$arg == {-switches}} {
                set switches [concat $switches [lindex $arg_pair 1]]
                
            # Type filters
            } elseif {$arg == {-type}} {
                lappend types [lindex $arg_pair 1]
                
            # Evaluate flag
            } elseif {[lsearch -exact {-eval -evaluate} $arg] != -1} {
                set evaluate 1
                
            # Variable patterns to match
            } elseif {[lsearch -exact {-variable -variables} $arg] != -1} {
                foreach variable [lindex $arg_pair 1] {
                    set added 0
                    foreach defined_variable [concat $gconfig::defined_variables $gconfig::undefined_variables] {
                        if {[string match $variable $defined_variable]} {
                            lappend variables $defined_variable
                            set added 1
                        }
                    }
                    if {$added == 0} {
                        print_message {WARNING} "No defined variables match \033\[91m$variable\033\[0m pattern."
                        lappend variables $variable
                    }
                }
            }
        }

        # Default records
        if {$records == {}} {
            set records $gconfig::records
        }
        
        # Active switches
        if {($switches == {}) && $evaluate} {
            set switches $gconfig::active_switches
        }
        
        # Filter records by each mask separately
        if {$masks != {}} {
            set result_records {}
            foreach mask $masks {
                set filtered_records [filter_records $records $switches $mask $variables $evaluate]
                
                # Evaluate records when required
                if {$evaluate} {
                    set filtered_records [evaluate_records $filtered_records]
                }
                
                set result_records [concat $result_records $filtered_records]
            }
            set records $result_records
        
        # Evaluate records
        } else {
            set records [filter_records $records $switches {} $variables $evaluate]
            
            # Evaluate records when required
            if {$evaluate} {
                set records [evaluate_records $records]
            }
        }

        # Filter records by type
        if {$types != {}} {
            set filtered_records {}
            foreach record $records {
                if {[lsearch -exact $types [get_record_type $record]] != -1} {
                    lappend filtered_records $record
                }
            }
            set records $filtered_records
        }

# check_here
# cache arguments and values in filter operations

        # Filter out not needed variables after evaluation
        if {$evaluate && ($variables != {})} {
            set filtered_records {}
            foreach record $records {
                if {[lsearch -exact $variables [get_record_variable $record]] != -1} {
                    lappend filtered_records $record
                }
            }
            set records $filtered_records
        }

        return $records
    }


    # Get record values
    proc get {args} {
        set result {}
        
        # Parse arguments
        set variable {}
        set records {}
        set masks {}
        set merge_mode {-redefine}
        set filtered_args {}
        foreach arg_pair [eval "parse_arguments {-merge -redefine -last} -variable {-variable -mask -view -type} {-switches -records -views -masks} $args"] {
            set arg [lindex $arg_pair 0]
            if {$arg == {-records}} {
                set records [concat $records [lindex $arg_pair 1]]
            } elseif {[lsearch -exact {-merge -redefine -last} $arg] != -1} {
                set merge_mode $arg
                continue
            } elseif {$arg == {-variable}} {
                set variable [lindex $arg_pair 1]
                check_variable $variable
            } elseif {[lsearch -exact {-mask -view} $arg] != -1} {
                set masks [concat $masks [ungroup_mask_pattern [lindex $arg_pair 1]]]
            } elseif {[lsearch -exact {-masks -views} $arg] != -1} {
                foreach mask [lindex $arg_pair 1] {
                    set masks [concat $masks [ungroup_mask_pattern $mask]]
                }
            }
            lappend filtered_args $arg_pair
        }

        # Enable message queue mode
        queue_messages

        # Variable should be defined
        if {$variable == {}} {
            print_message {WARNING} "Required -variable \033\[91m<name>\033\[0m argument has not specified."

        # Exact mask should be defined
        } elseif {[llength $masks] > 1} {
            print_message {ERROR} "Only \033\[91m one mask\033\[0m allowed in gconfig::\033\[97mget\033\[0m command."

        # Variable argument defined
        } else {

           # Get records if record list is empty
            if {$records == {}} {
                set records [eval "get_records [join $filtered_args] -evaluate"]
            }
            
            # Filter requested variable records
            set filtered_records [filter_records_by_index $records 3 == $variable]

            # Filter records by first mask before merge
            if {$masks != {}} {
                set filtered_records [filter_records_by_mask $filtered_records [lindex $masks 0]]
            }
            
            # Final result
            set result [get_record_value [merge_records $filtered_records $merge_mode]]
        }
        
        # Dump queued messages
        print_messages
        
        return $result
    }

    # Print config
    proc show {args} {
        show_records [eval "get_records $args"]
    }

    # Reset configuration
    reset

# end of gconfig namespace
}
