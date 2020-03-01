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

describe Azure::Storage::Blob::BlobService do
  subject { Azure::Storage::Blob::BlobService.create(SERVICE_CREATE_OPTIONS()) }
  after { ContainerNameHelper.clean }

  describe "#create_container" do
    let(:container_name) { ContainerNameHelper.name }

    it "creates the container" do
      container = subject.create_container container_name
      _(container.name).must_equal container_name
    end

    it "creates the container with custom metadata" do
      metadata = { "CustomMetadataProperty" => "CustomMetadataValue" }

      container = subject.create_container container_name, metadata: metadata

      _(container.name).must_equal container_name
      _(container.metadata).must_equal metadata
      container = subject.get_container_metadata container_name

      metadata.each { |k, v|
        _(container.metadata).must_include k.downcase
        _(container.metadata[k.downcase]).must_equal v
      }
    end

    it "errors if the container already exists" do
      subject.create_container container_name

      assert_raises(Azure::Core::Http::HTTPError) do
        subject.create_container container_name
      end
    end

    it "errors if the container name is invalid" do
      assert_raises(Azure::Core::Http::HTTPError) do
        subject.create_container "this_container.cannot-exist!"
      end
    end
  end
end
