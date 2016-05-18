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
require 'azure/storage/core/auth/shared_key'

describe Azure::Storage::Auth::SharedKey do
  subject { Azure::Storage::Auth::SharedKey.new 'account-name', 'YWNjZXNzLWtleQ==' }
  
  let(:verb) { 'POST' }
  let(:uri) { URI.parse 'http://dummy.uri/resource' }
  let(:headers) do
    {
      'Content-Encoding' => 'foo',
      'Content-Language' => 'foo',
      'Content-Length' => 'foo',
      'Content-MD5' => 'foo',
      'Content-Type' => 'foo',
      'Date' => 'foo',
      'If-Modified-Since' => 'foo',
      'If-Match' => 'foo',
      'If-None-Match' => 'foo',
      'If-Unmodified-Since' => 'foo',
      'Range' => 'foo',
      'x-ms-ImATeapot' => 'teapot',
      'x-ms-ShortAndStout' => 'True'
    }
  end

  describe 'sign' do
    it 'creates a signature from the provided HTTP method, uri, and a specific set of standard headers' do
      subject.sign(verb, uri, headers).must_equal 'account-name:vcdxlDVoE1QvJerkg0ci3Wlnj2Qq8yzlsrkRf5dEU/I='
    end
  end
  
  describe 'canonicalized_headers' do
    it 'creates a canonicalized header string' do
      subject.canonicalized_headers(headers).must_equal "x-ms-imateapot:teapot\nx-ms-shortandstout:True"
    end
  end

  describe 'canonicalized_resource' do
    it 'creates a canonicalized resource string' do
      subject.canonicalized_resource(uri).must_equal '/account-name/resource'
    end
  end
end
