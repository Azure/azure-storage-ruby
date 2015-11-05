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
require 'test_helper'
require 'azure/storage'

Azure::Storage.configure do |config|
  config.storage_access_key       = ENV.fetch('AZURE_STORAGE_ACCESS_KEY')
  config.storage_account_name     = ENV.fetch('AZURE_STORAGE_ACCOUNT')
  Azure::Storage.client(:storage_account_name => config.storage_account_name, :storage_access_key => config.storage_access_key)
end
