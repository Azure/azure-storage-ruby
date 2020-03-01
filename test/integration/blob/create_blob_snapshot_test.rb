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

  describe "#create_blob_snapshot" do
    let(:container_name) { ContainerNameHelper.name }
    let(:blob_name) { "blobname" }
    let(:content) { content = ""; 1024.times.each { |i| content << "@" }; content }
    let(:metadata) { { "CustomMetadataProperty" => "CustomMetadataValue" } }
    let(:options) { { content_type: "application/foo", metadata: metadata } }

    before {
      subject.create_container container_name
      subject.create_block_blob container_name, blob_name, content, options
    }

    it "errors if the container does not exist" do
      assert_raises(Azure::Core::Http::HTTPError) do
        subject.create_blob_snapshot ContainerNameHelper.name, blob_name
      end
    end

    it "errors if the blob does not exist" do
      assert_raises(Azure::Core::Http::HTTPError) do
        subject.create_blob_snapshot container_name, "unknown-blob"
      end
    end

    it "creates a snapshot of blob contents, metadata, and properties" do
      snapshot = subject.create_blob_snapshot container_name, blob_name

      content2 = ""
      1024.times.each { |i| content2 << "!" }
      options2 = options.dup
      options2[:metadata] = options[:metadata].dup
      options2[:content_type] = "application/bar"
      options2[:metadata]["CustomMetadataValue1"] = "NewMetadata"
      subject.create_block_blob container_name, blob_name, content2, options2

      # content/properties/metadata in blob is new version
      blob, returned_content = subject.get_blob container_name, blob_name, start_range: 0, end_range: 511
      _(returned_content.length).must_equal 512
      _(returned_content).must_equal content2[0..511]
      _(blob.properties[:content_type]).must_equal options2[:content_type]
      options2[:metadata].each { |k, v|
        _(blob.metadata).must_include k.downcase
        _(blob.metadata[k.downcase]).must_equal v
      }

      # content/properties/metadata in snapshot is old version
      blob, returned_content = subject.get_blob container_name, blob_name, start_range: 0, end_range: 511, snapshot: snapshot

      _(returned_content.length).must_equal 512
      _(returned_content).must_equal content[0..511]
      _(blob.properties[:content_type]).must_equal options[:content_type]
      options[:metadata].each { |k, v|
        _(blob.metadata).must_include k.downcase
        _(blob.metadata[k.downcase]).must_equal v
      }

    end

    it "lease id works for create_blob_snapshot" do
      page_blob_name = BlobNameHelper.name
      subject.create_page_blob container_name, page_blob_name, 1024
      # add lease to blob
      lease_id = subject.acquire_blob_lease container_name, page_blob_name
      subject.release_blob_lease container_name, page_blob_name, lease_id
      new_lease_id = subject.acquire_blob_lease container_name, page_blob_name
      # assert wrong lease fails
      status_code = ""
      description = ""
      begin
        snapshot = subject.create_blob_snapshot container_name, page_blob_name, lease_id: lease_id
      rescue Azure::Core::Http::HTTPError => e
        status_code = e.status_code.to_s
        description = e.description
      end
      _(status_code).must_equal "412"
      _(description).must_include "The lease ID specified did not match the lease ID for the blob."
      # assert right lease succeeds
      snapshot = subject.create_blob_snapshot container_name, page_blob_name, lease_id: new_lease_id
      _(snapshot).wont_be_nil
      # assert no lease succeeds
      snapshot = subject.create_blob_snapshot container_name, page_blob_name
      _(snapshot).wont_be_nil
    end
  end
end
