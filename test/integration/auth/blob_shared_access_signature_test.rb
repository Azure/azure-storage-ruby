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
require "azure/storage/common/core/auth/shared_access_signature"

describe Azure::Storage::Common::Core::Auth::SharedAccessSignature do
  subject { Azure::Storage::Blob::BlobService.create(SERVICE_CREATE_OPTIONS()) }
  let(:generator) { Azure::Storage::Common::Core::Auth::SharedAccessSignature.new(SERVICE_CREATE_OPTIONS()[:storage_account_name], SERVICE_CREATE_OPTIONS()[:storage_access_key]) }

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
      connection_string = "BlobEndpoint=https://#{SERVICE_CREATE_OPTIONS()[:storage_account_name]}.blob.core.windows.net;SharedAccessSignature=#{sas_token}"
      client = Azure::Storage::Blob::BlobService::create_from_connection_string connection_string
      blob_properties = client.get_blob_properties container_name, block_blob_name
      _(blob_properties).wont_be_nil
      _(blob_properties.name).must_equal block_blob_name
      _(blob_properties.properties[:last_modified]).wont_be_nil
      _(blob_properties.properties[:etag]).wont_be_nil
      _(blob_properties.properties[:content_length]).must_equal 512
      _(blob_properties.properties[:blob_type]).must_equal "BlockBlob"
    end

    it "reads a blob property with container permission" do
      sas_token = generator.generate_service_sas_token "#{container_name}", service: "b", resource: "c", permissions: "r", protocol: "https"
      client = Azure::Storage::Blob::BlobService.new({ storage_account_name: SERVICE_CREATE_OPTIONS()[:storage_account_name], storage_sas_token: sas_token })
      blob_properties = client.get_blob_properties container_name, block_blob_name
      _(blob_properties).wont_be_nil
      _(blob_properties.name).must_equal block_blob_name
      _(blob_properties.properties[:last_modified]).wont_be_nil
      _(blob_properties.properties[:etag]).wont_be_nil
      _(blob_properties.properties[:content_length]).must_equal 512
      _(blob_properties.properties[:blob_type]).must_equal "BlockBlob"
    end

    it "appends a blob with container permission" do
      sas_token = generator.generate_service_sas_token "#{container_name}", service: "b", resource: "c", permissions: "a", protocol: "https,http"
      client = Azure::Storage::Blob::BlobService.new({ storage_account_name: SERVICE_CREATE_OPTIONS()[:storage_account_name], storage_sas_token: sas_token })
      blob = client.append_blob_block container_name, append_blob_name, content
      _(blob).wont_be_nil
      _(blob.name).must_equal append_blob_name
      _(blob.properties[:last_modified]).wont_be_nil
      _(blob.properties[:etag]).wont_be_nil
      _(blob.properties[:append_offset]).must_equal 0
      _(blob.properties[:committed_count]).must_equal 1
    end

    it "snapshots a blob with container permission" do
      sas_token = generator.generate_service_sas_token "#{container_name}", service: "b", resource: "c", permissions: "c", protocol: "https"
      client = Azure::Storage::Blob::BlobService.new({ storage_account_name: SERVICE_CREATE_OPTIONS()[:storage_account_name], storage_sas_token: sas_token })
      snapshot_id = client.create_blob_snapshot container_name, block_blob_name
      _(snapshot_id).wont_be_nil
    end

    it "leases a blob with container permission" do
      sas_token = generator.generate_service_sas_token "#{container_name}", service: "b", resource: "c", permissions: "w", protocol: "https,http"
      client = Azure::Storage::Blob::BlobService.new({ storage_account_name: SERVICE_CREATE_OPTIONS()[:storage_account_name], storage_sas_token: sas_token })
      lease_id = client.acquire_blob_lease container_name, block_blob_name
      _(lease_id).wont_be_nil
    end

    it "list a blob with container permission" do
      sas_token = generator.generate_service_sas_token "#{container_name}", service: "b", resource: "c", permissions: "l", protocol: "https"
      client = Azure::Storage::Blob::BlobService.new({ storage_account_name: SERVICE_CREATE_OPTIONS()[:storage_account_name], storage_sas_token: sas_token })
      blobs = client.list_blobs container_name
      _(blobs).wont_be_nil
      assert blobs.length > 0
    end

    it "deletes a blob with container permission" do
      sas_token = generator.generate_service_sas_token "#{container_name}", service: "b", resource: "c", permissions: "d", protocol: "https,http"
      client = Azure::Storage::Blob::BlobService.new({ storage_account_name: SERVICE_CREATE_OPTIONS()[:storage_account_name], storage_sas_token: sas_token })
      result = client.delete_blob container_name, page_blob_name
      _(result).must_be_nil
    end

    it "reads a blob property with blob permission" do
      sas_token = generator.generate_service_sas_token "#{container_name}/#{block_blob_name}", service: "b", resource: "b", permissions: "r", protocol: "https"
      client = Azure::Storage::Blob::BlobService.new({ storage_account_name: SERVICE_CREATE_OPTIONS()[:storage_account_name], storage_sas_token: sas_token })
      blob_properties = client.get_blob_properties container_name, block_blob_name
      _(blob_properties).wont_be_nil
      _(blob_properties.name).must_equal block_blob_name
      _(blob_properties.properties[:last_modified]).wont_be_nil
      _(blob_properties.properties[:etag]).wont_be_nil
      _(blob_properties.properties[:content_length]).must_equal 512
      _(blob_properties.properties[:blob_type]).must_equal "BlockBlob"
    end

    it "appends a blob with blob permission" do
      sas_token = generator.generate_service_sas_token "#{container_name}/#{append_blob_name}", service: "b", resource: "b", permissions: "a", protocol: "https,http"
      client = Azure::Storage::Blob::BlobService.new({ storage_account_name: SERVICE_CREATE_OPTIONS()[:storage_account_name], storage_sas_token: sas_token })
      blob = client.append_blob_block container_name, append_blob_name, content
      _(blob).wont_be_nil
      _(blob.name).must_equal append_blob_name
      _(blob.properties[:last_modified]).wont_be_nil
      _(blob.properties[:etag]).wont_be_nil
      _(blob.properties[:append_offset]).must_equal 0
      _(blob.properties[:committed_count]).must_equal 1
    end

    it "snapshots a blob with blob permission" do
      sas_token = generator.generate_service_sas_token "#{container_name}/#{block_blob_name}", service: "b", resource: "b", permissions: "c", protocol: "https"
      client = Azure::Storage::Blob::BlobService.new({ storage_account_name: SERVICE_CREATE_OPTIONS()[:storage_account_name], storage_sas_token: sas_token })
      snapshot_id = client.create_blob_snapshot container_name, block_blob_name
      _(snapshot_id).wont_be_nil
    end

    it "leases a blob with blob permission" do
      sas_token = generator.generate_service_sas_token "#{container_name}/#{block_blob_name}", service: "b", resource: "b", permissions: "w", protocol: "https,http"
      client = Azure::Storage::Blob::BlobService.new({ storage_account_name: SERVICE_CREATE_OPTIONS()[:storage_account_name], storage_sas_token: sas_token })
      lease_id = client.acquire_blob_lease container_name, block_blob_name
      _(lease_id).wont_be_nil
    end

    it "deletes a blob with blob permission" do
      sas_token = generator.generate_service_sas_token "#{container_name}/#{page_blob_name}", service: "b", resource: "b", permissions: "d", protocol: "https"
      client = Azure::Storage::Blob::BlobService.new({ storage_account_name: SERVICE_CREATE_OPTIONS()[:storage_account_name], storage_sas_token: sas_token })
      result = client.delete_blob container_name, page_blob_name
      _(result).must_be_nil
    end
  end
end
