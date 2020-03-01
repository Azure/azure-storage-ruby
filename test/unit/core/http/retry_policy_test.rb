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
require "azure/core/http/http_request"
require "azure/storage/common"

describe Azure::Core::Http::RetryPolicy do
  it "uses blocks as retry logic" do
    retry_policy = Azure::Core::Http::RetryPolicy.new do |a, b| true end
    _(retry_policy.should_retry?(nil, nil)).must_equal true
  end

  it "uses linear retry policy" do
    retry_count = retry_interval = 1
    retry_policy = Azure::Storage::Common::Core::Filter::LinearRetryPolicyFilter.new retry_count, retry_interval
    _(retry_policy.should_retry?(nil, error: "SocketError: Hostname not known")).must_equal true
  end

  it "uses exponential retry policy" do
    retry_count = retry_interval = 1
    retry_policy = Azure::Storage::Common::Core::Filter::ExponentialRetryPolicyFilter.new retry_count, retry_interval
    _(retry_policy.should_retry?(nil, error: "Errno::EPROTONOSUPPORT")).must_equal false
  end

  describe "RetryPolicy retries with a new URL" do
    let(:retry_count) { 1 } 
    let(:retry_interval) { 1 }

    subject { Azure::Storage::Common::Core::Filter::LinearRetryPolicyFilter.new retry_count, retry_interval }

    let(:verb) { :put }
    let(:primary_uri) { URI.parse "http://primary.com" }
    let(:secondary_uri) { URI.parse "http://secondary.com" }
    let(:request) { Azure::Core::Http::HttpRequest.new verb, primary_uri, {} }
    let(:response) { Azure::Core::Http::HttpResponse.new nil, primary_uri }
    let(:retry_data) { { request_options: {} } }

    before {
      request.stubs(:call).returns(response)
      response.stubs(:success?).returns(true)
      response.stubs(:status_code).returns(500)
    }

    it "retries with a new URL: PRIMARY_THEN_SECONDARY" do
      retry_data[:request_options] =
        {
          primary_uri: primary_uri,
          secondary_uri: secondary_uri,
          location_mode: Azure::Storage::Common::LocationMode::PRIMARY_THEN_SECONDARY,
          request_location_mode: Azure::Storage::Common::RequestLocationMode::PRIMARY_OR_SECONDARY
        }
      subject.retry_data = retry_data
      subject.call request, request
      _(request.uri).must_equal secondary_uri
    end

    it "retries with a new URL: SECONDARY_THEN_PRIMARY" do
      retry_data[:request_options] =
        {
          primary_uri: primary_uri,
          secondary_uri: secondary_uri,
          location_mode: Azure::Storage::Common::LocationMode::SECONDARY_THEN_PRIMARY,
          request_location_mode: Azure::Storage::Common::RequestLocationMode::PRIMARY_OR_SECONDARY
        }
      subject.retry_data = retry_data
      subject.call request, request
      _(request.uri).must_equal primary_uri
    end

    it "retries with a new URL: PRIMARY_ONLY" do
      retry_data[:request_options] =
        {
          primary_uri: primary_uri,
          secondary_uri: secondary_uri,
          location_mode: Azure::Storage::Common::LocationMode::PRIMARY_ONLY,
          request_location_mode: Azure::Storage::Common::RequestLocationMode::PRIMARY_OR_SECONDARY
        }
      subject.retry_data = retry_data
      subject.call request, request
      _(request.uri).must_equal primary_uri
    end

    it "retries with a new URL: SECONDARY_ONLY" do
      retry_data[:request_options] =
        {
          primary_uri: primary_uri,
          secondary_uri: secondary_uri,
          location_mode: Azure::Storage::Common::LocationMode::SECONDARY_ONLY,
          request_location_mode: Azure::Storage::Common::RequestLocationMode::PRIMARY_OR_SECONDARY
        }
      subject.retry_data = retry_data
      subject.call request, request
      _(request.uri).must_equal secondary_uri
    end

    it "retries with a new URL: PRIMARY_THEN_SECONDARY, API: PRIMARY_ONLY" do
      retry_data[:request_options] =
        {
          primary_uri: primary_uri,
          secondary_uri: secondary_uri,
          location_mode: Azure::Storage::Common::LocationMode::PRIMARY_THEN_SECONDARY,
          request_location_mode: Azure::Storage::Common::RequestLocationMode::PRIMARY_ONLY
        }
      subject.retry_data = retry_data
      subject.call request, request
      _(request.uri).must_equal primary_uri
    end

    it "retries with a new URL: SECONDARY_THEN_PRIMARY, API: SECONDARY_ONLY" do
      retry_data[:request_options] =
        {
          primary_uri: primary_uri,
          secondary_uri: secondary_uri,
          location_mode: Azure::Storage::Common::LocationMode::SECONDARY_THEN_PRIMARY,
          request_location_mode: Azure::Storage::Common::RequestLocationMode::SECONDARY_ONLY
        }
      subject.retry_data = retry_data
      subject.call request, request
      _(request.uri).must_equal secondary_uri
    end
  end
end
