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
# Filename: templates/project_template.2023/blocks/block_template/block.common.gf
# Purpose:  Block-specific configuration and flow steps
################################################################################

gf_info "Loading block-specific setup ..."

################################################################################
# Flow options
################################################################################

# Default tasks resources
gf_set_task_options -cpu 8 -mem 20
gf_set_task_options 'Config*' -cpu 1 -mem 1 -local

# # Disable not needed tasks
# gf_set_task_options -disable ConfigFrontend
# gf_set_task_options -disable ConfigBackend
# gf_set_task_options -disable ConfigSignoff

################################################################################
# Flow variables
################################################################################

# Top cell name in netlist
DESIGN_NAME='<PLACEHOLDER>block_name'

# Global core nets
POWER_NETS_CORE='VDD'
GROUND_NETS_CORE='VSS'

# # Other global nets
# POWER_NETS_OTHER='<PLACEHOLDER>VDDA VDDPST'
# GROUND_NETS_OTHER='<PLACEHOLDER>VSSA VSSPST'

################################################################################
# MMMC configuration by design stage
################################################################################

# Common settings
gf_create_step -name gconfig_settings_common '

    ##################################################
    # Design-specific configuration  
    ##################################################

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
    #     -views {* * 1p100v * * *} {$pvt_v {HV}}
    #     -views {* * * m40 * *} {$pvt_t {neg40}}
    #     -views {* ss * * * *} {$pvt_rc {max}}
    #     -views {* tt *  25 * *} {$pvt {typical}}
    #     -views {* * * *   cb *} {$qrc {cbest}}
    #     -views {* * * * * s} {$check {late}}
    # }
'

# Synthesis settings
gf_create_step -name gconfig_settings_frontend '
    <PLACEHOLDER> Review frontend settings for synthesis
    
    # ------------------------
    # List of named scenarios:
    # ------------------------
    # - each scenario is {<scenario_name> {{analysis_view_1} {analysis_view_2} ...}}
    set TIMING_SETS {
        basic {
            {func ss 0p900v m40 cwt s}
        }
    }
    
    # --------------------------------------
    # Choose standard cell libraries to use:
    # --------------------------------------
    # - nldm_libraries - NLDM (Liberty) + CDB (Celtic) files used for fast runtime
    # - ecsm_libraries - ECSM (Liberty) + AOCV/SOCV files used for precise delay calculation
    # - ccs_libraries - CCS (Liberty) + AOCV/SOCV files used for precise delay calculation
    # - lvf_libraries - LVF (Liberty) files used for most precise delay calculation
    gconfig::enable_switches nldm_libraries
    # gconfig::enable_switches ecsm_libraries
    # gconfig::enable_switches ccs_libraries
    # gconfig::enable_switches lvf_libraries
    
    # ------------------------------------------------------------------------
    # Basic variation libraries to use (with ecsm_libraries or ccs_libraries):
    # ------------------------------------------------------------------------
    # - aocv_libraries - AOCV (advanced, SBOCV)
    # - socv_libraries - SOCV (statistical)
    # gconfig::enable_switches aocv_libraries
    # gconfig::enable_switches socv_libraries
   
    # -------------------------------------------
    # Derating scenarios - additional variations:
    # -------------------------------------------
    # - flat_derates - used with NLDM (see process node documentation)
    # - no_derates - zero derates (optimistic for prototyping mode)
    # - user_derates - same as flat_derates, but user-specified values used (customize below)
    # - vt_derates - used with ESCM/CCS if additional Voltage/Temparature derates required (see standard cell documentation, customize IR-drop below)
    gconfig::enable_switches flat_derates
    # gconfig::enable_switches no_derates
    # gconfig::enable_switches vt_derates
    # gconfig::enable_switches user_derates

    # # Set IR-drop value for voltage and temperature OCV derates (when vt_derate switch enabled)
    # # It is recommended to set 40% of Static IR for setup and 80% for hold
    # gconfig::add_section {
    #     -when vt_derates {
    #         -views {* * * * * s} {$voltage_drop <PLACEHOLDER>20}
    #         -views {* * * * * h} {$voltage_drop <PLACEHOLDER>40}
    #     }
    # }

    # # Set user-specific derate values (when user_derates switch enabled)
    # gconfig::add_section {
    #     -when user_derates {
    #         # -views {* tt * * * s} {$cell_data +10.0 $cell_early -10.0 $cell_late +10.0}
    #         # -views {* tt * * * h} {$cell_data -10.0 $cell_early -10.0 $cell_late +10.0}
    #         -views {* ss * * * s} {$cell_data +10.0 $cell_early -10.0 $cell_late +10.0}
    #         -views {* ss * * * h} {$cell_data -10.0 $cell_early -10.0 $cell_late +10.0}
    #         -views {* ff * * * h} {$cell_data -10.0 $cell_early -10.0 $cell_late +10.0}
    #     }
    # }
    
    # ------------------------------------------------------------------------------
    # Default uncertainty mode - reset all clocks uncertainty to recommended values:
    # ------------------------------------------------------------------------------
    # - default_uncertainty - use when SDC files do not contain set_clock_uncertainty commands
    # gconfig::enable_switches default_uncertainty
    #
    # # Set PLL jitter value in ps
    # gconfig::add_section {
    #     -when default_uncertainty {
    #         $jitter <PLACEHOLDER>25
    #     }
    # }
    
    # # Optional: set user-specific clock uncertainty values for all clocks
    # gconfig::add_section {
    #     -when default_uncertainty {
    #         -views {* ss 0p900v * * *} {$process_uncertainty 0 $setup_uncertainty <PLACEHOLDER>100 $hold_uncertainty <PLACEHOLDER>50}
    #         -views {* ff 1p100v * * *} {$process_uncertainty 0 $setup_uncertainty <PLACEHOLDER>100 $hold_uncertainty <PLACEHOLDER>50}
    #     }
    # }
