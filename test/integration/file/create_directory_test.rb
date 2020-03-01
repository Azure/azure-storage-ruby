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

  describe "#create_directory" do
    let(:share_name) { ShareNameHelper.name }
    let(:directory_name) { FileNameHelper.name }
    before {
      subject.create_share share_name
    }

    it "creates the directory" do
      directory = subject.create_directory share_name, directory_name
      _(directory.name).must_equal directory_name
    end

    it "creates the directory with custom metadata" do
      metadata = { "CustomMetadataProperty" => "CustomMetadataValue" }

      directory = subject.create_directory share_name, directory_name, metadata: metadata

      _(directory.name).must_equal directory_name
      _(directory.metadata).must_equal metadata
      directory = subject.get_directory_metadata share_name, directory_name

      metadata.each { |k, v|
        _(directory.metadata).must_include k.downcase
        _(directory.metadata[k.downcase]).must_equal v
      }
    end

    it "errors if the directory already exists" do
      subject.create_directory share_name, directory_name

      assert_raises(Azure::Core::Http::HTTPError) do
        subject.create_directory share_name, directory_name
      end
    end

    it "errors if the directory name is invalid" do
      assert_raises(Azure::Core::Http::HTTPError) do
        subject.create_directory share_name, "this_directory/cannot/exist!"
      end
    end
  end
end
