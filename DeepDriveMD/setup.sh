#! /usr/bin/env bash

if grep -q DEEPDRIVEDIR baseenv.sh 2>/dev/null ; then
  sed -i "s|DEEPDRIVEDIR|$(pwd)|" baseenv.sh
fi
exit
source baseenv.sh
if [ ! -d "venv/" ] ; then
  python3 -m venv venv
  source venv/bin/activate
  pip install --upgrade pip
  pip install numpy
  pip install h5py
  #env MPICC=$(which mpicc) python -m pip install mpi4py
  pip install cupy-cuda12x
  python -m cupyx.tools.install_library --cuda 12.x --library cutensor
  if [ false ] ; then
  pip install radical.entk
  else
  pip install git+https://github.com/radical-cybertools/radical.utils.git@devel
  pip install git+https://github.com/radical-cybertools/radical.saga.git@devel
  pip install git+https://github.com/radical-cybertools/radical.pilot.git@devel
  pip install git+https://github.com/radical-cybertools/radical.entk.git@devel
  fi
fi

