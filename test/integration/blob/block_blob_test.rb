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
require "base64"
require "securerandom"

describe Azure::Storage::Blob::BlobService do
  subject { Azure::Storage::Blob::BlobService.new }
  after { ContainerNameHelper.clean }

  let(:container_name) { ContainerNameHelper.name }
  let(:blob_name) { "blobname" }
  let(:content) { content = ""; 512.times.each { |i| content << "@" }; content }
  before {
    subject.create_container container_name
  }

  describe "#create_block_blob" do
    it "creates a block blob" do
      blob = subject.create_block_blob container_name, blob_name, content
      blob.name.must_equal blob_name
    end

    it "creates a block blob with IO" do
      begin
        file = File.open blob_name, "w+"
        file.write content
        file.seek 0
        subject.create_block_blob container_name, blob_name, file
        blob = subject.get_blob_properties container_name, blob_name
        blob.name.must_equal blob_name
        blob.properties[:content_length].must_equal content.length
      ensure
        unless file.nil?
          file.close
          File.delete blob_name
        end
      end
    end

    it "should create a block blob with spaces in name" do
      blob_name = "blob with spaces"
      blob = subject.create_block_blob container_name, blob_name, "content"
      blob.name.must_equal blob_name
    end

    it "should create block blob with complex in name" do
      blob_name = "with фбаф.txt"
      blob = subject.create_block_blob container_name, blob_name, "content"
      blob.name.must_equal blob_name
    end

    it "sets additional properties when the options hash is used" do
      options = {
        content_type: "application/xml",
        content_encoding: "gzip",
        content_language: "en-US",
        cache_control: "max-age=1296000",
        metadata: { "CustomMetadataProperty" => "CustomMetadataValue" }
      }

      blob = subject.create_block_blob container_name, blob_name, content, options
      blob = subject.get_blob_properties container_name, blob_name
      blob.name.must_equal blob_name
      blob.properties[:blob_type].must_equal "BlockBlob"
      blob.properties[:content_type].must_equal options[:content_type]
      blob.properties[:content_encoding].must_equal options[:content_encoding]
      blob.properties[:cache_control].must_equal options[:cache_control]
      blob.metadata["custommetadataproperty"].must_equal "CustomMetadataValue"

      blob = subject.get_blob_metadata container_name, blob_name
      blob.name.must_equal blob_name
      blob.metadata["custommetadataproperty"].must_equal "CustomMetadataValue"
    end

    it "errors if the container does not exist" do
      assert_raises(Azure::Core::Http::HTTPError) do
        subject.create_block_blob ContainerNameHelper.name, blob_name, content
      end
    end
  end

  describe "#put_blob_block" do
    let(:blockid1) { "anyblockid1" }
    let(:blockid2) { "anyblockid2" }

    it "creates a block as part of a block blob" do
      subject.put_blob_block container_name, blob_name, blockid1, content

      # verify
      block_list = subject.list_blob_blocks container_name, blob_name
      block = block_list[:uncommitted][0]
      block.type.must_equal :uncommitted
      block.size.must_equal 512
      block.name.must_equal blockid1
    end

    it "creates a 100M block as part of a block blob" do
      content_100_mb = SecureRandom.random_bytes(100 * 1024 * 1024)
      subject.put_blob_block container_name, blob_name, blockid2, content_100_mb
      # verify
      block_list = subject.list_blob_blocks container_name, blob_name
      block = block_list[:uncommitted][0]
      block.type.must_equal :uncommitted
      block.size.must_equal 100 * 1024 * 1024
      block.name.must_equal blockid2
    end
  end

  describe "#commit_blob_blocks" do
    let(:blocklist) { [["anyblockid0"], ["anyblockid1"]] }
    before {
      blocklist.each { |block_entry|
        subject.put_blob_block container_name, blob_name, block_entry[0], content
      }
    }

    it "commits a list of blocks to blob" do
      # verify starting state
      block_list = subject.list_blob_blocks container_name, blob_name

      (0..1).each { |i|
        block = block_list[:uncommitted][i]
        block.type.must_equal :uncommitted
        block.size.must_equal 512
        block.name.must_equal blocklist[i][0]
      }

      assert_raises(Azure::Core::Http::HTTPError) do
        subject.get_blob container_name, blob_name
      end

      # commit blocks
      result = subject.commit_blob_blocks container_name, blob_name, blocklist
      result.must_be_nil

      blob, returned_content = subject.get_blob container_name, blob_name
      blob.properties[:content_length].must_equal (content.length * 2)
      returned_content.must_equal (content + content)
    end
  end

  describe "#list_blob_blocks" do
    let(:blocklist) { [["anyblockid0"], ["anyblockid1"], ["anyblockid2"], ["anyblockid3"]] }
    before {

      subject.put_blob_block container_name, blob_name, blocklist[0][0], content
      subject.put_blob_block container_name, blob_name, blocklist[1][0], content

      # two committed blocks, two uncommitted blocks
      result = subject.commit_blob_blocks container_name, blob_name, blocklist.slice(0..1)
      result.must_be_nil

      subject.put_blob_block container_name, blob_name, blocklist[2][0], content
      subject.put_blob_block container_name, blob_name, blocklist[3][0], content
    }

    it "lists blocks in a blob, including their status" do
      result = subject.list_blob_blocks container_name, blob_name

      committed = result[:committed]
      committed.length.must_equal 2

      expected_blocks = blocklist.slice(0..1).each

      committed.each { |block|
        block.name.must_equal expected_blocks.next[0]
        block.type.must_equal :committed
        block.size.must_equal 512
      }

      uncommitted = result[:uncommitted]
      uncommitted.length.must_equal 2

      expected_blocks = blocklist.slice(2..3).each

      uncommitted.each { |block|
        block.name.must_equal expected_blocks.next[0]
        block.type.must_equal :uncommitted
        block.size.must_equal 512
      }
    end

    describe "when blocklist_type parameter is used" do
      it "lists uncommitted blocks only if :uncommitted is passed" do
        result = subject.list_blob_blocks container_name, blob_name, blocklist_type: :uncommitted

        committed = result[:committed]
        committed.length.must_equal 0

        uncommitted = result[:uncommitted]
        uncommitted.length.must_equal 2

        expected_blocks = blocklist.slice(2..3).each

        uncommitted.each { |block|
          block.name.must_equal expected_blocks.next[0]
          block.type.must_equal :uncommitted
          block.size.must_equal 512
        }
      end

      it "lists committed blocks only if :committed is passed" do
        result = subject.list_blob_blocks container_name, blob_name, blocklist_type: :committed

        committed = result[:committed]
        committed.length.must_equal 2

        expected_blocks = blocklist.slice(0..1).each

        committed.each { |block|
          block.name.must_equal expected_blocks.next[0]
          block.type.must_equal :committed
          block.size.must_equal 512
        }

        uncommitted = result[:uncommitted]
        uncommitted.length.must_equal 0
      end

      it "lists committed and uncommitted blocks if :all is passed" do
        result = subject.list_blob_blocks container_name, blob_name, blocklist_type: :all

        committed = result[:committed]
        committed.length.must_equal 2

        expected_blocks = blocklist.slice(0..1).each

        committed.each { |block|
          block.name.must_equal expected_blocks.next[0]
          block.type.must_equal :committed
          block.size.must_equal 512
        }

        uncommitted = result[:uncommitted]
        uncommitted.length.must_equal 2

        expected_blocks = blocklist.slice(2..3).each

        uncommitted.each { |block|
          block.name.must_equal expected_blocks.next[0]
          block.type.must_equal :uncommitted
          block.size.must_equal 512
        }
      end
    end

    describe "when snapshot parameter is used" do
      it "lists blocks for the blob snapshot" do
        snapshot = subject.create_blob_snapshot container_name, blob_name

        result = subject.commit_blob_blocks container_name, blob_name, blocklist
        result.must_be_nil
        result = subject.list_blob_blocks container_name, blob_name

        committed = result[:committed]
        committed.length.must_equal 4
        expected_blocks = blocklist.each

        committed.each { |block|
          block.name.must_equal expected_blocks.next[0]
          block.type.must_equal :committed
          block.size.must_equal 512
        }

        result = subject.list_blob_blocks container_name, blob_name, blocklist_type: :all, snapshot: snapshot

        committed = result[:committed]
        committed.length.must_equal 2

        expected_blocks = blocklist.slice(0..1).each

        committed.each { |block|
          block.name.must_equal expected_blocks.next[0]
          block.type.must_equal :committed
          block.size.must_equal 512
        }

        # uncommitted blobs aren't copied in a snapshot.
        uncommitted = result[:uncommitted]
        uncommitted.length.must_equal 0
      end
    end
  end
end
