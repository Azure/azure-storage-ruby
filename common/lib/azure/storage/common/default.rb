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

require "rbconfig"
require "azure/storage/common/version"

module Azure::Storage::Common
  module Default
    # Default REST service (STG) version number. This is used only for SAS generator.
    STG_VERSION = "2018-11-09"

    # The number of default concurrent requests for parallel operation.
    DEFAULT_PARALLEL_OPERATION_THREAD_COUNT = 1

    # Constant representing a kilobyte (Non-SI version).
    KB = 1024
    # Constant representing a megabyte (Non-SI version).
    MB = 1024 * 1024
    # Constant representing a gigabyte (Non-SI version).
    GB = 1024 * 1024 * 1024

    # Specifies HTTP.
    HTTP = "http"
    # Specifies HTTPS.
    HTTPS = "https"
    # Default HTTP port.
    DEFAULT_HTTP_PORT = 80
    # Default HTTPS port.
    DEFAULT_HTTPS_PORT = 443

    # Marker for atom metadata.
    XML_METADATA_MARKER = "$"
    # Marker for atom value.
    XML_VALUE_MARKER = "_"

    def os
      host_os = RbConfig::CONFIG["host_os"]
      case host_os
      when /mswin|msys|mingw|cygwin|bccwin|wince|emc/
        "Windows #{host_os}"
      when /darwin|mac os/
        "MacOS #{host_os}"
      when /linux/
        "Linux #{host_os}"
      when /solaris|bsd/
        "Unix #{host_os}"
      else
        "Unknown #{host_os}"
      end
    end

    module_function :os

    class << self
      def options
        Hash[Azure::Storage::Common::Configurable.keys.map { |key| [key, send(key)] }]
      end

      # Default storage access key
      # @return [String]
      def storage_access_key
        ENV["AZURE_STORAGE_ACCESS_KEY"]
      end

      # Default storage account name
      # @return [String]
      def storage_account_name
        ENV["AZURE_STORAGE_ACCOUNT"]
      end

      # Default storage connection string
      # @return [String]
      def storage_connection_string
        ENV["AZURE_STORAGE_CONNECTION_STRING"]
      end

      # Default storage shared access signature token
      # @return [String]
      def storage_sas_token
        ENV["AZURE_STORAGE_SAS_TOKEN"]
      end

      # Default storage table host
      # @return [String]
      def storage_table_host
        ENV["AZURE_STORAGE_TABLE_HOST"]
      end

      # Default storage blob host
      # @return [String]
      def storage_blob_host
        ENV["AZURE_STORAGE_BLOB_HOST"]
      end

      # Default storage queue host
      # @return [String]
      def storage_queue_host
        ENV["AZURE_STORAGE_QUEUE_HOST"]
      end

      # Default storage file host
      # @return [String]
      def storage_file_host
        ENV["AZURE_STORAGE_FILE_HOST"]
      end

      # A placeholder to map with the Azure::Storage::Common::Configurable.keys
      # @return nil
      def signer
      end
    end
  end

  # Service Types
  module ServiceType
    BLOB = "blob"
    QUEUE = "queue"
    TABLE = "table"
    FILE = "file"
  end

  # Specifies the location mode used to decide which location the request should be sent to.
  module LocationMode
    PRIMARY_ONLY = 0
    PRIMARY_THEN_SECONDARY = 1
    SECONDARY_ONLY = 2
    SECONDARY_THEN_PRIMARY = 3
  end

  # Specifies the location used to indicate which location the operation (REST API) can be performed against.
  # This is determined by the API and cannot be specified by the users.
  module RequestLocationMode
    PRIMARY_ONLY = 0
    SECONDARY_ONLY = 1
    PRIMARY_OR_SECONDARY = 2
  end

  # Represents a storage service location.
  module StorageLocation
    PRIMARY = 0
    SECONDARY = 1
  end

  # Defines constants for use with shared access policies.
  module AclConstants
    # XML element for an access policy.
    ACCESS_POLICY = "AccessPolicy"

    # XML element for the end time of an access policy.
    EXPIRY = "Expiry"

    # XML attribute for IDs.
    ID = "Id"

    # XML element for the permission of an access policy.
    PERMISSION = "Permission"

    # XML element for a signed identifier.
    SIGNED_IDENTIFIER_ELEMENT = "SignedIdentifier"

    # XML element for signed identifiers.
    SIGNED_IDENTIFIERS_ELEMENT = "SignedIdentifiers"

    # XML element for the start time of an access policy.
    START = "Start"
  end

  # Defines constants for use with service properties.
  module ServicePropertiesConstants
    # XML element for storage service properties.
    STORAGE_SERVICE_PROPERTIES_ELEMENT = "StorageServiceProperties"

    # Default analytics version to send for logging, hour metrics and minute metrics.
    DEFAULT_ANALYTICS_VERSION = "1.0"

    # XML element for logging.
    LOGGING_ELEMENT = "Logging"

    # XML element for version.
    VERSION_ELEMENT = "Version"

    # XML element for delete.
    DELETE_ELEMENT = "Delete"

    # XML element for read.
    READ_ELEMENT = "Read"

    # XML element for write.
    WRITE_ELEMENT = "Write"

    # XML element for retention policy.
    RETENTION_POLICY_ELEMENT = "RetentionPolicy"

    # XML element for enabled.
    ENABLED_ELEMENT = "Enabled"

    # XML element for days.
    DAYS_ELEMENT = "Days"

    # XML element for HourMetrics.
    HOUR_METRICS_ELEMENT = "HourMetrics"

    # XML element for MinuteMetrics.
    MINUTE_METRICS_ELEMENT = "MinuteMetrics"

    # XML element for Cors.
    CORS_ELEMENT = "Cors"

    # XML element for CorsRule.
    CORS_RULE_ELEMENT = "CorsRule"

    # XML element for AllowedOrigins.
    ALLOWED_ORIGINS_ELEMENT = "AllowedOrigins"

    # XML element for AllowedMethods.
    ALLOWED_METHODS_ELEMENT = "AllowedMethods"

    # XML element for MaxAgeInSeconds.
    MAX_AGE_IN_SECONDS_ELEMENT = "MaxAgeInSeconds"

    # XML element for ExposedHeaders.
    EXPOSED_HEADERS_ELEMENT = "ExposedHeaders"

    # XML element for AllowedHeaders.
    ALLOWED_HEADERS_ELEMENT = "AllowedHeaders"

    # XML element for IncludeAPIs.
    INCLUDE_APIS_ELEMENT = "IncludeAPIs"

    # XML element for DefaultServiceVersion.
    DEFAULT_SERVICE_VERSION_ELEMENT = "DefaultServiceVersion"
  end

  # Defines constants for use with HTTP headers.
  module HeaderConstants
    # The accept ranges header.
    ACCEPT_RANGES = "accept_ranges"

    # The content transfer encoding header.
    CONTENT_TRANSFER_ENCODING = "content-transfer-encoding"

    # The transfer encoding header.
    TRANSFER_ENCODING = "transfer-encoding"

    # The server header.
    SERVER = "server"

    # The location header.
    LOCATION = "location"

    # The Last-Modified header
    LAST_MODIFIED = "Last-Modified"

    # The data service version.
    DATA_SERVICE_VERSION = "DataServiceVersion"

    # The maximum data service version.
    MAX_DATA_SERVICE_VERSION = "maxdataserviceversion"

    # The master Windows Azure Storage header prefix.
    PREFIX_FOR_STORAGE = "x-ms-"

    # The client request Id header.
    CLIENT_REQUEST_ID = "x-ms-client-request-id"

    # The header that specifies the approximate message count of a queue.
    APPROXIMATE_MESSAGES_COUNT = "x-ms-approximate-messages-count"

    # The Authorization header.
    AUTHORIZATION = "authorization"

    # The header that specifies public access to blobs.
    BLOB_PUBLIC_ACCESS = "x-ms-blob-public-access"

    # The header for the blob type.
    BLOB_TYPE = "x-ms-blob-type"

    # The header for the type.
    TYPE = "x-ms-type"

    # Specifies the block blob type.
    BLOCK_BLOB = "blockblob"

    # The CacheControl header.
    CACHE_CONTROL = "cache-control"

    # The header that specifies blob caching control.
    BLOB_CACHE_CONTROL = "x-ms-blob-cache-control"

    # The header that specifies caching control.
    FILE_CACHE_CONTROL = "x-ms-cache-control"

    # The copy status.
    COPY_STATUS = "x-ms-copy-status"

    # The copy completion time
    COPY_COMPLETION_TIME = "x-ms-copy-completion-time"

    # The copy status message
    COPY_STATUS_DESCRIPTION = "x-ms-copy-status-description"

    # The copy identifier.
    COPY_ID = "x-ms-copy-id"

    # Progress of any copy operation
    COPY_PROGRESS = "x-ms-copy-progress"

    # The copy action.
    COPY_ACTION = "x-ms-copy-action"

    # The ContentID header.
    CONTENT_ID = "content-id"

    # The ContentEncoding header.
    CONTENT_ENCODING = "content-encoding"

    # The header that specifies blob content encoding.
    BLOB_CONTENT_ENCODING = "x-ms-blob-content-encoding"

    # The header that specifies content encoding.
    FILE_CONTENT_ENCODING = "x-ms-content-encoding"

    # The ContentLangauge header.
    CONTENT_LANGUAGE = "content-language"

    # The header that specifies blob content language.
    BLOB_CONTENT_LANGUAGE = "x-ms-blob-content-language"

    # The header that specifies content language.
    FILE_CONTENT_LANGUAGE = "x-ms-content-language"

    # The ContentLength header.
    CONTENT_LENGTH = "content-length"

    # The header that specifies blob content length.
    BLOB_CONTENT_LENGTH = "x-ms-blob-content-length"

    # The header that specifies content length.
    FILE_CONTENT_LENGTH = "x-ms-content-length"

    # The ContentDisposition header.
    CONTENT_DISPOSITION = "content-disposition"

    # The header that specifies blob content disposition.
    BLOB_CONTENT_DISPOSITION = "x-ms-blob-content-disposition"

    # The header that specifies content disposition.
    FILE_CONTENT_DISPOSITION = "x-ms-content-disposition"

    # The ContentMD5 header.
    CONTENT_MD5 = "content-md5"

    # The header that specifies blob content MD5.
    BLOB_CONTENT_MD5 = "x-ms-blob-content-md5"

    # The header that specifies content MD5.
    FILE_CONTENT_MD5 = "x-ms-content-md5"

    # The ContentRange header.
    CONTENT_RANGE = "cache-range"

    # The ContentType header.
    CONTENT_TYPE = "Content-Type"

    # The header that specifies blob content type.
    BLOB_CONTENT_TYPE = "x-ms-blob-content-type"

    # The header that specifies content type.
    FILE_CONTENT_TYPE = "x-ms-content-type"

    # The header for copy source.
    COPY_SOURCE = "x-ms-copy-source"

    # The header that specifies the date.
    DATE = "date"

    # The header that specifies the date.
    MS_DATE = "x-ms-date"

    # The header to delete snapshots.
    DELETE_SNAPSHOT = "x-ms-delete-snapshots"

    # The ETag header.
    ETAG = "etag"

    # The IfMatch header.
    IF_MATCH = "if-match"

    # The IfModifiedSince header.
    IF_MODIFIED_SINCE = "if-modified-since"

    # The IfNoneMatch header.
    IF_NONE_MATCH = "if-none-match"

    # The IfUnmodifiedSince header.
    IF_UNMODIFIED_SINCE = "if-unmodified-since"

    # Specifies snapshots are to be included.
    INCLUDE_SNAPSHOTS_VALUE = "include"

    # Specifies that the content-type is JSON.
    JSON_CONTENT_TYPE_VALUE = "application/json"

    # The header that specifies lease ID.
    LEASE_ID = "x-ms-lease-id"

    # The header that specifies the lease break period.
    LEASE_BREAK_PERIOD = "x-ms-lease-break-period"

    # The header that specifies the proposed lease identifier.
    PROPOSED_LEASE_ID = "x-ms-proposed-lease-id"

    # The header that specifies the lease duration.
    LEASE_DURATION = "x-ms-lease-duration"

    # The header that specifies the source lease ID.
    SOURCE_LEASE_ID = "x-ms-source-lease-id"

    # The header that specifies lease time.
    LEASE_TIME = "x-ms-lease-time"

    # The header that specifies lease status.
    LEASE_STATUS = "x-ms-lease-status"

    # The header that specifies lease state.
    LEASE_STATE = "x-ms-lease-state"

    # Specifies the page blob type.
    PAGE_BLOB = "PageBlob"

    # The header that specifies page write mode.
    PAGE_WRITE = "x-ms-page-write"

    # The header that specifies file range write mode.
    FILE_WRITE = "x-ms-write"

    # The header that specifies whether the response should include the inserted entity.
    PREFER = "Prefer"

    # The header value which specifies that the response should include the inserted entity.
    PREFER_CONTENT = "return-content"

    # The header value which specifies that the response should not include the inserted entity.
    PREFER_NO_CONTENT = "return-no-content"

    # The header prefix for metadata.
    PREFIX_FOR_STORAGE_METADATA = "x-ms-meta-"

    # The header prefix for properties.
    PREFIX_FOR_STORAGE_PROPERTIES = "x-ms-prop-"

    # The Range header.
    RANGE = "Range"

    # The header that specifies if the request will populate the ContentMD5 header for range gets.
    RANGE_GET_CONTENT_MD5 = "x-ms-range-get-content-md5"

    # The format string for specifying ranges.
    RANGE_HEADER_FORMAT = "bytes:%d-%d"

    # The header that indicates the request ID.
    REQUEST_ID = "x-ms-request-id"

    # The header for specifying the sequence number.
    SEQUENCE_NUMBER = "x-ms-blob-sequence-number"

    # The header for specifying the If-Sequence-Number-EQ condition.
    SEQUENCE_NUMBER_EQUAL = "x-ms-if-sequence-number-eq"

    # The header for specifying the If-Sequence-Number-LT condition.
    SEQUENCE_NUMBER_LESS_THAN = "x-ms-if-sequence-number-lt"

    # The header for specifying the If-Sequence-Number-LE condition.
    SEQUENCE_NUMBER_LESS_THAN_OR_EQUAL = "x-ms-if-sequence-number-le"

    # The header that specifies sequence number action.
    SEQUENCE_NUMBER_ACTION = "x-ms-sequence-number-action"

    # The header for the blob content length.
    SIZE = "x-ms-blob-content-length"

    # The header for snapshots.
    SNAPSHOT = "x-ms-snapshot"

    # Specifies only snapshots are to be included.
    SNAPSHOTS_ONLY_VALUE = "only"

    # The header for the If-Match condition.
    SOURCE_IF_MATCH = "x-ms-source-if-match"

    # The header for the If-Modified-Since condition.
    SOURCE_IF_MODIFIED_SINCE = "x-ms-source-if-modified-since"

    # The header for the If-None-Match condition.
    SOURCE_IF_NONE_MATCH = "x-ms-source-if-none-match"

    # The header for the If-Unmodified-Since condition.
    SOURCE_IF_UNMODIFIED_SINCE = "x-ms-source-if-unmodified-since"

    # The header for data ranges.
    STORAGE_RANGE = "x-ms-range"

    # The header for storage version.
    STORAGE_VERSION = "x-ms-version"

    # The UserAgent header.
    USER_AGENT = "user-agent"

    # The pop receipt header.
    POP_RECEIPT = "x-ms-popreceipt"

    # The time next visibile header.
    TIME_NEXT_VISIBLE = "x-ms-time-next-visible"

    # The approximate message counter header.
    APPROXIMATE_MESSAGE_COUNT = "x-ms-approximate-message-count"

    # The lease action header.
    LEASE_ACTION = "x-ms-lease-action"

    # The accept header.
    ACCEPT = "Accept"

    # The accept charset header.
    ACCEPT_CHARSET = "Accept-Charset"

    # The host header.
    HOST = "host"

    # The correlation identifier header.
    CORRELATION_ID = "x-ms-correlation-id"

    # The group identifier header.
    GROUP_ID = "x-ms-group-id"

    # The share quota header.
    SHARE_QUOTA = "x-ms-share-quota"

    # The max blob size header.
    BLOB_CONDITION_MAX_SIZE = "x-ms-blob-condition-maxsize"

    # The append blob position header.
    BLOB_CONDITION_APPEND_POSITION = "x-ms-blob-condition-appendpos"

    # The append blob append offset header.
    BLOB_APPEND_OFFSET = "x-ms-blob-append-offset"

    # The append blob committed block header.
    BLOB_COMMITTED_BLOCK_COUNT = "x-ms-blob-committed-block-count"

    # The returned response payload should be with no metadata.
    ODATA_NO_META = "application/json;odata=nometadata"

    # The returned response payload should be with minimal metadata.
    ODATA_MIN_META = "application/json;odata=minimalmetadata"

    # The returned response payload should be with full metadata.
    ODATA_FULL_META = "application/json;odata=fullmetadata"

    # The header for if request has been encrypted at server side.
    REQUEST_SERVER_ENCRYPTED = "x-ms-request-server-encrypted"

    # The header for if blob data and application metadata has been encrypted at server side.
    SERVER_ENCRYPTED = "x-ms-server-encrypted"
  end

  module QueryStringConstants
    # Query component for SAS API version.
    API_VERSION = "api-version"

    # The Comp value.
    COMP = "comp"

    # The Res Type.
    RESTYPE = "restype"

    # The copy Id.
    COPY_ID = "copyid"

    # The Snapshot value.
    SNAPSHOT = "snapshot"

    # The timeout value.
    TIMEOUT = "timeout"

    # The signed start time query string argument for shared access signature.
    SIGNED_START = "st"

    # The signed expiry time query string argument for shared access signature.
    SIGNED_EXPIRY = "se"

    # The signed resource query string argument for shared access signature.
    SIGNED_RESOURCE = "sr"

    # The signed permissions query string argument for shared access signature.
    SIGNED_PERMISSIONS = "sp"

    # The signed identifier query string argument for shared access signature.
    SIGNED_IDENTIFIER = "si"

    # The signature query string argument for shared access signature.
    SIGNATURE = "sig"

    # The signed version argument for shared access signature.
    SIGNED_VERSION = "sv"

    # The cache control argument for shared access signature.
    CACHE_CONTROL = "rscc"

    # The content type argument for shared access signature.
    CONTENT_TYPE = "rsct"

    # The content encoding argument for shared access signature.
    CONTENT_ENCODING = "rsce"

    # The content language argument for shared access signature.
    CONTENT_LANGUAGE = "rscl"

    # The content disposition argument for shared access signature.
    CONTENT_DISPOSITION = "rscd"

    # The block identifier query string argument for blob service.
    BLOCK_ID = "blockid"

    # The block list type query string argument for blob service.
    BLOCK_LIST_TYPE = "blocklisttype"

    # The prefix query string argument for listing operations.
    PREFIX = "prefix"

    # The marker query string argument for listing operations.
    MARKER = "marker"

    # The maxresults query string argument for listing operations.
    MAX_RESULTS = "maxresults"

    # The delimiter query string argument for listing operations.
    DELIMITER = "delimiter"

    # The include query string argument for listing operations.
    INCLUDE = "include"

    # The peekonly query string argument for queue service.
    PEEK_ONLY = "peekonly"

    # The numofmessages query string argument for queue service.
    NUM_OF_MESSAGES = "numofmessages"

    # The popreceipt query string argument for queue service.
    POP_RECEIPT = "popreceipt"

    # The visibilitytimeout query string argument for queue service.
    VISIBILITY_TIMEOUT = "visibilitytimeout"

    # The messagettl query string argument for queue service.
    MESSAGE_TTL = "messagettl"

    # The select query string argument.
    SELECT = "$select"

    # The filter query string argument.
    FILTER = "$filter"

    # The top query string argument.
    TOP = "$top"

    # The skip query string argument.
    SKIP = "$skip"

    # The next partition key query string argument for table service.
    NEXT_PARTITION_KEY = "NextPartitionKey"

    # The next row key query string argument for table service.
    NEXT_ROW_KEY = "NextRowKey"

    # The lock identifier for service bus messages.
    LOCK_ID = "lockid"

    # The table name for table SAS URI's.
    TABLENAME = "tn"

    # The starting Partition Key for tableSAS URI's.
    STARTPK = "spk"

    # The starting Partition Key for tableSAS URI's.
    STARTRK = "srk"

    # The ending Partition Key for tableSAS URI's.
    ENDPK = "epk"

    # The ending Partition Key for tableSAS URI's.
    ENDRK = "erk"

    # ACL
    ACL = "acl"

    # Incremental Copy
    INCREMENTAL_COPY = "incrementalcopy"
  end

  module StorageServiceClientConstants
    # The default protocol.
    DEFAULT_PROTOCOL = "https"

    # Default credentials.
    DEVSTORE_STORAGE_ACCOUNT = "devstoreaccount1"
    DEVSTORE_STORAGE_ACCESS_KEY = "Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw=="

    # The development store URI.
    DEV_STORE_URI = "http://127.0.0.1"

    # Development ServiceClient URLs.
    DEVSTORE_BLOB_HOST_PORT = "10000"
    DEVSTORE_QUEUE_HOST_PORT = "10001"
    DEVSTORE_TABLE_HOST_PORT = "10002"
    DEVSTORE_FILE_HOST_PORT = "10003"

    DEFAULT_ENDPOINT_SUFFIX = "core.windows.net"
  end

  module HttpConstants
    # Http Verbs
    module HttpVerbs
      PUT = "PUT"
      GET = "GET"
      DELETE = "DELETE"
      POST = "POST"
      MERGE = "MERGE"
      HEAD = "HEAD"
    end

    # Response codes.
    module HttpResponseCodes
      Ok = 200
      Created = 201
      Accepted = 202
      NoContent = 204
      PartialContent = 206
      BadRequest = 400
      Unauthorized = 401
      Forbidden = 403
      NotFound = 404
      Conflict = 409
      LengthRequired = 411
      PreconditionFailed = 412
    end
  end

  # Constants for storage error strings
  # More details are at = http://msdn.microsoft.com/en-us/library/azure/dd179357.aspx
  module StorageErrorCodeStrings
    # Not Modified (304) = The condition specified in the conditional header(s) was not met for a read operation.
    # Precondition Failed (412) = The condition specified in the conditional header(s) was not met for a write operation.
    CONDITION_NOT_MET = "ConditionNotMet"
    # Bad Request (400) = A required HTTP header was not specified.
    MISSING_REQUIRED_HEADER = "MissingRequiredHeader"
    # Bad Request (400) = A required XML node was not specified in the request body.
    MISSING_REQUIRED_XML_NODE = "MissingRequiredXmlNode"
    # Bad Request (400) = One of the HTTP headers specified in the request is not supported.
    UNSUPPORTED_HEADER = "UnsupportedHeader"
    # Bad Request (400) = One of the XML nodes specified in the request body is not supported.
    UNSUPPORTED_XML_NODE = "UnsupportedXmlNode"
    # Bad Request (400) = The value provided for one of the HTTP headers was not in the correct format.
    INVALID_HEADER_VALUE = "InvalidHeaderValue"
    # Bad Request (400) = The value provided for one of the XML nodes in the request body was not in the correct format.
    INVALID_XML_NODE_VALUE = "InvalidXmlNodeValue"
    # Bad Request (400) = A required query parameter was not specified for this request.
    MISSING_REQUIRED_QUERY_PARAMETER = "MissingRequiredQueryParameter"
    # Bad Request (400) = One of the query parameters specified in the request URI is not supported.
    UNSUPPORTED_QUERY_PARAMETER = "UnsupportedQueryParameter"
    # Bad Request (400) = An invalid value was specified for one of the query parameters in the request URI.
    INVALID_QUERY_PARAMETER_VALUE = "InvalidQueryParameterValue"
    # Bad Request (400) = A query parameter specified in the request URI is outside the permissible range.
    OUT_OF_RANGE_QUERY_PARAMETER_VALUE = "OutOfRangeQueryParameterValue"
    # Bad Request (400) = The url in the request could not be parsed.
    REQUEST_URL_FAILED_TO_PARSE = "RequestUrlFailedToParse"
    # Bad Request (400) = The requested URI does not represent any resource on the server.
    INVALID_URI = "InvalidUri"
    # Bad Request (400) = The HTTP verb specified was not recognized by the server.
    INVALID_HTTP_VERB = "InvalidHttpVerb"
    # Bad Request (400) = The key for one of the metadata key-value pairs is empty.
    EMPTY_METADATA_KEY = "EmptyMetadataKey"
    # Bad Request (400) = The specified XML is not syntactically valid.
    INVALID_XML_DOCUMENT = "InvalidXmlDocument"
    # Bad Request (400) = The MD5 value specified in the request did not match the MD5 value calculated by the server.
    MD5_MISMATCH = "Md5Mismatch"
    # Bad Request (400) = The MD5 value specified in the request is invalid. The MD5 value must be 128 bits and Base64-encoded.
    INVALID_MD5 = "InvalidMd5"
    # Bad Request (400) = One of the request inputs is out of range.
    OUT_OF_RANGE_INPUT = "OutOfRangeInput"
    # Bad Request (400) = The authentication information was not provided in the correct format. Verify the value of Authorization header.
    INVALID_AUTHENTICATION_INFO = "InvalidAuthenticationInfo"
    # Bad Request (400) = One of the request inputs is not valid.
    INVALID_INPUT = "InvalidInput"
    # Bad Request (400) = The specified metadata is invalid. It includes characters that are not permitted.
    INVALID_METADATA = "InvalidMetadata"
    # Bad Request (400) = The specifed resource name contains invalid characters.
    INVALID_RESOURCE_NAME = "InvalidResourceName"
    # Bad Request (400) = The size of the specified metadata exceeds the maximum size permitted.
    METADATA_TOO_LARGE = "MetadataTooLarge"
    # Bad Request (400) = Condition headers are not supported.
    CONDITION_HEADER_NOT_SUPPORTED = "ConditionHeadersNotSupported"
    # Bad Request (400) = Multiple condition headers are not supported.
    MULTIPLE_CONDITION_HEADER_NOT_SUPPORTED = "MultipleConditionHeadersNotSupported"
    # Forbidden (403) = Server failed to authenticate the request. Make sure the value of the Authorization header is formed correctly including the signature.
    AUTHENTICATION_FAILED = "AuthenticationFailed"
    # Forbidden (403) = Read-access geo-redundant replication is not enabled for the account.
    # Forbidden (403) = Write operations to the secondary location are not allowed.
    # Forbidden (403) = The account being accessed does not have sufficient permissions to execute this operation.
    INSUFFICIENT_ACCOUNT_PERMISSIONS = "InsufficientAccountPermissions"
    # Not Found (404) = The specified resource does not exist.
    RESOURCE_NOT_FOUND = "ResourceNotFound"
    # Forbidden (403) = The specified account is disabled.
    ACCOUNT_IS_DISABLED = "AccountIsDisabled"
    # Method Not Allowed (405) = The resource doesn't support the specified HTTP verb.
    UNSUPPORTED_HTTP_VERB = "UnsupportedHttpVerb"
    # Conflict (409) = The specified account already exists.
    ACCOUNT_ALREADY_EXISTS = "AccountAlreadyExists"
    # Conflict (409) = The specified account is in the process of being created.
    ACCOUNT_BEING_CREATED = "AccountBeingCreated"
    # Conflict (409) = The specified resource already exists.
    RESOURCE_ALREADY_EXISTS = "ResourceAlreadyExists"
    # Conflict (409) = The specified resource type does not match the type of the existing resource.
    RESOURCE_TYPE_MISMATCH = "ResourceTypeMismatch"
    # Length Required (411) = The Content-Length header was not specified.
    MISSING_CONTENT_LENGTH_HEADER = "MissingContentLengthHeader"
    # Request Entity Too Large (413) = The size of the request body exceeds the maximum size permitted.
    REQUEST_BODY_TOO_LARGE = "RequestBodyTooLarge"
    # Requested Range Not Satisfiable (416) = The range specified is invalid for the current size of the resource.
    INVALID_RANGE = "InvalidRange"
    # Internal Server Error (500) = The server encountered an internal error. Please retry the request.
    INTERNAL_ERROR = "InternalError"
    # Internal Server Error (500) = The operation could not be completed within the permitted time.
    OPERATION_TIMED_OUT = "OperationTimedOut"
    # Service Unavailable (503) = The server is currently unable to receive requests. Please retry your request.
    SERVER_BUSY = "ServerBusy"

    # Legacy error code strings
    UPDATE_CONDITION_NOT_SATISFIED = "UpdateConditionNotSatisfied"
    CONTAINER_NOT_FOUND = "ContainerNotFound"
    CONTAINER_ALREADY_EXISTS = "ContainerAlreadyExists"
    CONTAINER_DISABLED = "ContainerDisabled"
    CONTAINER_BEING_DELETED = "ContainerBeingDeleted"
  end
end
