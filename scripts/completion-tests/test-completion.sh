#!/bin/sh

set -e

if [ -z $(which docker) ]; then
  echo "Missing 'docker' client which is required for these tests";
  exit 2;
fi

COMP_DIR=/tmp/helm-tests
COMP_SCRIPT=run-tests.sh
BASH4_IMAGE=helm-bash4
BASH3_IMAGE=helm-bash3
ZSH_IMAGE=helm-zsh

mkdir -p ${COMP_DIR}
cp scripts/completion-tests/${COMP_SCRIPT} ${COMP_DIR}
cp _dist/linux-amd64/helm ${COMP_DIR}

# Bash 4 completion tests
docker build -t ${BASH4_IMAGE} - <<- EOF
   FROM bash:4.4
   RUN apk update && apk add bash-completion
EOF
docker run --rm \
           -v ${COMP_DIR}:${COMP_DIR} -v ${COMP_DIR}/helm:/bin/helm \
           ${BASH4_IMAGE} bash -c "source ${COMP_DIR}/${COMP_SCRIPT}"

# Bash 3.2 (that is the version by default on MacOS) completion tests
docker build -t ${BASH3_IMAGE} - <<- EOF
   FROM bash:3.2
   # For bash 3.2, the bash-completion package required is version 1.3
   RUN mkdir /usr/share/bash-completion && \
       wget -qO - https://github.com/scop/bash-completion/archive/1.3.tar.gz | \
            tar xvz -C /usr/share/bash-completion --strip-components 1 bash-completion-1.3/bash_completion
EOF
docker run --rm \
           -v ${COMP_DIR}:${COMP_DIR} -v ${COMP_DIR}/helm:/bin/helm \
           ${BASH3_IMAGE} bash -c "source ${COMP_DIR}/${COMP_SCRIPT}"

# Zsh completion tests
docker build -t ${ZSH_IMAGE} - <<- EOF
   FROM zshusers/zsh:5.7
EOF
docker run --rm \
           -v ${COMP_DIR}:${COMP_DIR} -v ${COMP_DIR}/helm:/bin/helm \
           ${ZSH_IMAGE} zsh -c "source ${COMP_DIR}/${COMP_SCRIPT}"

if [ "$(uname)" == "Darwin" ]; then
   if [ -f /usr/local/etc/bash_completion ]; then
      echo "Completion tests for bash running locally"
      PATH=$(pwd)/bin:$PATH bash -c "source ${COMP_DIR}/${COMP_SCRIPT}"
   fi

   echo "Completion tests for zsh running locally"
   PATH=$(pwd)/bin:$PATH zsh -c "source ${COMP_DIR}/${COMP_SCRIPT}"
fi
