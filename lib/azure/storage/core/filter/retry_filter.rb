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
  class RetryPolicyFilter < Azure::Core::Http::RetryPolicy
    def initialize(retry_count=nil, retry_interval=nil)
      @retry_count = retry_count
      @retry_interval = retry_interval
      
      super &:should_retry?
    end
    
    attr_reader :retry_count,
                :retry_interval
                
    # Overrides the base class implementation of call to determine 
    # whether to retry the operation
    #
    # response - HttpResponse. The response from the active request
    # retry_data - Hash. Stores stateful retry data
    def should_retry?(response, retry_data)
      # Applies the logic when there is subclass overrides it
      apply_retry_policy retry_data

      # Checks the result and count limit
      if retry_data[:retryable].nil?
        retry_data[:retryable] = true
      else
        retry_data[:retryable] &&= retry_data[:count] <= @retry_count
      end
      return false unless retry_data[:retryable]

      # Checks whether there is a local error
      # Cannot retry immediately when it returns true, as it need check other errors
      should_retry_on_local_error? retry_data
      return false unless should_retry_on_error? response, retry_data
      
      adjust_retry_parameter retry_data
    end
    
    # Apply the retry policy to determine how the HTTP request should continue retrying
    #
    # retry_data - Hash. Stores stateful retry data
    #
    # The retry_data is a Hash which can be used to store
    # stateful data about the request execution context (such as an
    # incrementing counter, timestamp, etc). The retry_data object
    # will be the same instance throughout the lifetime of the request
    #
    # Alternatively, a subclass could override this method.
    def apply_retry_policy(retry_data)
    end
    
    # Determines if the HTTP request should continue retrying
    #
    # retry_data - Hash. Stores stateful retry data
    #
    # The retry_data is a Hash which can be used to store
    # stateful data about the request execution context (such as an
    # incrementing counter, timestamp, etc). The retry_data object
    # will be the same instance throughout the lifetime of the request.
    def should_retry_on_local_error?(retry_data)
      unless retry_data[:error]
        retry_data[:retryable] = true;
        return true
      end

      error_message = retry_data[:error].inspect
      
      if error_message.include?('SocketError: Hostname not known')
        # Retry on local DNS resolving
        # When uses resolv-replace.rb to replace the libc resolver 
        # Reference: 
        #  https://makandracards.com/ninjaconcept/30815-fixing-socketerror-getaddrinfo-name-or-service-not-known-with-ruby-s-resolv-replace-rb 
        #  http://www.subelsky.com/2014/05/fixing-socketerror-getaddrinfo-name-or.html 
        retry_data[:retryable] = true;
      elsif error_message.include?('getaddrinfo: Name or service not known')
        # When uses the default resolver 
        retry_data[:retryable] = true;
      elsif error_message.downcase.include?('timeout')
        retry_data[:retryable] = true;
      elsif error_message.include?('Errno::ECONNRESET')
        retry_data[:retryable] = true;
      elsif error_message.include?('Errno::EACCES')
        retry_data[:retryable] = false;
      elsif error_message.include?('NOSUPPORT')
        retry_data[:retryable] = false;
      end
      
      retry_data[:retryable]
    end
    
    # Determines if the HTTP request should continue retrying
    #
    # response - Azure::Core::Http::HttpResponse. The response from the active request
    # retry_data - Hash. Stores stateful retry data
    #
    # The retry_data is a Hash which can be used to store
    # stateful data about the request execution context (such as an
    # incrementing counter, timestamp, etc). The retry_data object
    # will be the same instance throughout the lifetime of the request.
    def should_retry_on_error?(response, retry_data)
      response = response || retry_data[:error].http_response if retry_data[:error] && retry_data[:error].respond_to?('http_response')
      unless response
        retry_data[:retryable] = false unless retry_data[:error]
        return retry_data[:retryable]
      end

      # If a request sent to the secondary location fails with 404 (Not Found), it is possible
      # that the resource replication is not finished yet. So, in case of 404 only in the secondary
      # location, the failure should still be retryable.
      secondary_not_found = (retry_data[:current_location] === Azure::Storage::RequestLocationMode::SECONDARY_ONLY) && response.status_code === 404;

      if secondary_not_found
        retry_data[:status_code] = 500
      else
        if (response.status_code)
          retry_data[:status_code] = response.status_code
        else
          retry_data[:status_code] = nil
        end
      end
      
      if (retry_data[:status_code] < 400)
        retry_data[:retryable] = false;
        return false;
      # Non-timeout Cases
      elsif (retry_data[:status_code] != 408)
        # Always no retry on "not implemented" and "version not supported"
        if (retry_data[:status_code] == 501 || retry_data[:status_code] == 505)
          retry_data[:retryable] = false;
          return false;
        end

        # When absorb_conditional_errors_on_retry is set (for append blob)
        if (retry_data[:request_options] && retry_data[:request_options][:absorb_conditional_errors_on_retry])
          if (retry_data[:status_code] == 412)
            # When appending block with precondition failure and their was a server error before, we ignore the error.
            if (retry_data[:last_server_error])
              retry_data[:error] = nil;
              retry_data[:retryable] = true;
            else
              retry_data[:retryable] = false;
            end
          elsif (retry_data[:retryable] && retry_data[:status_code] >= 500 && retry_data[:status_code] < 600)
            # Retry on the server error
            retry_data[:retryable] = true;
            retry_data[:last_server_error] = true;
          end
        elsif (retry_data[:status_code] < 500)
          # No retry on the client error
          retry_data[:retryable] = false;
        end
      end
      retry_data[:retryable]
    end
    
    # Adjust the retry parameter
    #
    # retry_data - Hash. Stores stateful retry data
    def adjust_retry_parameter(retry_data)
      # TODO: Adjust the retry parameter according to the location and last attempt time 
      sleep retry_data[:interval] if retry_data[:retryable]
      retry_data[:retryable]
    end
    
  end
end
