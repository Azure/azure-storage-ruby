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
require "azure/storage/file/version"

module Azure::Storage::File
  module Default
    # Default REST service (STG) version number
    STG_VERSION = "2016-05-31"

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
    USER_AGENT = "Azure-Storage/#{Azure::Storage::File::Version.to_uas}-#{Azure::Storage::Common::Version.to_uas} (Ruby #{RUBY_VERSION}-p#{RUBY_PATCHLEVEL}; #{Azure::Storage::Common::Default.os})".freeze
  end

  # Defines constants for use with file operations.
  module FileConstants
    # The default write size, in bytes, used by file streams.
    DEFAULT_WRITE_SIZE_IN_BYTES = 4 * 1024 * 1024

    # The maximum range size when requesting for a contentMD5.
    MAX_RANGE_GET_SIZE_WITH_MD5 = 4 * 1024 * 1024

    # The maximum range size for a file update operation.
    MAX_UPDATE_FILE_SIZE = 4 * 1024 * 1024

    # The default minimum size, in bytes, of a file when it must be separated into ranges.
    DEFAULT_SINGLE_FILE_GET_THRESHOLD_IN_BYTES = 32 * 1024 * 1024

    # The minimum write file size, in bytes, used by file streams.
    MIN_WRITE_FILE_SIZE_IN_BYTES = 2 * 1024 * 1024

    # Put range write options
    module RangeWriteOptions
      UPDATE = "update"
      CLEAR = "clear"
    end

    # Resource types.
    module ResourceTypes
      SHARE = "s"
      FILE = "f"
    end
  end

  module FileErrorCodeStrings
    SHARE_ALREADY_EXISTS = "ShareAlreadyExists"
    SHARE_NOT_FOUND = "ShareNotFound"
    FILE_NOT_FOUND = "FileNotFound"
  end
end
