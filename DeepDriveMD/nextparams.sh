#! /usr/bin/env bash

###
# Function to get the next combination
# Uses indices, returns -1 when no more combinations
###
# Index array and other values are automatically calculated.
# Just need to set the "choices" array
# Optionally set the "names" array and "sep" string, see below
###
function getcombo() {
  place=$((${#indices[@]}-1))
  indices[place]=$((indices[place]+1))
  while [ "${indices[place]}" -ge "${num_elements[place]}" ] ; do
    place=$((place-1))
    if [ "$place" -lt 0 ] ; then
      printf -v "$1" -- "-1"
      return
    fi
    indices[place]=$((indices[place]+1))
  done
  if [ "${indices[0]}" -ge "${num_elements[0]}" ] ; then
    printf -v "$1" -- "-1"
    return
  fi
  place=$((place+1))
  while [ "$place" -lt "${#indices[@]}" ] ; do
    indices[place]=0
    place=$((place+1))
  done
  place=$((place-1))
  printf -v "$1" -- "%d" "$((combonumber-1))"
}

###
# Arrays to choose from, each element is a space-separated string
# Each element of the string is a combination choice
# ***Each string length should be in non-decreasing order***
choices=( "10000 20000"
          "20000 30000"
          "100 200"
          "500 1000"
          "128 256"
          "100 200"
          "1000 2000"
          "100 200"
          "3211264 6422528"
)
# Optional text to prepend to each choice
names=("--mat_size"
        "--num_step"
        "--num_epochs_train"
        "--num_sample"
        "--dense_dim_out"
        "--num_epochs_agent"
        "--num_mult_agent"
        "--num_mult_outlier"
        "--allreduce_size")
# Optional separator to use
sep=" "
###
# Result will be printed like: ${names[i]}${sep}${val[i]}
# Unsetting/removing names+sep will result in only values printed
# Each combination is printed on a line, space separated
###

###
# The rest of the values are automatically calculated
###
# Array to hold the number of elements
declare -a num_elements
# Array to hold the current printing indices
declare -a indices
###
# n, the number of arrays (minus 1)
n=-1
###

# Get the number of combos and the choice lists
num_combos=1
for i in $(seq 0 $((${#choices[@]}-1))) ; do
  n=$((n+1))
  read -ra vals <<< "${choices[i]}"
  num_elements+=(${#vals[@]})
  num_combos=$((num_combos*${#vals[@]}))
  indices+=(0)
done

# The combination number of combinations to get
combonumber="$1"

# The combonumber should be positive and within range
[ "$combonumber" -lt 1 ] && exit 1
# The combonumber is past the last combination
[ "$combonumber" -gt "$num_combos" ] && exit 1

# Set the last index to -1, the first iteration will bring it to zero
indices[n]=$((indices[n]-1))

###
# Combinations loop
###
# Loop until we have the specified combination number
while [ "$combonumber" -gt 0 ] ; do
  # Get the next combination
  getcombo combonumber
done
# Print our combination
combo=""
for i in $(seq 0 "$n") ; do
  if [ "$i" -gt 0 ] ; then combo+=" " ; fi
  read -ra vals <<< "${choices[i]}"
  combo+="${names[i]}$sep${vals[${indices[i]}]}"
done

echo "$combo"
exit 0
