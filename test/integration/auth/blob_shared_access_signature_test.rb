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
require "azure/storage/core/auth/shared_access_signature"

describe Azure::Storage::Core::Auth::SharedAccessSignature do
  subject { Azure::Storage::Blob::BlobService.new }
  let(:generator) { Azure::Storage::Core::Auth::SharedAccessSignature.new }

  describe "#blob_service_sas_for_container" do
    let(:container_name) { ContainerNameHelper.name }
    let(:block_blob_name) { BlobNameHelper.name }
    let(:append_blob_name) { BlobNameHelper.name }
    let(:page_blob_name) { BlobNameHelper.name }
    let(:content) { content = ""; 512.times.each { |i| content << "@" }; content }
    before {
      subject.create_container container_name
      subject.create_block_blob container_name, block_blob_name, content
      subject.create_append_blob container_name, append_blob_name
      subject.create_page_blob container_name, page_blob_name, 512
    }
    after { ContainerNameHelper.clean }

    it "reads a blob property with SAS in connection string" do
      sas_token = generator.generate_service_sas_token "#{container_name}", service: "b", resource: "c", permissions: "r", protocol: "https"
      connection_string = "BlobEndpoint=https://#{ENV['AZURE_STORAGE_ACCOUNT']}.blob.core.windows.net;SharedAccessSignature=#{sas_token}"
      sas_client = Azure::Storage::Client::create_from_connection_string connection_string
      client = sas_client.blob_client
      blob_properties = client.get_blob_properties container_name, block_blob_name
      blob_properties.wont_be_nil
      blob_properties.name.must_equal block_blob_name
      blob_properties.properties[:last_modified].wont_be_nil
      blob_properties.properties[:etag].wont_be_nil
      blob_properties.properties[:content_length].must_equal 512
      blob_properties.properties[:blob_type].must_equal "BlockBlob"
    end

    it "reads a blob property with container permission" do
      sas_token = generator.generate_service_sas_token "#{container_name}", service: "b", resource: "c", permissions: "r", protocol: "https"
      signer = Azure::Storage::Core::Auth::SharedAccessSignatureSigner.new Azure::Storage.storage_account_name, sas_token
      client = Azure::Storage::Blob::BlobService.new(signer: signer)
      blob_properties = client.get_blob_properties container_name, block_blob_name
      blob_properties.wont_be_nil
      blob_properties.name.must_equal block_blob_name
      blob_properties.properties[:last_modified].wont_be_nil
      blob_properties.properties[:etag].wont_be_nil
      blob_properties.properties[:content_length].must_equal 512
      blob_properties.properties[:blob_type].must_equal "BlockBlob"
    end

    it "appends a blob with container permission" do
      sas_token = generator.generate_service_sas_token "#{container_name}", service: "b", resource: "c", permissions: "a", protocol: "https,http"
      signer = Azure::Storage::Core::Auth::SharedAccessSignatureSigner.new Azure::Storage.storage_account_name, sas_token
      client = Azure::Storage::Blob::BlobService.new(signer: signer)
      blob = client.append_blob_block container_name, append_blob_name, content
      blob.wont_be_nil
      blob.name.must_equal append_blob_name
      blob.properties[:last_modified].wont_be_nil
      blob.properties[:etag].wont_be_nil
      blob.properties[:append_offset].must_equal 0
      blob.properties[:committed_count].must_equal 1
    end

    it "snapshots a blob with container permission" do
      sas_token = generator.generate_service_sas_token "#{container_name}", service: "b", resource: "c", permissions: "c", protocol: "https"
      signer = Azure::Storage::Core::Auth::SharedAccessSignatureSigner.new Azure::Storage.storage_account_name, sas_token
      client = Azure::Storage::Blob::BlobService.new(signer: signer)
      snapshot_id = client.create_blob_snapshot container_name, block_blob_name
      snapshot_id.wont_be_nil
    end

    it "leases a blob with container permission" do
      sas_token = generator.generate_service_sas_token "#{container_name}", service: "b", resource: "c", permissions: "w", protocol: "https,http"
      signer = Azure::Storage::Core::Auth::SharedAccessSignatureSigner.new Azure::Storage.storage_account_name, sas_token
      client = Azure::Storage::Blob::BlobService.new(signer: signer)
      lease_id = client.acquire_blob_lease container_name, block_blob_name
      lease_id.wont_be_nil
    end

    it "list a blob with container permission" do
      sas_token = generator.generate_service_sas_token "#{container_name}", service: "b", resource: "c", permissions: "l", protocol: "https"
      signer = Azure::Storage::Core::Auth::SharedAccessSignatureSigner.new Azure::Storage.storage_account_name, sas_token
      client = Azure::Storage::Blob::BlobService.new(signer: signer)
      blobs = client.list_blobs container_name
      blobs.wont_be_nil
      assert blobs.length > 0
    end

    it "deletes a blob with container permission" do
      sas_token = generator.generate_service_sas_token "#{container_name}", service: "b", resource: "c", permissions: "d", protocol: "https,http"
      signer = Azure::Storage::Core::Auth::SharedAccessSignatureSigner.new Azure::Storage.storage_account_name, sas_token
      client = Azure::Storage::Blob::BlobService.new(signer: signer)
      result = client.delete_blob container_name, page_blob_name
      result.must_be_nil
    end

    it "reads a blob property with blob permission" do
      sas_token = generator.generate_service_sas_token "#{container_name}/#{block_blob_name}", service: "b", resource: "b", permissions: "r", protocol: "https"
      signer = Azure::Storage::Core::Auth::SharedAccessSignatureSigner.new Azure::Storage.storage_account_name, sas_token
      client = Azure::Storage::Blob::BlobService.new(signer: signer)
      blob_properties = client.get_blob_properties container_name, block_blob_name
      blob_properties.wont_be_nil
      blob_properties.name.must_equal block_blob_name
      blob_properties.properties[:last_modified].wont_be_nil
      blob_properties.properties[:etag].wont_be_nil
      blob_properties.properties[:content_length].must_equal 512
      blob_properties.properties[:blob_type].must_equal "BlockBlob"
    end

    it "appends a blob with blob permission" do
      sas_token = generator.generate_service_sas_token "#{container_name}/#{append_blob_name}", service: "b", resource: "b", permissions: "a", protocol: "https,http"
      signer = Azure::Storage::Core::Auth::SharedAccessSignatureSigner.new Azure::Storage.storage_account_name, sas_token
      client = Azure::Storage::Blob::BlobService.new(signer: signer)
      blob = client.append_blob_block container_name, append_blob_name, content
      blob.wont_be_nil
      blob.name.must_equal append_blob_name
      blob.properties[:last_modified].wont_be_nil
      blob.properties[:etag].wont_be_nil
      blob.properties[:append_offset].must_equal 0
      blob.properties[:committed_count].must_equal 1
    end

    it "snapshots a blob with blob permission" do
      sas_token = generator.generate_service_sas_token "#{container_name}/#{block_blob_name}", service: "b", resource: "b", permissions: "c", protocol: "https"
      signer = Azure::Storage::Core::Auth::SharedAccessSignatureSigner.new Azure::Storage.storage_account_name, sas_token
      client = Azure::Storage::Blob::BlobService.new(signer: signer)
      snapshot_id = client.create_blob_snapshot container_name, block_blob_name
      snapshot_id.wont_be_nil
    end

    it "leases a blob with blob permission" do
      sas_token = generator.generate_service_sas_token "#{container_name}/#{block_blob_name}", service: "b", resource: "b", permissions: "w", protocol: "https,http"
      signer = Azure::Storage::Core::Auth::SharedAccessSignatureSigner.new Azure::Storage.storage_account_name, sas_token
      client = Azure::Storage::Blob::BlobService.new(signer: signer)
      lease_id = client.acquire_blob_lease container_name, block_blob_name
      lease_id.wont_be_nil
    end

    it "deletes a blob with blob permission" do
      sas_token = generator.generate_service_sas_token "#{container_name}/#{page_blob_name}", service: "b", resource: "b", permissions: "d", protocol: "https"
      signer = Azure::Storage::Core::Auth::SharedAccessSignatureSigner.new Azure::Storage.storage_account_name, sas_token
      client = Azure::Storage::Blob::BlobService.new(signer: signer)
      result = client.delete_blob container_name, page_blob_name
      result.must_be_nil
    end
  end
end
