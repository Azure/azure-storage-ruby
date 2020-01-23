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
require "azure/storage/blob/page"
require "azure/storage/blob/block"
require "azure/storage/blob/append"
require "azure/storage/blob/blob"

module Azure::Storage
  include Azure::Storage::Common::Service
  StorageService = Azure::Storage::Common::Service::StorageService

  module Blob
    class BlobService < StorageService
      include Azure::Storage::Common::Core::Utility
      include Azure::Storage::Blob
      include Azure::Storage::Blob::Container

      class << self
        # Public: Creates an instance of [Azure::Storage::Blob::BlobService]
        #
        # ==== Attributes
        #
        # * +options+    - Hash. Optional parameters.
        #
        # ==== Options
        #
        # Accepted key/value pairs in options parameter are:
        #
        # * +:use_development_storage+        - TrueClass|FalseClass. Whether to use storage emulator.
        # * +:development_storage_proxy_uri+  - String. Used with +:use_development_storage+ if emulator is hosted other than localhost.
        # * +:storage_account_name+           - String. The name of the storage account.
        # * +:storage_access_key+             - Base64 String. The access key of the storage account.
        # * +:storage_sas_token+              - String. The signed access signature for the storage account or one of its service.
        # * +:storage_blob_host+              - String. Specified Blob service endpoint or hostname
        # * +:storage_dns_suffix+             - String. The suffix of a regional Storage Service, to
        # * +:default_endpoints_protocol+     - String. http or https
        # * +:use_path_style_uri+             - String. Whether use path style URI for specified endpoints
        # * +:ca_file+                        - String. File path of the CA file if having issue with SSL
        # * +:user_agent_prefix+              - String. The user agent prefix that can identify the application calls the library
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
        # * +:ca_file+ is independent.
        #
        # When empty options are given, it will try to read settings from Environment Variables. Refer to [Azure::Storage::Common::ClientOptions.env_vars_mapping] for the mapping relationship
        #
        # @return [Azure::Storage::Blob::BlobService]
        def create(options = {}, &block)
          service_options = { client: Azure::Storage::Common::Client::create(options, &block), api_version: Azure::Storage::Blob::Default::STG_VERSION }
          service_options[:user_agent_prefix] = options[:user_agent_prefix] if options[:user_agent_prefix]
          Azure::Storage::Blob::BlobService.new(service_options, &block)
        end

        # Public: Creates an instance of [Azure::Storage::Blob::BlobService] with Storage Emulator
        #
        # ==== Attributes
        #
        # * +proxy_uri+    - String. Used with +:use_development_storage+ if emulator is hosted other than localhost.
        #
        # @return [Azure::Storage::Blob::BlobService]
        def create_development(proxy_uri = nil, &block)
          service_options = { client: Azure::Storage::Common::Client::create_development(proxy_uri, &block), api_version: Azure::Storage::Blob::Default::STG_VERSION }
          Azure::Storage::Blob::BlobService.new(service_options, &block)
        end

        # Public: Creates an instance of [Azure::Storage::Blob::BlobService] from Environment Variables
        #
        # @return [Azure::Storage::Blob::BlobService]
        def create_from_env(&block)
          service_options = { client: Azure::Storage::Common::Client::create_from_env(&block), api_version: Azure::Storage::Blob::Default::STG_VERSION }
          Azure::Storage::Blob::BlobService.new(service_options, &block)
        end

        # Public: Creates an instance of [Azure::Storage::Blob::BlobService] from Environment Variables
        #
        # ==== Attributes
        #
        # * +connection_string+    - String. Please refer to https://azure.microsoft.com/en-us/documentation/articles/storage-configure-connection-string/.
        #
        # @return [Azure::Storage::Blob::BlobService]
        def create_from_connection_string(connection_string, &block)
          service_options = { client: Azure::Storage::Common::Client::create_from_connection_string(connection_string, &block), api_version: Azure::Storage::Blob::Default::STG_VERSION }
          Azure::Storage::Blob::BlobService.new(service_options, &block)
        end
      end

      # Public: Initializes an instance of [Azure::Storage::Blob::BlobService]
      #
      # ==== Attributes
      #
      # * +options+    - Hash. Optional parameters.
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
      # * +:storage_dns_suffix+             - String. The suffix of a regional Storage Serivce, to
      # * +:default_endpoints_protocol+     - String. http or https
      # * +:use_path_style_uri+             - String. Whether use path style URI for specified endpoints
      # * +:ca_file+                        - String. File path of the CA file if having issue with SSL
      # * +:ssl_version+                    - Symbol. The ssl version to be used, sample: :TLSv1_1, :TLSv1_2, for the details, see https://github.com/ruby/openssl/blob/master/lib/openssl/ssl.rb
      # * +:ssl_min_version+                - Symbol. The min ssl version supported, only supported in Ruby 2.5+
      # * +:ssl_max_version+                - Symbol. The max ssl version supported, only supported in Ruby 2.5+
      # * +:user_agent_prefix+              - String. The user agent prefix that can identify the application calls the library
      # * +:client+                         - Azure::Storage::Common::Client. The common client used to initalize the service.
      #
      # The valid set of options include:
      # * Storage Emulator: +:use_development_storage+ required, +:development_storage_proxy_uri+ optionally
      # * Storage account name and key: +:storage_account_name+ and +:storage_access_key+ required, set +:storage_dns_suffix+ necessarily
      # * Storage account name and SAS token: +:storage_account_name+ and +:storage_sas_token+ required, set +:storage_dns_suffix+ necessarily
      # * Specified hosts and SAS token: At least one of the service host and SAS token. It's up to user to ensure the SAS token is suitable for the serivce
      # * Azure::Storage::Common::Client: The common client used to initalize the service. This client can be initalized and used repeatedly.
      # * Anonymous Blob: only +:storage_blob_host+, if it is to only access blobs within a container
      #
      # Additional notes:
      # * Specified hosts can be set when use account name with access key or sas token
      # * +:default_endpoints_protocol+ can be set if the scheme is not specified in hosts
      # * Storage emulator always use path style URI
      # * +:ca_file+ is independent.
      #
      # When empty options are given, it will try to read settings from Environment Variables. Refer to [Azure::Storage::Common::ClientOptions.env_vars_mapping] for the mapping relationship
      def initialize(options = {}, &block)
        service_options = options.clone
        client_config = service_options[:client] ||= Azure::Storage::Common::Client::create(service_options, &block)
        @user_agent_prefix = service_options[:user_agent_prefix] if service_options[:user_agent_prefix]
        @api_version = service_options[:api_version] || Azure::Storage::Blob::Default::STG_VERSION
        signer = service_options[:signer] || client_config.signer || Azure::Storage::Common::Core::Auth::SharedKey.new(client_config.storage_account_name, client_config.storage_access_key)
        signer.api_ver = @api_version if signer.is_a? Azure::Storage::Common::Core::Auth::SharedAccessSignatureSigner
        super(signer, client_config.storage_account_name, service_options, &block)
        @storage_service_host[:primary] = client.storage_blob_host
        @storage_service_host[:secondary] = client.storage_blob_host true
      end

      def call(method, uri, body = nil, headers = {}, options = {})
        content_type = get_or_apply_content_type(body, headers[Azure::Storage::Common::HeaderConstants::BLOB_CONTENT_TYPE])
        headers[Azure::Storage::Common::HeaderConstants::BLOB_CONTENT_TYPE] = content_type if content_type

        headers["x-ms-version"] = @api_version ? @api_version : Default::STG_VERSION
        headers["User-Agent"] = @user_agent_prefix ? "#{@user_agent_prefix}; #{Default::USER_AGENT}" : Default::USER_AGENT
        response = super

        # Force the response.body to the content charset of specified in the header.
        # Content-Type is echo'd back for the blob and is used to store the encoding of the octet stream
        if !response.nil? && !response.body.nil? && response.headers["Content-Type"]
          charset = parse_charset_from_content_type(response.headers["Content-Type"])
          response.body.force_encoding(charset) if charset && charset.length > 0
        end

        response
      end

      # Public: Get a list of Containers from the server.
      #
      # ==== Attributes
      #
      # * +options+                  - Hash. Optional parameters.
      #
      # ==== Options
      #
      # Accepted key/value pairs in options parameter are:
      # * +:prefix+                  - String. Filters the results to return only containers
      #                                whose name begins with the specified prefix. (optional)
      #
      # * +:marker+                  - String. An identifier the specifies the portion of the
      #                                list to be returned. This value comes from the property
      #                                Azure::Storage::Common::EnumerationResults.continuation_token when there
      #                                are more containers available than were returned. The
      #                                marker value may then be used here to request the next set
      #                                of list items. (optional)
      #
      # * +:max_results+             - Integer. Specifies the maximum number of containers to return.
      #                                If max_results is not specified, or is a value greater than
      #                                5,000, the server will return up to 5,000 items. If it is set
      #                                to a value less than or equal to zero, the server will return
      #                                status code 400 (Bad Request). (optional)
      #
      # * +:metadata+                - Boolean. Specifies whether or not to return the container metadata.
      #                                (optional, Default=false)
      #
      # * +:timeout+                 - Integer. A timeout in seconds.
      #
      # * +:request_id+              - String. Provides a client-generated, opaque value with a 1 KB character limit that is recorded
      #                                in the analytics logs when storage analytics logging is enabled.
      #
      # * +:location_mode+           - LocationMode. Specifies the location mode used to decide
      #                                which location the request should be sent to.
      #
      # See: https://msdn.microsoft.com/en-us/library/azure/dd179352.aspx
      #
      # NOTE: Metadata requested with the :metadata parameter must have been stored in
      # accordance with the naming restrictions imposed by the 2009-09-19 version of the Blob
      # service. Beginning with that version, all metadata names must adhere to the naming
      # conventions for C# identifiers. See: https://msdn.microsoft.com/en-us/library/aa664670(VS.71).aspx
      #
      # Any metadata with invalid names which were previously stored, will be returned with the
      # key "x-ms-invalid-name" in the metadata hash. This may contain multiple values and be an
      # Array (vs a String if it only contains a single value).
      #
      # Returns an Azure::Storage::Common::EnumerationResults
      #
      def list_containers(options = {})
        query = {}
        if options
          StorageService.with_query query, "prefix", options[:prefix]
          StorageService.with_query query, "marker", options[:marker]
          StorageService.with_query query, "maxresults", options[:max_results].to_s if options[:max_results]
          StorageService.with_query query, "include", "metadata" if options[:metadata] == true
          StorageService.with_query query, "timeout", options[:timeout].to_s if options[:timeout]
        end

        options[:request_location_mode] = Azure::Storage::Common::RequestLocationMode::PRIMARY_OR_SECONDARY
        uri = containers_uri(query, options)
        response = call(:get, uri, nil, {}, options)

        Serialization.container_enumeration_results_from_xml(response.body)
      end

      # Public: Obtain a user delegation key for the purpose of signing SAS tokens.
      #
      # ==== Attributes
      #
      # * +start+                  - Time. The start time for the user delegation SAS.
      # * +expiry+                 - Time. The expiry time of user delegation SAS.
      #
      # See: https://docs.microsoft.com/en-us/rest/api/storageservices/get-user-delegation-key
      #
      # NOTE: A token credential must be present on the service object for this request to succeed.
      # The start and expiry times must be within 7 days of the current time.
      #
      # Returns an Azure::Storage::Common::UserDelegationKey
      #
      def get_user_delegation_key(start, expiry)
        max_delegation_time = Time.now + BlobConstants::MAX_USER_DELEGATION_KEY_SECONDS
        raise ArgumentError, "Start time must be before #{max_delegation_time}" if start > max_delegation_time
        raise ArgumentError, "Expiry time must be before #{max_delegation_time}" if expiry > max_delegation_time
        raise ArgumentError, "Start time must be before expiry time" if start >= expiry

        body = Serialization.key_info_to_xml(start, expiry)

        response = call(:post, user_delegation_key_uri, body)

        Serialization.user_delegation_key_from_xml(response.body)
      end

      # Protected: Establishes an exclusive write lock on a container or a blob. The lock duration can be 15 to 60 seconds, or can be infinite.
      # To write to a locked container or blob, a client must provide a lease ID.
      #
      # ==== Attributes
      #
      # * +container+                - String. The container name.
      # * +blob+                     - String. The blob name.
      # * +options+                  - Hash. Optional parameters.
      #
      # ==== Options
      #
      # Accepted key/value pairs in options parameter are:
      # * +:duration+                - Integer. Default -1. Specifies the duration of the lease, in seconds, or negative one (-1)
      #                                for a lease that never expires. A non-infinite lease can be between 15 and 60 seconds. (optional)
      # * +:proposed_lease_id+       - String. Proposed lease ID, in a GUID string format. The Blob service returns 400 (Invalid request)
      #                                if the proposed lease ID is not in the correct format. (optional)
      # * +:timeout+                 - Integer. A timeout in seconds.
      # * +:request_id+              - String. Provides a client-generated, opaque value with a 1 KB character limit that is recorded
      #                                in the analytics logs when storage analytics logging is enabled.
      # * +:if_modified_since+       - String. A DateTime value. Specify this conditional header to acquire the lease
      #                                only if the blob has been modified since the specified date/time. If the blob has not been modified,
      #                                the Blob service returns status code 412 (Precondition Failed).
      # * +:if_unmodified_since+     - String. A DateTime value. Specify this conditional header to acquire the lease
      #                                only if the blob has not been modified since the specified date/time. If the blob has been modified,
      #                                the Blob service returns status code 412 (Precondition Failed).
      # * +:if_match+                - String. An ETag value. Specify an ETag value for this conditional header to acquire the lease
      #                                only if the blob's ETag value matches the value specified. If the values do not match,
      #                                the Blob service returns status code 412 (Precondition Failed).
      # * +:if_none_match+           - String. An ETag value. Specify an ETag value for this conditional header to acquire the lease
      #                                only if the blob's ETag value does not match the value specified. If the values are identical,
      #                                the Blob service returns status code 412 (Precondition Failed).
      # * +:origin+                  - String. Optional. Specifies the origin from which the request is issued. The presence of this header results
      #                                in cross-origin resource sharing headers on the response.
      #
      # See http://msdn.microsoft.com/en-us/library/azure/ee691972.aspx
      #
      # Returns a String of the new unique lease id. While the lease is active, you must include the lease ID with any request
      # to write, or to renew, change, or release the lease.
      #
      protected
        def acquire_lease(container, blob, options = {})
          query = { "comp" => "lease" }
          StorageService.with_query query, "timeout", options[:timeout].to_s if options[:timeout]

          if blob
            uri = blob_uri(container, blob, query)
          else
            uri = container_uri(container, query)
          end

          duration = -1
          duration = options[:duration] if options[:duration]

          headers = {}
          StorageService.with_header headers, "x-ms-lease-action", "acquire"
          StorageService.with_header headers, "x-ms-lease-duration", duration.to_s if duration
          StorageService.with_header headers, "x-ms-proposed-lease-id", options[:proposed_lease_id]
          StorageService.with_header headers, "Origin", options[:origin].to_s if options[:origin]
          add_blob_conditional_headers options, headers

          response = call(:put, uri, nil, headers, options)
          response.headers["x-ms-lease-id"]
        end

      # Protected: Renews the lease. The lease can be renewed if the lease ID specified on the request matches that
      # associated with the blob. Note that the lease may be renewed even if it has expired as long as the container or blob
      # has not been modified or leased again since the expiration of that lease. When you renew a lease, the
      # lease duration clock resets.
      #
      # ==== Attributes
      #
      # * +container+                - String. The container name.
      # * +blob+                     - String. The blob name.
      # * +lease+                    - String. The lease id
      # * +options+                  - Hash. Optional parameters.
      #
      # ==== Options
      #
      # Accepted key/value pairs in options parameter are:
      # * +:timeout+                 - Integer. A timeout in seconds.
      # * +:request_id+              - String. Provides a client-generated, opaque value with a 1 KB character limit that is recorded
      #                                in the analytics logs when storage analytics logging is enabled.
      # * +:if_modified_since+       - String. A DateTime value. Specify this conditional header to renew the lease
      #                                only if the blob has been modified since the specified date/time. If the blob has not been modified,
      #                                the Blob service returns status code 412 (Precondition Failed).
      # * +:if_unmodified_since+     - String. A DateTime value. Specify this conditional header to renew the lease
      #                                only if the blob has not been modified since the specified date/time. If the blob has been modified,
      #                                the Blob service returns status code 412 (Precondition Failed).
      # * +:if_match+                - String. An ETag value. Specify an ETag value for this conditional header to renew the lease
      #                                only if the blob's ETag value matches the value specified. If the values do not match,
      #                                the Blob service returns status code 412 (Precondition Failed).
      # * +:if_none_match+           - String. An ETag value. Specify an ETag value for this conditional header to renew the lease
      #                                only if the blob's ETag value does not match the value specified. If the values are identical,
      #                                the Blob service returns status code 412 (Precondition Failed).
      # * +:origin+                  - String. Optional. Specifies the origin from which the request is issued. The presence of this header results
      #                                in cross-origin resource sharing headers on the response.
      #
      # See http://msdn.microsoft.com/en-us/library/azure/ee691972.aspx
      #
      # Returns the renewed lease id
      #
      protected
        def renew_lease(container, blob, lease, options = {})
          query = { "comp" => "lease" }
          StorageService.with_query query, "timeout", options[:timeout].to_s if options[:timeout]

          if blob
            uri = blob_uri(container, blob, query)
          else
            uri = container_uri(container, query)
          end

          headers = {}
          StorageService.with_header headers, "x-ms-lease-action", "renew"
          StorageService.with_header headers, "x-ms-lease-id", lease
          StorageService.with_header headers, "Origin", options[:origin].to_s if options[:origin]
          add_blob_conditional_headers options, headers

          response = call(:put, uri, nil, headers, options)
          response.headers["x-ms-lease-id"]
        end

      # Protected: Change the ID of an existing lease.
      #
      # ==== Attributes
      #
      # * +container+                - String. The container name.
      # * +blob+                     - String. The blob name.
      # * +lease+                    - String. The existing lease id.
      # * +proposed_lease+           - String. Proposed lease ID, in a GUID string format. The Blob service returns 400 (Invalid request)
      #                                if the proposed lease ID is not in the correct format. (optional).
      # * +options+                  - Hash. Optional parameters.
      #
      # ==== Options
      #
      # Accepted key/value pairs in options parameter are:
      # * +:timeout+                 - Integer. A timeout in seconds.
      # * +:request_id+              - String. Provides a client-generated, opaque value with a 1 KB character limit that is recorded
      #                                in the analytics logs when storage analytics logging is enabled.
      # * +:if_modified_since+       - String. A DateTime value. Specify this conditional header to change the lease
      #                                only if the blob has been modified since the specified date/time. If the blob has not been modified,
      #                                the Blob service returns status code 412 (Precondition Failed).
      # * +:if_unmodified_since+     - String. A DateTime value. Specify this conditional header to change the lease
      #                                only if the blob has not been modified since the specified date/time. If the blob has been modified,
      #                                the Blob service returns status code 412 (Precondition Failed).
      # * +:if_match+                - String. An ETag value. Specify an ETag value for this conditional header to change the lease
      #                                only if the blob's ETag value matches the value specified. If the values do not match,
      #                                the Blob service returns status code 412 (Precondition Failed).
      # * +:if_none_match+           - String. An ETag value. Specify an ETag value for this conditional header to change the lease
      #                                only if the blob's ETag value does not match the value specified. If the values are identical,
      #                                the Blob service returns status code 412 (Precondition Failed).
      # * +:origin+                  - String. Optional. Specifies the origin from which the request is issued. The presence of this header results
      #                                in cross-origin resource sharing headers on the response.
      #
      # See http://msdn.microsoft.com/en-us/library/azure/ee691972.aspx
      #
      # Returns a String of the new unique lease id. While the lease is active, you must include the lease ID with any request
      # to write, or to renew, change, or release the lease.
      #
      protected
        def change_lease(container, blob, lease, proposed_lease, options = {})
          query = { "comp" => "lease" }
          StorageService.with_query query, "timeout", options[:timeout].to_s if options[:timeout]

          if blob
            uri = blob_uri(container, blob, query)
          else
            uri = container_uri(container, query)
          end

          headers = {}
          StorageService.with_header headers, "x-ms-lease-action", "change"
          StorageService.with_header headers, "x-ms-lease-id", lease
          StorageService.with_header headers, "x-ms-proposed-lease-id", proposed_lease
          StorageService.with_header headers, "Origin", options[:origin].to_s if options[:origin]
          add_blob_conditional_headers options, headers

          response = call(:put, uri, nil, headers, options)
          response.headers["x-ms-lease-id"]
        end

      # Protected: Releases the lease. The lease may be released if the lease ID specified on the request matches that
      # associated with the container or blob. Releasing the lease allows another client to immediately acquire the lease for
      # the container or blob as soon as the release is complete.
      #
      # ==== Attributes
      #
      # * +container+                - String. The container name.
      # * +blob+                     - String. The blob name.
      # * +lease+                    - String. The lease id.
      # * +options+                  - Hash. Optional parameters.
      #
      # ==== Options
      #
      # Accepted key/value pairs in options parameter are:
      # * +:timeout+                 - Integer. A timeout in seconds.
      # * +:request_id+              - String. Provides a client-generated, opaque value with a 1 KB character limit that is recorded
      #                                in the analytics logs when storage analytics logging is enabled.
      # * +:if_modified_since+       - String. A DateTime value. Specify this conditional header to release the lease
      #                                only if the blob has been modified since the specified date/time. If the blob has not been modified,
      #                                the Blob service returns status code 412 (Precondition Failed).
      # * +:if_unmodified_since+     - String. A DateTime value. Specify this conditional header to release the lease
      #                                only if the blob has not been modified since the specified date/time. If the blob has been modified,
      #                                the Blob service returns status code 412 (Precondition Failed).
      # * +:if_match+                - String. An ETag value. Specify an ETag value for this conditional header to release the lease
      #                                only if the blob's ETag value matches the value specified. If the values do not match,
      #                                the Blob service returns status code 412 (Precondition Failed).
      # * +:if_none_match+           - String. An ETag value. Specify an ETag value for this conditional header to release the lease
      #                                only if the blob's ETag value does not match the value specified. If the values are identical,
      #                                the Blob service returns status code 412 (Precondition Failed).
      # * +:origin+                  - String. Optional. Specifies the origin from which the request is issued. The presence of this header results
      #                                in cross-origin resource sharing headers on the response.
      #
      # See http://msdn.microsoft.com/en-us/library/azure/ee691972.aspx
      #
      # Returns nil on success
      #
      protected
        def release_lease(container, blob, lease, options = {})
          query = { "comp" => "lease" }
          StorageService.with_query query, "timeout", options[:timeout].to_s if options[:timeout]

          if blob
            uri = blob_uri(container, blob, query)
          else
            uri = container_uri(container, query)
          end

          headers = {}
          StorageService.with_header headers, "x-ms-lease-action", "release"
          StorageService.with_header headers, "x-ms-lease-id", lease
          StorageService.with_header headers, "Origin", options[:origin].to_s if options[:origin]
          add_blob_conditional_headers options, headers

          call(:put, uri, nil, headers, options)
          nil
        end

      # Protected: Breaks the lease, if the container or blob has an active lease. Once a lease is broken, it cannot be renewed. Any
      # authorized request can break the lease; the request is not required to specify a matching lease ID. When a
      # lease is broken, the lease break period is allowed to elapse, during which time no lease operation except
      # break and release can be performed on the container or blob. When a lease is successfully broken, the response indicates
      # the interval in seconds until a new lease can be acquired.
      #
      # A lease that has been broken can also be released, in which case another client may immediately acquire the
      # lease on the container or blob.
      #
      # ==== Attributes
      #
      # * +container+                - String. The container name.
      # * +blob+                     - String. The blob name.
      # * +options+                  - Hash. Optional parameters.
      #
      # ==== Options
      #
      # Accepted key/value pairs in options parameter are:
      # * +:break_period+            - Integer. The proposed duration of seconds that the lease should continue before it is
      #                                broken, between 0 and 60 seconds. This break period is only used if it is shorter than
      #                                the time remaining on the lease. If longer, the time remaining on the lease is used. A
      #                                new lease will not be available before the break period has expired, but the lease may
      #                                be held for longer than the break period.
      #
      #                                If this option is not used, a fixed-duration lease breaks after the remaining lease
      #                                period elapses, and an infinite lease breaks immediately.
      # * +:timeout+                 - Integer. A timeout in seconds.
      # * +:request_id+              - String. Provides a client-generated, opaque value with a 1 KB character limit that is recorded
      #                                in the analytics logs when storage analytics logging is enabled.
      # * +:if_modified_since+       - String. A DateTime value. Specify this conditional header to acquire the lease
      #                                only if the blob has been modified since the specified date/time. If the blob has not been modified,
      #                                the Blob service returns status code 412 (Precondition Failed).
      # * +:if_unmodified_since+     - String. A DateTime value. Specify this conditional header to acquire the lease
      #                                only if the blob has not been modified since the specified date/time. If the blob has been modified,
      #                                the Blob service returns status code 412 (Precondition Failed).
      # * +:if_match+                - String. An ETag value. Specify an ETag value for this conditional header to acquire the lease
      #                                only if the blob's ETag value matches the value specified. If the values do not match,
      #                                the Blob service returns status code 412 (Precondition Failed).
      # * +:if_none_match+           - String. An ETag value. Specify an ETag value for this conditional header to acquire the lease
      #                                only if the blob's ETag value does not match the value specified. If the values are identical,
      #                                the Blob service returns status code 412 (Precondition Failed).
      # * +:origin+                  - String. Optional. Specifies the origin from which the request is issued. The presence of this header results
      #                                in cross-origin resource sharing headers on the response.
      #
      # See http://msdn.microsoft.com/en-us/library/azure/ee691972.aspx
      #
      # Returns an Integer of the remaining lease time. This value is the approximate time remaining in the lease
      # period, in seconds. This header is returned only for a successful request to break the lease. If the break
      # is immediate, 0 is returned.
      #
      protected
        def break_lease(container, blob, options = {})
          query = { "comp" => "lease" }
          StorageService.with_query query, "timeout", options[:timeout].to_s if options[:timeout]

          if blob
            uri = blob_uri(container, blob, query)
          else
            uri = container_uri(container, query)
          end

          headers = {}
          StorageService.with_header headers, "x-ms-lease-action", "break"
          StorageService.with_header headers, "x-ms-lease-break-period", options[:break_period].to_s if options[:break_period]
          StorageService.with_header headers, "Origin", options[:origin].to_s if options[:origin]
          add_blob_conditional_headers options, headers

          response = call(:put, uri, nil, headers, options)
          response.headers["x-ms-lease-time"].to_i
        end

      # Protected: Generate the URI for the collection of containers.
      #
      # ==== Attributes
      #
      # * +query+ - A Hash of key => value query parameters.
      #
      # Returns a URI.
      #
      protected
        def containers_uri(query = {}, options = {})
          query = { "comp" => "list" }.merge(query)
          generate_uri("", query, options)
        end

      # Protected: Generate the URI for the user delegation key.
      #
      # ==== Attributes
      #
      # * +query+ - A Hash of key => value query parameters.
      #
      # Returns a URI.
      #
      protected
        def user_delegation_key_uri(query = {}, options = {})
          query = { :restype => "service", :comp => "userdelegationkey" }.merge(query)
          generate_uri("", query, options)
        end

      # Protected: Generate the URI for a specific container.
      #
      # ==== Attributes
      #
      # * +name+  - The container name. If this is a URI, we just return this.
      # * +query+ - A Hash of key => value query parameters.
      #
      # Returns a URI.
      #
      protected
        def container_uri(name, query = {}, options = {})
          return name if name.kind_of? ::URI
          query = { "restype" => "container" }.merge(query)
          generate_uri(name, query, options)
        end

      # Protected: Generate the URI for a specific Blob.
      #
      # ==== Attributes
      #
      # * +container_name+ - String representing the name of the container.
      # * +blob_name+      - String representing the name of the blob.
      # * +query+          - A Hash of key => value query parameters.
      #
      # Returns a URI.
      #
      protected
        def blob_uri(container_name, blob_name, query = {}, options = {})
          if container_name.nil? || container_name.empty?
            path = blob_name
          else
            path = ::File.join(container_name, blob_name)
          end
          options = { encode: true }.merge(options)
          generate_uri(path, query, options)
        end

      # Adds conditional header with required condition
      #
      # headers   - A Hash of HTTP headers
      # options   - A Hash of condition name/value pairs
      #
      protected
        def add_blob_conditional_headers(options, headers)
          return unless options

          # Common conditional headers for blobs: https://msdn.microsoft.com/en-us/library/azure/dd179371.aspx
          StorageService.with_header headers, "If-Modified-Since", options[:if_modified_since]
          StorageService.with_header headers, "If-Unmodified-Since", options[:if_unmodified_since]
          StorageService.with_header headers, "If-Match", options[:if_match]
          StorageService.with_header headers, "If-None-Match", options[:if_none_match]

          # Conditional headers for copying blob
          StorageService.with_header headers, "If-Modified-Since", options[:dest_if_modified_since]
          StorageService.with_header headers, "If-Unmodified-Since", options[:dest_if_unmodified_since]
          StorageService.with_header headers, "If-Match", options[:dest_if_match]
          StorageService.with_header headers, "If-None-Match", options[:dest_if_none_match]
          StorageService.with_header headers, "x-ms-source-if-modified-since", options[:source_if_modified_since]
          StorageService.with_header headers, "x-ms-source-if-unmodified-since", options[:source_if_unmodified_since]
          StorageService.with_header headers, "x-ms-source-if-match", options[:source_if_match]
          StorageService.with_header headers, "x-ms-source-if-none-match", options[:source_if_none_match]

          # Conditional headers for page blob
          StorageService.with_header headers, "x-ms-if-sequence-number-le", options[:if_sequence_number_le] if options[:if_sequence_number_le]
          StorageService.with_header headers, "x-ms-if-sequence-number-lt", options[:if_sequence_number_lt] if options[:if_sequence_number_lt]
          StorageService.with_header headers, "x-ms-if-sequence-number-eq", options[:if_sequence_number_eq] if options[:if_sequence_number_eq]

          # Conditional headers for append blob
          StorageService.with_header headers, "x-ms-blob-condition-maxsize", options[:max_size]
          StorageService.with_header headers, "x-ms-blob-condition-appendpos", options[:append_position]
        end

      # Get the content type according to the blob content type header and request body.
      #
      # headers      - The request body
      # content_type - The request content type
      protected
        def get_or_apply_content_type(body, content_type = nil)
          unless body.nil?
            if (body.is_a? String) && body.encoding.to_s != "ASCII_8BIT" && !body.empty?
              if content_type.nil?
                content_type = "text/plain; charset=#{body.encoding}"
              else
                # Force the request.body to the content encoding of specified in the header
                charset = parse_charset_from_content_type(content_type)
                body.force_encoding(charset) if charset
              end
            else
              # It is either that the body is not a string, or that the body's encoding is ASCII_8BIT, which is a binary
              # In this case, set the content type to be default content-type
              content_type = Default::CONTENT_TYPE_VALUE unless content_type
            end
          end
          content_type
        end
    end
  end
end

Azure::Storage::BlobService = Azure::Storage::Blob::BlobService
