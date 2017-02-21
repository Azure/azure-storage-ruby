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
require 'azure/storage/file/serialization'

module Azure::Storage::File
  module Share
    include Azure::Storage::Service
    
    class Share
      def initialize
        @properties = {}
        @metadata = {}
        yield self if block_given?
      end

      attr_accessor :name
      attr_accessor :properties
      attr_accessor :metadata
      attr_accessor :quota
      attr_accessor :usage
    end

    # Public: Create a new share
    #
    # ==== Attributes
    #
    # * +name+                      - String. The name of the share.
    # * +options+                   - Hash. Optional parameters.
    #
    # ==== Options
    #
    # Accepted key/value pairs in options parameter are:
    # * +:metadata+                 - Hash. User defined metadata for the share (optional).
    # * +:quota+                    - Integer. The maximum size of the share, in gigabytes.
    #                                 Must be greater than 0, and less than or equal to 5TB (5120). (optional).
    # * +:timeout+                  - Integer. A timeout in seconds.
    # * +:request_id+               - String. Provides a client-generated, opaque value with a 1 KB character limit that is recorded 
    #                                 in the analytics logs when storage analytics logging is enabled.
    #
    # See https://docs.microsoft.com/en-us/rest/api/storageservices/fileservices/create-share
    #
    # Returns a Share
    def create_share(name, options={})
      # Query
      query = { }
      query['timeout'] = options[:timeout].to_s if options[:timeout]

      # Scheme + path
      uri = share_uri(name, query)

      # Headers
      headers = StorageService.common_headers
      StorageService.add_metadata_to_headers(options[:metadata], headers) if options[:metadata]
      headers['x-ms-share-quota'] = options[:quota].to_s if options[:quota]

      # Call
      response = call(:put, uri, nil, headers, options)

      # result
      share = Serialization.share_from_headers(response.headers)
      share.name = name
      share.quota = options[:quota] if options[:quota]
      share.metadata = options[:metadata] if options[:metadata]
      share
    end

    # Public: Returns all properties and metadata on the share.
    #
    # ==== Attributes
    #
    # * +name+                      - String. The name of the share
    # * +options+                   - Hash. Optional parameters.
    #
    # ==== Options
    #
    # Accepted key/value pairs in options parameter are:
    # * +:timeout+                  - Integer. A timeout in seconds.
    # * +:request_id+               - String. Provides a client-generated, opaque value with a 1 KB character limit that is recorded 
    #                                 in the analytics logs when storage analytics logging is enabled.
    #
    # See https://docs.microsoft.com/en-us/rest/api/storageservices/fileservices/get-share-properties
    #
    # Returns a Share
    def get_share_properties(name, options={})
      # Query
      query = { }
      query['timeout'] = options[:timeout].to_s if options[:timeout]

      # Call
      response = call(:get, share_uri(name, query), nil, {}, options)

      # result
      share = Serialization.share_from_headers(response.headers)
      share.name = name
      share
    end

    # Public: Sets service-defined properties for the share.
    #
    # ==== Attributes
    #
    # * +name+                      - String. The name of the share
    # * +options+                   - Hash. Optional parameters.
    #
    # ==== Options
    #
    # Accepted key/value pairs in options parameter are:
    # * +:quota+                    - Integer. The maximum size of the share, in gigabytes.
    #                                 Must be greater than 0, and less than or equal to 5TB (5120). (optional).
    # * +:timeout+                  - Integer. A timeout in seconds.
    # * +:request_id+               - String. Provides a client-generated, opaque value with a 1 KB character limit that is recorded 
    #                                 in the analytics logs when storage analytics logging is enabled.
    #
    # See https://docs.microsoft.com/en-us/rest/api/storageservices/fileservices/set-share-properties
    #
    # Returns nil on success
    def set_share_properties(name, options={})
      # Query
      query = { 'comp' => 'properties' }
      query['timeout'] = options[:timeout].to_s if options[:timeout]

      # Headers
      headers = StorageService.common_headers
      headers['x-ms-share-quota'] = options[:quota].to_s if options[:quota]

      # Call
      call(:put, share_uri(name, query), nil, headers, options)
      
      # Result
      nil
    end

    # Public: Returns only user-defined metadata for the specified share.
    #
    # ==== Attributes
    #
    # * +name+                      - String. The name of the share
    # * +options+                   - Hash. Optional parameters.
    #
    # ==== Options
    #
    # Accepted key/value pairs in options parameter are:
    # * +:timeout+                  - Integer. A timeout in seconds.
    # * +:request_id+               - String. Provides a client-generated, opaque value with a 1 KB character limit that is recorded 
    #                                 in the analytics logs when storage analytics logging is enabled.
    #
    # See https://docs.microsoft.com/en-us/rest/api/storageservices/fileservices/get-share-metadata
    #
    # Returns a Share
    def get_share_metadata(name, options={})
      # Query
      query = { 'comp' => 'metadata' }
      query['timeout'] = options[:timeout].to_s if options[:timeout]

      # Call
      response = call(:get, share_uri(name, query), nil, {}, options)

      # result
      share = Serialization.share_from_headers(response.headers)
      share.name = name
      share
    end

    # Public: Sets custom metadata for the share.
    #
    # ==== Attributes
    #
    # * +name+                      - String. The name of the share
    # * +metadata+                  - Hash. A Hash of the metadata values
    # * +options+                   - Hash. Optional parameters.
    #
    # ==== Options
    #
    # Accepted key/value pairs in options parameter are:
    # * +:timeout+                  - Integer. A timeout in seconds.
    # * +:request_id+               - String. Provides a client-generated, opaque value with a 1 KB character limit that is recorded 
    #                                 in the analytics logs when storage analytics logging is enabled.
    #
    # See https://docs.microsoft.com/en-us/rest/api/storageservices/fileservices/set-share-metadata
    #
    # Returns nil on success
    def set_share_metadata(name, metadata, options={})
      # Query
      query = { 'comp' => 'metadata' }
      query['timeout'] = options[:timeout].to_s if options[:timeout]

      # Headers
      headers = StorageService.common_headers
      StorageService.add_metadata_to_headers(metadata, headers) if metadata

      # Call
      call(:put, share_uri(name, query), nil, headers, options)
      
      # Result
      nil
    end

    # Public: Deletes a share.
    #
    # ==== Attributes
    #
    # * +name+                      - String. The name of the share.
    # * +options+                   - Hash. Optional parameters.
    #
    # ==== Options
    #
    # Accepted key/value pairs in options parameter are:
    # * +:timeout+                  - Integer. A timeout in seconds.
    # * +:request_id+               - String. Provides a client-generated, opaque value with a 1 KB character limit that is recorded 
    #                                 in the analytics logs when storage analytics logging is enabled.
    #
    # See https://docs.microsoft.com/en-us/rest/api/storageservices/fileservices/delete-share
    #
    # Returns nil on success
    def delete_share(name, options={})
      # Query
      query = { }
      query['timeout'] = options[:timeout].to_s if options[:timeout]

      # Call
      call(:delete, share_uri(name, query), nil, {}, options)
      
      # result
      nil
    end

    # Public: Gets the information about stored access policies for the share.
    #
    # ==== Attributes
    #
    # * +name+                      - String. The name of the share
    # * +options+                   - Hash. Optional parameters.
    #
    # ==== Options
    #
    # Accepted key/value pairs in options parameter are:
    # * +:timeout+                  - Integer. A timeout in seconds.
    # * +:request_id+               - String. Provides a client-generated, opaque value with a 1 KB character limit that is recorded 
    #                                 in the analytics logs when storage analytics logging is enabled.
    #
    # See https://docs.microsoft.com/en-us/rest/api/storageservices/fileservices/get-share-acl
    #
    # Returns a tuple of (share, signed_identifiers)
    #   share                       - A Azure::Storage::File::Share::Share instance
    #   signed_identifiers          - A list of Azure::Storage::Service::SignedIdentifier instances
    #
    def get_share_acl(name, options={})
      # Query
      query = { 'comp' => 'acl' }
      query['timeout'] = options[:timeout].to_s if options[:timeout]
      
      # Call
      response = call(:get, share_uri(name, query), nil, {}, options)

      # Result
      share = Serialization.share_from_headers(response.headers)
      share.name = name

      signed_identifiers = nil
      signed_identifiers = Serialization.signed_identifiers_from_xml(response.body) if response.body != nil && response.body.length > 0

      return share, signed_identifiers
    end

    # Public: Sets stored access policies the share.
    #
    # ==== Attributes
    #
    # * +name+                         - String. The name of the share
    # * +options+                      - Hash. Optional parameters.
    #
    # ==== Options
    #
    # Accepted key/value pairs in options parameter are:
    # * +:signed_identifiers+          - Array. A list of Azure::Storage::Service::SignedIdentifier instances.
    # * +:timeout+                     - Integer. A timeout in seconds.
    # * +:request_id+                  - String. Provides a client-generated, opaque value with a 1 KB character limit that is recorded 
    #                                    in the analytics logs when storage analytics logging is enabled.
    # 
    # See https://docs.microsoft.com/en-us/rest/api/storageservices/fileservices/set-share-acl
    #
    # Returns a tuple of (share, signed_identifiers)
    # * +share+                        - A Azure::Storage::File::Share::Share instance
    # * +signed_identifiers+           - A list of Azure::Storage::Service::SignedIdentifier instances
    #
    def set_share_acl(name, options={})
      # Query
      query = { 'comp' => 'acl' }
      query['timeout'] = options[:timeout].to_s if options[:timeout]

      # Scheme + path
      uri = share_uri(name, query)

      # Headers + body
      headers = StorageService.common_headers

      signed_identifiers = options[:signed_identifiers] ? options[:signed_identifiers] : nil
      body = signed_identifiers ? Serialization.signed_identifiers_to_xml(signed_identifiers) : nil

      # Call
      response = call(:put, uri, body, headers, options)

      # Result
      share = Serialization.share_from_headers(response.headers)
      share.name = name

      return share, signed_identifiers || []
    end

    # Public: Retrieves statistics related to the share.
    #
    # ==== Attributes
    #
    # * +name+                      - String. The name of the share
    # * +options+                   - Hash. Optional parameters.
    #
    # ==== Options
    #
    # Accepted key/value pairs in options parameter are:
    # * +:timeout+                  - Integer. A timeout in seconds.
    # * +:request_id+               - String. Provides a client-generated, opaque value with a 1 KB character limit that is recorded 
    #                                 in the analytics logs when storage analytics logging is enabled.
    #
    # See https://docs.microsoft.com/en-us/rest/api/storageservices/fileservices/get-share-stats
    #
    # Returns a Share
    def get_share_stats(name, options={})
      # Query
      query = { 'comp' => 'stats' }
      query['timeout'] = options[:timeout].to_s if options[:timeout]

      # Call
      response = call(:get, share_uri(name, query), nil, {}, options)

      # result
      share = Serialization.share_from_headers(response.headers)
      share.name = name
      share.usage = Serialization.share_stats_from_xml(response.body)
      share
    end
  end
end