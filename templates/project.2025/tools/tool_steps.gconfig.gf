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
# Filename: templates/project.2025/tools/tool_steps.gconfig.gf
# Purpose:  TCL procedures to work with file lists
################################################################################

gf_info "Loading tool-specific gconfig steps ..."

gf_create_step -name init_gconfig_mmmc '

    ##########################################################
    # MMMC-specific configuration
    ##########################################################

    # Current OCV mode control switches
    gconfig::define_switches -group "OCV libraries presets" -optional -switches {aocv_libraries socv_libraries}
    gconfig::define_switches -group "OCV derate factor presets" -required -switches {no_derates flat_derates vt_derates user_derates}

    # Variables storing files to use
    gconfig::define_variables -group "Project MMMC files" {sdc_files lib_files lvf_files cdb_files aocv_files socv_files cap_table_files qrc_files pgv_files spef_files twf_files}

    # Operating conditions for create_timing_condition command
    gconfig::define_variables -group "MMMC operating conditions" -variables {power_domain_timing_conditions opcond opcond_lib}

    # Variables to store MMMC object names
    gconfig::define_variables -group "MMMC object names" -variables {
        constraint_mode_name library_set_name timing_condition_name extract_corner_name delay_corner_name analysis_view_name
    }

    # MMMC variables
    gconfig::define_variables -group "MMMC extraction corner temperature" -variables {temperature}
    gconfig::define_variables -group "MMMC analysis view types" -variables {is_setup_view is_hold_view is_leakage_view is_dynamic_view}

    # Variables to store MMMC commands
    gconfig::define_variables -group "MMMC commands" -variables {
        constraint_mode_commands library_set_commands timing_condition_commands extract_corner_commands delay_corner_commands update_delay_corner_commands analysis_view_commands
    }
    gconfig::define_variables -group "OCV commands" -variables {
        set_timing_derate_commands set_clock_uncertainty_commands
    }

    # Variables to store file arguments used in MMMC commands
    gconfig::define_variables -group "MMMC file lists" -variables {
        sdc_argument opcond_argument lib_argument cdb_argument aocv_argument socv_argument cap_table_argument qrc_argument
    }

    # Analysis view types
    gconfig::add_section {
        # Variable mask meaning is {<constraint_mode> <process> <voltage> <temperature> <rc_corner> <check>}

        # STA setup and hold views
        -views {* * * * * s} {$is_setup_view 1}
        -views {* * * * * h} {$is_hold_view 1}
        
        # Power analysis views
        -views {* * * * * {p l}} {$is_leakage_view 1}
        -views {* * * * * {p d}} {$is_dynamic_view 1}
    }
        
    # Automatical MMMC object names (merged view mask of dependent variables)
    gconfig::add_section {
        -auto_name $library_set_name {$library_set_commands}
        -auto_name $timing_condition_name {$timing_condition_commands}
        -auto_name $extract_corner_name {$extract_corner_commands}
        -auto_name $delay_corner_name {$delay_corner_commands $update_delay_corner_commands $set_timing_derate_commands}
        -auto_name $constraint_mode_name {$constraint_mode_commands $set_clock_uncertainty_commands}
        -auto_name $analysis_view_name {$analysis_view_commands}
    }

    # MMMC file list arguments splitted into lines with paragraph
    gconfig::add_section {
     
        # SDC files
        -when {$sdc_files}  $sdc_argument {[regsub -all "\n" {$sdc_files} "\n    "]} 
        -when {!$sdc_files} $sdc_argument {} 

        # Operating conditions
        -when {$opcond&$opcond_lib} $opcond_argument {-opcond_library {$opcond_lib} -opcond {$opcond}} 
        -when {!$opcond|!$opcond_lib} $opcond_argument {} 

        # Library files
        -when {$lib_files}  $lib_argument {[regsub -all "\n" {$lib_files} "\n    "]} 
        -when {!$lib_files} $lib_argument {} 

        # Celtic files
        -when {$cdb_files}  $cdb_argument {[regsub -all "\n" {$cdb_files} "\n    "]} 
        -when {!$cdb_files} $cdb_argument {} 

        # AOCV files
        -when {aocv_libraries && $aocv_files}  $aocv_argument {[regsub -all "\n" {$aocv_files} "\n    "]} 
        -when {!aocv_libraries || !$aocv_files} $aocv_argument {}

        # SOCV files
        -when {socv_libraries && $socv_files}  $socv_argument {[regsub -all "\n" {$socv_files} "\n    "]} 
        -when {!socv_libraries || !$socv_files} $socv_argument {} 
        
        # Cap Table file
        -when {$cap_table_files}  $cap_table_argument {[regsub -all "\n" {$cap_table_files} " "]} 
        -when {!$cap_table_files} $cap_table_argument {} 

        # QRC file
        -when {$qrc_files}  $qrc_argument {[regsub -all "\n" {$qrc_files} " "]} 
        -when {!$qrc_files} $qrc_argument {} 
    }

    # MMMC command templates
    gconfig::add_section {

        # Constraint mode
        $constraint_mode_commands {
            create_constraint_mode -name $constraint_mode_name -sdc_files {
                $sdc_argument
            }
            puts \"INFO: Constraint mode ${COLOR}$constraint_mode_name${NO_COLOR} created.\"
        }

        # Library set
        $library_set_commands {
            create_library_set -name $library_set_name -timing {
                $lib_argument
            } -si {
                $cdb_argument
            } -aocv {
                $aocv_argument
            } -socv {
                $socv_argument
            }
            puts \"INFO: Library set ${COLOR}$library_set_name${NO_COLOR} created.\"
        }

        # Timing condition
        $timing_condition_commands {
            create_timing_condition -name $timing_condition_name -library_set $library_set_name $opcond_argument
            puts \"INFO: Timing condition ${COLOR}$timing_condition_name${NO_COLOR} created.\"
        }

        # RC corner
        $extract_corner_commands {
            create_rc_corner -name $extract_corner_name \\
                -cap_table {$cap_table_argument} \\
                -qrc_tech {$qrc_argument} \\
                -temperature {$temperature}
            puts \"INFO: RC corner ${COLOR}$extract_corner_name${NO_COLOR} created.\"
        }

        # Delay corner
        $delay_corner_commands {
            create_delay_corner -name $delay_corner_name -timing_condition $timing_condition_name -rc_corner $extract_corner_name
            puts \"INFO: Delay corner ${COLOR}$delay_corner_name${NO_COLOR} created.\"
        }

        # Update delay corner for low power MMMC
        $update_delay_corner_commands {
            update_delay_corner -name $delay_corner_name -timing_condition {$timing_condition_name \$power_domain_conditions} -rc_corner $extract_corner_name
            puts \"INFO: Delay corner ${COLOR}$delay_corner_name${NO_COLOR} updated.\"
        }

        # Analysis view
        $analysis_view_commands {
            create_analysis_view -name $analysis_view_name -constraint_mode $constraint_mode_name -delay_corner $delay_corner_name
            puts \"INFO: Analysis view ${COLOR}$analysis_view_name${NO_COLOR} created.\"
        }
    }

    # Switch to control if MMMC commands output will be colorized
    gconfig::define_switches -group "Colored commands support" -switches {colorize}
    gconfig::enable_switches colorize

    # Variables to substitite as colors
    gconfig::define_variables -group "Coloring variables" -variables {COLOR NO_COLOR}

    # Colored messages support
    gconfig::add_section {

        # Bold/normal color variables
        -when colorize {
            $COLOR {\\033\\\\\[97m}
            $NO_COLOR {\\033\\\\\[0m}
        }
        
        # No color variables
        -when !colorize {
            $COLOR {}
            $NO_COLOR {}
        }
    }

    ##########################################################
    # File setup aliases to simplify project and design config
    ##########################################################

    # Alias to add files into specific variable by type (lib, lef, etc.)
    proc gconfig::add_files {type args} {
        set variable "${type}_files"
        if {![gconfig::is_variable_defined $variable]} {
            gconfig::define_variables -group "Other files" $variable
        }
        return [llength [add_section "\\\$$variable -files $args"]]
    }

    # Alias to get files by type
    proc gconfig::get_files {type args} {
        set variable "${type}_files"
        return [eval "gconfig::get -variable $variable $args"]
    }

    ##########################################################
    # Procedures to use in the flow scripts
    ##########################################################

    # Define extraction temperatures for RC corners
    proc gconfig::add_extraction_temperatures {args} {
        return [add_section "\\\$temperature $args"]
    }

    # Define timing derate commands to configure OCV
    proc gconfig::add_timing_derate_commands {args} {
        return [add_section "-merge \\\$set_timing_derate_commands $args"]
    }

    # Define clock uncertaintycommands to configure OCV
    proc gconfig::add_clock_uncertainty_commands {args} {
        return [add_section "-merge \\\$set_clock_uncertainty_commands $args"]
    }

    # Define extraction temperatures for RC corners
    proc gconfig::add_power_domain_timing_conditions {args} {
        return [add_section "\\\$power_domain_timing_conditions $args"]
    }

    # Get MMMC commands to evaluate or dump
    proc gconfig::get_mmmc_commands {args} {

        # Reset error counter
        get_error_count
        
        # Parse arguments
        set analysis_views {}
        set active_views {}
        set all_active_views 0
        set out_file {}
        foreach arg_pair [parse_proc_arguments -parameters "-views -active_views -dump_to_file" -options "-all_active" $args] {
            set arg [lindex $arg_pair 0]
            
            # Specify analysis views
            if {$arg == {-views}} {
                set analysis_views [concat $analysis_views [lindex $arg_pair 1]]
                
            # Specify active analysis views
            } elseif {$arg == {-active_views}} {
                set active_views [concat $active_views [lindex $arg_pair 1]]
            } elseif {$arg == {-all_active}} {
                set all_active_views 1
                
            # Dump mmmc configuration to file
            } elseif {$arg == {-dump_to_file}} {
               set out_file [lindex $arg_pair 1]
            }
        }

        # View list should not be empty
        if {$analysis_views == {}} {
            print_message {ERROR} "\033\[91mNo analysis views\033\[0m defined in get_ocv_commands. Please use \033\[97m-views\033\[0m option."
            print_messages
            return {}
        }
       
        # Views argument should be a list
        if {[lindex $analysis_views 0 1] == {}} {
            print_message {ERROR} "Value \033\[97m$analysis_views\033\[0m is \033\[91mnot a list of views\033\[0m. Please use {{mode process voltage temperature extraction check} ...} template."
            print_messages
            return {}
        }
       
        # Use all analysis views if not specified by user
        if {$active_views == {}} {set active_views $analysis_views}
                
        # Remove view duplicates
        set views {}
        foreach view $analysis_views {
            if {[lsearch -exact $views $view] == -1} {
                lappend views $view
            }
        }

        # Timing conditions views for low power MMMC file
        set tc_views {}
        foreach view $views {
            set pd_conditions [get -variable power_domain_timing_conditions -view $view]
            foreach {pd sub_view} $pd_conditions {
                set tc_view {}
                set i 0
                while {$i < [llength $view]} {
                    set mask [lindex $sub_view $i]
                    if {($mask == "") || ($mask == "*")} {
                        lappend tc_view [lindex $view $i]
                    } else {
                        lappend tc_view $mask
                    }
                    incr i
                }
                if {[lsearch -exact [concat $views $tc_views] $tc_view] == -1} {
                    lappend tc_views $tc_view
                }
            }
        }

        # Variables to store MMMC object names
        set library_set_names {}
        set timing_condition_names {}
        set extract_corner_names {}
        set delay_corner_names {}
        set constraint_mode_names {}
        set analysis_view_names {}

        # Variables to store content
        set library_set_commands {}
        set timing_condition_commands {}
        set extract_corner_commands {}
        set delay_corner_commands {}
        set update_delay_corner_commands {}
        set constraint_mode_commands {}
        set analysis_view_commands {}
        
        # View sets
        set setup_views {}
        set hold_views {}
        set leakage_view {}
        set dynamic_view {}
        
        # Process every view in the list
        puts {}
        print_subtitle "Configuring MMMC views"
        foreach view [concat $tc_views $views] {
            
            # Queue messages
            catch {
                queue_messages

                # Get all config records relative to current view
                set view_records [get_records -variables {*_name *_commands is_* power_domain_timing_conditions} -view $view -evaluate]

                # Get unique MMMC objects names for current view
                set library_set_name [get library_set_name -records $view_records]
                set timing_condition_name [get timing_condition_name -records $view_records]
                set extract_corner_name [get extract_corner_name -records $view_records]
                set delay_corner_name [get delay_corner_name -records $view_records]
                set constraint_mode_name [get constraint_mode_name -records $view_records]
                set analysis_view_name [get analysis_view_name -records $view_records]
                
                # Print information - timing conditions
                if {[lsearch -exact $views $view] == -1} {
                    puts "=> Timing condition \033\[97m$timing_condition_name\033\[0m {$view} (library set $library_set_name)"

                # Print information - analysis views
                } else {
                    puts "=> Analysis view \033\[97m$analysis_view_name\033\[0m {$view} (mode $constraint_mode_name, delay corner $delay_corner_name, RC corner $extract_corner_name, library set $library_set_name)"
                }
                
                # Add new library set if not added already
                if {[lsearch -exact $library_set_names $library_set_name] == -1} {
                    lappend library_set_names $library_set_name
                    
                     # Remove leading indent and evaluate expressions
                    set command [subst [regsub -line -all {^ {8}} \
                        [get -variable library_set_commands -records $view_records] \
                    {}]]
                    
                    # Remove empty arguments
                    set command [regsub -all {\s+\-[a-z_]+\s+\{\s*\}} $command {}]
                    
                    # Argument -timing should exist
                    if {![regexp { -timing } $command]} {
                        print_message {ERROR} "\033\[91mNo LIB files\033\[0m configured for view {\033\[97m$view\033\[0m}. Please use gconfig::\033\[97madd_files lib\033\[0m command."
                    }
                    
                    # Argument -aocv should exist in aocv mode
                    if {[is_switch_enabled aocv_libraries] && ![regexp { -aocv } $command]} {
                        print_message {ERROR} "\033\[91mNo AOCV files\033\[0m configured for view {\033\[97m$view\033\[0m} in AOCV mode. Please use gconfig::\033\[97madd_files aocv\033\[0m command."
                    }
                    
                    # Argument -socv should exist in socv mode
                    if {[is_switch_enabled socv_libraries] && ![regexp { -socv } $command]} {
                        print_message {ERROR} "\033\[91mNo SOCV files\033\[0m configured for view {\033\[97m$view\033\[0m} in SOCV mode. Please use gconfig::\033\[97madd_files socv\033\[0m command."
                    }
                    
                    # Add library set commands
                    append library_set_commands [regsub {\s*$} $command "\n"]
                }

                # Add new timing condition if not added already
                if {[lsearch -exact $timing_condition_names $timing_condition_name] == -1} {
                    lappend timing_condition_names $timing_condition_name
                    
                     # Remove leading indent and evaluate expressions
                    set command [subst [regsub -line -all {^ {8}} \
                        [get -variable timing_condition_commands -records $view_records] \
                    {}]]
                    
                    # Add timing condition commands
                    append timing_condition_commands [regsub {\s*$} $command "\n"]
                }

                # True views
                if {[lsearch -exact $views $view] != -1} {
                    
                    # Add new constraint mode if not added already
                    if {[lsearch -exact $constraint_mode_names $constraint_mode_name] == -1} {
                        lappend constraint_mode_names $constraint_mode_name
                        
                        # Remove leading indent and evaluate expressions
                        set command [subst [regsub -line -all {^ {8}} \
                            [get -variable constraint_mode_commands -records $view_records] \
                        {}]]
                        
                        # Remove empty arguments
                        set command [regsub -all {\s+\-[a-z_]+\s+\{\s*\}} $command {}]
                        
                        # Argument -sdc_files should exist
                        if {![regexp { -sdc_files } $command]} {
                            print_message {ERROR} "\033\[91mNo SDC files\033\[0m configured for view {\033\[97m$view\033\[0m}. Please use gconfig::\033\[97madd_files sdc\033\[0m command."
                        }
                        
                        # Add constraint mode commands
                        append constraint_mode_commands [regsub {\s*$} $command "\n"]
                    }

                    # Add new extraction corner if not added already
                    if {[lsearch -exact $extract_corner_names $extract_corner_name] == -1} {
                        lappend extract_corner_names $extract_corner_name
                        
                        # Remove leading indent and evaluate expressions
                        set command [subst [regsub -line -all {^ {8}} \
                            [get -variable extract_corner_commands -records $view_records] \
                        {}]]
                        
                        # Remove empty arguments
                        set command [regsub -all {\\\s*\\} [regsub -all {\s+\-[a-z_]+\s+\{\s*\}\s*} $command {}] {\\}]
                        
                        # Argument -timing should exist
                        if {![regexp { -cap_table } $command] && ![regexp { -qrc_tech } $command]} {
                            print_message {ERROR} "\033\[91mNo QRC tech or CapTbl file\033\[0m configured for view {\033\[97m$view\033\[0m}. Please use gconfig::\033\[97madd_files qrc\033\[0m or  gconfig::\033\[97madd_files cap_table\033\[0mcommand."
                        }
                        
                        # Add etraction corner commands
                        append extract_corner_commands [regsub {\s*$} $command "\n"]
                    }

                    # Add new delay corner if not added already
                    if {[lsearch -exact $delay_corner_names $delay_corner_name] == -1} {
                        lappend delay_corner_names $delay_corner_name
                        
                        # Remove leading indent and evaluate expressions
                        set command [subst [regsub -line -all {^ {8}} \
                            [get -variable delay_corner_commands -records $view_records] \
                        {}]]
                        
                        # Add delay corner commands
                        append delay_corner_commands [regsub {\s*$} $command "\n"]

                        # Low power MMMC
                        set power_domain_conditions {}
                        foreach {pd sub_view} [get -variable power_domain_timing_conditions -records $view_records] {
                            set tc_view {}
                            set i 0
                            while {$i < [llength $view]} {
                                set mask [lindex $sub_view $i]
                                if {($mask == "") || ($mask == "*")} {
                                    lappend tc_view [lindex $view $i]
                                } else {
                                    lappend tc_view $mask
                                }
                                incr i
                            }
                            lappend power_domain_conditions "$pd@[get -variable timing_condition_name -view $tc_view]"
                        }

                        # Update delay corner
                        if {[llength $power_domain_conditions] > 0} {
                            
                            # Remove leading indent and evaluate expressions
                            set command [subst [regsub -line -all {^ {8}} \
                                [get -variable update_delay_corner_commands -records $view_records] \
                            {}]]
                            set command [regsub -line -all {\$power_domain_conditions} $command $power_domain_conditions]
                            
                            # Add delay corner commands
                            append update_delay_corner_commands [regsub {\s*$} $command "\n"]
                        }
                    }

                    # Add new analysis view if not added already
                    if {[lsearch -exact $analysis_view_names $analysis_view_name] == -1} {
                        lappend analysis_view_names $analysis_view_name
                        
                        # Remove leading indent and evaluate expressions
                        set command [subst [regsub -line -all {^ {8}} \
                            [get -variable analysis_view_commands -records $view_records] \
                        {}]]
                        
                        # Add analysis view commands
                        append analysis_view_commands [regsub {\s*$} $command "\n"]
                    }

                    set is_view_active [expr {[lsearch -exact $active_views $view] != -1}]
                    
                    # Update view sets
                    if {$is_view_active} {
                        if {$all_active_views || ([get -records $view_records -variable is_setup_view] != {})} {
                            lappend setup_views $analysis_view_name
                        }
                        if {$all_active_views || ([get -records $view_records -variable is_hold_view] != {})} {
                            lappend hold_views $analysis_view_name
                        }
                        if {[get -records $view_records -variable is_leakage_view] != {}} {
                            set leakage_view $analysis_view_name
                        }
                        if {[get -records $view_records -variable is_dynamic_view] != {}} {
                            set dynamic_view $analysis_view_name
                        }
                    }
                }
            }
            
            # Print error messages if they exist
            print_messages
            
            # No errors allowed
            if {[get_error_count] != 0} {
                error "Please fix errors above to get correct value"
            }
        }
        

        # Compose result MMMC commands
        set result {}
        
        append result "##################################################\n"
        append result "# Library sets\n"
        append result "##################################################\n"
        append result "$library_set_commands\n"

        if {[lindex $timing_condition_commands 0] != {}} {
            append result "##################################################\n"
            append result "# Timing conditions\n"
            append result "##################################################\n"
            append result "$timing_condition_commands\n"
        }

        append result "##################################################\n"
        append result "# Extraction corners\n"
        append result "##################################################\n"
        append result "$extract_corner_commands\n"

        append result "##################################################\n"
        append result "# Delay corners\n"
        append result "##################################################\n"
        append result "$delay_corner_commands\n"

        append result "##################################################\n"
        append result "# Constraint modes\n"
        append result "##################################################\n"
        append result "$constraint_mode_commands\n"

        append result "##################################################\n"
        append result "# Analysis views\n"
        append result "##################################################\n"
        append result "$analysis_view_commands\n"

        # Fix empty setup and hold view lists
        if {$setup_views == {}} {set setup_views [lindex [concat $hold_views $leakage_view $dynamic_view] 0]}
        if {$hold_views == {}} {set hold_views [lindex [concat $setup_views $leakage_view $dynamic_view] 0]}
        
        # Compose command
        set command {
            set_analysis_view \\
                -setup {$setup_views} \\
                -hold {$hold_views} \\
                -leakage {$leakage_view} \\
                -dynamic {$dynamic_view} \\
        }
        
        # Remove leading indent and substitite variables
        set command [subst [regsub -line -all {^ {8}} $command {}]]
        
        # Remove empty arguments
        set command [regsub -all {\s+\-[a-z_]+\s+\{\s*\}} $command {}]
                
        # Add commands to set analysis view 
        append result "##################################################\n"
        append result "# Active views\n"
        append result "##################################################\n"
        append result "[regsub {[\s\\]*$} $command "\n"]\n"

        # Update delay corner commands for low power designs
        if {$update_delay_corner_commands != {}} {
            append result "##################################################\n"
            append result "# Update delay corners\n"
            append result "##################################################\n"
            append result "$update_delay_corner_commands\n"
        }

        # Dump commands to file
        if {$out_file != {}} {
            set FH [open $out_file w]
            puts $FH $result
            close $FH
            return $out_file
            
        # Return commands
        } else {
            puts {}
            return $result
        }
    }

    # Get OCV commands to evaluate or dump
    proc gconfig::get_ocv_commands {args} {

        # Parse arguments
        set analysis_views {}
        set active_views {}
        set out_file {}
        foreach arg_pair [parse_proc_arguments -parameters "-views -active_views -dump_to_file" $args] {
            set arg [lindex $arg_pair 0]
            
            # Specify analysis views
            if {$arg == {-views}} {
                set analysis_views [concat $analysis_views [lindex $arg_pair 1]]
                
            # Specify active analysis views
            } elseif {$arg == {-active_views}} {
                set active_views [concat $active_views [lindex $arg_pair 1]]
                
            # Dump mmmc configuration to file
            } elseif {$arg == {-dump_to_file}} {
               set out_file [lindex $arg_pair 1]
            }
        }

        # View list should not be empty
        if {$analysis_views == {}} {
            print_message {ERROR} "\033\[91mNo analysis views\033\[0m defined in get_ocv_commands. Please use \033\[97m-views\033\[0m option."
            return {}
        }

        # Views argument should be a list
        if {[lindex $analysis_views 0 1] == {}} {
            print_message {ERROR} "Value \033\[97m$analysis_views\033\[0m is \033\[91mnot a list of views\033\[0m. Please use {{mode process voltage temperature extraction check} ...} template."
            print_messages
            return {}
        }
       
                
        # Remove view duplicates
        set views {}
        foreach view $analysis_views {
           if {[lsearch -exact $views $view] == -1} {
                lappend views $view
            }
        }

        # Variables to store MMMC object names
        set delay_corner_names {}
        set constraint_mode_names {}

        # Variables to store content
        set set_timing_derate_commands {}
        set set_clock_uncertainty_commands {}
        
        # Process every view in the list
        puts {}
        print_subtitle "Configuring OCV in views"
        foreach view $views {
        
            # Get all config records relative to current view
            set view_records [get_records -variables {analysis_view_name delay_corner_name constraint_mode_name set_timing_derate_commands set_clock_uncertainty_commands} -view $view -evaluate]
            set analysis_view_name [get -variable analysis_view_name -records $view_records]

            # Get unique MMMC objects names for current view
            set delay_corner_name [get delay_corner_name -records $view_records]
            set constraint_mode_name [get constraint_mode_name -records $view_records]
            
            # Print information
            puts "=> \033\[97m$analysis_view_name\033\[0m {$view} (mode $constraint_mode_name, delay corner $delay_corner_name)"
            
            # Add new constraint mode clock uncertainty if not added already
            if {[lsearch -exact $constraint_mode_names $constraint_mode_name] == -1} {
                lappend constraint_mode_names $constraint_mode_name
                
                # Remove leading indent and evaluate expressions
                # set command [subst [regsub -line -all {^ *\. ?} xxx {}]]
                set command [subst [regsub -line -all {^ +} \
                    [get -variable set_clock_uncertainty_commands -records $view_records] \
                {}]]
                
                # Remove empty lines
                set command [regsub -all {\n[ \n]*\n} $command "\n"]
                
                # Add constraint mode commands
                if {$command != {}} {
                    append set_clock_uncertainty_commands [regsub {\s*$} $command "\n"]
                }
            }

            # Add new delay corner timing derate factors if not added already
            if {[lsearch -exact $delay_corner_names $delay_corner_name] == -1} {
                lappend delay_corner_names $delay_corner_name
                
                # Remove leading indent and evaluate expressions
                set command [subst [regsub -line -all {^ +} \
                    [get -variable set_timing_derate_commands -records $view_records] \
                {}]]
                
                # Remove empty lines
                set command [regsub -all {\n[ \n]*\n} $command "\n"]
                
                # Add delay corner commands
                if {$command != {}} {
                    append set_timing_derate_commands [regsub {\s*$} $command "\n"]
                }
            }
        }
        

        # Compose result OCV commands
        set result {}
        
        if {$set_clock_uncertainty_commands != {}} {
            append result "##################################################\n"
            append result "# Clock uncertainty in constraint modes\n"
            append result "##################################################\n"
            append result "set saved_interactive_constraint_mode \[get_interactive_constraint_mode\]\n"
            append result "$set_clock_uncertainty_commands\n"
            append result "set_interactive_constraint_mode \$saved_interactive_constraint_mode\n\n"
        }

        if {$set_timing_derate_commands != {}} {
            append result "##################################################\n"
            append result "# Timing derate factors in delay corners\n"
            append result "##################################################\n"
            append result "$set_timing_derate_commands\n"
        }

        # Dump commands to file
        if {$out_file != {}} {
            set FH [open $out_file w]
            puts $FH $result
            close $FH
            return $out_file
            
        # Return commands
        } else {
            puts {}
            return $result
        }
    }
'


# Proc to apply IR-drop-aware OCV derates
gf_create_step -name gconfig_procs_ocv '

    # Proc to apply IR-drop-aware OCV derates
    proc gf_apply_ir_cell_derates {IR cells_IR_dV_dT_table check_derates_pattern delay_corner_name args} {
        set derated_cells [get_db base_cells $check_derates_pattern]
        foreach row $cells_IR_dV_dT_table {
            set cells [lindex $row 0]
            set IR_row [lindex $row 1]
            set dV_row [lindex $row 2]
            set dT [lindex $row 3]
            set PDF [lindex $row 4]
            if {[llength $IR_row] < 1} {
                puts "\033\[31;41m \033\[0m ERROR: \033\[1m$cells\033\[0m IR-drop table is empty in $delay_corner_name delay corner"
            } elseif {[llength $IR_row] != [llength $dV_row]} {
                puts "\033\[31;41m \033\[0m ERROR: \033\[1m$cells\033\[0m IR-drop and dV/dT table columns number is different in $delay_corner_name delay corner"
            } else {
                if {$IR > [lindex $IR_row end]} {
                    set dV [lindex $dV_row end]
                    puts "\033\[31;41m \033\[0m ERROR: \033\[1m$cells\033\[0m IR-drop value \033\[1m${IR}\033\[0mmV is out of the range in $delay_corner_name delay corner"
                } else {
                    set dV 0
                    set IR_left 0
                    set dV_left 0
                    set index 0
                    foreach value $IR_row {
                        set IR_right $value
                        set dV_right [lindex $dV_row $index]
                        if {($IR >= $IR_left) && ($IR < $IR_right)} {
                            if {$dV_right < $dV_left} {
                                puts "\033\[31;41m \033\[0m ERROR: \033\[1m$cells\033\[0m IR-drop table is not monotonous in $delay_corner_name delay corner"
                            }
                            if {$IR_right < $IR_left} {
                                puts "\033\[31;41m \033\[0m ERROR: \033\[1m$cells\033\[0m dV/dT table is not monotonous in $delay_corner_name delay corner"
                            } 
                            if {($dV_right != $dV_left) && ($IR_right != $IR_left)} {
                                set dV [expr {0.0001*round(($dV_right-($dV_right-$dV_left)*(($IR-$IR_right)/($IR_left-$IR_right)))*10000)}]
                            }
                        }
                        set IR_left $IR_right
                        set dV_left $dV_right
                        incr index
                    }
                }
                if {[get_db base_cells $cells] != ""} {
                    foreach command $args {eval "$command"}
                    foreach base_cell [get_db [get_db base_cells $cells] .name] {
                        if {[lsearch -exact $derated_cells $base_cell]<0} {
                            lappend derated_cells $base_cell
                        } else {
                            puts "\033\[33;43m \033\[0m WARNING: \033\[1m$base_cell\033\[0m dV/dT derates applied several times in $delay_corner_name delay corner"
                        }
                    }
                }
            }
        }
        if {$check_derates_pattern == ""} {set check_derates_pattern {*}}
        foreach base_cell [get_db [get_db base_cells $check_derates_pattern] .name] {
            if {[lsearch -exact $derated_cells $base_cell]<0} {
                puts "\033\[31;41m \033\[0m ERROR: \033\[1m$base_cell\033\[0m dV/dT derates not found for $delay_corner_name delay corner"
            }
        }
    }
'
