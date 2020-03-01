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

  describe "#create_page_blob" do
    let(:container_name) { ContainerNameHelper.name }
    let(:blob_name) { "blobname" }
    let(:complex_blob_name) { 'qa-872053-/*"\'&.({[<+ ' + [ 0x7D, 0xEB, 0x8B, 0xA4].pack("U*") + "_" + "0" }
    let(:length) { 1024 }
    before {
      subject.create_container container_name
    }

    it "creates a page blob" do
      blob = subject.create_page_blob container_name, blob_name, length
      _(blob.name).must_equal blob_name
      _(is_boolean(blob.encrypted)).must_equal true
      blob = subject.get_blob_properties container_name, blob_name
      _(blob.properties[:content_type]).must_equal "application/octet-stream"
    end

    it "creates page blob with non uri encoded path" do
      blob = subject.create_page_blob container_name, "фбаф.jpg", length
      _(blob.name).must_equal "фбаф.jpg"
      _(is_boolean(blob.encrypted)).must_equal true
    end

    it "creates a page blob with complex name" do
      blob = subject.create_page_blob container_name, complex_blob_name, length
      _(blob.name).must_equal complex_blob_name
      _(is_boolean(blob.encrypted)).must_equal true

      complex_blob_name.force_encoding("UTF-8")
      found_complex_name = false
      result = subject.list_blobs container_name
      result.each { |blob|
        found_complex_name = true if blob.name == complex_blob_name
      }

      _(found_complex_name).must_equal true
    end

    it "sets additional properties when the options hash is used" do
      options = {
        content_type: "application/xml",
        content_encoding: "gzip",
        content_language: "en-US",
        cache_control: "max-age=1296000",
        metadata: { "CustomMetadataProperty" => "CustomMetadataValue" }
      }

      blob = subject.create_page_blob container_name, blob_name, length, options
      blob = subject.get_blob_properties container_name, blob_name
      _(is_boolean(blob.encrypted)).must_equal true
      _(blob.name).must_equal blob_name
      _(blob.properties[:blob_type]).must_equal "PageBlob"
      _(blob.properties[:content_type]).must_equal options[:content_type]
      _(blob.properties[:content_encoding]).must_equal options[:content_encoding]
      _(blob.properties[:cache_control]).must_equal options[:cache_control]
      _(blob.metadata["custommetadataproperty"]).must_equal "CustomMetadataValue"

      blob = subject.get_blob_metadata container_name, blob_name
      _(blob.name).must_equal blob_name
      _(blob.metadata["custommetadataproperty"]).must_equal "CustomMetadataValue"
    end

    it "errors if the container does not exist" do
      assert_raises(Azure::Core::Http::HTTPError) do
        subject.create_page_blob ContainerNameHelper.name, blob_name, length
      end
    end

    it "errors if the length is not 512 byte aligned" do
      assert_raises(Azure::Core::Http::HTTPError) do
        subject.create_page_blob container_name, blob_name, length + 1
      end
    end

    it "lease id works for create_page_blob" do
      page_blob_name = BlobNameHelper.name
      subject.create_page_blob container_name, page_blob_name, length
      # acquire lease for blob
      lease_id = subject.acquire_blob_lease container_name, page_blob_name
      # assert no lease fails
      status_code = ""
      description = ""
      begin
        subject.create_page_blob container_name, page_blob_name, length
      rescue Azure::Core::Http::HTTPError => e
        status_code = e.status_code.to_s
        description = e.description
      end
      _(status_code).must_equal "412"
      _(description).must_include "There is currently a lease on the blob and no lease ID was specified in the request."
      # assert correct lease works
      blob = subject.create_page_blob container_name, page_blob_name, length, lease_id: lease_id
      _(blob.name).must_equal page_blob_name
    end
  end
end
