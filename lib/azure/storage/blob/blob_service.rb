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
require 'base64'
require 'azure/storage/core/auth/shared_key'
require 'azure/storage/blob/container'
require 'azure/storage/blob/blob'
require 'azure/storage/blob/block'
require 'azure/storage/blob/page'
require 'azure/storage/blob/append'

module Azure::Storage
  include Service
  
  module Blob
    class BlobService < StorageService
      include Azure::Storage::Core::Utility
      include Azure::Storage::Blob
      include Azure::Storage::Blob::Container
      
      def initialize(options = {}, &block)
        client_config = options[:client] || Azure::Storage
        signer = options[:signer] || client_config.signer || Azure::Storage::Core::Auth::SharedKey.new(client_config.storage_account_name, client_config.storage_access_key)
        super(signer, client_config.storage_account_name, options, &block)
        @host = client.storage_blob_host
      end

      def call(method, uri, body=nil, headers={}, options={})
        # Force the request.body to the content encoding of specified in the header
        if headers && !body.nil? && (body.is_a? String) && ((body.encoding.to_s <=> 'ASCII_8BIT') != 0)
          if headers['x-ms-blob-content-type'].nil?
            Service::StorageService.with_header headers, 'x-ms-blob-content-type', "text/plain; charset=#{body.encoding}"
          else
            charset = parse_charset_from_content_type(headers['x-ms-blob-content-type'])
            body.force_encoding(charset) if charset
          end
        end

        response = super

        # Force the response.body to the content charset of specified in the header.
        # Content-Type is echo'd back for the blob and is used to store the encoding of the octet stream
        if !response.nil? && !response.body.nil? && response.headers['Content-Type']
          charset = parse_charset_from_content_type(response.headers['Content-Type'])
          response.body.force_encoding(charset) if charset && charset.length > 0
        end

        response
      end

      # Public: Get a list of Containers from the server.
      #
      # ==== Attributes
      #
      # * +options+                  - Hash. Optional parameters.
      #
      # ==== Options
      #
      # Accepted key/value pairs in options parameter are:
      # * +:prefix+                  - String. Filters the results to return only containers
      #                                whose name begins with the specified prefix. (optional)
      #
      # * +:marker+                  - String. An identifier the specifies the portion of the
      #                                list to be returned. This value comes from the property
      #                                Azure::Service::EnumerationResults.continuation_token when there
      #                                are more containers available than were returned. The
      #                                marker value may then be used here to request the next set
      #                                of list items. (optional)
      #
      # * +:max_results+             - Integer. Specifies the maximum number of containers to return.
      #                                If max_results is not specified, or is a value greater than
      #                                5,000, the server will return up to 5,000 items. If it is set
      #                                to a value less than or equal to zero, the server will return
      #                                status code 400 (Bad Request). (optional)
      #
      # * +:metadata+                - Boolean. Specifies whether or not to return the container metadata.
      #                                (optional, Default=false)
      #
      # * +:timeout+                 - Integer. A timeout in seconds.
      #
      # * +:request_id+              - String. Provides a client-generated, opaque value with a 1 KB character limit that is recorded 
      #                                in the analytics logs when storage analytics logging is enabled.
      #
      # See: https://msdn.microsoft.com/en-us/library/azure/dd179352.aspx
      #
      # NOTE: Metadata requested with the :metadata parameter must have been stored in
      # accordance with the naming restrictions imposed by the 2009-09-19 version of the Blob
      # service. Beginning with that version, all metadata names must adhere to the naming
      # conventions for C# identifiers. See: https://msdn.microsoft.com/en-us/library/aa664670(VS.71).aspx
      #
      # Any metadata with invalid names which were previously stored, will be returned with the
      # key "x-ms-invalid-name" in the metadata hash. This may contain multiple values and be an
      # Array (vs a String if it only contains a single value).
      #
      # Returns an Azure::Service::EnumerationResults
      #
      def list_containers(options={})
        query = { }
        if options
          StorageService.with_query query, 'prefix', options[:prefix]
          StorageService.with_query query, 'marker', options[:marker]
          StorageService.with_query query, 'maxresults', options[:max_results].to_s if options[:max_results]
          StorageService.with_query query, 'include', 'metadata' if options[:metadata] == true
          StorageService.with_query query, 'timeout', options[:timeout].to_s if options[:timeout]
        end

        uri = containers_uri(query)
        response = call(:get, uri, nil, {}, options)

        Serialization.container_enumeration_results_from_xml(response.body)
      end
     
      # Protected: Establishes an exclusive write lock on a container or a blob. The lock duration can be 15 to 60 seconds, or can be infinite.
      # To write to a locked container or blob, a client must provide a lease ID.
      #
      # ==== Attributes
      #
      # * +container+                - String. The container name.
      # * +blob+                     - String. The blob name.
      # * +options+                  - Hash. Optional parameters.
      #
      # ==== Options
      #
      # Accepted key/value pairs in options parameter are:
      # * +:duration+                - Integer. Default -1. Specifies the duration of the lease, in seconds, or negative one (-1)
      #                                for a lease that never expires. A non-infinite lease can be between 15 and 60 seconds. (optional)
      # * +:proposed_lease_id+       - String. Proposed lease ID, in a GUID string format. The Blob service returns 400 (Invalid request)
      #                                if the proposed lease ID is not in the correct format. (optional)
      # * +:timeout+                 - Integer. A timeout in seconds.
      # * +:request_id+              - String. Provides a client-generated, opaque value with a 1 KB character limit that is recorded 
      #                                in the analytics logs when storage analytics logging is enabled.
      # * +:if_modified_since+       - String. A DateTime value. Specify this conditional header to acquire the lease
      #                                only if the blob has been modified since the specified date/time. If the blob has not been modified, 
      #                                the Blob service returns status code 412 (Precondition Failed).
      # * +:if_unmodified_since+     - String. A DateTime value. Specify this conditional header to acquire the lease
      #                                only if the blob has not been modified since the specified date/time. If the blob has been modified, 
      #                                the Blob service returns status code 412 (Precondition Failed).
      # * +:if_match+                - String. An ETag value. Specify an ETag value for this conditional header to acquire the lease
      #                                only if the blob's ETag value matches the value specified. If the values do not match, 
      #                                the Blob service returns status code 412 (Precondition Failed).
      # * +:if_none_match+           - String. An ETag value. Specify an ETag value for this conditional header to acquire the lease
      #                                only if the blob's ETag value does not match the value specified. If the values are identical, 
      #                                the Blob service returns status code 412 (Precondition Failed).
      #
      # See http://msdn.microsoft.com/en-us/library/azure/ee691972.aspx
      #
      # Returns a String of the new unique lease id. While the lease is active, you must include the lease ID with any request
      # to write, or to renew, change, or release the lease.
      #
      protected
      def acquire_lease(container, blob, options={})
        query = { 'comp' => 'lease' }
        Service::StorageService.with_query query, 'timeout', options[:timeout].to_s if options[:timeout]

        if blob
          uri = blob_uri(container, blob, query)
        else
          uri = container_uri(container, query)
        end

        duration = -1
        duration = options[:duration] if options[:duration]

        headers = Service::StorageService.common_headers
        Service::StorageService.with_header headers, 'x-ms-lease-action', 'acquire'
        Service::StorageService.with_header headers, 'x-ms-lease-duration', duration.to_s if duration
        Service::StorageService.with_header headers, 'x-ms-proposed-lease-id', options[:proposed_lease_id]
        add_blob_conditional_headers options, headers

        response = call(:put, uri, nil, headers, options)
        response.headers['x-ms-lease-id']
      end

      # Protected: Renews the lease. The lease can be renewed if the lease ID specified on the request matches that
      # associated with the blob. Note that the lease may be renewed even if it has expired as long as the container or blob
      # has not been modified or leased again since the expiration of that lease. When you renew a lease, the
      # lease duration clock resets.
      #
      # ==== Attributes
      #
      # * +container+                - String. The container name.
      # * +blob+                     - String. The blob name.
      # * +lease+                    - String. The lease id
      # * +options+                  - Hash. Optional parameters.
      #
      # ==== Options
      #
      # Accepted key/value pairs in options parameter are:
      # * +:timeout+                 - Integer. A timeout in seconds.
      # * +:request_id+              - String. Provides a client-generated, opaque value with a 1 KB character limit that is recorded 
      #                                in the analytics logs when storage analytics logging is enabled.
      # * +:if_modified_since+       - String. A DateTime value. Specify this conditional header to renew the lease
      #                                only if the blob has been modified since the specified date/time. If the blob has not been modified, 
      #                                the Blob service returns status code 412 (Precondition Failed).
      # * +:if_unmodified_since+     - String. A DateTime value. Specify this conditional header to renew the lease
      #                                only if the blob has not been modified since the specified date/time. If the blob has been modified, 
      #                                the Blob service returns status code 412 (Precondition Failed).
      # * +:if_match+                - String. An ETag value. Specify an ETag value for this conditional header to renew the lease
      #                                only if the blob's ETag value matches the value specified. If the values do not match, 
      #                                the Blob service returns status code 412 (Precondition Failed).
      # * +:if_none_match+           - String. An ETag value. Specify an ETag value for this conditional header to renew the lease
      #                                only if the blob's ETag value does not match the value specified. If the values are identical, 
      #                                the Blob service returns status code 412 (Precondition Failed).
      #
      # See http://msdn.microsoft.com/en-us/library/azure/ee691972.aspx
      #
      # Returns the renewed lease id
      #
      protected
      def renew_lease(container, blob, lease, options={})
        query = { 'comp' => 'lease' }
        Service::StorageService.with_query query, 'timeout', options[:timeout].to_s if options[:timeout]

        if blob
          uri = blob_uri(container, blob, query)
        else
          uri = container_uri(container, query)
        end

        headers = Service::StorageService.common_headers
        Service::StorageService.with_header headers, 'x-ms-lease-action', 'renew'
        Service::StorageService.with_header headers, 'x-ms-lease-id', lease
        add_blob_conditional_headers options, headers

        response = call(:put, uri, nil, headers, options)
        response.headers['x-ms-lease-id']
      end
      
      # Protected: Change the ID of an existing lease.
      #
      # ==== Attributes
      #
      # * +container+                - String. The container name.
      # * +blob+                     - String. The blob name.
      # * +lease+                    - String. The existing lease id.
      # * +proposed_lease+           - String. Proposed lease ID, in a GUID string format. The Blob service returns 400 (Invalid request)
      #                                if the proposed lease ID is not in the correct format. (optional).
      # * +options+                  - Hash. Optional parameters.
      #
      # ==== Options
      #
      # Accepted key/value pairs in options parameter are:
      # * +:timeout+                 - Integer. A timeout in seconds.
      # * +:request_id+              - String. Provides a client-generated, opaque value with a 1 KB character limit that is recorded 
      #                                in the analytics logs when storage analytics logging is enabled.
      # * +:if_modified_since+       - String. A DateTime value. Specify this conditional header to change the lease
      #                                only if the blob has been modified since the specified date/time. If the blob has not been modified, 
      #                                the Blob service returns status code 412 (Precondition Failed).
      # * +:if_unmodified_since+     - String. A DateTime value. Specify this conditional header to change the lease
      #                                only if the blob has not been modified since the specified date/time. If the blob has been modified, 
      #                                the Blob service returns status code 412 (Precondition Failed).
      # * +:if_match+                - String. An ETag value. Specify an ETag value for this conditional header to change the lease
      #                                only if the blob's ETag value matches the value specified. If the values do not match, 
      #                                the Blob service returns status code 412 (Precondition Failed).
      # * +:if_none_match+           - String. An ETag value. Specify an ETag value for this conditional header to change the lease
      #                                only if the blob's ETag value does not match the value specified. If the values are identical, 
      #                                the Blob service returns status code 412 (Precondition Failed).
      #
      # See http://msdn.microsoft.com/en-us/library/azure/ee691972.aspx
      #
      # Returns a String of the new unique lease id. While the lease is active, you must include the lease ID with any request
      # to write, or to renew, change, or release the lease.
      #
      protected
      def change_lease(container, blob, lease, proposed_lease, options={})
        query = { 'comp' => 'lease' }
        Service::StorageService.with_query query, 'timeout', options[:timeout].to_s if options[:timeout]

        if blob
          uri = blob_uri(container, blob, query)
        else
          uri = container_uri(container, query)
        end

        headers = Service::StorageService.common_headers
        Service::StorageService.with_header headers, 'x-ms-lease-action', 'change'
        Service::StorageService.with_header headers, 'x-ms-lease-id', lease
        Service::StorageService.with_header headers, 'x-ms-proposed-lease-id', proposed_lease
        add_blob_conditional_headers options, headers

        response = call(:put, uri, nil, headers, options)
        response.headers['x-ms-lease-id']
      end

      # Protected: Releases the lease. The lease may be released if the lease ID specified on the request matches that
      # associated with the container or blob. Releasing the lease allows another client to immediately acquire the lease for
      # the container or blob as soon as the release is complete.
      #
      # ==== Attributes
      #
      # * +container+                - String. The container name.
      # * +blob+                     - String. The blob name.
      # * +lease+                    - String. The lease id.
      # * +options+                  - Hash. Optional parameters.
      #
      # ==== Options
      #
      # Accepted key/value pairs in options parameter are:
      # * +:timeout+                 - Integer. A timeout in seconds.
      # * +:request_id+              - String. Provides a client-generated, opaque value with a 1 KB character limit that is recorded 
      #                                in the analytics logs when storage analytics logging is enabled.
      # * +:if_modified_since+       - String. A DateTime value. Specify this conditional header to release the lease
      #                                only if the blob has been modified since the specified date/time. If the blob has not been modified, 
      #                                the Blob service returns status code 412 (Precondition Failed).
      # * +:if_unmodified_since+     - String. A DateTime value. Specify this conditional header to release the lease
      #                                only if the blob has not been modified since the specified date/time. If the blob has been modified, 
      #                                the Blob service returns status code 412 (Precondition Failed).
      # * +:if_match+                - String. An ETag value. Specify an ETag value for this conditional header to release the lease
      #                                only if the blob's ETag value matches the value specified. If the values do not match, 
      #                                the Blob service returns status code 412 (Precondition Failed).
      # * +:if_none_match+           - String. An ETag value. Specify an ETag value for this conditional header to release the lease
      #                                only if the blob's ETag value does not match the value specified. If the values are identical, 
      #                                the Blob service returns status code 412 (Precondition Failed).
      #
      # See http://msdn.microsoft.com/en-us/library/azure/ee691972.aspx
      #
      # Returns nil on success
      #
      protected
      def release_lease(container, blob, lease, options={})
        query = { 'comp' => 'lease' }
        Service::StorageService.with_query query, 'timeout', options[:timeout].to_s if options[:timeout]

        if blob
          uri = blob_uri(container, blob, query)
        else
          uri = container_uri(container, query)
        end

        headers = Service::StorageService.common_headers
        Service::StorageService.with_header headers, 'x-ms-lease-action', 'release'
        Service::StorageService.with_header headers, 'x-ms-lease-id', lease
        add_blob_conditional_headers options, headers

        call(:put, uri, nil, headers, options)
        nil
      end

      # Protected: Breaks the lease, if the container or blob has an active lease. Once a lease is broken, it cannot be renewed. Any
      # authorized request can break the lease; the request is not required to specify a matching lease ID. When a
      # lease is broken, the lease break period is allowed to elapse, during which time no lease operation except
      # break and release can be performed on the container or blob. When a lease is successfully broken, the response indicates
      # the interval in seconds until a new lease can be acquired.
      #
      # A lease that has been broken can also be released, in which case another client may immediately acquire the
      # lease on the container or blob.
      #
      # ==== Attributes
      #
      # * +container+                - String. The container name.
      # * +blob+                     - String. The blob name.
      # * +options+                  - Hash. Optional parameters.
      #
      # ==== Options
      #
      # Accepted key/value pairs in options parameter are:
      # * +:break_period+            - Integer. The proposed duration of seconds that the lease should continue before it is
      #                                broken, between 0 and 60 seconds. This break period is only used if it is shorter than
      #                                the time remaining on the lease. If longer, the time remaining on the lease is used. A
      #                                new lease will not be available before the break period has expired, but the lease may
      #                                be held for longer than the break period.
      #
      #                                If this option is not used, a fixed-duration lease breaks after the remaining lease
      #                                period elapses, and an infinite lease breaks immediately.
      # * +:timeout+                 - Integer. A timeout in seconds.
      # * +:request_id+              - String. Provides a client-generated, opaque value with a 1 KB character limit that is recorded 
      #                                in the analytics logs when storage analytics logging is enabled.
      # * +:if_modified_since+       - String. A DateTime value. Specify this conditional header to acquire the lease
      #                                only if the blob has been modified since the specified date/time. If the blob has not been modified, 
      #                                the Blob service returns status code 412 (Precondition Failed).
      # * +:if_unmodified_since+     - String. A DateTime value. Specify this conditional header to acquire the lease
      #                                only if the blob has not been modified since the specified date/time. If the blob has been modified, 
      #                                the Blob service returns status code 412 (Precondition Failed).
      # * +:if_match+                - String. An ETag value. Specify an ETag value for this conditional header to acquire the lease
      #                                only if the blob's ETag value matches the value specified. If the values do not match, 
      #                                the Blob service returns status code 412 (Precondition Failed).
      # * +:if_none_match+           - String. An ETag value. Specify an ETag value for this conditional header to acquire the lease
      #                                only if the blob's ETag value does not match the value specified. If the values are identical, 
      #                                the Blob service returns status code 412 (Precondition Failed).
      #
      # See http://msdn.microsoft.com/en-us/library/azure/ee691972.aspx
      #
      # Returns an Integer of the remaining lease time. This value is the approximate time remaining in the lease
      # period, in seconds. This header is returned only for a successful request to break the lease. If the break
      # is immediate, 0 is returned.
      #
      protected
      def break_lease(container, blob, options={})
        query = { 'comp' => 'lease' }
        Service::StorageService.with_query query, 'timeout', options[:timeout].to_s if options[:timeout]

        if blob
          uri = blob_uri(container, blob, query)
        else
          uri = container_uri(container, query)
        end

        headers = Service::StorageService.common_headers
        Service::StorageService.with_header headers, 'x-ms-lease-action', 'break'
        Service::StorageService.with_header headers, 'x-ms-lease-break-period', options[:break_period].to_s if options[:break_period]
        add_blob_conditional_headers options, headers

        response = call(:put, uri, nil, headers, options)
        response.headers['x-ms-lease-time'].to_i
      end
      
      # Protected: Generate the URI for the collection of containers.
      #
      # ==== Attributes
      #
      # * +query+ - A Hash of key => value query parameters.
      #
      # Returns a URI.
      #
      protected
      def containers_uri(query={})
        query = { 'comp' => 'list' }.merge(query)
        generate_uri('', query)
      end
      
      # Protected: Generate the URI for a specific container.
      #
      # ==== Attributes
      #
      # * +name+  - The container name. If this is a URI, we just return this.
      # * +query+ - A Hash of key => value query parameters.
      #
      # Returns a URI.
      #
      protected
      def container_uri(name, query={})
        return name if name.kind_of? ::URI
        query = { 'restype' => 'container' }.merge(query)
        generate_uri(name, query)
      end
      
      # Protected: Generate the URI for a specific Blob.
      #
      # ==== Attributes
      #
      # * +container_name+ - String representing the name of the container.
      # * +blob_name+      - String representing the name of the blob.
      # * +query+          - A Hash of key => value query parameters.
      #
      # Returns a URI.
      #
      protected
      def blob_uri(container_name, blob_name, query={})
        if container_name.nil? || container_name.empty?
          path = blob_name
        else
          path = ::File.join(container_name, blob_name)
        end
        generate_uri(path, query, true)
      end
      
      # Adds conditional header with required condition
      #
      # headers   - A Hash of HTTP headers
      # options   - A Hash of condition name/value pairs
      #
      protected
      def add_blob_conditional_headers(options, headers)
        return unless options
        
        # Common conditional headers for blobs: https://msdn.microsoft.com/en-us/library/azure/dd179371.aspx
        Service::StorageService.with_header headers, 'If-Modified-Since', options[:if_modified_since]
        Service::StorageService.with_header headers, 'If-Unmodified-Since', options[:if_unmodified_since]
        Service::StorageService.with_header headers, 'If-Match', options[:if_match]
        Service::StorageService.with_header headers, 'If-None-Match', options[:if_none_match]
        
        # Conditional headers for copying blob
        Service::StorageService.with_header headers, 'If-Modified-Since', options[:dest_if_modified_since]
        Service::StorageService.with_header headers, 'If-Unmodified-Since', options[:dest_if_unmodified_since]
        Service::StorageService.with_header headers, 'If-Match', options[:dest_if_match]
        Service::StorageService.with_header headers, 'If-None-Match', options[:dest_if_none_match]
        Service::StorageService.with_header headers, 'x-ms-source-if-modified-since', options[:source_if_modified_since]
        Service::StorageService.with_header headers, 'x-ms-source-if-unmodified-since', options[:source_if_unmodified_since]
        Service::StorageService.with_header headers, 'x-ms-source-if-match', options[:source_if_match]
        Service::StorageService.with_header headers, 'x-ms-source-if-none-match', options[:source_if_none_match]
        
        # Conditional headers for page blob
        Service::StorageService.with_header headers, 'x-ms-if-sequence-number-le', options[:if_sequence_number_le]
        Service::StorageService.with_header headers, 'x-ms-if-sequence-number-lt', options[:if_sequence_number_lt]
        Service::StorageService.with_header headers, 'x-ms-if-sequence-number-eq', options[:if_sequence_number_eq]
        
        # Conditional headers for append blob
        Service::StorageService.with_header headers, 'x-ms-blob-condition-maxsize', options[:max_size] 
        Service::StorageService.with_header headers, 'x-ms-blob-condition-appendpos', options[:append_position]
      end
    end
  end
end

Azure::Storage::BlobService = Azure::Storage::Blob::BlobService