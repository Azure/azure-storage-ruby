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
  subject { Azure::Storage::File::FileService.new }
  after { ShareNameHelper.clean }

  describe "#get_directory_properties" do
    let(:share_name) { ShareNameHelper.name }
    let(:directory_name) { FileNameHelper.name }
    before {
      subject.create_share share_name
    }
    let(:metadata) { { "CustomMetadataProperty" => "CustomMetadataValue" } }

    it "gets properties and custom metadata for the directory" do
      directory = subject.create_directory share_name, directory_name, metadata: metadata
      properties = directory.properties

      directory = subject.get_directory_properties share_name, directory_name
      directory.wont_be_nil
      directory.name.must_equal directory_name
      directory.properties[:etag].must_equal properties[:etag]
      directory.properties[:last_modified].must_equal properties[:last_modified]

      metadata.each { |k, v|
        directory.metadata.must_include k.downcase
        directory.metadata[k.downcase].must_equal v
      }
    end

    it "errors if the directory does not exist" do
      assert_raises(Azure::Core::Http::HTTPError) do
        subject.get_directory_properties share_name, FileNameHelper.name
      end
    end
  end
end
