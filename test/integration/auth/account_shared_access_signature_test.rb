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
require 'integration/test_helper'
require 'azure/storage/core/auth/shared_access_signature'

describe Azure::Storage::Core::Auth::SharedAccessSignature do
  subject { Azure::Storage::Client.create }
  let(:generator) { Azure::Storage::Core::Auth::SharedAccessSignature.new }

  describe '#account_sas' do
    let(:container_name) { ContainerNameHelper.name }
    let(:blob_name) { BlobNameHelper.name }
    let(:content) { content = ""; 512.times.each{ |i| content << "@" }; content }
    before {
      subject.blob_client.create_container container_name
      subject.blob_client.create_block_blob container_name, blob_name, content
    }
    after { ContainerNameHelper.clean }

    it 'reads the blob properties with an object level SAS' do
      sas_token = generator.generate_account_sas_token service: 'b', resource: 'o', permissions: 'r'
      signer = Azure::Storage::Core::Auth::SharedAccessSignatureSigner.new Azure::Storage.storage_account_name, sas_token
      client = Azure::Storage::Blob::BlobService.new(signer: signer)
      blob_properties = client.get_blob_properties container_name, blob_name
      blob_properties.wont_be_nil
      blob_properties.name.must_equal blob_name
      blob_properties.properties[:last_modified].wont_be_nil
      blob_properties.properties[:etag].wont_be_nil
      blob_properties.properties[:content_length].must_equal 512
      blob_properties.properties[:blob_type].must_equal 'BlockBlob'
    end

    it 'fails to read the blob properties using an object level SAS without permission' do
      sas_token = generator.generate_account_sas_token service: 'b', resource: 'o', permissions: 'l'
      signer = Azure::Storage::Core::Auth::SharedAccessSignatureSigner.new Azure::Storage.storage_account_name, sas_token
      client = Azure::Storage::Blob::BlobService.new(signer: signer)
      assert_raises(Azure::Core::Http::HTTPError) do
        client.get_blob_properties container_name, blob_name
      end
    end

    it 'lists the blobs with a container level SAS' do
      sas_token = generator.generate_account_sas_token service: 'b', resource: 'c', permissions: 'l'
      signer = Azure::Storage::Core::Auth::SharedAccessSignatureSigner.new Azure::Storage.storage_account_name, sas_token
      client = Azure::Storage::Blob::BlobService.new(signer: signer)
      blobs = client.list_blobs container_name
      blobs.wont_be_nil
      assert blobs.length > 0
    end

    it 'fails to list the blobs using a container level SAS without permission' do
      sas_token = generator.generate_account_sas_token service: 'b', resource: 'c', permissions: 'rwd'
      signer = Azure::Storage::Core::Auth::SharedAccessSignatureSigner.new Azure::Storage.storage_account_name, sas_token
      client = Azure::Storage::Blob::BlobService.new(signer: signer)
      assert_raises(Azure::Core::Http::HTTPError) do
        client.list_blobs container_name
      end
    end

    it 'lists the containers with a service level SAS' do
      sas_token = generator.generate_account_sas_token service: 'b', resource: 's', permissions: 'l'
      signer = Azure::Storage::Core::Auth::SharedAccessSignatureSigner.new Azure::Storage.storage_account_name, sas_token
      client = Azure::Storage::Blob::BlobService.new(signer: signer)
      containers = client.list_containers
      containers.wont_be_nil
      assert containers.length > 0
    end

    it 'fails to list the containers using a service level SAS without permission' do
      sas_token = generator.generate_account_sas_token service: 'b', resource: 's', permissions: 'rw'
      signer = Azure::Storage::Core::Auth::SharedAccessSignatureSigner.new Azure::Storage.storage_account_name, sas_token
      client = Azure::Storage::Blob::BlobService.new(signer: signer)
      assert_raises(Azure::Core::Http::HTTPError) do
        client.list_containers
      end
    end
  end
end
