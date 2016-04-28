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
require 'cgi'
require 'azure/storage/core/auth/shared_key'

module Azure::Storage
  module Table
    module Auth
      class SharedKey < Core::Auth::SharedKey
        # The account name
        attr :account_name

        # Generate the string to sign.
        #
        # @param method   [Symbol]  The HTTP request method.
        # @param uri      [URI]     The URI of the request we're signing.
        # @param headers  [Hash]    The HTTP request headers.
        #
        # Returns a plain text string.
        def signable_string(method, uri, headers)
          [
              method.to_s.upcase,
              headers.fetch('Content-MD5', ''),
              headers.fetch('Content-Type', ''),
              headers.fetch('Date') { headers.fetch('x-ms-date') },
              canonicalized_resource(uri)
          ].join("\n")
        end

        # Calculate the Canonicalized Resource string for a request.
        #
        # @param uri [URI] The request's URI.
        #
        # @return  [String] with the canonicalized resource.
        def canonicalized_resource(uri)
          resource = "/#{account_name}#{uri.path}"

          comp = CGI.parse(uri.query.to_s).fetch('comp', nil)
          resource = [resource, 'comp=' + comp[0]].join('?') if comp

          resource
        end

      end
    end
  end
end
