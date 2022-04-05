#!/usr/bin/env bash

DNA3SPNGRO_BIN_PATH=~/Workspace/genesis_CG_julia
export PATH=$PATH:~/Workspace/x3dna-v2.4/bin
export X3DNA=~/Workspace/x3dna-v2.4

# This tool is originally built by de Pablo's group and modified to generate
# input files for Genesis.

if [ $# -lt 1 ]; then
    echo "Usage: $0 <sequence file>"
    exit 1
fi

echo "================================================================================"
echo "Making DNA curvature parameter file..."
$DNA3SPNGRO_BIN_PATH/tools/modeling/DNA_3SPN.2C/seq2curv_DNA2C.jl $1

echo "--------------------------------------------------------------------------------"
echo "Running X3DNA..."
x3dna_utils cp_std BDNA
rebuild -atomic dna2c.curv ${1%.*}_x3dna.pdb
rm -f Atomic*
rm -f ref_frames.dat
rm -f dna2c.curv

echo "--------------------------------------------------------------------------------"
echo "Making GROMACS itp files for GENESIS..."
$DNA3SPNGRO_BIN_PATH/tools/modeling/DNA_3SPN.2C/x3dna_pdb_prune.jl ${1%.*}_x3dna.pdb
if [ $# -eq 1 ]; then
    $DNA3SPNGRO_BIN_PATH/src/aa_2_cg.jl ${1%.*}_x3dna_new.pdb --3spn-param 1 --cgpdb --cgconnect --psf
else
    $DNA3SPNGRO_BIN_PATH/src/aa_2_cg.jl ${1%.*}_x3dna_new.pdb --3spn-param 1 --cgpdb --cgconnect --psf $2
fi
echo " DONE!"
echo "================================================================================"
