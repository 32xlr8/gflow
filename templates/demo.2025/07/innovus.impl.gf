#!../../../bin/gflow

##################################################
# Placement
##################################################
gf_create_task -name Place

# Choose netlist if not chosen
gf_choose_file_dir_task -variable NETLIST -keep -prompt "Please select netlist to implement:" -files "
    */out/SynMap*.v
    */out/SynOpt*.v
" -active -tasks "
    */tasks/SynMap*
    */tasks/SynOpt*
"

# Auto-populate database for task
if [ -e "$NETLIST/run" ]; then
    gf_want_task -exact $NETLIST
    NETLIST="$NETLIST/out/$(basename "$NETLIST").v"
fi

# Tool commands
gf_set_task_command "
    echo $TASK_NAME inputs:
    ls -l $NETLIST
    read
    touch ./out/$TASK_NAME.innovus.db
"
gf_submit_task

##################################################
# Clock tree
##################################################
gf_create_task -name Clock -mother Place
gf_set_task_command "
    echo $TASK_NAME inputs:
    ls -l ./out/$MOTHER_TASK_NAME.innovus.db
    touch ./out/$TASK_NAME.innovus.db
"
gf_submit_task

##################################################
# Clock tree
##################################################
gf_create_task -name Route -mother Clock
gf_set_task_command "
    echo $TASK_NAME inputs:
    ls -l ./out/$MOTHER_TASK_NAME.innovus.db
    touch ./out/$TASK_NAME.innovus.db
"
gf_submit_task

##################################################
# Post-route optimization
##################################################
gf_create_task -name PostR -mother Route
gf_set_task_command "
    echo $TASK_NAME inputs:
    ls -l ./out/$MOTHER_TASK_NAME.innovus.db
    tree -L 2 ../../
    read
    touch ./out/$TASK_NAME.innovus.db
"
gf_submit_task
