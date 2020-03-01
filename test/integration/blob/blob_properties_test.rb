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

  describe "#set/get_blob_properties" do
    let(:container_name) { ContainerNameHelper.name }
    let(:blob_name) { "blobname" }
    let(:length) { 1024 }
    before {
      subject.create_container container_name
      subject.create_page_blob container_name, blob_name, length
    }
    let(:options) { {
        content_type: "application/my-special-format",
        content_encoding: "gzip",
        content_language: "klingon",
        cache_control: "max-age=1296000",
      }}

    it "sets and gets properties for a blob" do
      result = subject.set_blob_properties container_name, blob_name, options
      _(result).must_be_nil
      blob = subject.get_blob_properties container_name, blob_name
      _(blob.properties[:content_type]).must_equal options[:content_type]
      _(blob.properties[:content_encoding]).must_equal options[:content_encoding]
      _(blob.properties[:cache_control]).must_equal options[:cache_control]
    end

    describe "when a blob has a snapshot" do
      before {
        subject.set_blob_properties container_name, blob_name, options
      }

      it "gets properties for a blob snapshot" do
        snapshot = subject.create_blob_snapshot container_name, blob_name
        blob = subject.get_blob_properties container_name, blob_name, snapshot: snapshot

        _(blob.snapshot).must_equal snapshot
        _(blob.properties[:content_type]).must_equal options[:content_type]
        _(blob.properties[:content_encoding]).must_equal options[:content_encoding]
        _(blob.properties[:cache_control]).must_equal options[:cache_control]
      end

      it "errors if the snapshot does not exist" do
        assert_raises(Azure::Core::Http::HTTPError) do
          subject.get_blob_properties container_name, blob_name, snapshot: "invalidsnapshot"
        end
      end
    end

    it "errors if the blob name does not exist" do
      assert_raises(Azure::Core::Http::HTTPError) do
        subject.get_blob_properties container_name, "thisblobdoesnotexist"
      end
      assert_raises(Azure::Core::Http::HTTPError) do
        subject.get_blob_properties container_name, "thisblobdoesnotexist", options
      end
    end

    it "lease id works for get_blob_properties" do
      page_blob_name = BlobNameHelper.name
      subject.create_page_blob container_name, page_blob_name, length
      subject.set_blob_properties container_name, page_blob_name, options
      # add lease to blob
      lease_id = subject.acquire_blob_lease container_name, page_blob_name
      subject.release_blob_lease container_name, page_blob_name, lease_id
      new_lease_id = subject.acquire_blob_lease container_name, page_blob_name
      # assert wrong lease fails
      status_code = ""
      description = ""
      begin
        blob = subject.get_blob_properties container_name, page_blob_name, lease_id: lease_id
      rescue Azure::Core::Http::HTTPError => e
        status_code = e.status_code.to_s
        description = e.description
      end
      _(status_code).must_equal "412"
      # assert right lease succeeds
      blob = subject.get_blob_properties container_name, page_blob_name, lease_id: new_lease_id
      _(blob).wont_be_nil
      _(blob.properties[:content_type]).must_equal options[:content_type]
      _(blob.properties[:content_encoding]).must_equal options[:content_encoding]
      _(blob.properties[:cache_control]).must_equal options[:cache_control]
      # assert no lease succeeds
      blob = subject.get_blob_properties container_name, page_blob_name
      _(blob).wont_be_nil
      _(blob.properties[:content_type]).must_equal options[:content_type]
      _(blob.properties[:content_encoding]).must_equal options[:content_encoding]
      _(blob.properties[:cache_control]).must_equal options[:cache_control]
    end

    it "lease id works for set_blob_properties" do
      page_blob_name = BlobNameHelper.name
      subject.create_page_blob container_name, page_blob_name, length
      # add lease to blob
      lease_id = subject.acquire_blob_lease container_name, page_blob_name
      subject.release_blob_lease container_name, page_blob_name, lease_id
      new_lease_id = subject.acquire_blob_lease container_name, page_blob_name
      # assert wrong lease fails
      status_code = ""
      description = ""
      begin
        blob = subject.set_blob_properties container_name, page_blob_name, options.merge(lease_id: lease_id)
      rescue Azure::Core::Http::HTTPError => e
        status_code = e.status_code.to_s
        description = e.description
      end
      _(status_code).must_equal "412"
      _(description).must_include "The lease ID specified did not match the lease ID for the blob."
      # assert right lease succeeds
      result = subject.set_blob_properties container_name, page_blob_name, options.merge(lease_id: new_lease_id)
      _(result).must_be_nil
      blob = subject.get_blob_properties container_name, page_blob_name
      _(blob).wont_be_nil
      _(blob.properties[:content_type]).must_equal options[:content_type]
      _(blob.properties[:content_encoding]).must_equal options[:content_encoding]
      _(blob.properties[:cache_control]).must_equal options[:cache_control]
      # prove that no lease fails
      status_code = ""
      description = ""
      begin
        blob = subject.set_blob_properties container_name, page_blob_name, options
      rescue Azure::Core::Http::HTTPError => e
        status_code = e.status_code.to_s
        description = e.description
      end
      _(status_code).must_equal "412"
      _(description).must_include "There is currently a lease on the blob and no lease ID was specified in the request."
    end
  end
end
