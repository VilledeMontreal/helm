#!bash
#
# Copyright (C) 2019 Ville de Montreal
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

# This script tests different scenarios of completion.  The tests can be
# run by sourcing this file from a bash shell or a zsh shell.

source /tmp/completion-tests/lib/completionTests-base.sh

# Don't use the new source <() form as it does not work with bash v3
source /dev/stdin <<- EOF
   $(helm completion $SHELL_TYPE)
EOF

####################
# Static completion
####################

# No need to test every command, as completion is handled
# automatically by Cobra.
# We focus on some smoke tests for the Cobra-handled completion
# and also on code specific to this project.

# Basic first level commands (static completion)
_completionTests_verifyCompletion "helm stat" "status"
_completionTests_verifyCompletion "helm status" "status"
_completionTests_verifyCompletion "helm lis" "list"
_completionTests_verifyCompletion "helm r" "rollback registry repo"
_completionTests_verifyCompletion "helm re" "registry repo"

# Basic second level commands (static completion)
_completionTests_verifyCompletion "helm get " "hooks manifest values"
_completionTests_verifyCompletion "helm get h" "hooks"
_completionTests_verifyCompletion "helm completion " "bash zsh"
_completionTests_verifyCompletion "helm completion z" "zsh"

# Completion of flags
#_completionTests_verifyCompletion ZFAIL "helm --kube-con" "--kube-context= --kube-context"
#_completionTests_verifyCompletion ZFAIL "helm --kubecon" "--kubeconfig= --kubeconfig"
#_completionTests_verifyCompletion ZFAIL "helm --name" "--namespace= --namespace"
_completionTests_verifyCompletion "helm -v" "-v"
#_completionTests_verifyCompletion ZFAIL "helm --v" "--v= --vmodule= --v --vmodule"

# Completion of commands while using flags
_completionTests_verifyCompletion "helm --kube-context prod sta" "status"
_completionTests_verifyCompletion "helm --namespace mynamespace get h" "hooks"
#_completionTests_verifyCompletion KFAIL "helm -v get " "hooks manifest values"
#_completionTests_verifyCompletion ZFAIL "helm --kubeconfig=/tmp/config lis" "list"
#_completionTests_verifyCompletion ZFAIL "helm ---namespace mynamespace get " "hooks manifest values"
#_completionTests_verifyCompletion ZFAIL "helm get --name" "--namespace= --namespace"
#_completionTests_verifyCompletion ZFAIL "helm get hooks --kubec" "--kubeconfig= --kubeconfig"

# Alias completion
# Does not work.
#_completionTests_verifyCompletion KFAIL "helm ls" "ls"
#_completionTests_verifyCompletion KFAIL "helm dependenci" "dependencies"

#####################
# Dynamic completion
#####################
#
# Completion of a single release
_completionTests_verifyCompletion "helm status rel306" "rel306"

# Completion of multiple releases with a prefix
prefix="rel10"
result="$prefix"
for i in {0..9}; do
   result+=" $prefix$i"
   for j in {0..9}; do
      result+=" $prefix$i$j"
   done
done
_completionTests_verifyCompletion "helm status $prefix" "$result"

# Completion of multiple releases without prefix
result="rel1"
# Releases 0 to the limit used in the completion logic (1000)
for i in 1; do
   for j in {0..8}; do
      result+=" rel$i$j"
      for k in {0..9}; do
         result+=" rel$i$j$k"
         for l in {0..9}; do
            result+=" rel$i$j$k$l"
         done
      done
   done
done
_completionTests_verifyCompletion "helm status " "$result"

# Completion of a single release for all other commands that take
# a release as a parameter
_completionTests_verifyCompletion "helm uninstall rel2345" "rel2345"
_completionTests_verifyCompletion "helm history rel2345" "rel2345"
_completionTests_verifyCompletion "helm test run rel2345" "rel2345"
_completionTests_verifyCompletion "helm upgrade rel2345" "rel2345"
_completionTests_verifyCompletion "helm rollback rel2345" "rel2345"

# Completion of a release that does not exist
_completionTests_verifyCompletion "helm status WRONG" ""

# helm_get_*
