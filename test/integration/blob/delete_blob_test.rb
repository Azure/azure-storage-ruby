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

  describe "#delete_blob" do
    let(:container_name) { ContainerNameHelper.name }
    let(:blob_name) { "blobname" }
    let(:length) { 1024 }
    before {
      subject.create_container container_name
      subject.create_page_blob container_name, blob_name, length
    }

    it "deletes a blob" do
      subject.delete_blob container_name, blob_name
    end

    it "errors if the container does not exist" do
      assert_raises(Azure::Core::Http::HTTPError) do
        subject.delete_blob ContainerNameHelper.name, blob_name
      end
    end

    it "errors if the blob does not exist" do
      assert_raises(Azure::Core::Http::HTTPError) do
        subject.delete_blob container_name, "unknown-blob"
      end
    end

    it "lease id works for delete_blob" do
      page_blob_name = BlobNameHelper.name
      subject.create_page_blob container_name, page_blob_name, length
      # acquire lease for blob
      lease_id = subject.acquire_blob_lease container_name, page_blob_name
      # assert no lease fails
      status_code = ""
      description = ""
      begin
        subject.delete_blob container_name, page_blob_name
      rescue Azure::Core::Http::HTTPError => e
        status_code = e.status_code.to_s
        description = e.description
      end
      _(status_code).must_equal "412"
      _(description).must_include "There is currently a lease on the blob and no lease ID was specified in the request."
      # assert correct lease works
      subject.delete_blob container_name, page_blob_name, lease_id: lease_id
    end

    describe "when a blob has snapshots" do
      let(:snapshot) {
        subject.create_blob_snapshot container_name, blob_name
      }

      # ensure snapshot gets created before tests run. silly.
      before { s = snapshot }

      it "deletes the blob, and all the snapshots for the blob, if optional paramters are not used" do
        # verify snapshot exists
        result = subject.list_blobs(container_name, snapshots: true)

        snapshot_exists = false
        result.each { |b|
          snapshot_exists = true if b.name == (blob_name) && b.snapshot == (snapshot)
        }
        _(snapshot_exists).must_equal true

        # delete blob
        subject.delete_blob container_name, blob_name

        # verify blob is gone and snapshot remains
        result = subject.list_blobs(container_name, snapshots: true)
        _(result.length).must_equal 0
      end

      it "the snapshot parameter deletes a specific blob snapshot" do
        # create a second snapshot
        second_snapshot = subject.create_blob_snapshot container_name, blob_name

        # verify two snapshots exist

        result = subject.list_blobs(container_name, snapshots: true)

        snapshots = 0
        result.each { |b|
          snapshots += 1 if b.name == (blob_name) && b.snapshot != (nil)
        }
        _(snapshots).must_equal 2

        subject.delete_blob container_name, blob_name, snapshot: snapshot

        # verify first snapshot is gone and blob remains
        result = subject.list_blobs(container_name, snapshots: true)

        snapshots = 0
        blob_exists = false
        result.each { |b|
          blob_exists = true if b.name == (blob_name) && b.snapshot == (nil)
          snapshots += 1 if b.name == (blob_name) && b.snapshot == (second_snapshot)
        }
        _(blob_exists).must_equal true
        _(snapshots).must_equal 1
      end

      it "errors if the snapshot id provided does not exist" do
        assert_raises(Azure::Core::Http::HTTPError) do
          subject.delete_blob container_name, blob_name, snapshot: "thissnapshotidisinvalid"
        end
      end

      describe "when :only is provided in the delete_snapshots parameter" do
        let(:delete_snapshots) { :only }
        it "deletes all the snapshots for the blob, keeping the blob" do
          # verify snapshot exists
          result = subject.list_blobs(container_name, snapshots: true)

          snapshot_exists = false
          result.each { |b|
            snapshot_exists = true if b.name == (blob_name) && b.snapshot == (snapshot)
          }
          _(snapshot_exists).must_equal true

          # delete snapshots
          subject.delete_blob container_name, blob_name, snapshot: nil, delete_snapshots: :only

          # verify snapshot is gone and blob remains
          result = subject.list_blobs(container_name, snapshots: true)

          snapshot_exists = false
          blob_exists = false
          result.each { |b|
            blob_exists = true if b.name == (blob_name) && b.snapshot == (nil)
            snapshot_exists = true if b.name == (blob_name) && b.snapshot == (snapshot)
          }
          _(blob_exists).must_equal true
          _(snapshot_exists).must_equal false
        end
      end

      describe "when :include is provided in the delete_snapshots parameter" do
        let(:delete_snapshots) { :include }
        it "deletes the blob and all of the snapshots for the blob" do
          # verify snapshot exists
          result = subject.list_blobs(container_name, snapshots: true)

          snapshot_exists = false
          result.each { |b|
            snapshot_exists = true if b.name == (blob_name) && b.snapshot == (snapshot)
          }
          _(snapshot_exists).must_equal true

          # delete snapshots
          subject.delete_blob container_name, blob_name, snapshot: nil, delete_snapshots: :include

          # verify snapshot is gone and blob remains
          result = subject.list_blobs(container_name, snapshots: true)
          _(result.length).must_equal 0
        end
      end
    end
  end
end
