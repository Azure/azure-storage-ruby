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
  module SR
    ANONYMOUS_ACCESS_BLOBSERVICE_ONLY = 'Anonymous access is only valid for the BlobService.'
    ARGUMENT_NULL_OR_EMPTY = 'The argument must not be null or an empty string. Argument name: %s.'
    ARGUMENT_NULL_OR_UNDEFINED = 'The argument must not be null or undefined. Argument name: %s.'
    ARGUMENT_OUT_OF_RANGE_ERROR = 'The argument is out of range. Argument name: %s, Value passed: %s.'
    BATCH_ONE_PARTITION_KEY = 'All entities in the batch must have the same PartitionKey value.'
    BATCH_ONE_RETRIEVE = 'If a retrieve operation is part of a batch, it must be the only operation in the batch.'
    BATCH_TOO_LARGE = 'Batches must not contain more than 100 operations.'
    BLOB_INVALID_SEQUENCE_NUMBER = 'The sequence number may not be specified for an increment operation.'
    BLOB_TYPE_MISMATCH = 'Blob type of the blob reference doesn\'t match blob type of the blob.'
    CANNOT_CREATE_SAS_WITHOUT_ACCOUNT_KEY = 'Cannot create Shared Access Signature unless the Account Name and Key are used to create the ServiceClient.'
    CONTENT_LENGTH_MISMATCH = 'An incorrect number of bytes was read from the connection. The connection may have been closed.'
    CONTENT_TYPE_MISSING = 'Content-Type response header is missing or invalid.'
    EMPTY_BATCH = 'Batch must not be empty.'
    EXCEEDED_SIZE_LIMITATION = 'Upload exceeds the size limitation. Max size is %s but the current size is %s'
    HASH_MISMATCH = 'Hash mismatch (integrity check failed), Expected value is %s, retrieved %s.'
    INCORRECT_ENTITY_KEYS = 'PartitionKey and RowKey must be specified as strings in the entity object.'
    INVALID_BLOB_LENGTH = 'createBlockBlobFromText requires the size of text to be less than 64MB. Please use createBlockBlobFromLocalFile or createBlockBlobFromStream to upload large blobs.'
    INVALID_CONNECTION_STRING = 'Connection strings must be of the form "key1=value1;key2=value2".'
    INVALID_CONNECTION_STRING_BAD_KEY = 'Connection string contains unrecognized key: "%s"'
    INVALID_CONNECTION_STRING_DUPLICATE_KEY = 'Connection string contains duplicate key: "%s"'
    INVALID_CONNECTION_STRING_EMPTY_KEY = 'Connection strings must not contain empty keys.'
    INVALID_CLIENT_OPTIONS = 'Storage client options are invalid'
    INVALID_DELETE_SNAPSHOT_OPTION = 'The deleteSnapshots option cannot be included when deleting a specific snapshot using the snapshotId option.'
    INVALID_EDM_TYPE = 'The value \'%s\' does not match the type \'%s\'.'
    INVALID_FILE_LENGTH = 'createFileFromText requires the size of text to be less than 4MB. Please use createFileFromLocalFile or createFileFromStream to upload large files.'
    INVALID_FILE_RANGE_FOR_UPDATE = 'Range size should be less than 4MB for a file range update operation.'
    INVALID_HEADERS = 'Headers are not supported in the 2012-02-12 version.'
    INVALID_MESSAGE_ID = 'Message ID cannot be null or undefined for deleteMessage and updateMessage operations.'
    INVALID_PAGE_BLOB_LENGTH = 'Page blob length must be multiple of 512.'
    INVALID_PAGE_END_OFFSET = 'Page end offset must be multiple of 512.'
    INVALID_PAGE_RANGE_FOR_UPDATE = 'Page range size should be less than 4MB for a page update operation.'
    INVALID_PAGE_START_OFFSET = 'Page start offset must be multiple of 512.'
    INVALID_POP_RECEIPT = 'Pop Receipt cannot be null or undefined for deleteMessage and updateMessage operations.'
    INVALID_PROPERTY_RESOLVER = 'The specified property resolver returned an invalid type. %s:{_:%s,$:%s }'
    INVALID_RANGE_FOR_MD5 = 'The requested range should be less than 4MB when contentMD5 is expected from the server'
    INVALID_SAS_VERSION = 'SAS Version ? is invalid. Valid versions include: ?.'
    INVALID_SAS_TOKEN = 'The SAS token should not contain api-version.'
    INVALID_SIGNED_IDENTIFIERS = 'Signed identifiers need to be an array.'
    INVALID_STREAM_LENGTH = 'The length of the provided stream is invalid.'
    INVALID_STRING_ERROR = 'Invalid string error.'
    INVALID_TABLE_OPERATION = 'Operation not found: %s'
    INVALID_TEXT_LENGTH = 'The length of the provided text is invalid.'
    MAXIMUM_EXECUTION_TIMEOUT_EXCEPTION = 'The client could not finish the operation within specified maximum execution timeout.'
    MD5_NOT_PRESENT_ERROR = 'MD5 does not exist. If you do not want to force validation, please disable useTransactionalMD5.'
    METADATA_KEY_INVALID = 'The key for one of the metadata key-value pairs is null, empty, or whitespace.'
    METADATA_VALUE_INVALID = 'The value for one of the metadata key-value pairs is null, empty, or whitespace.'
    NO_CREDENTIALS_PROVIDED = 'Credentials must be provided when creating a service client.'
    PRIMARY_ONLY_COMMAND = 'This operation can only be executed against the primary storage location.'
    QUERY_OPERATOR_REQUIRES_WHERE = '%s operator needs to be used after where.'
    SECONDARY_ONLY_COMMAND = 'This operation can only be executed against the secondary storage location.'
    STORAGE_HOST_LOCATION_REQUIRED = 'The host for the storage service must be specified.'
    STORAGE_HOST_MISSING_LOCATION = 'The host for the target storage location is not specified. Please consider changing the request\'s location mode.'
    TYPE_NOT_SUPPORTED = 'Type not supported when sending data to the service: '
    MAX_BLOB_SIZE_CONDITION_NOT_MEET = 'The max blob size condition specified was not met.'
  end
end
