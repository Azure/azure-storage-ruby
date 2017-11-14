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

require "azure/core/signed_service"
require "azure/storage/core"
require "azure/storage/service/storage_service_properties"
require "azure/storage/service/storage_service_stats"

module Azure::Storage
  module Service
    # A base class for StorageService implementations
    class StorageService < Azure::Core::SignedService

      # @!attribute storage_service_host
      # @return [Hash] Get or set the storage service host
      attr_accessor :storage_service_host

      # Create a new instance of the StorageService
      #
      # @param signer         [Azure::Core::Auth::Signer] An implementation of Signer used for signing requests.
      #                                                   (optional, Default=Azure::Storage::Auth::SharedKey.new)
      # @param account_name   [String] The account name (optional, Default=Azure::Storage.storage_account_name)
      # @param options        [Azure::Storage::Configurable] the client configuration context
      def initialize(signer = nil, account_name = nil, options = {}, &block)
        StorageService.register_request_callback(&block) if block_given?
        options[:client] = Azure::Storage if options[:client] == nil
        client_config = options[:client]
        signer = signer || Azure::Storage::Core::Auth::SharedKey.new(
          client_config.storage_account_name,
          client_config.storage_access_key) if client_config.storage_access_key
        signer = signer || Azure::Storage::Core::Auth::SharedAccessSignatureSigner.new(
          client_config.storage_account_name,
          client_config.storage_sas_token)
        @storage_service_host = { primary: "", secondary: "" };
        super(signer, account_name, options)
      end

      def call(method, uri, body = nil, headers = {}, options = {})
        super(method, uri, body, StorageService.common_headers(options).merge(headers), options)
      end

      # Public: Get Storage Service properties
      #
      # See http://msdn.microsoft.com/en-us/library/azure/hh452239
      # See http://msdn.microsoft.com/en-us/library/azure/hh452243
      #
      # ==== Options
      #
      # * +:timeout+                   - Integer. A timeout in seconds.
      # * +:request_id+                - String. Provides a client-generated, opaque value with a 1 KB character limit that is recorded
      #                                  in the analytics logs when storage analytics logging is enabled.
      #
      # Returns a Hash with the service properties or nil if the operation failed
      def get_service_properties(options = {})
        query = {}
        StorageService.with_query query, "timeout", options[:timeout].to_s if options[:timeout]

        response = call(:get, service_properties_uri(query), nil, {}, options)
        Serialization.service_properties_from_xml response.body
      end

      # Public: Set Storage Service properties
      #
      # service_properties - An instance of Azure::Storage::Service::StorageServiceProperties
      #
      # See http://msdn.microsoft.com/en-us/library/azure/hh452235
      # See http://msdn.microsoft.com/en-us/library/azure/hh452232
      #
      # ==== Options
      #
      # * +:timeout+                   - Integer. A timeout in seconds.
      # * +:request_id+                - String. Provides a client-generated, opaque value with a 1 KB character limit that is recorded
      #                                  in the analytics logs when storage analytics logging is enabled.
      #
      # Returns boolean indicating success.
      def set_service_properties(service_properties, options = {})
        query = {}
        StorageService.with_query query, "timeout", options[:timeout].to_s if options[:timeout]

        body = Serialization.service_properties_to_xml service_properties
        call(:put, service_properties_uri(query), body, {}, options)
        nil
      end

      # Public: Retrieves statistics related to replication for the service. 
      # It is only available on the secondary location endpoint when read-access geo-redundant 
      # replication is enabled for the storage account. 
      #
      # See https://docs.microsoft.com/en-us/rest/api/storageservices/get-blob-service-stats
      # See https://docs.microsoft.com/en-us/rest/api/storageservices/get-queue-service-stats
      # See https://docs.microsoft.com/en-us/rest/api/storageservices/get-table-service-stats
      #
      # ==== Options
      #
      # * +:timeout+                   - Integer. A timeout in seconds.
      # * +:request_id+                - String. Provides a client-generated, opaque value with a 1 KB character limit that is recorded
      #                                  in the analytics logs when storage analytics logging is enabled.
      #
      # Returns a Hash with the service statistics or nil if the operation failed
      def get_service_stats(options = {})
        query = {}
        StorageService.with_query query, "timeout", options[:timeout].to_s if options[:timeout]

        options.update(
          location_mode: LocationMode::SECONDARY_ONLY,
          request_location_mode: RequestLocationMode::SECONDARY_ONLY)
        response = call(:get, service_stats_uri(query, options), nil, {}, options)
        Serialization.service_stats_from_xml response.body
      end

      # Public: Generate the URI for the service properties
      #
      # * +:query+ - see Azure::Storage::Services::GetServiceProperties#call documentation.
      #
      # Returns a URI.
      def service_properties_uri(query = {})
        query.update(restype: "service", comp: "properties")
        generate_uri("", query)
      end

      # Public: Generate the URI for the service statistics
      #
      # * +:query+ - see Azure::Storage::Services::GetServiceStats#call documentation.
      #
      # Returns a URI.
      def service_stats_uri(query = {}, options = {})
        query.update(restype: "service", comp: "stats")
        generate_uri("", query, options)
      end

      # Overrides the base class implementation to determine the request uri
      #
      # path    - String. the request path
      # query   - Hash. the query parameters
      #
      # ==== Options
      #
      # * +:encode+                    - bool. Specifies whether to encode the path.
      # * +:location_mode+             - LocationMode. Specifies the location mode used to decide 
      #                                  which location the request should be sent to. 
      # * +:request_location_mode+     - RequestLocationMode. Specifies the location used to indicate 
      #                                  which location the operation (REST API) can be performed against.
      #                                  This is determined by the API and cannot be specified by the users. 
      #
      # Returns the uri hash
      def generate_uri(path = "", query = {}, options = {})
        location_mode =
          if options[:location_mode].nil?
            LocationMode::PRIMARY_ONLY
          else
            options[:location_mode]
          end

        request_location_mode = 
          if options[:request_location_mode].nil?
            RequestLocationMode::PRIMARY_ONLY
          else
            request_location_mode = options[:request_location_mode]
          end

        location = StorageService.get_location location_mode, request_location_mode

        if self.client.is_a?(Azure::Storage::Client) && self.client.options[:use_path_style_uri]
          account_path = get_account_path location
          path = path.length > 0 ? account_path + "/" + path : account_path
        end

        @host = location == StorageLocation::PRIMARY ? @storage_service_host[:primary] : @storage_service_host[:secondary]

        encode = options[:encode].nil? ? false : options[:encode]
        if encode
          path = CGI.escape(path.encode("UTF-8"))

          # decode the forward slashes to match what the server expects.
          path = path.gsub(/%2F/, "/")
          # decode the backward slashes to match what the server expects.
          path = path.gsub(/%5C/, "/")
          # Re-encode the spaces (encoded as space) to the % encoding.
          path = path.gsub(/\+/, "%20")
        end

        @host = storage_service_host[:primary]
        options[:primary_uri] = super path, query

        @host = storage_service_host[:secondary]
        options[:secondary_uri] = super path, query

        if location == StorageLocation::PRIMARY
          @host = @storage_service_host[:primary]
          return options[:primary_uri]
        else
          @host = @storage_service_host[:secondary]
          return options[:secondary_uri]
        end
      end

      # Get account path according to the location settings.
      #
      # * +:location+                      - StorageLocation. Specifies the request location.
      #
      # Returns the account path
      def get_account_path(location)
        if location == StorageLocation::PRIMARY
          self.client.options[:storage_account_name]
        else
          self.client.options[:storage_account_name] + "-secondary"
        end
      end

      class << self
        # @!attribute user_agent_prefix
        # @return [Proc] Get or set the user agent prefix
        attr_accessor :user_agent_prefix

        # @!attribute request_callback
        # @return [Proc] The callback before the request is signed and sent
        attr_reader :request_callback

        # Registers the callback when sending the request
        # The headers in the request can be viewed or changed in the code block
        def register_request_callback
          @request_callback = Proc.new
        end

        # Get the request location.
        #
        # * +:location_mode+             - LocationMode. Specifies the location mode used to decide 
        #                                  which location the request should be sent to.
        # * +:request_location_mode+     - RequestLocationMode. Specifies the location used to indicate 
        #                                  which location the operation (REST API) can be performed against.
        #                                  This is determined by the API and cannot be specified by the users. 
        #
        # Returns the reqeust location
        def get_location(location_mode, request_location_mode)
          if request_location_mode == RequestLocationMode::PRIMARY_ONLY && location_mode == LocationMode::SECONDARY_ONLY
            raise InvalidOptionsError, "This operation can only be executed against the primary storage location."
          end

          if request_location_mode == RequestLocationMode::SECONDARY_ONLY && location_mode == LocationMode::PRIMARY_ONLY
            raise InvalidOptionsError, "This operation can only be executed against the secondary storage location."
          end

          if request_location_mode == RequestLocationMode::PRIMARY_ONLY
            return StorageLocation::PRIMARY
          elsif request_location_mode == RequestLocationMode::SECONDARY_ONLY
            return StorageLocation::SECONDARY
          end

          if location_mode == LocationMode::PRIMARY_ONLY || location_mode == LocationMode::PRIMARY_THEN_SECONDARY
            StorageLocation::PRIMARY
          elsif location_mode == LocationMode::SECONDARY_ONLY || location_mode == LocationMode::SECONDARY_THEN_PRIMARY
            StorageLocation::SECONDARY
          end
        end

        # Adds metadata properties to header hash with required prefix
        #
        # * +:metadata+  - A Hash of metadata name/value pairs
        # * +:headers+   - A Hash of HTTP headers
        def add_metadata_to_headers(metadata, headers)
          if metadata
            metadata.each do |key, value|
              headers["x-ms-meta-#{key}"] = value
            end
          end
        end

        # Adds a value to the Hash object
        #
        # * +:object+     - A Hash object
        # * +:key+        - The key name
        # * +:value+      - The value
        def with_value(object, key, value)
          object[key] = value if value
        end

        # Adds a header with the value
        #
        # * +:headers+    - A Hash of HTTP headers
        # * +:name+       - The header name
        # * +:value+      - The value
        alias with_header with_value

        # Adds a query parameter
        #
        # * +:query+      - A Hash of HTTP query
        # * +:name+       - The parameter name
        # * +:value+      - The value
        alias with_query with_value

        # Declares a default hash object for request headers
        def common_headers(options = {})
          headers = {
            "x-ms-version" => Azure::Storage::Default::STG_VERSION,
            "User-Agent" => user_agent_prefix ? "#{user_agent_prefix}; #{Azure::Storage::Default::USER_AGENT}" : Azure::Storage::Default::USER_AGENT
          }
          headers.merge!("x-ms-client-request-id" => options[:request_id]) if options[:request_id]
          @request_callback.call(headers) if @request_callback
          headers
        end
      end
    end
  end
end
