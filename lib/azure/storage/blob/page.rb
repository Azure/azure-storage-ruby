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
require "azure/storage/blob/blob"

module Azure::Storage
  module Blob
    # Public: Creates a new page blob. Note that calling create_page_blob to create a page
    # blob only initializes the blob. To add content to a page blob, call put_blob_pages method.
    #
    # ==== Attributes
    #
    # * +container+                  - String. The container name.
    # * +blob+                       - String. The blob name.
    # * +length+                     - Integer. Specifies the maximum size for the page blob, up to 1 TB.
    #                                  The page blob size must be aligned to a 512-byte boundary.
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
    # * +:sequence_number+           - Integer. The sequence number is a user-controlled value that you can use to track requests.
    #                                  The value of the sequence number must be between 0 and 2^63 - 1.The default value is 0.
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
    def create_page_blob(container, blob, length, options = {})
      query = {}
      StorageService.with_query query, "timeout", options[:timeout].to_s if options[:timeout]

      uri = blob_uri(container, blob, query)

      headers = StorageService.common_headers

      # set x-ms-blob-type to PageBlob
      StorageService.with_header headers, "x-ms-blob-type", "PageBlob"

      # ensure content-length is 0 and x-ms-blob-content-length is the blob length
      StorageService.with_header headers, "Content-Length", 0.to_s
      StorageService.with_header headers, "x-ms-blob-content-length", length.to_s

      # set x-ms-sequence-number from options (or default to 0)
      StorageService.with_header headers, "x-ms-sequence-number", (options[:sequence_number] || 0).to_s

      # set the rest of the optional headers
      StorageService.with_header headers, "Content-MD5", options[:transactional_md5]
      StorageService.with_header headers, "x-ms-blob-content-type", options[:content_type]
      StorageService.with_header headers, "x-ms-blob-content-encoding", options[:content_encoding]
      StorageService.with_header headers, "x-ms-blob-content-language", options[:content_language]
      StorageService.with_header headers, "x-ms-blob-content-md5", options[:content_md5]
      StorageService.with_header headers, "x-ms-blob-cache-control", options[:cache_control]
      StorageService.with_header headers, "x-ms-blob-content-disposition", options[:content_disposition]

      StorageService.add_metadata_to_headers options[:metadata], headers
      add_blob_conditional_headers options, headers
      headers["x-ms-lease-id"] = options[:lease_id] if options[:lease_id]

      # call PutBlob with empty body
      response = call(:put, uri, nil, headers, options)

      result = Serialization.blob_from_headers(response.headers)
      result.name = blob
      result.metadata = options[:metadata] if options[:metadata]

      result
    end

    # Public: Creates a range of pages in a page blob.
    #
    # ==== Attributes
    #
    # * +container+                  - String. Name of container
    # * +blob+                       - String. Name of blob
    # * +start_range+                - Integer. Position of first byte of first page
    # * +end_range+                  - Integer. Position of last byte of of last page
    # * +content+                    - IO or String. Content to write. Length in bytes should equal end_range - start_range + 1
    # * +options+                    - Hash. A collection of options.
    #
    # ==== Options
    #
    # Accepted key/value pairs in options parameter are:
    # * +:transactional_md5+         - String. An MD5 hash of the page content. This hash is used to verify the integrity of the page during transport.
    #                                  When this header is specified, the storage service checks the hash that has arrived with the one that was sent.
    # * +:if_sequence_number_le+     - Integer. If the blob's sequence number is less than or equal to the specified value, the request proceeds;
    #                                  otherwise it fails with the SequenceNumberConditionNotMet error (HTTP status code 412 - Precondition Failed).
    # * +:if_sequence_number_lt+     - Integer. If the blob's sequence number is less than the specified value, the request proceeds;
    #                                  otherwise it fails with SequenceNumberConditionNotMet error (HTTP status code 412 - Precondition Failed).
    # * +:if_sequence_number_eq+     - Integer. If the blob's sequence number is equal to the specified value, the request proceeds;
    #                                  otherwise it fails with SequenceNumberConditionNotMet error (HTTP status code 412 - Precondition Failed).
    # * +:if_modified_since+         - String. A DateTime value. Specify this conditional header to write the page only if
    #                                  the blob has been modified since the specified date/time. If the blob has not been modified,
    #                                  the Blob service returns status code 412 (Precondition Failed).
    # * +:if_unmodified_since+       - String. A DateTime value. Specify this conditional header to write the page only if
    #                                  the blob has not been modified since the specified date/time. If the blob has been modified,
    #                                  the Blob service returns status code 412 (Precondition Failed).
    # * +:if_match+                  - String. An ETag value. Specify an ETag value for this conditional header to write the page only if
    #                                  the blob's ETag value matches the value specified. If the values do not match,
    #                                  the Blob service returns status code 412 (Precondition Failed).
    # * +:if_none_match+             - String. An ETag value. Specify an ETag value for this conditional header to write the page only if
    #                                  the blob's ETag value does not match the value specified. If the values are identical,
    #                                  the Blob service returns status code 412 (Precondition Failed).
    # * +:timeout+                   - Integer. A timeout in seconds.
    # * +:request_id+                - String. Provides a client-generated, opaque value with a 1 KB character limit that is recorded
    #                                  in the analytics logs when storage analytics logging is enabled.
    # * +:lease_id+                  - String. Required if the blob has an active lease. To perform this operation on a blob with an active lease,
    #                                  specify the valid lease ID for this header.
    #
    # See http://msdn.microsoft.com/en-us/library/azure/ee691975.aspx
    #
    # Returns Blob
    def put_blob_pages(container, blob, start_range, end_range, content, options = {})
      query = { "comp" => "page" }
      StorageService.with_query query, "timeout", options[:timeout].to_s if options[:timeout]

      uri = blob_uri(container, blob, query)
      headers = StorageService.common_headers
      StorageService.with_header headers, "Content-MD5", options[:transactional_md5]
      StorageService.with_header headers, "x-ms-range", "bytes=#{start_range}-#{end_range}"
      StorageService.with_header headers, "x-ms-page-write", "update"

      # clear default content type
      StorageService.with_header headers, "Content-Type", ""
      headers["x-ms-lease-id"] = options[:lease_id] if options[:lease_id]

      # set optional headers
      unless options.empty?
        add_blob_conditional_headers options, headers
      end

      response = call(:put, uri, content, headers, options)

      result = Serialization.blob_from_headers(response.headers)
      result.name = blob

      result
    end

    # Public: Clears a range of pages from the blob.
    #
    # ==== Attributes
    #
    # * +container+                  - String. Name of container.
    # * +blob+                       - String. Name of blob.
    # * +start_range+                - Integer. Position of first byte of first page.
    # * +end_range+                  - Integer. Position of last byte of of last page.
    # * +options+                    - Hash. Optional parameters.
    #
    # ==== Options
    #
    # Accepted key/value pairs in options parameter are:
    # * +:timeout+                   - Integer. A timeout in seconds.
    # * +:request_id+                - String. Provides a client-generated, opaque value with a 1 KB character limit that is recorded
    #                                  in the analytics logs when storage analytics logging is enabled.
    # * +:if_modified_since+         - String. A DateTime value. Specify this conditional header to clear the page only if
    #                                  the blob has been modified since the specified date/time. If the blob has not been modified,
    #                                  the Blob service returns status code 412 (Precondition Failed).
    # * +:if_unmodified_since+       - String. A DateTime value. Specify this conditional header to clear the page only if
    #                                  the blob has not been modified since the specified date/time. If the blob has been modified,
    #                                  the Blob service returns status code 412 (Precondition Failed).
    # * +:if_match+                  - String. An ETag value. Specify an ETag value for this conditional header to clear the page only if
    #                                  the blob's ETag value matches the value specified. If the values do not match,
    #                                  the Blob service returns status code 412 (Precondition Failed).
    # * +:if_none_match+             - String. An ETag value. Specify an ETag value for this conditional header to clear the page only if
    #                                  the blob's ETag value does not match the value specified. If the values are identical,
    #                                  the Blob service returns status code 412 (Precondition Failed).
    #
    # See http://msdn.microsoft.com/en-us/library/azure/ee691975.aspx
    #
    # Returns Blob
    def clear_blob_pages(container, blob, start_range, end_range, options = {})
      query = { "comp" => "page" }
      StorageService.with_query query, "timeout", options[:timeout].to_s if options[:timeout]

      uri = blob_uri(container, blob, query)

      headers = StorageService.common_headers
      StorageService.with_header headers, "x-ms-range", "bytes=#{start_range}-#{end_range}"
      StorageService.with_header headers, "x-ms-page-write", "clear"

      # clear default content type
      StorageService.with_header headers, "Content-Type", ""

      # set optional headers
      unless options.empty?
        add_blob_conditional_headers options, headers
      end

      response = call(:put, uri, nil, headers, options)

      result = Serialization.blob_from_headers(response.headers)
      result.name = blob

      result
    end

    # Public: Returns a list of active page ranges for a page blob. Active page ranges are
    # those that have been populated with data.
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
    # * +:timeout+                   - Integer. A timeout in seconds.
    # * +:request_id+                - String. Provides a client-generated, opaque value with a 1 KB character limit that is recorded
    #                                  in the analytics logs when storage analytics logging is enabled.
    # * +:location_mode+             - LocationMode. Specifies the location mode used to decide 
    #                                  which location the request should be sent to.
    # * +:if_modified_since+         - String. A DateTime value. Specify this conditional header to list the pages only if
    #                                  the blob has been modified since the specified date/time. If the blob has not been modified,
    #                                  the Blob service returns status code 412 (Precondition Failed).
    # * +:if_unmodified_since+       - String. A DateTime value. Specify this conditional header to list the pages only if
    #                                  the blob has not been modified since the specified date/time. If the blob has been modified,
    #                                  the Blob service returns status code 412 (Precondition Failed).
    # * +:if_match+                  - String. An ETag value. Specify an ETag value for this conditional header to list the pages only if
    #                                  the blob's ETag value matches the value specified. If the values do not match,
    #                                  the Blob service returns status code 412 (Precondition Failed).
    # * +:if_none_match+             - String. An ETag value. Specify an ETag value for this conditional header to list the pages only if
    #                                  the blob's ETag value does not match the value specified. If the values are identical,
    #                                  the Blob service returns status code 412 (Precondition Failed).
    # * +:previous_snapshot+         - String. An opaque DateTime value that specifies that the response will contain only pages that
    #                                  were changed between target blob and previous snapshot. Changed pages include both updated and
    #                                  cleared pages. The target blob may be a snapshot, as long as the snapshot specified by this
    #                                  is the older of the two.
    # * +:lease_id+                  - String. If this header is specified, the operation will be performed only if both of the
    #                                  following conditions are met:
    #                                   - The blob's lease is currently active.
    #                                   - The lease ID specified in the request matches that of the blob.
    #                                  If this header is specified and both of these conditions are not met, the request will fail
    #                                  and the Get Blob operation will fail with status code 412 (Precondition Failed).
    #
    # See http://msdn.microsoft.com/en-us/library/azure/ee691973.aspx
    #
    # Returns a list of page ranges in the format [ [start, end], [start, end], ... ]
    #
    #   e.g. [ [0, 511], [512, 1024], ... ]
    #
    def list_page_blob_ranges(container, blob, options = {})
      query = { "comp" => "pagelist" }
      query.update("snapshot" => options[:snapshot]) if options[:snapshot]
      query.update("prevsnapshot" => options[:previous_snapshot]) if options[:previous_snapshot]
      StorageService.with_query query, "timeout", options[:timeout].to_s if options[:timeout]

      options[:request_location_mode] = RequestLocationMode::PRIMARY_OR_SECONDARY
      uri = blob_uri(container, blob, query, options)

      options[:start_range] = 0 if options[:end_range] && (not options[:start_range])

      headers = StorageService.common_headers
      StorageService.with_header headers, "x-ms-range", "bytes=#{options[:start_range]}-#{options[:end_range]}" if options[:start_range]
      add_blob_conditional_headers options, headers
      headers["x-ms-lease-id"] = options[:lease_id] if options[:lease_id]

      response = call(:get, uri, nil, headers, options)

      pagelist = Serialization.page_list_from_xml(response.body)
      pagelist
    end

    # Public: Resizes a page blob to the specified size.
    #
    # ==== Attributes
    #
    # * +container+                  - String. The container name.
    # * +blob+                       - String. The blob name.
    # * +size+                       - String. The blob size. Resizes a page blob to the specified size.
    #                                  If the specified value is less than the current size of the blob,
    #                                  then all pages above the specified value are cleared.
    # * +options+                    - Hash. Optional parameters.
    #
    # ==== Options
    #
    # Accepted key/value pairs in options parameter are:
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
    # See http://msdn.microsoft.com/en-us/library/azure/ee691966.aspx
    #
    # Returns nil on success.
    def resize_page_blob(container, blob, size, options = {})
      options = { content_length: size }.merge(options)
      set_blob_properties container, blob, options
    end

    # Public: Copies a snapshot of the source page blob to a destination page blob. The snapshot is copied such that only
    # the differential changes between the previously copied snapshot are transferred to the destination. The copied snapshots
    # are complete copies of the original snapshot and can be read or copied from as usual.The destination of an incremental copy
    # must either not exist, or must have been created with a previous incremental copy from the same source blob. Once created,
    # the destination blob is permanently associated with the source and may only be used for incremental copies. The Get Blob
    # Properties and List Blobs APIs indicate whether the blob is an incremental copy blob created in this way. Incremental
    # copy blobs may not be downloaded directly. The only supported operations are Get Blob Properties, Incremental Copy Blob,
    # and Delete Blob. The copied snapshots may be read and deleted as usual.
    #
    # ==== Attributes
    #
    # * +destination_container+       - String. The destination container name to copy to.
    # * +destination_blob+            - String. The destination blob name to copy to.
    # * +source_uri+                  - String. Specifies the URI of the source page blob snapshot.
    #                                   This value is a URL of up to 2 KB in length that specifies a page blob snapshot. The
    #                                   value should be URL-encoded as it would appear in a request URI. The source blob must
    #                                   either be public or must be authenticated via a shared access signature. Here is an
    #                                   example of a source blob URL:
    #                                     https://myaccount.blob.core.windows.net/mycontainer/myblob?snapshot=<DateTime>
    # * +options+                     - Hash. Optional parameters.
    #
    # ==== Options
    #
    # Accepted key/value pairs in options parameter are:
    # * +:metadata+                   - Hash. Custom metadata values to store with the copy. If this parameter is not
    #                                   specified, the operation will copy the source blob metadata to the destination
    #                                   blob. If this parameter is specified, the destination blob is created with the
    #                                   specified metadata, and metadata is not copied from the source blob.
    # * +:if_modified_since+          - String. A DateTime value. Specify this conditional header to copy the blob only if the
    #                                   destination blob has been modified since the specified date/time. If the destination blob
    #                                   has not been modified, the Blob service returns status code 412 (Precondition Failed).
    # * +:if_unmodified_since+        - String. A DateTime value. Specify this conditional header to copy the blob only if the
    #                                   destination blob has not been modified since the specified date/time. If the destination
    #                                   blob has been modified, the Blob service returns status code 412 (Precondition Failed).
    # * +:if_match+                   - String. An ETag value. Specify an ETag value for this conditional header to copy the blob
    #                                   only if the specified ETag value matches the ETag value for an existing destination blob.
    #                                   If the ETag for the destination blob does not match the ETag specified for If-Match,
    #                                   the Blob service returns status code 412 (Precondition Failed).
    # * +:if_none_match+              - String. An ETag value, or the wildcard character (*). Specify an ETag value for this
    #                                   conditional header to copy the blob only if the specified ETag value does not match the
    #                                   ETag value for the destination blob. Specify the wildcard character (*) to perform the
    #                                   operation only if the destination blob does not exist. If the specified condition isn't met,
    #                                   the Blob service returns status code 412 (Precondition Failed).
    # * +:timeout+                    - Integer. A timeout in seconds.
    # * +:request_id+                 - String. Provides a client-generated, opaque value with a 1 KB character limit that is recorded
    #                                   in the analytics logs when storage analytics logging is enabled.
    # * +:lease_id+                   - String. If this header is specified, the operation will be performed only if both of the
    #                                   following conditions are met:
    #                                     - The blob's lease is currently active.
    #                                     - The lease ID specified in the request matches that of the blob.
    #                                   If this header is specified and both of these conditions are not met, the request will fail
    #                                   and the Snapshot Blob operation will fail with status code 412 (Precondition Failed).
    #
    # See https://docs.microsoft.com/en-us/rest/api/storageservices/incremental-copy-blob
    #
    # Returns a tuple of (copy_id, copy_status).
    #
    # * +copy_id+                    - String. String identifier for this copy operation. Use with Get Blob Properties to check
    #                                  the status of this copy operation, or pass to Abort Copy Blob to abort a pending copy.
    # * +copy_status+                - String. State of the copy operation. This is always pending to indicate that the copy has
    #                                  started and is in progress.
    #
    def incremental_copy_blob(destination_container, destination_blob, source_uri, options = {})
      # query parameters
      query = { QueryStringConstants::COMP => QueryStringConstants::INCREMENTAL_COPY }
      StorageService.with_query query, "timeout", options[:timeout].to_s if options[:timeout]

      # URI
      uri = blob_uri(destination_container, destination_blob, query)

      # headers
      headers = StorageService.common_headers
      StorageService.with_header headers, "x-ms-copy-source", source_uri
      unless options.empty?
        add_blob_conditional_headers options, headers
        StorageService.add_metadata_to_headers options[:metadata], headers
        headers["x-ms-lease-id"] = options[:lease_id] if options[:lease_id]
      end

      response = call(:put, uri, nil, headers, options)
      return response.headers["x-ms-copy-id"], response.headers["x-ms-copy-status"]
    end

    # Public: Sets a page blob's sequence number.
    #
    # ==== Attributes
    #
    # * +container+                  - String. The container name.
    # * +blob+                       - String. The blob name.
    # * +action+                     - Symbol. Indicates how the service should modify the sequence
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
    # * +number+                     - Integer. Sets the blob's sequence number. The sequence number is a
    #                                  user-controlled property that you can use to track requests and manage concurrency
    #                                  issues. Required if the 'action' parameter is set to :max or :update.
    #                                  This property applies to page blobs only.
    #
    #                                  Use this together with the 'action' parameter to update the blob's sequence
    #                                  number, either to the specified value or to the higher of the values specified with
    #                                  the request or currently stored with the blob.
    #
    #                                  This header should not be specified if the 'action' parameter is set to :increment;
    #                                  in this case the service automatically increments the sequence number by one.
    #
    #                                  To set the sequence number to a value of your choosing, this property must be specified
    #                                  together with the 'action' parameter
    # * +options+                    - Hash. Optional parameters.
    #
    # ==== Options
    #
    # Accepted key/value pairs in options parameter are:
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
    # See http://msdn.microsoft.com/en-us/library/azure/ee691966.aspx
    #
    # Returns nil on success.
    def set_sequence_number(container, blob, action, number, options = {})
      options = { sequence_number_action: action, sequence_number: number }.merge(options)
      set_blob_properties container, blob, options
    end
  end
end
