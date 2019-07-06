#!/bin/sh

set -e

if [ -z $(which docker) ]; then
  echo "Missing 'docker' client which is required for this step";
  exit 2;
fi

COMP_DIR=/tmp/helm-tests
COMP_SCRIPT=run-tests.sh
BASH4_IMAGE=helm-bash4
ZSH_IMAGE=helm-zsh

mkdir -p ${COMP_DIR}
cp scripts/completion-tests/${COMP_SCRIPT} ${COMP_DIR}
cp _dist/linux-amd64/helm ${COMP_DIR}

# Bash 4 completion tests
docker build -t ${BASH4_IMAGE} - <<- EOF
   FROM bash:4.4
   RUN apk update && apk add bash-completion
EOF
echo
echo
echo "==========================================="
echo "Completion tests for bash 4.4 using Docker:"
echo "==========================================="
docker run --rm \
           -v ${COMP_DIR}:${COMP_DIR} -v ${COMP_DIR}/helm:/bin/helm \
           ${BASH4_IMAGE} bash -c "source ${COMP_DIR}/${COMP_SCRIPT}"
echo "==========================================="

# Zsh completion tests
docker build -t ${ZSH_IMAGE} - <<- EOF
   FROM zshusers/zsh:5.7
EOF
echo
echo
echo "=========================================="
echo "Completion tests for zsh 5.7 using Docker:"
echo "=========================================="
docker run --rm \
           -v ${COMP_DIR}:${COMP_DIR} -v ${COMP_DIR}/helm:/bin/helm \
           ${ZSH_IMAGE} zsh -c "source ${COMP_DIR}/${COMP_SCRIPT}"
echo "==========================================="

#if [ "$(uname)" == "Darwin" ]; then \
#   echo "=========================================="; \
#   echo "Completion tests for bash running locally:"; \
#   echo "=========================================="; \
#   PATH=${BINDIR}:$$PATH /bin/bash -c ${COMP_SCRIPT}; \
#   echo "Completion tests for zsh running locally:"; \
#   zsh -c ${COMP_SCRIPT}; \
#fi