'

# Implementation settings
gf_create_step -name gconfig_settings_backend '
    <PLACEHOLDER> Review backend settings for implementation
   
    # ------------------------
    # List of named scenarios:
    # ------------------------
    # - each scenario is {<scenario_name> {{analysis_view_1} {analysis_view_2} ...}}
    set TIMING_SETS {
        minimal {
            {func ss 0p900v m40 cwt s}
            {func ff 1p100v m40 cb h}
        }
        basic {
            {func ss 0p900v m40 rcwt s}
            {func ss 0p900v 125 cwt s}
            {func ff 1p100v m40 cw h}
            {func ff 1p100v 125 cb h}
        }
    }

    # --------------------------------------
    # Choose standard cell libraries to use:
    # --------------------------------------
    # - nldm_libraries - NLDM (Liberty) + CDB (Celtic) files used for fast runtime
    # - ecsm_libraries - ECSM (Liberty) + AOCV/SOCV files used for precise delay calculation
    # - ccs_libraries - CCS (Liberty) + AOCV/SOCV files used for precise delay calculation
    # - lvf_libraries - LVF (Liberty) files used for most precise delay calculation
    # gconfig::enable_switches nldm_libraries
    gconfig::enable_switches ecsm_libraries
    # gconfig::enable_switches ccs_libraries
    # gconfig::enable_switches lvf_libraries
    
    # ------------------------------------------------------------------------
    # Basic variation libraries to use (with ecsm_libraries or ccs_libraries):
    # ------------------------------------------------------------------------
    # - aocv_libraries - AOCV (advanced, SBOCV)
    # - socv_libraries - SOCV (statistical)
    gconfig::enable_switches aocv_libraries
    # gconfig::enable_switches socv_libraries
   
    # -------------------------------------------
    # Derating scenarios - additional variations:
    # -------------------------------------------
    # - flat_derates - used with NLDM (see process node documentation)
    # - no_derates - zero derates (optimistic for prototyping mode)
    # - user_derates - same as flat_derates, but user-specified values used (customize below)
    # - vt_derates - used with ESCM/CCS if additional Voltage/Temparature derates required (see standard cell documentation, customize IR-drop below)
    # gconfig::enable_switches flat_derates
    # gconfig::enable_switches no_derates
    gconfig::enable_switches vt_derates
    # gconfig::enable_switches user_derates

    # Set IR-drop value for voltage and temperature OCV derates (when vt_derate switch enabled)
    # It is recommended to set 40% of Static IR for setup and 80% for hold
    gconfig::add_section {
        -when vt_derates {
            -views {* * * * * s} {$voltage_drop <PLACEHOLDER>20}
            -views {* * * * * h} {$voltage_drop <PLACEHOLDER>40}
        }
    }

    # # Set user-specific derate values (when user_derates switch enabled)
    # gconfig::add_section {
    #     -when user_derates {
    #         # -views {* tt * * * s} {$cell_data +10.0 $cell_early -10.0 $cell_late +10.0}
    #         # -views {* tt * * * h} {$cell_data -10.0 $cell_early -10.0 $cell_late +10.0}
    #         -views {* ss * * * s} {$cell_data +10.0 $cell_early -10.0 $cell_late +10.0}
    #         -views {* ss * * * h} {$cell_data -10.0 $cell_early -10.0 $cell_late +10.0}
    #         -views {* ff * * * h} {$cell_data -10.0 $cell_early -10.0 $cell_late +10.0}
    #     }
    # }
    
    # ------------------------------------------------------------------------------
    # Default uncertainty mode - reset all clocks uncertainty to recommended values:
    # ------------------------------------------------------------------------------
    # - default_uncertainty - use when SDC files do not contain set_clock_uncertainty commands
    # gconfig::enable_switches default_uncertainty
    #
    # # Set PLL jitter value in ps
    # gconfig::add_section {
    #     -when default_uncertainty {
    #         $jitter <PLACEHOLDER>25
    #     }
    # }
    
    # # Optional: set user-specific clock uncertainty values for all clocks
    # gconfig::add_section {
    #     -when default_uncertainty {
    #         -views {* ss 0p900v * * *} {$process_uncertainty 0 $setup_uncertainty <PLACEHOLDER>100 $hold_uncertainty <PLACEHOLDER>50}
    #         -views {* ff 1p100v * * *} {$process_uncertainty 0 $setup_uncertainty <PLACEHOLDER>100 $hold_uncertainty <PLACEHOLDER>50}
    #     }
    # }
