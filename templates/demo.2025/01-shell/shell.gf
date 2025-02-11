#!../../../bin/gflow

# Shell commands demo

# Task start
gf_create_task -name Command

# Task body
gf_set_task_command '
    tree ../..
    bash -i
'

# Task end
gf_submit_task
