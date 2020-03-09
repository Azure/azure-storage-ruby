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

require "rbconfig"

module Azure::Storage::Blob
  module Default
    # Default REST service (STG) version number
    STG_VERSION = "2018-11-09"

    # The number of default concurrent requests for parallel operation.
    DEFAULT_PARALLEL_OPERATION_THREAD_COUNT = 1

    # Constant representing a kilobyte (Non-SI version).
    KB = 1024
    # Constant representing a megabyte (Non-SI version).
    MB = 1024 * 1024
    # Constant representing a gigabyte (Non-SI version).
    GB = 1024 * 1024 * 1024

    # Specifies HTTP.
    HTTP = "http"
    # Specifies HTTPS.
    HTTPS = "https"
    # Default HTTP port.
    DEFAULT_HTTP_PORT = 80
    # Default HTTPS port.
    DEFAULT_HTTPS_PORT = 443

    # Marker for atom metadata.
    XML_METADATA_MARKER = "$"
    # Marker for atom value.
    XML_VALUE_MARKER = "_"

    # Default value for Content-Type if request has body.
    CONTENT_TYPE_VALUE = "application/octet-stream"

    # Default User Agent header string
    USER_AGENT = "Azure-Storage/#{Azure::Storage::Blob::Version.to_uas}-#{Azure::Storage::Common::Version.to_uas} (Ruby #{RUBY_VERSION}-p#{RUBY_PATCHLEVEL}; #{Azure::Storage::Common::Default.os})".freeze
  end

  # Defines constants for use with blob operations.
  module BlobConstants
    # XML element for the latest.
    LATEST_ELEMENT = "Latest"

    # XML element for uncommitted blocks.
    UNCOMMITTED_ELEMENT = "Uncommitted"

    # XML element for a block list.
    BLOCK_LIST_ELEMENT = "BlockList"

    # XML element for committed blocks.
    COMMITTED_ELEMENT = "Committed"

    # The default write page size, in bytes, used by blob streams.
    DEFAULT_WRITE_PAGE_SIZE_IN_BYTES = 4 * 1024 * 1024

    # The minimum write page size, in bytes, used by blob streams.
    MIN_WRITE_PAGE_SIZE_IN_BYTES = 2 * 1024 * 1024

    # The default maximum size, in bytes, of a blob before it must be separated into blocks.
    DEFAULT_SINGLE_BLOB_PUT_THRESHOLD_IN_BYTES = 128 * 1024 * 1024

    # The default write block size, in bytes, used by blob streams.
    DEFAULT_WRITE_BLOCK_SIZE_IN_BYTES = 4 * 1024 * 1024

    # The maximum size of a single block.
    MAX_BLOCK_SIZE = 100 * 1024 * 1024

    # The maximum count of blocks for a block blob
    MAX_BLOCK_COUNT = 50000

    # The maximum size of block blob
    MAX_BLOCK_BLOB_SIZE = 50000 * 100 * 1024 * 1024

    # The maximum size of block blob
    MAX_APPEND_BLOB_SIZE = 1024 * 1024 * 1024 * 1024

    # The maximum size, in bytes, of a blob before it must be separated into blocks.
    MAX_SINGLE_UPLOAD_BLOB_SIZE_IN_BYTES = 256 * 1024 * 1024

    # The maximum range get size when requesting for a contentMD5
    MAX_RANGE_GET_SIZE_WITH_MD5 = 4 * 1024 * 1024

    # The maximum page range size for a page update operation.
    MAX_UPDATE_PAGE_SIZE = 4 * 1024 * 1024

    # The maximum buffer size for writing a stream buffer.
    MAX_QUEUED_WRITE_DISK_BUFFER_SIZE = 64 * 1024 * 1024

    # Max size for single get page range. The max value should be 150MB
    # http://blogs.msdn.com/b/windowsazurestorage/archive/2012/03/26/getting-the-page-ranges-of-a-large-page-blob-in-segments.aspx
    MAX_SINGLE_GET_PAGE_RANGE_SIZE = 37 * 4 * 1024 * 1024

    # The size of a page, in bytes, in a page blob.
    PAGE_SIZE = 512

    # The maximum validity of user delegation SAS (7 days from the current time).
    MAX_USER_DELEGATION_KEY_SECONDS = 60 * 60 * 24 * 7

    # Resource types.
    module ResourceTypes
      CONTAINER = "c"
      BLOB = "b"
    end

    # List blob types.
    module ListBlobTypes
      Blob = "b"
      Directory = "d"
    end

    # Put page write options
    module PageWriteOptions
      UPDATE = "update"
      CLEAR = "clear"
    end

    # Blob types
    module BlobTypes
      BLOCK = "BlockBlob"
      PAGE = "PageBlob"
      APPEND = "AppendBlob"
    end

    # Blob lease constants
    module LeaseOperation
      ACQUIRE = "acquire"
      RENEW = "renew"
      CHANGE = "change"
      RELEASE = "release"
      BREAK = "break"
    end
  end

  module BlobErrorCodeStrings
    INVALID_BLOCK_ID = "InvalidBlockId"
    BLOB_NOT_FOUND = "BlobNotFound"
    BLOB_ALREADY_EXISTS = "BlobAlreadyExists"
    CONTAINER_ALREADY_EXISTS = "ContainerAlreadyExists"
    CONTAINER_NOT_FOUND = "ContainerNotFound"
    INVALID_BLOB_OR_BLOCK = "InvalidBlobOrBlock"
    INVALID_BLOCK_LIST = "InvalidBlockList"
    MAX_BLOB_SIZE_CONDITION_NOT_MET = "MaxBlobSizeConditionNotMet"
    APPEND_POSITION_CONDITION_NOT_MET = "AppendPositionConditionNotMet"
  end
end
