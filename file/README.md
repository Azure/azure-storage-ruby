# Microsoft Azure Storage File Client Library for Ruby

[![Gem Version](https://badge.fury.io/rb/azure-storage-file.svg)](https://badge.fury.io/rb/azure-storage-file)
* Master: [![Master Build Status](https://travis-ci.org/Azure/azure-storage-ruby.svg?branch=master)](https://travis-ci.org/Azure/azure-storage-ruby/branches) [![Coverage Status](https://coveralls.io/repos/github/Azure/azure-storage-ruby/badge.svg?branch=master)](https://coveralls.io/github/Azure/azure-storage-ruby?branch=master)
* Dev: [![Dev Build Status](https://travis-ci.org/Azure/azure-storage-ruby.svg?branch=dev)](https://travis-ci.org/Azure/azure-storage-ruby/branches) [![Coverage Status](https://coveralls.io/repos/github/Azure/azure-storage-ruby/badge.svg?branch=dev)](https://coveralls.io/github/Azure/azure-storage-ruby?branch=dev)

This project provides a Ruby package that makes it easy to access and manage Microsoft Azure Storage File Services.

# Supported Ruby Versions

* Ruby 1.9.3 to 2.5

Note: 

* x64 Ruby for Windows is known to have some compatibility issues.
* azure-storage-file depends on gem nokogiri. For Ruby version lower than 2.2, please install the compatible nokogiri before trying to install azure-storage-file.

# Getting Started

## Install the rubygem package

You can install the azure storage file rubygem package directly.

```bash
gem install azure-storage-file
```

## Setup Connection

You can use this Client Library against the Microsoft Azure Storage File Services in the cloud.

There are two ways you can set up the connections:

1. [via code](#via-code)
2. [via environment variables](#via-environment-variables)

<a name="via-code"></a>
### Via Code
* Against Microsoft Azure Services in the cloud

```ruby

  require 'azure/storage/file'

  # Setup a specific instance of an Azure::Storage::File::FileService
  file_client = Azure::Storage::File::FileService.create(storage_account_name: 'your account name', storage_access_key: 'your access key')

  # Or create a client and initialize with it.
  require 'azure/storage/common'
  common_client = Azure::Storage::Common::Client.create(storage_account_name: 'your account name', storage_access_key: 'your access key')
  file_client = Azure::Storage::File::FileService.new(client: common_client)

  # Configure a ca_cert.pem file if you are having issues with ssl peer verification
  file_client.ca_file = './ca_file.pem'

```

<a name="via-environment-variables"></a>
### Via Environment Variables

* Against Microsoft Azure Storage File Services in the cloud

    ```bash
    export AZURE_STORAGE_ACCOUNT = <your azure storage account name>
    export AZURE_STORAGE_ACCESS_KEY = <your azure storage access key>
    ```

* [SSL Certificate File](https://gist.github.com/fnichol/867550) if having issues with ssl peer verification
    
    ```bash
    SSL_CERT_FILE=<path to *.pem>
    ```

# Usage

<a name="files"></a>
## Files

```ruby
# Require the azure storage file rubygem
require 'azure/storage/file'

# Setup a specific instance of an Azure::Storage::File::FileService
client = Azure::Storage::File::FileService.create(:storage_account_name => 'your account name', :storage_access_key => 'your access key')

# Alternatively, create a client that can anonymously access public containers for read operations
client = Azure::Storage::File::FileService.create(storage_file_host: "https://youraccountname.file.core.windows.net")

# Add retry filter to the service object
require "azure/storage/common"
client.with_filter(Azure::Storage::Common::Core::Filter::ExponentialRetryPolicyFilter.new)

# Create a share
share = client.create_share('test-share')

# Create a directory
directory = client.create_directory(share.name, 'test-directory')

# Create a file and update the file content
content = ::File.open('test.jpg', 'rb') { |file| file.read }
file = client.create_file(share.name, directory.name, 'test-file', content.size)
client.put_file_range(share.name, directory.name, file.name, 0, content.size - 1, content)

# List shares
client.list_shares()

# List directories and client
client.list_directories_and_files(share.name, directory.name)

# Download a File
file, content = client.get_file(share.name, directory.name, file.name)
::File.open('download.png', 'wb') {|f| f.write(content)}

# Delete a File
client.delete_file(share.name, directory.name, file.name)
```

<a name="Customize the user-agent"></a>
## Customize the user-agent

You can customize the user-agent string by setting your user agent prefix when creating the service client.

```ruby
# Require the azure storage rubygem
require "azure/storage/file"

# Setup a specific instance of an Azure::Storage::Client with :user_agent_prefix option
client = Azure::Storage::File::FileService.create(:storage_account_name => "your account name", :storage_access_key => "your access key", :user_agent_prefix => "your application name")
```

# Code of Conduct 
This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/). For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.
