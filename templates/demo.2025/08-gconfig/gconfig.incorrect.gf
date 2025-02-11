#!../../../bin/gflow

# Generic Config MMMC generation demo - errors debug

# Flow steps to paste
gf_source steps.gf

# MMMC configuration task
gf_create_task -name MMMC
gf_set_task_command "tclsh ./scripts/$TASK_NAME.tcl; bash -i"

# TCL script
gf_add_tool_commands -comment '#' -ext 'tcl' '

    # Initialize gconfig toolkit
    source ../../../../../../bin/gconfig.tcl

    `@init_gconfig_mmmc`
    `@init_variables`
    `@init_files`

    # Incorrect view combination
    gconfig::get_mmmc_commands -views {
        {func ss 720mv m40 cw s}
        {func ff 720mv 125 cb h}
    }
'

# End task
gf_submit_task
