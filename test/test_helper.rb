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
require 'dotenv'
Dotenv.load

ENV["AZURE_STORAGE_ACCOUNT"] = 'mockaccount' unless ENV["AZURE_STORAGE_ACCOUNT"]
ENV["AZURE_STORAGE_ACCESS_KEY"] = 'YWNjZXNzLWtleQ==' unless ENV["AZURE_STORAGE_ACCESS_KEY"]

require 'minitest/autorun'
require 'mocha/mini_test'
require 'minitest/reporters'
Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new
require 'timecop'
require 'logger'
require 'stringio'

# add to the MiniTest DSL
module Kernel
  def need_tests_for(name)
    describe "##{name}" do
      it 'needs unit tests' do
        skip ''
      end
    end
  end
end

Dir['./test/support/**/*.rb'].each { |dep| require dep }

# mock configuration setup
require 'azure/storage'

Azure::Storage.config.storage_account_name = 'mockaccount'
Azure::Storage.config.storage_access_key = 'YWNjZXNzLWtleQ=='