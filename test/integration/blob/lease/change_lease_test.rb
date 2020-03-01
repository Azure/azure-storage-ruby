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

  describe "#change_lease" do
    let(:container_name) { ContainerNameHelper.name }
    let(:porposed_lease_id) { "4137EAD7-795F-4FB0-8AD3-425266A4357B".downcase }
    let(:blob_name) { "blobname" }
    let(:length) { 1024 }
    before {
      subject.create_container container_name
    }

    it "should be possible to change a container lease" do
      lease_id = subject.acquire_container_lease container_name
      _(lease_id).wont_be_nil

      new_lease_id = subject.change_container_lease container_name, lease_id, porposed_lease_id
      _(new_lease_id).wont_be_nil

      # changing a lease returns the same lease id
      _(new_lease_id).must_equal porposed_lease_id
    end

    it "should be possible to change a blob lease" do
      subject.create_page_blob container_name, blob_name, length

      lease_id = subject.acquire_blob_lease container_name, blob_name
      _(lease_id).wont_be_nil

      new_lease_id = subject.change_blob_lease container_name, blob_name, lease_id, porposed_lease_id
      _(new_lease_id).wont_be_nil

      # changing a lease returns the same lease id
      _(new_lease_id).must_equal porposed_lease_id
    end
  end
end
