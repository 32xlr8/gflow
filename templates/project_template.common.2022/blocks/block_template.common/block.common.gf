################################################################################
# Generic Flow v5.0 (February 2023)
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
# File name: templates/project_template.common.2022/blocks/block_template.common/block.common.gf
# Purpose:   Block-specific configuration and flow steps
################################################################################

gf_info "Loading block-specific setup ..."

################################################################################
# Flow variables
################################################################################

# Default tasks resources
gf_set_task_options -cpu 8 -mem 20
gf_set_task_options 'Debug*' -cpu 4 -mem 10 -parallel 1

################################################################################
# Design variables
################################################################################

# Top cell name in netlist
DESIGN_NAME='<PLACEHOLDER:block_name>'

# Global core nets
POWER_NETS_CORE='VDD'
GROUND_NETS_CORE='VSS'

# # Global IO nets
# POWER_NETS_IO='<PLACEHOLDER:VDDA VDDPST>'
# GROUND_NETS_IO='<PLACEHOLDER:VSSA VSSPST>'

################################################################################
# Design configuration steps
################################################################################

# Initialize block-specific settings
gf_create_step -name gconfig_design_settings '

    ##################################################
    # Block configuration  
    ##################################################

    # Choose OCV libraries to use
    <PLACEHOLDER: Please enable one of following switches in case AOCV or SOCV library set files used>
    # gconfig::enable_switches aocv_libraries
    # gconfig::enable_switches socv_libraries
   
    # # IO voltage variants to use in file name patterns
    # gconfig::add_section {
    #     -views {* ss 0p900v * * *} {$pvt_v {0p9v1p62v 0p9v1p62v1p62v}}
    #     -views {* tt 1p000v * * *} {$pvt_v {1v1p8v 1v1p8v1p8v}}
    #     -views {* ff 1p100v * * *} {$pvt_v {1p1v1p98v 1p1v1p98v1p98v}}
    # }

    # # Other design-specific variable variants to use in file name patterns
    # gconfig::add_section {
    #     -views {test * * * * *} {$mode test}
    #     -views {* tt * * * *} {$pvt_p {typ}}
    #     -views {* * 1p210v * * *} {$pvt_v {HV}}
    #     -views {* * * m40 * *} {$pvt_t {neg40}}
    #     -views {* ss * * * *} {$pvt_e {max}}
    #     -views {* tt *  25 * *} {$pvt {typical}}
    #     -views {* * * *   cb *} {$qrc {cbest}}
    #     -views {* * * * * s} {$check {late}}
    # }

    # Choose derates scenario:
    #   no_derates - disable all set_timing_derate commands
    #   flat_derates - defined in ../../technology.ocv.gf
    #   vt_derates - IR-drop aware derates defined in ../../technology.ocv.gf
    #   user_derates - flat user derates defined below
    <PLACEHOLDER: Please choose one of derates scenarios>
    # gconfig::enable_switches no_derates
    # gconfig::enable_switches flat_derates
    # gconfig::enable_switches vt_derates
    # gconfig::enable_switches user_derates

    # # Set IR-drop value for voltage and temperature OCV derates (when vt_derate switch enabled)
    # # It is recommended to set 40% of Static IR for setup and 80% for hold
    # gconfig::add_section {
    #     -when vt_derates {
    #         -views {* * * * * s} {$voltage_drop <PLACEHOLDER:20>}
    #         -views {* * * * * h} {$voltage_drop <PLACEHOLDER:40>}
    #     }
    # }

    # # Set user-specific derate values (when user_derates switch enabled)
    # gconfig::add_section {
    #     -when user_derates {
    #         # -views {* tt 0p000v * * s} {$cell_data +0.0 $cell_early -0.0 $cell_late +0.0}
    #         # -views {* tt 0p000v * * h} {$cell_data -0.0 $cell_early -0.0 $cell_late +0.0}
    #         -views {* ss 0p000v * * s} {$cell_data +0.0 $cell_early -0.0 $cell_late +0.0}
    #         -views {* ss 0p000v * * h} {$cell_data -0.0 $cell_early -0.0 $cell_late +0.0}
    #         -views {* ff 0p000v * * h} {$cell_data -0.0 $cell_early -0.0 $cell_late +0.0}
    #     }
    # }
    
    # Default uncertainty mode - reset all clocks uncertainty to recommended values
    <PLACEHOLDER> gconfig::enable_switches default_uncertainty

    # # Set PLL jitter value in ps (when default_uncertainty switch enabled)
    # gconfig::add_section {
    #     -when default_uncertainty {
    #         $jitter <PLACEHOLDER:25>
    #     }
    # }
    
    # # Optional: set user-specific clock uncertainty values for all clocks (when default_uncertainty switch enabled)
    # gconfig::add_section {
    #     -when default_uncertainty {
    #         -views {* ss 0p900v * * *} {$process_uncertainty 0 $setup_uncertainty <PLACEHOLDER:100> $hold_uncertainty <PLACEHOLDER:50>}
    #         -views {* ff 1p100v * * *} {$process_uncertainty 0 $setup_uncertainty <PLACEHOLDER:100> $hold_uncertainty <PLACEHOLDER:50>}
    #     }
    # }
    
    # Show all defined and active switches
    gconfig::show_switches

'
