#!/bin/bash

# uncomment to test locally
# SITES_AVAILABLE="${HOME}/www/sites-available"
# SITES_ENABLED="${HOME}/www/sites-enabled"
# RESTART_CMD="sudo nginx -s stop && sudo nginx"

# echo "env_vars ${env_vars}"

if [ -z $SITES_AVAILABLE ]
then
  echo "ERROR: missing env SITES_AVAILABLE"
  exit 1
fi

if [ -z $SITES_ENABLED ]
then
  echo "ERROR: missing env SITES_AVAILABLE"
  exit 1
fi

if [ -z "${RESTART_CMD}" ]
then
  echo "ERROR: missing env RESTART_CMD"
  exit 1
fi

# SITES_AVAILABLE_PATH="${SITES_PATH}/sites-available"
# SITES_ENABLED_PATH="${SITES_PATH}/sites-enabled"
# SERVER_RELOAD_CMD="${SITES_PATH}/server-reload.sh"

# echo "SITES_PATH: ${SITES_PATH}"

# make path array for checking all paths in loop
dir_paths=(
  $SITES_AVAILABLE
  $SITES_ENABLED
)



for path in "${dir_paths[@]}"
do
  # recognize escape: echo -e
  echo "checking path ${path}"
  if [ ! -d "${path}" ]
  then
    echo "ERROR directory path does not exist: ${path}"
    set -e 
    exit 1
  fi
done

available_sites=()

for site in "${SITES_AVAILABLE}/"*
do
  filename=$(basename "${site}")
  echo "available site: ${filename}"
  available_sites=("${available_sites[@]}" $filename)
done   

echo "${#available_sites[@]} available sites found: ${available_sites}"

enabled_sites=()

for site in "${SITES_ENABLED}/"*
do
  filename=$(basename "${site}")
  echo "enabled site: ${filename}"
  enabled_sites=("${enabled_sites[@]}" $filename)
done

echo "${#enabled_sites[@]} enabled sites found: ${enabled_sites}"

for available_index in "${!available_sites[@]}"
do
  available_site="${available_sites[$available_index]}"
  site_info="[${available_index}]"
  site_status="   " 
  for enabled_index in "${!enabled_sites[@]}"
  do
    enabled_site="${enabled_sites[$enabled_index]}"
    # echo "[${enabled_index}] ${enabled_site}"
    if [ "${available_site}" == "${enabled_site}" ]
    then
      site_status="*A*"
      # echo "${available_site} == ${enabled_site}"
    fi
  done
    
  site_info+="[${site_status}] ${available_site}"
  echo "${site_info}"
done

echo "Enter Site Nr to toggle or (q)uit"
read input 

selected_site=""

if [ "${input}" == "q" ]
then
  echo "Quit (${input}) was clicked"
  exit 1
else
  echo "number ${input} was clicked"
  selected_site=${available_sites[input]}
fi

echo "selected site: ${selected_site}"

if [ -f "${SITES_ENABLED}/${selected_site}" ]
then
  rm "${SITES_ENABLED}/${selected_site}" 
else
  ln -s "${SITES_AVAILABLE}/${selected_site}" "${SITES_ENABLED}/${selected_site}"
fi

eval "${SERVER_RELOAD_CMD}" 
