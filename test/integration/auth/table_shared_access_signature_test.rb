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
  subject { Azure::Storage::Table::TableService.new }
  let(:generator) { Azure::Storage::Core::Auth::SharedAccessSignature.new }
  let(:table_name) { TableNameHelper.name }
  let(:entity1) { { PartitionKey: "test-partition-key-1", RowKey: "1-1", Content: "test entity content-1" } }
  let(:entity2) { { PartitionKey: "test-partition-key-2", RowKey: "2-1", Content: "test entity content-2" } }
  let(:entity3) { { PartitionKey: "test-partition-key-3", RowKey: "3-1", Content: "test entity content-3" } }
  let(:entity4) { { PartitionKey: "test-partition-key-4", RowKey: "4-1", Content: "test entity content-4" } }
  before {
    subject.create_table table_name
    subject.insert_entity table_name, entity1
    subject.insert_entity table_name, entity2
    subject.insert_entity table_name, entity3
  }
  after { TableNameHelper.clean }

  it "queries a table entity with SAS in connection string" do
    sas_token = generator.generate_service_sas_token table_name, service: "t", permissions: "r", protocol: "https,http"
    connection_string = "TableEndpoint=https://#{ENV['AZURE_STORAGE_ACCOUNT']}.table.core.windows.net;SharedAccessSignature=#{sas_token}"
    sas_client = Azure::Storage::Client::create_from_connection_string connection_string
    client = sas_client.table_client
    query = { filter: "RowKey eq '1-1'" }
    result = client.query_entities table_name, query
    result.wont_be_nil
    result[0].properties["PartitionKey"].must_equal entity1[:PartitionKey]
    result[0].properties["Content"].must_equal entity1[:Content]
  end

  it "queries a table entity with a SAS" do
    sas_token = generator.generate_service_sas_token table_name, service: "t", permissions: "r", protocol: "https,http"
    signer = Azure::Storage::Core::Auth::SharedAccessSignatureSigner.new Azure::Storage.storage_account_name, sas_token
    client = Azure::Storage::Table::TableService.new(signer: signer)
    query = { filter: "RowKey eq '1-1'" }
    result = client.query_entities table_name, query
    result.wont_be_nil
    result[0].properties["PartitionKey"].must_equal entity1[:PartitionKey]
    result[0].properties["Content"].must_equal entity1[:Content]
  end

  it "inserts a table entity with a SAS" do
    sas_token = generator.generate_service_sas_token table_name, service: "t", permissions: "a", protocol: "https"
    signer = Azure::Storage::Core::Auth::SharedAccessSignatureSigner.new Azure::Storage.storage_account_name, sas_token
    client = Azure::Storage::Table::TableService.new(signer: signer)
    result = client.insert_entity table_name, entity4
    result.wont_be_nil
    result.properties["PartitionKey"].must_equal entity4[:PartitionKey]
    result.properties["Content"].must_equal entity4[:Content]
  end

  it "updates a table entity with a SAS" do
    sas_token = generator.generate_service_sas_token table_name, service: "t", permissions: "u", protocol: "https,http"
    signer = Azure::Storage::Core::Auth::SharedAccessSignatureSigner.new Azure::Storage.storage_account_name, sas_token
    client = Azure::Storage::Table::TableService.new(signer: signer)
    entity2[:Content] = "test entity content-2-updated"
    result = client.update_entity table_name, entity2
    result.wont_be_nil
  end

  it "queries a table entity with pk in the SAS" do
    sas_token = generator.generate_service_sas_token table_name, service: "t", permissions: "r",
      startpk: "test-partition-key-1", endpk: "test-partition-key-2", protocol: "https,http"
    signer = Azure::Storage::Core::Auth::SharedAccessSignatureSigner.new Azure::Storage.storage_account_name, sas_token
    client = Azure::Storage::Table::TableService.new(signer: signer)
    query = { top: 10 }
    result = client.query_entities table_name, query
    result.wont_be_nil
    result.length.must_equal 2
  end

  it "queries a table entity with rk in the SAS" do
    sas_token = generator.generate_service_sas_token table_name, service: "t", permissions: "r",
      startpk: "test-partition-key-1", endpk: "test-partition-key-2",
      startrk: "1-0", endrk: "2-0", protocol: "https,http"
    signer = Azure::Storage::Core::Auth::SharedAccessSignatureSigner.new Azure::Storage.storage_account_name, sas_token
    client = Azure::Storage::Table::TableService.new(signer: signer)
    query = { top: 10 }
    result = client.query_entities table_name, query
    result.wont_be_nil
    result.length.must_equal 1
  end

  it "deletes a table entity with a SAS" do
    sas_token = generator.generate_service_sas_token table_name, service: "t", permissions: "d", protocol: "https"
    signer = Azure::Storage::Core::Auth::SharedAccessSignatureSigner.new Azure::Storage.storage_account_name, sas_token
    client = Azure::Storage::Table::TableService.new(signer: signer)
    entity2[:Content] = "test entity content-2-updated"
    result = client.delete_entity table_name, entity3[:PartitionKey], entity3[:RowKey]
    result.must_be_nil
  end
end
