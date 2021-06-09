# What is Flex?

Flex is a x-plat CLI tool for defining and executing configurable workflows.

Similar to tools such as Make, however it's not tightly coupled to heavy software development tools and can be used to execute any CLI tasks, including but not limited to building and testing code.

#### Docs
- [How to Use](#usage)
- [How to Develop](#working-on-flex)

## Usage

### Installation

To install into a repository:

1. From the root of your repo, execute:
```
curl -fsSL https://github.com/fp-mt-test-org/flex/releases/latest/download/flex.sh --output flex.sh && chmod a+x ./flex.sh && ./flex.sh
```
3. Run `flex init`

#### Get the Version

You can see the version of flex like so:

    flex -version

## Working on Flex

### Getting Started

1. Fork this repository
2. Set branch protection rules on your fork to require PRs for main
3. Clone this repository
4. Configure your remotes: `git remote set-url --push origin your-fork-url-here`

### Basics

First thing to know is that Flex is used to build and test itself.

### Pull Latest Source & Tags

    flex pull

### Build & Unit Test

To build and install a new version of flex, execute the build script:

    flex build

### Feature Test

Unit tests are great, but they don't mean the features are working!

To execute feature tests, execute the test workflow:

    flex test

### Push Changes w/ Validation

    flex push
