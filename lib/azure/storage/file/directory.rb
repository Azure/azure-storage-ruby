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
  module Directory
    include Azure::Storage::Service
    
    class Directory
      def initialize
        @properties = {}
        @metadata = {}
        yield self if block_given?
      end

      attr_accessor :name
      attr_accessor :properties
      attr_accessor :metadata
    end
  end

  # Public: Get a list of files or directories under the specified share or directory.
  #         It lists the contents only for a single level of the directory hierarchy.
  #
  # ==== Attributes
  #
  # * +share+                     - String. The name of the file share.
  # * +directory_path+            - String. The path to the directory.
  # * +options+                   - Hash. Optional parameters.
  #
  # ==== Options
  #
  # Accepted key/value pairs in options parameter are:
  #
  # * +:marker+                  - String. An identifier the specifies the portion of the
  #                                list to be returned. This value comes from the property
  #                                Azure::Service::EnumerationResults.continuation_token when there
  #                                are more shares available than were returned. The
  #                                marker value may then be used here to request the next set
  #                                of list items. (optional)
  #
  # * +:max_results+             - Integer. Specifies the maximum number of shares to return.
  #                                If max_results is not specified, or is a value greater than
  #                                5,000, the server will return up to 5,000 items. If it is set
  #                                to a value less than or equal to zero, the server will return
  #                                status code 400 (Bad Request). (optional)
  #
  # * +:timeout+                 - Integer. A timeout in seconds.
  #
  # * +:request_id+              - String. Provides a client-generated, opaque value with a 1 KB character limit that is recorded 
  #                                in the analytics logs when storage analytics logging is enabled.
  #
  # See: https://docs.microsoft.com/en-us/rest/api/storageservices/fileservices/list-directories-and-files
  #
  # Returns an Azure::Service::EnumerationResults
  #
  def list_directories_and_files(share, directory_path, options={})
    query = {'comp' => 'list'}
    unless options.nil?
      StorageService.with_query query, 'marker', options[:marker]
      StorageService.with_query query, 'maxresults', options[:max_results].to_s if options[:max_results]
      StorageService.with_query query, 'timeout', options[:timeout].to_s if options[:timeout]
    end

    uri = directory_uri(share, directory_path, query)
    response = call(:get, uri, nil, {}, options)

    # Result
    if response.success?
      Serialization.directories_and_files_enumeration_results_from_xml(response.body)
    else
      response.exception
    end
  end

  # Public: Create a new directory
  #
  # ==== Attributes
  #
  # * +share+                     - String. The name of the file share.
  # * +directory_path+            - String. The path to the directory.
  # * +options+                   - Hash. Optional parameters.
  #
  # ==== Options
  #
  # Accepted key/value pairs in options parameter are:
  # * +:metadata+                 - Hash. User defined metadata for the share (optional).
  # * +:timeout+                  - Integer. A timeout in seconds.
  # * +:request_id+               - String. Provides a client-generated, opaque value with a 1 KB character limit that is recorded 
  #                                 in the analytics logs when storage analytics logging is enabled.
  #
  # See https://docs.microsoft.com/en-us/rest/api/storageservices/fileservices/create-directory
  #
  # Returns a Directory
  def create_directory(share, directory_path, options={})
    # Query
    query = { }
    query['timeout'] = options[:timeout].to_s if options[:timeout]

    # Scheme + path
    uri = directory_uri(share, directory_path, query)

    # Headers
    headers = StorageService.common_headers
    StorageService.add_metadata_to_headers(options[:metadata], headers) if options[:metadata]

    # Call
    response = call(:put, uri, nil, headers, options)

    # result
    directory = Serialization.directory_from_headers(response.headers)
    directory.name = directory_path
    directory.metadata = options[:metadata] if options[:metadata]
    directory
  end

  # Public: Returns all system properties for the specified directory,
  #         and can also be used to check the existence of a directory.
  #         The data returned does not include the files in the directory or any subdirectories.
  #
  # ==== Attributes
  #
  # * +share+                     - String. The name of the file share.
  # * +directory_path+            - String. The path to the directory.
  # * +options+                   - Hash. Optional parameters.
  #
  # ==== Options
  #
  # Accepted key/value pairs in options parameter are:
  # * +:timeout+                  - Integer. A timeout in seconds.
  # * +:request_id+               - String. Provides a client-generated, opaque value with a 1 KB character limit that is recorded 
  #                                 in the analytics logs when storage analytics logging is enabled.
  #
  # See https://docs.microsoft.com/en-us/rest/api/storageservices/fileservices/get-directory-properties
  #
  # Returns a Directory
  def get_directory_properties(share, directory_path, options={})
    # Query
    query = { }
    query['timeout'] = options[:timeout].to_s if options[:timeout]

    # Call
    response = call(:get, directory_uri(share, directory_path, query), nil, {}, options)

    # result
    directory = Serialization.directory_from_headers(response.headers)
    directory.name = directory_path
    directory
  end

  # Public: Deletes a directory.
  #
  # ==== Attributes
  #
  # * +share+                     - String. The name of the file share.
  # * +directory_path+            - String. The path to the directory.
  # * +options+                   - Hash. Optional parameters.
  #
  # ==== Options
  #
  # Accepted key/value pairs in options parameter are:
  # * +:timeout+                  - Integer. A timeout in seconds.
  # * +:request_id+               - String. Provides a client-generated, opaque value with a 1 KB character limit that is recorded 
  #                                 in the analytics logs when storage analytics logging is enabled.
  #
  # See https://docs.microsoft.com/en-us/rest/api/storageservices/fileservices/delete-directory
  #
  # Returns nil on success
  def delete_directory(share, directory_path, options={})
    # Query
    query = { }
    query['timeout'] = options[:timeout].to_s if options[:timeout]

    # Call
    call(:delete, directory_uri(share, directory_path, query), nil, {}, options)
    
    # result
    nil
  end

  # Public: Returns only user-defined metadata for the specified directory.
  #
  # ==== Attributes
  #
  # * +share+                     - String. The name of the file share.
  # * +directory_path+            - String. The path to the directory.
  # * +options+                   - Hash. Optional parameters.
  #
  # ==== Options
  #
  # Accepted key/value pairs in options parameter are:
  # * +:timeout+                  - Integer. A timeout in seconds.
  # * +:request_id+               - String. Provides a client-generated, opaque value with a 1 KB character limit that is recorded 
  #                                 in the analytics logs when storage analytics logging is enabled.
  #
  # See https://docs.microsoft.com/en-us/rest/api/storageservices/fileservices/get-directory-metadata
  #
  # Returns a Directory
  def get_directory_metadata(share, directory_path, options={})
    # Query
    query = { 'comp' => 'metadata' }
    query['timeout'] = options[:timeout].to_s if options[:timeout]

    # Call
    response = call(:get, directory_uri(share, directory_path, query), nil, {}, options)

    # result
    directory = Serialization.directory_from_headers(response.headers)
    directory.name = directory_path
    directory
  end

  # Public: Sets custom metadata for the directory.
  #
  # ==== Attributes
  #
  # * +share+                     - String. The name of the file share.
  # * +directory_path+            - String. The path to the directory.
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
  # See https://docs.microsoft.com/en-us/rest/api/storageservices/fileservices/set-directory-metadata
  #
  # Returns nil on success
  def set_directory_metadata(share, directory_path, metadata, options={})
    # Query
    query = { 'comp' => 'metadata' }
    query['timeout'] = options[:timeout].to_s if options[:timeout]

    # Headers
    headers = StorageService.common_headers
    StorageService.add_metadata_to_headers(metadata, headers) if metadata

    # Call
    call(:put, directory_uri(share, directory_path, query), nil, headers, options)
    
    # Result
    nil
  end
end