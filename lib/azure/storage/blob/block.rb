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
    # Represents a Block as part of a BlockList 
    # The type should be one of :uncommitted, :committed or :latest
    class Block
      
      def initialize
        @type = :latest
        yield self if block_given?
      end

      attr_accessor :name
      attr_accessor :size
      attr_accessor :type
    end
    
    # Public: Creates a new block blob or updates the content of an existing block blob.
    #
    # Updating an existing block blob overwrites any existing metadata on the blob
    # Partial updates are not supported with create_block_blob the content of the
    # existing blob is overwritten with the content of the new blob. To perform a
    # partial update of the content of a block blob, use the create_block_list
    # method.
    #
    # Note that the default content type is application/octet-stream.
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
    def create_block_blob(container, blob, content, options={})
      query = { }
      StorageService.with_query query, 'timeout', options[:timeout].to_s if options[:timeout]

      uri = blob_uri(container, blob, query)

      headers = StorageService.common_headers

      # set x-ms-blob-type to BlockBlob
      StorageService.with_header headers, 'x-ms-blob-type', 'BlockBlob'

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
      response = call(:put, uri, content, headers, options)

      result = Serialization.blob_from_headers(response.headers)
      result.name = blob
      result.metadata = options[:metadata] if options[:metadata]

      result
    end
    
    # Public: Creates a new block to be committed as part of a block blob.
    #
    # ==== Attributes
    #
    # * +container+   - String. The container name.
    # * +blob+        - String. The blob name.
    # * +block_id+    - String. The block id. Note: this should be the raw block id, not Base64 encoded.
    # * +content+     - IO or String. The content of the blob.
    # * +options+      - Hash. Optional parameters.
    #
    # ==== Options
    #
    # Accepted key/value pairs in options parameter are:
    # * +:content_md5+           - String. Content MD5 for the request contents.
    # * +:timeout+               - Integer. A timeout in seconds.
    # * +:request_id+            - String. Provides a client-generated, opaque value with a 1 KB character limit that is recorded 
    #                              in the analytics logs when storage analytics logging is enabled.
    #
    # See http://msdn.microsoft.com/en-us/library/azure/dd135726.aspx
    #
    # Returns response of the operation
    def put_blob_block(container, blob, block_id, content, options={})
      query = { 'comp' => 'block'}
      StorageService.with_query query, 'blockid', Base64.strict_encode64(block_id)
      StorageService.with_query query, 'timeout', options[:timeout].to_s if options[:timeout]

      uri = blob_uri(container, blob, query)

      headers = StorageService.common_headers
      StorageService.with_header headers, 'Content-MD5', options[:content_md5]

      response = call(:put, uri, content, headers, options)
      response.headers['Content-MD5']
    end

    # Public: Commits existing blob blocks to a blob.
    #
    # This method writes a blob by specifying the list of block IDs that make up the
    # blob. In order to be written as part of a blob, a block must have been
    # successfully written to the server in a prior put_blob_block method.
    #
    # You can call Put Block List to update a blob by uploading only those blocks
    # that have changed, then committing the new and existing blocks together.
    # You can do this by specifying whether to commit a block from the committed
    # block list or from the uncommitted block list, or to commit the most recently
    # uploaded version of the block, whichever list it may belong to.
    #
    # ==== Attributes
    #
    # * +container+   - String. The container name.
    # * +blob+        - String. The blob name.
    # * +block_list+  - Array. A ordered list of lists in the following format:
    #   [ ["block_id1", :committed], ["block_id2", :uncommitted], ["block_id3"], ["block_id4", :committed]... ]
    #   The first element of the inner list is the block_id, the second is optional
    #   and can be either :committed or :uncommitted to indicate in which group of blocks
    #   the id should be looked for. If it is omitted, the latest of either group will be used.
    # * +options+     - Hash. Optional parameters.
    #
    # ==== Options
    #
    # Accepted key/value pairs in options parameter are:
    # * +:transactional_md5+         - String. Content MD5 for the request contents (not the blob contents!)
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
    #
    # This operation also supports the use of conditional headers to commit the block list if a specified condition is met.
    # For more information, see https://msdn.microsoft.com/en-us/library/azure/dd179371.aspx
    #
    # See http://msdn.microsoft.com/en-us/library/azure/dd179467.aspx 
    #
    # Returns nil on success
    def commit_blob_blocks(container, blob, block_list, options={})
      query = { 'comp' => 'blocklist'}
      StorageService.with_query query, 'timeout', options[:timeout].to_s if options[:timeout]

      uri = blob_uri(container, blob, query)

      headers = StorageService.common_headers
      unless options.empty?
        StorageService.with_header headers, 'Content-MD5', options[:transactional_md5]
        StorageService.with_header headers, 'x-ms-blob-content-type', options[:content_type]
        StorageService.with_header headers, 'x-ms-blob-content-encoding', options[:content_encoding]
        StorageService.with_header headers, 'x-ms-blob-content-language', options[:content_language]
        StorageService.with_header headers, 'x-ms-blob-content-md5', options[:content_md5]
        StorageService.with_header headers, 'x-ms-blob-cache-control', options[:cache_control]
        StorageService.with_header headers, 'x-ms-blob-content-disposition', options[:content_disposition]

        StorageService.add_metadata_to_headers(options[:metadata], headers)
        add_blob_conditional_headers(options, headers)
      end

      body = Serialization.block_list_to_xml(block_list)
      call(:put, uri, body, headers, options)
      nil
    end

    # Public: Retrieves the list of blocks that have been uploaded as part of a block blob.
    #
    # There are two block lists maintained for a blob:
    # 1) Committed Block List: The list of blocks that have been successfully
    #    committed to a given blob with commitBlobBlocks.
    # 2) Uncommitted Block List: The list of blocks that have been uploaded for a 
    #    blob using Put Block (REST API), but that have not yet been committed. 
    #    These blocks are stored in Microsoft Azure in association with a blob, but do
    #    not yet form part of the blob.
    #
    # ==== Attributes
    #
    # * +container+                 - String. The container name.
    # * +blob+                      - String. The blob name.
    # * +options+                   - Hash. Optional parameters.
    #
    # ==== Options
    #
    # Accepted key/value pairs in options parameter are:
    # * +:blocklist_type+           - Symbol. One of :all, :committed, :uncommitted. Defaults to :all (optional)
    # * +:snapshot+                 - String. An opaque DateTime value that specifies the blob snapshot to
    #                                 retrieve information from. (optional)
    # * +:timeout+                  - Integer. A timeout in seconds.
    # * +:request_id+               - String. Provides a client-generated, opaque value with a 1 KB character limit that is recorded 
    #                                 in the analytics logs when storage analytics logging is enabled.
    #
    # See http://msdn.microsoft.com/en-us/library/azure/dd179400.aspx
    #
    # Returns a list of Azure::Storage::Entity::Blob::Block instances
    def list_blob_blocks(container, blob, options={})

      options[:blocklist_type] = options[:blocklist_type] || :all

      query = { 'comp' => 'blocklist'}
      StorageService.with_query query, 'snapshot', options[:snapshot]
      StorageService.with_query query, 'blocklisttype', options[:blocklist_type].to_s if options[:blocklist_type]
      StorageService.with_query query, 'timeout', options[:timeout].to_s if options[:timeout]

      uri = blob_uri(container, blob, query)

      response = call(:get, uri, nil, {}, options)

      Serialization.block_list_from_xml(response.body)
    end
  end
end