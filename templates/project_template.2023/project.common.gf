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
# Filename: templates/project_template.2023/project.common.gf
# Purpose:  Project-specific configuration and flow steps
################################################################################

gf_info "Loading project-specific setup ..."

########################################
# Generic Flow command line options
########################################

# Run in user-specific `
gf_set_flow_options -dir ./work_$USER

# Use new run directory name every day
gf_set_flow_options -today

# # Run tasks in SGE mode
# gf_set_flow_options -sge -sge_options '-q all.q -pe servers ${GF_TASK_CPU} -l mem=${GF_TASK_MEM}G,arch=lx24-amd64,os_rel=RH7'
# gf_set_flow_options -sge

# # Run tasks in LSF mode
# gf_set_flow_options -lsf -lsf_options '-n ${GF_TASK_CPU} -R rusage[mem=${GF_TASK_MEM}000]'
# gf_set_flow_options -lsf

# # Raise main window when done
# gf_set_flow_options -raise

# # Use TrueType font
# gf_set_flow_options -smooth

# # Verbose logs of failed tasks
# gf_set_flow_options -verbose

# # Control access for new files
# umask u=rwx,g=rwx,o-rwx
    
########################################
# Linux environment initialization
########################################

# Use bash as the main shell
export SHELL=/bin/bash

# Commands to initialize shell environment (bash)
gf_create_step -name init_shell_environment '

    # Remove tool paths from path environment
    export PATH="$(echo ":$PATH" | sed -e "s|:<PLACEHOLDER>/PATH_TO/SOFT/ROOT/[^:]\+||g; s/^://;")"

    # Bypass OpenAccess issues
    unset OA_HOME

    # License options
    # export CDS_LIC_ONLY=1
    # export CDS_LIC_FILE=5280@<PLACEHOLDER>lic_server1:5280@<PLACEHOLDER>lic_server2
    export LM_LICENSE_FILE=5280@<PLACEHOLDER>lic_server1:5280@<PLACEHOLDER>lic_server2

    # Startup options
    export CDS_AUTO_32BIT=NONE
    export CDS_AUTO_64BIT=ALL
    export CDS_STYLUS_SOURCE_VERBOSE=0

    # # Fast temporary directory in RAM (use if total memory is more than 512Gb)
    # if [ -d "$XDG_RUNTIME_DIR" ]; then
    #     export TMPDIR="$XDG_RUNTIME_DIR/tmp"
    #     mkdir -p "$TMPDIR"
    # fi

    # # Slow temporary directory in project area
    # export TMPDIR="."
    # # mkdir -p "$TMPDIR"

    # Remove command line stack limit
    ulimit -s unlimited
'

################################################################################
# Load flow tool, technology and project settings
################################################################################

# Load Stylus and Generic Config flow steps
gf_source "../../tools/tool_steps.gconfig.gf"

# Load technology-specific flow steps
gf_source "../../technology.common.gf"

################################################################################
# Tool, technology and project configuration step
################################################################################

# Technology-specific configuration
gf_create_step -name init_gconfig '
    
    # Initialize Generic Config 
    source "../../../../../../gflow/bin/gconfig.tcl"

    # Load MMMC procedures
    `@init_gconfig_mmmc`
'
