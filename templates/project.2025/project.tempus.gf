################################################################################
# Generic Flow v5.5.1 (February 2025)
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
# Filename: templates/project.2025/project.tempus.gf
# Purpose:  Project-specific Tempus configuration and flow steps
################################################################################

# Load tool plugin, tool and technology steps to use in GF scripts
gf_source -once "../../tools/tool_steps.stylus.gf"
gf_source -once "../../tools/gflow_plugin.tempus.gf"
gf_source -once "../../tools/tool_steps.tempus.gf"

gf_info "Loading project-specific Tempus steps ..."

# Tool initialization in Linux environment
gf_create_step -name init_tempus_environment '

    # # Manually override OpenAccess lib platform
    # export OA_UNSUPPORTED_PLAT=linux_rhel60

    # Add path the directory with tool binaries
    <PLACEHOLDER>
    export CDS_STYLUS_SOURCE_VERBOSE=1
    export PATH="${PATH}:/PATH_TO_SSV/bin"

    # # Path to the libraries in case they are missing in Linux
    # export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:/PATH_TO_SSV/tools/lib64"
    # export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:/PATH_TO_SSV/tools/lib"
'

# Project-specific tool environment
gf_create_step -name tempus_post_init_design_project '
    
    # Process related settings
    set_db design_process_node <PLACEHOLDER>
'
