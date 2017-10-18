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
require "test_helper"
require "azure/storage/blob/blob_service"
require "azure/storage/blob/container"
require "azure/storage/blob/blob"
require "azure/storage/client"
require "azure/storage/core/auth/anonymous_signer"

describe Azure::Storage::Blob::BlobService do
  subject { Azure::Storage::Client.create(
    storage_account_name: ENV["AZURE_STORAGE_ACCOUNT"],
    storage_access_key: ENV["AZURE_STORAGE_ACCESS_KEY"]
  ).blob_client }

  let(:public_access_level) { :container.to_s }
  let(:content) { content = ""; 512.times.each { |i| content << "@" }; content }
  let(:blob_endpoint) { "blob.core.windows.net" }
  let(:schema) { "https" }
  let(:storage_account_name) {}
  let(:storage_access_key) {}

  after { ContainerNameHelper.clean }

  describe "test anonymous access" do
    before {
      Azure::Storage.config.storage_account_name = nil
      Azure::Storage.config.storage_access_key = nil
    }
    after {
      Azure::Storage.config.storage_account_name = ENV["AZURE_STORAGE_ACCOUNT"]
      Azure::Storage.config.storage_access_key = ENV["AZURE_STORAGE_ACCESS_KEY"]
    }

    let(:blob_host) { schema + "://" + subject.account_name + "." + blob_endpoint }
    let(:anonymous_blob_client) { Azure::Storage::Client.create(storage_blob_host: blob_host).blob_client }

    it "test anonymous access for public container works" do
      container_name = ContainerNameHelper.name
      blob_name = BlobNameHelper.name
      subject.create_container container_name
      subject.create_block_blob container_name, blob_name, content
      subject.set_container_acl container_name, public_access_level
      result = anonymous_blob_client.list_blobs container_name
      result.size.must_equal 1
      blob, body = anonymous_blob_client.get_blob container_name, blob_name
      blob.name.must_equal blob_name
      body.must_equal content
      Azure::Storage.config.storage_account_name = nil
      Azure::Storage.config.storage_access_key = nil
    end

    it "test anonymous access for private container does not work" do
      container_name = ContainerNameHelper.name
      blob_name = BlobNameHelper.name
      subject.create_container container_name
      subject.create_block_blob container_name, blob_name, content
      status_code = ""
      description = ""
      begin
        result = anonymous_blob_client.list_blobs container_name
      rescue Azure::Core::Http::HTTPError => e
        status_code = e.status_code.to_s
        description = e.description
      end
      status_code.must_equal "404"
      description.must_include "The specified resource does not exist."
    end
  end
end
