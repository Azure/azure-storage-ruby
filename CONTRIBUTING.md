If you intend to contribute to the project, please make sure you've followed the instructions provided in the [Azure Projects Contribution Guidelines](http://azure.github.io/guidelines/).
## Project Setup
The Azure Storage development team uses Visual Studio Code so instructions will be tailored to that preference. However, any preferred IDE or other toolset should be usable.

### Install
* Ruby 1.9.3, 2.0, 2.1 or 2.2.
* [Visual Studio Code](https://code.visualstudio.com/)

### Development Environment Setup
To get the source code of the SDK via **git** just type:

```bash
git clone https://github.com/Azure/azure-storage-ruby.git
cd ./azure-storage-ruby
```

Then, install Bundler and run bundler to install all the gem dependencies:

```bash
gem install bundler
bundle install
```

## Tests

### Configuration
If you would like to run the integration test suite, you will need to setup environment variables which will be used
during the integration tests. These tests will use these credentials to run live tests against Azure with the provided
credentials (you will be charged for usage, so verify the clean up scripts did their job at the end of a test run).

The root of the project contains a [.env_sample](.env_sample) file. This dot file is a sample of the actual environment vars needed to
run the integration tests.

Unit tests don't require real credentials and don't require to provide the .env file.

Do the following to prepare your environment for integration tests:

* Copy [.env_sample](.env_sample) to .env **relative to root of the project dir**
* Update .env with your credentials **.env is in the .gitignore, so should only reside locally**

### Running
You can use the following commands to run:

* All the tests: ``rake test``. **This will run integration tests if you have .env file or env vars setup**
* Run storage suite of tests: ``rake test:unit``, ``rake test:integration``
* One particular test file: ``ruby -I"lib:test" "<path of the test file>"``

### Testing Features
As you develop a feature, you'll need to write tests to ensure quality. Your changes should be covered by both unit tests and integration tests. You should also run existing tests related to your change to address any unexpected breaks.

## Pull Requests

### Guidelines
The following are the minimum requirements for any pull request that must be met before contributions can be accepted.
* Make sure you've signed the CLA before you start working on any change.
* Discuss any proposed contribution with the team via a GitHub issue **before** starting development.
* Code must be professional quality
	* No style issues
	* You should strive to mimic the style with which we have written the library
	* Clean, well-commented, well-designed code
	* Try to limit the number of commits for a feature to 1-2. If you end up having too many we may ask you to squash your changes into fewer commits.
* [ChangeLog.md](ChangeLog.md) needs to be updated describing the new change
* Thoroughly test your feature

### Branching Policy
Changes should be based on the **dev** branch, not master as master is considered publicly released code. Each breaking change should be recorded in [BreakingChanges.md](BreakingChanges.md).

### Adding Features for All Platforms
We strive to release each new feature for each of our environments at the same time. Therefore, we ask that all contributions be written for Ruby 1.9.3 and later.

### Review Process
We expect all guidelines to be met before accepting a pull request. As such, we will work with you to address issues we find by leaving comments in your code. Please understand that it may take a few iterations before the code is accepted as we maintain high standards on code quality. Once we feel comfortable with a contribution, we will validate the change and accept the pull request.


Thank you for any contributions! Please let the team know if you have any questions or concerns about our contribution policy.