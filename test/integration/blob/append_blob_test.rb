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

describe Azure::Storage::Blob::BlobService do
  subject { Azure::Storage::Blob::BlobService.create(SERVICE_CREATE_OPTIONS()) }
  after { ContainerNameHelper.clean }

  let(:container_name) { ContainerNameHelper.name }
  let(:blob_name) { "blobname" }

  describe "#create_append_blob_with_content" do
    before {
      subject.create_container container_name
    }

    it "1MB string payload with 512K max size fails" do
      length = 1 * 1024 * 1024
      maxSize = 512 * 1024
      content = SecureRandom.random_bytes(length)
      blob_name = BlobNameHelper.name
      exception = assert_raises(Azure::Storage::Common::Core::StorageError) do
        subject.create_append_blob_from_content container_name, blob_name, content, max_size: maxSize
      end
      _(exception.message).must_include("Given content has exceeded the specified maximum size for the blob.")
    end

    it "4MB + 1 byte IO with no 'size' and 4MB max size fails with max size condition not met" do
      class LocalFakeString
        def initialize(string)
          @string = StringIO.new(string)
        end
        def read(length)
          @string.read(length)
        end
        def eof?
          @string.eof?
        end
      end
      length = 4 * 1024 * 1024 + 1
      maxSize = length - 1
      content = LocalFakeString.new(SecureRandom.random_bytes(length))
      blob_name = BlobNameHelper.name
      exception = assert_raises(Azure::Core::Http::HTTPError) do
        subject.create_append_blob_from_content container_name, blob_name, content, max_size: maxSize
      end
      _(exception.status_code).must_equal 412
      _(exception.message).must_include("MaxBlobSizeConditionNotMet")
    end

    it "4MB string payload with 4MB max size and duplicate request fails" do
      length = 4 * 1024 * 1024
      content = SecureRandom.random_bytes(length)
      blob_name = BlobNameHelper.name
      tempSubject = subject.clone
      # Use duplicate request filter to simulate the retry scenario
      tempSubject.with_filter(Azure::Storage::DuplicateRequestFilter.new)
      exception = assert_raises(Azure::Core::Http::HTTPError) do
        tempSubject.create_append_blob_from_content container_name, blob_name, content, max_size: length
      end
      _(exception.status_code).must_equal 412
      _(exception.message).must_include("AppendPositionConditionNotMet")
    end

    it "1MB string payload works" do
      length = 1 * 1024 * 1024
      content = SecureRandom.random_bytes(length)
      content.force_encoding "utf-8"
      blob_name = BlobNameHelper.name
      subject.create_append_blob_from_content container_name, blob_name, content
      blob, body = subject.get_blob(container_name, blob_name)
      _(blob.name).must_equal blob_name
      _(blob.properties[:content_length]).must_equal length
      _(blob.properties[:content_type]).must_equal "text/plain; charset=UTF-8"
      _(Digest::MD5.hexdigest(body)).must_equal Digest::MD5.hexdigest(content)
    end

    it "4MB string payload works" do
      length = 4 * 1024 * 1024
      content = SecureRandom.random_bytes(length)
      blob_name = BlobNameHelper.name
      subject.create_page_blob_from_content container_name, blob_name, length, content
      blob, body = subject.get_blob(container_name, blob_name)
      _(blob.name).must_equal blob_name
      _(blob.properties[:content_length]).must_equal length
      _(blob.properties[:content_type]).must_equal "text/plain; charset=ASCII-8BIT"
      _(Digest::MD5.hexdigest(body)).must_equal Digest::MD5.hexdigest(content)
    end

    it "5MB string payload works" do
      length = 5 * 1024 * 1024
      content = SecureRandom.random_bytes(length)
      blob_name = BlobNameHelper.name
      subject.create_append_blob_from_content container_name, blob_name, content
      blob, body = subject.get_blob(container_name, blob_name)
      _(blob.name).must_equal blob_name
      _(blob.properties[:content_length]).must_equal length
      _(Digest::MD5.hexdigest(body)).must_equal Digest::MD5.hexdigest(content)
    end

    it "IO payload works" do
      begin
        content = SecureRandom.hex(3 * 1024 * 1024)
        length = content.size
        blob_name = BlobNameHelper.name
        file = File.open blob_name, "w+"
        file.write content
        file.seek 0
        subject.create_append_blob_from_content container_name, blob_name, file
        blob, body = subject.get_blob(container_name, blob_name)
        _(blob.name).must_equal blob_name
        _(blob.properties[:content_length]).must_equal length
        _(Digest::MD5.hexdigest(body)).must_equal Digest::MD5.hexdigest(content)
      ensure
        unless file.nil?
          file.close
          File.delete blob_name
        end
      end
    end
  end

  describe "#create_append_blob" do
    let(:complex_blob_name) { 'qa-872053-/*"\'&.({[<+ ' + [ 0x7D, 0xEB, 0x8B, 0xA4].pack("U*") + "_" + "0" }

    before {
      subject.create_container container_name
    }

    it "creates an append blob" do
      blob = subject.create_append_blob container_name, blob_name
      _(blob.name).must_equal blob_name
      _(is_boolean(blob.encrypted)).must_equal true
    end

    it "creates an append blob with complex name" do
      blob = subject.create_append_blob container_name, complex_blob_name
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

      blob = subject.create_append_blob container_name, blob_name, options
      _(is_boolean(blob.encrypted)).must_equal true
      blob = subject.get_blob_properties container_name, blob_name
      _(blob.name).must_equal blob_name
      _(is_boolean(blob.encrypted)).must_equal true
      _(blob.properties[:blob_type]).must_equal "AppendBlob"
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
        subject.create_append_blob ContainerNameHelper.name, blob_name
      end
    end

    it "lease id works for create_append_blob" do
      append_blob_name = BlobNameHelper.name
      subject.create_append_blob container_name, append_blob_name
      # acquire lease for blob
      lease_id = subject.acquire_blob_lease container_name, append_blob_name
      # assert no lease fails
      status_code = ""
      description = ""
      begin
        subject.create_append_blob container_name, append_blob_name
      rescue Azure::Core::Http::HTTPError => e
        status_code = e.status_code.to_s
        description = e.description
      end
      _(status_code).must_equal "412"
      _(description).must_include "There is currently a lease on the blob and no lease ID was specified in the request."
      # assert correct lease works
      blob = subject.create_append_blob container_name, append_blob_name, lease_id: lease_id
      _(blob.name).must_equal append_blob_name
    end
  end

  describe "#append_blob_block" do
    let(:content) { content = ""; 512.times.each { |i| content << "@" }; content }
    let(:blob_name) { BlobNameHelper.name }

    before {
      subject.create_container container_name
    }

    it "appends a block as part of an append blob" do
      subject.create_append_blob container_name, blob_name

      options = { content_md5: Base64.strict_encode64(Digest::MD5.digest(content)) }
      blob = subject.append_blob_block container_name, blob_name, content, options
      _(is_boolean(blob.encrypted)).must_equal true

      # verify
      _(blob.properties[:content_md5]).must_equal Base64.strict_encode64(Digest::MD5.digest(content))
      _(blob.properties[:append_offset]).must_equal 0

      blob = subject.get_blob_properties container_name, blob_name
      _(is_boolean(blob.encrypted)).must_equal true
      _(blob.properties[:blob_type]).must_equal "AppendBlob"
      _(blob.properties[:content_length]).must_equal 512
      _(blob.properties[:committed_count]).must_equal 1

      # append another and verify
      blob = subject.append_blob_block container_name, blob_name, content
      _(blob.properties[:append_offset]).must_equal 512
      _(blob.properties[:committed_count]).must_equal 2
    end

    it "appends a block as part of an append blob with wrong MD5" do
      blob_name = BlobNameHelper.name
      subject.create_append_blob container_name, blob_name

      exception = assert_raises(Azure::Core::Http::HTTPError) do
        options = { content_md5: "aaaaaa==" }
        subject.append_blob_block container_name, blob_name, content, options
      end
      refute_nil(exception.message.index "InvalidMd5 (400): The MD5 value specified in the request is invalid")
    end

    it "appends a block as part of an append blob with maximum size" do
      blob_name = BlobNameHelper.name
      subject.create_append_blob container_name, blob_name

      options = { max_size: 600.to_s }
      blob = subject.append_blob_block container_name, blob_name, content, options
      _(is_boolean(blob.encrypted)).must_equal true
      _(blob.properties[:append_offset]).must_equal 0
      _(blob.properties[:committed_count]).must_equal 1

      exception = assert_raises(Azure::Core::Http::HTTPError) do
        subject.append_blob_block container_name, blob_name, content, options
      end
      refute_nil(exception.message.index "MaxBlobSizeConditionNotMet (412): The max blob size condition specified was not met")
    end

    it "appends a block as part of an append blob with append postion" do
      blob_name = BlobNameHelper.name
      subject.create_append_blob container_name, blob_name

      blob = subject.append_blob_block container_name, blob_name, content
      _(is_boolean(blob.encrypted)).must_equal true
      _(blob.properties[:append_offset]).must_equal 0
      _(blob.properties[:committed_count]).must_equal 1

      options = { append_position: 512.to_s }
      blob = subject.append_blob_block container_name, blob_name, content, options
      _(is_boolean(blob.encrypted)).must_equal true
      _(blob.properties[:append_offset]).must_equal 512
      _(blob.properties[:committed_count]).must_equal 2

      exception = assert_raises(Azure::Core::Http::HTTPError) do
        subject.append_blob_block container_name, blob_name, content, options
      end
      refute_nil(exception.message.index "AppendPositionConditionNotMet (412): The append position condition specified was not met")
    end

    it "lease id works for append_blob_block" do
      append_blob_name = BlobNameHelper.name
      subject.create_append_blob container_name, append_blob_name
      # acquire lease for blob
      lease_id = subject.acquire_blob_lease container_name, append_blob_name
      # assert no lease fails
      status_code = ""
      description = ""
      begin
        subject.append_blob_block container_name, append_blob_name, content
      rescue Azure::Core::Http::HTTPError => e
        status_code = e.status_code.to_s
        description = e.description
      end
      _(status_code).must_equal "412"
      _(description).must_include "There is currently a lease on the blob and no lease ID was specified in the request."
      # assert correct lease works
      blob = subject.append_blob_block container_name, append_blob_name, content, lease_id: lease_id

      _(blob.properties[:content_md5]).must_equal Base64.strict_encode64(Digest::MD5.digest(content))
      _(blob.properties[:append_offset]).must_equal 0

      blob = subject.get_blob_properties container_name, append_blob_name
      _(is_boolean(blob.encrypted)).must_equal true
      _(blob.properties[:blob_type]).must_equal "AppendBlob"
      _(blob.properties[:content_length]).must_equal 512
      _(blob.properties[:committed_count]).must_equal 1
    end
  end
end
