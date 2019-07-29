
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
   SHELL_TYPE=zsh

   echo "===================================================="
   echo "Running completions tests on $(uname) with zsh $ZSH_VERSION"
   echo "===================================================="
   autoload -Uz compinit
   compinit
fi

_completionTests_complete() {
   local cmdLine=$1

   # Set the bash completion variables which are
   # used for both bash and zsh completion
   COMP_LINE=${cmdLine}
   COMP_POINT=${#COMP_LINE}
   COMP_TYPE=9 # 9 is TAB
   COMP_KEY=9  # 9 is TAB
   COMP_WORDS=($(echo ${cmdLine}))

   COMP_CWORD=$((${#COMP_WORDS[@]}-1))
   # We must check for a space as the last character which will tell us
   # that the previous word is complete and the cursor is on the next word.
   [ "${cmdLine: -1}" = " " ] && COMP_CWORD=${#COMP_WORDS[@]}

   if [ $SHELL_TYPE = "zsh" ]; then
       # When zsh calls real completion, it sets some options and emulates sh.
       # We need to do the same.
       emulate -L sh
       setopt kshglob noshglob braceexpand
    fi

    __start_helm

    echo "${COMPREPLY[@]}"
}

# Global variable to keep track of if a test has failed.
_completionTests_TEST_FAILED=0

# Run completion and indicate success or failure.
#    $1 is the command line that should be completed
#    $2 is the expected result of the completion
# If $1 == KFAIL this test will be skipped
_completionTests_verifyCompletion() {
   local skip=0
   if [ "$1" = "KFAIL" ]; then
      skip=1
      shift
   fi

   local cmdLine=$1
   local expected=$2

   result=$(_completionTests_complete "${cmdLine}")

   if [ "$result"  = "$expected" ]; then
      echo "SUCCESS: \"$cmdLine\" completes to \"$result\""
   elif [ $skip -eq 1 ]; then
      echo "KFAIL: \"$cmdLine\" should complete to \"$expected\" but we got \"$result\""
   else
      _completionTests_TEST_FAILED=1
      echo "FAIL: \"$cmdLine\" should complete to \"$expected\" but we got \"$result\""
   fi

   # Return the global result each time.  This allows for the very last call to
   # this method to return the correct success or failure code for the entire script
   return $_completionTests_TEST_FAILED
}
