#!/bin/bash

NAME=$1

if [ $# -eq 0 ]
then
  echo "ERROR: No filename" 
  exit 1
fi

echo "building files for ${NAME}"

if [ ! -f $NAME ]
then
  mkdir $NAME
else  
  echo "INFO: dir ${NAME} exist"
fi

BASE_PATH="./${NAME}/${NAME}"

# EOF EOT
# read here:
# https://unix.stackexchange.com/questions/323750/difference-between-eot-and-eof

tee "${BASE_PATH}.vue" <<EOF
<template src="./${NAME}.html" lang="html"></template>
<script src="./${NAME}.js"></script>
<style src="./${NAME}.scss" lang="scss"></style>
<style src="./${NAME}-scoped.scss" lang="scss" scoped></style>
EOF

tee "${BASE_PATH}.html" <<EOF
<div class="${NAME}"></div>
EOF

tee "${BASE_PATH}.scss" <<EOF
.${NAME} {}
EOF

tee "${BASE_PATH}-scoped.scss" <<EOF
.${NAME} {}
EOF


tee "${BASE_PATH}.js" <<EOT
export default {
  data() {
    return {
    };
  }
};
EOT

