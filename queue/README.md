# Microsoft Azure Storage Queue Client Library for Ruby

[![Gem Version](https://badge.fury.io/rb/azure-storage-queue.svg)](https://badge.fury.io/rb/azure-storage-queue)
* Master: [![Master Build Status](https://travis-ci.org/Azure/azure-storage-ruby.svg?branch=master)](https://travis-ci.org/Azure/azure-storage-ruby/branches) [![Coverage Status](https://coveralls.io/repos/github/Azure/azure-storage-ruby/badge.svg?branch=master)](https://coveralls.io/github/Azure/azure-storage-ruby?branch=master)
* Dev: [![Dev Build Status](https://travis-ci.org/Azure/azure-storage-ruby.svg?branch=dev)](https://travis-ci.org/Azure/azure-storage-ruby/branches) [![Coverage Status](https://coveralls.io/repos/github/Azure/azure-storage-ruby/badge.svg?branch=dev)](https://coveralls.io/github/Azure/azure-storage-ruby?branch=dev)

This project provides a Ruby package that makes it easy to access and manage Microsoft Azure Storage Queue Services.

# Supported Ruby Versions

* Ruby 1.9.3 to 2.5

Note: 

* x64 Ruby for Windows is known to have some compatibility issues.
* azure-storage-queue depends on gem nokogiri. For Ruby version lower than 2.2, please install the compatible nokogiri before trying to install azure-storage-queue.

# Getting Started

## Install the rubygem package

You can install the azure storage queue rubygem package directly.

```bash
gem install azure-storage-queue
```

## Setup Connection

You can use this Client Library against the Microsoft Azure Queue Storage Services in the cloud, or against the local Storage Emulator if you are on Windows.

There are two ways you can set up the connections:

1. [via code](#via-code)
2. [via environment variables](#via-environment-variables)

<a name="via-code"></a>
### Via Code
* Against Microsoft Azure Services in the cloud

```ruby

  require 'azure/storage/queue'

  # Setup a specific instance of an Azure::Storage::Queue::QueueService
  queue_client = Azure::Storage::Queue::QueueService.create(storage_account_name: 'your account name', storage_access_key: 'your access key')

  # Or create a client and initialize with it.
  require 'azure/storage/common'
  common_client = Azure::Storage::Common::Client.create(storage_account_name: 'your account name', storage_access_key: 'your access key')
  queue_client = Azure::Storage::Queue::QueueService.new(client: common_client)

  # Configure a ca_cert.pem file if you are having issues with ssl peer verification
  queue_client.ca_file = './ca_file.pem'

```

* Against local Emulator (Windows Only)

```ruby

  require 'azure/storage/queue'
  client = Azure::Storage::Queue::QueueService.create_development

  # Or create by options and provide your own proxy_uri
  client = Azure::Storage::Queue::QueueService.create(:use_development_storage => true, :development_storage_proxy_uri => 'your proxy uri')

```

<a name="via-environment-variables"></a>
### Via Environment Variables

* Against Microsoft Azure Storage Queue Services in the cloud

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

<a name="queues"></a>
## Queues

```ruby

# Require the azure storage queue rubygem
require 'azure/storage/queue'

# Setup a specific instance of an Azure::Storage::Queue::QueueService
client = Azure::Storage::Queue::QueueService.create(:storage_account_name => 'your account name', :storage_access_key => 'your access key')

# Alternatively, create a client that can anonymously access public containers for read operations
client = Azure::Storage::Queue::QueueService.create(storage_queue_host: "https://youraccountname.queue.core.windows.net")

# Add retry filter to the service object
require "azure/storage/common"
client.with_filter(Azure::Storage::Common::Core::Filter::ExponentialRetryPolicyFilter.new)

# Create a queue
client.create_queue('test-queue')

# Create a message
client.create_message('test-queue', 'test message')

# Get one or more messages with setting the visibility timeout
result = client.list_messages('test-queue', 30, { number_of_messages: 10 })

# Get one or more messages without setting the visibility timeout
result = client.peek_messages('test-queue', { number_of_messages: 10 })

# Update a message
message = client.list_messages('test-queue', 30)
pop_receipt, time_next_visible = client.update_message('test-queue', message[0].id, message[0].pop_receipt, 'updated test message', 30)

# Delete a message
message = client.list_messages('test-queue', 30)
client.delete_message('test-queue', message[0].id, message[0].pop_receipt)

# Delete a queue
client.delete_queue('test-queue')

```

<a name="Customize the user-agent"></a>
## Customize the user-agent

You can customize the user-agent string by setting your user agent prefix when creating the service client.

```ruby
# Require the azure storage queue rubygem
require "azure/storage/queue"

# Setup a specific instance of an Azure::Storage::Client with :user_agent_prefix option
client = Azure::Storage::Queue::QueueService.create(:storage_account_name => "your account name", :storage_access_key => "your access key", :user_agent_prefix => "your application name")
```

# Code of Conduct 
This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/). For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.
