TEST_FAILED=0

_helm_test_runCompletionTests() {

   # No need to test every command as completion is handled
   # automatically by Cobra.
   # We focus on some smoke tests for the Cobra-handled completion
   # and on helm-specific features.

   # Basic first level commands (static completion)
   _helm_test_verifyCompletion "stat" "status"
   _helm_test_verifyCompletion "status" "status"
   _helm_test_verifyCompletion "lis" "list"
   _helm_test_verifyCompletion "r" "registry repo rollback"
   _helm_test_verifyCompletion "re" "registry repo"

   # Basic second level commands (static completion)
   _helm_test_verifyCompletion "get " "hooks manifest values"
   _helm_test_verifyCompletion "get h" "hooks"
   _helm_test_verifyCompletion "completion " "bash zsh"
   _helm_test_verifyCompletion "completion z" "zsh"

   # Alias completion
   # Does not work.
   #_helm_test_verifyCompletion "ls" "ls"
   #_helm_test_verifyCompletion "dependenci" "dependencies"

   # Output of a single release
# result := "rel206"
# _helm_test_verifyCompletion "status rel206" result

# // Output of multiple releases with prefix
# result = "rel1"
# for i := 0; i < 10; i++ {
# 	result += fmt.Sprintf(" rel1%d", i)
# 	for j := 0; j < 10; j++ {
# 		result += fmt.Sprintf(" rel1%d%d", i, j)
# 	}
# }
# _helm_test_verifyCompletion "status rel1" ${result}
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
# _helm_test_verifyCompletion "status " ${result}

}

_helm_test_complete() {
   local cmdLine=$1

   # Set the bash completion variables
   COMP_LINE=${cmdLine}
   COMP_POINT=${#COMP_LINE}
   COMP_TYPE=9 # 9 is TAB
   COMP_KEY=9  # 9 is TAB
   COMP_WORDS=(${cmdLine})

   COMP_CWORD=$((${#COMP_WORDS[@]}-1))
   # We must check for a space as the last character which will tell us
   # that the previous word is complete and the cursor is on the next word.
   [ "${cmdLine: -1}" = " " ] && COMP_CWORD=${#COMP_WORDS[@]}

   __start_helm

   echo "${COMPREPLY[@]}"
}

_helm_test_verifyCompletion() {
   local cmdLine="helm $1"
   local expected=$2

   result=$(_helm_test_complete "${cmdLine}")

   if [ "$result"  != "$expected" ]; then
      TEST_FAILED=1
      echo "FAIL: \"$cmdLine\" should complete to \"$expected\" but we got \"$result\""
   else
      echo "SUCCESS: \"$cmdLine\" completes to \"$result\""
   fi
}

SHELL_TYPE=bash
if [ ! -z "$BASH_VERSION" ];then
   echo "===================================================="
   echo "Running completions tests on $(uname) with bash $BASH_VERSION"
   echo "===================================================="

   bashCompletionScript="/usr/share/bash-completion/bash_completion"
   if [ $(uname) = "Darwin" ]; then
      bashCompletionScript="/usr/local/etc/bash_completion"
   fi

   source ${bashCompletionScript}
else
   echo "===================================================="
   echo "Running completions tests on $(uname) with zsh $BASH_VERSION"
   echo "===================================================="
   autoload -Uz compinit
   compinit
   SHELL_TYPE=zsh
fi

source /dev/stdin <<- EOF
   $(helm completion $SHELL_TYPE)
EOF

_helm_test_runCompletionTests

echo "===================================================="

exit $TEST_FAILED
