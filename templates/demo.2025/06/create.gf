#!../../../bin/gflow

# Data creation task
gf_create_task -name Data
gf_set_task_command "
    read -p 'Press enter to create ./out/$TASK_NAME.dat'
    touch ./out/$TASK_NAME.dat
"
gf_submit_task
