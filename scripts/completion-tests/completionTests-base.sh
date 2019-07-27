BINARY_NAME=helm
TEST_FAILED=0

_completionTests_init() {
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

   # MUST use a TAB to indent the ending EOF or it won't work
   source /dev/stdin <<- EOF
      $(${BINARY_NAME} completion $SHELL_TYPE)
	EOF
}

# This method must be called at the very end of the application script
_completionTests_end() {
   echo '===================================================='
   return $TEST_FAILED
}

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
       # We need to do the same. We achieve that by re-using the logic of
       # __${BINARY_NAME}_bash_source
       __${BINARY_NAME}_bash_source <(echo "__start_${BINARY_NAME}")
   else
       __start_${BINARY_NAME}
   fi

   echo "${COMPREPLY[@]}"
}

_completionTests_verifyCompletion() {
   local cmdLine="${BINARY_NAME} $1"
   local expected=$2

   result=$(_completionTests_complete "${cmdLine}")

   if [ "$result"  != "$expected" ]; then
      TEST_FAILED=1
      echo "FAIL: \"$cmdLine\" should complete to \"$expected\" but we got \"$result\""
   else
      echo "SUCCESS: \"$cmdLine\" completes to \"$result\""
   fi
}
