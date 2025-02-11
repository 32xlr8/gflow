#!../../../bin/gflow

# Combined flow

# Include Genus synthesis sub-flow
gf_source genus.syn.gf

# Include Innovus implementation sub-flow
gf_get_task_dir SynOpt -variable NETLIST
gf_source innovus.impl.gf

# Include Tempus ECO sub-flow
gf_get_task_dir PostR -variable DATABASE
gf_source tempus.eco.gf
