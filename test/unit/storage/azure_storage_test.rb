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

describe Azure::Storage do

	before do
	  @account_name = 'mockaccount'
    @access_key = 'YWNjZXNzLWtleQ=='
  
    @account_key_options = {
      :storage_account_name => @account_name,
      :storage_access_key => @access_key
    }

		@removed = clear_storage_envs
		set_storage_envs(@account_key_options)
	end

	it 'should setup a singleton by calling setup' do
		client = Azure::Storage.client
		client.wont_be_nil
		client.storage_account_name.must_equal(@account_name)
	end

	it 'should delegate class methods to Azure::Storage::Client' do
		class Azure::Storage::Client
			def mock_method
				'hehe'
			end
		end

		Azure::Storage.mock_method.must_equal('hehe')
	end

	it 'should delegate class methods to singleton client if not in Client class' do
		client = Azure::Storage.client
		def client.mock_method2
			'haha'
		end
		Azure::Storage.mock_method2.must_equal('haha')
	end

	after do
		restore_storage_envs(@removed)
	end
end