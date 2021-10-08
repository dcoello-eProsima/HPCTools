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

echo This is task $SLURM_JOB_ID
echo PARAM=${PARAM}
pwd; hostname; date

echo
echo SLURM_JOB_NODELIST=${SLURM_JOB_NODELIST}
echo SLURM_NTASKS=${SLURM_NTASKS}
echo SLURM_CPUS_ON_NODE=${SLURM_CPUS_ON_NODE}
echo SLURM_CPUS_PER_TASK=${SLURM_CPUS_PER_TASK}
echo SLURM_JOB_CPUS_PER_NODE=${SLURM_JOB_CPUS_PER_NODE}
echo SLURM_JOB_PARTITION=${SLURM_JOB_PARTITION}
echo SLURM_TASKS_PER_NODE=${SLURM_TASKS_PER_NODE}
echo

#export OMP_NUM_THREADS=24

#module load gcc/6.4.0 openmpi/2.1.1 extrae/3.5.2

echo Batería de probas con GCC

GCC_TARGETS="dgesv_O0 dgesv_O1 dgesv_O2 dgesv_O2m dgesv_O3 dgesv_O3m dgesv_Ofast dgesv_Ofastm"

module load gcccore

cc --version
make -f makefile_bench cleanall
make -f makefile_bench ${GCC_TARGETS}

for old in ${GCC_TARGETS}; do
  mv $old ${old//dgesv/gcc}
done

#1st run
for exe in ${GCC_TARGETS//dgesv/gcc}; do
  srun -n 1 $exe ${PARAM}
done

#2nd run (shuffle)
for exe in `echo "${GCC_TARGETS//dgesv/gcc}" | tr ' ' '\n' | shuf | tr '\n' ' '`; do
  srun -n 1 $exe ${PARAM}
done

#3rd run (reverse)
for exe in `echo "${GCC_TARGETS//dgesv/gcc}" | tr ' ' '\n' | tac | tr '\n' ' '`; do
  srun -n 1 $exe ${PARAM}
done

echo Batería de probas con ICC

ICC_TARGETS="dgesv_O0 dgesv_O1 dgesv_O2 dgesv_O2m dgesv_O3 dgesv_O3m dgesv_Ofast dgesv_Ofastm dgesv_fast"

module load intel

icc --version
make -f makefile_bench cleanall
make -f makefile_benach CC=icc PLATFLAGS="-xHost" ${ICC_TARGETS}

for old in ${ICC_TARGETS}; do
  mv $old ${old//dgesv/icc}
done

#1st run
for exe in ${ICC_TARGETS//dgesv/icc}; do
  srun -n 1 $exe ${PARAM}
done

#2nd run (shuffle)
for exe in `echo "${ICC_TARGETS//dgesv/icc}" | tr ' ' '\n' | shuf | tr '\n' ' '`; do
  srun -n 1 $exe ${PARAM}
done

#3rd run (reverse)
for exe in `echo "${ICC_TARGETS//dgesv/icc}" | tr ' ' '\n' | tac | tr '\n' ' '`; do
  srun -n 1 $exe ${PARAM}
done

# Format results and send e-mail
cat slurm-${SLURM_JOB_ID}.out | ./parsingoutput.sh | mail -s "FT2: Resultados de tarefa ${SLURM_JOB_ID}" -b emilioj@posteo.net emilioj@udc.gal
