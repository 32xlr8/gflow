ne:
    ls -1aU {../../project,./block}.{common,gconfig,genus,innovus,quantus,tempus,voltus,calibre}.gf 2> /dev/null | xargs nedit  &

fe:
    ../template/genus.fe.gf

fp:
    ../template/innovus.fp.gf

be:
    ../template/innovus.be.gf

ig:
    ../template/innovus.gui.gf

sta:
    export GENUS_FE=N; \
    export INNOVUS_BE=N; \
    export INNOVUS_OUT=Y; \
    export CALIBRE_DUMMY=N; \
    export CALIBRE_DRC=N; \
    export CALIBRE_LVS=N; \
    export QUANTUS_OUT=Y; \
    export TEMPUS_STA=Y; \
    export TEMPUS_TSO=N; \
    export VOLTUS_STATIC=N; \
    export VOLTUS_DYNAMIC=N; \
    ../template/flow.gf -run flow.sta -today

tso:
    export GENUS_FE=N; \
    export INNOVUS_BE=N; \
    export INNOVUS_OUT=N; \
    export CALIBRE_DUMMY=N; \
    export CALIBRE_DRC=N; \
    export CALIBRE_LVS=N; \
    export QUANTUS_OUT=N; \
    export TEMPUS_STA=N; \
    export TEMPUS_TSO=Y; \
    export VOLTUS_STATIC=N; \
    export VOLTUS_DYNAMIC=N; \
    ../template/flow.gf -run flow.tso -today

rail:
    export GENUS_FE=N; \
    export INNOVUS_BE=N; \
    export INNOVUS_OUT=; \
    export CALIBRE_DUMMY=N; \
    export CALIBRE_DRC=N; \
    export CALIBRE_LVS=N; \
    export QUANTUS_OUT=; \
    export TEMPUS_STA=N; \
    export TEMPUS_TSO=N; \
    export VOLTUS_STATIC=N; \
    export VOLTUS_DYNAMIC=Y; \
    ../template/flow.gf -run flow.rail -today

dummy:
    ../template/calibre.dummy.gf

drc:
    ../template/calibre.drc.gf

lvs:
    ../template/calibre.lvs.gf

flow:
    ../template/flow.gf
