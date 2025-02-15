#!../../../bin/gflow

# Generic Config MMMC generation demo

# Flow steps to paste
gf_source steps.gf

# MMMC configuration task
gf_create_task -name MMMC
gf_set_task_command "tclsh ./scripts/$TASK_NAME.tcl; read"

# TCL script
gf_add_tool_commands -comment '#' -ext 'tcl' '

    # Initialize gconfig toolkit
    source ../../../../../../bin/gconfig.tcl

    `@init_gconfig_mmmc`
    `@init_variables`
    `@init_files`

    # Dump MMMC file
    gconfig::get_mmmc_commands -dump_to_file ./mmmc.tcl -views {
        {func ss 720mv m40 cw s}
        {func ff 880mv 125 cb h}
    }
    puts \n[exec cat ./mmmc.tcl]
'

# End task
gf_submit_task
