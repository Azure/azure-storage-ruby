# Microsoft Azure Storage Client Library for Ruby

This project provides a Ruby package that makes it easy to access and manage Microsoft Azure Storage Services.

# Library Features

* [Blobs](#blobs)
* [Tables](#tables)
* [Queues](#queues)

# Supported Ruby Versions

* Ruby 1.9.3
* Ruby 2.0
* Ruby 2.1
* Ruby 2.2

Note: 

* x64 Ruby for Windows is known to have some compatibility issues.
* azure_storage depends on gem nokogiri, which doesn't support Ruby 2.2+ on Windows.

# Getting Started

## Install the rubygem package

You can install the azure rubygem package directly.

```bash
gem install azure_storage
```

## Setup Connection

You can use this SDK against the Microsoft Azure Storage Services in the cloud, or against the local Storage Emulator if you are on Windows.

There are two ways you can set up the connections:

1. [via code](#via-code)
2. [via environment variables](#via-environment-variables)

<a name="via-code"></a>
### Via Code
* Against Microsoft Azure Services in the cloud

```ruby

  require "azure_storage"

  # Setup a specific instance of an Azure::Storage::Client
  client = Azure::Storage.create(:storage_account_name => "your account name", storage_access_key => "your access key")

  # Or create a client and store as a singleton
  Azure::Storage.setup(:storage_account_name => "your account name", storage_access_key => "your access key")
  # Then you can either call client.some_method or Azure::Storage.some_method to invoke a method on the Storage Client

  # Configure a ca_cert.pem file if you are having issues with ssl peer verification
  client.ca_file = "./ca_file.pem"

```

* Against local Emulator (Windows Only)

```ruby

  require "azure_storage"
  client = Azure::Storage.create_develpoment

  # Or create by options and provide your own proxy_uri
  client = Azure::Storage.create(:use_develpoment_storage => true, :development_storage_proxy_uri => "your proxy uri")

```

<a name="via-environment-variables"></a>
### Via Environment Variables

* Against Microsoft Azure Storage Services in the cloud

    ```bash
    export AZURE_STORAGE_ACCOUNT = <your azure storage account name>
    export AZURE_STORAGE_ACCESS_KEY = <your azure storage access key>
    ```

* Against local Emulator (Windows Only)

    ```bash
    export EMULATED = true
    ```

* [SSL Certificate File](https://gist.github.com/fnichol/867550) if having issues with ssl peer verification
    
    ```bash
    SSL_CERT_FILE=<path to *.pem>
    ```

# Usage

<a name="blobs"></a>
## Blobs

```ruby

# Create an azure storage blob service object after you set up the credentials
blobs = Azure::Storage.blobs

# Create a container
container = blobs.create_container("test-container")

# Upload a Blob
content = File.open('test.jpg', 'rb') { |file| file.read }
blobs.create_block_blob(container.name, "image-blob", content)

# List containers
blobs.list_containers()

# List Blobs
blobs.list_blobs(container.name)

# Download a Blob
blob, content = blobs.get_blob(container.name, "image-blob")
File.open("download.png", "wb") {|f| f.write(content)}

# Delete a Blob
blobs.delete_blob(container.name, "image-blob")

```
<a name="tables"></a>
## Tables

```ruby

# Require the azure rubygem
require "azure_storage"

# Create an azure storage table service object after you set up the credentials
tables = Azure::Storage.tables

# Create a table
tables.create_table("testtable")

# Insert an entity
entity = { "content" => "test entity", :partition_key => "test-partition-key", :row_key => "1" }
tables.insert_entity("testtable", entity)

# Get an entity
result = tables.get_entity("testtable", "test-partition-key", "1")

# Update an entity
result.properties["content"] = "test entity with updated content"
tables.update_entity(result.table, result.properties)

# Query entities
query = { :filter => "content eq 'test entity'" }
result, token = tables.query_entities("testtable", query)

# Delete an entity
tables.delete_entity("testtable", "test-partition-key", "1")

# delete a table
tables.delete_table("testtable")

```

<a name="queues"></a>
### Queues

```ruby

# Require the azure rubygem
require "azure_storage"

# Create an azure storage queue service object after you set up the credentials
queues = Azure::Storage.queues

# Create a queue
queues.create_queue("test-queue")

# Create a message
queues.create_message("test-queue", "test message")

# Get one or more messages with setting the visibility timeout
result = queues.list_messages("test-queue", 30, {:number_of_messages => 10})

# Get one or more messages without setting the visibility timeout
result = queues.peek_messages("test-queue", {:number_of_messages => 10})

# Update a message
message = queues.list_messages("test-queue", 30)
pop_receipt, time_next_visible = queues.update_message("test-queue", message.id, message.pop_receipt, "updated test message", 30)

# Delete a message
message = queues.list_messages("test-queue", 30)
queues.delete_message("test-queue", message.id, message.pop_receipt)

# Delete a queue
queues.delete_queue("test-queue")

```

# Getting Started for Contributors

## Development Environment Setup

To get the source code of the SDK via **git** just type:

```bash
git clone https://github.com/Azure/azure-storage-ruby.git
cd ./azure-storage-ruby
```

Then, run bundler to install all the gem dependencies:

```bash
bundle install
```

## Setup the Environment for Integration Tests

If you would like to run the integration test suite, you will need to setup environment variables which will be used
during the integration tests. These tests will use these credentials to run live tests against Azure with the provided
credentials (you will be charged for usage, so verify the clean up scripts did their job at the end of a test run).

The root of the project contains a .env_sample file. This dot file is a sample of the actual environment vars needed to
run the integration tests.

Unit tests doesn't require real credentials and doesn't require to provide the .env file.

Do the following to prepare your environment for integration tests:

* Copy .env_sample to .env **relative to root of the project dir**
* Update .env with your credentials **.env is in the .gitignore, so should only reside locally**

## Run Tests

You can use the following commands to run:

* All the tests: ``rake test``. **This will run integration tests if you have .env file or env vars setup**
* Run storage suite of tests: ``rake test:unit:storage``, ``rake test:integration:storage``
* One particular test file: ``ruby -I"lib:test" "<path of the test file>"``

# Provide Feedback

If you encounter any bugs with the library please file an issue in the [Issues](https://github.com/Azure/azure-storage-ruby/issues) section of the project and mark the issue with tag **storage**.

# Maintainers

* [Zack Yang](https://github.com/slepox)

# Azure Storage SDKs and Tooling

* [Azure Storage Client Library for .Net](http://github.com/azure/azure-storage-net)
* [Azure Storage Client Library for Java](http://github.com/azure/azure-storage-java)
* [Azure Storage Client Library for node.js](http://github.com/azure/azure-storage-node)
* [Azure Storage Client Library for C++](http://github.com/azure/azure-storage-cpp)