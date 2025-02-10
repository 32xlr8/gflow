#!../../../bin/gflow

# Task start
gf_create_task -name Script

# Task body
gf_set_task_command "bash ./scripts/$TASK_NAME.sh"
gf_add_tool_commands -ext 'sh' '
    tree ../..
    bash -i
'

# Task end
gf_submit_task
