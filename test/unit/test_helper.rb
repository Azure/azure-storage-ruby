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

require "test_helper"
require "azure/storage/blob"
require "azure/storage/queue"
require "azure/storage/file"
require "azure/storage/table"
require "azure/storage/common"

module Kernel
  def clear_storage_envs
    removed = {}
    Azure::Storage::Common::ClientOptions.env_vars_mapping.keys.each do |k|
      if ENV.include? k
        removed[k] = ENV[k]
        ENV.delete(k)
      end
    end
    removed
  end

  def clear_storage_instance_variables
    removed = {}
    Azure::Storage::Common::Configurable.keys.each do |key|
      if Azure::Storage::Common::Client::instance_variables.include? :"@#{key}"
        removed[key] = Azure::Storage.send(key)
        Azure::Storage::Common::Client::instance_variable_set(:"@#{key}", nil)
      end
    end
    removed
  end

  def restore_storage_envs(removed)
    removed.each do |k, v|
      ENV[k] = v
    end
  end

  def restore_storage_instance_variables(removed)
    removed.each do |k, v|
      Azure::Storage::Common::Client::instance_variable_set(:"@#{k}", v)
    end
  end

  def vars_env_mapping
    @vars_env = Azure::Storage::Common::ClientOptions.env_vars_mapping.invert unless defined? @vars_env
    @vars_env
  end

  def vars_cs_mapping
    @vars_cs = Azure::Storage::Common::ClientOptions.connection_string_mapping.invert unless defined? @vars_cs
    @vars_cs
  end

  def set_storage_envs(vals = {})
    vals.each do |k, v|
      ENV[vars_env_mapping[k]] = v if vars_env_mapping.key?(k)
    end
  end

  def get_connection_string(vals = {})
    vals.map { |k, v| "#{vars_cs_mapping[k]}=#{v}" if vars_cs_mapping.key?(k) }.join(";")
  end
end
