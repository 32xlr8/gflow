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
# Filename: templates/tools_template.2023/tool_steps.genus.gf
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
