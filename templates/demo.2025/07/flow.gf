#!../../../bin/gflow

gf_source genus.syn.gf

gf_get_task_dir SynOpt -variable NETLIST
gf_source innovus.impl.gf

gf_get_task_dir PostR -variable DATABASE
gf_source tempus.eco.gf
