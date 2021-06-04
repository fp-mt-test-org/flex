# What is Flex?

Flex is a CLI & config driven x-plat tool for defining and executing workflows.

Similar to tools such as Make, however it's not tightly coupled to heavy software development tools and can be used to execute any CLI tasks, including but not limited to building and testing code.

#### Docs
- [How to Use](#usage)
- [How to Develop](#working-on-flex)

## Usage

### Installation

To install into a repository:

1. From the root of your repo, execute:
```
bash -c "$(curl -fsSL https://github.com/fp-mt/flex/releases/latest/download/flex.sh)"
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
5. Setup dependencies on your machine: `./scripts/setup-dev-dependencies.sh`

### Basics

First thing to know is that Flex is used to build and test itself.

### Build & Unit Test

To build and install a new version of flex, execute the build script:

    auto_install=1 ./scripts/build-flex.sh

This will compile, unit test and update the binaries in the `.flex` directory.

Once you have flex built, you can then use flex to build itself:

    flex build

### Feature Test

Unit tests are great, but they don't mean the features are working!

To execute feature tests, execute the test workflow:

    flex test
