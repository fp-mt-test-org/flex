package cmd

import (
	"fmt"

	workflow "devx-workflows/internal/workflow"
	exec "devx-workflows/pkg/exec"

	"github.com/spf13/cobra"
	"github.com/spf13/viper"
)

var rootCmd = &cobra.Command{
	Use:   "flex",
	Short: "Flex for all of your CI/CD needs",
	Long:  `Execute custom workflows for your application with Flex`,
	Args:  cobra.MinimumNArgs(1),
	RunE: func(cmd *cobra.Command, args []string) error {
		execObj := new(exec.Obj)
		return workflow.WorkflowExec(execObj, args[0])
	},
}

// Execute is a cobra requirement to execute our flex root command.
func Execute() error {
	return rootCmd.Execute()
}

func init() {
	viper.SetConfigName("service_config")
	viper.AddConfigPath(".")
	if err := viper.ReadInConfig(); err != nil {
		if _, ok := err.(viper.ConfigFileNotFoundError); ok {
			fmt.Println("Config file not found, use `flex init` to initialize")
		} else {
			panic(fmt.Errorf("fatal error config file: %s", err))
		}
	}
}
