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
require "azure/storage/file/file"

module Azure::Storage
  include Azure::Storage::Common::Service
  StorageService = Azure::Storage::Common::Service::StorageService

  module File
    class FileService < StorageService
      include Azure::Storage::Common::Core::Utility
      include Azure::Storage::File::Share
      include Azure::Storage::File::Directory
      include Azure::Storage::File

      class << self
        # Public: Creates an instance of [Azure::Storage::File::FileService]
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
        # * +:storage_file_host+              - String. Specified File service endpoint or hostname
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
        # * Anonymous File: only +:storage_file_host+, if it is to only access files within a container
        #
        # Additional notes:
        # * Specified hosts can be set when use account name with access key or sas token
        # * +:default_endpoints_protocol+ can be set if the scheme is not specified in hosts
        # * Storage emulator always use path style URI
        # * +:ca_file+ is independent.
        #
        # When empty options are given, it will try to read settings from Environment Variables. Refer to [Azure::Storage::Common::ClientOptions.env_vars_mapping] for the mapping relationship
        #
        # @return [Azure::Storage::File::FileService]
        def create(options = {}, &block)
          service_options = { client: Azure::Storage::Common::Client::create(options, &block), api_version: Azure::Storage::File::Default::STG_VERSION }
          service_options[:user_agent_prefix] = options[:user_agent_prefix] if options[:user_agent_prefix]
          Azure::Storage::File::FileService.new(service_options, &block)
        end

        # Public: Creates an instance of [Azure::Storage::File::FileService] with Storage Emulator
        #
        # ==== Attributes
        #
        # * +proxy_uri+    - String. Used with +:use_development_storage+ if emulator is hosted other than localhost.
        #
        # @return [Azure::Storage::File::FileService]
        def create_development(proxy_uri = nil, &block)
          service_options = { client: Azure::Storage::Common::Client::create_development(proxy_uri, &block), api_version: Azure::Storage::File::Default::STG_VERSION }
          Azure::Storage::File::FileService.new(service_options, &block)
        end

        # Public: Creates an instance of [Azure::Storage::File::FileService] from Environment Variables
        #
        # @return [Azure::Storage::File::FileService]
        def create_from_env(&block)
          service_options = { client: Azure::Storage::Common::Client::create_from_env(&block), api_version: Azure::Storage::File::Default::STG_VERSION }
          Azure::Storage::File::FileService.new(service_options, &block)
        end

        # Public: Creates an instance of [Azure::Storage::File::FileService] from Environment Variables
        #
        # ==== Attributes
        #
        # * +connection_string+    - String. Please refer to https://azure.microsoft.com/en-us/documentation/articles/storage-configure-connection-string/.
        #
        # @return [Azure::Storage::File::FileService]
        def create_from_connection_string(connection_string, &block)
          service_options = { client: Azure::Storage::Common::Client::create_from_connection_string(connection_string, &block), api_version: Azure::Storage::File::Default::STG_VERSION }
          Azure::Storage::File::FileService.new(service_options, &block)
        end
      end

      # Public: Initializes an instance of [Azure::Storage::File::FileService]
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
      # * +:storage_file_host+              - String. Specified File serivce endpoint or hostname
      # * +:storage_table_host+             - String. Specified Table serivce endpoint or hostname
      # * +:storage_queue_host+             - String. Specified Queue serivce endpoint or hostname
      # * +:storage_dns_suffix+             - String. The suffix of a regional Storage Serivce, to
      # * +:default_endpoints_protocol+     - String. http or https
      # * +:use_path_style_uri+             - String. Whether use path style URI for specified endpoints
      # * +:ca_file+                        - String. File path of the CA file if having issue with SSL
      # * +:user_agent_prefix+              - String. The user agent prefix that can identify the application calls the library
      # * +:client+                         - Azure::Storage::Common::Client. The common client used to initalize the service.
      #
      # The valid set of options include:
      # * Storage Emulator: +:use_development_storage+ required, +:development_storage_proxy_uri+ optionally
      # * Storage account name and key: +:storage_account_name+ and +:storage_access_key+ required, set +:storage_dns_suffix+ necessarily
      # * Storage account name and SAS token: +:storage_account_name+ and +:storage_sas_token+ required, set +:storage_dns_suffix+ necessarily
      # * Specified hosts and SAS token: At least one of the service host and SAS token. It's up to user to ensure the SAS token is suitable for the serivce
      # * Azure::Storage::Common::Client: The common client used to initalize the service. This client can be initalized and used repeatedly.
      # * Anonymous File: only +:storage_file_host+, if it is to only access files within a container
      #
      # Additional notes:
      # * Specified hosts can be set when use account name with access key or sas token
      # * +:default_endpoints_protocol+ can be set if the scheme is not specified in hosts
      # * Storage emulator always use path style URI
      # * +:ca_file+ is independent.
      #
      # When empty options are given, it will try to read settings from Environment Variables. Refer to [Azure::Storage::Common::ClientOptions.env_vars_mapping] for the mapping relationship
      def initialize(options = {}, &block)
        service_options = options.clone
        client_config = service_options[:client] ||= Azure::Storage::Common::Client::create(service_options, &block)
        @user_agent_prefix = service_options[:user_agent_prefix] if service_options[:user_agent_prefix]
        @api_version = service_options[:api_version] || Azure::Storage::File::Default::STG_VERSION
        signer = service_options[:signer] || client_config.signer || Azure::Storage::Common::Core::Auth::SharedKey.new(client_config.storage_account_name, client_config.storage_access_key)
        signer.api_ver = @api_version if signer.is_a? Azure::Storage::Common::Core::Auth::SharedAccessSignatureSigner
        super(signer, client_config.storage_account_name, service_options, &block)
        @storage_service_host[:primary] = client.storage_file_host
        @storage_service_host[:secondary] = client.storage_file_host true
      end

      def call(method, uri, body = nil, headers = {}, options = {})
        content_type = get_or_apply_content_type(body, headers[Azure::Storage::Common::HeaderConstants::FILE_CONTENT_TYPE])
        headers[Azure::Storage::Common::HeaderConstants::FILE_CONTENT_TYPE] = content_type if content_type
        headers["x-ms-version"] = @api_version ? @api_version : Default::STG_VERSION
        headers["User-Agent"] = @user_agent_prefix ? "#{@user_agent_prefix}; #{Default::USER_AGENT}" : Default::USER_AGENT

        response = super

        # Force the response.body to the content charset of specified in the header.
        # Content-Type is echo'd back for the file and is used to store the encoding of the octet stream
        if !response.nil? && !response.body.nil? && response.headers["Content-Type"]
          charset = parse_charset_from_content_type(response.headers["Content-Type"])
          response.body.force_encoding(charset) if charset && charset.length > 0
        end

        response
      end

      # Public: Get a list of Shares from the server.
      #
      # ==== Attributes
      #
      # * +options+                  - Hash. Optional parameters.
      #
      # ==== Options
      #
      # Accepted key/value pairs in options parameter are:
      # * +:prefix+                  - String. Filters the results to return only shares
      #                                whose name begins with the specified prefix. (optional)
      #
      # * +:marker+                  - String. An identifier the specifies the portion of the
      #                                list to be returned. This value comes from the property
      #                                Azure::Storage::Common::EnumerationResults.continuation_token when there
      #                                are more shares available than were returned. The
      #                                marker value may then be used here to request the next set
      #                                of list items. (optional)
      #
      # * +:max_results+             - Integer. Specifies the maximum number of shares to return.
      #                                If max_results is not specified, or is a value greater than
      #                                5,000, the server will return up to 5,000 items. If it is set
      #                                to a value less than or equal to zero, the server will return
      #                                status code 400 (Bad Request). (optional)
      #
      # * +:metadata+                - Boolean. Specifies whether or not to return the share metadata.
      #                                (optional, Default=false)
      #
      # * +:timeout+                 - Integer. A timeout in seconds.
      #
      # * +:request_id+              - String. Provides a client-generated, opaque value with a 1 KB character limit that is recorded
      #                                in the analytics logs when storage analytics logging is enabled.
      #
      # * +:location_mode+           - LocationMode. Specifies the location mode used to decide 
      #                                which location the request should be sent to.
      #
      # See: https://docs.microsoft.com/en-us/rest/api/storageservices/fileservices/list-shares
      #
      # Returns an Azure::Storage::Common::EnumerationResults
      #
      def list_shares(options = {})
        query = {}
        if options
          StorageService.with_query query, "prefix", options[:prefix]
          StorageService.with_query query, "marker", options[:marker]
          StorageService.with_query query, "maxresults", options[:max_results].to_s if options[:max_results]
          StorageService.with_query query, "include", "metadata" if options[:metadata] == true
          StorageService.with_query query, "timeout", options[:timeout].to_s if options[:timeout]
        end

        options[:request_location_mode] = Azure::Storage::Common::RequestLocationMode::PRIMARY_OR_SECONDARY
        uri = shares_uri(query, options)
        response = call(:get, uri, nil, {}, options)

        Serialization.share_enumeration_results_from_xml(response.body)
      end

      # Protected: Generate the URI for the collection of shares.
      #
      # ==== Attributes
      #
      # * +query+ - A Hash of key => value query parameters.
      #
      # Returns a URI.
      #
      protected
        def shares_uri(query = {}, options = {})
          query = { "comp" => "list" }.merge(query)
          generate_uri("", query, options)
        end

      # Protected: Generate the URI for a specific share.
      #
      # ==== Attributes
      #
      # * +name+  - The share name. If this is a URI, we just return this.
      # * +query+ - A Hash of key => value query parameters.
      #
      # Returns a URI.
      #
      protected
        def share_uri(name, query = {}, options = {})
          return name if name.kind_of? ::URI
          query = { restype: "share" }.merge(query)
          generate_uri(name, query, options)
        end

      # Protected: Generate the URI for a specific directory.
      #
      # ==== Attributes
      #
      # * +share+                 - String representing the name of the share.
      # * +directory_path+        - String representing the path to the directory.
      # * +directory+             - String representing the name to the directory.
      # * +query+                 - A Hash of key => value query parameters.
      #
      # Returns a URI.
      #
      protected
        def directory_uri(share, directory_path, query = {}, options = {})
          path = directory_path.nil? ? share : ::File.join(share, directory_path)
          query = { restype: "directory" }.merge(query)
          options = { encode: true }.merge(options)
          generate_uri(path, query, options)
        end

      # Protected: Generate the URI for a specific file.
      #
      # ==== Attributes
      #
      # * +share+                 - String representing the name of the share.
      # * +directory_path+        - String representing the path to the directory.
      # * +file+                  - String representing the name to the file.
      # * +query+                 - A Hash of key => value query parameters.
      #
      # Returns a URI.
      #
      protected
        def file_uri(share, directory_path, file, query = {}, options = {})
          if directory_path.nil?
            path = ::File.join(share, file)
          else
            path = ::File.join(share, directory_path, file)
          end
          options = { encode: true }.merge(options)
          generate_uri(path, query, options)
        end

      # Get the content type according to the content type header and request body.
      #
      # headers      - The request body
      # content_type - The request content type
      protected
        def get_or_apply_content_type(body, content_type = nil)
          unless body.nil?
            if (body.is_a? String) && body.encoding.to_s != "ASCII_8BIT" && !body.empty?
              if content_type.nil?
                content_type = "text/plain; charset=#{body.encoding}"
              else
                # Force the request.body to the content encoding of specified in the header
                charset = parse_charset_from_content_type(content_type)
                body.force_encoding(charset) if charset
              end
            else
              # It is either that the body is not a string, or that the body's encoding is ASCII_8BIT, which is a binary
              # In this case, set the content type to be default content-type
              content_type = Default::CONTENT_TYPE_VALUE unless content_type
            end
          end
          content_type
        end
    end
  end
end

Azure::Storage::FileService = Azure::Storage::File::FileService
