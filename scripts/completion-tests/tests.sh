# No need to test every command as completion is handled
# automatically by Cobra.
# We focus on some smoke tests for the Cobra-handled completion
# and also on code specific to this project.

# Basic first level commands (static completion)
_completionTests_verifyCompletion "stat" "status"
_completionTests_verifyCompletion "status" "status"
_completionTests_verifyCompletion "lis" "list"
_completionTests_verifyCompletion "r" "registry repo rollback"
_completionTests_verifyCompletion "re" "registry repo"

# Basic second level commands (static completion)
_completionTests_verifyCompletion "get " "hooks manifest values"
_completionTests_verifyCompletion "get h" "hooks"
_completionTests_verifyCompletion "completion " "bash zsh"
_completionTests_verifyCompletion "completion z" "zsh"

# Completion of flags
_completionTests_verifyCompletion "--kube-con" "--kube-context= --kube-context"
_completionTests_verifyCompletion "--kubecon" "--kubeconfig= --kubeconfig"
_completionTests_verifyCompletion "--name" "--namespace= --namespace"
_completionTests_verifyCompletion "-v" "-v"
_completionTests_verifyCompletion "--v" "--v= --vmodule= --v --vmodule"

# Completion of commands while using flags
#_completionTests_verifyCompletion "--kube-context prod sta" "status"
#_completionTests_verifyCompletion "--kubeconfig=/tmp/config lis" "list"
#_completionTests_verifyCompletion "--namespace mynamespace get h" "hooks"
#_completionTests_verifyCompletion "-v get " "hooks manifest values"
#_completionTests_verifyCompletion "---namespace mynamespace get " "hooks manifest values"
#_completionTests_verifyCompletion "get --name" "--namespace= --namespace"
#_completionTests_verifyCompletion "get hooks --kubec" "--kubeconfig= --kubeconfig"

# Alias completion
# Does not work.
#_completionTests_verifyCompletion "ls" "ls"
#_completionTests_verifyCompletion "dependenci" "dependencies"

# Output of a single release
# result := "rel206"
# _completionTests_verifyCompletion "status rel206" result

# // Output of multiple releases with prefix
# result = "rel1"
# for i := 0; i < 10; i++ {
# 	result += fmt.Sprintf(" rel1%d", i)
# 	for j := 0; j < 10; j++ {
# 		result += fmt.Sprintf(" rel1%d%d", i, j)
# 	}
# }
# _completionTests_verifyCompletion "status rel1" ${result}
#
# // Output of multiple releases without prefix
# result = "rel0"
# // Releases 1 to the limit used in the completion logic (1000)
# for i := 1; i < 30; i++ {
# 	result += fmt.Sprintf(" rel%d", i)
# 	for j := 0; j < 10; j++ {
# 		result += fmt.Sprintf(" rel1%d%d", i, j)
# 	}
# }
# _completionTests_verifyCompletion "status " ${result}
