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

describe "File GB-18030" do
  subject { Azure::Storage::File::FileService.create(SERVICE_CREATE_OPTIONS()) }
  after { ShareNameHelper.clean }

  let(:share_name) { ShareNameHelper.name }
  let(:directory_name) { FileNameHelper.name }
  let(:file_name) { "rubyfilename" }
  let(:file_length) { 64 }

  before {
    subject.create_share share_name
    subject.create_directory share_name, directory_name
    subject.create_file share_name, directory_name, file_name, file_length
  }

  it "Read/Write File Share Name UTF-8" do
    # Expected results: Failure, because the File
    # share name can only contain ASCII
    # characters, per the File Service spec.
    GB18030TestStrings.get.each { |k, v|
      begin
        subject.create_share share_name + v.encode("UTF-8")
        flunk "No exception"
      rescue
        # Add validation?
      end
    }
  end

  it "Read/Write File Share Name GB-18030" do
    # Expected results: Failure, because the File
    # share name can only contain ASCII
    # characters, per the File Service spec.
    GB18030TestStrings.get.each { |k, v|
      begin
        subject.create_share share_name + v.encode("GB18030")
        flunk "No exception"
      rescue
        # Add validation?
      end
    }
  end

  it "Read/Write File Name UTF-8" do
    share_name = ShareNameHelper.name
    subject.create_share share_name
    subject.create_directory share_name, directory_name

    GB18030TestStrings.get.each { |k, v|
      # The File service does not support characters from extended plains.
      if k != ("ChineseExtB") && k != ("Chinese2B5") then
        test_name = share_name + v.encode("UTF-8")
        subject.create_file share_name, directory_name, test_name, file_length
        files = subject.list_directories_and_files share_name, directory_name
        files.each { |value|
          _(value.name).must_equal test_name
        }
        subject.delete_file share_name, directory_name, test_name
      end
    }
  end

  # Fails because of https://github.com/appfog/azure-sdk-for-ruby/issues/293
  it "Read/Write File Name GB18030" do
    share_name = ShareNameHelper.name
    subject.create_share share_name
    subject.create_directory share_name, directory_name
    GB18030TestStrings.get.each { |k, v|
      # The File service does not support characters from extended plains.
      if k != ("ChineseExtB") && k != ("Chinese2B5") then
        test_name = share_name + v.encode("GB18030")
        subject.create_file share_name, directory_name, test_name, file_length
        files = subject.list_directories_and_files share_name, directory_name
        files.each { |value|
          _(value.name.encode("UTF-8")).must_equal test_name.encode("UTF-8")
        }
        subject.delete_file share_name, directory_name, test_name
      end
    }
  end

  it "Read/Write File Metadata UTF-8 key" do
    GB18030TestStrings.get.each { |k, v|
      begin
        metadata = { "custommetadata" + v.encode("UTF-8") => "CustomMetadataValue" }
        subject.set_file_metadata share_name, directory_name, file_name, metadata
        flunk "No exception"
      rescue Azure::Core::Http::HTTPError => error
        _(error.status_code).must_equal 400
      end
    }
  end

  it "Read/Write File Metadata GB-18030 key" do
    GB18030TestStrings.get.each { |k, v|
      begin
        metadata = { "custommetadata" + v.encode("GB18030") => "CustomMetadataValue" }
        subject.set_file_metadata share_name, directory_name, file_name, metadata
        flunk "No exception"
      rescue Azure::Core::Http::HTTPError => error
        _(error.status_code).must_equal 400
      end
    }
  end

  it "Read/Write File Metadata UTF-8 value" do
    GB18030TestStrings.get.each { |k, v|
      begin
        metadata = { "custommetadata" => "CustomMetadataValue" + v.encode("UTF-8") }
        subject.set_file_metadata share_name, directory_name, file_name, metadata
        flunk "No exception"
      rescue Azure::Core::Http::HTTPError => error
        # TODO: Error should really be 400
        _(error.status_code).must_equal 403
      end
    }
  end

  it "Read/Write File Metadata GB-18030 value" do
    GB18030TestStrings.get.each { |k, v|
      begin
        metadata = { "custommetadata" => "CustomMetadataValue" + v.encode("GB18030") }
        subject.set_file_metadata share_name, directory_name, file_name, metadata
        flunk "No exception"
      rescue Azure::Core::Http::HTTPError => error
        # TODO: Error should really be 400
        _(error.status_code).must_equal 403
      end
    }
  end

  it "Read/Write File Content UTF-8 with auto charset" do
    GB18030TestStrings.get.each { |k, v|
      file_name = "Read-Write File Content UTF-8 for " + k
      content = v.encode("UTF-8")
      subject.create_file share_name, directory_name, file_name, content.bytesize
      subject.put_file_range share_name, directory_name, file_name, 0, content.bytesize - 1, content
      file, returned_content = subject.get_file share_name, directory_name, file_name
      _(file.properties[:content_type]).must_equal "application/octet-stream"
      _(returned_content.force_encoding("UTF-8")).must_equal content
    }
  end

  it "Read/Write File Content GB18030 with explicit charset" do
    GB18030TestStrings.get.each { |k, v|
      file_name = "Read-Write File Content GB18030 for " + k
      content = v.encode("GB18030")
      options = { content_type: "text/html; charset=GB18030" }
      subject.create_file share_name, directory_name, file_name, content.bytesize, options
      subject.put_file_range share_name, directory_name, file_name, 0, content.bytesize - 1, content
      file, returned_content = subject.get_file share_name, directory_name, file_name
      charset = file.properties[:content_type][file.properties[:content_type].index("charset=") + "charset=".length...file.properties[:content_type].length]
      returned_content.force_encoding(charset)
      _(returned_content).must_equal content
    }
  end

  it "Read/Write 512 bytes UTF-8 with explicit charset" do
    GB18030TestStrings.get.each { |k, v|
      file_name = "Read-Write File Content UTF-8 for " + k
      options = { content_type: "text/html; charset=UTF-8" }
      content = v.encode("UTF-8")
      while content.bytesize < 512 do
        content << "X"
      end
      subject.create_file share_name, directory_name, file_name, 512, options
      subject.put_file_range share_name, directory_name, file_name, 0, 511, content
      file, returned_content = subject.get_file share_name, directory_name, file_name
      charset = file.properties[:content_type][file.properties[:content_type].index("charset=") + "charset=".length...file.properties[:content_type].length]
      returned_content.force_encoding(charset)
      _(returned_content).must_equal content
    }
  end

  it "Read/Write 512 bytes GB18030 with explicit charset" do
    GB18030TestStrings.get.each { |k, v|
      file_name = "Read-Write File Content GB18030 for " + k
      options = { content_type: "text/html; charset=GB18030" }
      content = v.encode("GB18030")
      while content.bytesize < 512 do
        content << "X"
      end
      subject.create_file share_name, directory_name, file_name, 512, options
      subject.put_file_range share_name, directory_name, file_name, 0, 511, content
      file, returned_content = subject.get_file share_name, directory_name, file_name
      charset = file.properties[:content_type][file.properties[:content_type].index("charset=") + "charset=".length...file.properties[:content_type].length]
      returned_content.force_encoding(charset)
      _(returned_content).must_equal content
    }
  end
end
