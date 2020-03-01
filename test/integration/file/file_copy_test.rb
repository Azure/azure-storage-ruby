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
  describe "#copy_file" do
    let(:source_share_name) { ShareNameHelper.name }
    let(:source_directory_name) { FileNameHelper.name }
    let(:source_file_name) { "audio+video%25.mp4" }
    let(:source_file_uri) { "https://#{SERVICE_CREATE_OPTIONS()[:storage_account_name]}.file.core.windows.net/#{source_share_name}/#{source_directory_name}/#{CGI.escape(source_file_name).encode('UTF-8')}" }
    let(:file_length) { 1024 }
    let(:content) { content = ""; file_length.times.each { |i| content << "@" }; content }
    let(:metadata) { { "custommetadata" => "CustomMetadataValue" } }

    let(:dest_share_name) { ShareNameHelper.name }
    let(:dest_directory_name) { FileNameHelper.name }
    let(:dest_file_name) { "destaudio+video%25.mp4" }

    before {
      subject.create_share source_share_name
      subject.create_directory source_share_name, source_directory_name
      subject.create_file source_share_name, source_directory_name, source_file_name, file_length
      subject.put_file_range source_share_name, source_directory_name, source_file_name, 0, file_length - 1, content

      subject.create_share dest_share_name
      subject.create_directory dest_share_name, dest_directory_name
    }

    it "copies an existing file to a new storage location" do
      copy_id, copy_status = subject.copy_file dest_share_name, dest_directory_name, dest_file_name, source_share_name, source_directory_name, source_file_name
      _(copy_id).wont_be_nil

      file, returned_content = subject.get_file dest_share_name, dest_directory_name, dest_file_name

      _(file.name).must_equal dest_file_name
      _(returned_content).must_equal content
    end

    it "copies an existing file from URI to a new storage location" do
      copy_id, copy_status = subject.copy_file_from_uri dest_share_name, dest_directory_name, dest_file_name, source_file_uri
      _(copy_id).wont_be_nil

      file, returned_content = subject.get_file dest_share_name, dest_directory_name, dest_file_name

      _(file.name).must_equal dest_file_name
      _(returned_content).must_equal content
    end

    it "returns a copyid which can be used to monitor status of the asynchronous copy operation" do
      copy_id, copy_status = subject.copy_file dest_share_name, dest_directory_name, dest_file_name, source_share_name, source_directory_name, source_file_name
      _(copy_id).wont_be_nil

      counter = 0
      finished = false
      while (counter < (10) && (not finished))
        sleep(1)
        file = subject.get_file_properties dest_share_name, dest_directory_name, dest_file_name
        _(file.properties[:copy_id]).must_equal copy_id
        finished = file.properties[:copy_status] == "success"
        counter += 1
      end
      _(finished).must_equal true

      file, returned_content = subject.get_file dest_share_name, dest_directory_name, dest_file_name

      _(file.name).must_equal dest_file_name
      _(returned_content).must_equal content
    end

    it "returns a copyid which can be used to abort copy operation" do
      copy_id, copy_status = subject.copy_file dest_share_name, dest_directory_name, dest_file_name, source_share_name, source_directory_name, source_file_name
      _(copy_id).wont_be_nil

      counter = 0
      finished = false
      while (counter < (10) && (not finished))
        sleep(1)
        file = subject.get_file_properties dest_share_name, dest_directory_name, dest_file_name
        _(file.properties[:copy_id]).must_equal copy_id
        finished = file.properties[:copy_status] == "success"
        counter += 1
      end
      _(finished).must_equal true

      exception = assert_raises(Azure::Core::Http::HTTPError) do
        subject.abort_copy_file dest_share_name, dest_directory_name, dest_file_name, copy_id
      end
      refute_nil(exception.message.index "NoPendingCopyOperation (409): There is currently no pending copy operation")
    end

    describe "when a options hash is used" do
      it "replaces source metadata on the copy with provided Hash in :metadata property" do
        copy_id, copy_status = subject.copy_file dest_share_name, dest_directory_name, dest_file_name, source_share_name, source_directory_name, source_file_name, metadata: metadata
        _(copy_id).wont_be_nil

        file, returned_content = subject.get_file dest_share_name, dest_directory_name, dest_file_name
        _(file.name).must_equal dest_file_name
        _(returned_content).must_equal content

        file = subject.get_file_metadata dest_share_name, dest_directory_name, dest_file_name
        metadata.each { |k, v|
          _(file.metadata).must_include k
          _(file.metadata[k]).must_equal v
        }
      end
    end
  end
end
