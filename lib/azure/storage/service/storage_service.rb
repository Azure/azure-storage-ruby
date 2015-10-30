#-------------------------------------------------------------------------
# # Copyright (c) Microsoft and contributors. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#--------------------------------------------------------------------------

require 'azure/storage/core/signed_service'
require 'azure/storage/core'
require 'azure/storage/service/storage_service_properties'

module Azure::Storage
  module Service
    # A base class for StorageService implementations
    class StorageService < Azure::Core::SignedService
      # Create a new instance of the StorageService
      #
      # @param signer         [Azure::Core::Auth::Signer] An implementation of Signer used for signing requests.
      # (optional, Default=Azure::Storage::Auth::SharedKey.new)
      # @param account_name   [String] The account name (optional, Default=Azure.config.storage_account_name)
      # @param options        [Azure::Storage::Configurable] the client configuration context
      def initialize(signer=Auth::SharedKey.new, account_name=nil, options = {})
        super(signer, account_name, options)
      end

      def call(method, uri, body=nil, headers={})
        super(method, uri, body, service_properties_headers.merge(headers))
      end


      # Public: Get Storage Service properties
      #
      # See http://msdn.microsoft.com/en-us/library/azure/hh452239
      # See http://msdn.microsoft.com/en-us/library/azure/hh452243
      #
      # Returns a Hash with the service properties or nil if the operation failed
      def get_service_properties
        uri = service_properties_uri
        response = call(:get, uri)
        Serialization.service_properties_from_xml response.body
      end

      # Public: Set Storage Service properties
      #
      # service_properties - An instance of Azure::Storage::Entity::Service::StorageServiceProperties
      #
      # See http://msdn.microsoft.com/en-us/library/azure/hh452235
      # See http://msdn.microsoft.com/en-us/library/azure/hh452232
      #
      # Returns boolean indicating success.
      def set_service_properties(service_properties)
        body = Serialization.service_properties_to_xml service_properties

        uri = service_properties_uri
        call(:put, uri, body)
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

      # Adds metadata properties to header hash with required prefix
      #
      # metadata  - A Hash of metadata name/value pairs
      # headers   - A Hash of HTTP headers
      def add_metadata_to_headers(metadata, headers)
        metadata.each do |key, value|
          headers["x-ms-meta-#{key}"] = value
        end
      end

      def service_properties_headers
        {
          'x-ms-version' => Azure::Storage::Default::STG_VERSION,
          'User-Agent' => Azure::Storage::Default::USER_AGENT
        }
      end

    end
  end
end
