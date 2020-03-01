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

describe Azure::Storage::File::FileService do
  subject { Azure::Storage::File::FileService.create(SERVICE_CREATE_OPTIONS()) }
  after { ShareNameHelper.clean }

  describe "#set/get_share_acl" do
    let(:share_name) { ShareNameHelper.name }
    let(:public_access_level) { :share.to_s }
    let(:identifiers) {
      identifier = Azure::Storage::Common::Service::SignedIdentifier.new
      identifier.id = "MTIzNDU2Nzg5MDEyMzQ1Njc4OTAxMjM0NTY3ODkwMTI="
      identifier.access_policy.start = "2009-09-28T08:49:37.0000000Z"
      identifier.access_policy.expiry = "2009-09-29T08:49:37.0000000Z"
      identifier.access_policy.permission = "rwd"
      [identifier]
    }
    before {
      subject.create_share share_name
    }

    it "sets and gets the ACL for the share" do
      share, acl = subject.set_share_acl share_name, signed_identifiers: identifiers
      _(share).wont_be_nil
      _(share.name).must_equal share_name
      _(acl.length).must_equal identifiers.length
      _(acl.first.id).must_equal identifiers.first.id
      _(acl.first.access_policy.start).must_equal identifiers.first.access_policy.start
      _(acl.first.access_policy.expiry).must_equal identifiers.first.access_policy.expiry
      _(acl.first.access_policy.permission).must_equal identifiers.first.access_policy.permission

      share, acl = subject.get_share_acl share_name
      _(share).wont_be_nil
      _(share.name).must_equal share_name
      _(acl.length).must_equal identifiers.length
      _(acl.first.id).must_equal identifiers.first.id
      _(acl.first.access_policy.start).must_equal identifiers.first.access_policy.start
      _(acl.first.access_policy.expiry).must_equal identifiers.first.access_policy.expiry
      _(acl.first.access_policy.permission).must_equal identifiers.first.access_policy.permission
    end

    it "errors if the share does not exist" do
      assert_raises(Azure::Core::Http::HTTPError) do
        subject.get_share_acl FileNameHelper.name
      end
      assert_raises(Azure::Core::Http::HTTPError) do
        subject.set_share_acl FileNameHelper.name, identifiers: identifiers
      end
    end
  end
end
