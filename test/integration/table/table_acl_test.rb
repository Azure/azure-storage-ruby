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
require "azure/core/http/http_error"

describe Azure::Storage::Table::TableService do
  describe "#get/set_acl" do
    subject { Azure::Storage::Table::TableService.create(SERVICE_CREATE_OPTIONS()) }
    let(:table_name) { TableNameHelper.name }
    let(:signed_identifier) {
      identifier = Azure::Storage::Common::Service::SignedIdentifier.new
      identifier.id = "MTIzNDU2Nzg5MDEyMzQ1Njc4OTAxMjM0NTY3ODkwMTI="
      identifier.access_policy = Azure::Storage::Common::Service::AccessPolicy.new
      identifier.access_policy.start = "2009-09-28T08:49:37.0000000Z"
      identifier.access_policy.expiry = "2009-09-29T08:49:37.0000000Z"
      identifier.access_policy.permission = "raud"
      identifier
    }

    before {
      subject.create_table table_name
    }
    after { TableNameHelper.clean }

    it "sets and gets the ACL for a table" do
      subject.set_table_acl(table_name, signed_identifiers: [ signed_identifier ])

      result = subject.get_table_acl table_name
      _(result).must_be_kind_of Array

      result.wont_be_empty
      _(result.last).must_be_kind_of Azure::Storage::Common::Service::SignedIdentifier
      _(result.last.id).must_equal signed_identifier.id
      _(result.last.access_policy.start).must_equal signed_identifier.access_policy.start
      _(result.last.access_policy.expiry).must_equal signed_identifier.access_policy.expiry
      _(result.last.access_policy.permission).must_equal signed_identifier.access_policy.permission
    end
  end
end
