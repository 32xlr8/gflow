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
# Filename: templates/project.2025/blocks/template/data/uncertainty.ff.sdc
################################################################################

# Corner-specific margins

# Primary clocks uncertainty
set_clock_uncertainty -setup 0.050 [get_clocks "fast_clk"]
set_clock_uncertainty -hold 0.025 [get_clocks "fast_clk"]

# # Secondary clocks uncertainty
# set_clock_uncertainty -setup 0.050 [get_clocks "slow_clk"]
# set_clock_uncertainty -hold 0.025 [get_clocks "slow_clk"]
