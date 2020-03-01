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
require "digest/md5"

describe Azure::Storage::File::FileService do
  subject { Azure::Storage::File::FileService.create(SERVICE_CREATE_OPTIONS()) }
  after { ShareNameHelper.clean }

  describe "#get_file" do
    let(:share_name) { ShareNameHelper.name }
    let(:directory_name) { FileNameHelper.name }
    let(:file_name) { "filename" }
    let(:file_length) { 1024 }
    let(:content) { content = ""; file_length.times.each { |i| content << "@" }; content }
    let(:metadata) { { "CustomMetadataProperty" => "CustomMetadataValue" } }
    let(:full_md5) { Digest::MD5.base64digest(content) }
    let(:options) { { content_type: "application/foo", metadata: metadata, content_md5: full_md5 } }

    before {
      subject.create_share share_name
      subject.create_directory share_name, directory_name
      subject.create_file share_name, directory_name, file_name, file_length, options
      subject.put_file_range share_name, directory_name, file_name, 0, file_length - 1, content
    }

    it "retrieves the file properties, metadata, and contents" do
      file, returned_content = subject.get_file share_name, directory_name, file_name
      _(returned_content).must_equal content
      _(file.metadata).must_include "custommetadataproperty"
      _(file.metadata["custommetadataproperty"]).must_equal "CustomMetadataValue"
      _(file.properties[:content_type]).must_equal "application/foo"
    end

    it "retrieves a range of data from the file" do
      file, returned_content = subject.get_file share_name, directory_name, file_name, start_range: 0, end_range: 511, get_content_md5: true
      _(returned_content.length).must_equal 512
      _(returned_content).must_equal content[0..511]
      _(file.properties[:range_md5]).must_equal Digest::MD5.base64digest(content[0..511])
      _(file.properties[:content_md5]).must_equal full_md5
    end
  end
end
