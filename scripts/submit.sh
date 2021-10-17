#!/bin/sh
#SBATCH -t 00:35:00 # execution time hh:mm:ss *OB*
#SBATCH -n 1 #tasks (for example, MPI processes)
#SBATCH -c 24 #cores/task (for example, shared-mem threads/process)
##SBATCH -N 8  #nodes (can be obtained from the two previous)
##SBATCH --ntasks-per-core ntasks # max ntasks per core
##SBATCH --ntasks-per-socket ntasks # max ntasks per socket
##SBATCH --ntasks-per-node ntasks # max ntasks per node
#SBATCH -p cola-corta

# Parameters for the binary to run
PARAM=2048


function run() {
  echo "running size $1" 
  echo Batería de probas con GCC

  GCC_TARGETS="gcc_dgesv_O0 gcc_dgesv_O1 gcc_dgesv_O2 gcc_dgesv_O2m gcc_dgesv_O3 gcc_dgesv_O3m gcc_dgesv_Ofast gcc_dgesv_Ofastm"

  #module load gcccore

  cc --version
  # make -f makefile_bench cleanall
  # make -f makefile_bench LDFLAGS="-lm -llapack -lblas" ${GCC_TARGETS} 

  # for old in ${GCC_TARGETS}; do
    # mv $old ${old//dgesv/gcc}
  # done

  #1st run
  for exe in ${GCC_TARGETS//dgesv/gcc}; do
    echo $exe
    ./$exe ${1}
  done

  #2nd run (shuffle)
  for exe in `echo "${GCC_TARGETS//dgesv/gcc}" | tr ' ' '\n' | shuf | tr '\n' ' '`; do
    echo $exe
    ./$exe ${1}
  done

  #3rd run (reverse)
  for exe in `echo "${GCC_TARGETS//dgesv/gcc}" | tr ' ' '\n' | tac | tr '\n' ' '`; do
    echo $exe
    ./$exe ${1}
  done

  echo Batería de probas con ICC

  ICC_TARGETS="dgesv_O0 dgesv_O1 dgesv_O2 dgesv_O2m dgesv_O3 dgesv_O3m dgesv_Ofast dgesv_Ofastm dgesv_fast"

  icc --version
  # make -f makefile_bench cleanall
  # make -f makefile_bench CC=icc PLATFLAGS="-xHost" ${ICC_TARGETS}

  for old in ${ICC_TARGETS}; do
    mv $old ${old//dgesv/icc}
  done

  #1st run
  for exe in ${ICC_TARGETS//dgesv/icc}; do
    echo $exe
    ./$exe ${1}
  done

  #2nd run (shuffle)
  for exe in `echo "${ICC_TARGETS//dgesv/icc}" | tr ' ' '\n' | shuf | tr '\n' ' '`; do
    echo $exe
    ./$exe ${1}
  done

  #3rd run (reverse)
  for exe in `echo "${ICC_TARGETS//dgesv/icc}" | tr ' ' '\n' | tac | tr '\n' ' '`; do
    echo $exe
    ./$exe ${1}
  done
}

run 512
run 1024
run 2048




# Format results and send e-mail
# cat slurm-${SLURM_JOB_ID}.out | ./parsingoutput.sh | mail -s "FT2: Resultados de tarefa ${SLURM_JOB_ID}" -b emilioj@posteo.net emilioj@udc.gal
