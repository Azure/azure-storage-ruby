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
require "azure/storage/table/version"

module Azure::Storage::Table
  module Default
    # Default REST service (STG) version number
    STG_VERSION = "2016-05-31"

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

    # Default User Agent header string
    USER_AGENT = "Azure-Storage/#{Azure::Storage::Table::Version.to_uas}-#{Azure::Storage::Common::Version.to_uas} (Ruby #{RUBY_VERSION}-p#{RUBY_PATCHLEVEL}; #{Azure::Storage::Common::Default.os})".freeze
  end

  # Defines constants for use with table storage.
  module TableConstants
    # The changeset response delimiter.
    CHANGESET_DELIMITER = "--changesetresponse_"

    # The batch response delimiter.
    BATCH_DELIMITER = "--batchresponse_"

    # The next continuation row key token.
    CONTINUATION_NEXT_ROW_KEY = "x-ms-continuation-nextrowkey"

    # The next continuation partition key token.
    CONTINUATION_NEXT_PARTITION_KEY = "x-ms-continuation-nextpartitionkey"

    # The next continuation table name token.
    CONTINUATION_NEXT_TABLE_NAME = "x-ms-continuation-nexttablename"

    # The next row key query string argument.
    NEXT_ROW_KEY = "NextRowKey"

    # The next partition key query string argument.
    NEXT_PARTITION_KEY = "NextPartitionKey"

    # The next table name query string argument.
    NEXT_TABLE_NAME = "NextTableName"

    # Prefix of the odata properties returned in a JSON query
    ODATA_PREFIX = "odata."

    # Constant representing the string following a type annotation in a JSON table query
    ODATA_TYPE_SUFFIX = "@odata.type"

    # Constant representing the property where the odata metadata elements are stored.
    ODATA_METADATA_MARKER = ".metadata"

    # Constant representing the value for an entity property.
    ODATA_VALUE_MARKER = "_"

    # Constant representing the type for an entity property.
    ODATA_TYPE_MARKER = "$"

    # Constant representing the hash key of etag for an entity property in JSON.
    ODATA_ETAG = "odata.etag"

    # The value to set the maximum data service version header.
    DEFAULT_DATA_SERVICE_VERSION = "3.0;NetFx"

    # The name of the property that stores the table name.
    TABLE_NAME = "TableName"

    # The name of the special table used to store tables.
    TABLE_SERVICE_TABLE_NAME = "Tables"

    # The key of partition key in hash
    PARTITION_KEY = "PartitionKey"

    # The key of row key in hash
    ROW_KEY = "RowKey"

    # Operations
    module Operations
      RETRIEVE = "RETRIEVE"
      INSERT = "INSERT"
      UPDATE = "UPDATE"
      MERGE = "MERGE"
      DELETE = "DELETE"
      INSERT_OR_REPLACE = "INSERT_OR_REPLACE"
      INSERT_OR_MERGE = "INSERT_OR_MERGE"
    end
  end

  module TableErrorCodeStrings
    XMETHOD_NOT_USING_POST = "XMethodNotUsingPost"
    XMETHOD_INCORRECT_VALUE = "XMethodIncorrectValue"
    XMETHOD_INCORRECT_COUNT = "XMethodIncorrectCount"
    TABLE_HAS_NO_PROPERTIES = "TableHasNoProperties"
    DUPLICATE_PROPERTIES_SPECIFIED = "DuplicatePropertiesSpecified"
    TABLE_HAS_NO_SUCH_PROPERTY = "TableHasNoSuchProperty"
    DUPLICATE_KEY_PROPERTY_SPECIFIED = "DuplicateKeyPropertySpecified"
    TABLE_ALREADY_EXISTS = "TableAlreadyExists"
    TABLE_NOT_FOUND = "TableNotFound"
    ENTITY_NOT_FOUND = "EntityNotFound"
    ENTITY_ALREADY_EXISTS = "EntityAlreadyExists"
    PARTITION_KEY_NOT_SPECIFIED = "PartitionKeyNotSpecified"
    OPERATOR_INVALID = "OperatorInvalid"
    UPDATE_CONDITION_NOT_SATISFIED = "UpdateConditionNotSatisfied"
    PROPERTIES_NEED_VALUE = "PropertiesNeedValue"
    PARTITION_KEY_PROPERTY_CANNOT_BE_UPDATED = "PartitionKeyPropertyCannotBeUpdated"
    TOO_MANY_PROPERTIES = "TooManyProperties"
    ENTITY_TOO_LARGE = "EntityTooLarge"
    PROPERTY_VALUE_TOO_LARGE = "PropertyValueTooLarge"
    INVALID_VALUE_TYPE = "InvalidValueType"
    TABLE_BEING_DELETED = "TableBeingDeleted"
    TABLE_SERVER_OUT_OF_MEMORY = "TableServerOutOfMemory"
    PRIMARY_KEY_PROPERTY_IS_INVALID_TYPE = "PrimaryKeyPropertyIsInvalidType"
    PROPERTY_NAME_TOO_LONG = "PropertyNameTooLong"
    PROPERTY_NAME_INVALID = "PropertyNameInvalid"
    BATCH_OPERATION_NOT_SUPPORTED = "BatchOperationNotSupported"
    JSON_FORMAT_NOT_SUPPORTED = "JsonFormatNotSupported"
    METHOD_NOT_ALLOWED = "MethodNotAllowed"
    NOT_IMPLEMENTED = "NotImplemented"
  end
end
