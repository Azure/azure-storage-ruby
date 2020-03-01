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
  subject { Azure::Storage::Blob::BlobService.create(SERVICE_CREATE_OPTIONS()) }
  after { ContainerNameHelper.clean }

  describe "#list_containers" do
    let(:container_names) { [ContainerNameHelper.name, ContainerNameHelper.name] }
    let(:metadata) { { "CustomMetadataProperty" => "CustomMetadataValue" } }
    let(:public_access_level) { "blob" }
    before {
      container_names.each { |c|
        subject.create_container c, metadata: metadata, public_access_level: public_access_level
      }
    }

    it "lists the containers for the account" do
      result = subject.list_containers

      found = 0
      result.each { |c|
        found += 1 if container_names.include? c.name
        _(c.public_access_level).must_equal "blob" if container_names.include? c.name
      }
      _(found).must_equal container_names.length
    end

    it "lists the containers for the account with prefix" do
      result = subject.list_containers(prefix: container_names[0])

      found = 0
      result.each { |c|
        found += 1 if container_names.include? c.name
        _(c.public_access_level).must_equal "blob" if container_names.include? c.name
      }

      _(found).must_equal 1
    end

    it "lists the containers for the account with max results" do
      result = subject.list_containers(max_results: 1)
      _(result.length).must_equal 1
      first_container = result[0]
      result.continuation_token.wont_equal("")

      result = subject.list_containers(max_results: 1, marker: result.continuation_token)
      _(result.length).must_equal 1
      result[0].name.wont_equal first_container.name
    end

    it "returns metadata if the :metadata=>true option is used" do
      result = subject.list_containers(metadata: true)

      found = 0
      result.each { |c|
        if container_names.include? c.name
          found += 1
          metadata.each { |k, v|
            _(c.metadata).must_include k.downcase
            _(c.metadata[k.downcase]).must_equal v
          }
          _(c.public_access_level).must_equal "blob"
        end
      }
      _(found).must_equal container_names.length
    end
  end
end
