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
require 'azure/storage/blob/serialization'

module Azure::Storage::Blob
  module Container
    include Azure::Storage::Service
    
    class Container
      def initialize
        @properties = {}
        @metadata = {}
        yield self if block_given?
      end

      attr_accessor :name
      attr_accessor :properties
      attr_accessor :metadata
      attr_accessor :public_access_level
    end
    
    # Public: Create a new container
    #
    # ==== Attributes
    #
    # * +name+                      - String. The name of the container.
    # * +options+                   - Hash. Optional parameters.
    #
    # ==== Options
    #
    # Accepted key/value pairs in options parameter are:
    # * +:metadata+                 - Hash. User defined metadata for the container (optional).
    # * +:public_access_level+      - String. One of "container" or "blob" (optional).
    # * +:timeout+                  - Integer. A timeout in seconds.
    # * +:request_id+               - String. Provides a client-generated, opaque value with a 1 KB character limit that is recorded 
    #                                 in the analytics logs when storage analytics logging is enabled.
    #
    # See http://msdn.microsoft.com/en-us/library/azure/dd179468.aspx
    #
    # Returns a Container
    def create_container(name, options={})
      # Query
      query = { }
      query['timeout'] = options[:timeout].to_s if options[:timeout]

      # Scheme + path
      uri = container_uri(name, query)

      # Headers
      headers = StorageService.common_headers
      StorageService.add_metadata_to_headers(options[:metadata], headers) if options[:metadata]
      headers['x-ms-blob-public-access'] = options[:public_access_level].to_s if options[:public_access_level]

      # Call
      response = call(:put, uri, nil, headers, options)

      # result
      container = Serialization.container_from_headers(response.headers)
      container.name = name
      container.metadata = options[:metadata]
      container
    end
              
    # Public: Returns all properties and metadata on the container.
    #
    # ==== Attributes
    #
    # * +name+                      - String. The name of the container
    # * +options+                   - Hash. Optional parameters.
    #
    # ==== Options
    #
    # Accepted key/value pairs in options parameter are:
    # * +:timeout+                  - Integer. A timeout in seconds.
    # * +:request_id+               - String. Provides a client-generated, opaque value with a 1 KB character limit that is recorded 
    #                                 in the analytics logs when storage analytics logging is enabled.
    #
    # See http://msdn.microsoft.com/en-us/library/azure/dd179370.aspx
    #
    # Returns a Container
    def get_container_properties(name, options={})
      # Query
      query = { }
      query['timeout'] = options[:timeout].to_s if options[:timeout]

      # Call
      response = call(:get, container_uri(name, query), nil, {}, options)

      # result
      container = Serialization.container_from_headers(response.headers)
      container.name = name
      container
    end
    
    # Public: Returns only user-defined metadata for the specified container.
    #
    # ==== Attributes
    #
    # * +name+                      - String. The name of the container
    # * +options+                   - Hash. Optional parameters.
    #
    # ==== Options
    #
    # Accepted key/value pairs in options parameter are:
    # * +:timeout+                  - Integer. A timeout in seconds.
    # * +:request_id+               - String. Provides a client-generated, opaque value with a 1 KB character limit that is recorded 
    #                                 in the analytics logs when storage analytics logging is enabled.
    #
    # See http://msdn.microsoft.com/en-us/library/azure/ee691976.aspx
    #
    # Returns a Container
    def get_container_metadata(name, options={})
      # Query
      query = { 'comp' => 'metadata' }
      query['timeout'] = options[:timeout].to_s if options[:timeout]

      # Call
      response = call(:get, container_uri(name, query), nil, {}, options)

      # result
      container = Serialization.container_from_headers(response.headers)
      container.name = name
      container
    end
    
    # Public: Sets custom metadata for the container.
    #
    # ==== Attributes
    #
    # * +name+                      - String. The name of the container
    # * +metadata+                  - Hash. A Hash of the metadata values
    # * +options+                   - Hash. Optional parameters.
    #
    # ==== Options
    #
    # Accepted key/value pairs in options parameter are:
    # * +:timeout+                  - Integer. A timeout in seconds.
    # * +:request_id+               - String. Provides a client-generated, opaque value with a 1 KB character limit that is recorded 
    #                                 in the analytics logs when storage analytics logging is enabled.
    #
    # See http://msdn.microsoft.com/en-us/library/azure/dd179362.aspx
    #
    # Returns nil on success
    def set_container_metadata(name, metadata, options={})
      # Query
      query = { 'comp' => 'metadata' }
      query['timeout'] = options[:timeout].to_s if options[:timeout]

      # Headers
      headers = StorageService.common_headers
      StorageService.add_metadata_to_headers(metadata, headers) if metadata

      # Call
      call(:put, container_uri(name, query), nil, headers, options)
      
      # Result
      nil
    end
    
    # Public: Gets the access control list (ACL) and any container-level access policies
    # for the container.
    #
    # ==== Attributes
    #
    # * +name+                      - String. The name of the container
    # * +options+                   - Hash. Optional parameters.
    #
    # ==== Options
    #
    # Accepted key/value pairs in options parameter are:
    # * +:timeout+                  - Integer. A timeout in seconds.
    # * +:request_id+               - String. Provides a client-generated, opaque value with a 1 KB character limit that is recorded 
    #                                 in the analytics logs when storage analytics logging is enabled.
    #
    # See http://msdn.microsoft.com/en-us/library/azure/dd179469.aspx
    #
    # Returns a tuple of (container, signed_identifiers)
    #   container           - A Azure::Storage::Entity::Blob::Container instance
    #   signed_identifiers  - A list of Azure::Storage::Entity::SignedIdentifier instances
    #
    def get_container_acl(name, options={})
      # Query
      query = { 'comp' => 'acl' }
      query['timeout'] = options[:timeout].to_s if options[:timeout]
      
      # Call
      response = call(:get, container_uri(name, query), nil, {}, options)

      # Result
      container = Serialization.container_from_headers(response.headers)
      container.name = name

      signed_identifiers = nil
      signed_identifiers = Serialization.signed_identifiers_from_xml(response.body) if response.body != nil && response.body.length > 0

      return container, signed_identifiers
    end

    # Public: Sets the ACL and any container-level access policies for the container.
    #
    # ==== Attributes
    #
    # * +name+                         - String. The name of the container
    # * +public_access_level+          - String. The container public access level
    # * +options+                      - Hash. Optional parameters.
    #
    # ==== Options
    #
    # Accepted key/value pairs in options parameter are:
    # * +:signed_identifiers+          - Array. A list of Azure::Storage::Entity::SignedIdentifier instances (optional)
    # * +:timeout+                     - Integer. A timeout in seconds.
    # * +:request_id+                  - String. Provides a client-generated, opaque value with a 1 KB character limit that is recorded 
    #                                    in the analytics logs when storage analytics logging is enabled.
    # 
    # See http://msdn.microsoft.com/en-us/library/azure/dd179391.aspx
    #
    # Returns a tuple of (container, signed_identifiers)
    # * +container+                    - A Azure::Storage::Entity::Blob::Container instance
    # * +signed_identifiers+           - A list of Azure::Storage::Entity::SignedIdentifier instances
    #
    def set_container_acl(name, public_access_level, options={})
      # Query
      query = { 'comp' => 'acl' }
      query['timeout'] = options[:timeout].to_s if options[:timeout]

      # Scheme + path
      uri = container_uri(name, query)

      # Headers + body
      headers = StorageService.common_headers
      headers['x-ms-blob-public-access'] = public_access_level if public_access_level && public_access_level.to_s.length > 0

      signed_identifiers = nil
      signed_identifiers = options[:signed_identifiers] if options[:signed_identifiers]

      body = nil
      body = Serialization.signed_identifiers_to_xml(signed_identifiers) if signed_identifiers

      # Call
      response = call(:put, uri, body, headers, options)

      # Result
      container = Serialization.container_from_headers(response.headers)
      container.name = name
      container.public_access_level = public_access_level

      return container, signed_identifiers || []
    end
    
    # Public: Deletes a container.
    #
    # ==== Attributes
    #
    # * +name+                      - String. The name of the container.
    # * +options+                   - Hash. Optional parameters.
    #
    # ==== Options
    #
    # Accepted key/value pairs in options parameter are:
    # * +:timeout+                  - Integer. A timeout in seconds.
    # * +:request_id+               - String. Provides a client-generated, opaque value with a 1 KB character limit that is recorded 
    #                                 in the analytics logs when storage analytics logging is enabled.
    #
    # See http://msdn.microsoft.com/en-us/library/azure/dd179408.aspx
    #
    # Returns nil on success
    def delete_container(name, options={})
      # Query
      query = { }
      query['timeout'] = options[:timeout].to_s if options[:timeout]

      # Call
      call(:delete, container_uri(name, query), nil, {}, options)
      
      # result
      nil
    end
    
    # Public: Establishes an exclusive write lock on a container. The lock duration can be 15 to 60 seconds, or can be infinite.
    # To write to a locked container, a client must provide a lease ID.
    #
    # ==== Attributes
    #
    # * +container+                  - String. The container name.
    # * +options+                    - Hash. Optional parameters.
    #
    # ==== Options
    #
    # Accepted key/value pairs in options parameter are:
    # * +:duration+                  - Integer. Default -1. Specifies the duration of the lease, in seconds, or negative one (-1)
    #                                  for a lease that never expires. A non-infinite lease can be between 15 and 60 seconds. (optional)
    # * +:proposed_lease_id+         - String. Proposed lease ID, in a GUID string format. The Blob service returns 400 (Invalid request)
    #                                  if the proposed lease ID is not in the correct format. (optional)
    # * +:timeout+                   - Integer. A timeout in seconds.
    # * +:request_id+                - String. Provides a client-generated, opaque value with a 1 KB character limit that is recorded 
    #                                  in the analytics logs when storage analytics logging is enabled.
    # * +:if_modified_since+         - String. A DateTime value. Specify this conditional header to acquire the lease
    #                                  only if the container has been modified since the specified date/time. If the container has not been modified, 
    #                                  the Blob service returns status code 412 (Precondition Failed).
    # * +:if_unmodified_since+       - String. A DateTime value. Specify this conditional header to acquire the lease
    #                                  only if the container has not been modified since the specified date/time. If the container has been modified, 
    #                                  the Blob service returns status code 412 (Precondition Failed).
    # * +:if_match+                  - String. An ETag value. Specify an ETag value for this conditional header to acquire the lease
    #                                  only if the container's ETag value matches the value specified. If the values do not match, 
    #                                  the Blob service returns status code 412 (Precondition Failed).
    # * +:if_none_match+             - String. An ETag value. Specify an ETag value for this conditional header to acquire the lease
    #                                  only if the container's ETag value does not match the value specified. If the values are identical, 
    #                                  the Blob service returns status code 412 (Precondition Failed).
    #
    # See http://msdn.microsoft.com/en-us/library/azure/ee691972.aspx
    #
    # Returns a String of the new unique lease id. While the lease is active, you must include the lease ID with any request
    # to write, or to renew, change, or release the lease.
    #
    def acquire_container_lease(container, options={})
      acquire_lease container, nil, options
    end

    # Public: Renews the lease. The lease can be renewed if the lease ID specified on the request matches that
    # associated with the container. Note that the lease may be renewed even if it has expired as long as the container
    # has not been modified or leased again since the expiration of that lease. When you renew a lease, the
    # lease duration clock resets.
    #
    # ==== Attributes
    #
    # * +container+                  - String. The container name.
    # * +lease+                      - String. The lease id
    # * +options+                    - Hash. Optional parameters.
    #
    # ==== Options
    #
    # Accepted key/value pairs in options parameter are:
    # * +:timeout+                   - Integer. A timeout in seconds.
    # * +:request_id+                - String. Provides a client-generated, opaque value with a 1 KB character limit that is recorded 
    #                                  in the analytics logs when storage analytics logging is enabled.
    # * +:if_modified_since+         - String. A DateTime value. Specify this conditional header to renew the lease
    #                                  only if the container has been modified since the specified date/time. If the container has not been modified, 
    #                                  the Blob service returns status code 412 (Precondition Failed).
    # * +:if_unmodified_since+       - String. A DateTime value. Specify this conditional header to renew the lease
    #                                  only if the container has not been modified since the specified date/time. If the container has been modified, 
    #                                  the Blob service returns status code 412 (Precondition Failed).
    # * +:if_match+                  - String. An ETag value. Specify an ETag value for this conditional header to renew the lease
    #                                  only if the container's ETag value matches the value specified. If the values do not match, 
    #                                  the Blob service returns status code 412 (Precondition Failed).
    # * +:if_none_match+             - String. An ETag value. Specify an ETag value for this conditional header to renew the lease
    #                                  only if the container's ETag value does not match the value specified. If the values are identical, 
    #                                  the Blob service returns status code 412 (Precondition Failed).
    # See http://msdn.microsoft.com/en-us/library/azure/ee691972.aspx
    #
    # Returns the renewed lease id
    def renew_container_lease(container, lease, options={})
      renew_lease container, nil, lease, options
    end
    
    # Public: Change the lease ID.
    #
    # ==== Attributes
    #
    # * +container+                  - String. The container name.
    # * +lease+                      - String. The existing lease id.
    # * +proposed_lease+             - String. Proposed lease ID, in a GUID string format. The Blob service returns 400 (Invalid request)
    #                                  if the proposed lease ID is not in the correct format. (optional).
    # * +options+                    - Hash. Optional parameters.
    #
    # ==== Options
    #
    # Accepted key/value pairs in options parameter are:
    # * +:timeout+                   - Integer. A timeout in seconds.
    # * +:request_id+                - String. Provides a client-generated, opaque value with a 1 KB character limit that is recorded 
    #                                  in the analytics logs when storage analytics logging is enabled.
    # * +:if_modified_since+         - String. A DateTime value. Specify this conditional header to change the lease
    #                                  only if the container has been modified since the specified date/time. If the container has not been modified, 
    #                                  the Blob service returns status code 412 (Precondition Failed).
    # * +:if_unmodified_since+       - String. A DateTime value. Specify this conditional header to change the lease
    #                                  only if the container has not been modified since the specified date/time. If the container has been modified, 
    #                                  the Blob service returns status code 412 (Precondition Failed).
    # * +:if_match+                  - String. An ETag value. Specify an ETag value for this conditional header to change the lease
    #                                  only if the container's ETag value matches the value specified. If the values do not match, 
    #                                  the Blob service returns status code 412 (Precondition Failed).
    # * +:if_none_match+             - String. An ETag value. Specify an ETag value for this conditional header to change the lease
    #                                  only if the container's ETag value does not match the value specified. If the values are identical, 
    #                                  the Blob service returns status code 412 (Precondition Failed).
    # See http://msdn.microsoft.com/en-us/library/azure/ee691972.aspx
    #
    # Returns the changed lease id
    def change_container_lease(container, lease, proposed_lease, options={})
      change_lease container, nil, lease, proposed_lease, options
    end

    # Public: Releases the lease. The lease may be released if the lease ID specified on the request matches that
    # associated with the container. Releasing the lease allows another client to immediately acquire the lease for
    # the container as soon as the release is complete.
    #
    # ==== Attributes
    #
    # * +container+                  - String. The container name.
    # * +lease+                      - String. The lease id.
    # * +options+                    - Hash. Optional parameters.
    #
    # ==== Options
    #
    # Accepted key/value pairs in options parameter are:
    # * +:timeout+                   - Integer. A timeout in seconds.
    # * +:request_id+                - String. Provides a client-generated, opaque value with a 1 KB character limit that is recorded 
    #                                  in the analytics logs when storage analytics logging is enabled.
    # * +:if_modified_since+         - String. A DateTime value. Specify this conditional header to release the lease
    #                                  only if the container has been modified since the specified date/time. If the container has not been modified, 
    #                                  the Blob service returns status code 412 (Precondition Failed).
    # * +:if_unmodified_since+       - String. A DateTime value. Specify this conditional header to release the lease
    #                                  only if the container has not been modified since the specified date/time. If the container has been modified, 
    #                                  the Blob service returns status code 412 (Precondition Failed).
    # * +:if_match+                  - String. An ETag value. Specify an ETag value for this conditional header to release the lease
    #                                  only if the container's ETag value matches the value specified. If the values do not match, 
    #                                  the Blob service returns status code 412 (Precondition Failed).
    # * +:if_none_match+             - String. An ETag value. Specify an ETag value for this conditional header to release the lease
    #                                  only if the container's ETag value does not match the value specified. If the values are identical, 
    #                                  the Blob service returns status code 412 (Precondition Failed).
    # See http://msdn.microsoft.com/en-us/library/azure/ee691972.aspx
    #
    # Returns nil on success
    def release_container_lease(container, lease, options={})
      release_lease container, nil, lease, options
    end

    # Public: Breaks the lease, if the container has an active lease. Once a lease is broken, it cannot be renewed. Any
    # authorized request can break the lease; the request is not required to specify a matching lease ID. When a
    # lease is broken, the lease break period is allowed to elapse, during which time no lease operation except
    # break and release can be performed on the container. When a lease is successfully broken, the response indicates
    # the interval in seconds until a new lease can be acquired.
    #
    # A lease that has been broken can also be released, in which case another client may immediately acquire the
    # lease on the container.
    #
    # ==== Attributes
    #
    # * +container+                  - String. The container name.
    # * +options+                    - Hash. Optional parameters.
    #
    # ==== Options
    #
    # Accepted key/value pairs in options parameter are:
    # * +:break_period+              - Integer. The proposed duration of seconds that the lease should continue before it is
    #                                  broken, between 0 and 60 seconds. This break period is only used if it is shorter than
    #                                  the time remaining on the lease. If longer, the time remaining on the lease is used. A
    #                                  new lease will not be available before the break period has expired, but the lease may
    #                                  be held for longer than the break period.
    #
    #                                  If this option is not used, a fixed-duration lease breaks after the remaining lease
    #                                  period elapses, and an infinite lease breaks immediately.
    # * +:timeout+                   - Integer. A timeout in seconds.
    # * +:request_id+                - String. Provides a client-generated, opaque value with a 1 KB character limit that is recorded 
    #                                  in the analytics logs when storage analytics logging is enabled.
    # * +:if_modified_since+         - String. A DateTime value. Specify this conditional header to break the lease
    #                                  only if the container has been modified since the specified date/time. If the container has not been modified, 
    #                                  the Blob service returns status code 412 (Precondition Failed).
    # * +:if_unmodified_since+       - String. A DateTime value. Specify this conditional header to break the lease
    #                                  only if the container has not been modified since the specified date/time. If the container has been modified, 
    #                                  the Blob service returns status code 412 (Precondition Failed).
    # * +:if_match+                  - String. An ETag value. Specify an ETag value for this conditional header to break the lease
    #                                  only if the container's ETag value matches the value specified. If the values do not match, 
    #                                  the Blob service returns status code 412 (Precondition Failed).
    # * +:if_none_match+             - String. An ETag value. Specify an ETag value for this conditional header to break the lease
    #                                  only if the container's ETag value does not match the value specified. If the values are identical, 
    #                                  the Blob service returns status code 412 (Precondition Failed).
    # See http://msdn.microsoft.com/en-us/library/azure/ee691972.aspx
    #
    # Returns an Integer of the remaining lease time. This value is the approximate time remaining in the lease
    # period, in seconds. This header is returned only for a successful request to break the lease. If the break
    # is immediate, 0 is returned.
    def break_container_lease(container, options={})
      break_lease container, nil, options
    end
    
    # Public: Get a list of Blobs from the server
    #
    # ==== Attributes
    #
    # * +name+              - String. The name of the container to list blobs for.
    # * +options+           - Hash. Optional parameters.
    #
    # ==== Options
    #
    # Accepted key/value pairs in options parameter are:
    # * +:prefix+           - String. Filters the results to return only blobs
    #                         whose name begins with the specified prefix. (optional)
    # * +:delimiter+        - String. When the request includes this parameter, the operation
    #                         returns a BlobPrefix element in the response body that acts as a
    #                         placeholder for all blobs whose names begin with the same substring
    #                         up to the appearance of the delimiter character. The delimiter may
    #                         be a single character or a string.
    # * +:marker+           - String. An identifier that specifies the portion of the
    #                         list to be returned. This value comes from the property
    #                         Azure::Service::EnumerationResults.continuation_token when
    #                         there are more blobs available than were returned. The
    #                         marker value may then be used here to request the next set
    #                         of list items. (optional)
    # * +:max_results+      - Integer. Specifies the maximum number of blobs to return.
    #                         If max_results is not specified, or is a value greater than
    #                         5,000, the server will return up to 5,000 items. If it is set
    #                         to a value less than or equal to zero, the server will return
    #                         status code 400 (Bad Request). (optional)
    # * +:metadata+         - Boolean. Specifies whether or not to return the blob metadata.
    #                         (optional, Default=false)
    # * +:snapshots+        - Boolean. Specifies that snapshots should be included in the
    #                         enumeration. Snapshots are listed from oldest to newest in the
    #                         response. (optional, Default=false)
    # * +:uncomittedblobs+  - Boolean. Specifies that blobs for which blocks have been uploaded,
    #                         but which have not been committed using put_block_list, be included
    #                         in the response. (optional, Default=false)
    # * +:copy+             - Boolean. Specifies that metadata related to any current or previous
    #                         copy_blob operation should be included in the response.
    #                         (optional, Default=false)
    # * +:timeout+          - Integer. A timeout in seconds.
    # * +:request_id+       - String. Provides a client-generated, opaque value with a 1 KB character limit that is recorded 
    #                         in the analytics logs when storage analytics logging is enabled.
    #
    # NOTE: Metadata requested with the :metadata parameter must have been stored in
    # accordance with the naming restrictions imposed by the 2009-09-19 version of the Blob
    # service. Beginning with that version, all metadata names must adhere to the naming
    # conventions for C# identifiers.
    #
    # See: http://msdn.microsoft.com/en-us/library/azure/dd135734.aspx
    #
    # Any metadata with invalid names which were previously stored, will be returned with the
    # key "x-ms-invalid-name" in the metadata hash. This may contain multiple values and be an
    # Array (vs a String if it only contains a single value).
    #
    # Returns an Azure::Service::EnumerationResults
    def list_blobs(name, options={})
      # Query
      query = { 'comp' => 'list' }
      query['prefix'] = options[:prefix].gsub(/\\/, '/') if options[:prefix]
      query['delimiter'] = options[:delimiter] if options[:delimiter]
      query['marker'] = options[:marker] if options[:marker]
      query['maxresults'] = options[:max_results].to_s if options[:max_results]
      query['timeout'] = options[:timeout].to_s if options[:timeout]

      included_datasets = []
      included_datasets.push('metadata') if options[:metadata] == true
      included_datasets.push('snapshots') if options[:snapshots] == true
      included_datasets.push('uncommittedblobs') if options[:uncommittedblobs] == true
      included_datasets.push('copy') if options[:copy] == true

      query['include'] = included_datasets.join ',' if included_datasets.length > 0

      # Scheme + path
      uri = container_uri(name, query)
      
      # Call
      response = call(:get, uri, nil, {}, options)
      
      # Result
      if response.success?
        Serialization.blob_enumeration_results_from_xml(response.body)
      else
        response.exception
      end
    end

  end
end