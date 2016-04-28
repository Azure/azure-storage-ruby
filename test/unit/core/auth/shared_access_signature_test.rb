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
require 'azure/storage/core/auth/shared_access_signature'
require 'base64'
require 'uri'

describe Azure::Storage::Auth::SharedAccessSignature do
  let(:path) { 'example/path' }
  let(:service_type) { 'servicetype' }
  let(:options) {
    {
      permissions:         'rwd',
      expiry:              '2020-12-11',
      resource:            'b',
      content_disposition: 'inline, filename=nyan.cat'
    }
  }
  let(:access_account_name) { 'account-name' }
  let(:access_key_base64) { Base64.strict_encode64('access-key') }

  subject { Azure::Storage::Auth::SharedAccessSignature.new(access_account_name, access_key_base64) }

  describe '#signable_string' do
    it 'constructs a string in the required format' do
      subject.signable_string(service_type, path, options).must_equal(
        "rwd\n\n#{Time.parse("2020-12-11").utc.iso8601}\n/servicetype/account-name/example/path\n\n#{Azure::Storage::Default::STG_VERSION}\n\ninline, filename=nyan.cat\n\n\n"
      )
    end
  end

  describe '#canonicalized_resource' do
    it 'prefixes and concatenates account name and resource path with forward slashes' do
      subject.canonicalized_resource(service_type, path).must_equal '/servicetype/account-name/example/path'
    end
  end

  describe '#signed_uri' do
    let(:uri) { URI(subject.signed_uri(URI(path), options)) }
    let(:query_hash) { Hash[URI.decode_www_form(uri.query)] }

    it 'maps options to the abbreviated API versions' do
      query_hash['sp'].must_equal 'rwd'
      query_hash['se'].must_equal Time.parse("2020-12-11").utc.iso8601
      query_hash['sr'].must_equal 'b'
      query_hash['rscd'].must_equal 'inline, filename=nyan.cat'
    end

  end
end
