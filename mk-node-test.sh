#!/bin/bash

NAME=$1

if [ $# -eq 0 ]
then
  echo "ERROR: No filename" 
  exit 1
fi

echo "building test for ${NAME}"

if [ -e $NAME ]
then
  echo "INFO:  ${NAME} exist"
else  

# EOF EOT
# read here:
# https://unix.stackexchange.com/questions/323750/difference-between-eot-and-eof

tee "${NAME}.js" <<EOT
const log = require('mk-log');
const tape = require('tape');

async function main() {
  tape('describe', async(t) => {
    try {
      // test here 
      t.end();
    } catch (err) {
      log.error(err);
    }
  });
}

main();
EOT

fi
