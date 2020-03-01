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

describe "Blob GB-18030" do
  subject { Azure::Storage::Blob::BlobService.create(SERVICE_CREATE_OPTIONS()) }
  after { ContainerNameHelper.clean }

  let(:container_name) { ContainerNameHelper.name }
  let(:blob_name) { "rubyblobname" }
  let(:length) { 1024 }

  before {
    subject.create_container container_name
    subject.create_page_blob container_name, blob_name, length
  }

  it "Read/Write Blob Container Name UTF-8" do
    # Expected results: Failure, because the Blob
    # container name can only contain ASCII
    # characters, per the Blob Service spec.
    GB18030TestStrings.get.each { |k, v|
      begin
        subject.create_container container_name + v.encode("UTF-8")
        flunk "No exception"
      rescue
        # Add validation?
      end
    }
  end

  it "Read/Write Blob Container Name GB-18030" do
    # Expected results: Failure, because the Blob
    # container name can only contain ASCII
    # characters, per the Blob Service spec.
    GB18030TestStrings.get.each { |k, v|
      begin
        subject.create_container container_name + v.encode("GB18030")
        flunk "No exception"
      rescue
        # Add validation?
      end
    }
  end

  it "Read/Write Blob Name UTF-8" do
    container_name = ContainerNameHelper.name
    subject.create_container container_name
    GB18030TestStrings.get.each { |k, v|
      # The Blob service does not support characters from extended plains.
      if k != "ChineseExtB" then
        test_name = container_name + v.encode("UTF-8")
        subject.create_block_blob container_name, test_name, "hi"
        blobs = subject.list_blobs container_name
        blobs.each { |value|
          _(value.name).must_equal test_name
        }
        subject.delete_blob container_name, test_name
      end
    }
  end

  # Fails because of https://github.com/appfog/azure-sdk-for-ruby/issues/293
  it "Read/Write Blob Name GB18030" do
    container_name = ContainerNameHelper.name
    subject.create_container container_name
    GB18030TestStrings.get.each { |k, v|
      # The Blob service does not support characters from extended plains.
      if k != "ChineseExtB" then
        test_name = container_name + v.encode("GB18030")
        subject.create_block_blob container_name, test_name, "hi"
        blobs = subject.list_blobs container_name
        blobs.each { |value|
          _(value.name.encode("UTF-8")).must_equal test_name.encode("UTF-8")
        }
        subject.delete_blob container_name, test_name
      end
    }
  end

  it "Read/Write Blob Metadata UTF-8 key" do
    GB18030TestStrings.get.each { |k, v|
      begin
        metadata = { "custommetadata" + v.encode("UTF-8") => "CustomMetadataValue" }
        subject.set_blob_metadata container_name, blob_name, metadata
        flunk "No exception"
      rescue Azure::Core::Http::HTTPError => error
        _(error.status_code).must_equal 400
      end
    }
  end

  it "Read/Write Blob Metadata GB-18030 key" do
    GB18030TestStrings.get.each { |k, v|
      begin
        metadata = { "custommetadata" + v.encode("GB18030") => "CustomMetadataValue" }
        subject.set_blob_metadata container_name, blob_name, metadata
        flunk "No exception"
      rescue Azure::Core::Http::HTTPError => error
        _(error.status_code).must_equal 400
      end
    }
  end

  it "Read/Write Blob Metadata UTF-8 value" do
    GB18030TestStrings.get.each { |k, v|
      begin
        metadata = { "custommetadata" => "CustomMetadataValue" + v.encode("UTF-8") }
        subject.set_blob_metadata container_name, blob_name, metadata
        flunk "No exception"
      rescue Azure::Core::Http::HTTPError => error
        # TODO: Error should really be 400
        _(error.status_code).must_equal 403
      end
    }
  end

  it "Read/Write Blob Metadata GB-18030 value" do
    GB18030TestStrings.get.each { |k, v|
      begin
        metadata = { "custommetadata" => "CustomMetadataValue" + v.encode("GB18030") }
        subject.set_blob_metadata container_name, blob_name, metadata
        flunk "No exception"
      rescue Azure::Core::Http::HTTPError => error
        # TODO: Error should really be 400
        _(error.status_code).must_equal 403
      end
    }
  end

  it "Read/Write Blob Block Content UTF-8 with auto charset" do
    GB18030TestStrings.get.each { |k, v|
      blob_name = "Read/Write Block Blob Content UTF-8 for " + k
      content = v.encode("UTF-8")
      subject.create_block_blob container_name, blob_name, content
      blob, returned_content = subject.get_blob container_name, blob_name
      _(returned_content).must_equal content
    }
  end

  it "Read/Write Blob Block Content GB18030 with explicit charset" do
    GB18030TestStrings.get.each { |k, v|
      blob_name = "Read/Write Block Blob Content GB18030 for " + k
      content = v.encode("GB18030")
      options = { content_type: "text/html; charset=GB18030" }
      subject.create_block_blob container_name, blob_name, content, options
      blob, returned_content = subject.get_blob container_name, blob_name
      charset = blob.properties[:content_type][blob.properties[:content_type].index("charset=") + "charset=".length...blob.properties[:content_type].length]
      returned_content.force_encoding(charset)
      _(returned_content).must_equal content
    }
  end

  it "Read/Write Blob Page Content UTF-8 with explicit charset" do
    GB18030TestStrings.get.each { |k, v|
      blob_name = "Read/Write Page Blob Content UTF-8 for " + k
      options = { content_type: "text/html; charset=UTF-8" }
      content = v.encode("UTF-8")
      while content.bytesize < 512 do
        content << "X"
      end
      subject.create_page_blob container_name, blob_name, 512, options
      subject.put_blob_pages container_name, blob_name, 0, 511, content
      blob, returned_content = subject.get_blob container_name, blob_name
      charset = blob.properties[:content_type][blob.properties[:content_type].index("charset=") + "charset=".length...blob.properties[:content_type].length]
      returned_content.force_encoding(charset)
      _(returned_content).must_equal content
    }
  end

  it "Read/Write Blob Page Content GB18030 with explicit charset" do
    GB18030TestStrings.get.each { |k, v|
      blob_name = "Read/Write Page Blob Content GB18030 for " + k
      options = { content_type: "text/html; charset=GB18030" }
      content = v.encode("GB18030")
      while content.bytesize < 512 do
        content << "X"
      end
      subject.create_page_blob container_name, blob_name, 512, options
      subject.put_blob_pages container_name, blob_name, 0, 511, content
      blob, returned_content = subject.get_blob container_name, blob_name
      charset = blob.properties[:content_type][blob.properties[:content_type].index("charset=") + "charset=".length...blob.properties[:content_type].length]
      returned_content.force_encoding(charset)
      _(returned_content).must_equal content
    }
  end
end
