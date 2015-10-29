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

require 'azure_storage/core'
require 'azure_storage/core/client_options_error'
require 'azure_storage/core/auth/signer'
require 'time'
require 'uri'

# @see https://msdn.microsoft.com/library/azure/dn140255.aspx for more information on construction
module Azure::Storage
  module Auth
    class SharedAccessSignature

      DEFAULTS = {
        permissions: 'r',
        version: Azure::Storage::Default::STG_VERSION
      }

      KEY_MAPPINGS = {
        version:              :sv,
        permissions:          :sp,
        start:                :st,
        expiry:               :se,
        identifier:           :si
      }

      BLOB_KEY_MAPPINGS = {
        resource:             :sr,
        cache_control:        :rscc,
        content_disposition:  :rscd,
        content_encoding:     :rsce,
        content_language:     :rscl,
        content_type:         :rsct
      }

      TABLE_KEY_MAPPINGS = {
        tablename:            :tn,
        startpk:              :spk,
        endpk:                :epk,
        startrk:              :srk,
        endrk:                :erk
      }

      OPTIONAL_QUERY_PARAMS = [:sp, :si, :rscc, :rscd, :rsce, :rscl, :rsct, :spk, :srk, :epk, :erk]

      attr :account_name

      # Public: Initialize the SharedAccessSignature generator
      #
      # @param account_name [String] The account name. Defaults to the one in the global configuration.
      # @param access_key [String]   The access_key encoded in Base64. Defaults to the one in the global configuration.
      def initialize(account_name=Azure::Storage.storage_account_name, access_key=Azure::Storage.storage_access_key)
        @account_name = account_name
        @signer = Azure::Core::Auth::Signer.new(access_key)
      end

      # Shared Access Signature for the given path and options
      # @param path     [String] Path of the URI
      # @param options  [Hash]
      #
      # ==== Options
      #
      # * +:permissions+  - String. Combination of 'r','w','d','l' (container only) in this order. Default 'r'
      # * +:start+        - String. UTC Date/Time in ISO8601 format. Optional.
      # * +:expiry+       - String. UTC Date/Time in ISO8601 format. Optional. Default now + 30 minutes.
      # * +:identifier+   - String. Identifier for stored access policy. Optional
      #
      # Below options for Blob only
      # * +:resource+            - String. Resource type, either 'b' (blob) or 'c' (container). Default 'b'
      # * +:cache_control+       - String. Response header override. Optional.
      # * +:content_disposition+ - String. Response header override. Optional.
      # * +:content_encoding+    - String. Response header override. Optional.
      # * +:content_language+    - String. Response header override. Optional.
      # * +:content_type+        - String. Response header override. Optional.
      #
      # Below options for table only
      # * +:startpk+             - String. The start partition key of a specified partition key range. Optional but startpk must accompany startrk.
      # * +:endpk+               - String. The end partition key of a specified partition key range. Optional but endpk must accompany endrk.
      # * +:startrk+             - String. The start row key of a specified row key range. Optional.
      # * +:endrk+               - String. The end row key of a specified row key range. Optional.
      def generate(path, options={})
        service_type = options[:service_type] || Azure::Storage::ServiceType::BLOB
        options.delete(:service_type) if options.key?(:service_type)

        options[:expiry] ||= (Time.now + 60*30).utc.iso8601

        raise InvalidOptionsError,"SAS version cannot be set" if options[:version]

        defs = DEFAULTS
        valid_mappings = KEY_MAPPINGS
        if service_type == Azure::Storage::ServiceType::BLOB
          defs.merge!(resource: 'b')
          valid_mappings.merge!(BLOB_KEY_MAPPINGS)
        elsif service_type == Azure::Storage::ServiceType::TABLE
          defs.merge!(tablename: path)
          valid_mappings.merge!(TABLE_KEY_MAPPINGS)
        end

        invalid_options = options.reject { |k,v| valid_mappings.key?(k) }
        raise InvalidOptionsError,"invalid options #{invalid_options} provided for SAS token generate" if invalid_options.length > 0

        options.merge!(defs)

        # Order is significant
        # The newlines from empty strings here are required
        signable_string =
        [
          options[:permissions],
          options[:start],
          options[:expiry],
          "/#{service_type}/#{account_name}#{path.start_with?('/') ? '' : '/'}#{path}",
          options[:identifier],
          options[:version],
          options[:cache_control],
          options[:content_disposition],
          options[:content_encoding],
          options[:content_language],
          options[:content_type]
        ].join("\n")

        query_hash = Hash[options.map { |k, v| [KEY_MAPPINGS[k], v] }]
        .reject { |k, v| OPTIONAL_QUERY_PARAMS.include?(k) && v.to_s == '' }
        .merge( sig: @signer.sign(signable_string) )

        sas_params = URI.encode_www_form(query_hash)
      end

      # A customised URI reflecting options for the resource signed with Shared Access Signature
      # @param uri      [URI] uri to resource including query options
      # @param options  [Hash]
      #
      # ==== Options
      #
      # * +:permissions+  - String. Combination of 'r','w','d','l' (container only) in this order. Default 'r'
      # * +:start+        - String. UTC Date/Time in ISO8601 format. Optional.
      # * +:expiry+       - String. UTC Date/Time in ISO8601 format. Optional. Default now + 30 minutes.
      # * +:identifier+   - String. Identifier for stored access policy. Optional
      #
      # Below options for Blob only
      # * +:resource+            - String. Resource type, either 'b' (blob) or 'c' (container). Default 'b'
      # * +:cache_control+       - String. Response header override. Optional.
      # * +:content_disposition+ - String. Response header override. Optional.
      # * +:content_encoding+    - String. Response header override. Optional.
      # * +:content_language+    - String. Response header override. Optional.
      # * +:content_type+        - String. Response header override. Optional.
      #
      # Below options for table only
      # * +:tablename+           - String. Table name for SAS
      # * +:startpk+             - String. The start partition key of a specified partition key range. Optional but startpk must accompany startrk.
      # * +:endpk+               - String. The end partition key of a specified partition key range. Optional but endpk must accompany endrk.
      # * +:startrk+             - String. The start row key of a specified row key range. Optional.
      # * +:endrk+               - String. The end row key of a specified row key range. Optional.
      def sign_uri(uri, options)
        parsed_query = CGI::parse(uri.query || '').inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}

        if parsed_query.has_key?(:restype)
          options[:resource] = parsed_query[:restype].first == 'container' ? 'c' : 'b'
        end

        if options[:service_type] == nil
          host_splits = uri.host.split('.')
          options[:service_type] = host_splits[1] if host_splits.length > 1 && host_splits[0] == account_name
        end

        sas_params = generate(uri.path, options)

        URI.parse(uri.to_s + (uri.query.nil? ? '?' : '&') + sas_params)
      end

    end
  end
end
