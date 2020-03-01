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

describe Azure::Storage::Blob::BlobService do
  subject { Azure::Storage::Blob::BlobService.create(SERVICE_CREATE_OPTIONS()) }
  after { ContainerNameHelper.clean }

  describe "#set/get_container_acl" do
    let(:public_access_level) { :container.to_s }
    let(:identifiers) {
      identifier = Azure::Storage::Common::Service::SignedIdentifier.new
      identifier.id = "MTIzNDU2Nzg5MDEyMzQ1Njc4OTAxMjM0NTY3ODkwMTI="
      identifier.access_policy.start = "2009-09-28T08:49:37.0000000Z"
      identifier.access_policy.expiry = "2009-09-29T08:49:37.0000000Z"
      identifier.access_policy.permission = "rwd"
      [identifier]
    }

    it "sets and gets the ACL for the container" do
      container_name = ContainerNameHelper.name
      subject.create_container container_name
      container, acl = subject.set_container_acl container_name, public_access_level, signed_identifiers: identifiers
      _(container).wont_be_nil
      _(container.name).must_equal container_name
      _(container.public_access_level).must_equal public_access_level.to_s
      _(acl.length).must_equal identifiers.length
      _(acl.first.id).must_equal identifiers.first.id
      _(acl.first.access_policy.start).must_equal identifiers.first.access_policy.start
      _(acl.first.access_policy.expiry).must_equal identifiers.first.access_policy.expiry
      _(acl.first.access_policy.permission).must_equal identifiers.first.access_policy.permission

      container, acl = subject.get_container_acl container_name
      _(container).wont_be_nil
      _(container.name).must_equal container_name
      _(container.public_access_level).must_equal public_access_level.to_s
      _(acl.length).must_equal identifiers.length
      _(acl.first.id).must_equal identifiers.first.id
      _(acl.first.access_policy.start).must_equal identifiers.first.access_policy.start
      _(acl.first.access_policy.expiry).must_equal identifiers.first.access_policy.expiry
      _(acl.first.access_policy.permission).must_equal identifiers.first.access_policy.permission
    end

    it "errors if the container does not exist" do
      assert_raises(Azure::Core::Http::HTTPError) do
        subject.get_container_acl ContainerNameHelper.name
      end
      assert_raises(Azure::Core::Http::HTTPError) do
        subject.set_container_acl ContainerNameHelper.name, public_access_level, identifiers: identifiers
      end
    end

    it "lease id works for get_container_acl" do
      container_name = ContainerNameHelper.name
      subject.create_container container_name
      container, acl = subject.set_container_acl container_name, public_access_level, signed_identifiers: identifiers
      lease_id = subject.acquire_container_lease container_name
      subject.release_container_lease container_name, lease_id
      new_lease_id = subject.acquire_container_lease container_name
      # assert wrong lease fails
      status_code = ""
      description = ""
      begin
        container, acl = subject.get_container_acl container_name, lease_id: lease_id
      rescue Azure::Core::Http::HTTPError => e
        status_code = e.status_code.to_s
        description = e.description
      end
      _(status_code).must_equal "412"
      _(description).must_include "The lease ID specified did not match the lease ID for the container."
      # assert right lease succeeds
      container, acl = subject.get_container_acl container_name, lease_id: new_lease_id
      _(container).wont_be_nil
      _(container.name).must_equal container_name
      _(container.public_access_level).must_equal public_access_level.to_s
      _(acl.length).must_equal identifiers.length
      _(acl.first.id).must_equal identifiers.first.id
      _(acl.first.access_policy.start).must_equal identifiers.first.access_policy.start
      _(acl.first.access_policy.expiry).must_equal identifiers.first.access_policy.expiry
      _(acl.first.access_policy.permission).must_equal identifiers.first.access_policy.permission
      # assert no lease succeeds
      container, acl = subject.get_container_acl container_name
      _(container).wont_be_nil
      _(container.name).must_equal container_name
      _(container.public_access_level).must_equal public_access_level.to_s
      _(acl.length).must_equal identifiers.length
      _(acl.first.id).must_equal identifiers.first.id
      _(acl.first.access_policy.start).must_equal identifiers.first.access_policy.start
      _(acl.first.access_policy.expiry).must_equal identifiers.first.access_policy.expiry
      _(acl.first.access_policy.permission).must_equal identifiers.first.access_policy.permission
      # release lease afterwards
      subject.release_container_lease container_name, new_lease_id
    end

    it "lease id works for set_container_acl" do
      container_name = ContainerNameHelper.name
      subject.create_container container_name
      lease_id = subject.acquire_container_lease container_name
      subject.release_container_lease container_name, lease_id
      new_lease_id = subject.acquire_container_lease container_name
      # assert wrong lease fails
      status_code = ""
      description = ""
      begin
        container, acl = subject.set_container_acl container_name, public_access_level, signed_identifiers: identifiers, lease_id: lease_id
      rescue Azure::Core::Http::HTTPError => e
        status_code = e.status_code.to_s
        description = e.description
      end
      _(status_code).must_equal "412"
      _(description).must_include "The lease ID specified did not match the lease ID for the container."
      # assert right lease succeeds
      container, acl = subject.set_container_acl container_name, public_access_level, signed_identifiers: identifiers, lease_id: new_lease_id
      container, acl = subject.get_container_acl container_name, lease_id: new_lease_id
      _(container).wont_be_nil
      _(container.name).must_equal container_name
      _(container.public_access_level).must_equal public_access_level.to_s
      _(acl.length).must_equal identifiers.length
      _(acl.first.id).must_equal identifiers.first.id
      _(acl.first.access_policy.start).must_equal identifiers.first.access_policy.start
      _(acl.first.access_policy.expiry).must_equal identifiers.first.access_policy.expiry
      _(acl.first.access_policy.permission).must_equal identifiers.first.access_policy.permission
      # prove that no lease succeeds
      container, acl = subject.set_container_acl container_name, public_access_level, signed_identifiers: identifiers, lease_id: new_lease_id
      # release lease afterwards
      subject.release_container_lease container_name, new_lease_id
    end
  end
end
