#! /usr/bin/env bash

export MINI_APP_DeepDriveMD_DIR="DEEPDRIVEDIR"

module use /soft/modulefiles
module load conda/2024-04-29
module load perftools-base/23.12.0

conda activate /eagle/RECUP/twang/env/base-clone-rct-09262024

export RADICAL_LOG_LVL=DEBUG
export RADICAL_PROFILE=TRUE
export RADICAL_REPORT=TRUE
export RADICAL_SMT=1
export MPIR_CVAR_NOLOCAL=1

if [ false ] ; then
  # if GPU support is enabled, it appears when mpi4py is imported we get:
  # MPIDI_CRAY_init: GPU_SUPPORT_ENABLED is requested, but GTL library is not linked
  # I am unable to build mpi4py due to version issues
  # so I believe there is only the system provided mpi4py available
  export MPICH_GPU_SUPPORT_ENABLED=0
  module load cpe-cuda/23.12 nvhpc/23.9 PrgEnv-nvhpc/8.5.0 craype-accel-nvidia80
  module load craype-network-ofi
  module load cray-mpich/8.1.28
  module load cray-python/3.11.5
  module load cray-hdf5-parallel/1.12.2.9
  [ -d "$venv" ] && source "${venv}/bin/activate"
fi

export PYTHONPATH="/eagle/RECUP/twang/env/base-clone-rct-09262024/lib/python3.11/site-packages:$PYTHONPATH"

[ -d "${HOME}/pyhook" ] && export PYTHONPATH="${HOME}/pyhook:${PYTHONPATH}"

export PAPI_PREFIX="/opt/cray/pe/papi/7.0.1.2"
export PDUMP_FILENAME="THEDUMPNAME"
export PDUMP_EVENTS="THECOUNTERS"
export PDUMP_DUMP_DIR="THETRACEDIR"
export PDUMP_OUTPUT_FORMAT="hdf5"

