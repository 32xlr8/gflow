#!../../../bin/gflow

# Tempus STA sub-flow

##################################################
# Data out
##################################################
gf_create_task -name Init

# Select Innovus database to analyze from latest available if $DATABASE is empty
echo
gf_choose_file_dir_task -variable DATABASE -prompt "Please select database or active task:" -keep -files "
    */out/PostR*.innovus.db
    */out/ECO*.innovus.db
" -active -tasks "
    */tasks/PostR*
    */tasks/ECO*
"

# Auto-populate database for task
if [ -e "$DATABASE/run" ]; then
    gf_want_task -exact $DATABASE
    DATABASE="$DATABASE/out/$(basename "$DATABASE").innovus.db"
fi

gf_info "Innovus database \e[32m$DATABASE\e[0m selected"

# Tool commands
gf_set_task_command "
    echo $TASK_NAME inputs:
    ls -l $DATABASE
    read
    touch ./out/$TASK_NAME.v.gz
    touch ./out/$TASK_NAME.def.gz
"
gf_submit_task

##################################################
# Quantus extraction
##################################################
gf_create_task -name Extraction -mother Init

# Ask if user would like to run STA with metal fill
echo
gf_choose -variable USE_DUMMY_GDS -keep -keys YN -time 30 -default Y -prompt "Do you want to use dummy fill GDS (Y/N)?"

# Select dummy fill to use when required
if [ "$USE_DUMMY_GDS" == "Y" ]; then
    echo
    gf_choose_file_dir_task -variable DUMMY_GDS -prompt "Please select dummy fill to use:" -files "
        */out/Dummy*.gds.gz
    " -active -tasks "
        */tasks/Dummy*
    "
    # Auto-populate metal fill for task
    if [ -e "$DUMMY_GDS/run" ]; then
        gf_want_task -exact $DUMMY_GDS
        DUMMY_GDS="$DUMMY_GDS/out/$(basename "$DUMMY_GDS").gds.gz"
    fi
    gf_info "Metal fill GDS \e[32m$DUMMY_GDS\e[0m selected"
fi

gf_set_task_command "
    echo $TASK_NAME inputs:
    ls -l ./out/$MOTHER_TASK_NAME.def.gz $DUMMY_GDS
    read
    touch ./out/$TASK_NAME.spef.gz
"
gf_submit_task

##################################################
# STA
##################################################
gf_create_task -name STA
gf_want_task -variable INIT_TASK_NAME Init
gf_want_task -variable EXTRACTION_TASK_NAME Extraction
gf_set_task_command "
    echo $TASK_NAME inputs:
    ls -l ./out/$INIT_TASK_NAME.v.gz
    ls -l ./out/$INIT_TASK_NAME.def.gz
    ls -l ./out/$EXTRACTION_TASK_NAME.spef.gz
    read
    touch ./out/$TASK_NAME.tempus.db
"
gf_submit_task
