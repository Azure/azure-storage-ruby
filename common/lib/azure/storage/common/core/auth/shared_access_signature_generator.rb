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

require "azure/storage/common/core"
require "azure/storage/common/client_options_error"
require "azure/core/auth/signer"
require "time"
require "uri"

# @see https://msdn.microsoft.com/library/azure/dn140255.aspx for more information on construction
module Azure::Storage::Common::Core
  module Auth
    class SharedAccessSignature
      DEFAULTS = {
        permissions: "r",
        version: Azure::Storage::Common::Default::STG_VERSION
      }

      SERVICE_TYPE_MAPPING = {
        b: Azure::Storage::Common::ServiceType::BLOB,
        t: Azure::Storage::Common::ServiceType::TABLE,
        q: Azure::Storage::Common::ServiceType::QUEUE,
        f: Azure::Storage::Common::ServiceType::FILE
      }

      ACCOUNT_KEY_MAPPINGS = {
        version:              :sv,
        service:              :ss,
        resource:             :srt,
        permissions:          :sp,
        start:                :st,
        expiry:               :se,
        protocol:             :spr,
        ip_range:             :sip
      }

      SERVICE_KEY_MAPPINGS = {
        version:              :sv,
        permissions:          :sp,
        start:                :st,
        expiry:               :se,
        identifier:           :si,
        protocol:             :spr,
        ip_range:             :sip
      }

      USER_DELEGATION_KEY_MAPPINGS = {
        signed_oid:           :skoid,
        signed_tid:           :sktid,
        signed_start:         :skt,
        signed_expiry:        :ske,
        signed_service:       :sks,
        signed_version:       :skv
      }

      BLOB_KEY_MAPPINGS = {
        resource:             :sr,
        timestamp:            :snapshot,
        cache_control:        :rscc,
        content_disposition:  :rscd,
        content_encoding:     :rsce,
        content_language:     :rscl,
        content_type:         :rsct
      }

      TABLE_KEY_MAPPINGS = {
        table_name:           :tn,
        startpk:              :spk,
        endpk:                :epk,
        startrk:              :srk,
        endrk:                :erk
      }

      FILE_KEY_MAPPINGS = {
        resource:             :sr,
        cache_control:        :rscc,
        content_disposition:  :rscd,
        content_encoding:     :rsce,
        content_language:     :rscl,
        content_type:         :rsct
      }

      SERVICE_OPTIONAL_QUERY_PARAMS = [:sp, :si, :sip, :spr, :rscc, :rscd, :rsce, :rscl, :rsct, :spk, :srk, :epk, :erk]

      ACCOUNT_OPTIONAL_QUERY_PARAMS = [:st, :sip, :spr]

      attr :account_name

      # Public: Initialize the SharedAccessSignature generator
      #
      # @param account_name [String] The account name. Defaults to the one in the global configuration.
      # @param access_key [String]   The access_key encoded in Base64. Defaults to the one in the global configuration.
      # @param user_delegation_key [Azure::Storage::Common::UserDelegationKey] The user delegation key obtained from
      # calling get_user_delegation_key after authenticating with an Azure Active Directory entity. If present, the
      # SAS is signed with the user delegation key instead of the access key.
      def initialize(account_name = "", access_key = "", user_delegation_key = nil)
        if access_key.empty? && !user_delegation_key.nil?
          access_key = user_delegation_key.value
        end
        if account_name.empty? || access_key.empty?
          client = Azure::Storage::Common::Client.create_from_env
          account_name = client.storage_account_name if account_name.empty?
          access_key = client.storage_access_key if access_key.empty?
        end
        @account_name = account_name
        @user_delegation_key = user_delegation_key
        @signer = Azure::Core::Auth::Signer.new(access_key)
      end

      # Service Shared Access Signature Token for the given path and options
      # @param path     [String] Path of the URI or the table name
      # @param options  [Hash]
      #
      # ==== Options
      #
      # * +:service+             - String. Required. Service type. 'b' (blob) or 'q' (queue) or 't' (table) or 'f' (file).
      # * +:resource+            - String. Required. Resource type, 'b' (blob) or 'c' (container) or 'f' (file) or 's' (share).
      # * +:permissions+         - String. Optional. Combination of 'r', 'a', 'c', w','d','l' in this order for a container.
      #                                              Combination of 'r', 'a', 'c', 'w', 'd' in this order for a blob.
      #                                              Combination of 'r', 'c', 'w', 'd', 'l' in this order for a share.
      #                                              Combination of 'r', 'c', 'w', 'd' in this order for a file.
      #                                              Combination of 'r', 'a', 'u', 'p' in this order for a queue.
      #                                              Combination of 'r', 'a', 'u', 'd' in this order for a table.
      #                                              This option must be omitted if it has been specified in an associated stored access policy.
      # * +:start+               - String. Optional. UTC Date/Time in ISO8601 format.
      # * +:expiry+              - String. Optional. UTC Date/Time in ISO8601 format. Default now + 30 minutes.
      # * +:identifier+          - String. Optional. Identifier for stored access policy.
      #                                              This option must be omitted if a user delegation key has been provided.
      # * +:protocol+            - String. Optional. Permitted protocols.
      # * +:ip_range+            - String. Optional. An IP address or a range of IP addresses from which to accept requests.
      #
      # Below options for blob serivce only
      # * +:snapshot+            - String. Optional. UTC Date/Time in ISO8601 format. The blob snapshot to grant permission.
      # * +:cache_control+       - String. Optional. Response header override.
      # * +:content_disposition+ - String. Optional. Response header override.
      # * +:content_encoding+    - String. Optional. Response header override.
      # * +:content_language+    - String. Optional. Response header override.
      # * +:content_type+        - String. Optional. Response header override.
      #
      # Below options for table service only
      # * +:startpk+             - String. Optional but must accompany startrk. The start partition key of a specified partition key range.
      # * +:endpk+               - String. Optional but must accompany endrk. The end partition key of a specified partition key range.
      # * +:startrk+             - String. Optional. The start row key of a specified row key range.
      # * +:endrk+               - String. Optional. The end row key of a specified row key range.
      def generate_service_sas_token(path, options = {})
        if options.key?(:service)
          service_type = SERVICE_TYPE_MAPPING[options[:service].to_sym]
          options.delete(:service)
        end

        raise Azure::Storage::Common::InvalidOptionsError, "SAS version cannot be set" if options[:version]

        options = DEFAULTS.merge(options)
        valid_mappings = SERVICE_KEY_MAPPINGS
        if service_type == Azure::Storage::Common::ServiceType::BLOB
          if options[:resource]
            options.merge!(resource: options[:resource])
          else
            options.merge!(resource: "b")
          end
          valid_mappings.merge!(BLOB_KEY_MAPPINGS)
        elsif service_type == Azure::Storage::Common::ServiceType::TABLE
          options.merge!(table_name: path)
          valid_mappings.merge!(TABLE_KEY_MAPPINGS)
        elsif service_type == Azure::Storage::Common::ServiceType::FILE
          if options[:resource]
            options.merge!(resource: options[:resource])
          else
            options.merge!(resource: "f")
          end
          valid_mappings.merge!(FILE_KEY_MAPPINGS)
        end

        service_key_mappings = SERVICE_KEY_MAPPINGS
        unless @user_delegation_key.nil?
          valid_mappings.delete(:identifier)
          USER_DELEGATION_KEY_MAPPINGS.each { |k, _| options[k] = @user_delegation_key.send(k) }
          valid_mappings.merge!(USER_DELEGATION_KEY_MAPPINGS)
          service_key_mappings = service_key_mappings.merge(USER_DELEGATION_KEY_MAPPINGS)
        end

        invalid_options = options.reject { |k, _| valid_mappings.key?(k) }
        raise Azure::Storage::Common::InvalidOptionsError, "invalid options #{invalid_options} provided for SAS token generate" if invalid_options.length > 0

        canonicalize_time(options)

        query_hash = Hash[options.map { |k, v| [service_key_mappings[k], v] }]
        .reject { |k, v| SERVICE_OPTIONAL_QUERY_PARAMS.include?(k) && v.to_s == "" }
        .merge(sig: @signer.sign(signable_string_for_service(service_type, path, options)))

        URI.encode_www_form(query_hash)
      end

      # Construct the plaintext to the spec required for signatures
      # @return [String]
      def signable_string_for_service(service_type, path, options)
        # Order is significant
        # The newlines from empty strings here are required
        signable_fields =
        [
          options[:permissions],
          options[:start],
          options[:expiry],
          canonicalized_resource(service_type, path)
        ]

        if @user_delegation_key.nil?
          signable_fields.push(options[:identifier])
        else
          signable_fields.concat [
            @user_delegation_key.signed_oid,
            @user_delegation_key.signed_tid,
            @user_delegation_key.signed_start,
            @user_delegation_key.signed_expiry,
            @user_delegation_key.signed_service,
            @user_delegation_key.signed_version
          ]
        end

        signable_fields.concat [
          options[:ip_range],
          options[:protocol],
          Azure::Storage::Common::Default::STG_VERSION
        ]

        signable_fields.concat [
          options[:resource],
          options[:timestamp]
        ] if service_type == Azure::Storage::Common::ServiceType::BLOB

        signable_fields.concat [
          options[:cache_control],
          options[:content_disposition],
          options[:content_encoding],
          options[:content_language],
          options[:content_type]
        ] if service_type == Azure::Storage::Common::ServiceType::BLOB || service_type == Azure::Storage::Common::ServiceType::FILE

        signable_fields.concat [
          options[:startpk],
          options[:startrk],
          options[:endpk],
          options[:endrk]
        ] if service_type == Azure::Storage::Common::ServiceType::TABLE

        signable_fields.join "\n"
      end

      # Account Shared Access Signature Token for the given options
      # @param account_name     [String] storage account name
      # @param options          [Hash]
      #
      # ==== Options
      #
      # * +:service+             - String. Required. Accessible services. Combination of 'b' (blob), 'q' (queue), 't' (table), 'f' (file).
      # * +:resource+            - String. Required. Accessible resource types. Combination of 's' (service), 'c' (container-level), 'o'(object-level).
      # * +:permissions+         - String. Required. Permissions. Combination of 'r' (read), 'w' (write), 'd'(delete), 'l'(list), 'a'(add),
      #                                              'c'(create), 'u'(update), 'p'(process). Permissions are only valid if they match
      #                                              the specified signed resource type; otherwise they are ignored.
      # * +:start+               - String. Optional. UTC Date/Time in ISO8601 format.
      # * +:expiry+              - String. Optional. UTC Date/Time in ISO8601 format. Default now + 30 minutes.
      # * +:protocol+            - String. Optional. Permitted protocols.
      # * +:ip_range+            - String. Optional. An IP address or a range of IP addresses from which to accept requests.
      #                                    When specifying a range, note that the range is inclusive.
      def generate_account_sas_token(options = {})
        raise Azure::Storage::Common::InvalidOptionsError, "SAS version cannot be set" if options[:version]

        options = DEFAULTS.merge(options)
        valid_mappings = ACCOUNT_KEY_MAPPINGS

        invalid_options = options.reject { |k, _| valid_mappings.key?(k) }
        raise Azure::Storage::Common::InvalidOptionsError, "invalid options #{invalid_options} provided for SAS token generate" if invalid_options.length > 0

        canonicalize_time(options)

        query_hash = Hash[options.map { |k, v| [ACCOUNT_KEY_MAPPINGS[k], v] }]
        .reject { |k, v| ACCOUNT_OPTIONAL_QUERY_PARAMS.include?(k) && v.to_s == "" }
        .merge(sig: @signer.sign(signable_string_for_account(options)))

        URI.encode_www_form(query_hash)
      end

      # Construct the plaintext to the spec required for signatures
      # @return [String]
      def signable_string_for_account(options)
        # Order is significant
        # The newlines from empty strings here are required
        [
          @account_name,
          options[:permissions],
          options[:service],
          options[:resource],
          options[:start],
          options[:expiry],
          options[:ip_range],
          options[:protocol],
          Azure::Storage::Common::Default::STG_VERSION,
          ""
        ].join("\n")
      end

      # Return the cononicalized resource representation of the blob resource
      # @return [String]
      def canonicalized_resource(service_type, path)
        "/#{service_type}/#{account_name}#{path.start_with?('/') ? '' : '/'}#{path}"
      end

      def canonicalize_time(options)
        options[:start] = Time.parse(options[:start]).utc.iso8601 if options[:start]
        options[:expiry] = Time.parse(options[:expiry]).utc.iso8601 if options[:expiry]
        options[:expiry] ||= (Time.now + 60 * 30).utc.iso8601
      end

      # A customised URI reflecting options for the resource signed with Shared Access Signature
      # @param uri                [URI] uri to resource including query options
      # @param use_account_sas    [Boolean] Whether uses account SAS
      # @param options            [Hash]
      #
      # ==== Options
      #
      # * +:start+                - String. Optional. UTC Date/Time in ISO8601 format.
      # * +:expiry+               - String. Optional. UTC Date/Time in ISO8601 format. Default now + 30 minutes.
      # * +:protocol+             - String. Optional. Permitted protocols.
      # * +:ip_range+             - String. Optional. An IP address or a range of IP addresses from which to accept requests.
      #                                     When specifying a range, note that the range is inclusive.
      #
      # Below options for account SAS only
      # * +:service+              - String. Required. Accessible services. Combination of 'b' (blob), 'q' (queue), 't' (table), 'f' (file).
      # * +:resource+             - String. Required. Accessible resource types. Combination of 's' (service), 'c' (container-level), 'o'(object-level).
      # * +:permissions+          - String. Required. Permissions. Combination of 'r' (read), 'w' (write), 'd'(delete), 'l'(list), 'a'(add),
      #                                               'c'(create), 'u'(update), 'p'(process). Permissions are only valid if they match
      #                                               the specified signed resource type; otherwise they are ignored.
      #
      # Below options for service SAS only
      # * +:service+              - String. Required. Service type. 'b' (blob) or 'q' (queue) or 't' (table) or 'f' (file).
      # * +:resource+             - String. Required. Resource type, 'b' (blob) or 'c' (container) or 'f' (file) or 's' (share).
      # * +:identifier+           - String. Optional. Identifier for stored access policy.
      # * +:permissions+          - String. Optional. Combination of 'r', 'a', 'c', w','d','l' in this order for a container.
      #                                               Combination of 'r', 'a', 'c', 'w', 'd' in this order for a blob.
      #                                               Combination of 'r', 'c', 'w', 'd', 'l' in this order for a share.
      #                                               Combination of 'r', 'c', 'w', 'd' in this order for a file.
      #                                               Combination of 'r', 'a', 'u', 'p' in this order for a queue.
      #                                               Combination of 'r', 'a', 'u', 'd' in this order for a table.
      #
      # Below options for Blob service only
      # * +:cache_control+        - String. Optional. Response header override.
      # * +:content_disposition+  - String. Optional. Response header override.
      # * +:content_encoding+     - String. Optional. Response header override.
      # * +:content_language+     - String. Optional. Response header override.
      # * +:content_type+         - String. Optional. Response header override.
      #
      # Below options for Table service only
      # * +:table_name+           - String. Required. Table name for SAS.
      # * +:startpk+              - String. Optional but must accompany startrk. The start partition key of a specified partition key range.
      # * +:endpk+                - String. Optional but must accompany endrk. The end partition key of a specified partition key range.
      # * +:startrk+              - String. Optional. The start row key of a specified row key range.
      # * +:endrk+                - String. Optional. The end row key of a specified row key range.
      def signed_uri(uri, use_account_sas, options)
        CGI::parse(uri.query || "").inject({}) { |memo, (k, v)| memo[k.to_sym] = v; memo }

        if options[:service] == (nil) && uri.host != (nil)
          host_splits = uri.host.split(".")
          options[:service] = host_splits[1].chr if host_splits.length > 1 && host_splits[0] == @account_name
        end

        sas_params = if use_account_sas
          generate_account_sas_token(options)
                     else
                       generate_service_sas_token(uri.path, options)
                     end

        URI.parse(uri.to_s + (uri.query.nil? ? "?" : "&") + sas_params)
      end
    end
  end
end
