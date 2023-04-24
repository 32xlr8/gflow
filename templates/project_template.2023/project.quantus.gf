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
# Filename: templates/project_template.2023/project.quantus.gf
# Purpose:  Project-specific Quantus configuration and flow steps
################################################################################

# Load tool plugin, tool and technology steps to use in GF scripts
gf_source -once "../../tools/gflow_plugin.quantus.gf"
gf_source -once "../../tools/tool_steps.quantus.gf"

gf_info "Loading project-specific Quantus steps ..."

# Tool initialization in Linux environment
gf_create_step -name init_quantus_environment '
    
    # # Manually override OpenAccess lib platform
    # export OA_UNSUPPORTED_PLAT=linux_rhel60

    # Add path the directory with tool binaries
    export PATH="${PATH}:<PLACEHOLDER>/PATH_TO_EXT/bin"

    # # Path to the libraries in case they are missing in Linux
    # export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:<PLACEHOLDER>/PATH_TO_EXT/tools/lib64"
    # export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:<PLACEHOLDER>/PATH_TO_EXT/tools/lib"
'

# Project-specific tool environment
gf_create_step -name quantus_pre_init_design_project '

    # Cross-coupling mode required for SI
    extract \
        -selection all \
        -type rc_coupled

    # Filtering options
    filter_coupling_cap \
        -total_cap_threshold 0.0 \
        -coupling_cap_threshold_absolute 0.1 \
        -coupling_cap_threshold_relative 1.0 \
        -cap_filtering_mode absolute_and_relative

    # Parasitics reduction
    parasitic_reduction -enable_reduction false
    
    # Process scale factor
    extraction_setup \
        -layout_scale <PLACEHOLDER>1.0

    extraction_setup \
        -promote_pin_pad logical
'
