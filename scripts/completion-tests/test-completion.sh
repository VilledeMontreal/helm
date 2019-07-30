#!/usr/bin/env bash

SCRIPT_DIR=$(dirname "${BASH_SOURCE[0]}")

BINARY_NAME=helm
BINARY_PATH=${SCRIPT_DIR}/../../_dist/linux-amd64

# Fail as soon as there is an error
set -e

if [ -z $(which docker) ]; then
  echo "Missing 'docker' client which is required for these tests";
  exit 2;
fi

COMP_DIR=/tmp/completion-tests
COMP_SCRIPT_NAME=completionTests.sh
COMP_SCRIPT=${COMP_DIR}/${COMP_SCRIPT_NAME}
BASH4_IMAGE=completion-bash4
BASH3_IMAGE=completion-bash3
ZSH_IMAGE=completion-zsh

mkdir -p ${COMP_DIR}
cp ${SCRIPT_DIR}/${COMP_SCRIPT_NAME} ${COMP_DIR}
cp ${SCRIPT_DIR}/completionTests-base.sh ${COMP_DIR}
cp ${BINARY_PATH}/${BINARY_NAME} ${COMP_DIR}

########################################
# Bash 4 completion tests
########################################
echo;echo;
docker build -t ${BASH4_IMAGE} - <<- EOF
   FROM bash:4.4
   RUN apk update && apk add bash-completion
EOF
docker run --rm \
           -v ${COMP_DIR}:${COMP_DIR} -v ${COMP_DIR}/${BINARY_NAME}:/bin/${BINARY_NAME} \
           ${BASH4_IMAGE} bash -c "source ${COMP_SCRIPT}"

########################################
# Bash 3.2 completion tests
########################################
# We choose version 3.2 because we want some Bash 3 version and 3.2
# is the version by default on MacOS.  So testing that version
# gives us a bit of coverage for MacOS.
echo;echo;
docker build -t ${BASH3_IMAGE} - <<- EOF
   FROM bash:3.2
   # For bash 3.2, the bash-completion package required is version 1.3
   RUN mkdir /usr/share/bash-completion && \
       wget -qO - https://github.com/scop/bash-completion/archive/1.3.tar.gz | \
            tar xvz -C /usr/share/bash-completion --strip-components 1 bash-completion-1.3/bash_completion
EOF
docker run --rm \
           -v ${COMP_DIR}:${COMP_DIR} -v ${COMP_DIR}/${BINARY_NAME}:/bin/${BINARY_NAME} \
           -e BASH_COMPLETION=/usr/share/bash-completion \
           ${BASH3_IMAGE} bash -c "source ${COMP_SCRIPT}"

########################################
# Zsh completion tests
########################################
echo;echo;
docker build -t ${ZSH_IMAGE} - <<- EOF
   FROM zshusers/zsh:5.7
EOF
docker run --rm \
           -v ${COMP_DIR}:${COMP_DIR} -v ${COMP_DIR}/${BINARY_NAME}:/bin/${BINARY_NAME} \
           ${ZSH_IMAGE} zsh -c "source ${COMP_SCRIPT}"

########################################
# MacOS completion tests
########################################
# Since we can't use Docker to test MacOS,
# we run the MacOS tests locally when possible.
if [ "$(uname)" == "Darwin" ]; then
   # Make sure that for the local tests, the tests will find the newly
   # built binary.  If for some reason the binary to test is not present
   # the tests may use the default binary installed on localhost and we
   # won't be testing the right thing.  So we check here.
   if [ $(PATH=$(pwd)/bin:$PATH which ${BINARY_NAME}) != $(pwd)/bin/${BINARY_NAME} ]; then
      echo "Cannot find ${BINARY_NAME} under $(pwd)/bin/${BINARY_NAME} although it is what we need to test."
      exit 1
   fi

   if [ -f /usr/local/etc/bash_completion ]; then
      echo;echo;
      echo "Completion tests for bash running locally"
      PATH=$(pwd)/bin:$PATH bash -c "source ${COMP_SCRIPT}"
   fi

   echo;echo;
   echo "Completion tests for zsh running locally"
   PATH=$(pwd)/bin:$PATH zsh -c "source ${COMP_SCRIPT}"
fi
