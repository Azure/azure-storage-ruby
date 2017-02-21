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
    # Public: Creates a new append blob. Note that calling create_append_blob to create an append
    # blob only initializes the blob. To add content to an append blob, call append_blob_blocks method.
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
    # * +:transactional_md5+         - String. An MD5 hash of the blob content. This hash is used to verify the integrity of the blob during transport. 
    #                                  When this header is specified, the storage service checks the hash that has arrived with the one that was sent. 
    #                                  If the two hashes do not match, the operation will fail with error code 400 (Bad Request).
    # * +:content_type+              - String. Content type for the blob. Will be saved with blob.
    # * +:content_encoding+          - String. Content encoding for the blob. Will be saved with blob.
    # * +:content_language+          - String. Content language for the blob. Will be saved with blob.
    # * +:content_md5+               - String. Content MD5 for the blob. Will be saved with blob.
    # * +:cache_control+             - String. Cache control for the blob. Will be saved with blob.
    # * +:content_disposition+       - String. Conveys additional information about how to process the response payload, 
    #                                  and also can be used to attach additional metadata
    # * +:metadata+                  - Hash. Custom metadata values to store with the blob.
    # * +:timeout+                   - Integer. A timeout in seconds.
    # * +:request_id+                - String. Provides a client-generated, opaque value with a 1 KB character limit that is recorded 
    #                                  in the analytics logs when storage analytics logging is enabled.
    # * +:if_modified_since+         - String. A DateTime value. Specify this conditional header to create a new blob 
    #                                  only if the blob has been modified since the specified date/time. If the blob has not been modified, 
    #                                  the Blob service returns status code 412 (Precondition Failed).
    # * +:if_unmodified_since+       - String. A DateTime value. Specify this conditional header to create a new blob 
    #                                  only if the blob has not been modified since the specified date/time. If the blob has been modified, 
    #                                  the Blob service returns status code 412 (Precondition Failed).
    # * +:if_match+                  - String. An ETag value. Specify an ETag value for this conditional header to create a new blob 
    #                                  only if the blob's ETag value matches the value specified. If the values do not match, 
    #                                  the Blob service returns status code 412 (Precondition Failed).
    # * +:if_none_match+             - String. An ETag value. Specify an ETag value for this conditional header to create a new blob 
    #                                  only if the blob's ETag value does not match the value specified. If the values are identical, 
    #                                  the Blob service returns status code 412 (Precondition Failed).
    #
    # See http://msdn.microsoft.com/en-us/library/azure/dd179451.aspx
    #
    # Returns a Blob
    def create_append_blob(container, blob, options={})
      query = { }
      StorageService.with_query query, 'timeout', options[:timeout].to_s if options[:timeout]

      uri = blob_uri(container, blob, query)

      headers = StorageService.common_headers

      # set x-ms-blob-type to AppendBlob
      StorageService.with_header headers, 'x-ms-blob-type', 'AppendBlob'

      # ensure content-length is 0
      StorageService.with_header headers, 'Content-Length', 0.to_s

      # set the rest of the optional headers
      StorageService.with_header headers, 'Content-MD5', options[:transactional_md5]
      StorageService.with_header headers, 'x-ms-blob-content-type', options[:content_type]
      StorageService.with_header headers, 'x-ms-blob-content-encoding', options[:content_encoding]
      StorageService.with_header headers, 'x-ms-blob-content-language', options[:content_language]
      StorageService.with_header headers, 'x-ms-blob-content-md5', options[:content_md5]
      StorageService.with_header headers, 'x-ms-blob-cache-control', options[:cache_control]
      StorageService.with_header headers, 'x-ms-blob-content-disposition', options[:content_disposition]

      StorageService.add_metadata_to_headers options[:metadata], headers
      add_blob_conditional_headers options, headers

      # call PutBlob with empty body
      response = call(:put, uri, nil, headers, options)

      result = Serialization.blob_from_headers(response.headers)
      result.name = blob
      result.metadata = options[:metadata] if options[:metadata]

      result
    end
    
    # Public: Commits a new block of data to the end of an existing append blob.
    # This operation is permitted only on blobs created with the create_append_blob API.
    #
    # ==== Attributes
    #
    # * +container+                  - String. The container name.
    # * +blob+                       - String. The blob name.
    # * +content+                    - IO or String. The content of the blob.
    # * +options+                    - Hash. Optional parameters.
    #
    # ==== Options
    #
    # Accepted key/value pairs in options parameter are:
    # * +:content_md5+               - String. Content MD5 for the request contents.
    # * +:lease_id+                  - String. The lease id if the blob has an active lease
    # * +:max_size+                  - Integer. The max length in bytes permitted for the append blob
    # * +:append_position+           - Integer. A number indicating the byte offset to compare. It will succeed only if the append position is equal to this number
    # * +:timeout+                   - Integer. A timeout in seconds.
    # * +:request_id+                - String. Provides a client-generated, opaque value with a 1 KB character limit that is recorded 
    #                                  in the analytics logs when storage analytics logging is enabled.
    # * +:if_modified_since+         - String. A DateTime value. Specify this conditional header to append a block only if 
    #                                  the blob has been modified since the specified date/time. If the blob has not been modified, 
    #                                  the Blob service returns status code 412 (Precondition Failed).
    # * +:if_unmodified_since+       - String. A DateTime value. Specify this conditional header to append a block only if 
    #                                  the blob has not been modified since the specified date/time. If the blob has been modified, 
    #                                  the Blob service returns status code 412 (Precondition Failed).
    # * +:if_match+                  - String. An ETag value. Specify an ETag value for this conditional header to append a block only if 
    #                                  the blob's ETag value matches the value specified. If the values do not match, 
    #                                  the Blob service returns status code 412 (Precondition Failed).
    # * +:if_none_match+             - String. An ETag value. Specify an ETag value for this conditional header to append a block only if 
    #                                  the blob's ETag value does not match the value specified. If the values are identical, 
    #                                  the Blob service returns status code 412 (Precondition Failed).
    #
    # See http://msdn.microsoft.com/en-us/library/azure/mt427365.aspx
    #
    # Returns a Blob
    def append_blob_block(container, blob, content, options={})
      query = { 'comp' => 'appendblock' }
      StorageService.with_query query, 'timeout', options[:timeout].to_s if options[:timeout]

      uri = blob_uri(container, blob, query)

      headers = StorageService.common_headers
      StorageService.with_header headers, 'Content-MD5', options[:content_md5]
      StorageService.with_header headers, 'x-ms-lease-id', options[:lease_id]
      
      add_blob_conditional_headers options, headers

      response = call(:put, uri, content, headers, options)
      result = Serialization.blob_from_headers(response.headers)
      result.name = blob

      result
    end
  end
end