#-------------------------------------------------------------------------
# # Copyright (c) Microsoft and contributors. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#--------------------------------------------------------------------------

require 'unit/storage/test_helper'

describe Azure::Storage::Client do

  before do

    @account_name = 'mockaccount'
    @access_key = 'YWNjZXNzLWtleQ=='
    @mock_blob_host_with_protocol = 'http://www.blob.net'
    @mock_sas = '?sv=2014-02-14&sr=b&sig=T42yqGMPksTcuMENIOyM%2F25P%2BMO1z2w1NdFwKucbGaA%3D&se=2015-07-10T03%3A26%3A27Z&sp=rwd'

    @account_key_options = {
      :storage_account_name => @account_name,
      :storage_access_key => @access_key
    }

    @account_key_protocol_options = {
      :storage_account_name => @account_name,
      :storage_access_key => @access_key,
      :default_endpoints_protocol => 'http'
    }

    @devstore_options = {
      :use_development_storage => true,
      :development_storage_proxy_uri => 'http://192.168.0.1'
    }

    @account_key_suffix_options = {
      :storage_account_name => @account_name,
      :storage_access_key => @access_key,
      :storage_dns_suffix => 'mocksuffix.com'
    }

    @removed = clear_storage_envs
  end

  describe 'when create with empty options' do

    it 'should fail with nil params or call create_from_env directly' do
      lambda { Azure::Storage::Client.create }.must_raise(Azure::Storage::InvalidOptionsError)
      lambda { Azure::Storage::Client.new }.must_raise(Azure::Storage::InvalidOptionsError)
      lambda { Azure::Storage::Client.create_from_env }.must_raise(Azure::Storage::InvalidOptionsError)
    end

    it 'should fail with empty Hash' do
      lambda { Azure::Storage::Client.create({}) }.must_raise(Azure::Storage::InvalidOptionsError)
      lambda { Azure::Storage::Client.new({}) }.must_raise(Azure::Storage::InvalidOptionsError)
    end

    it 'should fail with empty connection string' do
      lambda { Azure::Storage::Client.create_from_connection_string("") }.must_raise(Azure::Storage::InvalidConnectionStringError)
    end

  end

  describe 'when create development' do

    it 'should succeed by Hash, connection_string or method' do
      client1 = Azure::Storage::Client.create(@devstore_options)
      client2 = Azure::Storage::Client.create(get_connection_string(@devstore_options))
      client3 = Azure::Storage::Client.create_development(@devstore_options[:development_storage_proxy_uri])
      [client1,client2,client3].each do |c|
        c.wont_be_nil
        c.storage_account_name.must_equal(Azure::Storage::StorageServiceClientConstants::DEVSTORE_STORAGE_ACCOUNT)
        c.storage_access_key.must_equal(Azure::Storage::StorageServiceClientConstants::DEVSTORE_STORAGE_ACCESS_KEY)
        c.storage_blob_host.must_include(@devstore_options[:development_storage_proxy_uri])
        c.use_path_style_uri.must_equal(true)
      end
    end

    it 'should set the default proxy_uri if not given in all methods' do

      ENV['EMULATED'] = 'true'

      client1 = Azure::Storage::Client.new(:use_development_storage => true)
      client2 = Azure::Storage::Client.new(get_connection_string(:use_development_storage => true))
      client3 = Azure::Storage::Client.create_development
      client4 = Azure::Storage::Client.new
      [client1,client2,client3,client4].each do |c|
        c.wont_be_nil
        c.storage_account_name.must_equal(Azure::Storage::StorageServiceClientConstants::DEVSTORE_STORAGE_ACCOUNT)
        c.storage_access_key.must_equal(Azure::Storage::StorageServiceClientConstants::DEVSTORE_STORAGE_ACCESS_KEY)
        c.storage_blob_host.must_include(Azure::Storage::StorageServiceClientConstants::DEV_STORE_URI)
      end

      ENV.delete('EMULATED')
    end

  end

  describe 'when create with account name/key' do

    it 'should succeed with Hash or connection_string' do
      client1 = Azure::Storage::Client.new(@account_key_options)
      client2 = Azure::Storage::Client.create_from_connection_string(get_connection_string(@account_key_options))

      [client1,client2].each do |c|
        c.wont_be_nil
        c.storage_account_name.must_equal(@account_name)
        c.storage_access_key.must_equal(@access_key)
        c.storage_table_host.must_include(Azure::Storage::StorageServiceClientConstants::DEFAULT_ENDPOINT_SUFFIX)
        c.default_endpoints_protocol.must_equal('https')
        c.use_path_style_uri.must_equal(false)
      end
    end

    it 'should set hosts differently if suffix is set' do
      c = Azure::Storage::Client.new(@account_key_suffix_options)
      c.wont_be_nil
      c.storage_account_name.must_equal(@account_name)
      c.storage_access_key.must_equal(@access_key)
      c.storage_queue_host.must_include(@account_key_suffix_options[:storage_dns_suffix])
    end

    it 'should set scheme if protocol is set' do
      c = Azure::Storage::Client.create(@account_key_protocol_options)
      c.wont_be_nil
      c.storage_account_name.must_equal(@account_name)
      c.storage_access_key.must_equal(@access_key)
      c.default_endpoints_protocol.must_equal('http')
      c.storage_blob_host.must_include('http://')
    end

    it 'should set host if given' do
      opts = @account_key_options.merge( { :storage_blob_host => @mock_blob_host_with_protocol})
      c = Azure::Storage::Client.new(get_connection_string( opts))
      c.wont_be_nil
      c.storage_account_name.must_equal(@account_name)
      c.storage_access_key.must_equal(@access_key)
      lambda { c.default_endpoints_protocol }.must_raise(NoMethodError)
      c.storage_blob_host.must_equal(@mock_blob_host_with_protocol)
    end

    it 'should fail host if protocol are dup set' do
      opts = @account_key_protocol_options.merge( { :storage_blob_host => @mock_blob_host_with_protocol})
      lambda { c = Azure::Storage::Client.new(opts) }.must_raise(Azure::Storage::InvalidOptionsError)
    end
  end

  describe 'when create for anonymous or with sas' do

    it 'should succeed if sas_token is given with name' do
      opts = {:storage_account_name => @account_name, :storage_sas_token => @mock_sas}
      c = Azure::Storage::Client.create(opts)
      c.wont_be_nil
      c.storage_account_name.must_equal(@account_name)
      lambda { c.storage_access_key }.must_raise(NoMethodError)
      c.storage_sas_token.must_equal(@mock_sas)
    end

    it 'should fail if both sas_token and key' do
      opts = @account_key_options.merge( { :storage_sas_token => @mock_sas})
      lambda { c = Azure::Storage::Client.create(opts) }.must_raise(Azure::Storage::InvalidOptionsError)
    end

    it 'should succeed if given a host anonymously' do
      opts = {:storage_blob_host => @mock_blob_host_with_protocol}
      c = Azure::Storage::Client.create(opts)
      c.wont_be_nil
      c.storage_blob_host.must_equal(@mock_blob_host_with_protocol)
      lambda { c.storage_queue_host }.must_raise(NoMethodError)
    end
  end

  describe 'when create from env' do

    it 'should fail if no environment variables are set' do
      lambda { Azure::Storage::Client.create }.must_raise(Azure::Storage::InvalidOptionsError)
    end

    it 'should succeed if env vars are set and match the settings' do
      set_storage_envs(@account_key_options)

      client = Azure::Storage::Client.create
      client.wont_be_nil
      client.storage_account_name.must_equal(@account_key_options[:storage_account_name])
      client.storage_access_key.must_equal(@account_key_options[:storage_access_key])

      clear_storage_envs
    end

  end

  after do
    restore_storage_envs(@removed)
  end

end
