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
require "azure/storage/queue/version"

module Azure::Storage::Queue
  module Default
    # Default REST service (STG) version number
    STG_VERSION = "2017-11-09"

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

    # Default User Agent header string
    USER_AGENT = "Azure-Storage/#{Azure::Storage::Queue::Version.to_uas}-#{Azure::Storage::Common::Version.to_uas} (Ruby #{RUBY_VERSION}-p#{RUBY_PATCHLEVEL}; #{Azure::Storage::Common::Default.os})".freeze
  end

  # Defines constants for use with queue storage.
  module QueueConstants
    # XML element for QueueMessage.
    QUEUE_MESSAGE_ELEMENT = "QueueMessage"

    # XML element for MessageText.
    MESSAGE_TEXT_ELEMENT = "MessageText"
  end

  module QueueErrorCodeStrings
    QUEUE_NOT_FOUND = "QueueNotFound"
    QUEUE_DISABLED = "QueueDisabled"
    QUEUE_ALREADY_EXISTS = "QueueAlreadyExists"
    QUEUE_NOT_EMPTY = "QueueNotEmpty"
    QUEUE_BEING_DELETED = "QueueBeingDeleted"
    POP_RECEIPT_MISMATCH = "PopReceiptMismatch"
    INVALID_PARAMETER = "InvalidParameter"
    MESSAGE_NOT_FOUND = "MessageNotFound"
    MESSAGE_TOO_LARGE = "MessageTooLarge"
    INVALID_MARKER = "InvalidMarker"
  end
end
