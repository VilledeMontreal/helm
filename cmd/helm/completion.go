/*
Copyright The Helm Authors.
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

package main

import (
	"fmt"
	"io"
	"os"
	"path/filepath"

	"github.com/pkg/errors"
	"github.com/spf13/cobra"

	"helm.sh/helm/v3/internal/completion"
)

const completionDesc = `
Generate autocompletions script for Helm for the specified shell (bash, zsh or fish).

This command can generate shell autocompletions. e.g.

    $ helm completion bash

Can be sourced as such

    $ source <(helm completion bash)
`

var (
	completionShells = map[string]func(out io.Writer, cmd *cobra.Command) error{
		"bash": runCompletionBash,
		"zsh":  runCompletionZsh,
		"fish": runCompletionFish,
	}
	completionNoDesc bool
)

func newCompletionCmd(out io.Writer) *cobra.Command {
	shells := []string{}
	for s := range completionShells {
		shells = append(shells, s)
	}

	cmd := &cobra.Command{
		Use:   "completion SHELL",
		Short: "Generate autocompletions script for the specified shell (bash, zsh or fish)",
		Long:  completionDesc,
		RunE: func(cmd *cobra.Command, args []string) error {
			return runCompletion(out, cmd, args)
		},
		ValidArgs: shells,
	}
	cmd.PersistentFlags().BoolVar(&completionNoDesc, "no-descriptions", false, "disable completion description for shells that support it")

	return cmd
}

func runCompletion(out io.Writer, cmd *cobra.Command, args []string) error {
	if len(args) == 0 {
		return errors.New("shell not specified")
	}
	if len(args) > 1 {
		return errors.New("too many arguments, expected only the shell type")
	}
	run, found := completionShells[args[0]]
	if !found {
		return errors.Errorf("unsupported shell type %q", args[0])
	}

	return run(out, cmd)
}

func runCompletionBash(out io.Writer, cmd *cobra.Command) error {
	err := cmd.Root().GenBashCompletion(out)

	// In case the user renamed the helm binary (e.g., to be able to run
	// both helm2 and helm3), we hook the new binary name to the completion function
	if binary := filepath.Base(os.Args[0]); binary != "helm" {
		renamedBinaryHook := `
# Hook the command used to generate the completion script
# to the helm completion function to handle the case where
# the user renamed the helm binary
if [[ $(type -t compopt) = "builtin" ]]; then
    complete -o default -F __start_helm %[1]s
else
    complete -o default -o nospace -F __start_helm %[1]s
fi
`
		fmt.Fprintf(out, renamedBinaryHook, binary)
	}

	return err
}

func runCompletionZsh(out io.Writer, cmd *cobra.Command) error {
	err := completion.GenZshCompletion(out, completionNoDesc)

	// In case the user renamed the helm binary (e.g., to be able to run
	// both helm2 and helm3), we hook the new binary name to the completion function
	if binary := filepath.Base(os.Args[0]); binary != "helm" {
		renamedBinaryHook := `
# Hook the command used to generate the completion script
# to the helm completion function to handle the case where
# the user renamed the helm binary
compdef __helm_do_completion %[1]s
`
		fmt.Fprintf(out, renamedBinaryHook, binary)
	}

	return err
}

func runCompletionFish(out io.Writer, cmd *cobra.Command) error {
	err := completion.GenFishCompletion(out, completionNoDesc)

	// In case the user renamed the helm binary (e.g., to be able to run
	// both helm2 and helm3), we hook the new binary name to the completion function
	if binary := filepath.Base(os.Args[0]); binary != "helm" {
		renamedBinaryHook := `
# Hook the binary name used to call the completion command
# to the fish completion functions.  This is to handle the
# case where the user renamed the helm binary
complete -c %[1]s -e
complete -c %[1]s -n 'set --query __helm_comp_do_file_comp'
complete -c %[1]s -n '__helm_comp_prepare' -f -a '$__helm_comp_results'
`
		fmt.Fprintf(out, renamedBinaryHook, binary)
	}

	return err
}
