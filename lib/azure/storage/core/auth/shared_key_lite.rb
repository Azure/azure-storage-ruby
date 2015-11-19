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
require "azure/storage/core/auth/shared_key"

module Azure::Storage
  module Auth
    class SharedKeyLite < SharedKey
      # The name of the strategy.
      #
      # @return [String]
      def name
        'SharedKeyLite'
      end

      # Generate the string to sign.
      #
      # @param method     [Symbol] The HTTP request method.
      # @param uri        [URI] The URI of the request we're signing.
      # @param headers    [Hash] A Hash of HTTP request headers.
      #
      # Returns a plain text string.
      def signable_string(method, uri, headers)
        [
          method.to_s.upcase,
          headers.fetch('Content-MD5', ''),
          headers.fetch('Content-Type', ''),
          headers.fetch('Date') { raise IndexError, 'Headers must include Date' },
          canonicalized_headers(headers),
          canonicalized_resource(uri)
        ].join("\n")
      end
    end
  end
end
