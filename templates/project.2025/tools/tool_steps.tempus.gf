################################################################################
# Generic Flow v5.5.2 (February 2025)
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
# Filename: templates/project.2025/tools/tool_steps.tempus.gf
# Purpose:  Tempus steps to use in the Generic Flow
################################################################################

gf_info "Loading tool-specific Tempus steps ..."

################################################################################
# Report timing steps for Tempus
################################################################################

# Create timing summary report
gf_create_step -name procs_tempus_reports '
 
    # Print report_timing file summary
    proc gf_print_report_timing_summary {file} {
        return [exec perl -e {
            open FILE, $ARGV[0];
            my $count = 0; my $avg = 0.000; my $neg_count = 0; my $wns = "";
            while (<FILE>) {
                if (m|^\s*slack\s*[\:\=]+\s+(\-?\d+\.?\d*)\b|i) {
                    my $slack = $1;
                    $wns = $slack if ($wns eq "");
                    $wns = $slack if ($wns > $slack);
                    $count++;
                    $avg += $slack;
                    $neg_count++ if ($slack < 0);
                }
            }
            close FILE;
            if ($count > 0) {
                $avg /= $count;
                print sprintf("WNS = %+.03f, AVG = %+.03f, %d of %d violated", $wns, $avg, $neg_count, $count);
            } else {
                print "No timing paths\n";
            }
        } $file]
    }
    
    # Print report_timing summary
    proc gf_print_report_contraint_summary {file {header ""}} {
        if {$header == {}} {set header "DRV summary: $file"}
        puts "$header";
        puts [exec perl -e {
            open FILE, $ARGV[0];
            my $check = "";
            while (<FILE>) {
                $check = $1 if (m|^\s*check\s+type\s*:\s*(.*?)\s*$|i);
                if (m|^\s*slack\s*[\:\=]+\s+(\-?\d+\.?\d*)\s*|i) {
                    print sprintf("  Slack = %+.03f @ %s\n", $1, $check) if ($check);
                    $check = "";
                }
            }
        } $file]
    }

    # Print report_noise file summary
    proc gf_print_report_glitch_summary {file} {
        return [exec perl -e {
            open FILE, $ARGV[0];
            my @results; my $violated = 0;
            while (<FILE>) {
                if (/^[\s\#]*View\s*:\s*(\S+)\s*$/) {
                    $results[$#results+1]{view} = $1;
                }
                if (m|^\s*Number\s+of\s+.*[\s\=]+(\d+)\s*$|i) {
                    $violated += $1;
                    $results[$#results]{violated} += $1 if ($#results >= 0);
                }
            }
            print "$violated violations in ".($#results+1)." views\n";
            foreach my $result (@results) {
                print sprintf("  %d nets with violations @ %s\n", $$result{violated}, $$result{view}) if ($$result{violated} > 0);
            }
        } $file]
    }
    
    # Basic design health checks
    proc gf_check_timing {} {

        # Reports that check design health
        check_netlist -out_file ./reports/$::TASK_NAME/check.netlist.rpt
        check_timing -verbose > ./reports/$::TASK_NAME/check.timing.rpt
        report_analysis_coverage > ./reports/$::TASK_NAME/check.coverage.rpt
        report_analysis_coverage -verbose violated > ./reports/$::TASK_NAME/check.coverage.violated.rpt
        report_analysis_coverage -verbose untested > ./reports/$::TASK_NAME/check.coverage.untested.rpt
        report_annotated_parasitics > ./reports/$::TASK_NAME/check.annotation.rpt

        # Reports that describe constraints
        report_clocks > ./reports/$::TASK_NAME/check.clocks.rpt
        report_case_analysis > ./reports/$::TASK_NAME/check.case_analysis.rpt
        #report_inactive_arcs > ./reports/$::TASK_NAME/check.inactive_arcs.rpt
    }

    # Reports that describe noise health
    proc gf_report_noise {} {
        check_noise -all -verbose > ./reports/$::TASK_NAME/check.noise.rpt
        report_noise -out_file ./reports/$::TASK_NAME/noise.rpt
        report_noise -sort_by noise -failure > ./reports/$::TASK_NAME/noise.glitch.rpt
        puts "Glitch summary: [gf_print_report_glitch_summary ./reports/$::TASK_NAME/noise.glitch.rpt]"

        # report_noise -sort_by noise -clock > ./reports/$::TASK_NAME/noise.clock.rpt
        #write_noise_eco_nets ./reports/$::TASK_NAME/glitch.eco_nets.rpt
    }
    
    # Report timing summary
    proc gf_report_timing_summary {} {
        redirect -tee ./reports/$::TASK_NAME/timing.summary {
            # report_timing_summary -views [get_db -u [concat [get_db analysis_views -if .is_setup] [get_db analysis_views -if .is_hold]] .name]
            report_timing_summary -groups reg2reg -expand_views
        }
    }

    # Create late timing reports
    proc gf_report_constraint_late {} {

        # Summary constraint reports
        report_constraint -drv_violation_type {max_transition max_capacitance max_fanout pulse_clock_max_transition} > ./reports/$::TASK_NAME/constraint.late.gba.rpt
        report_constraint -check_type {clock_period skew pulse_width pulse_clock_max_width} -verbose >> ./reports/$::TASK_NAME/constraint.late.gba.rpt
        gf_print_report_contraint_summary ./reports/$::TASK_NAME/constraint.late.gba.rpt "GBA late constraint violations:"
        
        # Violated summary
        report_constraint -drv_violation_type max_transition -all_violators > ./reports/$::TASK_NAME/constraint.late.gba.max_transition.violated.rpt
        report_constraint -drv_violation_type max_capacitance -all_violators > ./reports/$::TASK_NAME/constraint.late.gba.max_capacitance.violated.rpt
        report_constraint -drv_violation_type max_fanout -all_violators > ./reports/$::TASK_NAME/constraint.late.gba.max_fanout.violated.rpt
        report_constraint -drv_violation_type pulse_clock_max_transition -all_violators > ./reports/$::TASK_NAME/constraint.late.gba.pulse_clock_max_transition.violated.rpt
        report_constraint -check_type clock_period -all_violators > ./reports/$::TASK_NAME/constraint.late.gba.clock_period.violated.rpt
        report_constraint -check_type skew -all_violators > ./reports/$::TASK_NAME/constraint.late.gba.skew.violated.rpt
        report_constraint -check_type pulse_width -all_violators > ./reports/$::TASK_NAME/constraint.late.gba.pulse_width.violated.rpt
        report_constraint -check_type pulse_clock_max_width -all_violators > ./reports/$::TASK_NAME/constraint.late.gba.pulse_clock_max_width.violated.rpt
    }

    # Create late timing reports
    proc gf_report_timing_late {{count 150}} {

        # All timing reports
        report_timing -late -max_paths $count -path_type full_clock -split_delay > ./reports/$::TASK_NAME/timing.late.gba.all.tarpt
        report_timing -late -max_paths [expr $count*10] -max_slack 0.0 -path_type summary > ./reports/$::TASK_NAME/timing.late.gba.all.violated.tarpt
        puts "GBA late timing: [gf_print_report_timing_summary ./reports/$::TASK_NAME/timing.late.gba.all.violated.tarpt]"

        # Reports by path group
        catch { foreach group reg2reg {
            report_timing -late -max_paths $count -path_type full_clock -split_delay -group $group > ./reports/$::TASK_NAME/timing.late.gba.$group.tarpt
            report_timing -late -max_paths [expr $count*10] -max_slack 0.0 -path_type summary -group $group > ./reports/$::TASK_NAME/timing.late.gba.$group.violated.tarpt
            report_timing -late -max_paths $count -output_format gtd -group $group > ./reports/$::TASK_NAME/timing.late.gba.$group.mtarpt
        }}
        
        # Constraint violations
        report_constraint -late -drv_violation_type max_capacitance -all_violators > ./reports/$::TASK_NAME/drv.max.capacitance.all.rpt
        report_constraint -late -drv_violation_type max_transition -all_violators > ./reports/$::TASK_NAME/drv.max.transition.all.rpt

        # Reports by view
        catch { foreach group reg2reg {
            foreach view [get_db [get_db analysis_views -if .is_setup] .name] {
                report_timing -late -max_paths $count -path_type full_clock -split_delay -group $group -view $view > ./reports/$::TASK_NAME/timing.late.gba.$group.$view.tarpt
                puts "  [gf_print_report_timing_summary ./reports/$::TASK_NAME/timing.late.gba.$group.$view.tarpt] @ $group $view"
            }
        }}
        
        # DRV by 
        foreach view [get_db [get_db analysis_views -if .is_setup] .name] {
            report_constraint -late -drv_violation_type max_capacitance -all_violators -view $view > ./reports/$::TASK_NAME/drv.max.capacitance.$view.rpt
            report_constraint -late -drv_violation_type max_transition -all_violators -view $view > ./reports/$::TASK_NAME/drv.max.transition.$view.rpt
        }
    }

    # Report late PBA timing paths
    proc gf_report_timing_late_pba {{count 150}} {

        # Reports by path group
        catch { foreach group reg2reg {
            if {[get_db timing_analysis_aocv]} {
                report_timing -late -max_paths $count -path_type full_clock -split_delay -group $group -retime aocv_path_slew_propagation > ./reports/$::TASK_NAME/timing.late.pba.$group.tarpt
            } else {
                report_timing -late -max_paths $count -path_type full_clock -split_delay -group $group -retime path_slew_propagation > ./reports/$::TASK_NAME/timing.late.pba.$group.tarpt
            }
            puts "PBA late timing: [gf_print_report_timing_summary ./reports/$::TASK_NAME/timing.late.pba.$group.tarpt] @ $group"
         }}
    }

    # Create early timing reports
    proc gf_report_timing_early {{count 150}} {
    
        # All timing reports
        report_timing -early -max_paths $count -path_type full_clock -split_delay > ./reports/$::TASK_NAME/timing.early.gba.all.tarpt
        report_timing -early -max_paths [expr $count*10] -max_slack 0.0 -path_type summary > ./reports/$::TASK_NAME/timing.early.gba.all.violated.tarpt
        puts "GBA early timing: [gf_print_report_timing_summary ./reports/$::TASK_NAME/timing.early.gba.all.violated.tarpt]"

        # Reports by path group
        catch { foreach group reg2reg {
            report_timing -early -max_paths $count -path_type full_clock -split_delay -group $group > ./reports/$::TASK_NAME/timing.early.gba.$group.tarpt
            report_timing -early -max_paths [expr $count*10] -max_slack 0.0 -path_type summary -group $group > ./reports/$::TASK_NAME/timing.early.gba.$group.violated.tarpt
            report_timing -early -max_paths $count -output_format gtd -group $group > ./reports/$::TASK_NAME/timing.early.gba.$group.mtarpt
        }}
        
        # Constraint violations
        report_constraint -early -drv_violation_type min_capacitance -all_violators > ./reports/$::TASK_NAME/drv.min.capacitance.all.rpt
        report_constraint -early -drv_violation_type min_transition -all_violators > ./reports/$::TASK_NAME/drv.min.transition.all.rpt

        # Reports by view
        foreach view [get_db [get_db analysis_views -if .is_hold] .name] {
            catch { foreach group reg2reg {
                report_timing -early -max_paths $count -path_type full_clock -split_delay -group $group -view $view > ./reports/$::TASK_NAME/timing.early.gba.$group.$view.tarpt
                puts "  [gf_print_report_timing_summary ./reports/$::TASK_NAME/timing.early.gba.$group.$view.tarpt] @ $group $view"
            }}
            report_constraint -early -drv_violation_type min_capacitance -all_violators -view $view > ./reports/$::TASK_NAME/drv.min.capacitance.$view.rpt
            report_constraint -early -drv_violation_type min_transition -all_violators -view $view > ./reports/$::TASK_NAME/drv.min.transition.$view.rpt
        }
    }

    # Report early PBA timing paths
    proc gf_report_timing_early_pba {{count 150}} {
    
        # Reports by path group
        catch { foreach group reg2reg {
            if {[get_db timing_analysis_aocv]} {
                report_timing -early -max_paths $count -path_type full_clock -split_delay -group $group -retime aocv_path_slew_propagation > ./reports/$::TASK_NAME/timing.early.pba.$group.tarpt
            } else {
                report_timing -early -max_paths $count -path_type full_clock -split_delay -group $group -retime path_slew_propagation > ./reports/$::TASK_NAME/timing.early.pba.$group.tarpt
            }
            puts "PBA early timing: [gf_print_report_timing_summary ./reports/$::TASK_NAME/timing.early.pba.$group.tarpt] @ $group"
        }}
    }

    # Create early timing reports
    proc gf_report_constraint_early {} {

        # Summary constraint reports
        report_constraint -drv_violation_type {min_transition min_capacitance min_fanout pulse_clock_min_transition} > ./reports/$::TASK_NAME/constraint.early.gba.rpt
        report_constraint -check_type {pulse_clock_min_width} -verbose >> ./reports/$::TASK_NAME/constraint.early.gba.rpt
        gf_print_report_contraint_summary ./reports/$::TASK_NAME/constraint.early.gba.rpt "GBA early constraint violations:"
        
        # Violated summary
        report_constraint -drv_violation_type min_transition -all_violators > ./reports/$::TASK_NAME/constraint.early.gba.min_transition.violated.rpt
        report_constraint -drv_violation_type min_capacitance -all_violators > ./reports/$::TASK_NAME/constraint.early.gba.min_capacitance.violated.rpt
        report_constraint -drv_violation_type min_fanout -all_violators > ./reports/$::TASK_NAME/constraint.early.gba.min_fanout.violated.rpt
        report_constraint -drv_violation_type pulse_clock_min_transition -all_violators > ./reports/$::TASK_NAME/constraint.early.gba.pulse_clock_min_transition.violated.rpt
        report_constraint -check_type pulse_clock_min_width -all_violators > ./reports/$::TASK_NAME/constraint.early.gba.pulse_clock_min_width.violated.rpt
    }

'

################################################################################
# Data in/out steps
################################################################################

# Initialize design with Innovus inputs
gf_create_step -name tempus_init_innovus_db '
    `@innovus_procs_db`
    gf_globals_read $DATABASE
    
    set_db init_power_nets [gf_globals_get init_pwr_net]
    set_db init_ground_nets [gf_globals_get init_gnd_net]

    read_mmmc [gf_globals_get init_mmmc_file]
    read_physical -lefs [gf_globals_get init_lef_file]
    read_netlist -top [gf_globals_get init_top_cell] [gf_globals_get init_verilog]
    init_design

    if {[file exists $DATABASE/mmmc/timingderate.sdc]} {source $DATABASE/mmmc/timingderate.sdc}
    get_db analysis_views .name -u -foreach {
        update_analysis_view -name $object -latency_file $DATABASE/mmmc/views/$object/latency.sdc
    }
'

# Procedures to read in required data
gf_create_step -name procs_tempus_read_data '

    # Update latency constraints from given database
    proc gf_read_latency {database} {
        foreach analysis_view [get_db [get_db analysis_views -if {.is_setup||.is_hold}] .name] {
            set is_error 0
            set latency_file $database/mmmc/views/$analysis_view/latency.sdc
            puts "update_analysis_view -name $analysis_view -latency_file $latency_file"
            if {[file exists $latency_file]} {
                update_analysis_view -name $analysis_view -latency_file $latency_file
            } else {
                puts "**ERROR: Latency file $latency_file not found for analysis view $analysis_view"
            }
        }
    }
'

################################################################################
# ECO steps
################################################################################

gf_create_step -name begin_opt_signoff '
    # ECO index
    incr ECO_COUNT
    set_db opt_signoff_eco_file_prefix $ECO_COUNT
'

gf_create_step -name end_opt_signoff '
    # Cumulative ECO file
    exec grep -v -e route_eco ./${ECO_COUNT}_eco_innovus.tcl >> ./out/$TASK_NAME.eco_innovus.tcl
    exec cat ./${ECO_COUNT}_eco_tempus.tcl >> ./out/$TASK_NAME.eco_tempus.tcl
'

gf_create_step -name run_opt_signoff_setup '
    `@begin_opt_signoff`
    set_db opt_signoff_prefix ESOS
    opt_signoff -setup
    `@end_opt_signoff`
'

gf_create_step -name run_opt_signoff_hold '
    `@begin_opt_signoff`
    set_db opt_signoff_prefix ESOH
    opt_signoff -hold
    `@end_opt_signoff`
'

gf_create_step -name run_opt_signoff_drv '
    `@begin_opt_signoff`
    set_db opt_signoff_prefix ESOD
    opt_signoff -drv
    `@end_opt_signoff`
'

gf_create_step -name run_opt_signoff_leakage '
    `@begin_opt_signoff`
    set_db opt_signoff_prefix ESOL
    opt_signoff -leakage
    `@end_opt_signoff`
'

gf_create_step -name run_opt_signoff_power '
    `@begin_opt_signoff`
    set_db opt_signoff_prefix ESOP
    opt_signoff -power
    `@end_opt_signoff`
'

gf_create_step -name run_opt_signoff_area '
    `@begin_opt_signoff`
    set_db opt_signoff_prefix ESOA
    opt_signoff -area
    `@end_opt_signoff`
'
