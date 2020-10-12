package completion

import (
	"bytes"
	"fmt"
	"io"

	"github.com/spf13/cobra"
)

// GenFishCompletion generates the Fish completion script
func GenFishCompletion(w io.Writer, includeDesc bool) error {
	compCmd := cobra.ShellCompRequestCmd
	if !includeDesc {
		compCmd = cobra.ShellCompNoDescRequestCmd
	}
	buf := new(bytes.Buffer)
	buf.WriteString(fmt.Sprintf(`# Helm's own fish completion

function __helm_debug
    set file "$BASH_COMP_DEBUG_FILE"
    if test -n "$file"
        echo "$argv" >> $file
    end
end

function __helm_perform_completion
    __helm_debug "Starting __helm_perform_completion"

    set args (string split -- " " (commandline -c))
    set lastArg "$args[-1]"

    __helm_debug "args: $args"
    __helm_debug "last arg: $lastArg"

    set emptyArg ""
    if test -z "$lastArg"
        __helm_debug "Setting emptyArg"
        set emptyArg \"\"
    end
    __helm_debug "emptyArg: $emptyArg"

    if not type -q "$args[1]"
        # This can happen when "complete --do-complete helm" is called when running this script.
        __helm_debug "Cannot find $args[1]. No completions."
        return
    end

    set requestComp "$args[1] %[1]s $args[2..-1] $emptyArg"
    __helm_debug "Calling $requestComp"

    set results (eval $requestComp 2> /dev/null)
    set comps $results[1..-2]
    set directiveLine $results[-1]

    # For Fish, when completing a flag with an = (e.g., <program> -n=<TAB>)
    # completions must be prefixed with the flag
    set flagPrefix (string match -r -- '-.*=' "$lastArg")

    __helm_debug "Comps: $comps"
    __helm_debug "DirectiveLine: $directiveLine"
    __helm_debug "flagPrefix: $flagPrefix"

    for comp in $comps
        printf "%%s%%s\n" "$flagPrefix" "$comp"
    end

    printf "%%s\n" "$directiveLine"
end

# This function does two things:
# - Obtain the completions and store them in the global __helm_comp_results
# - Return false if file completion should be performed
function __helm_prepare_completions
    __helm_debug ""
    __helm_debug "========= starting completion logic =========="

    # Start fresh
    set --erase __helm_comp_results

    set results (__helm_perform_completion)
    __helm_debug "Completion results: $results"

    if test -z "$results"
        __helm_debug "No completion, probably due to a failure"
        # Might as well do file completion, in case it helps
        return 1
    end

    set directive (string sub --start 2 $results[-1])
    set --global __helm_comp_results $results[1..-2]

    __helm_debug "Completions are: $__helm_comp_results"
    __helm_debug "Directive is: $directive"

    set shellCompDirectiveError %[2]d
    set shellCompDirectiveNoSpace %[3]d
    set shellCompDirectiveNoFileComp %[4]d
    set shellCompDirectiveFilterFileExt %[5]d
    set shellCompDirectiveFilterDirs %[6]d

    if test -z "$directive"
        set directive 0
    end

    set compErr (math (math --scale 0 $directive / $shellCompDirectiveError) %% 2)
    if test $compErr -eq 1
        __helm_debug "Received error directive: aborting."
        # Might as well do file completion, in case it helps
        return 1
    end

    set filefilter (math (math --scale 0 $directive / $shellCompDirectiveFilterFileExt) %% 2)
    set dirfilter (math (math --scale 0 $directive / $shellCompDirectiveFilterDirs) %% 2)
    if test $filefilter -eq 1; or test $dirfilter -eq 1
        __helm_debug "File extension filtering or directory filtering not supported"
        # Do full file completion instead
        return 1
    end

    set nospace (math (math --scale 0 $directive / $shellCompDirectiveNoSpace) %% 2)
    set nofiles (math (math --scale 0 $directive / $shellCompDirectiveNoFileComp) %% 2)

    __helm_debug "nospace: $nospace, nofiles: $nofiles"

    # If we want to prevent a space, or if file completion is NOT disabled,
    # we need to count the number of valid completions.
    # To do so, we will filter on prefix as the completions we have received
    # may not already be filtered so as to allow fish to math on different
    # criteria than prefix.
    if test $nospace -ne 0; or test $nofiles -eq 0
        set prefix (commandline -t)
        __helm_debug "prefix: $prefix"

        set completions
        for comp in $__helm_comp_results
            if test (string match -e -r "^$prefix" "$comp")
                set -a completions $comp
            end
        end
        set --global __helm_comp_results $completions
        __helm_debug "Filtered completions are: $__helm_comp_results"

        # Important not to quote the variable for count to work
        set numComps (count $__helm_comp_results)
        __helm_debug "numComps: $numComps"

        if test $numComps -eq 1; and test $nospace -ne 0
            # To support the "nospace" directive we trick the shell
            # by outputting an extra, longer completion.
            # We must first split on \t to get rid of the descriptions because
            # the extra character we add to the fake second completion must be
            # before the description.  We don't need descriptions anyway since
            # there is only a single real completion which the shell will expand
            # immediately.
            __helm_debug "Adding second completion to perform nospace directive"
            set split (string split --max 1 \t $__helm_comp_results[1])
            set --global __helm_comp_results $split[1] $split[1].
            __helm_debug "Completions are now: $__helm_comp_results"
        end

        if test $numComps -eq 0; and test $nofiles -eq 0
            # To be consistent with bash and zsh, we only trigger file
            # completion when there are no other completions
            __helm_debug "Requesting file completion"
            return 1
        end
    end

    return 0
end

# Since Fish completions are only loaded once the user triggers them, we trigger them ourselves
# so we can properly delete any completions provided by another script.
# The space after the the program name is essential to trigger completion for the program
# and not completion of the program name itself.
complete --do-complete "helm " > /dev/null 2>&1
# Using '> /dev/null 2>&1' since '&>' is not supported in older versions of fish.

# Remove any pre-existing completions for the program since we will be handling all of them.
complete -c helm -e

# The call to __helm_prepare_completions will setup __helm_comp_results
# which provides the program's completion choices.
complete -c helm -n '__helm_prepare_completions' -f -a '$__helm_comp_results'
`, compCmd,
		cobra.ShellCompDirectiveError, cobra.ShellCompDirectiveNoSpace, cobra.ShellCompDirectiveNoFileComp,
		cobra.ShellCompDirectiveFilterFileExt, cobra.ShellCompDirectiveFilterDirs))

	_, err := buf.WriteTo(w)
	return err
}
