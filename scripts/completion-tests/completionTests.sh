source /tmp/completion-tests/completionTests-base.sh

# Don't use the new source <() form as it does
# not work with bash v3
source /dev/stdin <<- EOF
   $(helm completion $SHELL_TYPE)
EOF

# No need to test every command as completion is handled
# automatically by Cobra.
# We focus on some smoke tests for the Cobra-handled completion
# and also on code specific to this project.

# Basic first level commands (static completion)
_completionTests_verifyCompletion "helm stat" "status"
_completionTests_verifyCompletion "helm status" "status"
_completionTests_verifyCompletion "helm lis" "list"
_completionTests_verifyCompletion "helm r" "registry repo rollback"
_completionTests_verifyCompletion "helm re" "registry repo"

# Basic second level commands (static completion)
_completionTests_verifyCompletion "helm get " "hooks manifest values"
_completionTests_verifyCompletion "helm get h" "hooks"
_completionTests_verifyCompletion "helm completion " "bash zsh"
_completionTests_verifyCompletion "helm completion z" "zsh"

# Completion of flags
# Currently failing for zsh
if [ $SHELL_TYPE = bash ]; then
   _completionTests_verifyCompletion "helm --kube-con" "--kube-context= --kube-context"
   _completionTests_verifyCompletion "helm --kubecon" "--kubeconfig= --kubeconfig"
   _completionTests_verifyCompletion "helm --name" "--namespace= --namespace"
   _completionTests_verifyCompletion "helm -v" "-v"
   _completionTests_verifyCompletion "helm --v" "--v= --vmodule= --v --vmodule"
fi

# Completion of commands while using flags
_completionTests_verifyCompletion "helm --kube-context prod sta" "status"
_completionTests_verifyCompletion "helm --namespace mynamespace get h" "hooks"
_completionTests_verifyCompletion KFAIL "helm -v get " "hooks manifest values"
if [ $SHELL_TYPE = bash ]; then
   _completionTests_verifyCompletion "helm --kubeconfig=/tmp/config lis" "list"
   _completionTests_verifyCompletion "helm ---namespace mynamespace get " "hooks manifest values"
   _completionTests_verifyCompletion "helm get --name" "--namespace= --namespace"
   _completionTests_verifyCompletion "helm get hooks --kubec" "--kubeconfig= --kubeconfig"
fi

# Alias completion
# Does not work.
_completionTests_verifyCompletion KFAIL "helm ls" "ls"
_completionTests_verifyCompletion KFAIL "helm dependenci" "dependencies"


