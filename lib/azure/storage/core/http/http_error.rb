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
require 'azure/storage/core/error'

module Azure
  module Core
    module Http
      # Public: Class for handling all HTTP response errors
      class HTTPError < Azure::Core::Error
        
        attr :uri

        # Public: The HTTP status code of this error
        #
        # Returns a Fixnum
        attr :status_code

        # Public: The type of error
        #
        # http://msdn.microsoft.com/en-us/library/azure/dd179357
        #
        # Returns a String
        attr :type

        # Public: Description of the error
        #
        # Returns a String
        attr :description

        # Public: Detail of the error
        #
        # Returns a String
        attr :detail

        # Public: Initialize an error
        #
        # http_response - An Azure::Core::HttpResponse
        def initialize(http_response)
          @http_response = http_response
          @uri = http_response.uri
          @status_code = http_response.status_code
          parse_response
          super("#{type} (#{status_code}): #{description}")
        end

        # Extract the relevant information from the response's body. If the response
        # body is not an XML, we return an 'Unknown' error with the entire body as
        # the description
        #
        # Returns nothing
        def parse_response
          if @http_response.body && @http_response.body.include?('<')

            document = Nokogiri.Slop(@http_response.body)

            @type = document.css('code').first.text if document.css('code').any?
            @type = document.css('Code').first.text if document.css('Code').any?
            @description = document.css('message').first.text if document.css('message').any?
            @description = document.css('Message').first.text if document.css('Message').any?

            # service bus uses detail instead of message
            @detail = document.css('detail').first.text if document.css('detail').any?
            @detail = document.css('Detail').first.text if document.css('Detail').any?
          else
            @type = 'Unknown'
            if @http_response.body
              @description = "#{@http_response.body.strip}"
            end
          end
        end
      end
    end
  end
end
