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
require "test_helper"
require "azure/storage/blob"
require "azure/storage/file"
require "azure/storage/table"
require "azure/storage/queue"

def SERVICE_CREATE_OPTIONS()
  { storage_account_name: ENV.fetch("AZURE_STORAGE_ACCOUNT"), storage_access_key: ENV.fetch("AZURE_STORAGE_ACCESS_KEY") }
end

def is_boolean(value)
  (value == true || value == false) == true
end

require "azure/core/http/http_filter"

module Azure::Storage
  class DuplicateRequestFilter < Azure::Core::Http::HttpFilter
    def initialize(callable = nil)
      @callable = callable
    end
    def call(req, _next)
      begin
        r = _next.call
      rescue Azure::Core::Http::HTTPError
      end
      @callable.call(req, r) if @callable
      r = _next.call
    end
  end
end
