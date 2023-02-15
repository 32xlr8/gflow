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
# File name: templates/project_template.cadence.2022/project.genus.gf
# Purpose:   Project-specific Genus configuration and flow steps
################################################################################

# Load tool plugin, tool and technology steps to use in GF scripts
gf_source "../../tools/tool_steps.stylus.gf"
gf_source "../../tools/gflow_plugin.genus.gf"
gf_source "../../tools/tool_steps.genus.gf"
gf_source "../../technology.genus.gf"

gf_info "Loading project-specific Genus steps ..."

# Tool initialization in Linux environment
gf_create_step -name init_genus_environment '
    export PATH="${PATH}:<PLACEHOLDER:/PATH_TO_GENUS/bin>"
'
