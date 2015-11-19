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
require 'azure/storage/core/http/http_error'

module Azure
  module Core
    module Http
      # A small proxy to clean up the API of Net::HTTPResponse.
      class HttpResponse

        # Public: Initialize a new response.
        #
        # http_response - A Net::HTTPResponse.
        def initialize(http_response, uri='')
          @http_response = http_response
          @uri = uri
        end

        attr_accessor :uri

        # Public: Get the response body.
        #
        # Returns a String.
        def body
          @http_response.body
        end

        # Public: Get the response status code.
        #
        # Returns a Fixnum.
        def status_code
          @http_response.status
        end

        # Public: Check if this response was successful. A request is considered
        # successful if the response is in the 200 - 399 range.
        #
        # Returns nil|false.
        def success?
          @http_response.success?
        end

        # Public: Get all the response headers as a Hash.
        #
        # Returns a Hash.
        def headers
          @http_response.headers
        end

        # Public: Get an error that wraps this HTTP response, as long as this
        # response was unsuccessful. This method will return nil if the
        # response was successful.
        #
        # Returns an Azure::Core::Http::HTTPError.
        def exception
          HTTPError.new(self) unless success?
        end
        
        alias_method :error, :exception

        # TODO: This needs to be deleted and HttpError needs to be refactored to not rely on HttpResponse.
        # The dependency on knowing the internal structure of HttpResponse breaks good design principles.
        # The only reason this class exists is because the HttpError parses the HttpResponse to produce an error msg.
        class MockResponse
          def initialize(code, body, headers)
            @status = code
            @body = body
            @headers = headers
            @headers.each { |k,v|
              @headers[k] = [v] unless v.respond_to? first
            }
          end
          attr_accessor :status
          attr_accessor :body
          attr_accessor :headers

          def to_hash
            @headers
          end
        end
      end
    end
  end
end
