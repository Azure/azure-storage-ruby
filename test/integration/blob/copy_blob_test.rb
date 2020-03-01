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
  describe "#copy_blob" do
    let(:source_container_name) { ContainerNameHelper.name }
    let(:source_blob_name) { "audio+video%25.mp4" }
    let(:content) { content = ""; 512.times.each { |i| content << "@" }; content }
    let(:metadata) { { "custommetadata" => "CustomMetadataValue" } }

    let(:dest_container_name) { ContainerNameHelper.name }
    let(:dest_blob_name) { "destaudio+video%25.mp4" }

    before {
      subject.create_container source_container_name
      subject.create_block_blob source_container_name, source_blob_name, content

      subject.create_container dest_container_name
    }

    it "copies an existing blob to a new storage location" do
      copy_id, copy_status = subject.copy_blob dest_container_name, dest_blob_name, source_container_name, source_blob_name
      _(copy_id).wont_be_nil

      blob, returned_content = subject.get_blob dest_container_name, dest_blob_name

      _(blob.name).must_equal dest_blob_name
      _(returned_content).must_equal content
    end

    it "returns a copyid which can be used to monitor status of the asynchronous copy operation" do
      copy_id, copy_status = subject.copy_blob dest_container_name, dest_blob_name, source_container_name, source_blob_name
      _(copy_id).wont_be_nil

      counter = 0
      finished = false
      while (counter < (10) && (not finished))
        sleep(1)
        blob = subject.get_blob_properties dest_container_name, dest_blob_name
        _(blob.properties[:copy_id]).must_equal copy_id
        finished = blob.properties[:copy_status] == "success"
        counter += 1
      end
      _(finished).must_equal true

      blob, returned_content = subject.get_blob dest_container_name, dest_blob_name

      _(blob.name).must_equal dest_blob_name
      _(returned_content).must_equal content
    end

    it "returns a copyid which can be used to abort copy operation" do
      copy_id, copy_status = subject.copy_blob dest_container_name, dest_blob_name, source_container_name, source_blob_name
      _(copy_id).wont_be_nil

      counter = 0
      finished = false
      while (counter < (10) && (not finished))
        sleep(1)
        blob = subject.get_blob_properties dest_container_name, dest_blob_name
        _(blob.properties[:copy_id]).must_equal copy_id
        finished = blob.properties[:copy_status] == "success"
        counter += 1
      end
      _(finished).must_equal true

      exception = assert_raises(Azure::Core::Http::HTTPError) do
        subject.abort_copy_blob dest_container_name, dest_blob_name, copy_id
      end
      refute_nil(exception.message.index "NoPendingCopyOperation (409): There is currently no pending copy operation")
    end

    describe "when a snapshot is specified" do
      it "creates a copy of the snapshot" do
        snapshot = subject.create_blob_snapshot source_container_name, source_blob_name

        # verify blob is updated, and content is different than snapshot
        subject.create_block_blob source_container_name, source_blob_name, content + "more content"
        blob, returned_content = subject.get_blob source_container_name, source_blob_name
        _(returned_content).must_equal content + "more content"

        # do copy against, snapshot
        subject.copy_blob dest_container_name, dest_blob_name, source_container_name, source_blob_name, source_snapshot: snapshot

        blob, returned_content = subject.get_blob dest_container_name, dest_blob_name

        # verify copied content is old content
        _(returned_content).must_equal content
      end
    end

    describe "when a options hash is used" do
      it "replaces source metadata on the copy with provided Hash in :metadata property" do
        copy_id, copy_status = subject.copy_blob dest_container_name, dest_blob_name, source_container_name, source_blob_name, metadata: metadata
        _(copy_id).wont_be_nil

        blob, returned_content = subject.get_blob dest_container_name, dest_blob_name

        _(blob.name).must_equal dest_blob_name
        _(returned_content).must_equal content

        blob = subject.get_blob_metadata dest_container_name, dest_blob_name

        metadata.each { |k, v|
          _(blob.metadata).must_include k
          _(blob.metadata[k]).must_equal v
        }
      end

      it "can specify ETag matching behaviours" do
        # invalid if match
        assert_raises(Azure::Core::Http::HTTPError) do
          subject.copy_blob dest_container_name, dest_blob_name, source_container_name, source_blob_name, source_if_match: "fake"
        end
      end
    end

    it "lease id works for copy_blob and copy_blob_from_uri" do
      blob_name = BlobNameHelper.name
      subject.create_block_blob dest_container_name, blob_name, "nonsense"
      # acquire lease for blob
      lease_id = subject.acquire_blob_lease dest_container_name, blob_name
      # assert no lease fails
      status_code = ""
      description = ""
      begin
        copy_id, copy_status = subject.copy_blob dest_container_name, blob_name, source_container_name, source_blob_name
      rescue Azure::Core::Http::HTTPError => e
        status_code = e.status_code.to_s
        description = e.description
      end
      _(status_code).must_equal "412"
      _(description).must_include "There is currently a lease on the blob and no lease ID was specified in the request."
      # assert correct lease works
      copy_id, copy_status = subject.copy_blob dest_container_name, blob_name, source_container_name, source_blob_name, lease_id: lease_id
      _(copy_id).wont_be_nil
      blob, returned_content = subject.get_blob dest_container_name, blob_name
      _(blob.name).must_equal blob_name
      _(returned_content).must_equal content
    end
  end
end
