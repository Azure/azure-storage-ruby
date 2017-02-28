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
require 'azure/storage/core/auth/shared_key'
require 'azure/storage/file/serialization'
require 'azure/storage/file/file'

module Azure::Storage
  module File
    class FileService < StorageService
      include Azure::Storage::Core::Utility
      include Azure::Storage::File::Share
      include Azure::Storage::File::Directory
      include Azure::Storage::File

      def initialize(options = {}, &block)
        client_config = options[:client] || Azure::Storage
        signer = options[:signer] || client_config.signer || Core::Auth::SharedKey.new(client_config.storage_account_name, client_config.storage_access_key)
        super(signer, client_config.storage_account_name, options, &block)
        @host = client.storage_file_host
      end

      def call(method, uri, body=nil, headers={}, options={})
        # Force the request.body to the content encoding of specified in the header
        if headers && !body.nil? && (body.is_a? String) && ((body.encoding.to_s <=> 'ASCII_8BIT') != 0)
          if headers['x-ms-content-type'].nil?
            Service::StorageService.with_header headers, 'x-ms-content-type', "text/plain; charset=#{body.encoding}"
          else
            charset = parse_charset_from_content_type(headers['x-ms-content-type'])
            body.force_encoding(charset) if charset
          end
        end

        response = super

        # Force the response.body to the content charset of specified in the header.
        # Content-Type is echo'd back for the blob and is used to store the encoding of the octet stream
        if !response.nil? && !response.body.nil? && response.headers['Content-Type']
          charset = parse_charset_from_content_type(response.headers['Content-Type'])
          response.body.force_encoding(charset) if charset && charset.length > 0
        end

        response
      end

      # Public: Get a list of Shares from the server.
      #
      # ==== Attributes
      #
      # * +options+                  - Hash. Optional parameters.
      #
      # ==== Options
      #
      # Accepted key/value pairs in options parameter are:
      # * +:prefix+                  - String. Filters the results to return only shares
      #                                whose name begins with the specified prefix. (optional)
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
      # * +:metadata+                - Boolean. Specifies whether or not to return the share metadata.
      #                                (optional, Default=false)
      #
      # * +:timeout+                 - Integer. A timeout in seconds.
      #
      # * +:request_id+              - String. Provides a client-generated, opaque value with a 1 KB character limit that is recorded 
      #                                in the analytics logs when storage analytics logging is enabled.
      #
      # See: https://docs.microsoft.com/en-us/rest/api/storageservices/fileservices/list-shares
      #
      # Returns an Azure::Service::EnumerationResults
      #
      def list_shares(options={})
        query = { }
        if options
          StorageService.with_query query, 'prefix', options[:prefix]
          StorageService.with_query query, 'marker', options[:marker]
          StorageService.with_query query, 'maxresults', options[:max_results].to_s if options[:max_results]
          StorageService.with_query query, 'include', 'metadata' if options[:metadata] == true
          StorageService.with_query query, 'timeout', options[:timeout].to_s if options[:timeout]
        end

        uri = shares_uri(query)
        response = call(:get, uri, nil, {}, options)

        Serialization.share_enumeration_results_from_xml(response.body)
      end

      # Protected: Generate the URI for the collection of shares.
      #
      # ==== Attributes
      #
      # * +query+ - A Hash of key => value query parameters.
      #
      # Returns a URI.
      #
      protected
      def shares_uri(query={})
        query = { 'comp' => 'list' }.merge(query)
        generate_uri('', query)
      end

      # Protected: Generate the URI for a specific share.
      #
      # ==== Attributes
      #
      # * +name+  - The share name. If this is a URI, we just return this.
      # * +query+ - A Hash of key => value query parameters.
      #
      # Returns a URI.
      #
      protected
      def share_uri(name, query={})
        return name if name.kind_of? ::URI
        query = { 'restype' => 'share' }.merge(query)
        generate_uri(name, query)
      end

      # Protected: Generate the URI for a specific directory.
      #
      # ==== Attributes
      #
      # * +share+                 - String representing the name of the share.
      # * +directory_path+        - String representing the path to the directory.
      # * +directory+             - String representing the name to the directory.
      # * +query+                 - A Hash of key => value query parameters.
      #
      # Returns a URI.
      #
      protected
      def directory_uri(share, directory_path, query={})
        path = directory_path.nil? ? share : ::File.join(share, directory_path)
        query = { 'restype' => 'directory' }.merge(query)
        generate_uri(path, query, true)
      end

      # Protected: Generate the URI for a specific file.
      #
      # ==== Attributes
      #
      # * +share+                 - String representing the name of the share.
      # * +directory_path+        - String representing the path to the directory.
      # * +file+                  - String representing the name to the file.
      # * +query+                 - A Hash of key => value query parameters.
      #
      # Returns a URI.
      #
      protected
      def file_uri(share, directory_path, file, query={})
        if directory_path.nil?
          path = ::File.join(share, file)
        else
          path = ::File.join(share, directory_path, file)
        end
        generate_uri(path, query, true)
      end
    end
  end
end

Azure::Storage::FileService = Azure::Storage::File::FileService