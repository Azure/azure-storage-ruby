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
require 'azure/storage/file/serialization'

module Azure::Storage::File
  include Azure::Storage::Service
    
  class File
    def initialize
      @properties = {}
      @metadata = {}
      yield self if block_given?
    end

    attr_accessor :name
    attr_accessor :properties
    attr_accessor :metadata
  end

  # Public: Creates a new file or replaces a file. Note that it only initializes the file.
  #         To add content to a file, call the put_range operation.
  #
  # Updating an existing file overwrites any existing metadata on the file
  # Partial updates are not supported with create_file. The content of the
  # existing file is overwritten with the content of the new file. To perform a
  # partial update of the content of a file, use the put_range method.
  #
  # Note that the default content type is application/octet-stream.
  #
  # ==== Attributes
  #
  # * +share+                      - String. The name of the file share.
  # * +directory_path+             - String. The path to the directory.
  # * +file+                       - String. The name of the file.
  # * +length+                     - Integer. Specifies the maximum byte value for the file, up to 1 TB.
  # * +options+                    - Hash. Optional parameters.
  #
  # ==== Options
  #
  # Accepted key/value pairs in options parameter are:
  # * +:content_type+              - String. Content type for the file. Will be saved with file.
  # * +:content_encoding+          - String. Content encoding for the file. Will be saved with file.
  # * +:content_language+          - String. Content language for the file. Will be saved with file.
  # * +:content_md5+               - String. Content MD5 for the file. Will be saved with file.
  # * +:cache_control+             - String. Cache control for the file. Will be saved with file.
  # * +:content_disposition+       - String. Conveys additional information about how to process the response payload, 
  #                                  and also can be used to attach additional metadata
  # * +:metadata+                  - Hash. Custom metadata values to store with the file.
  # * +:timeout+                   - Integer. A timeout in seconds.
  # * +:request_id+                - String. Provides a client-generated, opaque value with a 1 KB character limit that is recorded 
  #                                  in the analytics logs when storage analytics logging is enabled.
  #
  # See https://docs.microsoft.com/en-us/rest/api/storageservices/fileservices/create-file
  #
  # Returns a File
  def create_file(share, directory_path, file, length, options={})
    query = { }
    StorageService.with_query query, 'timeout', options[:timeout].to_s if options[:timeout]

    uri = file_uri(share, directory_path, file, query)

    headers = StorageService.common_headers

    # set x-ms-type to file
    StorageService.with_header headers, 'x-ms-type', 'file'

    # ensure content-length is 0 and x-ms-content-length is the file length
    StorageService.with_header headers, 'Content-Length', 0.to_s
    StorageService.with_header headers, 'x-ms-content-length', length.to_s

    # set the rest of the optional headers
    StorageService.with_header headers, 'x-ms-content-type', options[:content_type]
    StorageService.with_header headers, 'x-ms-content-encoding', options[:content_encoding]
    StorageService.with_header headers, 'x-ms-content-language', options[:content_language]
    StorageService.with_header headers, 'x-ms-content-md5', options[:content_md5]
    StorageService.with_header headers, 'x-ms-cache-control', options[:cache_control]
    StorageService.with_header headers, 'x-ms-content-disposition', options[:content_disposition]

    StorageService.add_metadata_to_headers options[:metadata], headers

    response = call(:put, uri, nil, headers, options)

    result = Serialization.file_from_headers(response.headers)
    result.name = file
    result.properties[:content_length] = length
    result.metadata = options[:metadata] if options[:metadata]
    result
  end

  # Public: Reads or downloads a file from the system, including its metadata and properties.
  #
  # ==== Attributes
  #
  # * +share+                      - String. The name of the file share.
  # * +directory_path+             - String. The path to the directory.
  # * +file+                       - String. The name of the file.
  # * +options+                    - Hash. Optional parameters.
  #
  # ==== Options
  #
  # Accepted key/value pairs in options parameter are:
  # * +:start_range+               - Integer. Position of the start range. (optional)
  # * +:end_range+                 - Integer. Position of the end range. (optional)
  # * +:get_content_md5+           - Boolean. Return the MD5 hash for the range. This option only valid if
  #                                  start_range and end_range are specified. (optional)
  # * +:timeout+                   - Integer. A timeout in seconds.
  # * +:request_id+                - String. Provides a client-generated, opaque value with a 1 KB character limit that is recorded 
  #                                  in the analytics logs when storage analytics logging is enabled.
  #
  # See https://docs.microsoft.com/en-us/rest/api/storageservices/fileservices/get-file
  #
  # Returns a File and the file body
  def get_file(share, directory_path, file, options={})
    query = { }
    StorageService.with_query query, 'timeout', options[:timeout].to_s if options[:timeout]
    uri = file_uri(share, directory_path, file, query)

    headers = StorageService.common_headers
    options[:start_range] = 0 if options[:end_range] and not options[:start_range]
    if options[:start_range]
      StorageService.with_header headers, 'x-ms-range', "bytes=#{options[:start_range]}-#{options[:end_range]}"
      StorageService.with_header headers, 'x-ms-range-get-content-md5', true if options[:get_content_md5]
    end

    response = call(:get, uri, nil, headers, options)
    result = Serialization.file_from_headers(response.headers)
    result.name = file
    return result, response.body
  end

  # Public: Returns all properties and metadata on the file.
  #
  # ==== Attributes
  #
  # * +share+                      - String. The name of the file share.
  # * +directory_path+             - String. The path to the directory.
  # * +file+                       - String. The name of the file.
  # * +options+                    - Hash. Optional parameters.
  #
  # ==== Options
  #
  # Accepted key/value pairs in options parameter are:
  # * +:timeout+                   - Integer. A timeout in seconds.
  # * +:request_id+                - String. Provides a client-generated, opaque value with a 1 KB character limit that is recorded 
  #                                  in the analytics logs when storage analytics logging is enabled.
  #
  # See https://docs.microsoft.com/en-us/rest/api/storageservices/fileservices/get-file-properties
  #
  # Returns a File
  def get_file_properties(share, directory_path, file, options={})
    query = { }
    StorageService.with_query query, 'timeout', options[:timeout].to_s if options[:timeout]

    headers = StorageService.common_headers
      
    uri = file_uri(share, directory_path, file, query)

    response = call(:head, uri, nil, headers, options)

    result = Serialization.file_from_headers(response.headers)
    result.name = file
    result
  end

  # Public: Sets system properties defined for a file.
  #
  # ==== Attributes
  #
  # * +share+                      - String. The name of the file share.
  # * +directory_path+             - String. The path to the directory.
  # * +file+                       - String. The name of the file.
  # * +options+                    - Hash. Optional parameters.
  #
  # ==== Options
  #
  # Accepted key/value pairs in options parameter are:
  # * +:content_type+              - String. Content type for the file. Will be saved with file.
  # * +:content_encoding+          - String. Content encoding for the file. Will be saved with file.
  # * +:content_language+          - String. Content language for the file. Will be saved with file.
  # * +:content_md5+               - String. Content MD5 for the file. Will be saved with file.
  # * +:cache_control+             - String. Cache control for the file. Will be saved with file.
  # * +:content_disposition+       - String. Conveys additional information about how to process the response payload, 
  #                                  and also can be used to attach additional metadata
  # * +:content_length+            - Integer. Resizes a file to the specified size. If the specified
  #                                  value is less than the current size of the file, then all ranges above
  #                                  the specified value are cleared.
  # * +:timeout+                   - Integer. A timeout in seconds.
  # * +:request_id+                - String. Provides a client-generated, opaque value with a 1 KB character limit that is recorded 
  #                                  in the analytics logs when storage analytics logging is enabled.
  #
  # See https://docs.microsoft.com/en-us/rest/api/storageservices/fileservices/set-file-properties
  #
  # Returns nil on success.
  def set_file_properties(share, directory_path, file, options={})
    query = {'comp' => 'properties'}
    StorageService.with_query query, 'timeout', options[:timeout].to_s if options[:timeout]
    uri = file_uri(share, directory_path, file, query)

    headers = StorageService.common_headers

    unless options.empty?
      StorageService.with_header headers, 'x-ms-content-type', options[:content_type]
      StorageService.with_header headers, 'x-ms-content-encoding', options[:content_encoding]
      StorageService.with_header headers, 'x-ms-content-language', options[:content_language]
      StorageService.with_header headers, 'x-ms-content-md5', options[:content_md5]
      StorageService.with_header headers, 'x-ms-cache-control', options[:cache_control]
      StorageService.with_header headers, 'x-ms-content-length', options[:content_length].to_s if options[:content_length]
      StorageService.with_header headers, 'x-ms-content-disposition', options[:content_disposition]
    end

    call(:put, uri, nil, headers, options)
    nil
  end

  # Public: Resizes a file to the specified size.
  #
  # ==== Attributes
  #
  # * +share+                      - String. The name of the file share.
  # * +directory_path+             - String. The path to the directory.
  # * +file+                       - String. The name of the file.
  # * +size+                       - String. The file size. Resizes a file to the specified size. 
  #                                  If the specified value is less than the current size of the file, 
  #                                  then all ranges above the specified value are cleared.
  # * +options+                    - Hash. Optional parameters.
  #
  # ==== Options
  #
  # Accepted key/value pairs in options parameter are:
  # * +:timeout+                   - Integer. A timeout in seconds.
  # * +:request_id+                - String. Provides a client-generated, opaque value with a 1 KB character limit that is recorded 
  #                                  in the analytics logs when storage analytics logging is enabled.
  #
  # See https://docs.microsoft.com/en-us/rest/api/storageservices/fileservices/set-file-properties
  #
  # Returns nil on success.
  def resize_file(share, directory_path, file, size, options={})
    options = { :content_length => size }.merge(options)
    set_file_properties share, directory_path, file, options
  end

  # Public: Writes a range of bytes to a file
  #
  # ==== Attributes
  #
  # * +share+                      - String. The name of the file share.
  # * +directory_path+             - String. The path to the directory.
  # * +file+                       - String. The name of the file.
  # * +start_range+                - Integer. Position of first byte of the range.
  # * +end_range+                  - Integer. Position of last byte of of the range. The range can be up to 4 MB in size.
  # * +content+                    - IO or String. Content to write.
  # * +options+                    - Hash. A collection of options.
  #
  # ==== Options
  #
  # Accepted key/value pairs in options parameter are:
  # * +:transactional_md5+         - String. An MD5 hash of the content. This hash is used to verify the integrity of the data during transport.
  #                                  When this header is specified, the storage service checks the hash that has arrived with the one that was sent.
  # * +:timeout+                   - Integer. A timeout in seconds.
  # * +:request_id+                - String. Provides a client-generated, opaque value with a 1 KB character limit that is recorded 
  #                                  in the analytics logs when storage analytics logging is enabled.
  # 
  # See https://docs.microsoft.com/en-us/rest/api/storageservices/fileservices/put-range
  #
  # Returns a File
  #
  def put_file_range(share, directory_path, file, start_range, end_range=nil, content=nil, options={})
    query = { 'comp' => 'range' }
    StorageService.with_query query, 'timeout', options[:timeout].to_s if options[:timeout]

    uri = file_uri(share, directory_path, file, query)
    headers = StorageService.common_headers
    StorageService.with_header headers, 'Content-MD5', options[:transactional_md5]
    StorageService.with_header headers, 'x-ms-range', "bytes=#{start_range}-#{end_range}"
    StorageService.with_header headers, 'x-ms-write', 'update'
    
    response = call(:put, uri, content, headers, options)

    result = Serialization.file_from_headers(response.headers)
    result.name = file
    result
  end

  # Public: Clears a range of file.
  #
  # ==== Attributes
  #
  # * +share+                      - String. The name of the file share.
  # * +directory_path+             - String. The path to the directory.
  # * +file+                       - String. The name of the file.
  # * +start_range+                - Integer. Position of first byte of the range.
  # * +end_range+                  - Integer. Position of last byte of of the range.
  # * +options+                    - Hash. A collection of options.
  #
  # ==== Options
  #
  # Accepted key/value pairs in options parameter are:
  # * +:timeout+                   - Integer. A timeout in seconds.
  # * +:request_id+                - String. Provides a client-generated, opaque value with a 1 KB character limit that is recorded 
  #                                  in the analytics logs when storage analytics logging is enabled.
  #
  # See https://docs.microsoft.com/en-us/rest/api/storageservices/fileservices/put-range
  #
  # Returns a File
  def clear_file_range(share, directory_path, file, start_range, end_range=nil, options={})
    query = { 'comp' => 'range' }
    StorageService.with_query query, 'timeout', options[:timeout].to_s if options[:timeout]

    uri =  file_uri(share, directory_path, file, query)
    start_range = 0 if !end_range.nil? and start_range.nil?

    headers = StorageService.common_headers
    StorageService.with_header headers, 'x-ms-range', "bytes=#{start_range}-#{end_range}"
    StorageService.with_header headers, 'x-ms-write', 'clear'

    response = call(:put, uri, nil, headers, options)

    result = Serialization.file_from_headers(response.headers)
    result.name = file
    result
  end

  # Public: Returns a list of valid ranges for a file.
  #
  # ==== Attributes
  #
  # * +share+                      - String. The name of the file share.
  # * +directory_path+             - String. The path to the directory.
  # * +file+                       - String. The name of the file.
  # * +options+                    - Hash. Optional parameters.
  #
  # ==== Options
  #
  # Accepted key/value pairs in options parameter are:
  # * +:start_range+               - Integer. Position of first byte of the range.
  # * +:end_range+                 - Integer. Position of last byte of of the range.
  # * +:timeout+                   - Integer. A timeout in seconds.
  # * +:request_id+                - String. Provides a client-generated, opaque value with a 1 KB character limit that is recorded 
  #                                  in the analytics logs when storage analytics logging is enabled.
  #
  # See https://docs.microsoft.com/en-us/rest/api/storageservices/fileservices/list-ranges
  #
  # Returns a tuple of a File and a list of ranges in the format [ [start, end], [start, end], ... ]
  #
  #   eg. (Azure::Storage::File::File, [ [0, 511], [512, 1024], ... ])
  #
  def list_file_ranges(share, directory_path, file, options={})
    query = {'comp' => 'rangelist'}
    StorageService.with_query query, 'timeout', options[:timeout].to_s if options[:timeout]

    uri = file_uri(share, directory_path, file, query)

    options[:start_range] = 0 if options[:end_range] and not options[:start_range]

    headers = StorageService.common_headers
    StorageService.with_header headers, 'x-ms-range', "bytes=#{options[:start_range]}-#{options[:end_range]}" if options[:start_range]
    
    response = call(:get, uri, nil, headers, options)

    result = Serialization.file_from_headers(response.headers)
    result.name = file
    rangelist = Serialization.range_list_from_xml(response.body)
    return result, rangelist
  end

  # Public: Returns only user-defined metadata for the specified file.
  #
  # ==== Attributes
  #
  # * +share+                     - String. The name of the file share.
  # * +directory_path+            - String. The path to the directory.
  # * +file+                      - String. The name of the file.
  # * +options+                   - Hash. Optional parameters.
  #
  # ==== Options
  #
  # Accepted key/value pairs in options parameter are:
  # * +:timeout+                  - Integer. A timeout in seconds.
  # * +:request_id+               - String. Provides a client-generated, opaque value with a 1 KB character limit that is recorded 
  #                                 in the analytics logs when storage analytics logging is enabled.
  #
  # See https://docs.microsoft.com/en-us/rest/api/storageservices/fileservices/get-file-metadata
  #
  # Returns a File
  def get_file_metadata(share, directory_path, file, options={})
    # Query
    query = { 'comp' => 'metadata' }
    query['timeout'] = options[:timeout].to_s if options[:timeout]

    # Call
    response = call(:get, file_uri(share, directory_path, file, query), nil, {}, options)

    # result
    result = Serialization.file_from_headers(response.headers)
    result.name = file
    result
  end

  # Public: Sets custom metadata for the file.
  #
  # ==== Attributes
  #
  # * +share+                     - String. The name of the file share.
  # * +directory_path+            - String. The path to the directory.
  # * +file+                      - String. The name of the file.
  # * +metadata+                  - Hash. A Hash of the metadata values.
  # * +options+                   - Hash. Optional parameters.
  #
  # ==== Options
  #
  # Accepted key/value pairs in options parameter are:
  # * +:timeout+                  - Integer. A timeout in seconds.
  # * +:request_id+               - String. Provides a client-generated, opaque value with a 1 KB character limit that is recorded 
  #                                 in the analytics logs when storage analytics logging is enabled.
  #
  # See https://docs.microsoft.com/en-us/rest/api/storageservices/fileservices/set-file-metadata
  #
  # Returns nil on success
  def set_file_metadata(share, directory_path, file, metadata, options={})
    # Query
    query = { 'comp' => 'metadata' }
    query['timeout'] = options[:timeout].to_s if options[:timeout]

    # Headers
    headers = StorageService.common_headers
    StorageService.add_metadata_to_headers(metadata, headers) if metadata

    # Call
    call(:put, file_uri(share, directory_path, file, query), nil, headers, options)
    
    # Result
    nil
  end

  # Public: Deletes a file.
  #
  # ==== Attributes
  #
  # * +share+                     - String. The name of the file share.
  # * +directory_path+            - String. The path to the directory.
  # * +file+                      - String. The name of the file.
  # * +options+                   - Hash. Optional parameters.
  #
  # ==== Options
  #
  # Accepted key/value pairs in options parameter are:
  # * +:timeout+                  - Integer. A timeout in seconds.
  # * +:request_id+               - String. Provides a client-generated, opaque value with a 1 KB character limit that is recorded 
  #                                 in the analytics logs when storage analytics logging is enabled.
  #
  # See https://docs.microsoft.com/en-us/rest/api/storageservices/fileservices/delete-file2
  #
  # Returns nil on success
  def delete_file(share, directory_path, file, options={})
    # Query
    query = { }
    query['timeout'] = options[:timeout].to_s if options[:timeout]
    
    # Call
    call(:delete, file_uri(share, directory_path, file, query), nil, {}, options)
    
    # result
    nil
  end

  # Public: Copies a source file or file to a destination file within the storage account.
  #
  # ==== Attributes
  #
  # * +destination_share+             - String. The name of the destination file share.
  # * +destination_directory_path+    - String. The path to the destination directory.
  # * +destination_file+              - String. The name of the destination file.
  # * +source_uri+                    - String. The source file or file URI to copy from.
  # * +options+                       - Hash. Optional parameters.
  #
  # ==== Options
  #
  # Accepted key/value pairs in options parameter are:
  # * +:metadata+                   - Hash. Custom metadata values to store with the copy. If this parameter is not
  #                                   specified, the operation will copy the source file metadata to the destination
  #                                   file. If this parameter is specified, the destination file is created with the
  #                                   specified metadata, and metadata is not copied from the source file.
  # * +:timeout+                    - Integer. A timeout in seconds.
  # * +:request_id+                 - String. Provides a client-generated, opaque value with a 1 KB character limit that is recorded 
  #                                   in the analytics logs when storage analytics logging is enabled.
  #
  # See https://docs.microsoft.com/en-us/rest/api/storageservices/fileservices/copy-file
  #
  # Returns a tuple of (copy_id, copy_status).
  #
  # * +copy_id+                    - String identifier for this copy operation. Use with get_file or get_file_properties to check
  #                                  the status of this copy operation, or pass to abort_copy_file to abort a pending copy.
  # * +copy_status+                - String. The state of the copy operation, with these values:
  #                                    "success" - The copy completed successfully.
  #                                    "pending" - The copy is in progress.
  #
  def copy_file_from_uri(destination_share, destination_directory_path, destination_file, source_uri, options={})
    query = { }
    StorageService.with_query query, 'timeout', options[:timeout].to_s if options[:timeout]

    uri = file_uri(destination_share, destination_directory_path, destination_file, query)
    headers = StorageService.common_headers
    StorageService.with_header headers, 'x-ms-copy-source', source_uri
    StorageService.add_metadata_to_headers options[:metadata], headers unless options.empty?

    response = call(:put, uri, nil, headers, options)
    return response.headers['x-ms-copy-id'], response.headers['x-ms-copy-status']
  end

  # Public: Copies a source file to a destination file within the same storage account.
  #
  # ==== Attributes
  #
  # * +destination_share+             - String. The destination share name to copy to.
  # * +destination_directory_path+    - String. The path to the destination directory.
  # * +source_file+                   - String. The destination file name to copy to.
  # * +source_share+                  - String. The source share name to copy from.
  # * +source_directory_path+         - String. The path to the source directory.
  # * +source_file+                   - String. The source file name to copy from.
  # * +options+                       - Hash. Optional parameters.
  #
  # ==== Options
  #
  # Accepted key/value pairs in options parameter are:
  # * +:metadata+                   - Hash. Custom metadata values to store with the copy. If this parameter is not
  #                                   specified, the operation will copy the source file metadata to the destination
  #                                   file. If this parameter is specified, the destination file is created with the
  #                                   specified metadata, and metadata is not copied from the source file.
  # * +:timeout+                    - Integer. A timeout in seconds.
  # * +:request_id+                 - String. Provides a client-generated, opaque value with a 1 KB character limit that is recorded 
  #                                   in the analytics logs when storage analytics logging is enabled.
  #
  # See https://docs.microsoft.com/en-us/rest/api/storageservices/fileservices/copy-file
  #
  # Returns a tuple of (copy_id, copy_status).
  #
  # * +copy_id+                    - String identifier for this copy operation. Use with get_file or get_file_properties to check
  #                                  the status of this copy operation, or pass to abort_copy_file to abort a pending copy.
  # * +copy_status+                - String. The state of the copy operation, with these values:
  #                                    "success" - The copy completed successfully.
  #                                    "pending" - The copy is in progress.
  #
  def copy_file(destination_share, destination_directory_path, destination_file, source_share, source_directory_path, source_file, options={})
    source_file_uri = file_uri(source_share, source_directory_path, source_file, {}).to_s

    return copy_file_from_uri(destination_share, destination_directory_path, destination_file, source_file_uri, options)
  end

  # Public: Aborts a pending Copy File operation and leaves a destination file with zero length and full metadata. 
  #
  # ==== Attributes
  #
  # * +share+                 - String. The name of the destination file share.
  # * +directory_path+        - String. The path to the destination directory.
  # * +file+                  - String. The name of the destination file.
  # * +copy_id+               - String. The copy identifier returned in the copy file operation.
  # * +options+               - Hash. Optional parameters.
  #
  # ==== Options
  #
  # Accepted key/value pairs in options parameter are:
  # * +:timeout+              - Integer. A timeout in seconds.
  # * +:request_id+           - String. Provides a client-generated, opaque value with a 1 KB character limit that is recorded 
  #                             in the analytics logs when storage analytics logging is enabled.
  #
  # See https://docs.microsoft.com/en-us/rest/api/storageservices/fileservices/abort-copy-file
  #
  # Returns nil on success
  def abort_copy_file(share, directory_path, file, copy_id, options={})
    query = {'comp' => 'copy'}
    StorageService.with_query query, 'timeout', options[:timeout].to_s if options[:timeout]
    StorageService.with_query query, 'copyid', copy_id

    uri = file_uri(share, directory_path, file, query);
    headers = StorageService.common_headers
    StorageService.with_header headers, 'x-ms-copy-action', 'abort';

    call(:put, uri, nil, headers, options)
    nil
  end
end