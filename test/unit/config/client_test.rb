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

  before do

    @account_name = "mockaccount"
    @access_key = "YWNjZXNzLWtleQ=="
    @mock_blob_host_with_protocol = "http://www.blob.net"
    @mock_sas = "?sv=2014-02-14&sr=b&sig=T42yqGMPksTcuMENIOyM%2F25P%2BMO1z2w1NdFwKucbGaA%3D&se=2015-07-10T03%3A26%3A27Z&sp=rwd"

    @account_key_options = {
      storage_account_name: @account_name,
      storage_access_key: @access_key
    }

    @account_key_protocol_options = {
      storage_account_name: @account_name,
      storage_access_key: @access_key,
      default_endpoints_protocol: "http"
    }

    @devstore_options = {
      use_development_storage: true,
      development_storage_proxy_uri: "http://192.168.0.1"
    }

    @account_key_suffix_options = {
      storage_account_name: @account_name,
      storage_access_key: @access_key,
      storage_dns_suffix: "mocksuffix.com"
    }

    @ssl_version = :TLSv1_2
    @ssl_min_version = :TLSv1_2
    @ssl_max_version = :TLSv1_2
    @account_key_options_with_ssl_version = {
      storage_account_name: @account_name,
      storage_access_key: @access_key,
      ssl_version: @ssl_version,
      ssl_min_version: @ssl_min_version,
      ssl_max_version: @ssl_max_version
    }

    @removed = clear_storage_envs
  end

  describe "when create with empty options" do

    it "should fail with nil params or call create_from_env directly" do
      removed = clear_storage_instance_variables
      _(lambda { Azure::Storage::Common::Client.create }).must_raise(Azure::Storage::Common::InvalidOptionsError)
      _(lambda { Azure::Storage::Common::Client.new }).must_raise(Azure::Storage::Common::InvalidOptionsError)
      _(lambda { Azure::Storage::Common::Client.create_from_env }).must_raise(Azure::Storage::Common::InvalidOptionsError)
      restore_storage_instance_variables removed
    end

    it "should fail with empty Hash" do
      removed = clear_storage_instance_variables
      _(lambda { Azure::Storage::Common::Client.create({}) }).must_raise(Azure::Storage::Common::InvalidOptionsError)
      _(lambda { Azure::Storage::Common::Client.new({}) }).must_raise(Azure::Storage::Common::InvalidOptionsError)
      restore_storage_instance_variables removed
    end

    it "should fail with empty connection string" do
      removed = clear_storage_instance_variables
      _(lambda { Azure::Storage::Common::Client.create_from_connection_string("") }).must_raise(Azure::Storage::Common::InvalidConnectionStringError)
      restore_storage_instance_variables removed
    end

  end

  describe "when create development" do

    it "should succeed by Hash, connection_string or method" do
      client1 = Azure::Storage::Common::Client.create(@devstore_options)
      client2 = Azure::Storage::Common::Client.create(get_connection_string(@devstore_options))
      client3 = Azure::Storage::Common::Client.create_development(@devstore_options[:development_storage_proxy_uri])

      [client1, client2, client3].each do |c|
        _(c).wont_be_nil
        _(c.storage_account_name).must_equal(Azure::Storage::Common::StorageServiceClientConstants::DEVSTORE_STORAGE_ACCOUNT)
        _(c.storage_access_key).must_equal(Azure::Storage::Common::StorageServiceClientConstants::DEVSTORE_STORAGE_ACCESS_KEY)
        _(c.storage_blob_host).must_include(@devstore_options[:development_storage_proxy_uri])
        _(c.use_path_style_uri).must_equal(true)
      end
    end

    it "should set the default proxy_uri if not given in all methods" do
      ENV["EMULATED"] = "true"
      client1 = Azure::Storage::Common::Client.new(use_development_storage: true)
      client2 = Azure::Storage::Common::Client.new(get_connection_string(use_development_storage: true))
      client3 = Azure::Storage::Common::Client.create_development
      removed = clear_storage_instance_variables
      client4 = Azure::Storage::Common::Client.new
      restore_storage_instance_variables removed

      [client1, client2, client3, client4].each do |c|
        _(c).wont_be_nil
        _(c.storage_account_name).must_equal(Azure::Storage::Common::StorageServiceClientConstants::DEVSTORE_STORAGE_ACCOUNT)
        _(c.storage_access_key).must_equal(Azure::Storage::Common::StorageServiceClientConstants::DEVSTORE_STORAGE_ACCESS_KEY)
        _(c.storage_blob_host).must_include(Azure::Storage::Common::StorageServiceClientConstants::DEV_STORE_URI)
      end

      ENV.delete("EMULATED")
    end

  end

  describe "when create with account name/key" do

    it "should succeed with Hash or connection_string" do
      client1 = Azure::Storage::Common::Client.new(@account_key_options)
      client2 = Azure::Storage::Common::Client.create_from_connection_string(get_connection_string(@account_key_options))

      [client1, client2].each do |c|
        _(c).wont_be_nil
        _(c.storage_account_name).must_equal(@account_name)
        _(c.storage_access_key).must_equal(@access_key)
        _(c.storage_table_host).must_include(Azure::Storage::Common::StorageServiceClientConstants::DEFAULT_ENDPOINT_SUFFIX)
        _(c.default_endpoints_protocol).must_equal("https")
        _(c.use_path_style_uri).must_equal(false)
      end
    end

    it "should set hosts differently if suffix is set" do
      c = Azure::Storage::Common::Client.new(@account_key_suffix_options)
      _(c).wont_be_nil
      _(c.storage_account_name).must_equal(@account_name)
      _(c.storage_access_key).must_equal(@access_key)
      _(c.storage_queue_host).must_include(@account_key_suffix_options[:storage_dns_suffix])
    end

    it "should set scheme if protocol is set" do
      c = Azure::Storage::Common::Client.create(@account_key_protocol_options)
      _(c).wont_be_nil
      _(c.storage_account_name).must_equal(@account_name)
      _(c.storage_access_key).must_equal(@access_key)
      _(c.default_endpoints_protocol).must_equal("http")
      _(c.storage_blob_host).must_include("http://")
    end

    it "should set host if given" do
      opts = @account_key_options.merge(storage_blob_host: @mock_blob_host_with_protocol)
      c = Azure::Storage::Common::Client.new(get_connection_string(opts))
      _(c).wont_be_nil
      _(c.storage_account_name).must_equal(@account_name)
      _(c.storage_access_key).must_equal(@access_key)
      _(lambda { c.default_endpoints_protocol }).must_raise(NoMethodError)
      _(c.storage_blob_host).must_equal(@mock_blob_host_with_protocol)
    end

    it "should fail host if protocol are dup set" do
      opts = @account_key_protocol_options.merge(storage_blob_host: @mock_blob_host_with_protocol)
      _(lambda { Azure::Storage::Common::Client.new(opts) }).must_raise(Azure::Storage::Common::InvalidOptionsError)
    end
  end

  describe "when create for anonymous or with sas" do

    it "should succeed if sas_token is given with name" do
      opts = { storage_account_name: @account_name, storage_sas_token: @mock_sas }
      c = Azure::Storage::Common::Client.create(opts)
      _(c).wont_be_nil
      _(c.storage_account_name).must_equal(@account_name)
      _(lambda { c.options.storage_access_key }).must_raise(NoMethodError)
      _(c.storage_sas_token).must_equal(@mock_sas)
    end

    it "should fail if both sas_token and key" do
      opts = @account_key_options.merge(storage_sas_token: @mock_sas)
      _(lambda { Azure::Storage::Common::Client.create(opts) }).must_raise(Azure::Storage::Common::InvalidOptionsError)
    end

    it "should succeed if given a host anonymously" do
      opts = { storage_blob_host: @mock_blob_host_with_protocol }
      c = Azure::Storage::Common::Client.create(opts)
      _(c).wont_be_nil
      _(c.storage_blob_host).must_equal(@mock_blob_host_with_protocol)
      _(lambda { c.options.storage_queue_host }).must_raise(NoMethodError)
    end
  end

  describe "when create from env" do

    it "should fail if no environment variables are set" do
      removed = clear_storage_instance_variables
      _(lambda { Azure::Storage::Common::Client.create }).must_raise(Azure::Storage::Common::InvalidOptionsError)
      restore_storage_instance_variables removed
    end

    it "calls default options to see if valid"  do
      options = Azure::Storage::Common::Default.options
      for key in Azure::Storage::Common::Configurable::keys
        _(options[key]).must_be_nil
      end
    end

    it "should succeed if env vars are set and match the settings" do
      set_storage_envs(@account_key_options)

      client = Azure::Storage::Common::Client.create
      _(client).wont_be_nil
      _(client.storage_account_name).must_equal(@account_key_options[:storage_account_name])
      _(client.storage_access_key).must_equal(@account_key_options[:storage_access_key])

      clear_storage_envs
    end

  end

  describe "when create with TokenCredential" do
    let(:token) { "TestToken" }
    let(:token_credential) { Azure::Storage::Common::Core::TokenCredential.new token }
    let(:token_signer) { Azure::Storage::Common::Core::Auth::TokenSigner.new token_credential }
    let(:common_signer_client) { Azure::Storage::Common::Client.create storage_account_name: @account_name, signer: token_signer }

    it "should succeed to create blob client if account name and signer are given" do
      _(token_credential.token).must_equal token
      blob_signer_client = Azure::Storage::Blob::BlobService.new(storage_account_name: @account_name, signer: token_signer)
      _(blob_signer_client).wont_be_nil
    end

    it "should succeed to create blob client if common client is given" do
      _(token_credential.token).must_equal token
      blob_signer_client = Azure::Storage::Blob::BlobService.new(client: common_signer_client, signer: token_signer)
      _(blob_signer_client).wont_be_nil
    end

    it "should succeed to create queue client if account name and signer are given" do
      _(token_credential.token).must_equal token
      queue_signer_client = Azure::Storage::Queue::QueueService.new(storage_account_name: @account_name, signer: token_signer)
      _(queue_signer_client).wont_be_nil
    end

    it "should succeed to create queue client if common client is given" do
      _(token_credential.token).must_equal token
      queue_signer_client = Azure::Storage::Queue::QueueService.new(client: common_signer_client, signer: token_signer)
      _(queue_signer_client).wont_be_nil
    end

  end

  describe "when create with ssl options" do
    it "should set the ssl option correctly" do
      client1 = Azure::Storage::Common::Client.new(@account_key_options_with_ssl_version)
      _(client1.ssl_version).must_equal(@ssl_version)
      _(client1.ssl_min_version).must_equal(@ssl_min_version)
      _(client1.ssl_max_version).must_equal(@ssl_max_version)
    end
  end

  after do
    restore_storage_envs(@removed)
  end

end
