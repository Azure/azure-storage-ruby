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
                  :storage_connection_string,
                  :storage_sas_token

    attr_writer :storage_table_host,
                :storage_blob_host,
                :storage_queue_host,
                :storage_file_host

    attr_reader :signer

    class << self
      # List of configurable keys for {Azure::Client}
      # @return [Array] of option keys
      def keys
        @keys ||= [
          :storage_access_key,
          :storage_account_name,
          :storage_connection_string,
          :storage_sas_token,
          :storage_table_host,
          :storage_blob_host,
          :storage_queue_host,
          :storage_file_host
        ]
      end
    end

    # Set configuration options using a block
    def configure
      yield self
    end

    def config
      self
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
      setup_signer_for_service
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

    private

    def default_host(service)
      "https://#{storage_account_name}.#{service}.core.windows.net" if storage_account_name
    end

    def setup_options
      opts = {}
      Azure::Storage::Configurable.keys.map do |key|
        opts[key] = Azure::Storage.send(key) if Azure::Storage.send(key)
      end
      opts
    end

    def account_name_from_endpoint endpoint
      return nil if endpoint.nil?
      uri = URI::parse endpoint
      fields = uri.host.split '.'
      fields[0]
    end

    def determine_account_name
      if instance_variable_get(:@storage_account_name).nil?
        hosts = [@storage_blob_host, @storage_table_host, @storage_queue_host, @storage_file_host]
        account_name = nil;
        hosts.each do |host|
          parsed = account_name_from_endpoint host
          if account_name.nil?
            account_name = parsed
          elsif !account_name.nil? and !parsed.nil? and (account_name <=> parsed) != 0
            raise InvalidOptionsError, "Ambiguous account name in service hosts."
          end
        end
        raise InvalidOptionsError, "Cannot identify account name." if account_name.nil?
        @storage_account_name = account_name
      end
    end

    def setup_signer_for_service
      if @storage_sas_token
        determine_account_name
        @signer = Azure::Storage::Core::Auth::SharedAccessSignatureSigner.new @storage_account_name, @storage_sas_token
      end
    end

  end
end