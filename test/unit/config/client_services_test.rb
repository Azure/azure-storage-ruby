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
require "unit/test_helper"
require "azure/storage/common"

describe Azure::Storage::Common::Client do

  describe "create client with options" do
    let(:azure_storage_account) { "testStorageAccount" }
    let(:azure_storage_access_key) { "testKey1" }
    let(:storage_sas_token) { "testSAS1" }

    it "storage host should be set to default" do
      subject = Azure::Storage::Common::Client.create(storage_account_name: azure_storage_account, storage_access_key: azure_storage_access_key)
      _(subject.storage_account_name).must_equal azure_storage_account
      _(subject.storage_access_key).must_equal azure_storage_access_key
      _(subject.storage_blob_host).must_equal "https://#{azure_storage_account}.blob.core.windows.net"
      _(subject.storage_blob_host(true)).must_equal "https://#{azure_storage_account}-secondary.blob.core.windows.net"
      _(subject.storage_table_host).must_equal "https://#{azure_storage_account}.table.core.windows.net"
      _(subject.storage_table_host(true)).must_equal "https://#{azure_storage_account}-secondary.table.core.windows.net"
      _(subject.storage_queue_host).must_equal "https://#{azure_storage_account}.queue.core.windows.net"
      _(subject.storage_queue_host(true)).must_equal "https://#{azure_storage_account}-secondary.queue.core.windows.net"
      _(subject.storage_file_host).must_equal "https://#{azure_storage_account}.file.core.windows.net"
      _(subject.storage_file_host(true)).must_equal "https://#{azure_storage_account}-secondary.file.core.windows.net"
      _(subject.signer).must_be_nil
    end

    it "storage sas works" do
      subject = Azure::Storage::Common::Client.create(storage_account_name: azure_storage_account, storage_sas_token: storage_sas_token)
      _(subject.storage_account_name).must_equal azure_storage_account
      _(subject.storage_sas_token).must_equal storage_sas_token
      _(subject.storage_blob_host).must_equal "https://#{azure_storage_account}.blob.core.windows.net"
      _(subject.storage_blob_host(true)).must_equal "https://#{azure_storage_account}-secondary.blob.core.windows.net"
      _(subject.storage_table_host).must_equal "https://#{azure_storage_account}.table.core.windows.net"
      _(subject.storage_table_host(true)).must_equal "https://#{azure_storage_account}-secondary.table.core.windows.net"
      _(subject.storage_queue_host).must_equal "https://#{azure_storage_account}.queue.core.windows.net"
      _(subject.storage_queue_host(true)).must_equal "https://#{azure_storage_account}-secondary.queue.core.windows.net"
      _(subject.storage_file_host).must_equal "https://#{azure_storage_account}.file.core.windows.net"
      _(subject.storage_file_host(true)).must_equal "https://#{azure_storage_account}-secondary.file.core.windows.net"
      _(subject.signer).wont_be_nil
      _(subject.signer.class).must_equal Azure::Storage::Common::Core::Auth::SharedAccessSignatureSigner
    end

    it "storage development works" do
      subject = Azure::Storage::Common::Client.create_development
      _(subject.storage_account_name).must_equal Azure::Storage::Common::StorageServiceClientConstants::DEVSTORE_STORAGE_ACCOUNT
      _(subject.storage_access_key).must_equal Azure::Storage::Common::StorageServiceClientConstants::DEVSTORE_STORAGE_ACCESS_KEY
      proxy_uri = Azure::Storage::Common::StorageServiceClientConstants::DEV_STORE_URI
      _(subject.storage_blob_host).must_equal "#{proxy_uri}:#{Azure::Storage::Common::StorageServiceClientConstants::DEVSTORE_BLOB_HOST_PORT}"
      _(subject.storage_table_host).must_equal "#{proxy_uri}:#{Azure::Storage::Common::StorageServiceClientConstants::DEVSTORE_TABLE_HOST_PORT}"
      _(subject.storage_queue_host).must_equal "#{proxy_uri}:#{Azure::Storage::Common::StorageServiceClientConstants::DEVSTORE_QUEUE_HOST_PORT}"
      _(subject.storage_file_host).must_equal "#{proxy_uri}:#{Azure::Storage::Common::StorageServiceClientConstants::DEVSTORE_FILE_HOST_PORT}"
      _(subject.signer).must_be_nil
    end

    it "storage from env && storage from connection_string works" do
      subjectA = Azure::Storage::Common::Client.create_from_env
      subjectB = Azure::Storage::Common::Client.create_from_connection_string(ENV["AZURE_STORAGE_CONNECTION_STRING"])
      _(subjectA.storage_account_name).must_equal subjectB.storage_account_name
      _(subjectA.storage_access_key).must_equal subjectB.storage_access_key
      _(subjectA.storage_sas_token).must_equal subjectB.storage_sas_token
      _(subjectA.storage_blob_host).must_equal subjectB.storage_blob_host
      _(subjectA.storage_table_host).must_equal subjectB.storage_table_host
      _(subjectA.storage_queue_host).must_equal subjectB.storage_queue_host
      _(subjectA.storage_file_host).must_equal subjectB.storage_file_host
    end
  end
end
