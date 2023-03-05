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
# Filename: templates/project_template.2023/project.voltus.gf
# Purpose:  Project-specific Voltus configuration and flow steps
################################################################################

# Load tool plugin, tool and technology steps to use in GF scripts
gf_source "../../tools/tool_steps.stylus.gf"
gf_source "../../tools/gflow_plugin.voltus.gf"
gf_source "../../tools/tool_steps.voltus.gf"
gf_source "../../technology.voltus.gf"

gf_info "Loading project-specific Voltus steps ..."

# Tool initialization in Linux environment
gf_create_step -name init_voltus_environment '

    # # Manually override OpenAccess lib platform
    # export OA_UNSUPPORTED_PLAT=linux_rhel60

    # Add path the directory with tool binaries
    export PATH="${PATH}:<PLACEHOLDER:/PATH_TO_SSV/bin>"
'
