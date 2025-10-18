################################################################################
# Generic Flow v5.5.3 (October 2025)
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
# Filename: templates/project.2025/blocks/template/data/func.sdc
# Purpose:  Functional constraints
################################################################################

##################################################
# Clocks
##################################################

# Primary clocks
set period_fast_clk 1.000
create_clock -period $period_fast_clk -name fast_clk [get_ports "fast_clk"]

# # Secondary clocks
# set period_slow_clk 10.000
# create_clock -period $period_slow_clk -name slow_clk [get_ports "slow_clk"]

##################################################
# Clocks exceptions
##################################################

# # Primary and secondary clocks relationship
# set_clock_groups -asynchronous -group [get_clocks "fast_clk"] -group [get_clocks "slow_clk"]
# set_clock_groups -logically_exclusive -group [get_clocks "fast_clk"] -group [get_clocks "slow_clk"]
# set_clock_groups -physically_exclusive -group [get_clocks "fast_clk"] -group [get_clocks "slow_clk"]

# # Async FIFO between primary and secondary clocks
# set_clock_groups -asynchronous -allowpaths -group [get_clocks "fast_clk"] -group [get_clocks "slow_clk"]
# set_max_delay 1.000 -from [get_clocks "fast_clk"] -to [get_clocks "slow_clk"]
# set_max_delay 1.000 -to [get_clocks "fast_clk"] -from [get_clocks "slow_clk"]
# set_min_delay 0.000 -from [get_clocks "fast_clk"] -to [get_clocks "slow_clk"]
# set_min_delay 0.000 -to [get_clocks "fast_clk"] -from [get_clocks "slow_clk"]

##################################################
# I/O
##################################################

# Clock ports
set clock_ports [get_ports "fast_clk slow_clk"]

# Primary data ports
set ports_fast_clk [remove_from_collection [get_ports "*"] $clock_ports]
set_input_delay [expr 0.40*$period_fast_clk] -clock fast_clk [remove_from_collection $ports_fast_clk [all_outputs]]
set_output_delay [expr 0.40*$period_fast_clk] -clock fast_clk [remove_from_collection $ports_fast_clk [all_inputs]]

# # Secondary data ports
# set ports_slow_clk [remove_from_collection [get_ports "*"] $clock_ports]
# set_input_delay [expr 0.40*$period_slow_clk] -clock slow_clk [remove_from_collection $ports_slow_clk [all_outputs]]
# set_output_delay [expr 0.40*$period_slow_clk] -clock slow_clk [remove_from_collection $ports_slow_clk [all_inputs]]

##################################################
# Path exceptions
##################################################

# # Case analysis
# set_case_analysis 0 [get_ports "PATTERN"]

# # False paths
# set_false_path -from [get_ports "PATTERN"]
# set_false_path -from [get_pins "PATTERN"] -to [get_pins "PATTERN"]

# # Multi-cycle paths
# set_multi_cycle_path 2 -setup -from [get_pins "PATTERN"]
# set_multi_cycle_path 1 -hold -from [get_pins "PATTERN"]
