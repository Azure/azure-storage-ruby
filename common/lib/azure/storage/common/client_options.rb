# frozen_string_literal: true

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

require "uri"
require "azure/storage/common/client_options_error"
require "azure/storage/common/core/auth/anonymous_signer"

module Azure::Storage::Common
  module ClientOptions
    attr_accessor :ca_file, :ssl_version, :ssl_min_version, :ssl_max_version

    # Public: Reset options for [Azure::Storage::Common::Client]
    #
    # ==== Attributes
    #
    # * +options+                         - Hash | String. Optional parameters or storage connection string.
    #
    # ==== Options
    #
    # Accepted key/value pairs in options parameter are:
    #
    # * +:use_development_storage+        - TrueClass|FalseClass. Whether to use storage emulator.
    # * +:development_storage_proxy_uri+  - String. Used with +:use_development_storage+ if emulator is hosted other than localhost.
    # * +:storage_connection_string+      - String. The storage connection string.
    # * +:storage_account_name+           - String. The name of the storage account.
    # * +:storage_access_key+             - Base64 String. The access key of the storage account.
    # * +:storage_sas_token+              - String. The signed access signature for the storage account or one of its service.
    # * +:storage_blob_host+              - String. Specified Blob serivce endpoint or hostname
    # * +:storage_table_host+             - String. Specified Table serivce endpoint or hostname
    # * +:storage_queue_host+             - String. Specified Queue serivce endpoint or hostname
    # * +:storage_dns_suffix+             - String. The suffix of a regional Storage Serivce, to
    # * +:default_endpoints_protocol+     - String. http or https
    # * +:use_path_style_uri+             - String. Whether use path style URI for specified endpoints
    # * +:ca_file+                        - String. File path of the CA file if having issue with SSL
    # * +:ssl_version+                    - Symbol. The ssl version to be used, sample: :TLSv1_1, :TLSv1_2, for the details, see https://github.com/ruby/openssl/blob/master/lib/openssl/ssl.rb
    # * +:ssl_min_version+                - Symbol. The min ssl version supported, only supported in Ruby 2.5+
    # * +:ssl_max_version+                - Symbol. The max ssl version supported, only supported in Ruby 2.5+
    #
    # The valid set of options include:
    # * Storage Emulator: +:use_development_storage+ required, +:development_storage_proxy_uri+ optionally
    # * Storage account name and key: +:storage_account_name+ and +:storage_access_key+ required, set +:storage_dns_suffix+ necessarily
    # * Storage account name and SAS token: +:storage_account_name+ and +:storage_sas_token+ required, set +:storage_dns_suffix+ necessarily
    # * Specified hosts and SAS token: At least one of the service host and SAS token. It's up to user to ensure the SAS token is suitable for the serivce
    # * Anonymous Blob: only +:storage_blob_host+, if it is to only access blobs within a container
    #
    # Additional notes:
    # * Specified hosts can be set when use account name with access key or sas token
    # * +:default_endpoints_protocol+ can be set if the scheme is not specified in hosts
    # * Storage emulator always use path style URI
    #
    # When empty options are given, it will try to read settings from Environment Variables. Refer to [Azure::Storage::Common:ClientOptions.env_vars_mapping] for the mapping relationship
    #
    # @return [Azure::Storage::Common::Client]
    def reset!(options = {})
      if options.is_a? String
        options = parse_connection_string(options)
      elsif options.is_a? Hash
        # When the options are provided via singleton setup: Azure::Storage.setup()
        options = setup_options if options.length == 0

        options = parse_connection_string(options[:storage_connection_string]) if options[:storage_connection_string]
      end

      # Load from environment when no valid input
      options = load_env if options.length == 0

      @ca_file = options.delete(:ca_file)
      @ssl_version = options.delete(:ssl_version)
      @ssl_min_version = options.delete(:ssl_min_version)
      @ssl_max_version = options.delete(:ssl_max_version)
      @options = filter(options)
      self.send(:reset_config!, @options) if self.respond_to?(:reset_config!)
      self
    end

    # Check if this client is configured with the same options
    def same_options?(opts)
      opts.length == 0 || opts.hash == options.hash
    end

    # The options after validated and normalized
    #
    # @return [Hash]
    def options
      @options ||= {}
    end

    # The valid options for the storage client
    #
    # @return [Array]
    def self.valid_options
      @valid_options ||= [
        :use_development_storage,
        :development_storage_proxy_uri,
        :storage_account_name,
        :storage_access_key,
        :storage_connection_string,
        :storage_sas_token,
        :storage_blob_host,
        :storage_table_host,
        :storage_queue_host,
        :storage_file_host,
        :storage_dns_suffix,
        :default_endpoints_protocol,
        :use_path_style_uri
      ]
    end

    # The mapping between Storage Environment Variables and the options name
    #
    # @return [Hash]
    def self.env_vars_mapping
      @env_vars_mapping ||= {
        "EMULATED" => :use_development_storage,
        "AZURE_STORAGE_ACCOUNT" => :storage_account_name,
        "AZURE_STORAGE_ACCESS_KEY" => :storage_access_key,
        "AZURE_STORAGE_CONNECTION_STRING" => :storage_connection_string,
        "AZURE_STORAGE_BLOB_HOST" => :storage_blob_host,
        "AZURE_STORAGE_TABLE_HOST" => :storage_table_host,
        "AZURE_STORAGE_QUEUE_HOST" => :storage_queue_host,
        "AZURE_STORAGE_FILE_HOST" => :storage_file_host,
        "AZURE_STORAGE_SAS_TOKEN" => :storage_sas_token,
        "AZURE_STORAGE_DNS_SUFFIX" => :storage_dns_suffix
      }
    end

    # The mapping between Storage Connection String items and the options name
    #
    # @return [Hash]
    def self.connection_string_mapping
      @connection_string_mapping ||= {
        "UseDevelopmentStorage" => :use_development_storage,
        "DevelopmentStorageProxyUri" => :development_storage_proxy_uri,
        "DefaultEndpointsProtocol" => :default_endpoints_protocol,
        "AccountName" => :storage_account_name,
        "AccountKey" => :storage_access_key,
        "BlobEndpoint" => :storage_blob_host,
        "TableEndpoint" => :storage_table_host,
        "QueueEndpoint" => :storage_queue_host,
        "FileEndpoint" => :storage_file_host,
        "SharedAccessSignature" => :storage_sas_token,
        "EndpointSuffix" => :storage_dns_suffix
      }
    end

    private

      def method_missing(method_name, *args, &block)
        return super unless options.key? method_name
        options[method_name]
      end

      def filter(opts = {})
        results = {}

        # P1 - develpoment storage
        begin
          results = validated_options(opts,
                                      required: [:use_development_storage],
                                      optional: [:development_storage_proxy_uri])
          results[:use_development_storage] = true
          proxy_uri = results[:development_storage_proxy_uri] ||= StorageServiceClientConstants::DEV_STORE_URI
          results.merge!(storage_account_name: StorageServiceClientConstants::DEVSTORE_STORAGE_ACCOUNT,
                          storage_access_key: StorageServiceClientConstants::DEVSTORE_STORAGE_ACCESS_KEY,
                          storage_blob_host: "#{proxy_uri}:#{StorageServiceClientConstants::DEVSTORE_BLOB_HOST_PORT}",
                          storage_table_host: "#{proxy_uri}:#{StorageServiceClientConstants::DEVSTORE_TABLE_HOST_PORT}",
                          storage_queue_host: "#{proxy_uri}:#{StorageServiceClientConstants::DEVSTORE_QUEUE_HOST_PORT}",
                          storage_file_host: "#{proxy_uri}:#{StorageServiceClientConstants::DEVSTORE_FILE_HOST_PORT}",
                          use_path_style_uri: true)
          return results
        rescue InvalidOptionsError
        end

        # P2 - explicit hosts with account connection string
        begin
          results = validated_options(opts,
                                      required: [:storage_connection_string],
                                      optional: [:use_path_style_uri])
          results[:use_path_style_uri] = results.key?(:use_path_style_uri)
          normalize_hosts(results)
          return results
        rescue InvalidOptionsError
        end

        # P3 - account name and key or sas with default hosts or an end suffix
        begin
          results = validated_options(opts,
                                      required: [:storage_account_name],
                                      only_one: [:storage_access_key, :storage_sas_token, :signer],
                                      optional: [:default_endpoints_protocol, :storage_dns_suffix])
          protocol = results[:default_endpoints_protocol] ||= StorageServiceClientConstants::DEFAULT_PROTOCOL
          suffix = results[:storage_dns_suffix] ||= StorageServiceClientConstants::DEFAULT_ENDPOINT_SUFFIX
          account = results[:storage_account_name]
          results.merge!(storage_blob_host: "#{protocol}://#{account}.#{ServiceType::BLOB}.#{suffix}",
                          storage_table_host: "#{protocol}://#{account}.#{ServiceType::TABLE}.#{suffix}",
                          storage_queue_host: "#{protocol}://#{account}.#{ServiceType::QUEUE}.#{suffix}",
                          storage_file_host: "#{protocol}://#{account}.#{ServiceType::FILE}.#{suffix}",
                          use_path_style_uri: false)
          return results
        rescue InvalidOptionsError
        end

        # P4 - explicit hosts with account name and key
        begin
          results = validated_options(opts,
                                      required: [:storage_account_name, :storage_access_key],
                                      at_least_one: [:storage_blob_host, :storage_table_host, :storage_file_host, :storage_queue_host],
                                      optional: [:use_path_style_uri, :default_endpoints_protocol])
          results[:use_path_style_uri] = results.key?(:use_path_style_uri)
          normalize_hosts(results)
          return results
        rescue InvalidOptionsError
        end

        # P5 - anonymous or sas only for one or more particular services, options with account name/key + hosts should be already validated in P4
        begin
          results = validated_options(opts,
                                      at_least_one: [:storage_blob_host, :storage_table_host, :storage_file_host, :storage_queue_host],
                                      optional: [:use_path_style_uri, :default_endpoints_protocol, :storage_sas_token])
          results[:use_path_style_uri] = results.key?(:use_path_style_uri)
          normalize_hosts(results)
          # Adds anonymous signer if no sas token
          results[:signer] = Azure::Storage::Common::Core::Auth::AnonymousSigner.new unless results.key?(:storage_sas_token)
          return results
        rescue InvalidOptionsError
        end

        # P6 - account name and key or sas with explicit hosts
        begin
          results = validated_options(opts,
                                      required: [:storage_account_name],
                                      only_one: [:storage_access_key, :storage_sas_token],
                                      at_least_one: [:storage_blob_host, :storage_table_host, :storage_file_host, :storage_queue_host])
          results[:use_path_style_uri] = results.key?(:use_path_style_uri)
          normalize_hosts(results)
          return results
        rescue InvalidOptionsError
        end

        raise InvalidOptionsError, "options provided are not valid set: #{opts}" # wrong opts if move to this line
      end

      def normalize_hosts(options)
        if options[:default_endpoints_protocol]
          [:storage_blob_host, :storage_table_host, :storage_file_host, :storage_queue_host].each do |k|
            if options[k]
              raise InvalidOptionsError, "Explict host cannot contain scheme if default_endpoints_protocol is set." if options[k] =~ /^https?/
              options[k] = "#{options[:default_endpoints_protocol]}://#{options[k]}"
            end
          end
        end
      end

      def is_base64_encoded
        Proc.new do |i|
          i.is_a?(String) && i =~ /^(?:[A-Za-z0-9+\/]{4})*(?:[A-Za-z0-9+\/]{2}==|[A-Za-z0-9+\/]{3}=|[A-Za-z0-9+\/]{4})$/
        end
      end

      def is_url
        Proc.new do |i|
          i = "http://" + i unless i =~ /\Ahttps?:\/\//
          i =~ URI.regexp(["http", "https"])
        end
      end

      def is_true
        Proc.new { |i| i == true || (i.is_a?(String) && i.downcase == "true") }
      end

      def is_non_empty_string
        Proc.new { |i| i && i.is_a?(String) && i.strip.length }
      end

      def validated_options(opts, requirements = {})
        raise InvalidOptionsError, 'nil is not allowed for option\'s value' if opts.values.any? { |v| v == nil }
        required = requirements[:required] || []
        at_least_one = requirements[:at_least_one] || []
        only_one = requirements[:only_one] || []
        optional = requirements[:optional] || []

        raise InvalidOptionsError, "Not all required keys are provided: #{required}" if required.any? { |k| !opts.key? k }
        raise InvalidOptionsError, "Only one of #{only_one} is required" unless only_one.length == 0 || only_one.count { |k| opts.key? k } == 1
        raise InvalidOptionsError, "At least one of #{at_least_one} is required" unless at_least_one.length == 0 || at_least_one.any? { |k| opts.key? k }

        @@option_validators ||= {
          use_development_storage: is_true,
          development_storage_proxy_uri: is_url,
          storage_account_name: lambda { |i| i.is_a?(String) },
          storage_access_key: is_base64_encoded,
          storage_sas_token: lambda { |i| i.is_a?(String) },
          storage_blob_host: is_url,
          storage_table_host: is_url,
          storage_queue_host: is_url,
          storage_file_host: is_url,
          storage_dns_suffix: is_url,
          default_endpoints_protocol: lambda { |i| ["http", "https"].include? i.downcase },
          use_path_style_uri: is_true,
          signer: lambda { |i| i.is_a? Azure::Core::Auth::Signer} 
        }

        valid_options = required + at_least_one + only_one + optional
        results = {}

        opts.each do |k, v|
          raise InvalidOptionsError, "#{k} is not included in valid options" unless valid_options.length == 0 || valid_options.include?(k)
          unless @@option_validators.key?(k) && @@option_validators[k].call(v)
            raise InvalidOptionsError, "#{k} is invalid"
          end
          results[k] = v
        end
        results
      end

      def load_env
        cs = ENV["AZURE_STORAGE_CONNECTION_STRING"]
        return parse_connection_string(cs) if cs

        opts = {}
        ClientOptions.env_vars_mapping.each { |k, v| opts[v] = ENV[k] if ENV[k] }
        opts
      end

      def parse_connection_string(connection_string)
        opts = {}
        connection_string.split(";").each do |i|
          e = i.index("=") || -1
          raise InvalidConnectionStringError, Azure::Storage::Common::Core::SR::INVALID_CONNECTION_STRING if e < 0 || e == i.length - 1
          key, value = i[0..e - 1], i[e + 1..i.length - 1]
          raise InvalidConnectionStringError, Azure::Storage::Common::Core::SR::INVALID_CONNECTION_STRING_BAD_KEY % key unless ClientOptions.connection_string_mapping.key? key
          raise InvalidConnectionStringError, Azure::Storage::Common::Core::SR::INVALID_CONNECTION_STRING_EMPTY_KEY % key if value.length == 0
          raise InvalidConnectionStringError, Azure::Storage::Common::Core::SR::INVALID_CONNECTION_STRING_DUPLICATE_KEY % key if opts.key? key
          opts[ClientOptions.connection_string_mapping[key]] = value
        end
        raise InvalidConnectionStringError, Azure::Storage::Common::Core::SR::INVALID_CONNECTION_STRING if opts.length == 0

        opts
      end
  end
end
