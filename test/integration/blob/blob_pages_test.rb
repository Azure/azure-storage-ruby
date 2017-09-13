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
  subject { Azure::Storage::Blob::BlobService.new }
  after { ContainerNameHelper.clean }

  let(:container_name) { ContainerNameHelper.name }
  let(:blob_name) { "blobname" }
  let(:blob_name2) { "blobname2" }
  let(:length) { 2560 }
  before {
    subject.create_container container_name
    subject.create_page_blob container_name, blob_name, length
    subject.create_page_blob container_name, blob_name2, length
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
  end

  describe "when the options hash is used" do
    it "if none match is specified" do
      content = ""
      512.times.each { |i| content << "@" }

      blob = subject.put_blob_pages container_name, blob_name2, 0, 511, content

      assert_raises(Azure::Core::Http::HTTPError) do
        subject.put_blob_pages container_name, blob_name2, 1024, 1535, content, if_none_match: blob.properties[:etag]
      end
    end

    it "if match is specified" do
      content = ""
      512.times.each { |i| content << "@" }

      blob = subject.put_blob_pages container_name, blob_name, 0, 511, content
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
  end
end
