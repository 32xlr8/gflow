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
# Filename: templates/project.2025/tools/tool_steps.tempus.gf
# Purpose:  Tempus steps to use in the Generic Flow
################################################################################

gf_info "Loading tool-specific Tempus steps ..."

################################################################################
# Report timing steps for Tempus
################################################################################

# Parse timing reports
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
