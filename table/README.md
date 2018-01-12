# Microsoft Azure Storage Table Client Library for Ruby

[![Gem Version](https://badge.fury.io/rb/azure-storage-table.svg)](https://badge.fury.io/rb/azure-storage-table)
* Master: [![Master Build Status](https://travis-ci.org/Azure/azure-storage-ruby.svg?branch=master)](https://travis-ci.org/Azure/azure-storage-ruby/branches) [![Coverage Status](https://coveralls.io/repos/github/Azure/azure-storage-ruby/badge.svg?branch=master)](https://coveralls.io/github/Azure/azure-storage-ruby?branch=master)
* Dev: [![Dev Build Status](https://travis-ci.org/Azure/azure-storage-ruby.svg?branch=dev)](https://travis-ci.org/Azure/azure-storage-ruby/branches) [![Coverage Status](https://coveralls.io/repos/github/Azure/azure-storage-ruby/badge.svg?branch=dev)](https://coveralls.io/github/Azure/azure-storage-ruby?branch=dev)

This project provides a Ruby package that makes it easy to access and manage Microsoft Azure Storage Table Services.

# Supported Ruby Versions

* Ruby 1.9.3 to 2.5

Note: 

* x64 Ruby for Windows is known to have some compatibility issues.
* azure-storage-table depends on gem nokogiri. For Ruby version lower than 2.2, please install the compatible nokogiri before trying to install azure-storage-table.

# Getting Started

## Install the rubygem package

You can install the azure storage table rubygem package directly.

```bash
gem install azure-storage-table
```

## Setup Connection

You can use this Client Library against the Microsoft Azure Storage Table Services in the cloud, or against the local Storage Emulator if you are on Windows.

There are two ways you can set up the connections:

1. [via code](#via-code)
2. [via environment variables](#via-environment-variables)

<a name="via-code"></a>
### Via Code
* Against Microsoft Azure Services in the cloud

```ruby

  require 'azure/storage/table'

  # Setup a specific instance of an Azure::Storage::Table::TableService
  table_client = Azure::Storage::Table::TableService.create(storage_account_name: 'your account name', storage_access_key: 'your access key')

  # Or create a client and initialize with it.
  require 'azure/storage/common'
  common_client = Azure::Storage::Common::Client.create(storage_account_name: 'your account name', storage_access_key: 'your access key')
  table_client = Azure::Storage::Table::TableService.new(client: common_client)

  # Configure a ca_cert.pem file if you are having issues with ssl peer verification
  table_client.ca_file = './ca_file.pem'

```

* Against local Emulator (Windows Only)

```ruby

  require 'azure/storage/table'
  client = Azure::Storage::Table::TableService.create_development

  # Or create by options and provide your own proxy_uri
  client = Azure::Storage::Table::TableService.create(:use_development_storage => true, :development_storage_proxy_uri => 'your proxy uri')

```

<a name="via-environment-variables"></a>
### Via Environment Variables

* Against Microsoft Azure Storage Table Services in the cloud

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

<a name="tables"></a>
## Tables

```ruby

# Require the azure storage rubygem
require 'azure/storage'

# Setup a specific instance of an Azure::Storage::Client
client = Azure::Storage::Client.create(:storage_account_name => 'your account name', :storage_access_key => 'your access key')

# Get an azure storage table service object from a specific instance of an Azure::Storage::Client
tables = client.table_client

# Or setup the client as a singleton
Azure::Storage.setup(:storage_account_name => 'your account name', :storage_access_key => 'your access key')

# Create an azure storage table service object after you set up the credentials
tables = Azure::Storage::Table::TableService.new

# Add retry filter to the service object
tables.with_filter(Azure::Storage::Core::Filter::ExponentialRetryPolicyFilter.new)

# Create a table
tables.create_table('testtable')

# Insert an entity
entity = { content: 'test entity', PartitionKey: 'test-partition-key', RowKey: '1' }
tables.insert_entity('testtable', entity)

# Get an entity
result = tables.get_entity('testtable', 'test-partition-key', '1')

# Update an entity
result.properties['content'] = 'test entity with updated content'
tables.update_entity(result.table, result.properties)

# Query entities
query = { :filter => "content eq 'test entity'" }
result, token = tables.query_entities('testtable', query)

# Delete an entity
tables.delete_entity('testtable', 'test-partition-key', '1')

# delete a table
tables.delete_table('testtable')

```

<a name="Customize the user-agent"></a>
## Customize the user-agent

You can customize the user-agent string by setting your user agent prefix when creating the service client.

```ruby
# Require the azure storage table rubygem
require "azure/storage/table"

# Setup a specific instance of an Azure::Storage::Client with :user_agent_prefix option
client = Azure::Storage::Table::TableService.create(:storage_account_name => "your account name", :storage_access_key => "your access key", :user_agent_prefix => "your application name")
```

# Code of Conduct 
This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/). For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.
