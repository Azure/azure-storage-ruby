# Microsoft Azure Storage Blob Client Library for Ruby

[![Gem Version](https://badge.fury.io/rb/azure-storage-blob.svg)](https://badge.fury.io/rb/azure-storage-blob)
* Master: [![Master Build Status](https://travis-ci.org/Azure/azure-storage-ruby.svg?branch=master)](https://travis-ci.org/Azure/azure-storage-ruby/branches) [![Coverage Status](https://coveralls.io/repos/github/Azure/azure-storage-ruby/badge.svg?branch=master)](https://coveralls.io/github/Azure/azure-storage-ruby?branch=master)
* Dev: [![Dev Build Status](https://travis-ci.org/Azure/azure-storage-ruby.svg?branch=dev)](https://travis-ci.org/Azure/azure-storage-ruby/branches) [![Coverage Status](https://coveralls.io/repos/github/Azure/azure-storage-ruby/badge.svg?branch=dev)](https://coveralls.io/github/Azure/azure-storage-ruby?branch=dev)

This project provides a Ruby package that makes it easy to access and manage Microsoft Azure Storage Blob Services.


# Supported Ruby Versions

* Ruby 2.3 to 2.7

Note: 

* x64 Ruby for Windows is known to have some compatibility issues.
* azure-storage-blob depends on gem nokogiri.

# Getting Started

## Install the rubygem package

You can install the azure storage blob rubygem package directly.

```bash
gem install azure-storage-blob
```

## Setup Connection

You can use this Client Library against the Microsoft Azure Storage Blob Services in the cloud, or against the local Storage Emulator if you are on Windows.

There are two ways you can set up the connections:

1. [via code](#via-code)
2. [via environment variables](#via-environment-variables)

<a name="via-code"></a>
### Via Code
* Against Microsoft Azure Services in the cloud

```ruby

  require 'azure/storage/blob'

  # Setup a specific instance of an Azure::Storage::Blob::BlobService
  blob_client = Azure::Storage::Blob::BlobService.create(storage_account_name: <your account name>, storage_access_key: <your access key>)

  # Or create a client and initialize with it.
  require 'azure/storage/common'
  common_client = Azure::Storage::Common::Client.create(storage_account_name: <your account name>, storage_access_key: <your access key>)
  blob_client = Azure::Storage::Blob::BlobService.new(client: common_client)

  # Configure a ca_cert.pem file if you are having issues with ssl peer verification
  blob_client.ca_file = './ca_file.pem'

```

* Against local Emulator (Windows Only)

```ruby

  require 'azure/storage/blob'
  client = Azure::Storage::Blob::BlobService.create_development

  # Or create by options and provide your own proxy_uri
  client = Azure::Storage::Blob::BlobService.create(use_development_storage: true, development_storage_proxy_uri: <your proxy uri>)

```

<a name="via-environment-variables"></a>
### Via Environment Variables

* Against Microsoft Azure Storage Blob Services in the cloud

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

<a name="usage"></a>
## Usage

```ruby

# Require the azure storage blob rubygem
require 'azure/storage/blob'

# Setup a specific instance of an Azure::Storage::Blob::BlobService
client = Azure::Storage::Blob::BlobService.create(storage_account_name: <your account name>, storage_access_key: <your access key>)

# Alternatively, create a client that can anonymously access public containers for read operations
client = Azure::Storage::Blob::BlobService.create(storage_blob_host: "https://youraccountname.blob.core.windows.net")

# Add retry filter to the service object
require "azure/storage/common"
client.with_filter(Azure::Storage::Common::Core::Filter::ExponentialRetryPolicyFilter.new)

# Create a container
container = client.create_container('test-container')

# Upload a Blob
content = ::File.open('test.jpg', 'rb') { |file| file.read }
client.create_block_blob(container.name, 'image-blob', content)

# List containers
client.list_containers()

# List Blobs
client.list_blobs(container.name)

# Download a Blob
blob, content = client.get_blob(container.name, 'image-blob')
::File.open('download.png', 'wb') {|f| f.write(content)}

# Delete a Blob
client.delete_blob(container.name, 'image-blob')

```

<a name="token"></a>
## Access Token

Please refer to the below links for obtaining an access token:
* [Authenticate with Azure Active Directory](https://docs.microsoft.com/en-us/rest/api/storageservices/authenticate-with-azure-active-directory)
* [Getting a MSI access token](https://docs.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/tutorial-linux-vm-access-storage#get-an-access-token-and-use-it-to-call-azure-storage)

```ruby
require "azure/storage/common"

access_token = <your initial access token>

# Creating an instance of `Azure::Storage::Common::Core::TokenCredential`
token_credential = Azure::Storage::Common::Core::TokenCredential.new access_token
token_signer = Azure::Storage::Common::Core::Auth::TokenSigner.new token_credential
blob_token_client = Azure::Storage::Blob::BlobService.new(storage_account_name: <your_account_name>, signer: token_signer)

# Refresh internal is 50 minutes
refresh_interval = 50 * 60
# The user-defined thread that renews the access token
cancelled = false
renew_token = Thread.new do
  Thread.stop
  while !cancelled
    sleep(refresh_interval)

    # Renew the access token here

    # Update the access token to the credential
    token_credential.renew_token <new_access_token>
  end
end
sleep 0.1 while renew_token.status != 'sleep'
renew_token.run

# Call blob client functions as usaual

```

<a name="Customize the user-agent"></a>
## Customize the user-agent

You can customize the user-agent string by setting your user agent prefix when creating the service client.

```ruby
# Require the azure storage blob rubygem
require "azure/storage/blob"

# Setup a specific instance of an Azure::Storage::Client with :user_agent_prefix option
client = Azure::Storage::Blob::BlobService.create(storage_account_name: <your account name>, storage_access_key: <your access key>, user_agent_prefix: <your application name>)
```

# Code of Conduct 
This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/). For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.
