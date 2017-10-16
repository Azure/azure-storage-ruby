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
require "digest/md5"

describe Azure::Storage::Blob::BlobService do
  subject { Azure::Storage::Blob::BlobService.new }
  after { ContainerNameHelper.clean }

  describe "#get_blob" do
    let(:container_name) { ContainerNameHelper.name }
    let(:blob_name) { "blobname" }
    let(:content) { content = ""; 1024.times.each { |i| content << "@" }; content }
    let(:metadata) { { "CustomMetadataProperty" => "CustomMetadataValue" } }
    let(:options) { { content_type: "application/foo", metadata: metadata } }

    before {
      subject.create_container container_name
      subject.create_block_blob container_name, blob_name, content, options
    }

    it "retrieves the blob properties, metadata, and contents" do
      blob, returned_content = subject.get_blob container_name, blob_name
      returned_content.must_equal content
      blob.metadata.must_include "custommetadataproperty"
      blob.metadata["custommetadataproperty"].must_equal "CustomMetadataValue"
      blob.properties[:content_type].must_equal "application/foo"
    end

    it "retrieves a range of data from the blob" do
      blob, returned_content = subject.get_blob container_name, blob_name, start_range: 0, end_range: 511, get_content_md5: true
      is_boolean(blob.encrypted).must_equal true
      returned_content.length.must_equal 512
      returned_content.must_equal content[0..511]
      blob.properties[:range_md5].must_equal Digest::MD5.base64digest(content[0..511])
      blob.properties[:content_md5].must_equal Digest::MD5.base64digest(content)
    end

    it "retrieves a snapshot of data from the blob" do
      snapshot = subject.create_blob_snapshot container_name, blob_name

      content2 = ""
      1024.times.each { |i| content2 << "!" }
      subject.create_block_blob container_name, blob_name, content2, options

      blob, returned_content = subject.get_blob container_name, blob_name, start_range: 0, end_range: 511
      is_boolean(blob.encrypted).must_equal true
      returned_content.length.must_equal 512
      returned_content.must_equal content2[0..511]

      blob, returned_content = subject.get_blob container_name, blob_name, start_range: 0, end_range: 511, snapshot: snapshot
      is_boolean(blob.encrypted).must_equal true

      returned_content.length.must_equal 512
      returned_content.must_equal content[0..511]
    end

    it "read failure with if_none_match: *" do
      status_code = ""
      description = ""
      begin
        blob = subject.get_blob container_name, blob_name, if_none_match: "*"
      rescue Azure::Core::Http::HTTPError => e
        status_code = e.status_code.to_s
        description = e.description
      end
      status_code.must_equal "400"
      description.must_include "The request includes an unsatisfiable condition for this operation."
    end

    it "lease id works for get_blob" do
      block_blob_name = BlobNameHelper.name
      subject.create_block_blob container_name, block_blob_name, content
      # acquire lease for blob
      lease_id = subject.acquire_blob_lease container_name, block_blob_name
      subject.release_blob_lease container_name, block_blob_name, lease_id
      new_lease_id = subject.acquire_blob_lease container_name, block_blob_name
      # assert no lease fails
      status_code = ""
      description = ""
      begin
        subject.get_blob container_name, block_blob_name, lease_id: lease_id
      rescue Azure::Core::Http::HTTPError => e
        status_code = e.status_code.to_s
        description = e.description
      end
      status_code.must_equal "412"
      description.must_include "The lease ID specified did not match the lease ID for the blob."
      # assert correct lease works
      blob, body = subject.get_blob container_name, block_blob_name, lease_id: new_lease_id
      blob.name.must_equal block_blob_name
      body.must_equal content
      # assert no lease works
      blob, body = subject.get_blob container_name, block_blob_name
      blob.name.must_equal block_blob_name
      body.must_equal content
    end
  end
end
