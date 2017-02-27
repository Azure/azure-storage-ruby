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

  describe '#account_sas for blob service' do
    let(:container_name) { ContainerNameHelper.name }
    let(:blob_name) { BlobNameHelper.name }
    let(:content) { content = ""; 512.times.each{ |i| content << "@" }; content }
    before {
      subject.blob_client.create_container container_name
      subject.blob_client.create_block_blob container_name, blob_name, content
    }
    after { ContainerNameHelper.clean }

    it 'reads the blob properties with an object level SAS in connection string' do
      sas_token = generator.generate_account_sas_token service: 'b', resource: 'o', permissions: 'r'
      connection_string = "BlobEndpoint=https://#{ENV['AZURE_STORAGE_ACCOUNT']}.blob.core.windows.net;SharedAccessSignature=#{sas_token}"
      sas_client = Azure::Storage::Client::create_from_connection_string connection_string
      client = sas_client.blob_client
      blob_properties = client.get_blob_properties container_name, blob_name
      blob_properties.wont_be_nil
      blob_properties.name.must_equal blob_name
      blob_properties.properties[:last_modified].wont_be_nil
      blob_properties.properties[:etag].wont_be_nil
      blob_properties.properties[:content_length].must_equal 512
      blob_properties.properties[:blob_type].must_equal 'BlockBlob'
    end

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

  describe '#account_sas for file service' do
    let(:share_name) { ShareNameHelper.name }
    let(:directory_name) { FileNameHelper.name }
    let(:file_name) { FileNameHelper.name }
    let(:file_length) { 1024 }
    let(:content) { content = ""; file_length.times.each{ |i| content << "@" }; content }
    before {
      subject.file_client.create_share share_name
      subject.file_client.create_directory share_name, directory_name
      subject.file_client.create_file share_name, directory_name, file_name, file_length
    }
    after { ShareNameHelper.clean }

    it 'reads the file properties with an object level SAS in connection string' do
      sas_token = generator.generate_account_sas_token service: 'f', resource: 'o', permissions: 'r'
      connection_string = "FileEndpoint=https://#{ENV['AZURE_STORAGE_ACCOUNT']}.file.core.windows.net;SharedAccessSignature=#{sas_token}"
      sas_client = Azure::Storage::Client::create_from_connection_string connection_string
      client = sas_client.file_client
      file_properties = client.get_file_properties share_name, directory_name, file_name
      file_properties.wont_be_nil
      file_properties.name.must_equal file_name
      file_properties.properties[:last_modified].wont_be_nil
      file_properties.properties[:etag].wont_be_nil
      file_properties.properties[:content_length].must_equal file_length
      file_properties.properties[:type].must_equal 'File'
    end

    it 'reads the file properties with an object level SAS' do
      sas_token = generator.generate_account_sas_token service: 'f', resource: 'o', permissions: 'r'
      signer = Azure::Storage::Core::Auth::SharedAccessSignatureSigner.new Azure::Storage.storage_account_name, sas_token
      client = Azure::Storage::File::FileService.new(signer: signer)
      file_properties = client.get_file_properties share_name, directory_name, file_name
      file_properties.wont_be_nil
      file_properties.name.must_equal file_name
      file_properties.properties[:last_modified].wont_be_nil
      file_properties.properties[:etag].wont_be_nil
      file_properties.properties[:content_length].must_equal file_length
      file_properties.properties[:type].must_equal 'File'
    end

    it 'fails to read the file properties using an object level SAS without permission' do
      sas_token = generator.generate_account_sas_token service: 'f', resource: 'o', permissions: 'l'
      signer = Azure::Storage::Core::Auth::SharedAccessSignatureSigner.new Azure::Storage.storage_account_name, sas_token
      client = Azure::Storage::File::FileService.new(signer: signer)
      assert_raises(Azure::Core::Http::HTTPError) do
        client.get_file_properties share_name, directory_name, file_name
      end
    end

    it 'lists the directories with a share level SAS' do
      sas_token = generator.generate_account_sas_token service: 'f', resource: 'c', permissions: 'l'
      signer = Azure::Storage::Core::Auth::SharedAccessSignatureSigner.new Azure::Storage.storage_account_name, sas_token
      client = Azure::Storage::File::FileService.new(signer: signer)
      directories = client.list_directories_and_files share_name, nil
      directories.wont_be_nil
      assert directories.length > 0
    end

    it 'fails to list the directories using a share level SAS without permission' do
      sas_token = generator.generate_account_sas_token service: 'f', resource: 'c', permissions: 'rwd'
      signer = Azure::Storage::Core::Auth::SharedAccessSignatureSigner.new Azure::Storage.storage_account_name, sas_token
      client = Azure::Storage::File::FileService.new(signer: signer)
      assert_raises(Azure::Core::Http::HTTPError) do
        client.list_directories_and_files share_name, nil
      end
    end

    it 'lists the shares with a service level SAS' do
      sas_token = generator.generate_account_sas_token service: 'f', resource: 's', permissions: 'l'
      signer = Azure::Storage::Core::Auth::SharedAccessSignatureSigner.new Azure::Storage.storage_account_name, sas_token
      client = Azure::Storage::File::FileService.new(signer: signer)
      shares = client.list_shares
      shares.wont_be_nil
      assert shares.length > 0
    end

    it 'fails to list the shares using a service level SAS without permission' do
      sas_token = generator.generate_account_sas_token service: 'f', resource: 's', permissions: 'rw'
      signer = Azure::Storage::Core::Auth::SharedAccessSignatureSigner.new Azure::Storage.storage_account_name, sas_token
      client = Azure::Storage::File::FileService.new(signer: signer)
      assert_raises(Azure::Core::Http::HTTPError) do
        client.list_shares
      end
    end
  end

  describe '#sas in connection string' do
    it 'throws when no account name can be identified in connection string' do
      sas_token = generator.generate_account_sas_token service: 'b', resource: 'o', permissions: 'r'
      connection_string = "SharedAccessSignature=#{sas_token}"
      assert_raises(Azure::Storage::InvalidOptionsError) do
        Azure::Storage::Client::create_from_connection_string connection_string
      end
    end
  end
end
