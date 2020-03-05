# Microsoft Azure Storage Common Client Library for Ruby

[![Gem Version](https://badge.fury.io/rb/azure-storage-common.svg)](https://badge.fury.io/rb/azure-storage-common)
* Master: [![Master Build Status](https://travis-ci.org/Azure/azure-storage-ruby.svg?branch=master)](https://travis-ci.org/Azure/azure-storage-ruby/branches) [![Coverage Status](https://coveralls.io/repos/github/Azure/azure-storage-ruby/badge.svg?branch=master)](https://coveralls.io/github/Azure/azure-storage-ruby?branch=master)
* Dev: [![Dev Build Status](https://travis-ci.org/Azure/azure-storage-ruby.svg?branch=dev)](https://travis-ci.org/Azure/azure-storage-ruby/branches) [![Coverage Status](https://coveralls.io/repos/github/Azure/azure-storage-ruby/badge.svg?branch=dev)](https://coveralls.io/github/Azure/azure-storage-ruby?branch=dev)

This project provides a Ruby package that supports service client libraries.

# Supported Ruby Versions

* Ruby 2.3 to 2.7

Note: 

* x64 Ruby for Windows is known to have some compatibility issues.
* azure-storage-common depends on gem nokogiri.

# Getting Started

## Install the rubygem package

You can install the azure storage common rubygem package directly.

```bash
gem install azure-storage-common
```

## Create client

You can use this module to create client that can be later shared by service modules, to avoid repeating code of creating storage client.

There are two ways you can create the client:

1. [via code](#via-code)
2. [via environment variables](#via-environment-variables)

<a name="via-code"></a>
### Via Code
* Against Microsoft Azure Services in the cloud

```ruby

  require 'azure/storage/common'

  # Setup a specific instance of an Azure::Storage::Common::Client
  client = Azure::Storage::Common::Client.create(storage_account_name: <your account name>, storage_access_key: <your access key>)

  # Configure a ca_cert.pem file if you are having issues with ssl peer verification
  client.ca_file = './ca_file.pem'

```

* Against local Emulator (Windows Only)

```ruby

  require 'azure/storage/common'
  client = Azure::Storage::Common::Client.create_development

  # Or create by options and provide your own proxy_uri
  client = Azure::Storage::Common::Client.create(use_development_storage: true, development_storage_proxy_uri: <your proxy uri>)

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

<a name="sas"></a>
## Shared Access Signature generation

```ruby

require "azure/storage/common"

# Creating an instance of `Azure::Storage::Common::Core::Auth::SharedAccessSignature`
generator = Azure::Storage::Common::Core::Auth::SharedAccessSignature.new(your_account_name, your_access_key)

# The generator now can be used to create service SAS or account SAS.
generator.generate_service_sas_token(my_path_or_table_name, my_sas_options)
generator.generate_account_sas_token(my_account_sas_options)
# For details about the possible options, please reference the document of the class `Azure::Storage::Common::Core::Auth::SharedAccessSignature`

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
common_token_client = Azure::Storage::Common::Client.create.new(storage_account_name: <your_account_name>, signer: token_signer)

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

# Call client functions as usaual

```

# Code of Conduct 
This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/). For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.
