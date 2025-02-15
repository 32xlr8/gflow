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
# Filename: templates/project.2025/README.txt
################################################################################

To start new project please create new directory to be used as project root (ex. /projects/my_project_name/digital).
Step 1. Create project root: mkdir /projects/my_project_name/digital/
Step 2. Change directory: cd /projects/my_project_name/digital/
Step 3. Clone Generic Flow: git clone http://github.com/32xlr8/gflow
Step 4. Copy project template: cp -vR ./gflow/templates/project.2025/* .
Step 5. Customize project-specific files: 
  - Replace all placeholders (<PLACEHOLDER>) and uncomment required lines and provide paths to standard cell libraries files
  - nedit project.*.gf
Step 6. Create new block: mkdir ./blocks/my_block
Step 7. Copy block-specific settings: cp ./blocks/template/block.common.gf ./blocks/my_block/
Step 7. Copy block-specific tool configuration files: cp ./blocks/template/block.$TOOL.gf ./blocks/my_block/
Step 5. Customize block-specific files: 
- Replace all placeholders (<PLACEHOLDER>), uncomment required lines and provide paths to macro files
- nedit ./blocks/my_block/block.*.gf

Check flows in following sequence:
cd ./blocks/my_block/
../block_template/genus.fe.gf
../block_template/genus.gui.gf
../block_template/innovus.fp.gf
../block_template/innovus.be.gf
../block_template/innovus.gui.gf
../block_template/innovus.*.gf
../block_template/calibre.dummy.gf
../block_template/calibre.drc.gf
../block_template/calibre.lvs.gf
../block_template/calibre.gui.gf
../block_template/calibre.*.gf
../block_template/quantus.out.gf
../block_template/quantus.out.split.gf
../block_template/tempus.tso.gf
../block_template/tempus.gui.gf
../block_template/tempus.sta.gf
../block_template/tempus.sta.split.pvt.gf
../block_template/tempus.sta.split.views.gf
../block_template/tempus.out.gf
../block_template/tempus.out.split.pvt.gf
../block_template/tempus.out.split.views.gf
../block_template/voltus.pgv.gf
../block_template/voltus.static.gf
../block_template/voltus.dynamic.gf
../block_template/voltus.sem.gf
../block_template/voltus.gui.gf

Digital project directory structure:

./project
| ./gflow
|   ` ...
| ./tools
|   | gflow_plugin.gconfig.gf
|   | tool_steps.gconfig.gf
|   | gflow_plugin.${TOOL}.gf
|   | tool_steps.${TOOL}.gf
|   ` ...
| project.common.gf
| project.gconfig.gf
| project.$TOOL.gf
| ...
| ./blocks
|   | ./template
|   |   | block.common.gf
|   |   | block.$TOOL.gf
|   |   ` ...
|   | ./$BLOCK
|   |   | block.common.gf
|   |   | block.$TOOL.gf
|   |   ` ...
|   ` ...
` ...

./project directory is project root directory specified by user and used to store project-specific Generic Flow steps and settings.
./project/tools directory stores tool-specific Generic Flow plugins and flow steps.
./project/blocks/$BLOCK directory stores block-specific Generic Flow settings and flow steps.

Plugin is an initization script that tells Generic Flow what command to run, where to store tool script, success/failed marks, multi-cpu options.
Typically contains gf_use_${TOOL} bash function to use in GF scripts.

Tool step is a part of the code written in the tool language to be pasted into the final tool script using `@$STEP` construction.
From Generic Flow it can be considered as a portion of the plain text.

Special ./tools/*.gconfig.gf scripts contain additional TCL procedures which allow to generate MMMC/OCV configuration using Generic Config tool.
Contains command aliases to make process of configuration easier:
    gconfig::add_files lef {...}
    gconfig::add_files lib -views {...}
    gconfig::get_mmmc_commands -views {...}
    gconfig::get_ocv_commands -views {...}

Project setup file for Generic Flow is project.common.gf.
It contains GF shell environment settings, path to the tools and basic command line options, file paths to all project-related data supposed to be reused by different blocks of current project.

Project-specific flow steps located in project.$TOOL.gf files and grouped by tool.

Block setup file for Generic Flow is ./project/blocks/$BLOCK/block.common.gf.
It contains GF shell block settings, flow steps and paths to block-specific files.

Block-specific flow steps located in ./project/blocks/$BLOCK/block.$TOOL.gf files and grouped by tool.

Block-specific data to be stored in ./project/blocks/$BLOCK/data directory.
Typically contains RTL, netlists, floorplans, constraints, golden databases and other data.

Special ./blocks/template directory contains reference flows and configuration templates as a start point.

Generic Flow scripts describing flows are stored in ./project/blocks/$BLOCK/$FLOW.gf.
Each file describes it's own flow and can be executed from flows/ or workarea/ block directory.
Gift flows are:
    check.gf - verify project configuration, including all files desribed in Generic Config.
    find.gf - look for block-specific files on disk based on the netlist given in block.common.gf.
    fp.gf - interactive floorplanning with available gf_* special procedures out of the box.
    innovus.be.gf - implementation in Innovus from netlist to gds.
    timing.gf - timing analysis and ECO of Innovus database in Tempus.
    power.gf - power analysis of Innovus database in Voltus.
    physical.gf - physical verification of Innovus database in Pegasus.
    debug.$TOOL.gf - debugging results.

Working directory ./project/blocks/$BLOCK/work_$USER used to store all flow runs data by user.

./project/blocks/$BLOCK/work_$USER
| $FLOW.$DATE
|   | ./in
|   |   `-- ...
|   | ./out
|   |   `-- ...
|   | ./reports
|   |   `-- ...
|   | ./tasks
|   |   | ./$TASK
|   |   |   | ./in -> ../../in
|   |   |   | ./out -> ../../out
|   |   |   | ./scripts -> ../../scripts
|   |   |   | ./logs -> ../../logs
|   |   |   | ./reports -> ../../reports
|   |   |   | start.sh
|   |   |   | run
|   |   |   ` ...
|   |   `-- ...
|   | ./logs
|   |   | $TASK.log
|   |   | run.$INDEX.log
|   |   ` ...
|   | ./scripts
|   |   | $TASK.script
|   |   | $FLOW.$INDEX.gf
|   |   | $FLOW.sources.$INDEX.gf
|   |   `-- ...
|   |-- run.1.sh
|   |-- run.info
|   |-- run.log
|   |-- show_log.sh
|   |-- submit.$TASK.sh
|   |-- $FLOW.$INDEX.gf -> ./scripts/$FLOW.$INDEX.gf
|   |-- $FLOW.sources.$INDEX.gf -> ./scripts/$FLOW.sources.$INDEX.gf
|   `-- ...
`-- ...

Every flow creates it's own run directory $FLOW.$DATE under working directory.
Generic Flow log to debug internal issues is $FLOW.$DATE/run.log.

Every task of the flow will be executed in separate ./tasks/$TASK subdirectory under run directory.
All non-absolute file paths in task commands should be defined relative to ./project/blocks/$BLOCK/work_$USER/$FLOW.$DATE/tasks/$TASK.
Generic Flow automatically starts ./tasks/$TASK/start.sh with logging. The main task shell script is ./tasks/$TASK/run.

Main flow window log stored in ./logs/run.$INDEX.log, variable $INDEX is an unique run number.
Generic Flow automatically creates full log for every task and stores it in ./logs/$TASK.log under run directory.

Generic Flow also automatically creates plain script for every task and stores it in ./scripts/$TASK.* under run directory.
Copy of initial flow script stored in ./scripts/$FLOW.$INDEX.gf under run directory.
Content of every sourced file of flow script stored in ./scripts/$FLOW.sources.$INDEX.gf under run directory.
Links to the latest run scripts are $FLOW.$INDEX.gf and $FLOW.sources.$INDEX.gf.

Optional directories to organize project-based file storage:

./project
| ./data
|   ` ...
| ./xfer
|   ` ...
` ./blocks
    ` ./$BLOCK
        ` ./data
            ` ...

./data directory supposed to to store project-specific data and controlled by project lead.
./xfer directory supposed to store transferred external data and controlled by data administrator.
./blocks/$BLOCK/data supposed to store local blocks data and controlled by block owner.
