package workflow

import (
	"fmt"
	"testing"

	exec "devx-workflows/pkg/exec"

	"github.com/spf13/viper"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
	"github.com/stretchr/testify/suite"
)

type WorkflowSuite struct {
	suite.Suite
	execMock *exec.Mock
}

const testWorkflowName = "testing"
const testWorkflowCommand = "testing.sh"
const testWorkflowDependencyName = "testing-dependency"
const testWorkflowDependencyCommand = "testing_dependency.sh"
const testSecondDependencyName = "testing-second-dependency"
const testSecondDependencyCommand = "testing_second_dependency.sh"

func (suite *WorkflowSuite) SetupTest() {
	suite.execMock = new(exec.Mock)
	suite.execMock.On("ExecFn", mock.Anything, mock.Anything).Return(nil)
	viper.Set(fmt.Sprintf("%s.%s.command", WorkflowKey, testWorkflowName), testWorkflowCommand)
}

func (suite *WorkflowSuite) TestWorkflowCommandNoError() {
	assert.Nil(suite.T(), WorkflowExec(suite.execMock, testWorkflowName), "Unexpected error")
}

func (suite *WorkflowSuite) TestWorkflowCommandIsExecuted() {
	WorkflowExec(suite.execMock, testWorkflowName)
	suite.execMock.AssertCalled(suite.T(), "ExecFn", testWorkflowCommand, mock.Anything)
}

func (suite *WorkflowSuite) TestEmptyWorkflowCommandDoesNotExecute() {
	viper.Set(fmt.Sprintf("%s.%s.command", WorkflowKey, testWorkflowName), "")
	WorkflowExec(suite.execMock, testWorkflowName)
	suite.execMock.AssertNotCalled(suite.T(), "ExecFn", mock.Anything)
}

func (suite *WorkflowSuite) TestNoWorkflowDefWillError() {
	assert.NotNil(suite.T(), WorkflowExec(suite.execMock, "fake"), "No error when command not defined")
}

func (suite *WorkflowSuite) TestWorkflowWithDependenciesNoError() {
	viper.Set(fmt.Sprintf("%s.%s.depends-on", WorkflowKey, testWorkflowName), []string{testWorkflowDependencyName})
	viper.Set(fmt.Sprintf("%s.%s.command", WorkflowKey, testWorkflowDependencyName), testWorkflowDependencyCommand)
	assert.Nil(suite.T(), WorkflowExec(suite.execMock, testWorkflowName), "Unexpected error")
}

func (suite *WorkflowSuite) TestDependenciesAreExecuted() {
	viper.Set(fmt.Sprintf("%s.%s.depends-on", WorkflowKey, testWorkflowName), []string{testWorkflowDependencyName})
	viper.Set(fmt.Sprintf("%s.%s.command", WorkflowKey, testWorkflowDependencyName), testWorkflowDependencyCommand)
	WorkflowExec(suite.execMock, testWorkflowName)
	suite.execMock.AssertCalled(suite.T(), "ExecFn", testWorkflowDependencyCommand, mock.Anything)
}

func (suite *WorkflowSuite) TestMultiLevelDependenciesAreExecuted() {
	viper.Set(fmt.Sprintf("%s.%s.depends-on", WorkflowKey, testWorkflowName), []string{testWorkflowDependencyName})
	viper.Set(fmt.Sprintf("%s.%s.command", WorkflowKey, testWorkflowDependencyName), testWorkflowDependencyCommand)
	viper.Set(fmt.Sprintf("%s.%s.depends-on", WorkflowKey, testWorkflowDependencyName), []string{testSecondDependencyName})
	viper.Set(fmt.Sprintf("%s.%s.command", WorkflowKey, testSecondDependencyName), testSecondDependencyCommand)
	WorkflowExec(suite.execMock, testWorkflowName)
	suite.execMock.AssertCalled(suite.T(), "ExecFn", testSecondDependencyCommand, mock.Anything)
	suite.execMock.AssertCalled(suite.T(), "ExecFn", testWorkflowDependencyCommand, mock.Anything)
	suite.execMock.AssertCalled(suite.T(), "ExecFn", testWorkflowCommand, mock.Anything)
}

func (suite *WorkflowSuite) TestMultipleSameLevelDependenciesAreExecuted() {
	viper.Set(fmt.Sprintf("%s.%s.depends-on", WorkflowKey, testWorkflowName), []string{testWorkflowDependencyName, testSecondDependencyName})
	viper.Set(fmt.Sprintf("%s.%s.command", WorkflowKey, testWorkflowDependencyName), testWorkflowDependencyCommand)
	viper.Set(fmt.Sprintf("%s.%s.command", WorkflowKey, testSecondDependencyName), testSecondDependencyCommand)
	WorkflowExec(suite.execMock, testWorkflowName)
	suite.execMock.AssertCalled(suite.T(), "ExecFn", testSecondDependencyCommand, mock.Anything)
	suite.execMock.AssertCalled(suite.T(), "ExecFn", testWorkflowDependencyCommand, mock.Anything)
	suite.execMock.AssertCalled(suite.T(), "ExecFn", testWorkflowCommand, mock.Anything)
}

func TestWorkflowSuite(t *testing.T) {
	suite.Run(t, new(WorkflowSuite))
}
