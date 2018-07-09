#!/usr/bin/env bash
set -e

#--- BART ---
vBART=~/Programs/BART/bart_PUB-RING
cd $vBART
source startup.sh
bartinfo=$(git rev-parse --abbrev-ref HEAD)
cd -
echo $bartinfo > bart.info
bart version >> bart.info

#--- Config ---
RO=320
SP=1
SPF=15 # spokes per frame
RF=60 # relevant frames

# Create corresponding trajectory
bart traj -x$RO -y$(($SPF*$RF)) -c -r -G _t
bart reshape $(bart bitmask 2 10) $SPF $RF _t t




# Combine F frames: F * 15 spokes
F=5
Fstart=34
bart extract 10 $Fstart  $(($Fstart + $F)) k _kex
bart transpose 2 9 _kex _kex1
bart reshape $(bart bitmask 9 10) 1 $(($F * $SPF)) _kex1 _kex2
bart transpose 2 10 _kex2 kex

bart extract 10 $Fstart $(($Fstart + $F)) t _tex
bart reshape $(bart bitmask 2 10) $(($F * $SPF)) 1 _tex tex

# GD corrections
for i in 3 15 75; do
#--- Extract SP_GDest spokes ---
SP_GDest=$i
bart extract 2 0 $SP_GDest kex k_SP_GDest
bart extract 2 0 $SP_GDest tex t_SP_GDest

#--- GD RING tool ---
GDring=$(bart estdelay -R t_SP_GDest k_SP_GDest); echo -e $i "\t" $GDring >> RING.txt
bart traj -x$RO -y$(($SPF*$RF)) -c -r -G -q$GDring -O _tGDring0
bart reshape $(bart bitmask 2 10) $SPF $RF _tGDring0 _tGDring
bart extract 10 17 50 _tGDring tGDring
bart extract 10 0 $F tGDring _tGDringex
bart reshape $(bart bitmask 2 10) $(($F * $SPF)) 1 _tGDringex tGDringex

# Gridding
bart nufft -i tGDringex kex _tmp
bart rss 8 _tmp rec_RING_SPGDest$SP_GDest


#--- GD AC-Adaptive tool ---
bart extract 1 1 $RO k_SP_GDest kACadapt
bart extract 1 1 $RO t_SP_GDest tACadapt
GD_ACadapt=$(bart estdelay tACadapt kACadapt); echo -e $i "\t" $GD_ACadapt >> ACadapt.txt
bart traj -x$RO -y$(($SPF*$RF)) -c -r -G -q$GD_ACadapt -O _tGD_ACadapt0
bart reshape $(bart bitmask 2 10) $SPF $RF _tGD_ACadapt0 _tGD_ACadapt
bart extract 10 17 50 _tGD_ACadapt tGD_ACadapt
bart extract 10 0 $F tGD_ACadapt _tGD_ACadaptex
bart reshape $(bart bitmask 2 10) $(($F * $SPF)) 1 _tGD_ACadaptex tGD_ACadaptex

# Gridding
bart nufft -i tGD_ACadaptex kex _tmp
bart rss 8 _tmp rec_ACadapt_SPGDest$SP_GDest
done










