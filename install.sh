#!/usr/bin/env bash

REPO_BASE_URL="https://raw.githubusercontent.com/mkastner/sh/master/"
SCRIPTS=(
  "install.sh"
  "manage-sites.sh"
  "mk-vue-files.sh"
  "mk-node-test.sh"
)



if [ -z $SCRIPTS_DIR ]
then
  export SCRIPTS_DIR="${HOME}/sh"
  if [ $NODE_ENV = 'development' ]
  then
    echo "don't use ${SCRIPTS_DIR} as install target in development" 
    exit 1  
  fi
  echo "SCRIPTS_DIR not found in env"
  echo "installing in ${SCRIPTS_DIR}" 
fi

if [ ! -d "${SCRIPTS_DIR}" ]
then
  echo "ERROR directory path does not exist: ${SCRIPTS_DIR}"
  set -e 
  exit 1
fi

echo "scripts target ${SCRIPTS_DIR}"

for script_index in "${!SCRIPTS[@]}"
do
  script="${SCRIPTS[$script_index]}"
  script_path="${SCRIPTS_DIR}/${script}"
  if [ -f "${script_path}" ]
  then
    echo "[${script_index}] + update  ${script}"
  else
    echo "[${script_index}] ~ install ${script}"
  fi
done

echo "Enter a number to select or (q)uit"
read input 

if [ "${input}" == "q" ]
then
  echo "Quit (${input}) was clicked"
  exit 1
else
  echo "number ${input} was clicked"
  selected_script=${SCRIPTS[input]}
  echo "selected script: ${selected_script}"
  
  script_url="${REPO_BASE_URL}${selected_script}"
  script_path="${SCRIPTS_DIR}/${selected_script}"
  echo "*************************"
  echo "trying to download"
  echo $script_url
  echo "to"
  echo $script_path 
  curl $script_url --output $script_path 
fi

