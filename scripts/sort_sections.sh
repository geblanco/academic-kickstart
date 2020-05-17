#!/bin/bash

# go to project root dir
scriptdir=$(dirname -- "$(realpath -- "$0")")
rootdir=$(dirname $scriptdir)
cwd=$(pwd)
cd $rootdir >/dev/null

DEBUG=0
ONLY_LIST=0

get_section_file(){
  echo $(grep "weight" -R content -l | grep "$1")
}

get_sorted_section_files(){
  local -n sections=$1
  sections=($(grep "weight" -R content | sort -t = -k 2 -g | cut -f 1 -d ':'))
  if [[ "$DEBUG" -eq 1 ]]; then 
    echo "get sorted_section_files"
    for sect in ${sections[@]}; do
      echo "* $sect"
    done
  fi
}

get_sorted_sections(){
  local -n sections=$1; shift
  local sects=($@)
  if [[ "${#sects}" -eq 0 ]]; then
    get_sorted_section_files sects
  fi
  sections=($(printf "%s\n" "${sects[@]}" | xargs -i basename '{}' | cut -f 1 -d '.'))
  if [[ "$DEBUG" -eq 1 ]]; then 
    echo "get sorted_section"
    for sect in ${sections[@]}; do
      echo "* $sect"
    done
  fi
}

merge_sections(){
  local -n output=$1; shift
  local sections=($@)
  for sect in "${sections[@]}"; do
    if [[ ! " ${output[@]} " =~ " $sect " ]]; then
      output+=($sect)
    fi
  done
  if [[ "$DEBUG" -eq 1 ]]; then
    echo "merge sections"
    for sect in "${output[@]}"; do
      echo "* $sect"
    done
  fi
}

diff_sections(){
  local -n output=$1; shift
  local -n sections_1=$1; shift
  local -n sections_2=$1; shift
  for sect in "${sections_1[@]}"; do
    if [[ ! " ${sections_2[@]} " =~ " $sect " ]]; then
      output+=($sect)
    fi
  done
}

set_weight() {
  local file=$1; shift
  local weight=$1; shift
  # backup?
  sed -i "s/weight = .*/weight = $weight/g" $file
}

assign_weigths(){
  local sections=($@)
  if [[ "$DEBUG" -eq 1 || "$ONLY_LIST" -eq 1 ]]; then
    echo "Ordered sections"
  fi
  for (( index = 0; index < ${#sections[@]}; index++ )); do
    sect="${sections[$index]}"
    sect_file="$(get_section_file $sect)"
    weight=$(( ($index + 1) * 10 ))
    if [[ "$DEBUG" -eq 1 || "$ONLY_LIST" -eq 1 ]]; then
      echo "* $sect ($sect_file): $weight"
    fi
    if [[ "$ONLY_LIST" -eq 0 ]]; then
      set_weight $sect_file $weight
    fi
  done
}

filter_known_sections(){
  local -n sections=$1;shift
  local known_sections=($@)
  local output=()
  for sect in ${sections[@]}; do
    if [[ " ${known_sections[@]} " =~ " $sect " ]]; then
      output+=($sect)
    fi
  done
  if [[ "$DEBUG" -eq 1 ]]; then
    echo "filter known_sections"
    for sect in "${output[@]}"; do
      echo "* $sect"
    done
  fi
  sections=$output
}

usage(){
  echo "Usage: sort_sections [-l (only list)] <sect_1> [, <sect_2>, ...]"
  exit 0
}

if [[ "$#" -eq 1 && " $1 " == " -l " ]]; then
  ONLY_LIST=1
fi

# get files with weight parameter, sorted
sorted_section_files=()
sorted_sections=()

get_sorted_section_files sorted_section_files
get_sorted_sections sorted_sections

if [[ "$ONLY_LIST" -eq 1 ]]; then
  assign_weigths "${sorted_sections[@]}"
  exit 0
fi

order=($@)
missing=()
filter_known_sections order "${sorted_sections[@]}"

# If order contains only some sections, put those first, then the rest
if [[ "${#order[@]}" -lt "${#sorted_sections[@]}" ]]; then
  diff_sections missing sorted_sections order
  echo -n "There are some missing sections: "
  printf "\"%s\" " "${missing[@]}"
  echo
  merge_sections order "${order[@]}" "${sorted_sections[@]}"
fi

assign_weigths "${order[@]}"
echo "You should probably commit your changes! :)"

