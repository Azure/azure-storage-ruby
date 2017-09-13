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
require "integration/test_helper"
require "azure/storage/blob/blob_service"
require "azure/storage/service/signed_identifier"

describe Azure::Storage::Blob::BlobService do
  subject { Azure::Storage::Blob::BlobService.new }
  after { ContainerNameHelper.clean }

  describe "#set/get_container_acl" do
    let(:container_name) { ContainerNameHelper.name }
    let(:public_access_level) { :container.to_s }
    let(:identifiers) {
      identifier = Azure::Storage::Service::SignedIdentifier.new
      identifier.id = "MTIzNDU2Nzg5MDEyMzQ1Njc4OTAxMjM0NTY3ODkwMTI="
      identifier.access_policy.start = "2009-09-28T08:49:37.0000000Z"
      identifier.access_policy.expiry = "2009-09-29T08:49:37.0000000Z"
      identifier.access_policy.permission = "rwd"
      [identifier]
    }
    before {
      subject.create_container container_name
    }

    it "sets and gets the ACL for the container" do
      container, acl = subject.set_container_acl container_name, public_access_level, signed_identifiers: identifiers
      container.wont_be_nil
      container.name.must_equal container_name
      container.public_access_level.must_equal public_access_level.to_s
      acl.length.must_equal identifiers.length
      acl.first.id.must_equal identifiers.first.id
      acl.first.access_policy.start.must_equal identifiers.first.access_policy.start
      acl.first.access_policy.expiry.must_equal identifiers.first.access_policy.expiry
      acl.first.access_policy.permission.must_equal identifiers.first.access_policy.permission

      container, acl = subject.get_container_acl container_name
      container.wont_be_nil
      container.name.must_equal container_name
      container.public_access_level.must_equal public_access_level.to_s
      acl.length.must_equal identifiers.length
      acl.first.id.must_equal identifiers.first.id
      acl.first.access_policy.start.must_equal identifiers.first.access_policy.start
      acl.first.access_policy.expiry.must_equal identifiers.first.access_policy.expiry
      acl.first.access_policy.permission.must_equal identifiers.first.access_policy.permission
    end

    it "errors if the container does not exist" do
      assert_raises(Azure::Core::Http::HTTPError) do
        subject.get_container_acl ContainerNameHelper.name
      end
      assert_raises(Azure::Core::Http::HTTPError) do
        subject.set_container_acl ContainerNameHelper.name, public_access_level, identifiers: identifiers
      end
    end
  end
end
