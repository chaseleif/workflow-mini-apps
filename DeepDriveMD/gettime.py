#! /usr/bin/env python3

import os, re, sys

def getTaskExecTime(filename):
  execstart = re.compile(r'^(\d+\.?\d*),exec_start,[^,]*,[^,]*,([^,]+),.*')
  execstop = re.compile(r'^(\d+\.?\d*),exec_stop,[^,]*,[^,]*,([^,]+),.*')
  timetable_start = {}
  timetable_stop = {}
  with open(filename,'r') as infile:
    for line in infile.readlines():
      if execstart.match(line):
        groups = execstart.match(line).groups()
        time = float(groups[0])
        task = groups[1]
        if task not in timetable_start:
          timetable_start[task] = time
      elif execstop.match(line):
        groups = execstop.match(line).groups()
        time = float(groups[0])
        task = groups[1]
        if task not in timetable_stop:
          timetable_stop[task] = time
  print(f'Task exec_start timetable: {timetable_start}')
  print(f'Task exec_stop timetable: {timetable_stop}')
  if len(timetable_start) != len(timetable_stop):
    print(f'Mismatch in timetable_start and timetable_stop lengths!')
  task_execution_table = { task: timetable_stop[task] - timetable_start[task] \
                            for task in timetable_start if task in timetable_stop }
  print(f'Task duration: {task_execution_table}')

def getWorkflowExecTime(filename):
  fields = re.compile(r'^(\d+\.?\d*),([^,]+),.*')
  with open(filename,'r') as infile:
    for line in infile.readlines():
      if not fields.match(line): continue
      groups = fields.match(line).groups()
      if groups[1] == 'bootstrap_0_start':
        start = float(groups[0])
      elif groups[1] == 'bootstrap_0_stop':
        stop = float(groups[0])
        break
  print(f'First bootstrap_0_start time: {start}')
  print(f'First bootstrap_0_stop time: {stop}')
  print(f'Workflow execution time {stop-start}')

if __name__ == '__main__':
  if len(sys.argv) != 2 or not os.path.isdir(sys.argv[1]):
    print('Usage:')
    print(f'python3 {sys.argv[0]} [pilot directory]')
    sys.exit(1)
  getTaskExecTime(os.path.join(sys.argv[1], 'agent_staging_output.0000.prof'))
  getWorkflowExecTime(os.path.join(sys.argv[1], 'bootstrap_0.prof'))
