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
require "securerandom"

describe Azure::Storage::Blob::BlobService do
  subject { Azure::Storage::Blob::BlobService.new }
  after { ContainerNameHelper.clean }

  let(:container_name) { ContainerNameHelper.name }
  let(:blob_name) { "blobname" }
  let(:blob_name2) { "blobname2" }
  let(:blob_name3) { "blobname3" }
  let(:length) { 2560 }
  before {
    subject.create_container container_name
    subject.create_page_blob container_name, blob_name, length
    subject.create_page_blob container_name, blob_name2, length
    subject.create_page_blob container_name, blob_name3, length
  }

  describe "#put_blob_pages" do
    it "creates pages in a page blob" do
      content = ""
      512.times.each { |i| content << "@" }

      subject.put_blob_pages container_name, blob_name, 0, 511, content
      subject.put_blob_pages container_name, blob_name, 1024, 1535, content

      ranges = subject.list_page_blob_ranges container_name, blob_name, start_range: 0, end_range: 1536
      ranges[0][0].must_equal 0
      ranges[0][1].must_equal 511
      ranges[1][0].must_equal 1024
      ranges[1][1].must_equal 1535
    end

    it "lease id works for put_blob_pages" do
      page_blob_name = BlobNameHelper.name
      subject.create_page_blob container_name, page_blob_name, length
      content = ""
      512.times.each { |i| content << "@" }
      # add lease to blob
      lease_id = subject.acquire_blob_lease container_name, page_blob_name
      # assert no lease fails
      status_code = ""
      description = ""
      begin
        blob = subject.put_blob_pages container_name, page_blob_name, 0, 511, content
      rescue Azure::Core::Http::HTTPError => e
        status_code = e.status_code.to_s
        description = e.description
      end
      status_code.must_equal "412"
      description.must_include "There is currently a lease on the blob and no lease ID was specified in the request."
      # assert right lease succeeds
      subject.put_blob_pages container_name, page_blob_name, 0, 511, content, lease_id: lease_id
      subject.put_blob_pages container_name, page_blob_name, 1024, 1535, content, lease_id: lease_id

      ranges = subject.list_page_blob_ranges container_name, page_blob_name, start_range: 0, end_range: 1536
      ranges[0][0].must_equal 0
      ranges[0][1].must_equal 511
      ranges[1][0].must_equal 1024
      ranges[1][1].must_equal 1535
    end
  end

  describe "when the options hash is used" do
    it "if none match is specified" do
      content = ""
      512.times.each { |i| content << "@" }

      blob = subject.put_blob_pages container_name, blob_name2, 0, 511, content
      is_boolean(blob.encrypted).must_equal true

      assert_raises(Azure::Core::Http::HTTPError) do
        subject.put_blob_pages container_name, blob_name2, 1024, 1535, content, if_none_match: blob.properties[:etag]
      end
    end

    it "if match is specified" do
      content = ""
      512.times.each { |i| content << "@" }

      blob = subject.put_blob_pages container_name, blob_name, 0, 511, content
      is_boolean(blob.encrypted).must_equal true
      subject.put_blob_pages container_name, blob_name, 1024, 1535, content, if_match: blob.properties[:etag]
    end
  end

  describe "#clear_blob_pages" do
    before {
      content = ""
      512.times.each { |i| content << "@" }

      subject.put_blob_pages container_name, blob_name, 0, 511, content
      subject.put_blob_pages container_name, blob_name, 1024, 1535, content
      subject.put_blob_pages container_name, blob_name, 2048, 2559, content

      ranges = subject.list_page_blob_ranges container_name, blob_name, start_range: 0, end_range: 2560
      ranges.length.must_equal 3
      ranges[0][0].must_equal 0
      ranges[0][1].must_equal 511
      ranges[1][0].must_equal 1024
      ranges[1][1].must_equal 1535
      ranges[2][0].must_equal 2048
      ranges[2][1].must_equal 2559
    }

    describe "when both start_range and end_range are specified" do
      it "clears the data in page blobs within the provided range" do
        subject.clear_blob_pages container_name, blob_name, 512, 1535

        ranges = subject.list_page_blob_ranges container_name, blob_name, start_range: 0, end_range: 2560
        ranges.length.must_equal 2
        ranges[0][0].must_equal 0
        ranges[0][1].must_equal 511
        ranges[1][0].must_equal 2048
        ranges[1][1].must_equal 2559
      end
    end
  end

  describe "#list_page_blob_ranges" do
    before {
      content = ""
      512.times.each { |i| content << "@" }

      subject.put_blob_pages container_name, blob_name, 0, 511, content
      subject.put_blob_pages container_name, blob_name, 1024, 1535, content
    }

    it "lists the active blob pages" do
      ranges = subject.list_page_blob_ranges container_name, blob_name, start_range: 0, end_range: 1536
      ranges[0][0].must_equal 0
      ranges[0][1].must_equal 511
      ranges[1][0].must_equal 1024
      ranges[1][1].must_equal 1535
    end

    it "list blob pages in the snapshot" do
      # initialize the blob
      content_512B = SecureRandom.random_bytes(512)
      subject.put_blob_pages container_name, blob_name3, 0, 511, content_512B
      subject.put_blob_pages container_name, blob_name3, 1024, 1535, content_512B
      # snapshot
      snapshot1 = subject.create_blob_snapshot container_name, blob_name3
      # modify the blob after snapshot
      subject.put_blob_pages container_name, blob_name3, 2048, 2559, content_512B
      # verify that even the blob has been altered, the returned list
      # will not contain the change if snapshot is specified
      ranges = subject.list_page_blob_ranges container_name, blob_name3, snapshot: snapshot1
      ranges.length.must_equal 2
      # verify the change
      ranges = subject.list_page_blob_ranges container_name, blob_name3
      ranges.length.must_equal 3
      # take another snapshot
      snapshot2 = subject.create_blob_snapshot container_name, blob_name3
      # only change between snapshot1 and snapshot2 will be listed
      ranges = subject.list_page_blob_ranges container_name, blob_name3, snapshot: snapshot2, previous_snapshot: snapshot1
      ranges.length.must_equal 1
      ranges[0][0].must_equal 2048
      ranges[0][1].must_equal 2559
    end

    it "lease id works for list_page_blob_ranges" do
      # initialize the blob
      page_blob_name = BlobNameHelper.name
      subject.create_page_blob container_name, page_blob_name, length
      content_512B = SecureRandom.random_bytes(512)
      subject.put_blob_pages container_name, page_blob_name, 0, 511, content_512B
      subject.put_blob_pages container_name, page_blob_name, 1024, 1535, content_512B
      subject.put_blob_pages container_name, page_blob_name, 2048, 2559, content_512B
      # acquire lease for blob
      lease_id = subject.acquire_blob_lease container_name, page_blob_name
      subject.release_blob_lease container_name, page_blob_name, lease_id
      new_lease_id = subject.acquire_blob_lease container_name, page_blob_name
      # assert wrong lease fails
      status_code = ""
      description = ""
      begin
        ranges = subject.list_page_blob_ranges container_name, page_blob_name, lease_id: lease_id
      rescue Azure::Core::Http::HTTPError => e
        status_code = e.status_code.to_s
        description = e.description
      end
      status_code.must_equal "412"
      description.must_include "The lease ID specified did not match the lease ID for the blob."
      # assert correct lease works
      ranges = subject.list_page_blob_ranges container_name, page_blob_name, lease_id: new_lease_id
      ranges.length.must_equal 3
      # assert no lease works
      ranges = subject.list_page_blob_ranges container_name, page_blob_name
      ranges.length.must_equal 3
    end
  end
end
