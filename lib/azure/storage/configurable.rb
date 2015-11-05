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

module Azure::Storage
  # The Azure::Storage::Configurable module provides basic configuration for Azure storage activities.
  module Configurable

    # @!attribute [w] storage_access_key
    #   @return [String] Azure Storage access key.
    # @!attribute storage_account_name
    #   @return [String] Azure Storage account name.
    # @!attribute storage_connection_string
    #   @return [String] Azure Storage connection string.
    # @!attribute storage_blob_host
    #   @return [String] Set the host for the Blob service. Only set this if you want
    #     something custom (like, for example, to point this to a LocalStorage
    #     emulator). This should be the complete host, including http:// at the
    #     start. When using the emulator, make sure to include your account name at
    #     the end.
    # @!attribute storage_table_host
    #   @return [String] Set the host for the Table service. Only set this if you want
    #     something custom (like, for example, to point this to a LocalStorage
    #     emulator). This should be the complete host, including http:// at the
    #     start. When using the emulator, make sure to include your account name at
    #     the end.
    # @!attribute storage_queue_host
    #   @return [String] Set the host for the Queue service. Only set this if you want
    #     something custom (like, for example, to point this to a LocalStorage
    #     emulator). This should be the complete host, including http:// at the
    #     start. When using the emulator, make sure to include your account name at
    #     the end.

    attr_accessor :storage_access_key,
                  :storage_account_name,
                  :storage_connection_string

    attr_writer :storage_table_host,
                :storage_blob_host,
                :storage_queue_host

    class << self
      # List of configurable keys for {Azure::Client}
      # @return [Array] of option keys
      def keys
        @keys ||= [
          :storage_access_key,
          :storage_account_name,
          :storage_connection_string,
          :storage_table_host,
          :storage_blob_host,
          :storage_queue_host
        ]
      end
    end

    # Set configuration options using a block
    def configure
      yield self
    end

    # Reset configuration options to default values
    def reset_config!(options = {})
      Azure::Storage::Configurable.keys.each do |key|
        value = if self == Azure::Storage
                  Azure::Storage::Default.options[key]
                else
                  Azure::Storage.send(key)
                end
        instance_variable_set(:"@#{key}", options.fetch(key, value))
      end
      self.send(:reset_agents!) if self.respond_to?(:reset_agents!)
      self
    end

    alias setup reset_config!
    
    # Storage queue host
    # @return [String]
    def storage_queue_host
      @storage_queue_host || default_host(:queue)
    end

    # Storage blob host
    # @return [String]
    def storage_blob_host
      @storage_blob_host || default_host(:blob)
    end

    # Storage table host
    # @return [String]
    def storage_table_host
      @storage_table_host || default_host(:table)
    end
    
    # Storage file host
    # @return [String]
    def storage_file_host
      @storage_file_host || default_host(:file)
    end

    def config
      self
    end

    private

    def default_host(service)
      "https://#{storage_account_name}.#{service}.core.windows.net"
    end

    def options
      Hash[Azure::Storage::Configurable.keys.map { |key| [key, instance_variable_get(:"@#{key}")] }]
    end

  end
end