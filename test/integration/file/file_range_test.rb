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

  let(:share_name) { ShareNameHelper.name }
  let(:directory_name) { FileNameHelper.name }
  let(:file_name) { "filename" }
  let(:file_name2) { "filename2" }
  let(:file_length) { 2560 }
  before {
    subject.create_share share_name
    subject.create_directory share_name, directory_name
    subject.create_file share_name, directory_name, file_name, file_length
    subject.create_file share_name, directory_name, file_name2, file_length
  }

  describe "#put_file_range" do
    it "creates ranges in a file" do
      content = ""
      512.times.each { |i| content << "@" }

      subject.put_file_range share_name, directory_name, file_name, 0, 511, content
      subject.put_file_range share_name, directory_name, file_name, 1024, 1535, content

      file, ranges = subject.list_file_ranges share_name, directory_name, file_name, start_range: 0, end_range: 1536
      _(file.properties[:etag]).wont_be_nil
      _(file.properties[:last_modified]).wont_be_nil
      _(file.properties[:content_length]).must_equal file_length
      _(ranges[0][0]).must_equal 0
      _(ranges[0][1]).must_equal 511
      _(ranges[1][0]).must_equal 1024
      _(ranges[1][1]).must_equal 1535
    end
  end

  describe "when the options hash is used" do
    it "if transactional_md5 match is specified" do
      content = ""
      512.times.each { |i| content << "@" }

      file = subject.put_file_range share_name, directory_name, file_name, 0, 511, content
      subject.put_file_range share_name, directory_name, file_name, 1024, 1535, content, transactional_md5: Base64.strict_encode64(Digest::MD5.digest(content))
    end

    it "if transactional_md5 does not match" do
      content = ""
      512.times.each { |i| content << "@" }

      assert_raises(Azure::Core::Http::HTTPError) do
        file = subject.put_file_range share_name, directory_name, file_name2, 0, 511, content, transactional_md5: "2105b16a6714bd9d"
      end
    end
  end

  describe "#clear_file_ranges" do
    before {
      content = ""
      512.times.each { |i| content << "@" }

      subject.put_file_range share_name, directory_name, file_name, 0, 511, content
      subject.put_file_range share_name, directory_name, file_name, 1024, 1535, content
      subject.put_file_range share_name, directory_name, file_name, 2048, 2559, content

      file, ranges = subject.list_file_ranges share_name, directory_name, file_name, start_range: 0, end_range: 2560
      _(ranges.length).must_equal 3
      _(ranges[0][0]).must_equal 0
      _(ranges[0][1]).must_equal 511
      _(ranges[1][0]).must_equal 1024
      _(ranges[1][1]).must_equal 1535
      _(ranges[2][0]).must_equal 2048
      _(ranges[2][1]).must_equal 2559
    }

    describe "when both start_range and end_range are specified" do
      it "clears the data in files within the provided range" do
        subject.clear_file_range share_name, directory_name, file_name, 512, 1535

        file, ranges = subject.list_file_ranges share_name, directory_name, file_name, start_range: 0, end_range: 2560
        _(file.properties[:etag]).wont_be_nil
        _(file.properties[:last_modified]).wont_be_nil
        _(file.properties[:content_length]).must_equal file_length
        _(ranges.length).must_equal 2
        _(ranges[0][0]).must_equal 0
        _(ranges[0][1]).must_equal 511
        _(ranges[1][0]).must_equal 2048
        _(ranges[1][1]).must_equal 2559
      end
    end
  end

  describe "#list_file_ranges" do
    before {
      content = ""
      512.times.each { |i| content << "@" }

      subject.put_file_range share_name, directory_name, file_name, 0, 511, content
      subject.put_file_range share_name, directory_name, file_name, 1024, 1535, content
    }

    it "lists the active file ranges" do
      file, ranges = subject.list_file_ranges share_name, directory_name, file_name, start_range: 0, end_range: 1536
      _(file.properties[:etag]).wont_be_nil
      _(file.properties[:last_modified]).wont_be_nil
      _(file.properties[:content_length]).must_equal file_length
      _(ranges[0][0]).must_equal 0
      _(ranges[0][1]).must_equal 511
      _(ranges[1][0]).must_equal 1024
      _(ranges[1][1]).must_equal 1535
    end
  end
end
