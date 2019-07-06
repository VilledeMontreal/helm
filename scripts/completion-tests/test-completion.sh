#!/bin/sh

set -e

if [ -z $(which docker) ]; then
  echo "Missing 'docker' client which is required for this step";
  exit 2;
fi

COMP_DIR=/tmp/helm-tests
COMP_SCRIPT=run-tests.sh
BASH4_IMAGE=helm-bash4
BASH3_IMAGE=helm-bash3
ZSH_IMAGE=helm-zsh

mkdir -p ${COMP_DIR}
cp scripts/completion-tests/${COMP_SCRIPT} ${COMP_DIR}
cp scripts/completion-tests/bash_completion-3.2 ${COMP_DIR}
cp _dist/linux-amd64/helm ${COMP_DIR}

# Bash 4 completion tests
docker build -t ${BASH4_IMAGE} - <<- EOF
   FROM bash:4.4
   RUN apk update && apk add bash-completion
EOF
docker run --rm \
           -v ${COMP_DIR}:${COMP_DIR} -v ${COMP_DIR}/helm:/bin/helm \
           ${BASH4_IMAGE} bash -c "source ${COMP_DIR}/${COMP_SCRIPT}"

# Bash 3.2 (MacOS version) completion tests
docker build -t ${BASH3_IMAGE} - <<- EOF
   FROM bash:3.2
EOF
docker run --rm \
           -v ${COMP_DIR}:${COMP_DIR} -v ${COMP_DIR}/helm:/bin/helm \
           -v ${COMP_DIR}/bash_completion-3.2:/usr/share/bash-completion/bash_completion \
           ${BASH3_IMAGE} bash -c "source ${COMP_DIR}/${COMP_SCRIPT}"

# Zsh completion tests
docker build -t ${ZSH_IMAGE} - <<- EOF
   FROM zshusers/zsh:5.7
EOF
docker run --rm \
           -v ${COMP_DIR}:${COMP_DIR} -v ${COMP_DIR}/helm:/bin/helm \
           ${ZSH_IMAGE} zsh -c "source ${COMP_DIR}/${COMP_SCRIPT}"

#if [ "$(uname)" == "Darwin" ]; then \
#   PATH=${BINDIR}:$$PATH /bin/bash -c ${COMP_SCRIPT}; \
#   echo "Completion tests for zsh running locally:"; \
#   zsh -c ${COMP_SCRIPT}; \
#fi
