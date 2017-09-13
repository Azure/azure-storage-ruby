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

describe Azure::Storage::Blob::BlobService do
  subject { Azure::Storage::Blob::BlobService.new }
  after { ContainerNameHelper.clean }

  describe "#get_container_properties" do
    let(:container_name) { ContainerNameHelper.name }
    let(:metadata) { { "CustomMetadataProperty" => "CustomMetadataValue" } }

    it "gets properties and custom metadata for the container" do
      container = subject.create_container container_name, metadata: metadata
      properties = container.properties

      container = subject.get_container_properties container_name
      container.wont_be_nil
      container.name.must_equal container_name
      container.properties[:etag].must_equal properties[:etag]
      container.properties[:last_modified].must_equal properties[:last_modified]

      metadata.each { |k, v|
        container.metadata.must_include k.downcase
        container.metadata[k.downcase].must_equal v
      }
    end

    it "errors if the container does not exist" do
      assert_raises(Azure::Core::Http::HTTPError) do
        subject.get_container_properties ContainerNameHelper.name
      end
    end
  end
end
