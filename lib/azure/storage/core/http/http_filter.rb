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
module Azure
  module Core
    module Http
      # A filter which can modify the HTTP pipeline both before and 
      # after requests/responses. Multiple filters can be nested in a 
      # "Russian Doll" model to create a compound HTTP pipeline
      class HttpFilter
    
        # Initialize a HttpFilter 
        #
        # &block - An inline block which implements the filter. 
        # 
        # The inline block should take parameters |request, _next| where 
        # request is a HttpRequest and _next is an object that implements 
        # a method .call which returns an HttpResponse. The block passed 
        # to the constructor should also return HttpResponse, either as 
        # the result of calling _next.call or by customized logic. 
        #   
        def initialize(&block)
          @block = block
        end
        
        # Executes the filter
        #
        # request - HttpRequest. The request
        # _next   - An object that implements .call (no params)
        #
        # NOTE: _next is a either a subsequent HttpFilter wrapped in a 
        # closure, or the HttpRequest object's call method. Either way, 
        # it must have it's .call method executed within each filter to
        #  complete the pipeline. _next.call should return an HttpResponse
        # and so should this Filter.
        def call(request, _next)
          @block ? @block.call(request, _next) : _next.call
        end
      end
    end
  end
end