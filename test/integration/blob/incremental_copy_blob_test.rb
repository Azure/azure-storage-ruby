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
require "securerandom"
require "time"

class MockBlobService < Azure::Storage::Blob::BlobService
  def containers_uri(query = {}, options = {})
    super
  end

  def container_uri(name, query = {}, options = {})
    super
  end

  def blob_uri(container_name, blob_name, query = {}, options = {})
    super
  end
end

describe Azure::Storage::Blob::BlobService do
  subject { MockBlobService.new(SERVICE_CREATE_OPTIONS()) }

  let(:container_name) { ContainerNameHelper.name }
  let(:source_page_blob) { BlobNameHelper.name }
  let(:length) { 1024 }
  let(:content) { SecureRandom.random_bytes(512) }
  let(:incremental_content) { SecureRandom.random_bytes(512) }

  before do
    #create a container and a page blob, then set the blob to be public readable.
    subject.create_container container_name
    subject.set_container_acl container_name, "blob"
    subject.create_page_blob container_name, source_page_blob, length
    subject.put_blob_pages container_name, source_page_blob, 0, 511, content
    @snapshot1 = subject.create_blob_snapshot container_name, source_page_blob
    subject.put_blob_pages container_name, source_page_blob, 512, 1023, incremental_content
    @source_uri1 = subject.blob_uri(container_name, source_page_blob, "snapshot" => @snapshot1)
    @snapshot2 = subject.create_blob_snapshot container_name, source_page_blob
    subject.put_blob_pages container_name, source_page_blob, 0, 511, incremental_content
    @source_uri2 = subject.blob_uri(container_name, source_page_blob, "snapshot" => @snapshot2)
  end

  after { ContainerNameHelper.clean }

  describe "Test Incremental Snapshots" do
    it "test incremental snapshot can work" do
      dest_blob_name = BlobNameHelper.name
      result = subject.incremental_copy_blob container_name, dest_blob_name, @source_uri1.to_s
      _(result[1]).must_equal "pending"
      blob = subject.get_blob_properties(container_name, dest_blob_name)
      _(blob.properties[:incremental_copy]).must_equal true
    end

    it "test incremental snapshot fails on existing blob" do
      dest_blob_name = BlobNameHelper.name
      subject.create_page_blob(container_name, dest_blob_name, length)
      e = assert_raises Azure::Core::Http::HTTPError do
        subject.incremental_copy_blob container_name, dest_blob_name, @source_uri1.to_s
      end
      _(e.status_code).must_equal 409
      _(e.type).must_equal "OperationNotAllowedOnIncrementalCopyBlob"
    end

    it "test 'if_modified_since' work" do
      dest_blob_name = BlobNameHelper.name
      result = subject.incremental_copy_blob container_name, dest_blob_name, @source_uri1.to_s
      _(result[1]).must_equal "pending"
      blob = subject.get_blob_properties(container_name, dest_blob_name)
      _(blob.properties[:incremental_copy]).must_equal true
      # test failing case for if_modified_since
      now = Time.new + 1
      e = assert_raises Azure::Core::Http::HTTPError do
        subject.incremental_copy_blob container_name, dest_blob_name, @source_uri2.to_s, if_modified_since: now.httpdate
      end
      _(e.status_code).must_equal 412
      _(e.type).must_equal "ConditionNotMet"
      now -= 65535 # Should be a long time that makes sense
      # test success case for if_modified_since
      copy_id = subject.incremental_copy_blob container_name, dest_blob_name, @source_uri2.to_s, if_modified_since: now.httpdate
      _(copy_id).wont_be_nil
    end

    it "test 'if_unmodified_since' work" do
      dest_blob_name = BlobNameHelper.name
      result = subject.incremental_copy_blob container_name, dest_blob_name, @source_uri1.to_s
      _(result[1]).must_equal "pending"
      blob = subject.get_blob_properties(container_name, dest_blob_name)
      _(blob.properties[:incremental_copy]).must_equal true
      # test failing case for if_unmodified_since
      now = Time.new - 65535 # Should be a long time that makes sense
      e = assert_raises Azure::Core::Http::HTTPError do
        subject.incremental_copy_blob container_name, dest_blob_name, @source_uri2.to_s, if_unmodified_since: now.httpdate
      end
      _(e.status_code).must_equal 412
      _(e.type).must_equal "ConditionNotMet"
      now += 65536 # Should be a long time that makes sense
      # test success case for if_unmodified_since
      copy_id = subject.incremental_copy_blob container_name, dest_blob_name, @source_uri2.to_s, if_unmodified_since: now.httpdate
      _(copy_id).wont_be_nil
    end

    it "test 'if_match' work" do
      dest_blob_name = BlobNameHelper.name
      result = subject.incremental_copy_blob container_name, dest_blob_name, @source_uri1.to_s
      _(result[1]).must_equal "pending"
      blob = subject.get_blob_properties(container_name, dest_blob_name)
      _(blob.properties[:incremental_copy]).must_equal true
      etag = blob.properties[:etag]
      _(etag).wont_be_nil
      # test failing case for if_match
      e = assert_raises Azure::Core::Http::HTTPError do
        subject.incremental_copy_blob container_name, dest_blob_name, @source_uri2.to_s, if_match: etag + "blablabla"
      end
      _(e.status_code).must_equal 412
      _(e.type).must_equal "TargetConditionNotMet"
      # test success case for if_match
      copy_id = subject.incremental_copy_blob container_name, dest_blob_name, @source_uri2.to_s, if_match: etag
      _(copy_id).wont_be_nil
    end

    it "test 'if_none_match' work" do
      dest_blob_name = BlobNameHelper.name
      result = subject.incremental_copy_blob container_name, dest_blob_name, @source_uri1.to_s
      _(result[1]).must_equal "pending"
      blob = subject.get_blob_properties(container_name, dest_blob_name)
      _(blob.properties[:incremental_copy]).must_equal true
      etag = blob.properties[:etag]
      _(etag).wont_be_nil
      # test failing case for if_none_match
      e = assert_raises Azure::Core::Http::HTTPError do
        subject.incremental_copy_blob container_name, dest_blob_name, @source_uri2.to_s, if_none_match: etag
      end
      _(e.status_code).must_equal 412
      _(e.type).must_equal "ConditionNotMet"
      # test success case for if_none_match
      copy_id = subject.incremental_copy_blob container_name, dest_blob_name, @source_uri2.to_s, if_none_match: etag + "blablabla"
      _(copy_id).wont_be_nil
    end

    it "lease id works for incremental_copy_blob" do
      dest_blob_name = BlobNameHelper.name
      result = subject.incremental_copy_blob container_name, dest_blob_name, @source_uri1.to_s
      _(result[1]).must_equal "pending"
      blob = subject.get_blob_properties(container_name, dest_blob_name)
      _(blob.properties[:incremental_copy]).must_equal true
      # acquire lease for blob
      lease_id = subject.acquire_blob_lease container_name, dest_blob_name
      subject.release_blob_lease container_name, dest_blob_name, lease_id
      new_lease_id = subject.acquire_blob_lease container_name, dest_blob_name

      # assert wrong lease fails
      status_code = ""
      description = ""
      begin
        result = subject.incremental_copy_blob container_name, dest_blob_name, @source_uri2.to_s, lease_id: lease_id
      rescue Azure::Core::Http::HTTPError => e
        status_code = e.status_code.to_s
        description = e.description
      end
      _(status_code).must_equal "412"
      _(description).must_include "The lease ID specified did not match the lease ID for the blob."
      # assert correct lease works
      copy_id = subject.incremental_copy_blob container_name, dest_blob_name, @source_uri2.to_s, lease_id: new_lease_id
      _(copy_id).wont_be_nil
    end
  end
end
