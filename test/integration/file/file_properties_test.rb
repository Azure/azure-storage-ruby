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

describe Azure::Storage::File::FileService do
  subject { Azure::Storage::File::FileService.create(SERVICE_CREATE_OPTIONS()) }
  after { ShareNameHelper.clean }

  describe "#set/get_file_properties" do
    let(:share_name) { ShareNameHelper.name }
    let(:directory_name) { FileNameHelper.name }
    let(:file_name) { FileNameHelper.name }
    let(:file_length) { 1024 }
    before {
      subject.create_share share_name
      subject.create_directory share_name, directory_name
      subject.create_file share_name, directory_name, file_name, file_length
    }
    let(:options) { {
      content_type: "application/my-special-format",
      content_encoding: "gzip",
      content_language: "klingon",
      content_md5: "5e1f7f9c28345d2b",
      content_disposition: "attachment",
      cache_control: "max-age=1296000",
    }}

    it "sets and gets properties for a file" do
      result = subject.set_file_properties share_name, directory_name, file_name, options
      _(result).must_be_nil
      file = subject.get_file_properties share_name, directory_name, file_name
      _(file.properties[:content_type]).must_equal options[:content_type]
      _(file.properties[:content_encoding]).must_equal options[:content_encoding]
      _(file.properties[:cache_control]).must_equal options[:cache_control]
      _(file.properties[:content_md5]).must_equal options[:content_md5]
      _(file.properties[:content_disposition]).must_equal options[:content_disposition]
    end

    it "resize a file" do
      result = subject.resize_file share_name, directory_name, file_name, file_length + file_length
      _(result).must_be_nil
      file = subject.get_file_properties share_name, directory_name, file_name
      _(file.properties[:content_length]).must_equal file_length * 2
    end

    it "resize a file should not change other properties" do
      result = subject.set_file_properties share_name, directory_name, file_name, options
      _(result).must_be_nil

      result = subject.resize_file share_name, directory_name, file_name, file_length + file_length
      _(result).must_be_nil
      file = subject.get_file_properties share_name, directory_name, file_name
      _(file.properties[:content_length]).must_equal file_length * 2
      _(file.properties[:content_type]).must_equal options[:content_type]
      _(file.properties[:content_encoding]).must_equal options[:content_encoding]
      _(file.properties[:cache_control]).must_equal options[:cache_control]
      _(file.properties[:content_md5]).must_equal options[:content_md5]
      _(file.properties[:content_disposition]).must_equal options[:content_disposition]
    end

    it "errors if the file name does not exist" do
      assert_raises(Azure::Core::Http::HTTPError) do
        subject.get_file_properties share_name, directory_name, "thisfiledoesnotexist"
      end
      assert_raises(Azure::Core::Http::HTTPError) do
        subject.get_file_properties share_name, directory_name, "thisfiledoesnotexist", options
      end
    end
  end
end
