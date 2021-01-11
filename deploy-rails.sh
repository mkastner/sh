#!/usr/bin/env bash
# agnostic portable bash

CONFIG_FILE=${1:-"deployment-config.sh"}
SSH_BASH_LOGIN="bash --login" #use login shell to obtain env i.e. bashrc settings

function check_var() {
  VAR_NAME=$1
  if [ -z ${!VAR_NAME} ] # use ! to pass VAR_NAME as variable indirection 
  then
    echo "could not find ${VAR_NAME}: exiting ..."
    exit
  fi
}

echo CONFIG_FILE ${CONFIG_FILE}

echo "running deploy"

if [ ! -f Gemfile ]
then
  echo could not find Gemfile: exiting ...
  exit 0
fi

if [ ! -f $CONFIG_FILE ]
then
  echo could not find config.sh in project root: exiting ...
  exit 0
fi

. $CONFIG_FILE 

check_var "GIT_REPO"
check_var "DEPLOYMENT_KEY_PATH"

# defaults
check_var "BRANCH"
check_var "ROOT_PATH"

# production settings
check_var "BRANCH_PRODUCTION"
check_var "ROOT_PATH_PRODUCTION"

APP_NAME=${PWD##*/}
check_var "APP_NAME"

export FIRST_LINE=$(head -n 1 Gemfile) 
PACKAGE_VERSION=${FIRST_LINE/\#version\=/}
check_var "PACKAGE_VERSION"
TAG_VERSION="v${PACKAGE_VERSION}"
INSTALL_CMD="/home/webhost/.rbenv/shims/bundle install"
SSH_PORT=""

echo Wo soll die Anwendung bereitgestellt werden? \(staging\|production\)
read TARGET_ENV

echo OTHER_SSH_PORT $OTHER_SSH_PORT 

if [[ "${TARGET_ENV}" == "production" ]]
then
  ROOT_PATH=${ROOT_PATH_PRODUCTION} 
  BRANCH=${BRANCH_PRODUCTION}
  SSH_HOST=${SSH_HOST_PRODUCTION}
  if [[ ! -z $OTHER_SSH_PORT_PRODUCTION ]] 
  then
    SSH_PORT="-p ${OTHER_SSH_PORT_PRODUCTION}"
  fi 
else
  if [[ ! -z $OTHER_SSH_PORT ]] 
  then
    SSH_PORT="-p ${OTHER_SSH_PORT}"
  fi 
fi

VERSIONED_APP_NAME="${APP_NAME}-${TAG_VERSION}"
 
INSTALLATION_PATH="${ROOT_PATH}/${VERSIONED_APP_NAME}"
SYMLINK_PATH="${ROOT_PATH}/${APP_NAME}"

CONFIRM="NO"

echo -----------------------------------------------
echo "TARGET_ENV         : ${TARGET_ENV}"
echo "SSH_HOST           : ${SSH_HOST}"
echo "ROOT_PATH          : ${ROOT_PATH}"
echo "BRANCH             : ${BRANCH}"
echo "TAG_VERSION        : ${TAG_VERSION}"
echo "GIT_REPO           : ${GIT_REPO}"
echo "DEPLOYMENT_KEY_PATH: ${DEPLOYMENT_KEY_PATH}"
echo "INSTALLATION_PATH  : ${INSTALLATION_PATH}"
echo "SYMLINK_PATH       : ${SYMLINK_PATH}"
if [[ $SSH_PORT != "" ]]
then
  echo "SSH_PORT          : ${SSH_PORT}"
fi
echo -----------------------------------------------
printf '\n'

SSH_COMMAND_INSTALL="cd ${ROOT_PATH} && 
  rm -fr ${VERSIONED_APP_NAME} && 
  echo \"cloning from repo\" &&  
  GIT_SSH_COMMAND='ssh -i ${DEPLOYMENT_KEY_PATH}' git clone -v --branch ${TAG_VERSION} ${GIT_REPO} ${INSTALLATION_PATH} && 
  cd ${INSTALLATION_PATH} && 
  echo \"installing dependencies\" &&
  RAILS_ENV=production ${INSTALL_CMD}"

SSH_COMMAND_ACTIVATE="cd ${ROOT_PATH} &&
  cd ${INSTALLATION_PATH} &&
  rm ${SYMLINK_PATH} &&
  ln -s ${INSTALLATION_PATH} ${SYMLINK_PATH} &&
  sudo -S service nginx reload"

echo SSH_COMMAND_INSTALL:
echo $SSH_COMMAND_INSTALL
echo SSH_BASH_LOGIN:
echo $SSH_BASH_LOGIN

printf 'Does this look ok to you?'
printf '(YES/NO) ' 
read -r CONFIRM

if [ "${CONFIRM}" != "YES" ]
then
  echo not confirmed: exiting ...
  exit 1
fi

echo -----------------------------------------------
echo installing ...

  
ssh $SSH_PORT $SSH_HOST bash --login -c "${SSH_COMMAND_INSTALL}" 

printf 'Do you want to activate the installation?'
printf '(YES/NO) ' 
read -r CONFIRM

if [ "${CONFIRM}" != "YES" ]
then
  echo activation not confirmed: exiting ...
  exit 1
fi

echo activating ...

ssh $SSH_PORT $SSH_HOST $SSH_BASH_LOGIN -c $SSH_COMMAND_ACTIVATE 

