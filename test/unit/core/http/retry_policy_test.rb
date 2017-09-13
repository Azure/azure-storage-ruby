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
require "azure/core/http/retry_policy"
require "azure/storage/core/filter/linear_retry_filter"
require "azure/storage/core/filter/exponential_retry_filter"

describe Azure::Core::Http::RetryPolicy do
  it "uses blocks as retry logic" do
    retry_policy = Azure::Core::Http::RetryPolicy.new do |a, b| true end
    retry_policy.should_retry?(nil, nil).must_equal true
  end

  it "uses linear retry policy" do
    retry_count = retry_interval = 1
    retry_policy = Azure::Storage::Core::Filter::LinearRetryPolicyFilter.new retry_count, retry_interval
    retry_policy.should_retry?(nil, error: "SocketError: Hostname not known").must_equal true
  end

  it "uses exponential retry policy" do
    retry_count = retry_interval = 1
    retry_policy = Azure::Storage::Core::Filter::ExponentialRetryPolicyFilter.new retry_count, retry_interval
    retry_policy.should_retry?(nil, error: "Errno::EPROTONOSUPPORT").must_equal false
  end
end
