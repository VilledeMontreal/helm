package completion

import (
	"bytes"
	"fmt"
	"io"

	"github.com/spf13/cobra"
)

// GenBashCompletion generates the bash completion script
func GenBashCompletion(w io.Writer, includeDesc bool) error {
	compCmd := cobra.ShellCompRequestCmd
	if !includeDesc {
		compCmd = cobra.ShellCompNoDescRequestCmd
	}
	buf := new(bytes.Buffer)
	buf.WriteString(fmt.Sprintf(`# Helm's own bash completion

__helm_debug()
{
    if [[ -n ${BASH_COMP_DEBUG_FILE:-} ]]; then
        echo "$*" >> "${BASH_COMP_DEBUG_FILE}"
    fi
}

# Macs have bash3 for which the bash-completion package doesn't include
# _init_completion. This is a minimal version of that function.
__helm_init_completion()
{
    COMPREPLY=()
    _get_comp_words_by_ref "$@" cur prev words cword
}

# This function calls the helm program to obtain the completion
# results and the directive.  It fills the 'out' and 'directive' vars.
__helm_get_completion_results() {
    local requestComp lastParam lastChar args

    # Prepare the command to request completions for the program.
    # Calling ${words[0]} instead of directly helm allows to handle aliases
    args=("${words[@]:1}")
    requestComp="${words[0]} %[1]s ${args[*]}"

    lastParam=${words[$((${#words[@]}-1))]}
    lastChar=${lastParam:$((${#lastParam}-1)):1}
    __helm_debug "lastParam ${lastParam}, lastChar ${lastChar}"

    if [ -z "${cur}" ] && [ "${lastChar}" != "=" ]; then
        # If the last parameter is complete (there is a space following it)
        # We add an extra empty parameter so we can indicate this to the go method.
        __helm_debug "Adding extra empty parameter"
        requestComp="${requestComp} ''"
    fi

    # When completing a flag with an = (e.g., helm -n=<TAB>)
    # bash focuses on the part after the =, so we need to remove
    # the flag part from $cur
    if [[ "${cur}" == -*=* ]]; then
        cur="${cur#*=}"
    fi

    __helm_debug "Calling ${requestComp}"
    # Use eval to handle any environment variables and such
    out=$(eval "${requestComp}" 2>/dev/null)

    # Extract the directive integer at the very end of the output following a colon (:)
    directive=${out##*:}
    # Remove the directive
    out=${out%%:*}
    if [ "${directive}" = "${out}" ]; then
        # There is not directive specified
        directive=0
    fi
    __helm_debug "The completion directive is: ${directive}"
    __helm_debug "The completions are: ${out[*]}"
}

__helm_process_completion_results() {
    local shellCompDirectiveError=%[2]d
    local shellCompDirectiveNoSpace=%[3]d
    local shellCompDirectiveNoFileComp=%[4]d
    local shellCompDirectiveFilterFileExt=%[5]d
    local shellCompDirectiveFilterDirs=%[6]d

    if [ $((directive & shellCompDirectiveError)) -ne 0 ]; then
        # Error code.  No completion.
        __helm_debug "Received error from custom completion go code"
        return
    else
        if [ $((directive & shellCompDirectiveNoSpace)) -ne 0 ]; then
            if [[ $(type -t compopt) = "builtin" ]]; then
                __helm_debug "Activating no space"
                compopt -o nospace
            else
                __helm_debug "No space directive not supported in this version of bash"
            fi
        fi
        if [ $((directive & shellCompDirectiveNoFileComp)) -ne 0 ]; then
            if [[ $(type -t compopt) = "builtin" ]]; then
                __helm_debug "Activating no file completion"
                compopt +o default
            else
                __helm_debug "No file completion directive not supported in this version of bash"
            fi
        fi
    fi

    if [ $((directive & shellCompDirectiveFilterFileExt)) -ne 0 ]; then
        # File extension filtering
        local fullFilter filter filteringCmd

        # Do not use quotes around the $out variable or else newline
        # characters will be kept.
        for filter in ${out[*]}; do
            fullFilter+="$filter|"
        done

        filteringCmd="_filedir $fullFilter"
        __helm_debug "File filtering command: $filteringCmd"
        $filteringCmd
    elif [ $((directive & shellCompDirectiveFilterDirs)) -ne 0 ]; then
        # File completion for directories only

        # Use printf to strip any trailing newline
        local subdir
        subdir=$(printf "%%s" "${out[0]}")
        if [ -n "$subdir" ]; then
            __helm_debug "Listing directories in $subdir"
            pushd "$subdir" >/dev/null 2>&1 && _filedir -d && popd >/dev/null 2>&1 || return
        else
            __helm_debug "Listing directories in ."
            _filedir -d
        fi
    else
        local completions=()
        local infos=()
        __helm_extract_infos

        __helm_handle_standard_completion_case
    fi

    __helm_handle_special_char "$cur" :
    __helm_handle_special_char "$cur" =

    # Print the info statements before we finish
    if [ ${#infos} -ne 0 ]; then
        printf "\n";
        printf "%%s\n" "${infos[@]}"
        printf "\n"
        # This needs bash 4.4
        printf "%%s" "${PS1@P}${COMP_LINE[@]}"
    fi
}

# Separate info lines from real completions.
# Fills the $info and $completions arrays.
__helm_extract_infos() {
    local compInfoMarker="%[7]s"
    local endIndex=${#compInfoMarker}

    while IFS='' read -r comp; do
        if [ "${comp:0:endIndex}" = "$compInfoMarker" ]; then
            comp=${comp:endIndex}
            __helm_debug "Info statement found: $comp"
            if [ -n "$comp" ]; then
                infos+=("$comp")
            fi
        else
            # Not an info line but a normal completion
            completions+=("$comp")
        fi
    done < <(printf "%%s\n" "${out[@]}")
}

__helm_handle_standard_completion_case() {
    local tab comp
    tab=$(printf '\t')

    local longest=0
    # Look for the longest completion so that we can format things nicely
    while IFS='' read -r comp; do
        # Strip any description before checking the length
        comp=${comp%%%%$tab*}
        # Only consider the completions that match
        comp=$(compgen -W "$comp" -- "$cur")
        if ((${#comp}>longest)); then
            longest=${#comp}
        fi
    done < <(printf "%%s\n" "${completions[@]}")

    local finalcomps=()
    while IFS='' read -r comp; do
        if [ -z "$comp" ]; then
            continue
        fi

        __helm_debug "Original comp: $comp"
        comp="$(__helm_format_comp_descriptions "$comp" "$longest")"
        __helm_debug "Final comp: $comp"
        finalcomps+=("$comp")
    done < <(printf "%%s\n" "${completions[@]}")

    # Filter completions on the prefix the user specified ($cur)
    # We do this here because we need to have already escaped any
    # special characters of descriptions with __helm_format_comp_descriptions
    while IFS='' read -r comp; do
        COMPREPLY+=("$comp")
    done < <(compgen -W "${finalcomps[*]}" -- "$cur")

    # If there is a single completion left, remove the description text
    if [ ${#COMPREPLY[*]} -eq 1 ]; then
        __helm_debug "COMPREPLY[0]: ${COMPREPLY[0]}"
        comp="${COMPREPLY[0]%%%% *}"
        __helm_debug "Removed description from single completion, which is now: ${comp}"
        COMPREPLY=()
        COMPREPLY+=("$comp")
    fi
}

__helm_handle_special_char()
{
    local comp="$1"
    local char=$2
    if [[ "$comp" == *${char}* && "$COMP_WORDBREAKS" == *${char}* ]]; then
        local word=${comp%%"${comp##*${char}}"}
        local idx=${#COMPREPLY[*]}
        while [[ $((--idx)) -ge 0 ]]; do
            COMPREPLY[$idx]=${COMPREPLY[$idx]#"$word"}
        done
    fi
}

__helm_format_comp_descriptions()
{
    local tab
    tab=$(printf '\t')
    local comp="$1"
    local longest=$2

    # Properly format the description string which follows a tab character if there is one
    if [[ "$comp" == *$tab* ]]; then
        desc=${comp#*$tab}
        comp=${comp%%%%$tab*}

        # $COLUMNS stores the current shell width.
        # Remove an extra 4 because we add 2 spaces and 2 parentheses.
        maxdesclength=$(( COLUMNS - longest - 4 ))

        # Make sure we can fit a description of at least 8 characters
        # if we are to align the descriptions.
        if [[ $maxdesclength -gt 8 ]]; then
            # Add the proper number of spaces to align the descriptions
            for ((i = ${#comp} ; i < longest ; i++)); do
                comp+=" "
            done
        else
            # Don't pad the descriptions so we can fit more text after the completion
            maxdesclength=$(( COLUMNS - ${#comp} - 4 ))
        fi

        # If there is enough space for any description text,
        # truncate the descriptions that are too long for the shell width
        if [ $maxdesclength -gt 0 ]; then
            if [ ${#desc} -gt $maxdesclength ]; then
                desc=${desc:0:$(( maxdesclength - 1 ))}
                desc+="…"
            fi
            comp+="  ($desc)"
        fi
    fi

    # Must use printf to escape all special characters
    printf "%%q" "${comp}"
}

__start_helm()
{
    local cur prev words cword

    COMPREPLY=()

    # Call _init_completion from the bash-completion package
    # to prepare the arguments properly
    if declare -F _init_completion >/dev/null 2>&1; then
        _init_completion -n "=:" || return
    else
        __helm_init_completion -n "=:" || return
    fi

    __helm_debug
    __helm_debug "========= starting completion logic =========="
    __helm_debug "cur is ${cur}, words[*] is ${words[*]}, #words[@] is ${#words[@]}, cword is $cword"

    # The user could have moved the cursor backwards on the command-line.
    # We need to trigger completion from the $cword location, so we need
    # to truncate the command-line ($words) up to the $cword location.
    words=("${words[@]:0:$cword+1}")
    __helm_debug "Truncated words[*]: ${words[*]},"

    local out directive
    __helm_get_completion_results
    __helm_process_completion_results
}

if [[ $(type -t compopt) = "builtin" ]]; then
    complete -o default -F __start_helm helm
else
    complete -o default -o nospace -F __start_helm helm
fi

# ex: ts=4 sw=4 et filetype=sh
`, compCmd,
		cobra.ShellCompDirectiveError, cobra.ShellCompDirectiveNoSpace, cobra.ShellCompDirectiveNoFileComp,
		cobra.ShellCompDirectiveFilterFileExt, cobra.ShellCompDirectiveFilterDirs, compInfoMarker))

	_, err := buf.WriteTo(w)
	return err
}
