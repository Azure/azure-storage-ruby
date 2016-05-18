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
require 'azure/core'
require 'azure/core/http/retry_policy'

module Azure::Storage::Core::Filter
  class ExponentialRetryPolicyFilter < RetryPolicyFilter
    def initialize(retry_count=nil, min_retry_interval=nil, max_retry_interval=nil)
      @retry_count = retry_count || ExponentialRetryPolicyFilter::DEFAULT_RETRY_COUNT
      @min_retry_interval = min_retry_interval || ExponentialRetryPolicyFilter::DEFAULT_MIN_RETRY_INTERVAL
      @max_retry_interval = max_retry_interval || ExponentialRetryPolicyFilter::DEFAULT_MAX_RETRY_INTERVAL
      
      super @retry_count, @min_retry_interval
    end
    
    attr_reader :min_retry_interval,
                :max_retry_interval
    
    DEFAULT_RETRY_COUNT = 3
    DEFAULT_MIN_RETRY_INTERVAL = 10
    DEFAULT_MAX_RETRY_INTERVAL = 90
    
    # Overrides the base class implementation of call to determine 
    # how the HTTP request should continue retrying
    #
    # retry_data - Hash. Stores stateful retry data
    #
    # The retry_data is a Hash which can be used to store
    # stateful data about the request execution context (such as an
    # incrementing counter, timestamp, etc). The retry_data object
    # will be the same instance throughout the lifetime of the request
    def apply_retry_policy(retry_data)
      # Adjust retry count
      retry_data[:count] = retry_data[:count] === nil ? 1 : retry_data[:count] + 1
      
      # Adjust retry interval
      increment_delta = (@max_retry_interval - @min_retry_interval).fdiv(2 ** (@retry_count - 1)) * (2 ** (retry_data[:count] - 1));
      retry_data[:interval] = retry_data[:interval] === nil ? @min_retry_interval : [@min_retry_interval + increment_delta, @max_retry_interval].min;
    end
  end
end