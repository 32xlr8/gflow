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
# Filename: templates/project.2025/tools/tool_steps.genus.gf
# Purpose:  Genus steps to use in the Generic Flow
################################################################################

gf_info "Loading tool-specific Genus steps ..."

################################################################################
# Synthesis steps
################################################################################

# Check if design has unresolved instances
gf_create_step -name genus_check_missing_cells '
    set unresolved_modules [get_db -u [get_db hinsts -if .unresolved] .module.name]
    if {$unresolved_modules == {}} {
        puts "\033\[42m \033\[0m No unresolved modules found"
    } else {
        puts "\033\[44m \033\[0m Set variable below in ./block.search.gf and run ./flows/files.search.gf to look for required files on disk.\n"
        puts "GF_SEARCH_CELLS='"'"'\n    [join $unresolved_modules "\n    "]\n'"'"'\n"
        puts "\033\[41m \033\[0m Total [llength $unresolved_modules] unresolved modules found.\n"
        sleep 10
    }
'

# Reporting procs
gf_create_step -name genus_procs_reports '

    # Write out hinst parameters
    proc gf_report_hdl_parameters {file} {
        puts "\033\[36;46m \033\[0m Creating $file ..."
        redirect $file {
            foreach hinst [lsort [get_db current_design .hinsts -if .module.hdl_parameters!=""]] {
                set module [get_db $hinst .module]
                puts "[get_db $module .name] ([get_db $module .hdl_user_name]) => [get_db $hinst .name]"
                foreach parameter [lsort [get_db $module .hdl_parameters]] {
                    puts "  [lindex $parameter 0] = [lindex $parameter 1]"
                }
                puts ""
            }
        }
    }

    # # Write out flops statistics by module
    # proc gf_report_modules_statistics {file {threshold 10}} {
        # puts "\033\[36;46m \033\[0m Creating $file ..."
        # redirect $file {
            # foreach hinst [lsort [get_db current_design .hinsts]] {
                # if {[set num_insts [llength [set insts [get_db $hinst .local_insts]]]] > $threshold} {
                    # set num_flops [llength [get_db $insts -if .is_sequential]]
                    # puts "[format {%3.0f%%} [expr 100.0*$num_flops/$num_insts]] flops = [format {%6d / %-6d} $num_flops $num_insts] [format {%-40s} "[get_db $hinst .module.name] ([get_db $hinst .module.hdl_user_name])"] [get_db $hinst .name]"
                # }
            # }
        # }
    # }
    
    # Write out flops statistics per hinst
    proc gf_report_hinst_flops_statistics {file {depth 5} {threshold 10}} {
        puts "\033\[36;46m \033\[0m Creating $file ..."
        
        # Statistics collection
        proc gf_report_hinst_flops_statistics_recursive {hinst depth tab threshold} {
            if {$depth>0} {
                if {[set num_insts [llength [set insts [get_db $hinst .insts]]]] >= $threshold} {
                    set num_flops [llength [get_db $insts -if .is_sequential]]
                    puts "$tab:[format {%3.0f%%} [expr 100.0*$num_flops/$num_insts]] flops = [format {%6d / %-6d} $num_flops $num_insts] [get_db $hinst .name] ([get_db $hinst .module.hdl_user_name]:[get_db $hinst .module.name])"
                    foreach hinst [get_db $hinst .local_hinsts] {
                        gf_report_hinst_flops_statistics_recursive $hinst [expr $depth-1] "$tab  " $threshold
                    }
                }
            }
        }
        
        # Report generation
        redirect $file {
            set num_insts [llength [set insts [get_db current_design .insts]]]
            set num_flops [llength [get_db $insts -if .is_sequential]]
            puts "[format {%3.0f%%} [expr 100.0*$num_flops/$num_insts]] flops = [format {%6d / %-6d} $num_flops $num_insts] [get_db current_design .name]"
            foreach hinst [get_db current_design .local_hinsts] {
                gf_report_hinst_flops_statistics_recursive $hinst $depth "  " $threshold
            }
        }
    }
    
    # Create dummy lefs with port definitions
    proc gf_write_dummy_lef {file design_or_module {width 100.000} {height 100.000}} {
        if {[set name [get_db $design_or_module .name]]!=""} {
            if {[get_db $design_or_module .obj_type] == "design"} {
                set ports [get_db $design_or_module .ports]
            } else {
                set ports [get_db [lindex [get_db $design_or_module .hinsts] 0] .hports]
            }
            if {[llength $ports]} {
                puts "\033\[34;44m \033\[0m Writing $file ..."
                exec mkdir -p [file dirname $file]
                set FH [open $file "w"]
                puts $FH {VERSION 5.8 ;}
                puts $FH {BUSBITCHARS "[]" ;}
                puts $FH {DIVIDERCHAR "/" ;}
                puts $FH "MACRO $name"
                puts $FH "  CLASS BLOCK ;"
                puts $FH "  SIZE $width BY $height ;"
                puts $FH "  FOREIGN $name 0.000 0.000 ;"
                puts $FH "  ORIGIN 0.000 0.000 ;"
                foreach port [lsort $ports] {
                    set port_name [get_db $port .base_name]
                    set port_direction "INPUT"; if {[get_db $port .direction] == "out"} {set port_direction "OUTPUT"}
                    puts $FH "  PIN $port_name"
                    puts $FH "    USE SIGNAL ;"
                    puts $FH "    DIRECTION $port_direction ;"
                    puts $FH "  END $port_name"
                }
                puts $FH "END $name"
                puts $FH "END LIBRARY"
                close $FH
            }
        }
    }

    # Update LEF 
    proc gf_update_lef_pins {reference_file target_file {output_file {}}} {
        if {$output_file == ""} {set output_file $target_file}
        if {[file exists $reference_file]} {
            puts [exec perl -e {
                my $reference_file = shift;
                my $target_file = shift;
                my $output_file = shift;
                my @files; my %pins; my $counter = -1;
                sub read_file {
                    my $file = shift;
                    my $is_header = 1;
                    my $pin = "";
                    
                    # Read LEF file content
                    if (open FILE, $file) {
                        $counter++;
                        while (<FILE>) {
                            
                            # Pin definition
                            if (/^\s*PIN\s*(.*\S)\s*$/i) {
                                $pin = $1;
                                my $index = ".$pin."; $index =~ s/[\[\]\{\}\<\>\.\\_]+/*/ig; $index =~ s/(\d+)/sprintf("%06d",$1)/ge;
                                $pins{$pin} = $index;
                                $files[$counter]{pins}{$pin}{begin} = $_;
                                $files[$counter]{pins}{$pin}{content} = "";
                                $files[$counter]{index}{$index}{count}++;
                                $files[$counter]{index}{$index}{pin} = $pin;
                                $is_header = 0;

                            # Pin content
                            } elsif ($pin ne "") {
                                my $is_content = 1;
                                if (/^\s*END\s*(.*\S)\s*$/i) {
                                    if ($1 eq $pin) {
                                        $files[$counter]{pins}{$pin}{end} = $_;
                                        $is_content = 0;
                                    }
                                }
                                if ($is_content) {
                                    $files[$counter]{pins}{$pin}{content} .= $_;
                                } else {
                                    $files[$counter]{footer} .= $_;
                                }
                            
                            # Header
                            } elsif ($is_header) {
                                $files[$counter]{header} .= $_;
                            
                            # Footer
                            } else {
                                $files[$counter]{footer} .= $_;
                            }
                        }
                        close FILE;
                    }
                }
                my @messages; 
                sub add_message {
                    my $header = shift;
                    my $body = shift;
                    my @values = (); push @values, $1 while ($body =~ s|(\d+)|\!\*\!|);
                    $messages[$#messages+1]{text} = $header." ".$body."\n";
                    for (
                        my $i=0; $i<=$#values; $i++
                    ) {
                       $messages[$#messages]{values}[$i] = $values[$i];
                    }
                }
                exit "Error: file $reference_file not found\n" if (! -e $reference_file);
                exit "Error: file $target_file not found\n" if (! -e $target_file);
                read_file $reference_file;
                read_file $target_file;
                if (open FILE, ">".$output_file) {
                    print FILE $files[0]{header};
                    foreach my $pin (sort {$pins{$a} cmp $pins{$b}} keys %pins) {
                        my $index = $pins{$pin};
                        my $processed = 0;
                        if ((defined $files[0]{pins}{$pin}) && (defined $files[1]{pins}{$pin})) {
                            print FILE $files[0]{pins}{$pin}{begin};
                            print FILE $files[0]{pins}{$pin}{content};
                            print FILE $files[0]{pins}{$pin}{end};
                            $processed = 1;
                        } elsif (($files[0]{index}{$index}{count} == 1) && ($files[1]{index}{$index}{count} == 1)) {
                            if (defined $files[1]{pins}{$pin}) {
                                my $prev_pin = $files[0]{index}{$index}{pin};
                                add_message ("\e[33;43m \e[0m", "Port $prev_pin renamed to $pin");
                                print FILE $files[1]{pins}{$pin}{begin};
                                print FILE $files[0]{pins}{$prev_pin}{content};
                                print FILE $files[1]{pins}{$pin}{end};
                            }
                            $processed = 1;
                        }
                        if (!$processed) {
                            if (defined $files[1]{pins}{$pin}) {
                                add_message ("\e[35;45m \e[0m", "Port $pin added");
                                print FILE $files[1]{pins}{$pin}{begin};
                                print FILE $files[1]{pins}{$pin}{content};
                                print FILE $files[1]{pins}{$pin}{end};
                            } else {
                                add_message ("\e[31;41m \e[0m", "Port $pin deleted");
                            }
                        }
                    }
                    
                    # Detect message groups
                    my %messages; my %values;
                    for (
                        my $i=0; $i<=$#messages; $i++
                    ) {
                        my $text = $messages[$i]{text};
                        $messages{$text} = 1;
                        my $j=0; foreach my $value (@{$messages[$i]{values}}) {
                            $values{$text}[$j]{values}{$value} = 1;
                            $j++;
                        }
                    }
                    
                    # Print grouped messages
                    my %index;
                    for (
                        my $i=0; $i<=$#messages; $i++
                    ) {
                        my $text = $messages[$i]{text};
                        my $index = $text;
                        for (
                            my $j=0; $j<=$#{$values{$text}}; $j++
                        ) {
                            my @values = keys %{$values{$text}[$j]{values}};
                            if ($#values == 0) {
                                my $value = $values[0];
                                $index =~ s|\!\*\!|$value|;
                            } else {
                                $index =~ s|\!\*\!|\*|;
                            }
                        }
                        print $index if (!defined $index{$index}); $index{$index} = 1;
                    }

                    print FILE $files[0]{footer};
                    close FILE;
                }
            } $reference_file $target_file $output_file]
        }
    }
'
