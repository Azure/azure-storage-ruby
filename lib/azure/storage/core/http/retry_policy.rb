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
require "azure/storage/core/http/http_filter"

module Azure
  module Core
    module Http
    
      # A HttpFilter implementation that handles retrying based on a 
      # specific policy when HTTP layer errors occur
      class RetryPolicy < HttpFilter
    
        def initialize(&block)
          @block = block
        end

        attr_accessor :retry_data

        # Overrides the base class implementation of call to implement 
        # a retry loop that uses should_retry? to determine when to 
        # break the loop
        # 
        # req   - HttpRequest. The HTTP request
        # _next - HttpFilter. The next filter in the pipeline
        def call(req, _next)
          retry_data = {}
          response = nil
          begin
            response = _next.call
          rescue
            retry_data[:error] = $!
          end while should_retry?(response, retry_data)
          if retry_data.has_key?(:error)
            raise retry_data[:error]
          else
            response
          end
        end

        # Determines if the HTTP request should continue retrying
        # 
        # response - HttpResponse. The response from the active request
        # retry_data - Hash. Stores stateful retry data
        #
        # The retry_data is a Hash which can be used to store 
        # stateful data about the request execution context (such as an 
        # incrementing counter, timestamp, etc). The retry_data object 
        # will be the same instance throughout the lifetime of the request.
        #
        # If an inline block was passed to the constructor, that block 
        # will be used here and should return true to retry the job, or
        # false to stop exit. If an inline block was not passed to the 
        # constructor the method returns false.
        #
        # Alternatively, a subclass could override this method.
        def should_retry?(response, retry_data)
          @block ? @block.call(response, retry_data) : false
        end
      end
    end
  end
end