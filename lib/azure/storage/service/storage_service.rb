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

require 'azure/core/signed_service'
require 'azure/storage/core'
require 'azure/storage/service/storage_service_properties'

module Azure::Storage
  module Service
    # A base class for StorageService implementations
    class StorageService < Azure::Core::SignedService
      # Create a new instance of the StorageService
      #
      # @param signer         [Azure::Core::Auth::Signer] An implementation of Signer used for signing requests.
      #                                                   (optional, Default=Azure::Storage::Auth::SharedKey.new)
      # @param account_name   [String] The account name (optional, Default=Azure::Storage.storage_account_name)
      # @param options        [Azure::Storage::Configurable] the client configuration context
      def initialize(signer=nil, account_name=nil, options = {}, &block)
        StorageService.register_request_callback &block if block_given?
        options[:client] = Azure::Storage if options[:client] == nil
        client_config = options[:client]
        signer = signer || Azure::Storage::Core::Auth::SharedKey.new(
          client_config.storage_account_name,
          client_config.storage_access_key) if client_config.storage_access_key
        signer = signer || Azure::Storage::Core::Auth::SharedAccessSignatureSigner.new(
          client_config.storage_account_name,
          client_config.storage_sas_token)
        super(signer, account_name, options)
      end

      def call(method, uri, body=nil, headers={}, options={})
        super(method, uri, body, StorageService.common_headers(options).merge(headers))
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
      def get_service_properties(options={})
        query = { }
        StorageService.with_query query, 'timeout', options[:timeout].to_s if options[:timeout]

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
      def set_service_properties(service_properties, options={})
        query = { }
        StorageService.with_query query, 'timeout', options[:timeout].to_s if options[:timeout]

        body = Serialization.service_properties_to_xml service_properties
        call(:put, service_properties_uri(query), body, {}, options)
        nil
      end

      # Public: Generate the URI for the service properties
      #
      # query - see Azure::Storage::Services::GetServiceProperties#call documentation.
      #
      # Returns a URI.
      def service_properties_uri(query={})
        query.update(restype: 'service', comp: 'properties')
        generate_uri('', query)
      end

      # Overrides the base class implementation to determine the request uri
      #
      # path    - String. the request path
      # query   - Hash. the query parameters
      #
      # Returns the uri hash
      def generate_uri(path='', query={}, encode=false)
        if self.client.is_a?(Azure::Storage::Client) && self.client.options[:use_path_style_uri]
          if path.length > 0
            path = self.client.options[:storage_account_name] + '/' + path
          else
            path = self.client.options[:storage_account_name]
          end
        end

        if encode
          path = CGI.escape(path.encode('UTF-8'))

          # decode the forward slashes to match what the server expects.
          path = path.gsub(/%2F/, '/')
          # decode the backward slashes to match what the server expects.
          path = path.gsub(/%5C/, '/')
          # Re-encode the spaces (encoded as space) to the % encoding.
          path = path.gsub(/\+/, '%20')
        end

        super path, query
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

        # Adds metadata properties to header hash with required prefix
        #
        # metadata  - A Hash of metadata name/value pairs
        # headers   - A Hash of HTTP headers
        def add_metadata_to_headers(metadata, headers)
          if metadata
            metadata.each do |key, value|
              headers["x-ms-meta-#{key}"] = value
            end
          end
        end
        
        # Adds a value to the Hash object
        #
        # object     - A Hash object
        # key        - The key name
        # value      - The value
        def with_value(object, key, value)
          object[key] = value if value
        end

        # Adds a header with the value
        #
        # headers    - A Hash of HTTP headers
        # name       - The header name
        # value      - The value
        alias with_header with_value
        
        # Adds a query parameter
        #
        # query      - A Hash of HTTP query
        # name       - The parameter name
        # value      - The value
        alias with_query with_value
        
        # Declares a default hash object for request headers
        def common_headers(options = {})
          headers = {
            'x-ms-version' => Azure::Storage::Default::STG_VERSION,
            'User-Agent' => user_agent_prefix ? "#{user_agent_prefix}; #{Azure::Storage::Default::USER_AGENT}" : Azure::Storage::Default::USER_AGENT
          }
          headers.merge!({'x-ms-client-request-id' => options[:request_id]}) if options[:request_id]
          @request_callback.call(headers) if @request_callback
          headers
        end
      end

    end
  end
end