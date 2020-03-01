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

  describe "#list_blobs" do
    let(:container_name) { ContainerNameHelper.name }
    let(:blob_names) { ["blobname0", "blobname1", "blobname2", "blobname3", "prefix0/blobname4", "prefix0/blobname5", "prefix0/child_prefix0/blobname6"] }
    let(:content) { content = ""; 1024.times.each { |i| content << "@" }; content }
    let(:metadata) { { "CustomMetadataProperty" => "CustomMetadataValue" } }
    let(:options) { { content_type: "application/foo", metadata: metadata } }

    before {
      subject.create_container container_name
      blob_names.each { |blob_name|
        subject.create_block_blob container_name, blob_name, content, options
      }
    }

    it "lists the available blobs" do
      result = subject.list_blobs container_name
      _(result.length).must_equal blob_names.length
      expected_blob_names = blob_names.each
      result.each { |blob|
        _(blob.name).must_equal expected_blob_names.next
        _(blob.properties[:content_length]).must_equal content.length
        _(is_boolean(blob.encrypted)).must_equal true
      }
    end

    it "lists the available blobs with prefix" do
      result = subject.list_blobs container_name, prefix: "blobname0"
      _(result.length).must_equal 1
      result = subject.list_blobs container_name, prefix: "prefix0/"
      _(result.length).must_equal 3
    end

    it "lists the available blobs and prefixes with delimiter and prefix" do
      result = subject.list_blobs container_name, delimiter: "/"
      _(result.length).must_equal 5
      result = subject.list_blobs container_name, delimiter: "/", prefix: "prefix0/"
      _(result.length).must_equal 3
      result = subject.list_blobs container_name, delimiter: "/", prefix: "prefix0/child_prefix0/"
      _(result.length).must_equal 1
    end

    it "lists the available blobs with max results and marker " do
      result = subject.list_blobs container_name, max_results: 2
      _(result.length).must_equal 2
      first_blob = result[0]
      result.continuation_token.wont_equal("")

      result = subject.list_blobs container_name, max_results: 2, marker: result.continuation_token
      _(result.length).must_equal 2
      result[0].name.wont_equal first_blob.name
    end

    describe "when options hash is used" do
      it "if :metadata is set true, also returns custom metadata for the blobs" do
        result = subject.list_blobs container_name, metadata: true
        _(result.length).must_equal blob_names.length
        expected_blob_names = blob_names.each

        result.each { |blob|
          _(blob.name).must_equal expected_blob_names.next
          _(blob.properties[:content_length]).must_equal content.length
          _(is_boolean(blob.encrypted)).must_equal true

          metadata.each { |k, v|
            _(blob.metadata).must_include k.downcase
            _(blob.metadata[k.downcase]).must_equal v
          }
        }
      end

      it "if :snapshots is set true, also returns snapshots" do
        snapshot = subject.create_blob_snapshot container_name, blob_names[0]

        # verify snapshots aren't returned on a normal call
        result = subject.list_blobs container_name
        _(result.length).must_equal blob_names.length

        result = subject.list_blobs container_name, snapshots: true
        _(result.length).must_equal blob_names.length + 1
        found_snapshot = false
        result.each { |blob|
          found_snapshot = true if blob.name == (blob_names[0]) && blob.snapshot == (snapshot)
        }
        _(found_snapshot).must_equal true
      end

      it "if :uncommittedblobs is set true, also returns blobs with uploaded, uncommitted blocks" do
        # uncommited blob/block
        subject.put_blob_block container_name, "blockblobname", "blockid", content

        # verify uncommitted blobs aren't returned on a normal call
        result = subject.list_blobs container_name
        _(result.length).must_equal blob_names.length

        result = subject.list_blobs container_name, uncommittedblobs: true
        _(result.length).must_equal blob_names.length + 1
        found_uncommitted = true
        result.each { |blob|
          found_uncommitted = true if blob.name == "blockblobname"
        }
        _(found_uncommitted).must_equal true
      end
    end
  end
end
