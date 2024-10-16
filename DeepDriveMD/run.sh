#! /usr/bin/env bash

###
#   User path, queue, etc., arguments
filesroot="/eagle/RECUP/miniapp_traces/work"
datadir="${filesroot}/data"
modeldir="${filesroot}/model"
workdir="$(pwd)"
project_id=RECUP
queue=debug
###

###
#   Configuration, base env.sh file and legend file
baseenv="$(pwd)/baseenv.sh"
envfile="$(pwd)/trialenv.sh"
legendfile="${filesroot}/legend.nfo"
traceroot="${filesroot}/traces"
# we need stuff from the base env in this script, if we haven't sourced it
[ -z "$CONDA_PREFIX" ] && source "$baseenv"
###

###
#   Runtime arguments varied by nextparams.sh
if [ false ] ; then
  mat_size=10000
  num_step=20000
  num_epochs_train=100
  num_sample=500
  dense_dim_out=128
  num_mult_agent=1000
  num_mult_outlier=100
  allreduce_size=3211264
fi
###

###
#   Runtime arguments not varied by nextparams.sh
io_json_file="io_size.json"
env="$envfile"
num_phases=3
num_mult_train=4000
dense_dim_in=12544
preprocess_time_train=30
preprocess_time_agent=5
num_epochs_agent=100
num_sim=8
num_nodes=2
###

###
#   The base command
cmd="python3 launch-scripts/modsim_exp/exp3_3/ddmd-F-ddp.py"
# add the unchanging user-specific arguments to the base command
cmd="$cmd --data_root_dir $datadir --model_dir $modeldir --work_dir $workdir"
cmd="$cmd --queue $queue --project_id $project_id"
cmd="$cmd --io_json_file $io_json_file --env $envfile"
# the base runtime arguments which do not vary
# output path will be created based on a hash of base args+varied args
baseargs="--num_phases $num_phases --num_mult_train $num_mult_train"
baseargs="$baseargs --dense_dim_in $dense_dim_in"
baseargs="$baseargs --preprocess_time_train $preprocess_time_train"
baseargs="$baseargs --preprocess_time_agent $preprocess_time_agent"
baseargs="$baseargs --num_sim $num_sim --num_nodes $num_nodes"
###

###
#   The PAPI Counter groups to collect (this will be the inner loop)
IFS=$'\n' read -d '' -r -a countergroups < ~/papi_lists/COUNTERS
###

###
#   Prepare filesroot directory and remove any leftover data/model directories
mkdir -p "$filesroot"
rm -rf "$datadir" "$modeldir"
# Iterator counters for loops, outer loop=combo, inner-loop=counter
# iteration tracks count in inner-loop
combo=1
iteration=0
# Skip counters ahead to avoid wasted grep, md5sum, etc., when resuming
[ ! -f last ] && echo "0" > last
lastiter="$(cat last)"
combo=$((combo+$lastiter/${#countergroups[@]}))
iteration=$((($combo-1)*${#countergroups[@]}))
while args="$(./nextparams.sh $combo)" ; do
  # increment the combo number for the next iteration
  combo=$((combo+1))
  # args is our varied arguments, prepend our base args to them
  args="$baseargs $args"
  # get a hash of our arguments
  arghash="$(echo -n "$args" | md5sum | cut -d' ' -f1)"
  # check if it is in our legend file and add it if it isn't
  if ! grep -q "$arghash" "$legendfile" 2>/dev/null ; then
    printf "%s\n%s\n" "$arghash" "$args" >> "$legendfile"
  fi
  # the command we'll run
  trialcmd="$cmd $args"
  # the trial trace directory
  tracedir="${traceroot}/$arghash"
  mkdir -p "$tracedir"
  # iterate through all counter groups for this argument combination
  for counters in "${countergroups[@]}" ; do
    # the number of times we've been in this inner loop
    iteration=$((iteration+1))
    # if we've failed twice in a row then skip this parameter combination
    [ -f "${tracedir}/fails" ] && \
      [ $(wc -l "${tracedir}/fails" | cut -d' ' -f1) -eq 2 ] && \
        break
    # get a hash of the counters
    counterhash="$(echo -n "$counters" | md5sum | cut -d' ' -f1)"
    # skip if the expected trace file exists
    [ -f "${tracedir}/${counterhash}.0.h5" ] && continue
    # check if it is in our legend file and add it if it isn't
    if ! grep -q "$counterhash" "$legendfile" 2>/dev/null ; then
      printf "%s\n%s\n" "$counterhash" "$counters" >> "$legendfile"
    fi
    # create model and data directories
    mkdir -p "$modeldir"
    for phase in $(seq 0 $num_phases) ; do
      mkdir -p "$datadir/phase$phase"
    done
    # fix our environment variables
    cp "$baseenv" "$envfile"
    sed -i "s/THEDUMPNAME/${counterhash}/g" "$envfile"
    sed -i "s/THECOUNTERS/${counters}/g" "$envfile"
    sed -i "s|THETRACEDIR|${tracedir}|g" "$envfile"
    # print what we're about to do
    echo "${iteration}: counters: $counters"
    echo "$trialcmd"
    # run the command
    TZ='America/Chicago' date
    $trialcmd
    TZ='America/Chicago' date
    echo "waiting for child PIDs . . ."
    wait
    sleep 5
    TZ='America/Chicago' date
    echo "checking/gathering output . . ."
    # ensure our output is as expected
    if [ -f "${tracedir}/${counterhash}.0.h5" ] && \
        [ -s "${tracedir}/${counterhash}.0.h5" ] ; then
      # get the profile time from the re logs
      pilotdir="$(ls -d re.*)/pilot.0000"
      if [ -d "$pilotdir" ] ; then
        refile="agent_staging_output.0000.prof"
        refile="$(find "$pilotdir" -type f -name "$refile")"
        if [ ! -f "$refile" ] ; then
          refile="$(find "$pilotdir" -type f -name "agent_staging_output.*.prof")"
        fi
        if [ -f "$refile" ] ; then
          python3 misc/get_task_execution_time.py \
                                  -f "$refile" >> "${tracedir}/times"
        else
          echo "task file $refile not found"
        fi
        refile="bootstrap_0.prof"
        refile="$(find "$pilotdir" -type f -name "$refile")"
        if [ -f "$refile" ] ; then
          python3 misc/get_workflow_execution_time.py \
                                  -f "$refile" >> "${tracedir}/times"
        else
          echo "boostrap file $refile is not valid"
        fi
      else
        echo "Directory $pilotdir is not valid"
      fi
      echo "Success"
      # set target for resume iteration
      echo "$iteration" > last
    else
      # remove the file if it was there and just empty
      rm -f "${tracedir}/${counterhash}"*
      # if we've failed twice in a row then skip this parameter combination
      # add a line to faillog
      TZ='America/Chicago' date >> "${tracedir}/fails"
    fi
    sleep 5
    # clean up files from radical
    rm -rf re.session* ~/.radical* ~/radical.pilot.sandbox/*
    # clean up files leftover from the command
    rm -rf "$datadir"/* "$modeldir"/*
  done
done
###
