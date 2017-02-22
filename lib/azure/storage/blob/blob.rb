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
module Azure::Storage
  module Blob
    include Azure::Storage::Service
    
    class Blob
      def initialize
        @properties = {}
        @metadata = {}
        yield self if block_given?
      end

      attr_accessor :name
      attr_accessor :snapshot
      attr_accessor :properties
      attr_accessor :metadata
    end
    
    # Public: Reads or downloads a blob from the system, including its metadata and properties.
    #
    # ==== Attributes
    #
    # * +container+                  - String. The container name.
    # * +blob+                       - String. The blob name.
    # * +options+                    - Hash. Optional parameters.
    #
    # ==== Options
    #
    # Accepted key/value pairs in options parameter are:
    # * +:start_range+               - Integer. Position of first byte of first page. (optional)
    # * +:end_range+                 - Integer. Position of last byte of of last page. (optional)
    # * +:snapshot+                  - String. An opaque DateTime value that specifies the blob snapshot to
    #                                  retrieve information from. (optional)
    # * +:get_content_md5+           - Boolean. Return the MD5 hash for the range. This option only valid if
    #                                  start_range and end_range are specified. (optional)
    # * +:timeout+                   - Integer. A timeout in seconds.
    # * +:request_id+                - String. Provides a client-generated, opaque value with a 1 KB character limit that is recorded 
    #                                  in the analytics logs when storage analytics logging is enabled.
    # * +:if_modified_since+         - String. A DateTime value. Specify this conditional header to get the blob 
    #                                  only if the blob has been modified since the specified date/time. If the blob has not been modified, 
    #                                  the Blob service returns status code 412 (Precondition Failed).
    # * +:if_unmodified_since+       - String. A DateTime value. Specify this conditional header to get the blob 
    #                                  only if the blob has not been modified since the specified date/time. If the blob has been modified, 
    #                                  the Blob service returns status code 412 (Precondition Failed).
    # * +:if_match+                  - String. An ETag value. Specify an ETag value for this conditional header to get the blob 
    #                                  only if the blob's ETag value matches the value specified. If the values do not match, 
    #                                  the Blob service returns status code 412 (Precondition Failed).
    # * +:if_none_match+             - String. An ETag value. Specify an ETag value for this conditional header to get the blob 
    #                                  only if the blob's ETag value does not match the value specified. If the values are identical, 
    #                                  the Blob service returns status code 412 (Precondition Failed).
    #
    # See http://msdn.microsoft.com/en-us/library/azure/dd179440.aspx
    #
    # Returns a blob and the blob body
    def get_blob(container, blob, options={})
      query = { }
      StorageService.with_query query, 'snapshot', options[:snapshot]
      StorageService.with_query query, 'timeout', options[:timeout].to_s if options[:timeout]
      uri = blob_uri(container, blob, query)

      headers = StorageService.common_headers
      options[:start_range] = 0 if options[:end_range] and not options[:start_range]
      if options[:start_range]
        StorageService.with_header headers, 'x-ms-range', "bytes=#{options[:start_range]}-#{options[:end_range]}"
        StorageService.with_header headers, 'x-ms-range-get-content-md5', true if options[:get_content_md5]
      end
      add_blob_conditional_headers options, headers

      response = call(:get, uri, nil, headers, options)
      result = Serialization.blob_from_headers(response.headers)
      result.name = blob unless result.name
      return result, response.body
    end
    
    # Public: Returns all properties and metadata on the blob.
    #
    # ==== Attributes
    #
    # * +container+                  - String. The container name.
    # * +blob+                       - String. The blob name.
    # * +options+                    - Hash. Optional parameters.
    #
    # ==== Options
    #
    # Accepted key/value pairs in options parameter are:
    # * +:snapshot+                  - String. An opaque DateTime value that specifies the blob snapshot to
    #                                  retrieve information from.
    # * +:timeout+                   - Integer. A timeout in seconds.
    # * +:request_id+                - String. Provides a client-generated, opaque value with a 1 KB character limit that is recorded 
    #                                  in the analytics logs when storage analytics logging is enabled.
    # * +:if_modified_since+         - String. A DateTime value. Specify this conditional header to get the blob properties
    #                                  only if the blob has been modified since the specified date/time. If the blob has not been modified, 
    #                                  the Blob service returns status code 412 (Precondition Failed).
    # * +:if_unmodified_since+       - String. A DateTime value. Specify this conditional header to get the blob properties
    #                                  only if the blob has not been modified since the specified date/time. If the blob has been modified, 
    #                                  the Blob service returns status code 412 (Precondition Failed).
    # * +:if_match+                  - String. An ETag value. Specify an ETag value for this conditional header to get the blob properties
    #                                  only if the blob's ETag value matches the value specified. If the values do not match, 
    #                                  the Blob service returns status code 412 (Precondition Failed).
    # * +:if_none_match+             - String. An ETag value. Specify an ETag value for this conditional header to get the blob properties
    #                                  only if the blob's ETag value does not match the value specified. If the values are identical, 
    #                                  the Blob service returns status code 412 (Precondition Failed).
    #
    # See http://msdn.microsoft.com/en-us/library/azure/dd179394.aspx
    #
    # Returns the blob properties with a Blob instance
    def get_blob_properties(container, blob, options={})
      query = { }
      StorageService.with_query query, 'snapshot', options[:snapshot]
      StorageService.with_query query, 'timeout', options[:timeout].to_s if options[:timeout]

      headers = StorageService.common_headers
      unless options.empty?
        add_blob_conditional_headers options, headers
      end
        
      uri = blob_uri(container, blob, query)

      response = call(:head, uri, nil, headers, options)

      result = Serialization.blob_from_headers(response.headers)

      result.name = blob
      result.snapshot = options[:snapshot]

      result
    end
    
    # Public: Sets system properties defined for a blob.
    #
    # ==== Attributes
    #
    # * +container+                  - String. The container name.
    # * +blob+                       - String. The blob name.
    # * +options+                    - Hash. Optional parameters.
    #
    # ==== Options
    #
    # Accepted key/value pairs in options parameter are:
    # * +:content_type+              - String. Content type for the blob. Will be saved with blob.
    # * +:content_encoding+          - String. Content encoding for the blob. Will be saved with blob.
    # * +:content_language+          - String. Content language for the blob. Will be saved with blob.
    # * +:content_md5+               - String. Content MD5 for the blob. Will be saved with blob.
    # * +:cache_control+             - String. Cache control for the blob. Will be saved with blob.
    # * +:content_disposition+       - String. Conveys additional information about how to process the response payload, 
    #                                  and also can be used to attach additional metadata
    # * +:content_length+            - Integer. Resizes a page blob to the specified size. If the specified
    #                                  value is less than the current size of the blob, then all pages above
    #                                  the specified value are cleared. This property cannot be used to change
    #                                  the size of a block blob. Setting this property for a block blob returns
    #                                  status code 400 (Bad Request).
    # * +:sequence_number_action+    - Symbol. This property indicates how the service should modify the sequence
    #                                  number for the blob. Required if :sequence_number is used. This property
    #                                  applies to page blobs only.
    #
    #                                  Specify one of the following options for this property:
    #
    #     * +:max+                       - Sets the sequence number to be the higher of the value included with
    #                                      the request and the value currently stored for the blob.
    #     * +:update+                    - Sets the sequence number to the value included with the request.
    #     * +:increment+                 - Increments the value of the sequence number by 1. If specifying this
    #                                      option, do not include the sequence_number option; doing so will return
    #                                      status code 400 (Bad Request).
    #
    # * +:sequence_number+           - Integer. This property sets the blob's sequence number. The sequence number is a
    #                                  user-controlled property that you can use to track requests and manage concurrency
    #                                  issues. Required if the :sequence_number_action option is set to :max or :update.
    #                                  This property applies to page blobs only.
    #
    #                                  Use this together with the :sequence_number_action to update the blob's sequence
    #                                  number, either to the specified value or to the higher of the values specified with
    #                                  the request or currently stored with the blob.
    #
    #                                  This header should not be specified if :sequence_number_action is set to :increment;
    #                                  in this case the service automatically increments the sequence number by one.
    #
    #                                  To set the sequence number to a value of your choosing, this property must be specified
    #                                  together with :sequence_number_action
    # * +:timeout+                   - Integer. A timeout in seconds.
    # * +:request_id+                - String. Provides a client-generated, opaque value with a 1 KB character limit that is recorded 
    #                                  in the analytics logs when storage analytics logging is enabled.
    # * +:if_modified_since+         - String. A DateTime value. Specify this conditional header to set the blob properties
    #                                  only if the blob has been modified since the specified date/time. If the blob has not been modified, 
    #                                  the Blob service returns status code 412 (Precondition Failed).
    # * +:if_unmodified_since+       - String. A DateTime value. Specify this conditional header to set the blob properties
    #                                  only if the blob has not been modified since the specified date/time. If the blob has been modified, 
    #                                  the Blob service returns status code 412 (Precondition Failed).
    # * +:if_match+                  - String. An ETag value. Specify an ETag value for this conditional header to set the blob properties
    #                                  only if the blob's ETag value matches the value specified. If the values do not match, 
    #                                  the Blob service returns status code 412 (Precondition Failed).
    # * +:if_none_match+             - String. An ETag value. Specify an ETag value for this conditional header to set the blob properties
    #                                  only if the blob's ETag value does not match the value specified. If the values are identical, 
    #                                  the Blob service returns status code 412 (Precondition Failed).
    #
    # Remarks:
    #
    # The semantics for updating a blob's properties are as follows:
    #
    # * A page blob's sequence number is updated only if the request meets either of the following conditions:
    #
    #     * The :sequence_number_action property is set to :max or :update, and a value for :sequence_number is also set.
    #     * The :sequence_number_action property is set to :increment, indicating that the service should increment
    #       the sequence number by one.
    #
    # * The size of the page blob is modified only if a value for :content_length is specified.
    #
    # * If :sequence_number and/or :content_length are the only properties specified, then the other properties of the blob
    #   will NOT be modified.
    #
    # * If any one or more of the following properties are set, then all of these properties are set together. If a value is
    #   not provided for a given property when at least one of the properties listed below is set, then that property will be
    #   cleared for the blob.
    #
    #     * :cache_control
    #     * :content_type
    #     * :content_md5
    #     * :content_encoding
    #     * :content_language
    #
    # See http://msdn.microsoft.com/en-us/library/azure/ee691966.aspx
    #
    # Returns nil on success.
    def set_blob_properties(container, blob, options={})
      query = {'comp' => 'properties'}
      StorageService.with_query query, 'timeout', options[:timeout].to_s if options[:timeout]
      uri = blob_uri(container, blob, query)

      headers = StorageService.common_headers

      unless options.empty?
        StorageService.with_header headers, 'x-ms-blob-content-type', options[:content_type]
        StorageService.with_header headers, 'x-ms-blob-content-encoding', options[:content_encoding]
        StorageService.with_header headers, 'x-ms-blob-content-language', options[:content_language]
        StorageService.with_header headers, 'x-ms-blob-content-md5', options[:content_md5]
        StorageService.with_header headers, 'x-ms-blob-cache-control', options[:cache_control]
        StorageService.with_header headers, 'x-ms-blob-content-length', options[:content_length].to_s if options[:content_length]
        StorageService.with_header headers, 'x-ms-blob-content-disposition', options[:content_disposition]
        
        if options[:sequence_number_action]
          StorageService.with_header headers, 'x-ms-blob-sequence-number-action', options[:sequence_number_action].to_s
          
          if options[:sequence_number_action] != :increment
            StorageService.with_header headers, 'x-ms-blob-sequence-number', options[:sequence_number].to_s if options[:sequence_number]
          end
        end
        
        add_blob_conditional_headers options, headers
      end

      call(:put, uri, nil, headers, options)
      nil
    end
    
    # Public: Returns metadata on the blob.
    #
    # ==== Attributes
    #
    # * +container+                  - String. The container name.
    # * +blob+                       - String. The blob name.
    # * +options+                    - Hash. Optional parameters.
    #
    # ==== Options
    #
    # Accepted key/value pairs in options parameter are:
    # * +:snapshot+                  - String. An opaque DateTime value that specifies the blob snapshot to
    #                                  retrieve information from.
    # * +:timeout+                   - Integer. A timeout in seconds.
    # * +:request_id+                - String. Provides a client-generated, opaque value with a 1 KB character limit that is recorded 
    #                                  in the analytics logs when storage analytics logging is enabled.
    # * +:if_modified_since+         - String. A DateTime value. Specify this conditional header to get the blob metadata
    #                                  only if the blob has been modified since the specified date/time. If the blob has not been modified, 
    #                                  the Blob service returns status code 412 (Precondition Failed).
    # * +:if_unmodified_since+       - String. A DateTime value. Specify this conditional header to get the blob metadata
    #                                  only if the blob has not been modified since the specified date/time. If the blob has been modified, 
    #                                  the Blob service returns status code 412 (Precondition Failed).
    # * +:if_match+                  - String. An ETag value. Specify an ETag value for this conditional header to get the blob metadata
    #                                  only if the blob's ETag value matches the value specified. If the values do not match, 
    #                                  the Blob service returns status code 412 (Precondition Failed).
    # * +:if_none_match+             - String. An ETag value. Specify an ETag value for this conditional header to get the blob metadata
    #                                  only if the blob's ETag value does not match the value specified. If the values are identical, 
    #                                  the Blob service returns status code 412 (Precondition Failed).
    #
    # See http://msdn.microsoft.com/en-us/library/azure/dd179350.aspx
    #
    # Returns a Blob
    def get_blob_metadata(container, blob, options={})
      query = {'comp' => 'metadata'}
      StorageService.with_query query, 'snapshot', options[:snapshot]
      StorageService.with_query query, 'timeout', options[:timeout].to_s if options[:timeout]

      headers = StorageService.common_headers
      unless options.empty?
        add_blob_conditional_headers options, headers
      end

      uri = blob_uri(container, blob, query)
      response = call(:get, uri, nil, headers, options)
      result = Serialization.blob_from_headers(response.headers)

      result.name = blob
      result.snapshot = options[:snapshot]

      result
    end
    
    # Public: Sets metadata headers on the blob.
    #
    # ==== Attributes
    #
    # * +container+                  - String. The container name.
    # * +blob+                       - String. The blob name.
    # * +metadata+                   - Hash. The custom metadata.
    # * +options+                    - Hash. Optional parameters.
    #
    # ==== Options
    #
    # Accepted key/value pairs in options parameter are:
    # * +:timeout+                   - Integer. A timeout in seconds.
    # * +:request_id+                - String. Provides a client-generated, opaque value with a 1 KB character limit that is recorded 
    #                                  in the analytics logs when storage analytics logging is enabled.
    # * +:if_modified_since+         - String. A DateTime value. Specify this conditional header to set the blob metadata
    #                                  only if the blob has been modified since the specified date/time. If the blob has not been modified, 
    #                                  the Blob service returns status code 412 (Precondition Failed).
    # * +:if_unmodified_since+       - String. A DateTime value. Specify this conditional header to set the blob metadata
    #                                  only if the blob has not been modified since the specified date/time. If the blob has been modified, 
    #                                  the Blob service returns status code 412 (Precondition Failed).
    # * +:if_match+                  - String. An ETag value. Specify an ETag value for this conditional header to set the blob metadata
    #                                  only if the blob's ETag value matches the value specified. If the values do not match, 
    #                                  the Blob service returns status code 412 (Precondition Failed).
    # * +:if_none_match+             - String. An ETag value. Specify an ETag value for this conditional header to set the blob metadata
    #                                  only if the blob's ETag value does not match the value specified. If the values are identical, 
    #                                  the Blob service returns status code 412 (Precondition Failed).
    #
    # See http://msdn.microsoft.com/en-us/library/azure/dd179414.aspx
    #
    # Returns nil on success.
    def set_blob_metadata(container, blob, metadata, options={})
      query = {'comp' => 'metadata'}
      StorageService.with_query query, 'timeout', options[:timeout].to_s if options[:timeout]
      
      uri = blob_uri(container, blob, query)

      headers = StorageService.common_headers
      StorageService.add_metadata_to_headers metadata, headers
      unless options.empty?
        add_blob_conditional_headers options, headers
      end

      call(:put, uri, nil, headers, options)
      nil
    end
    
    # Public: Establishes an exclusive write lock on a blob. The lock duration can be 15 to 60 seconds, or can be infinite.
    # To write to a locked blob, a client must provide a lease ID.
    #
    # ==== Attributes
    #
    # * +container+                  - String. The container name.
    # * +blob+                       - String. The blob name.
    # * +options+                    - Hash. Optional parameters.
    #
    # ==== Options
    #
    # Accepted key/value pairs in options parameter are:
    # * +:duration+                  - Integer. Default -1. Specifies the duration of the lease, in seconds, or negative one (-1)
    #                                  for a lease that never expires. A non-infinite lease can be between 15 and 60 seconds. (optional)
    # * +:proposed_lease_id+         - String. Proposed lease ID, in a GUID string format. The Blob service returns 400 (Invalid request)
    #                                  if the proposed lease ID is not in the correct format. (optional)
    # * +:timeout+                   - Integer. A timeout in seconds.
    # * +:request_id+                - String. Provides a client-generated, opaque value with a 1 KB character limit that is recorded 
    #                                  in the analytics logs when storage analytics logging is enabled.
    # * +:if_modified_since+         - String. A DateTime value. Specify this conditional header to acquire the lease
    #                                  only if the blob has been modified since the specified date/time. If the blob has not been modified, 
    #                                  the Blob service returns status code 412 (Precondition Failed).
    # * +:if_unmodified_since+       - String. A DateTime value. Specify this conditional header to acquire the lease
    #                                  only if the blob has not been modified since the specified date/time. If the blob has been modified, 
    #                                  the Blob service returns status code 412 (Precondition Failed).
    # * +:if_match+                  - String. An ETag value. Specify an ETag value for this conditional header to acquire the lease
    #                                  only if the blob's ETag value matches the value specified. If the values do not match, 
    #                                  the Blob service returns status code 412 (Precondition Failed).
    # * +:if_none_match+             - String. An ETag value. Specify an ETag value for this conditional header to acquire the lease
    #                                  only if the blob's ETag value does not match the value specified. If the values are identical, 
    #                                  the Blob service returns status code 412 (Precondition Failed).
    #
    # See http://msdn.microsoft.com/en-us/library/azure/ee691972.aspx
    #
    # Returns a String of the new unique lease id. While the lease is active, you must include the lease ID with any request
    # to write to the blob, or to renew, change, or release the lease.
    #
    def acquire_blob_lease(container, blob, options={})
      acquire_lease container, blob, options
    end

    # Public: Renews the lease. The lease can be renewed if the lease ID specified on the request matches that
    # associated with the blob. Note that the lease may be renewed even if it has expired as long as the blob
    # has not been modified or leased again since the expiration of that lease. When you renew a lease, the
    # lease duration clock resets.
    #
    # ==== Attributes
    #
    # * +container+                  - String. The container name.
    # * +blob+                       - String. The blob name.
    # * +lease+                      - String. The lease id
    # * +options+                    - Hash. Optional parameters.
    #
    # ==== Options
    #
    # Accepted key/value pairs in options parameter are:
    # * +:timeout+                   - Integer. A timeout in seconds.
    # * +:request_id+                - String. Provides a client-generated, opaque value with a 1 KB character limit that is recorded 
    #                                  in the analytics logs when storage analytics logging is enabled.
    # * +:if_modified_since+         - String. A DateTime value. Specify this conditional header to renew the lease
    #                                  only if the blob has been modified since the specified date/time. If the blob has not been modified, 
    #                                  the Blob service returns status code 412 (Precondition Failed).
    # * +:if_unmodified_since+       - String. A DateTime value. Specify this conditional header to renew the lease
    #                                  only if the blob has not been modified since the specified date/time. If the blob has been modified, 
    #                                  the Blob service returns status code 412 (Precondition Failed).
    # * +:if_match+                  - String. An ETag value. Specify an ETag value for this conditional header to renew the lease
    #                                  only if the blob's ETag value matches the value specified. If the values do not match, 
    #                                  the Blob service returns status code 412 (Precondition Failed).
    # * +:if_none_match+             - String. An ETag value. Specify an ETag value for this conditional header to renew the lease
    #                                  only if the blob's ETag value does not match the value specified. If the values are identical, 
    #                                  the Blob service returns status code 412 (Precondition Failed).
    # See http://msdn.microsoft.com/en-us/library/azure/ee691972.aspx
    #
    # Returns the renewed lease id
    def renew_blob_lease(container, blob, lease, options={})
      renew_lease container, blob, lease, options
    end
    
    # Public: Change the lease ID.
    #
    # ==== Attributes
    #
    # * +container+                  - String. The container name.
    # * +blob+                       - String. The blob name.
    # * +lease+                      - String. The existing lease id.
    # * +proposed_lease+             - String. Proposed lease ID, in a GUID string format. The Blob service returns 400 (Invalid request)
    #                                  if the proposed lease ID is not in the correct format. (optional).
    # * +options+                    - Hash. Optional parameters.
    #
    # ==== Options
    #
    # Accepted key/value pairs in options parameter are:
    # * +:timeout+                   - Integer. A timeout in seconds.
    # * +:request_id+                - String. Provides a client-generated, opaque value with a 1 KB character limit that is recorded 
    #                                  in the analytics logs when storage analytics logging is enabled.
    # * +:if_modified_since+         - String. A DateTime value. Specify this conditional header to change the lease
    #                                  only if the blob has been modified since the specified date/time. If the blob has not been modified, 
    #                                  the Blob service returns status code 412 (Precondition Failed).
    # * +:if_unmodified_since+       - String. A DateTime value. Specify this conditional header to change the lease
    #                                  only if the blob has not been modified since the specified date/time. If the blob has been modified, 
    #                                  the Blob service returns status code 412 (Precondition Failed).
    # * +:if_match+                  - String. An ETag value. Specify an ETag value for this conditional header to change the lease
    #                                  only if the blob's ETag value matches the value specified. If the values do not match, 
    #                                  the Blob service returns status code 412 (Precondition Failed).
    # * +:if_none_match+             - String. An ETag value. Specify an ETag value for this conditional header to change the lease
    #                                  only if the blob's ETag value does not match the value specified. If the values are identical, 
    #                                  the Blob service returns status code 412 (Precondition Failed).
    # See http://msdn.microsoft.com/en-us/library/azure/ee691972.aspx
    #
    # Returns the changed lease id
    def change_blob_lease(container, blob, lease, proposed_lease, options={})
      change_lease container, blob, lease, proposed_lease, options
    end

    # Public: Releases the lease. The lease may be released if the lease ID specified on the request matches that
    # associated with the blob. Releasing the lease allows another client to immediately acquire the lease for
    # the blob as soon as the release is complete.
    #
    # ==== Attributes
    #
    # * +container+                  - String. The container name.
    # * +blob+                       - String. The blob name.
    # * +lease+                      - String. The lease id.
    # * +options+                    - Hash. Optional parameters.
    #
    # ==== Options
    #
    # Accepted key/value pairs in options parameter are:
    # * +:timeout+                   - Integer. A timeout in seconds.
    # * +:request_id+                - String. Provides a client-generated, opaque value with a 1 KB character limit that is recorded 
    #                                  in the analytics logs when storage analytics logging is enabled.
    # * +:if_modified_since+         - String. A DateTime value. Specify this conditional header to release the lease
    #                                  only if the blob has been modified since the specified date/time. If the blob has not been modified, 
    #                                  the Blob service returns status code 412 (Precondition Failed).
    # * +:if_unmodified_since+       - String. A DateTime value. Specify this conditional header to release the lease
    #                                  only if the blob has not been modified since the specified date/time. If the blob has been modified, 
    #                                  the Blob service returns status code 412 (Precondition Failed).
    # * +:if_match+                  - String. An ETag value. Specify an ETag value for this conditional header to release the lease
    #                                  only if the blob's ETag value matches the value specified. If the values do not match, 
    #                                  the Blob service returns status code 412 (Precondition Failed).
    # * +:if_none_match+             - String. An ETag value. Specify an ETag value for this conditional header to release the lease
    #                                  only if the blob's ETag value does not match the value specified. If the values are identical, 
    #                                  the Blob service returns status code 412 (Precondition Failed).
    # See http://msdn.microsoft.com/en-us/library/azure/ee691972.aspx
    #
    # Returns nil on success
    def release_blob_lease(container, blob, lease, options={})
      release_lease container, blob, lease, options
    end

    # Public: Breaks the lease, if the blob has an active lease. Once a lease is broken, it cannot be renewed. Any
    # authorized request can break the lease; the request is not required to specify a matching lease ID. When a
    # lease is broken, the lease break period is allowed to elapse, during which time no lease operation except
    # break and release can be performed on the blob. When a lease is successfully broken, the response indicates
    # the interval in seconds until a new lease can be acquired.
    #
    # A lease that has been broken can also be released, in which case another client may immediately acquire the
    # lease on the blob.
    #
    # ==== Attributes
    #
    # * +container+                  - String. The container name.
    # * +blob+                       - String. The blob name.
    # * +options+                    - Hash. Optional parameters.
    #
    # ==== Options
    #
    # Accepted key/value pairs in options parameter are:
    # * +:break_period+              - Integer. The proposed duration of seconds that the lease should continue before it is
    #                                  broken, between 0 and 60 seconds. This break period is only used if it is shorter than
    #                                  the time remaining on the lease. If longer, the time remaining on the lease is used. A
    #                                  new lease will not be available before the break period has expired, but the lease may
    #                                  be held for longer than the break period.
    #
    #                                  If this option is not used, a fixed-duration lease breaks after the remaining lease
    #                                  period elapses, and an infinite lease breaks immediately.
    # * +:timeout+                   - Integer. A timeout in seconds.
    # * +:request_id+                - String. Provides a client-generated, opaque value with a 1 KB character limit that is recorded 
    #                                  in the analytics logs when storage analytics logging is enabled.
    # * +:if_modified_since+         - String. A DateTime value. Specify this conditional header to break the lease
    #                                  only if the blob has been modified since the specified date/time. If the blob has not been modified, 
    #                                  the Blob service returns status code 412 (Precondition Failed).
    # * +:if_unmodified_since+       - String. A DateTime value. Specify this conditional header to break the lease
    #                                  only if the blob has not been modified since the specified date/time. If the blob has been modified, 
    #                                  the Blob service returns status code 412 (Precondition Failed).
    # * +:if_match+                  - String. An ETag value. Specify an ETag value for this conditional header to break the lease
    #                                  only if the blob's ETag value matches the value specified. If the values do not match, 
    #                                  the Blob service returns status code 412 (Precondition Failed).
    # * +:if_none_match+             - String. An ETag value. Specify an ETag value for this conditional header to break the lease
    #                                  only if the blob's ETag value does not match the value specified. If the values are identical, 
    #                                  the Blob service returns status code 412 (Precondition Failed).
    # See http://msdn.microsoft.com/en-us/library/azure/ee691972.aspx
    #
    # Returns an Integer of the remaining lease time. This value is the approximate time remaining in the lease
    # period, in seconds. This header is returned only for a successful request to break the lease. If the break
    # is immediate, 0 is returned.
    def break_blob_lease(container, blob, options={})
      break_lease container, blob, options
    end
    
    # Public: Creates a snapshot of a blob.
    #
    # ==== Attributes
    #
    # * +container+                  - String. The container name.
    # * +blob+                       - String. The blob name.
    # * +options+                    - Hash. Optional parameters.
    #
    # ==== Options
    #
    # Accepted key/value pairs in options parameter are:
    # * +:metadata+                  - Hash. Custom metadata values to store with the blob snapshot.
    # * +:timeout+                   - Integer. A timeout in seconds.
    # * +:request_id+                - String. Provides a client-generated, opaque value with a 1 KB character limit that is recorded 
    #                                  in the analytics logs when storage analytics logging is enabled.
    # * +:if_modified_since+         - String. A DateTime value. Specify this conditional header to create the blob snapshot
    #                                  only if the blob has been modified since the specified date/time. If the blob has not been modified, 
    #                                  the Blob service returns status code 412 (Precondition Failed).
    # * +:if_unmodified_since+       - String. A DateTime value. Specify this conditional header to create the blob snapshot
    #                                  only if the blob has not been modified since the specified date/time. If the blob has been modified, 
    #                                  the Blob service returns status code 412 (Precondition Failed).
    # * +:if_match+                  - String. An ETag value. Specify an ETag value for this conditional header to create the blob snapshot
    #                                  only if the blob's ETag value matches the value specified. If the values do not match, 
    #                                  the Blob service returns status code 412 (Precondition Failed).
    # * +:if_none_match+             - String. An ETag value. Specify an ETag value for this conditional header to create the blob snapshot
    #                                  only if the blob's ETag value does not match the value specified. If the values are identical, 
    #                                  the Blob service returns status code 412 (Precondition Failed).
    #
    # See http://msdn.microsoft.com/en-us/library/azure/ee691971.aspx
    #
    # Returns the snapshot DateTime value
    def create_blob_snapshot(container, blob, options={})
      query = { 'comp' => 'snapshot'}
      StorageService.with_query query, 'timeout', options[:timeout].to_s if options[:timeout]

      uri = blob_uri(container, blob, query)

      headers = StorageService.common_headers
      unless options.empty?
        StorageService.add_metadata_to_headers(options[:metadata], headers)
        add_blob_conditional_headers(options, headers)
      end

      response = call(:put, uri, nil, headers, options)

      response.headers['x-ms-snapshot']
    end
    
    # Public: Copies a source blob or file to a destination blob.
    #
    # ==== Attributes
    #
    # * +destination_container+      - String. The destination container name to copy to.
    # * +destination_blob+           - String. The destination blob name to copy to.
    # * +source_uri+                 - String. The source blob or file URI to copy from.
    # * +options+                    - Hash. Optional parameters.
    #
    # ==== Options
    #
    # Accepted key/value pairs in options parameter are:
    # * +:source_snapshot+            - String. A snapshot id for the source blob
    # * +:metadata+                   - Hash. Custom metadata values to store with the copy. If this parameter is not
    #                                   specified, the operation will copy the source blob metadata to the destination
    #                                   blob. If this parameter is specified, the destination blob is created with the
    #                                   specified metadata, and metadata is not copied from the source blob.
    # * +:source_if_modified_since+   - String. A DateTime value. Specify this option to write the page only if the source blob
    #                                   has been modified since the specified date/time. If the blob has not been
    #                                   modified, the Blob service returns status code 412 (Precondition Failed).
    # * +:source_if_unmodified_since+ - String. A DateTime value. Specify this option to write the page only if the source blob
    #                                   has not been modified since the specified date/time. If the blob has been
    #                                   modified, the Blob service returns status code 412 (Precondition Failed).
    # * +:source_if_match+            - String. An ETag value. Specify an ETag value to write the page only if the source blob's
    #                                   ETag value matches the value specified. If the values do not match, the Blob
    #                                   service returns status code 412 (Precondition Failed).
    # * +:source_if_none_match+       - String. An ETag value. Specify an ETag value to write the page only if the source blob's
    #                                   ETag value does not match the value specified. If the values are identical, the
    #                                   Blob service returns status code 412 (Precondition Failed).
    # * +:dest_if_modified_since+     - String. A DateTime value. Specify this option to write the page only if the destination
    #                                   blob has been modified since the specified date/time. If the blob has not been
    #                                   modified, the Blob service returns status code 412 (Precondition Failed).
    # * +:dest_if_unmodified_since+   - String. A DateTime value. Specify this option to write the page only if the destination
    #                                   blob has not been modified since the specified date/time. If the blob has been
    #                                   modified, the Blob service returns status code 412 (Precondition Failed).
    # * +:dest_if_match+              - String. An ETag value. Specify an ETag value to write the page only if the destination
    #                                   blob's ETag value matches the value specified. If the values do not match, the
    #                                   Blob service returns status code 412 (Precondition Failed).
    # * +:dest_if_none_match+         - String. An ETag value. Specify an ETag value to write the page only if the destination
    #                                   blob's ETag value does not match the value specified. If the values are
    #                                   identical, the Blob service returns status code 412 (Precondition Failed).
    # * +:timeout+                    - Integer. A timeout in seconds.
    # * +:request_id+                 - String. Provides a client-generated, opaque value with a 1 KB character limit that is recorded 
    #                                   in the analytics logs when storage analytics logging is enabled.
    #
    # See http://msdn.microsoft.com/en-us/library/azure/dd894037.aspx
    #
    # Returns a tuple of (copy_id, copy_status).
    #
    # * +copy_id+                    - String identifier for this copy operation. Use with get_blob or get_blob_properties to check
    #                                  the status of this copy operation, or pass to abort_copy_blob to abort a pending copy.
    # * +copy_status+                - String. The state of the copy operation, with these values:
    #                                    "success" - The copy completed successfully.
    #                                    "pending" - The copy is in progress.
    #
    def copy_blob_from_uri(destination_container, destination_blob, source_uri, options={})
      query = { }
      StorageService.with_query query, 'timeout', options[:timeout].to_s if options[:timeout]

      uri = blob_uri(destination_container, destination_blob, query)
      headers = StorageService.common_headers
      StorageService.with_header headers, 'x-ms-copy-source', source_uri

      unless options.empty?
        add_blob_conditional_headers options, headers
        StorageService.add_metadata_to_headers options[:metadata], headers
      end

      response = call(:put, uri, nil, headers, options)
      return response.headers['x-ms-copy-id'], response.headers['x-ms-copy-status']
    end
    
    # Public: Copies a source blob to a destination blob within the same storage account.
    #
    # ==== Attributes
    #
    # * +destination_container+      - String. The destination container name to copy to.
    # * +destination_blob+           - String. The destination blob name to copy to.
    # * +source_container+           - String. The source container name to copy from.
    # * +source_blob+                - String. The source blob name to copy from.
    # * +options+                    - Hash. Optional parameters.
    #
    # ==== Options
    #
    # Accepted key/value pairs in options parameter are:
    # * +:source_snapshot+            - String. A snapshot id for the source blob
    # * +:metadata+                   - Hash. Custom metadata values to store with the copy. If this parameter is not
    #                                   specified, the operation will copy the source blob metadata to the destination
    #                                   blob. If this parameter is specified, the destination blob is created with the
    #                                   specified metadata, and metadata is not copied from the source blob.
    # * +:source_if_modified_since+   - String. A DateTime value. Specify this option to write the page only if the source blob
    #                                   has been modified since the specified date/time. If the blob has not been
    #                                   modified, the Blob service returns status code 412 (Precondition Failed).
    # * +:source_if_unmodified_since+ - String. A DateTime value. Specify this option to write the page only if the source blob
    #                                   has not been modified since the specified date/time. If the blob has been
    #                                   modified, the Blob service returns status code 412 (Precondition Failed).
    # * +:source_if_match+            - String. An ETag value. Specify an ETag value to write the page only if the source blob's
    #                                   ETag value matches the value specified. If the values do not match, the Blob
    #                                   service returns status code 412 (Precondition Failed).
    # * +:source_if_none_match+       - String. An ETag value. Specify an ETag value to write the page only if the source blob's
    #                                   ETag value does not match the value specified. If the values are identical, the
    #                                   Blob service returns status code 412 (Precondition Failed).
    # * +:dest_if_modified_since+     - String. A DateTime value. Specify this option to write the page only if the destination
    #                                   blob has been modified since the specified date/time. If the blob has not been
    #                                   modified, the Blob service returns status code 412 (Precondition Failed).
    # * +:dest_if_unmodified_since+   - String. A DateTime value. Specify this option to write the page only if the destination
    #                                   blob has not been modified since the specified date/time. If the blob has been
    #                                   modified, the Blob service returns status code 412 (Precondition Failed).
    # * +:dest_if_match+              - String. An ETag value. Specify an ETag value to write the page only if the destination
    #                                   blob's ETag value matches the value specified. If the values do not match, the
    #                                   Blob service returns status code 412 (Precondition Failed).
    # * +:dest_if_none_match+         - String. An ETag value. Specify an ETag value to write the page only if the destination
    #                                   blob's ETag value does not match the value specified. If the values are
    #                                   identical, the Blob service returns status code 412 (Precondition Failed).
    # * +:timeout+                    - Integer. A timeout in seconds.
    # * +:request_id+                 - String. Provides a client-generated, opaque value with a 1 KB character limit that is recorded 
    #                                   in the analytics logs when storage analytics logging is enabled.
    #
    # See http://msdn.microsoft.com/en-us/library/azure/dd894037.aspx
    #
    # Returns a tuple of (copy_id, copy_status).
    #
    # * +copy_id+                    - String identifier for this copy operation. Use with get_blob or get_blob_properties to check
    #                                  the status of this copy operation, or pass to abort_copy_blob to abort a pending copy.
    # * +copy_status+                - String. The state of the copy operation, with these values:
    #                                    "success" - The copy completed successfully.
    #                                    "pending" - The copy is in progress.
    #
    def copy_blob(destination_container, destination_blob, source_container, source_blob, options={})
      source_blob_uri = blob_uri(source_container, source_blob, options[:source_snapshot] ? { 'snapshot' => options[:source_snapshot] } : {}).to_s

      return copy_blob_from_uri(destination_container, destination_blob, source_blob_uri, options)
    end
    
    # Public: Aborts a pending Copy Blob operation and leaves a destination blob with zero length and full metadata. 
    #
    # ==== Attributes
    #
    # * +container+             - String. The destination container name.
    # * +blob+                  - String. The destination blob name.
    # * +copy_id+               - String. The copy identifier returned in the copy blob operation.
    # * +options+               - Hash. Optional parameters.
    #
    # ==== Options
    #
    # Accepted key/value pairs in options parameter are:
    # * +:lease_id+             - String. The lease id if the destination blob has an active infinite lease
    # * +:timeout+              - Integer. A timeout in seconds.
    # * +:request_id+           - String. Provides a client-generated, opaque value with a 1 KB character limit that is recorded 
    #                             in the analytics logs when storage analytics logging is enabled.
    #
    # See https://msdn.microsoft.com/en-us/library/azure/jj159098.aspx
    #
    # Returns nil on success
    def abort_copy_blob(container, blob, copy_id, options={})
      query = { 'comp' => 'copy'}
      StorageService.with_query query, 'timeout', options[:timeout].to_s if options[:timeout]
      StorageService.with_query query, 'copyid', copy_id

      uri = blob_uri(container, blob, query);
      headers = StorageService.common_headers
      StorageService.with_header headers, 'x-ms-copy-action', 'abort';
      
      unless options.empty?
        StorageService.with_header headers, 'x-ms-lease-id', options[:lease_id]
      end

      call(:put, uri, nil, headers, options)
      nil
    end
    
    # Public: Deletes a blob or blob snapshot.
    #
    # ==== Attributes
    #
    # * +container+                  - String. The container name.
    # * +blob+                       - String. The blob name.
    # * +options+                    - Hash. Optional parameters.
    #
    # ==== Options
    #
    # Accepted key/value pairs in options parameter are:
    # * +:snapshot+                  - String. An opaque DateTime value that specifies the blob snapshot to
    #                                  retrieve information from. (optional)
    # * +:delete_snapshots+          - Symbol. Used to specify the scope of the delete operation for snapshots.
    #                                  This parameter is ignored if a blob does not have snapshots, or if a
    #                                  snapshot is specified in the snapshot parameter. (optional)
    #
    #                                  Possible values include:
    #                                    * +:only+     - Deletes only the snapshots for the blob, but leaves the blob
    #                                    * +:include+  - Deletes the blob and all of the snapshots for the blob
    # * +:timeout+                   - Integer. A timeout in seconds.
    # * +:request_id+                - String. Provides a client-generated, opaque value with a 1 KB character limit that is recorded 
    #                                  in the analytics logs when storage analytics logging is enabled.
    # * +:if_modified_since+         - String. A DateTime value. Specify this conditional header to create the blob snapshot
    #                                  only if the blob has been modified since the specified date/time. If the blob has not been modified, 
    #                                  the Blob service returns status code 412 (Precondition Failed).
    # * +:if_unmodified_since+       - String. A DateTime value. Specify this conditional header to create the blob snapshot
    #                                  only if the blob has not been modified since the specified date/time. If the blob has been modified, 
    #                                  the Blob service returns status code 412 (Precondition Failed).
    # * +:if_match+                  - String. An ETag value. Specify an ETag value for this conditional header to create the blob snapshot
    #                                  only if the blob's ETag value matches the value specified. If the values do not match, 
    #                                  the Blob service returns status code 412 (Precondition Failed).
    # * +:if_none_match+             - String. An ETag value. Specify an ETag value for this conditional header to create the blob snapshot
    #                                  only if the blob's ETag value does not match the value specified. If the values are identical, 
    #                                  the Blob service returns status code 412 (Precondition Failed).
    #
    # See http://msdn.microsoft.com/en-us/library/azure/dd179440.aspx
    #
    # Returns nil on success
    def delete_blob(container, blob, options={})
      query = { }
      StorageService.with_query query, 'snapshot', options[:snapshot]
      StorageService.with_query query, 'timeout', options[:timeout].to_s if options[:timeout]

      uri = blob_uri(container, blob, query)

      options[:delete_snapshots] = :include unless options[:delete_snapshots]

      headers = StorageService.common_headers
      StorageService.with_header headers, 'x-ms-delete-snapshots', options[:delete_snapshots].to_s if options[:delete_snapshots] && options[:snapshot] == nil
      add_blob_conditional_headers options, headers

      call(:delete, uri, nil, headers, options)
      nil
    end
    
  end
end