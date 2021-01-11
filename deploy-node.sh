#!/usr/bin/env bash
# agnostic portable bash

CONFIG_FILE=${1:-"deployment-config.sh"}

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

if [ ! -f package.json ]
then
  echo could not find package.json in project root: exiting ...
  exit 0
fi

if [ ! -f $CONFIG_FILE ]
then
  echo could not find config.sh: exiting ...
  exit 0
fi

. $CONFIG_FILE 

check_var "GIT_REPO"

# defaults
check_var "BRANCH"
check_var "ROOT_PATH"

# production settings
check_var "BRANCH_PRODUCTION"
check_var "ROOT_PATH_PRODUCTION"

APP_NAME=$(node -p "require('./package.json').name")
check_var "APP_NAME"
PACKAGE_VERSION=$(node -p "require('./package.json').version")
check_var "PACKAGE_VERSION"
TAG_VERSION="v${PACKAGE_VERSION}"
INSTALL_CMD="yarn install"
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
echo "TARGET_ENV        : ${TARGET_ENV}"
echo "SSH_HOST          : ${SSH_HOST}"
echo "ROOT_PATH         : ${ROOT_PATH}"
echo "BRANCH            : ${BRANCH}"
echo "TAG_VERSION       : ${TAG_VERSION}"
echo "GIT_REPO          : ${GIT_REPO}"
echo "INSTALLATION_PATH : ${INSTALLATION_PATH}"
echo "SYMLINK_PATH      : ${SYMLINK_PATH}"
if [[ $SSH_PORT != "" ]]
then
  echo "SSH_PORT          : ${SSH_PORT}"
fi
echo -----------------------------------------------
printf '\n'

SSH_COMMAND="cd ${ROOT_PATH} && 
  rm -fr ${VERSIONED_APP_NAME} && 
  git clone -v --branch ${TAG_VERSION} ${GIT_REPO} ${VERSIONED_APP_NAME} && 
  cd ${INSTALLATION_PATH} && 
  echo \"installing dependencies\" &&  
  NODE_ENV=production ${INSTALL_CMD} && 
  rm ${SYMLINK_PATH} && 
  ln -s ${INSTALLATION_PATH} ${SYMLINK_PATH} && 
  sudo -S service nginx reload"


# SSH_COMMAND="cd ${ROOT_PATH}; pwd;"

echo SSH_COMMAND:
echo $SSH_COMMAND

printf 'Does this look ok to you?'
printf '(YES/NO) ' 
read -r CONFIRM
if [ "${CONFIRM}" != "YES" ]
then
  echo not confirmed: exiting ...
  exit 1
fi

ssh $SSH_PORT $SSH_HOST $SSH_COMMAND 
