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
require 'azure_storage'

module Kernel
  def clear_storage_envs
    removed = {}
    Azure::Storage::ClientOptions.env_vars_mapping.keys.each do |k|
      if ENV.include? k
        removed[k] = ENV[k]
        ENV.delete(k)
      end
    end
    removed
  end

  def restore_storage_envs(removed)
    removed.each do |k,v|
      ENV[k] = v
    end
  end

  def vars_env_mapping
    @vars_env = Azure::Storage::ClientOptions.env_vars_mapping.invert unless defined? @vars_env
    @vars_env
  end

  def vars_cs_mapping
    @vars_cs = Azure::Storage::ClientOptions.connection_string_mapping.invert unless defined? @vars_cs
    @vars_cs
  end

  def set_storage_envs(vals = {})
    vals.each do |k,v|
      ENV[vars_env_mapping[k]] = v if vars_env_mapping.key?(k)
    end
  end

  def get_connection_string(vals = {})
    vals.map { |k,v| "#{vars_cs_mapping[k]}=#{v}" if vars_cs_mapping.key?(k) }.join(';')
  end

end

# mock configuration setup
Azure::Storage.setup(:storage_account_name => 'mockaccount', :storage_access_key => 'YWNjZXNzLWtleQ==')
