package workflow

import (
	"fmt"

	exec "devx-workflows/pkg/exec"

	"github.com/spf13/viper"
)

type WorkflowDef struct {
	Command   string
	Env       []string
	DependsOn []string `mapstructure:"depends-on"`
}

const WorkflowKey = "flex.workflows"

// Executes a workflow given the workflow's name
// Returns an error if the workflow could not be found
func WorkflowExec(execObj exec.E, workflowName string) error {
	workflowDefList, err := GetWorkflowDefList()
	if err != nil {
		return err
	}

	workflowDef, err := getWorkflowDefByName(workflowName, workflowDefList)
	workflowsToExecute := []WorkflowDef{}
	if err != nil {
		return err
	}

	for _, dependency := range workflowDef.DependsOn {
		dependencyDef, err := getWorkflowDefByName(dependency, workflowDefList)
		if err != nil {
			return err
		}
		workflowsToExecute = append(workflowsToExecute, dependencyDef)
	}
	workflowsToExecute = append(workflowsToExecute, workflowDef)

	for _, workflow := range workflowsToExecute {
		if len(workflow.Command) > 0 {
			err = execObj.ExecFn(workflow.Command, workflow.Env...)
		}
		if err != nil {
			return err
		}
	}
	return nil
}

func getWorkflowDefByName(workflowName string, workflowDefList map[string]WorkflowDef) (WorkflowDef, error) {
	workflow, exists := workflowDefList[workflowName]
	if !exists {
		return WorkflowDef{}, fmt.Errorf("could not find workflow definition for %s; run `flex list` for a list of available workflows", workflowName)
	}
	return workflow, nil
}

var resolvedDependencies map[string][]string

// Returns a map of workflow name -> workflow definition, traversing dependencies
// Returns an error for undefined/circular dependencies
func GetWorkflowDefList() (map[string]WorkflowDef, error) {
	var defList map[string]WorkflowDef
	if err := viper.UnmarshalKey(WorkflowKey, &defList); err != nil {
		return nil, fmt.Errorf("error unmarshalling cmd definition in service_config.yml: %s", err)
	}

	var visited map[string]bool
	resolvedDependencies = map[string][]string{}
	for name, workflowDef := range defList {
		visited = map[string]bool{}
		dependencies, err := getDependencies(name, workflowDef, visited, defList)
		if err != nil {
			return nil, err
		}
		newDepList := defList[name]
		newDepList.DependsOn = dependencies
		defList[name] = newDepList
	}
	return defList, nil
}

func getDependencies(workflowName string, workflowDef WorkflowDef, visited map[string]bool, defList map[string]WorkflowDef) ([]string, error) {
	definedDependencies := workflowDef.DependsOn
	if len(definedDependencies) == 0 {
		return []string{}, nil
	}
	if val, ok := resolvedDependencies[workflowName]; ok {
		return val, nil
	}

	visited[workflowName] = true
	fullDependencyList := []string{}   // List with all dependencies for workflow, to be returned
	dependencyMap := map[string]bool{} // Maps if the dependency already been added to fullDependencyList
	for _, dependencyName := range definedDependencies {
		if _, ok := visited[dependencyName]; ok {
			return nil, fmt.Errorf("circular dependency %s->%s", workflowName, dependencyName)
		}
		dependencyDef, ok := defList[dependencyName]
		if !ok {
			return nil, fmt.Errorf("could not find dependency %s for workflow %s", dependencyName, workflowName)
		}
		curDepList, err := getDependencies(dependencyName, dependencyDef, visited, defList)
		if err != nil {
			return nil, err
		}
		for _, dep := range append(curDepList, dependencyName) {
			if _, ok := dependencyMap[dep]; !ok {
				fullDependencyList = append(fullDependencyList, dep)
				dependencyMap[dep] = true
			}
		}
	}
	resolvedDependencies[workflowName] = fullDependencyList
	return fullDependencyList, nil
}
