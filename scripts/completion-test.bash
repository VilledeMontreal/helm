#!/usr/bin/env bash

# Copyright The Helm Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# This script can be used to obtain the completion output of the helm
# completion script

completionFunction="__start_helm"

usage() {
    echo "Usage:"
    echo "    $0 <completionScriptLocation> <shellCommandLineToComplete>"
    echo "    e.g.,"
    echo "    helm completion bash > /tmp/helm_completion.bash && \\"
    echo "         scripts/completion-test.bash /tmp/helm_completion.bash \"helm li\""
}

if [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
    usage
    exit 0
fi

# Allow for debug printouts when running the script by hand
if [ "$1" == "-d" ] || [ "$1" == "--debug" ]; then
    debug=true
    shift
fi

# Full shell debugging printouts
if [ "$1" == "-D" ]; then
    set -x
    shift
fi

if [ $# != 2 ]; then
    echo "Error: only 2 parameters are expected."
    usage
    exit 1
fi

completionScript=$1
commandLineToComplete=$2

bashCompletionScript="/usr/share/bash-completion/bash_completion"
if [[ $(uname) == "Darwin" ]]; then
  bashCompletionScript="/usr/local/etc/bash_completion"
fi

if [ ! -e $bashCompletionScript ]; then
    echo "You must install bash completion on your computer before using this script."
    exit 1
fi
source ${bashCompletionScript}

if [ ! -e ${completionScript} ]; then
    echo "Error: specified completion script cannot be found: ${completionScript}"
    exit 1
fi
source ${completionScript}

if [ "${debug}" == "true" ]; then
    echo =====================================
    echo $0 called towards $completionFunction from $completionScript
    echo with command to complete: $commandLineToComplete
fi

# Set the bash completion variables
COMP_LINE=${commandLineToComplete}
COMP_POINT=${#COMP_LINE}
# 9 is TAB
COMP_TYPE=9
COMP_KEY=9
COMP_WORDS=(${commandLineToComplete})

# We must check for a space as the last character which will
# tell us that the previous word is complete and the cursor
# is on the next word.
if [ "${commandLineToComplete: -1}" == " " ]; then
	# The last character is a space, so our location is at the end
	# of the command-line array
	COMP_CWORD=${#COMP_WORDS[@]}
else
	# The last character is not a space, so our location is on the
	# last word of the command-line array, so we must decrement the
	# count by 1
	COMP_CWORD=$((${#COMP_WORDS[@]}-1))
fi

# Call the helm completion command
${completionFunction}

if [ "${debug}" == "true" ]; then
    echo =====================================
    echo $0 returned:
fi
echo "${COMPREPLY[@]}"
