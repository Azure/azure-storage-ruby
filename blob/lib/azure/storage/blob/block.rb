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

require "base64"

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
    # * +:single_upload_threshold+   - Integer. Threshold in bytes for single upload, must be lower than 256MB or 256MB will be used.
    # * +:content_length+            - Integer. Length of the content to upload, must be specified if 'content' does not implement 'size'.
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
    # * +:lease_id+                  - String. Required if the blob has an active lease. To perform this operation on a blob with an active lease,
    #                                  specify the valid lease ID for this header.
    #
    # See http://msdn.microsoft.com/en-us/library/azure/dd179451.aspx
    #
    # Returns a Blob
    def create_block_blob(container, blob, content, options = {})
      size = if content.respond_to? :size
        content.size
      elsif options[:content_length]
        options[:content_length]
      else
        raise ArgumentError, "Either optional parameter 'content_length' should be set or 'content' should implement 'size' method to get payload's size."
      end

      threshold = get_single_upload_threshold(options[:single_upload_threshold])
      if size > threshold
        create_block_blob_multiple_put(container, blob, content, size, options)
      else
        create_block_blob_single_put(container, blob, content, options)
      end
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
    # * +:lease_id+              - String. Required if the blob has an active lease. To perform this operation on a blob with an
    #                              active lease, specify the valid lease ID for this header.
    #
    # See http://msdn.microsoft.com/en-us/library/azure/dd135726.aspx
    #
    # Returns response of the operation
    def put_blob_block(container, blob, block_id, content, options = {})
      query = { "comp" => "block" }
      StorageService.with_query query, "blockid", Base64.strict_encode64(block_id)
      StorageService.with_query query, "timeout", options[:timeout].to_s if options[:timeout]

      uri = blob_uri(container, blob, query)

      headers = {}
      StorageService.with_header headers, "Content-MD5", options[:content_md5]
      headers["x-ms-lease-id"] = options[:lease_id] if options[:lease_id]

      response = call(:put, uri, content, headers, options)
      response.headers["Content-MD5"]
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
    # * +:lease_id+                  - String. Required if the blob has an active lease. To perform this operation on a blob with an
    #                                  active lease, specify the valid lease ID for this header.
    #
    # This operation also supports the use of conditional headers to commit the block list if a specified condition is met.
    # For more information, see https://msdn.microsoft.com/en-us/library/azure/dd179371.aspx
    #
    # See http://msdn.microsoft.com/en-us/library/azure/dd179467.aspx
    #
    # Returns nil on success
    def commit_blob_blocks(container, blob, block_list, options = {})
      query = { "comp" => "blocklist" }
      StorageService.with_query query, "timeout", options[:timeout].to_s if options[:timeout]

      uri = blob_uri(container, blob, query)

      headers = {}
      unless options.empty?
        StorageService.with_header headers, "Content-MD5", options[:transactional_md5]
        StorageService.with_header headers, "x-ms-blob-content-type", options[:content_type]
        StorageService.with_header headers, "x-ms-blob-content-encoding", options[:content_encoding]
        StorageService.with_header headers, "x-ms-blob-content-language", options[:content_language]
        StorageService.with_header headers, "x-ms-blob-content-md5", options[:content_md5]
        StorageService.with_header headers, "x-ms-blob-cache-control", options[:cache_control]
        StorageService.with_header headers, "x-ms-blob-content-disposition", options[:content_disposition]

        StorageService.add_metadata_to_headers(options[:metadata], headers)
        add_blob_conditional_headers(options, headers)
        headers["x-ms-lease-id"] = options[:lease_id] if options[:lease_id]
      end
      headers["x-ms-blob-content-type"] = Default::CONTENT_TYPE_VALUE unless headers["x-ms-blob-content-type"]
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
    # * +:location_mode+            - LocationMode. Specifies the location mode used to decide
    #                                 which location the request should be sent to.
    # * +:lease_id+                 - String. If this header is specified, the operation will be performed only if both of the
    #                                 following conditions are met:
    #                                   - The blob's lease is currently active.
    #                                   - The lease ID specified in the request matches that of the blob.
    #                                 If this header is specified and both of these conditions are not met, the request will fail
    #                                 and the operation will fail with status code 412 (Precondition Failed).
    #
    # See http://msdn.microsoft.com/en-us/library/azure/dd179400.aspx
    #
    # Returns a list of Azure::Storage::Entity::Blob::Block instances
    def list_blob_blocks(container, blob, options = {})
      options[:blocklist_type] = options[:blocklist_type] || :all

      query = { "comp" => "blocklist" }
      StorageService.with_query query, "snapshot", options[:snapshot]
      StorageService.with_query query, "blocklisttype", options[:blocklist_type].to_s if options[:blocklist_type]
      StorageService.with_query query, "timeout", options[:timeout].to_s if options[:timeout]

      headers = options[:lease_id] ? { "x-ms-lease-id" => options[:lease_id] } : {}

      options[:request_location_mode] = Azure::Storage::Common::RequestLocationMode::PRIMARY_OR_SECONDARY
      uri = blob_uri(container, blob, query, options)

      response = call(:get, uri, nil, headers, options)

      Serialization.block_list_from_xml(response.body)
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
    # * +:single_upload_threshold+   - Integer. Threshold in bytes for single upload, must be lower than 256MB or 256MB will be used.
    # * +:content_length+            - Integer. Length of the content to upload, must be specified if 'content' does not implement 'size'.
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
    # * +:lease_id+                  - String. Required if the blob has an active lease. To perform this operation on a blob with an active lease,
    #                                  specify the valid lease ID for this header.
    #
    # See http://msdn.microsoft.com/en-us/library/azure/dd179451.aspx
    #
    # Returns a Blob
    alias create_block_blob_from_content create_block_blob

    # Protected: Creates a new block blob or updates the content of an existing block blob with single API call
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
    # * +:content_length+            - Integer. Length of the content to upload, must be specified if 'content' does not implement 'size'.
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
    # * +:lease_id+                  - String. Required if the blob has an active lease. To perform this operation on a blob with an active lease,
    #                                  specify the valid lease ID for this header.
    #
    # See http://msdn.microsoft.com/en-us/library/azure/dd179451.aspx
    #
    # Returns a Blob
    protected
      def create_block_blob_single_put(container, blob, content, options = {})
        query = {}
        StorageService.with_query query, "timeout", options[:timeout].to_s if options[:timeout]

        uri = blob_uri(container, blob, query)

        headers = {}

        # set x-ms-blob-type to BlockBlob
        StorageService.with_header headers, "x-ms-blob-type", "BlockBlob"

        # set the rest of the optional headers
        StorageService.with_header headers, "Content-MD5", options[:transactional_md5]
        StorageService.with_header headers, "Content-Length", options[:content_length]
        StorageService.with_header headers, "x-ms-blob-content-encoding", options[:content_encoding]
        StorageService.with_header headers, "x-ms-blob-content-language", options[:content_language]
        StorageService.with_header headers, "x-ms-blob-content-md5", options[:content_md5]
        StorageService.with_header headers, "x-ms-blob-cache-control", options[:cache_control]
        StorageService.with_header headers, "x-ms-blob-content-disposition", options[:content_disposition]
        StorageService.with_header headers, "x-ms-lease-id", options[:lease_id]

        StorageService.add_metadata_to_headers options[:metadata], headers
        add_blob_conditional_headers options, headers
        StorageService.with_header headers, "x-ms-blob-content-type", get_or_apply_content_type(content, options[:content_type])
        # call PutBlob
        response = call(:put, uri, content, headers, options)

        result = Serialization.blob_from_headers(response.headers)
        result.name = blob
        result.metadata = options[:metadata] if options[:metadata]

        result
      end

    # Protected: Creates a new block blob or updates the content of an existing block blob with multiple upload
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
    # * +size+                       - Integer. The size of the content.
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
    # * +:metadata+                  - Hash. Custom metadata values to store with the blob.
    # * +:timeout+                   - Integer. A timeout in seconds.
    # * +:request_id+                - String. Provides a client-generated, opaque value with a 1 KB character limit that is recorded
    #                                  in the analytics logs when storage analytics logging is enabled.
    # * +:lease_id+                  - String. Required if the blob has an active lease. To perform this operation on a blob with an active lease,
    #                                  specify the valid lease ID for this header.
    #
    # See http://msdn.microsoft.com/en-us/library/azure/dd179451.aspx
    #
    # Returns a Blob
    protected
      def create_block_blob_multiple_put(container, blob, content, size, options = {})
        content_type = get_or_apply_content_type(content, options[:content_type])
        content = StringIO.new(content) if content.is_a? String
        block_size = get_block_size(size)
        # Get the number of blocks
        block_count = (Float(size) / Float(block_size)).ceil
        block_list = []
        for block_id in 0...block_count
          id = block_id.to_s.rjust(6, "0")
          put_blob_block(container, blob, id, content.read(block_size), timeout: options[:timeout], lease_id: options[:lease_id])
          block_list.push([id])
        end

        # Commit the blocks put
        commit_options = {}
        commit_options[:content_type] = content_type
        commit_options[:content_encoding] = options[:content_encoding] if options[:content_encoding]
        commit_options[:content_language] = options[:content_language] if options[:content_language]
        commit_options[:content_md5] = options[:content_md5] if options[:content_md5]
        commit_options[:cache_control] = options[:cache_control] if options[:cache_control]
        commit_options[:content_disposition] = options[:content_disposition] if options[:content_disposition]
        commit_options[:metadata] = options[:metadata] if options[:metadata]
        commit_options[:timeout] = options[:timeout] if options[:timeout]
        commit_options[:request_id] = options[:request_id] if options[:request_id]
        commit_options[:lease_id] = options[:lease_id] if options[:lease_id]

        commit_blob_blocks(container, blob, block_list, commit_options)

        get_properties_options = {}
        get_properties_options[:lease_id] = options[:lease_id] if options[:lease_id]

        # Get the blob properties
        get_blob_properties(container, blob, get_properties_options)
      end

    # Protected: Gets the single upload threshold according to user's preference
    #
    # ==== Attributes
    #
    # * +container+                  - String. The container name.
    #
    # Returns an Integer
    protected
      def get_single_upload_threshold(userThreshold)
        if userThreshold.nil?
          BlobConstants::DEFAULT_SINGLE_BLOB_PUT_THRESHOLD_IN_BYTES
        elsif userThreshold <= 0
          raise ArgumentError, "Single Upload Threshold should be positive number"
        elsif userThreshold < BlobConstants::MAX_SINGLE_UPLOAD_BLOB_SIZE_IN_BYTES
          userThreshold
        else
          BlobConstants::MAX_SINGLE_UPLOAD_BLOB_SIZE_IN_BYTES
        end
      end

    protected
      def get_block_size(size)
        if size > BlobConstants::MAX_BLOCK_BLOB_SIZE
          raise ArgumentError, "Block blob size should be less than #{BlobConstants::MAX_BLOCK_BLOB_SIZE} bytes in size"
        elsif (size / BlobConstants::MAX_BLOCK_COUNT) < BlobConstants::DEFAULT_WRITE_BLOCK_SIZE_IN_BYTES
          BlobConstants::DEFAULT_WRITE_BLOCK_SIZE_IN_BYTES
        else
          BlobConstants::MAX_BLOCK_SIZE
        end
      end
  end
end
