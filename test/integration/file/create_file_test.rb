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
require "azure/core/http/http_error"
require "integration/test_helper"

describe Azure::Storage::File::FileService do
  subject { Azure::Storage::File::FileService.create(SERVICE_CREATE_OPTIONS()) }
  after { ShareNameHelper.clean }

  describe "#create_file_from_content" do
    let(:share_name) { ShareNameHelper.name }
    let(:directory_name) { FileNameHelper.name }
    let(:file_name) { FileNameHelper.name }
    before {
      subject.create_share share_name
      subject.create_directory share_name, directory_name
    }

    it "1MB string payload works" do
      length = 1 * 1024 * 1024
      content = SecureRandom.random_bytes(length)
      content.force_encoding "utf-8"
      file_name = FileNameHelper.name
      subject.create_file_from_content share_name, directory_name, file_name, length, content
      file, body = subject.get_file(share_name, directory_name, file_name)
      _(file.name).must_equal file_name
      _(file.properties[:content_length]).must_equal length
      _(file.properties[:content_type]).must_equal "text/plain; charset=UTF-8"
      _(Digest::MD5.hexdigest(body)).must_equal Digest::MD5.hexdigest(content)
    end

    it "4MB string payload works" do
      length = 4 * 1024 * 1024
      content = SecureRandom.random_bytes(length)
      file_name = FileNameHelper.name
      subject.create_file_from_content share_name, directory_name, file_name, length, content
      file, body = subject.get_file(share_name, directory_name, file_name)
      _(file.name).must_equal file_name
      _(file.properties[:content_length]).must_equal length
      _(file.properties[:content_type]).must_equal "text/plain; charset=ASCII-8BIT"
      _(Digest::MD5.hexdigest(body)).must_equal Digest::MD5.hexdigest(content)
    end

    it "5MB string payload works" do
      length = 5 * 1024 * 1024
      content = SecureRandom.random_bytes(length)
      file_name = FileNameHelper.name
      subject.create_file_from_content share_name, directory_name, file_name, length, content
      file, body = subject.get_file(share_name, directory_name, file_name)
      _(file.name).must_equal file_name
      _(file.properties[:content_length]).must_equal length
      _(Digest::MD5.hexdigest(body)).must_equal Digest::MD5.hexdigest(content)
    end

    it "IO payload works" do
      begin
        content = SecureRandom.hex(3 * 1024 * 1024)
        length = content.size
        file_name = FileNameHelper.name
        local_file = File.open file_name, "w+"
        local_file.write content
        local_file.seek 0
        subject.create_file_from_content share_name, directory_name, file_name, length, local_file
        file, body = subject.get_file(share_name, directory_name, file_name)
        _(file.name).must_equal file_name
        _(file.properties[:content_length]).must_equal length
        _(Digest::MD5.hexdigest(body)).must_equal Digest::MD5.hexdigest(content)
      ensure
        unless local_file.nil?
          local_file.close
          File.delete file_name
        end
      end
    end
  end

  describe "#create_file" do
    let(:share_name) { ShareNameHelper.name }
    let(:directory_name) { FileNameHelper.name }
    let(:file_name) { FileNameHelper.name }
    let(:file_length) { 1024 }
    before {
      subject.create_share share_name
      subject.create_directory share_name, directory_name
    }

    it "creates the file" do
      file = subject.create_file share_name, directory_name, file_name, file_length
      _(file.name).must_equal file_name

      file = subject.get_file_properties share_name, directory_name, file_name
      _(file.properties[:content_length]).must_equal file_length
      _(file.properties[:content_type]).must_equal "application/octet-stream"
    end

    it "creates the file with custom metadata" do
      metadata = { "CustomMetadataProperty" => "CustomMetadataValue" }
      file = subject.create_file share_name, directory_name, file_name, file_length, metadata: metadata

      _(file.name).must_equal file_name
      _(file.metadata).must_equal metadata
      file = subject.get_file_metadata share_name, directory_name, file_name

      metadata.each { |k, v|
        _(file.metadata).must_include k.downcase
        _(file.metadata[k.downcase]).must_equal v
      }
    end

    it "no errors if the file already exists" do
      subject.create_file share_name, directory_name, file_name, file_length
      subject.create_file share_name, directory_name, file_name, file_length + file_length
      file = subject.get_file_properties share_name, directory_name, file_name
      _(file.name).must_equal file_name
      _(file.properties[:content_length]).must_equal file_length * 2
    end

    it "errors if the difilerectory name is invalid" do
      assert_raises(Azure::Core::Http::HTTPError) do
        subject.create_file share_name, directory_name, "this_file/cannot/exist!", file_length
      end
    end
  end
end