'

# Signoff settings
gf_create_step -name gconfig_settings_signoff '
    <PLACEHOLDER> Review signoff settings for timing and power analysis

    # ------------------------
    # List of named scenarios:
    # ------------------------
    # - each scenario is {<scenario_name> {{analysis_view_1} {analysis_view_2} ...}}
    set TIMING_SETS {
        recommended {
            {func tt 1p000v 85 ct s}
            {func tt 1p000v 85 ct h}

            {func ss 0p900v m40 cwt s} 
            {func ss 0p900v m40 rcwt s} 
            {func ss 0p900v 125 cwt s}
            {func ss 0p900v 125 rcwt s} 
            
            {func ss 0p900v m40 cw h} 
            {func ss 0p900v m40 rcw h} 
            {func ss 0p900v 125 cw h} 
            {func ss 0p900v 125 rcw h} 
            
            {func ff 1p100v m40 cb h} 
            {func ff 1p100v m40 cw h} 
            {func ff 1p100v 0 cb h} 
            {func ff 1p100v 0 cw h} 
            {func ff 1p100v 125 cb h} 
            {func ff 1p100v 125 cw h} 
            
            {func ff 1p100v m40 rcb h} 
            {func ff 1p100v m40 rcw h} 
            {func ff 1p100v 125 rcb h} 
            {func ff 1p100v 125 rcw h}
            
            {func ff 1p100v 0 rcb h} 
            {func ff 1p100v 0 rcw h}
        }
        basic {
            {func ss 0p900v m40 cwt s} 
            {func ss 0p900v 125 cwt s}
            
            {func ss 0p900v m40 cw h} 
            {func ss 0p900v 125 cw h} 
            
            {func ff 1p100v m40 cb h} 
            {func ff 1p100v m40 cw h} 
            {func ff 1p100v 0 cb h} 
            {func ff 1p100v 0 cw h} 
            {func ff 1p100v 125 cb h} 
            {func ff 1p100v 125 cw h} 
        }
    }
    
    # -------------------------
    # Power analysis scenarios:
    # -------------------------
    # - each scenario is {<scenario_name> {view_type {analysis_view} ...}}
    #   - PGV_SPEF_CORNER - PGV generation extraction corner
    #   - SIGNAL_SPEF_CORNER - Signal nets extraction corner
    #   - POWER_SPEF_CORNER - Power grid extraction corner
    #   - STATIC_POWER_VIEW - Static power analysis view
    #   - DINAMIC_POWER_VIEW - Dynamic power analysis view
    #   - STATIC_RAIL_VIEW - Static rail analysis view
    #   - DINAMIC_RAIL_VIEW - Dynamic rail analysis view
    #   - SIGNAL_EM_VIEW - Signal electromigration analysis view
    set POWER_SETS {
        basic {
            PGV_SPEF_CORNER {* * * 125 rcw *}
            SIGNAL_SPEF_CORNER {* * * m40 rcb *}
            POWER_SPEF_CORNER {* * * 125 cw *}
            
            STATIC_POWER_VIEW {func ff 1p100v 125 cw h}
            DINAMIC_POWER_VIEW {func ff 1p100v 125 cw h}
            
            STATIC_RAIL_VIEW {func ss 0p900v 125 rcw h}
            DINAMIC_RAIL_VIEW {func ss 0p900v 125 rcw h}

            SIGNAL_EM_VIEW {func ff 1p100v 125 cw h}
        }
    }
    
    # --------------------------------------
    # Choose standard cell libraries to use:
    # --------------------------------------
    # - nldm_libraries - NLDM (Liberty) + CDB (Celtic) files used for fast runtime
    # - ecsm_libraries - ECSM (Liberty) + AOCV/SOCV files used for precise delay calculation
    # - ccs_libraries - CCS (Liberty) + AOCV/SOCV files used for precise delay calculation
    # - lvf_libraries - LVF (Liberty) files used for most precise delay calculation
    # gconfig::enable_switches nldm_libraries
    gconfig::enable_switches ecsm_libraries
    # gconfig::enable_switches ccs_libraries
    # gconfig::enable_switches lvf_libraries
    
    # ------------------------------------------------------------------------
    # Basic variation libraries to use (with ecsm_libraries or ccs_libraries):
    # ------------------------------------------------------------------------
    # - aocv_libraries - AOCV (advanced, SBOCV)
    # - socv_libraries - SOCV (statistical)
    gconfig::enable_switches aocv_libraries
    # gconfig::enable_switches socv_libraries
   
    # -------------------------------------------
    # Derating scenarios - additional variations:
    # -------------------------------------------
    # - flat_derates - used with NLDM (see process node documentation)
    # - no_derates - zero derates (optimistic for prototyping mode)
    # - user_derates - same as flat_derates, but user-specified values used (customize below)
    # - vt_derates - used with ESCM/CCS if additional Voltage/Temparature derates required (see standard cell documentation, customize IR-drop below)
    # gconfig::enable_switches flat_derates
    # gconfig::enable_switches no_derates
    gconfig::enable_switches vt_derates
    # gconfig::enable_switches user_derates

    # Set IR-drop value for voltage and temperature OCV derates (when vt_derate switch enabled)
    # It is recommended to set 40% of Static IR for setup and 80% for hold
    gconfig::add_section {
        -when vt_derates {
            -views {* * * * * s} {$voltage_drop <PLACEHOLDER>20}
            -views {* * * * * h} {$voltage_drop <PLACEHOLDER>40}
        }
    }

    # # Set user-specific derate values (when user_derates switch enabled)
    # gconfig::add_section {
    #     -when user_derates {
    #         # -views {* tt * * * s} {$cell_data +10.0 $cell_early -10.0 $cell_late +10.0}
    #         # -views {* tt * * * h} {$cell_data -10.0 $cell_early -10.0 $cell_late +10.0}
    #         -views {* ss * * * s} {$cell_data +10.0 $cell_early -10.0 $cell_late +10.0}
    #         -views {* ss * * * h} {$cell_data -10.0 $cell_early -10.0 $cell_late +10.0}
    #         -views {* ff * * * h} {$cell_data -10.0 $cell_early -10.0 $cell_late +10.0}
    #     }
    # }
    
    # ------------------------------------------------------------------------------
    # Default uncertainty mode - reset all clocks uncertainty to recommended values:
    # ------------------------------------------------------------------------------
    # - default_uncertainty - use when SDC files do not contain set_clock_uncertainty commands
    # gconfig::enable_switches default_uncertainty
    #
    # # Set PLL jitter value in ps
    # gconfig::add_section {
    #     -when default_uncertainty {
    #         $jitter <PLACEHOLDER>25
    #     }
    # }
    
    # # Optional: set user-specific clock uncertainty values for all clocks
    # gconfig::add_section {
    #     -when default_uncertainty {
    #         -views {* ss 0p900v * * *} {$process_uncertainty 0 $setup_uncertainty <PLACEHOLDER>100 $hold_uncertainty <PLACEHOLDER>50}
    #         -views {* ff 1p100v * * *} {$process_uncertainty 0 $setup_uncertainty <PLACEHOLDER>100 $hold_uncertainty <PLACEHOLDER>50}
    #     }
    # }
'
