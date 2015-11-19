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
require 'test_helper'
require 'azure/storage/core/http/http_error'

describe Azure::Core::Http::HTTPError do
  let :http_response do
    stub(body: Fixtures[:http_error], status_code: 409, uri: 'http://dummy.uri', headers: {})
  end

  subject do
    Azure::Core::Http::HTTPError.new(http_response)
  end

  it 'is an instance of Azure::Core::Error' do
    subject.must_be_kind_of Azure::Core::Error
  end

  it 'lets us see the original uri' do
    subject.uri.must_equal 'http://dummy.uri'
  end

  it "lets us see the errors'status code" do
    subject.status_code.must_equal 409
  end

  it "lets us see the error's type" do
    subject.type.must_equal 'TableAlreadyExists'
  end

  it "lets us see the error's description" do
    subject.description.must_equal 'The table specified already exists.'
  end

  it 'generates an error message that wraps both the type and description' do
    subject.message.must_equal 'TableAlreadyExists (409): The table specified already exists.'
  end

  describe 'with invalid http_response body' do
    let :http_response do
      stub(:body => "\r\nInvalid request\r\n", :status_code => 409, :uri => 'http://dummy.uri', headers: {})
    end

    it 'sets the type to unknown if the response body is not an XML' do
      subject.type.must_equal 'Unknown'
      subject.description.must_equal 'Invalid request'
    end
  end
end
