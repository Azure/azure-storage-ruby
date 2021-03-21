# frozen_string_literal: true

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

module Azure::Storage::Common
  class Client
    include Azure::Storage::Common::Configurable
    include Azure::Storage::Common::ClientOptions
    include Azure::Storage::Common::Core::HttpClient

    # Public: Creates an instance of [Azure::Storage::Common::Client]
    #
    # ==== Attributes
    #
    # * +options+    - Hash. Optional parameters.
    #
    # ==== Options
    #
    # Accepted key/value pairs in options parameter are:
    #
    # * +:use_development_storage+        - TrueClass|FalseClass. Whether to use storage emulator.
    # * +:development_storage_proxy_uri+  - String. Used with +:use_development_storage+ if emulator is hosted other than localhost.
    # * +:storage_connection_string+      - String. The storage connection string.
    # * +:storage_account_name+           - String. The name of the storage account.
    # * +:storage_access_key+             - Base64 String. The access key of the storage account.
    # * +:storage_sas_token+              - String. The signed access signature for the storage account or one of its service.
    # * +:storage_blob_host+              - String. Specified Blob serivce endpoint or hostname
    # * +:storage_table_host+             - String. Specified Table serivce endpoint or hostname
    # * +:storage_queue_host+             - String. Specified Queue serivce endpoint or hostname
    # * +:storage_dns_suffix+             - String. The suffix of a regional Storage Serivce, to
    # * +:default_endpoints_protocol+     - String. http or https
    # * +:use_path_style_uri+             - String. Whether use path style URI for specified endpoints
    # * +:ca_file+                        - String. File path of the CA file if having issue with SSL
    # * +:user_agent_prefix+              - String. The user agent prefix that can identify the application calls the library
    #
    # The valid set of options include:
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
    # When empty options are given, it will try to read settings from Environment Variables. Refer to [Azure::Storage::Common::ClientOptions.env_vars_mapping] for the mapping relationship
    #
    # @return [Azure::Storage::Common::Client]
    def initialize(options = {}, &block)
      if options.is_a?(Hash) && options.has_key?(:user_agent_prefix)
        Azure::Storage::Common::Service::StorageService.user_agent_prefix = options[:user_agent_prefix]
        options.delete :user_agent_prefix
      end
      Azure::Storage::Common::Service::StorageService.register_request_callback(&block) if block_given?
      reset!(options)
    end

    class << self
      # Public: Creates an instance of [Azure::Storage::Common::Client]
      #
      # ==== Attributes
      #
      # * +options+    - Hash. Optional parameters.
      #
      # ==== Options
      #
      # Accepted key/value pairs in options parameter are:
      #
      # * +:use_development_storage+        - TrueClass|FalseClass. Whether to use storage emulator.
      # * +:development_storage_proxy_uri+  - String. Used with +:use_development_storage+ if emulator is hosted other than localhost.
      # * +:storage_account_name+           - String. The name of the storage account.
      # * +:storage_access_key+             - Base64 String. The access key of the storage account.
      # * +:storage_sas_token+              - String. The signed access signature for the storage account or one of its service.
      # * +:storage_blob_host+              - String. Specified Blob service endpoint or hostname
      # * +:storage_table_host+             - String. Specified Table service endpoint or hostname
      # * +:storage_queue_host+             - String. Specified Queue service endpoint or hostname
      # * +:storage_dns_suffix+             - String. The suffix of a regional Storage Service, to
      # * +:default_endpoints_protocol+     - String. http or https
      # * +:use_path_style_uri+             - String. Whether use path style URI for specified endpoints
      # * +:ca_file+                        - String. File path of the CA file if having issue with SSL
      # * +:ssl_version+                    - Symbol. The ssl version to be used, sample: :TLSv1_1, :TLSv1_2, for the details, see https://github.com/ruby/openssl/blob/master/lib/openssl/ssl.rb
      # * +:ssl_min_version+                - Symbol. The min ssl version supported, only supported in Ruby 2.5+
      # * +:ssl_max_version+                - Symbol. The max ssl version supported, only supported in Ruby 2.5+
      # * +:user_agent_prefix+              - String. The user agent prefix that can identify the application calls the library
      #
      # The valid set of options include:
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
      # When empty options are given, it will try to read settings from Environment Variables. Refer to [Azure::Storage::Common::ClientOptions.env_vars_mapping] for the mapping relationship
      #
      # @return [Azure::Storage::Common::Client]
      def create(options = {}, &block)
        Client.new(options, &block)
      end

      # Public: Creates an instance of [Azure::Storage::Common::Client] with Storage Emulator
      #
      # ==== Attributes
      #
      # * +proxy_uri+    - String. Used with +:use_development_storage+ if emulator is hosted other than localhost.
      #
      # @return [Azure::Storage::Common::Client]
      def create_development(proxy_uri = nil, &block)
        proxy_uri ||= StorageServiceClientConstants::DEV_STORE_URI
        create(use_development_storage: true, development_storage_proxy_uri: proxy_uri, &block)
      end

      # Public: Creates an instance of [Azure::Storage::Common::Client] from Environment Variables
      #
      # @return [Azure::Storage::Client]
      def create_from_env(&block)
        create(&block)
      end

      # Public: Creates an instance of [Azure::Storage::Common::Client] from Environment Variables
      #
      # ==== Attributes
      #
      # * +connection_string+    - String. Please refer to https://azure.microsoft.com/en-us/documentation/articles/storage-configure-connection-string/.
      #
      # @return [Azure::Storage::Common::Client]
      def create_from_connection_string(connection_string, &block)
        Client.new(connection_string, &block)
      end
    end
  end
end
