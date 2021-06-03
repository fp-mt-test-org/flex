package cmd

import (
	"fmt"
	"io"
	"os"

	workflow "devx-workflows/internal/workflow"

	"github.com/spf13/cobra"
)

func init() {
	rootCmd.AddCommand(listCmd)
}

var listCmd = &cobra.Command{
	Use:   "list",
	Short: "List workflows specified by user",
	Long:  `Reads config from service_config.yml to list user defined workflows`,
	RunE: func(cmd *cobra.Command, args []string) error {
		return list(os.Stdout)
	},
}

func list(out io.Writer) error {
	workflowDefList, err := workflow.GetWorkflowDefList()
	if err != nil {
		return err
	}
	if len(workflowDefList) == 0 {
		return fmt.Errorf("no commands specified in service_config.yml; `flex init` before running this command")
	}

	fmt.Fprintln(out, "List of commands:")
	for key, el := range workflowDefList {
		fmt.Fprintf(out, "  %s: %s\n", key, el.Command)
	}
	return nil
}
