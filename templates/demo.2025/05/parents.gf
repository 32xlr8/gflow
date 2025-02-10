#!../../../bin/gflow

# Root task
gf_create_task -name Root
gf_set_task_command "echo This is $TASK_NAME task; read"
gf_submit_task

# Parallel task 1
gf_create_task -name Mother
gf_wait_task Root
gf_set_task_command "echo This is $TASK_NAME task; read"
gf_submit_task

# Parallel task 2
gf_create_task -name Father
gf_wait_task Root
gf_set_task_command "echo This is $TASK_NAME task; read"
gf_submit_task

# Sequential task
gf_create_task -name Daughter
gf_want_task Mother -variable PARENT1
gf_want_task Father -variable PARENT2
gf_set_task_command "
    echo This is $TASK_NAME task
    echo Parent 1 is $PARENT1 task
    echo Parent 2 is $PARENT2 task
    read
"
gf_submit_task
