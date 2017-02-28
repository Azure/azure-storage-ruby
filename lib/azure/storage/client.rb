#-------------------------------------------------------------------------
# # Copyright (c) Microsoft and contributors. All rights reserved.
#
# The MIT License(MIT)

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files(the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and / or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions :

# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#--------------------------------------------------------------------------

require 'azure/storage/core'
require 'azure/storage/core/http_client'

require 'azure/storage/client_options'

require 'azure/storage/service/storage_service'
require 'azure/storage/blob/blob_service'
require 'azure/storage/table/table_service'
require 'azure/storage/queue/queue_service'
require 'azure/storage/file/file_service'

module Azure::Storage
  class Client
    include Azure::Storage::Configurable
    include Azure::Storage::ClientOptions
    include Azure::Storage::Core::HttpClient

    # Public: Creates an instance of [Azure::Storage::Client]
    #
    # ==== Attributes
    #
    # * +options+    - Hash. Optional parameters.
    #
    # ==== Options
    #
    # Accepted key/value pairs in options parameter are:
    #
    # * +:use_development_storage+        - True. Whether to use storage emulator.
    # * +:development_storage_proxy_uri+  - String. Used with +:use_development_storage+ if emulator is hosted other than localhost.
    # * +:storage_connection_string+      - String. The storage connection string.
    # * +:storage_account_name+           - String. The name of the storage account.
    # * +:storage_access_key+             - Base64 String. The access key of the storage account.
    # * +:storage_sas_token+              - String. The signed access signiture for the storage account or one of its service.
    # * +:storage_blob_host+              - String. Specified Blob serivce endpoint or hostname
    # * +:storage_table_host+             - String. Specified Table serivce endpoint or hostname
    # * +:storage_queue_host+             - String. Specified Queue serivce endpoint or hostname
    # * +:storage_dns_suffix+             - String. The suffix of a regional Storage Serivce, to
    # * +:default_endpoints_protocol+     - String. http or https
    # * +:use_path_style_uri+             - String. Whether use path style URI for specified endpoints
    # * +:ca_file+                        - String. File path of the CA file if having issue with SSL
    # * +:user_agent_prefix+              - String. The user agent prefix that can identify the application calls the library
    #
    # The valid set of options inlcude:
    # * Storage Emulator: +:use_development_storage+ required, +:development_storage_proxy_uri+ optionally
    # * Storage account name and key: +:storage_account_name+ and +:storage_access_key+ required, set +:storage_dns_suffix+ necessarily
    # * Storage account name and SAS token: +:storage_account_name+ and +:storage_sas_token+ required, set +:storage_dns_suffix+ necessarily
    # * Specified hosts and SAS token: At least one of the service host and SAS token. It's up to user to ensure the SAS token is suitable for the serivce
    # * Anonymous Blob: only +:storage_blob_host+, if it is to only access blobs within a container
    #
    # Additional notes:
    # * Specified hosts can be set when use account name with access key or sas token
    # * +:default_endpoints_protocol+ can be set if the scheme is not specified in hosts
    # * Storage emulator always use path style URI
    # * +:ca_file+ is independent.
    #
    # When empty options are given, it will try to read settings from Environment Variables. Refer to [Azure::Storage::ClientOptions.env_vars_mapping] for the mapping relationship
    #
    # @return [Azure::Storage::Client]
    def initialize(options = {}, &block)
      if options.is_a?(Hash) and options.has_key?(:user_agent_prefix)
        Azure::Storage::Service::StorageService.user_agent_prefix = options[:user_agent_prefix]
        options.delete :user_agent_prefix
      end
      Azure::Storage::Service::StorageService.register_request_callback &block if block_given?
      reset!(options)
    end

    # Azure Blob service client configured from this Azure Storage client instance
    # @return [Azure::Storage::Blob::BlobService]
    def blob_client(options = {}, &block)
      @blob_client ||= Azure::Storage::Blob::BlobService.new(default_client(options), &block)
    end

    # Azure Queue service client configured from this Azure Storage client instance
    # @return [Azure::Storage::Queue::QueueService]
    def queue_client(options = {})
      @queue_client ||= Azure::Storage::Queue::QueueService.new(default_client(options))
    end

    # Azure Table service client configured from this Azure Storage client instance
    # @return [Azure::Storage::Table::TableService]
    def table_client(options = {})
      @table_client ||= Azure::Storage::Table::TableService.new(default_client(options))
    end

    # Azure File service client configured from this Azure Storage client instance
    # @return [Azure::Storage::File::FileService]
    def file_client(options = {})
      @file_client ||= Azure::Storage::File::FileService.new(default_client(options))
    end

    class << self
      # Public: Creates an instance of [Azure::Storage::Client]
      #
      # ==== Attributes
      #
      # * +options+    - Hash. Optional parameters.
      #
      # ==== Options
      #
      # Accepted key/value pairs in options parameter are:
      #
      # * +:use_development_storage+        - TrueClass. Whether to use storage emulator.
      # * +:development_storage_proxy_uri+  - String. Used with +:use_development_storage+ if emulator is hosted other than localhost.
      # * +:storage_account_name+           - String. The name of the storage account.
      # * +:storage_access_key+             - Base64 String. The access key of the storage account.
      # * +:storage_sas_token+              - String. The signed access signiture for the storage account or one of its service.
      # * +:storage_blob_host+              - String. Specified Blob serivce endpoint or hostname
      # * +:storage_table_host+             - String. Specified Table serivce endpoint or hostname
      # * +:storage_queue_host+             - String. Specified Queue serivce endpoint or hostname
      # * +:storage_dns_suffix+             - String. The suffix of a regional Storage Serivce, to
      # * +:default_endpoints_protocol+     - String. http or https
      # * +:use_path_style_uri+             - String. Whether use path style URI for specified endpoints
      # * +:ca_file+                        - String. File path of the CA file if having issue with SSL
      # * +:user_agent_prefix+              - String. The user agent prefix that can identify the application calls the library
      #
      # The valid set of options inlcude:
      # * Storage Emulator: +:use_development_storage+ required, +:development_storage_proxy_uri+ optionally
      # * Storage account name and key: +:storage_account_name+ and +:storage_access_key+ required, set +:storage_dns_suffix+ necessarily
      # * Storage account name and SAS token: +:storage_account_name+ and +:storage_sas_token+ required, set +:storage_dns_suffix+ necessarily
      # * Specified hosts and SAS token: At least one of the service host and SAS token. It's up to user to ensure the SAS token is suitable for the serivce
      # * Anonymous Blob: only +:storage_blob_host+, if it is to only access blobs within a container
      #
      # Additional notes:
      # * Specified hosts can be set when use account name with access key or sas token
      # * +:default_endpoints_protocol+ can be set if the scheme is not specified in hosts
      # * Storage emulator always use path style URI
      # * +:ca_file+ is independent.
      #
      # When empty options are given, it will try to read settings from Environment Variables. Refer to [Azure::Storage::ClientOptions.env_vars_mapping] for the mapping relationship
      #
      # @return [Azure::Storage::Client]
      def create(options={}, &block)
        Client.new(options, &block)
      end

      # Public: Creates an instance of [Azure::Storage::Client] with Storage Emulator
      #
      # ==== Attributes
      #
      # * +proxy_uri+    - String. Used with +:use_development_storage+ if emulator is hosted other than localhost.
      #
      # @return [Azure::Storage::Client]
      def create_development(proxy_uri=nil, &block)
        proxy_uri ||= StorageServiceClientConstants::DEV_STORE_URI
        create(:use_development_storage => true, :development_storage_proxy_uri => proxy_uri, &block)
      end

      # Public: Creates an instance of [Azure::Storage::Client] from Environment Variables
      #
      # @return [Azure::Storage::Client]
      def create_from_env(&block)
        create &block
      end

      # Public: Creates an instance of [Azure::Storage::Client] from Environment Variables
      #
      # ==== Attributes
      #
      # * +connection_string+    - String. Please refer to https://azure.microsoft.com/en-us/documentation/articles/storage-configure-connection-string/.
      #
      # @return [Azure::Storage::Client]
      def create_from_connection_string(connection_string, &block)
        Client.new(connection_string, &block)
      end
    end

    private

    def default_client(opts)
      !opts.empty? ? {client: Azure::Storage.client(opts)} : {client: self} 
    end

  end
end