package cmd

import (
	"bytes"
	"fmt"
	"testing"

	workflow "devx-workflows/internal/workflow"

	"github.com/spf13/viper"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/suite"
)

type ListSuite struct {
	suite.Suite
	buf bytes.Buffer
}

const testWorkflowName = "testing"
const testWorkflowCommand = "testing.sh"

func (suite *ListSuite) SetupTest() {
	suite.buf = bytes.Buffer{}
	viper.Set(fmt.Sprintf("%s.%s.command", workflow.WorkflowKey, testWorkflowName), testWorkflowCommand)
}

func (suite *ListSuite) TestListErrorsIfEmpty() {
	viper.Set(workflow.WorkflowKey, "")
	assert.Error(suite.T(), list(&suite.buf))
}

func (suite *ListSuite) TestListDoesNotErrorIfPopulated() {
	assert.Nil(suite.T(), list(&suite.buf))
}

func (suite *ListSuite) TestListDisplaysAllWorkflows() {
	list(&suite.buf)
	assert.Contains(suite.T(), suite.buf.String(), testWorkflowName)
	assert.Contains(suite.T(), suite.buf.String(), testWorkflowCommand)
}

func TestListSuite(t *testing.T) {
	suite.Run(t, new(ListSuite))
}
