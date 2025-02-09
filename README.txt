Generic Flow is a tool which allows to generate and run Linux scripts.

Following functionality included:
- Bash-based *.gf script
- Task scheduling and dependencies
- Automatic directory structure
- Automatic snapshots of *.gf scripts when running the flow

This directory contains scripts providing Generic Flow and Config functionality.

Main Generic Flow tool to execute GF scripts is ./bin/gflow.
For more info please run:
    ./bin/gflow -help

Main Generic Config tool to source in any TCL-based shell is ./bin/gconfig.tcl.
For more info please run it in any TCL-based shell:
    source ./bin/gconfig.tcl

Additional utilities can be interpreted as a gift scripts
    ./bin/disk_usage provides disk usage statistics
    ./bin/relink_files - Utility to repair broken symlinks and relink identical files
    ./bin/search_files - Utility to search files on disk and repair file paths in custom scripts
    ./bin/search_cells - Utility to search LIB/LEF/GDS/AOCV files containing specific cells
    ./bin/trace_timing.tcl - Trace timing utility to debug timing chains

Directory structure:
    ./gflow
    |-- bin
    |   | gflow
    |   | gconfig.tcl
    |   | disk_usage
    |   | relink_files
    |   | search_files
    |   | search_cells
    |   ` trace_timing.tcl
    `-- templates
        | ./project.*
        |   ` ...
        ` ./demo.*
            ` ...

To start please follow steps discribed in ./templates/project.*/dir.info.
