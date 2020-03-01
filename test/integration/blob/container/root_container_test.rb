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
require "azure/core/http/http_error"

describe Azure::Storage::Blob::BlobService do
  subject { Azure::Storage::Blob::BlobService.create(SERVICE_CREATE_OPTIONS()) }

  let(:container_name) { "$root" }
  let(:blob_name1) { "blobname1" }
  let(:length) { 1024 }
  let(:blob_name2) { "blobname2" }
  let(:length) { 1024 }
  let(:blob_name3) { "blobname3" }
  let(:length) { 1024 }

  after {
    subject.delete_container "$root"
  }

  it "creates the container with explicit name and some blobs" do
    begin
      container = subject.create_container container_name
      _(container.name).must_equal container_name
      # explicit root container name
      blob = subject.create_page_blob container_name, blob_name1, length
      _(blob.name).must_equal blob_name1

      # nil container name
      blob = subject.create_page_blob nil, blob_name2, length
      _(blob.name).must_equal blob_name2

      # empty string container name
      blob = subject.create_page_blob "", blob_name3, length
      _(blob.name).must_equal blob_name3
    rescue Azure::Core::Http::HTTPError => error
      puts error.message
      _(error.status_code).must_equal 409
    end
  end
end
