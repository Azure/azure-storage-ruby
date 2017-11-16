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
require "azure/storage/service/storage_service"

require "azure/storage/table/auth/shared_key"
require "azure/storage/table/serialization"
require "azure/storage/table/entity"

module Azure::Storage
  module Table
    class TableService < Service::StorageService
      def initialize(options = {}, &block)
        client_config = options[:client] || Azure::Storage
        signer = options[:signer] || client_config.signer || Auth::SharedKey.new(client_config.storage_account_name, client_config.storage_access_key)
        super(signer, client_config.storage_account_name, options, &block)
        @storage_service_host[:primary] = client.storage_table_host
        @storage_service_host[:secondary] = client.storage_table_host true
      end

      # Public: Creates new table in the storage account
      #
      # ==== Attributes
      #
      # * +table_name+               - String. The table name
      # * +options+                  - Hash. Optional parameters.
      #
      # ==== Options
      #
      # Accepted key/value pairs in options parameter are:
      #
      # * +:timeout+                 - Integer. A timeout in seconds.
      # * +:request_id+              - String. Provides a client-generated, opaque value with a 1 KB character limit that is recorded
      #                                in the analytics logs when storage analytics logging is enabled.
      # * +:accept+                  - String. Specifies the accepted content-type of the response payload. Possible values are:
      #                                 :no_meta
      #                                 :min_meta
      #                                 :full_meta
      # * +:prefer+                  - String. Specifies whether the response should include the inserted entity in the payload. Possible values are:
      #                                 HeaderConstants::PREFER_CONTENT
      #                                 HeaderConstants::PREFER_NO_CONTENT
      #
      # See http://msdn.microsoft.com/en-us/library/azure/dd135729
      #
      # @return [nil] on success
      def create_table(table_name, options = {})
        headers = {
          HeaderConstants::ACCEPT => Table::Serialization.get_accept_string(options[:accept]),
        }
        headers[HeaderConstants::PREFER] = options[:prefer] unless options[:prefer].nil?
        body = Serialization.hash_to_json("TableName" => table_name)

        call(:post, collection_uri(new_query(options)), body, headers, options)
        nil
      end

      # Public: Deletes the specified table and any data it contains.
      #
      # ==== Attributes
      #
      # * +table_name+               - String. The table name
      # * +options+                  - Hash. Optional parameters.
      #
      # ==== Options
      #
      # Accepted key/value pairs in options parameter are:
      # * +:timeout+                 - Integer. A timeout in seconds.
      # * +:request_id+              - String. Provides a client-generated, opaque value with a 1 KB character limit that is recorded
      #                                in the analytics logs when storage analytics logging is enabled.
      #
      # See http://msdn.microsoft.com/en-us/library/azure/dd179387
      #
      # Returns nil on success
      def delete_table(table_name, options = {})
        call(:delete, table_uri(table_name, new_query(options)), nil, {}, options)
        nil
      end

      # Public: Gets the table.
      #
      # ==== Attributes
      #
      # * +table_name+               - String. The table name
      # * +options+                  - Hash. Optional parameters.
      #
      # ==== Options
      #
      # Accepted key/value pairs in options parameter are:
      # * +:timeout+                 - Integer. A timeout in seconds.
      # * +:request_id+              - String. Provides a client-generated, opaque value with a 1 KB character limit that is recorded
      #                                in the analytics logs when storage analytics logging is enabled.
      # * +:location_mode+           - LocationMode. Specifies the location mode used to decide 
      #                                which location the request should be sent to.
      #
      # Returns the last updated time for the table
      def get_table(table_name, options = {})
        headers = {
          HeaderConstants::ACCEPT => Table::Serialization.get_accept_string(:full_meta),
        }
        options[:request_location_mode] = RequestLocationMode::PRIMARY_OR_SECONDARY
        response = call(:get, table_uri(table_name, new_query(options), options), nil, headers, options)
        Table::Serialization.table_entries_from_json(response.body)
      rescue => e
        raise_with_response(e, response)
      end

      # Public: Gets a list of all tables on the account.
      #
      # ==== Attributes
      #
      # * +options+                  - Hash. Optional parameters.
      #
      # ==== Options
      #
      # Accepted key/value pairs in options parameter are:
      # * +:next_table_token+        - String. A token used to enumerate the next page of results, when the list of tables is
      #                                larger than a single operation can return at once. (optional)
      # * +:timeout+                 - Integer. A timeout in seconds.
      # * +:request_id+              - String. Provides a client-generated, opaque value with a 1 KB character limit that is recorded
      #                                in the analytics logs when storage analytics logging is enabled.
      # * +:location_mode+           - LocationMode. Specifies the location mode used to decide 
      #                                which location the request should be sent to.
      # * +:accept+                  - String. Specifies the accepted content-type of the response payload. Possible values are:
      #                                 :no_meta
      #                                 :min_meta
      #                                 :full_meta
      #
      # See http://msdn.microsoft.com/en-us/library/azure/dd179405
      #
      # Returns an array with an extra continuation_token property on success
      def query_tables(options = {})
        query = new_query(options)
        query[TableConstants::NEXT_TABLE_NAME] = options[:next_table_token] if options[:next_table_token]

        options[:request_location_mode] = RequestLocationMode::PRIMARY_OR_SECONDARY
        uri = collection_uri(query, options)

        headers = {
          HeaderConstants::ACCEPT => Table::Serialization.get_accept_string(options[:accept]),
        }

        response = call(:get, uri, nil, headers, options)
        entries = Table::Serialization.table_entries_from_json(response.body) || []
        values = Azure::Service::EnumerationResults.new(entries)
        values.continuation_token = response.headers[TableConstants::CONTINUATION_NEXT_TABLE_NAME]
        values
      rescue => e
        raise_with_response(e, response)
      end

      # Public: Gets the access control list (ACL) for the table.
      #
      # ==== Attributes
      #
      # * +table_name+               - String. The table name
      # * +options+                  - Hash. Optional parameters.
      #
      # ==== Options
      #
      # Accepted key/value pairs in options parameter are:
      # * +:timeout+                 - Integer. A timeout in seconds.
      # * +:request_id+              - String. Provides a client-generated, opaque value with a 1 KB character limit that is recorded
      #                                in the analytics logs when storage analytics logging is enabled.
      # * +:location_mode+           - LocationMode. Specifies the location mode used to decide 
      #                                which location the request should be sent to.
      #
      # See http://msdn.microsoft.com/en-us/library/azure/jj159100
      #
      # Returns a list of Azure::Storage::Entity::SignedIdentifier instances
      def get_table_acl(table_name, options = {})
        query = new_query(options)
        query[QueryStringConstants::COMP] = QueryStringConstants::ACL

        options[:request_location_mode] = RequestLocationMode::PRIMARY_OR_SECONDARY
        response = call(:get, generate_uri(table_name, query, options), nil, { "x-ms-version" => "2012-02-12" }, options)

        signed_identifiers = []
        signed_identifiers = Table::Serialization.signed_identifiers_from_xml response.body unless response.body == nil || response.body.length < 1
        signed_identifiers
      rescue => e
        raise_with_response(e, response)
      end

      # Public: Sets the access control list (ACL) for the table.
      #
      # ==== Attributes
      #
      # * +table_name+               - String. The table name
      # * +options+                  - Hash. Optional parameters.
      #
      # ==== Options
      #
      # Accepted key/value pairs in options parameter are:
      # * +:signed_identifiers+      - Array. A list of Azure::Storage::Entity::SignedIdentifier instances
      # * +:timeout+                 - Integer. A timeout in seconds.
      # * +:request_id+              - String. Provides a client-generated, opaque value with a 1 KB character limit that is recorded
      #                                in the analytics logs when storage analytics logging is enabled.
      #
      # See http://msdn.microsoft.com/en-us/library/azure/jj159102
      #
      # Returns nil on success
      def set_table_acl(table_name, options = {})
        query = new_query(options)
        query[QueryStringConstants::COMP] = QueryStringConstants::ACL

        uri = generate_uri(table_name, query)
        body = nil
        body = Table::Serialization.signed_identifiers_to_xml options[:signed_identifiers] if options[:signed_identifiers] && options[:signed_identifiers].length > 0

        call(:put, uri, body, { "x-ms-version" => "2012-02-12" }, options)
        nil
      end

      # Public: Inserts new entity to the table.
      #
      #
      # ==== Attributes
      #
      # * +table_name+               - String. The table name
      # * +entity_values+            - Hash. A hash of the name/value pairs for the entity.
      # * +options+                  - Hash. Optional parameters.
      #
      # ==== Options
      #
      # Accepted key/value pairs in options parameter are:
      # * +:timeout+                 - Integer. A timeout in seconds.
      # * +:request_id+              - String. Provides a client-generated, opaque value with a 1 KB character limit that is recorded
      #                                in the analytics logs when storage analytics logging is enabled.
      # * +:accept+                  - String. Specifies the accepted content-type of the response payload. Possible values are:
      #                                 :no_meta
      #                                 :min_meta
      #                                 :full_meta
      #
      # See http://msdn.microsoft.com/en-us/library/azure/dd179433
      #
      # Returns a Azure::Storage::Entity::Table::Entity
      def insert_entity(table_name, entity_values, options = {})
        body = Table::Serialization.hash_to_json(entity_values)
        #time = EdmType::to_edm_time(Time.now)
        headers = {
          HeaderConstants::ACCEPT => Table::Serialization.get_accept_string(options[:accept])
        }
        response = call(:post, entities_uri(table_name, nil, nil, new_query(options)), body, headers, options)
        result = Table::Serialization.entity_from_json(response.body)
        result.etag = response.headers[HeaderConstants::ETAG] if result.etag.nil?
        result
      rescue => e
        raise_with_response(e, response)
      end

      # Public: Queries entities for the given table name
      #
      # ==== Attributes
      #
      # * +table_name+               - String. The table name
      # * +options+                  - Hash. Optional parameters.
      #
      # ==== Options
      #
      # Accepted key/value pairs in options parameter are:
      # * +:partition_key+           - String. The partition key (optional)
      # * +:row_key+                 - String. The row key (optional)
      # * +:select+                  - Array. An array of property names to return (optional)
      # * +:filter+                  - String. A filter expression (optional)
      # * +:top+                     - Integer. A limit for the number of results returned (optional)
      # * +:continuation_token+      - Hash. The continuation token.
      # * +:timeout+                 - Integer. A timeout in seconds.
      # * +:request_id+              - String. Provides a client-generated, opaque value with a 1 KB character limit that is recorded
      #                                in the analytics logs when storage analytics logging is enabled.
      # * +:location_mode+           - LocationMode. Specifies the location mode used to decide 
      #                                which location the request should be sent to.
      # * +:accept+                  - String. Specifies the accepted content-type of the response payload. Possible values are:
      #                                 :no_meta
      #                                 :min_meta
      #                                 :full_meta
      #
      # See http://msdn.microsoft.com/en-us/library/azure/dd179421
      #
      # Returns an array with an extra continuation_token property on success
      def query_entities(table_name, options = {})
        query = new_query(options)
        query[QueryStringConstants::SELECT] = options[:select].join "," if options[:select]
        query[QueryStringConstants::FILTER] = options[:filter] if options[:filter]
        query[QueryStringConstants::TOP] = options[:top].to_s if options[:top] unless options[:partition_key] && options[:row_key]
        query[QueryStringConstants::NEXT_PARTITION_KEY] = options[:continuation_token][:next_partition_key] if options[:continuation_token] && options[:continuation_token][:next_partition_key]
        query[QueryStringConstants::NEXT_ROW_KEY] = options[:continuation_token][:next_row_key] if options[:continuation_token] && options[:continuation_token][:next_row_key]

        options[:request_location_mode] = RequestLocationMode::PRIMARY_OR_SECONDARY
        uri = entities_uri(table_name, options[:partition_key], options[:row_key], query, options)

        headers = {
          HeaderConstants::ACCEPT => Table::Serialization.get_accept_string(options[:accept])
        }

        response = call(:get, uri, nil, headers, options)

        entities = Azure::Service::EnumerationResults.new.push(*Table::Serialization.entities_from_json(response.body))

        entities.continuation_token = nil
        entities.continuation_token = {
          next_partition_key: response.headers[TableConstants::CONTINUATION_NEXT_PARTITION_KEY],
          next_row_key: response.headers[TableConstants::CONTINUATION_NEXT_ROW_KEY]
        } if response.headers[TableConstants::CONTINUATION_NEXT_PARTITION_KEY]

        entities
      rescue => e
        raise_with_response(e, response)
      end

      # Public: Updates an existing entity in a table. The Update Entity operation replaces
      # the entire entity and can be used to remove properties.
      #
      # ==== Attributes
      #
      # * +table_name+               - String. The table name
      # * +entity_values+            - Hash. A hash of the name/value pairs for the entity.
      # * +options+                  - Hash. Optional parameters.
      #
      # ==== Options
      #
      # Accepted key/value pairs in options parameter are:
      # * +:if_match+                - String. A matching condition which is required for update (optional, Default="*")
      # * +:create_if_not_exists+    - Boolean. If true, and partition_key and row_key do not reference and existing entity,
      #                                that entity will be inserted. If false, the operation will fail. (optional, Default=false)
      # * +:timeout+                 - Integer. A timeout in seconds.
      # * +:request_id+              - String. Provides a client-generated, opaque value with a 1 KB character limit that is recorded
      #                                in the analytics logs when storage analytics logging is enabled.
      #
      # See http://msdn.microsoft.com/en-us/library/azure/dd179427
      #
      # Returns the ETag for the entity on success
      def update_entity(table_name, entity_values, options = {})
        if_match = "*"
        if_match = options[:if_match] if options[:if_match]

        uri = entities_uri(table_name,
          entity_values[:PartitionKey] || entity_values["PartitionKey"],
          entity_values[:RowKey] || entity_values["RowKey"], new_query(options))

        headers = {}
        headers["If-Match"] = if_match || "*" unless options[:create_if_not_exists]

        body = Table::Serialization.hash_to_json(entity_values)

        response = call(:put, uri, body, headers, options)
        response.headers["etag"]
      rescue => e
        raise_with_response(e, response)
      end

      # Public: Updates an existing entity by updating the entity's properties. This operation
      # does not replace the existing entity, as the update_entity operation does.
      #
      # ==== Attributes
      #
      # * +table_name+               - String. The table name
      # * +entity_values+            - Hash. A hash of the name/value pairs for the entity.
      # * +options+                  - Hash. Optional parameters.
      #
      # ==== Options
      #
      # Accepted key/value pairs in options parameter are:
      # * +:if_match+                - String. A matching condition which is required for update (optional, Default="*")
      # * +:create_if_not_exists+    - Boolean. If true, and partition_key and row_key do not reference and existing entity,
      #                                that entity will be inserted. If false, the operation will fail. (optional, Default=false)
      # * +:timeout+                 - Integer. A timeout in seconds.
      # * +:request_id+              - String. Provides a client-generated, opaque value with a 1 KB character limit that is recorded
      #                                in the analytics logs when storage analytics logging is enabled.
      #
      # See http://msdn.microsoft.com/en-us/library/azure/dd179392
      #
      # Returns the ETag for the entity on success
      def merge_entity(table_name, entity_values, options = {})
        if_match = "*"
        if_match = options[:if_match] if options[:if_match]

        uri = entities_uri(table_name,
          entity_values[:PartitionKey] || entity_values["PartitionKey"],
          entity_values[:RowKey] || entity_values["RowKey"], new_query(options))

        headers = { "X-HTTP-Method" => "MERGE" }
        headers["If-Match"] = if_match || "*" unless options[:create_if_not_exists]

        body = Table::Serialization.hash_to_json(entity_values)

        response = call(:post, uri, body, headers, options)
        response.headers["etag"]
      rescue => e
        raise_with_response(e, response)
      end

      # Public: Inserts or updates an existing entity within a table by merging new property values into the entity.
      #
      # ==== Attributes
      #
      # * +table_name+               - String. The table name
      # * +entity_values+            - Hash. A hash of the name/value pairs for the entity.
      # * +options+                  - Hash. Optional parameters.
      #
      # ==== Options
      #
      # Accepted key/value pairs in options parameter are:
      # * +:timeout+                 - Integer. A timeout in seconds.
      # * +:request_id+              - String. Provides a client-generated, opaque value with a 1 KB character limit that is recorded
      #                                in the analytics logs when storage analytics logging is enabled.
      #
      # See http://msdn.microsoft.com/en-us/library/azure/hh452241
      #
      # Returns the ETag for the entity on success
      def insert_or_merge_entity(table_name, entity_values, options = {})
        options[:create_if_not_exists] = true
        merge_entity(table_name, entity_values, options)
      end

      # Public: Inserts or updates a new entity into a table.
      #
      # ==== Attributes
      #
      # * +table_name+               - String. The table name
      # * +entity_values+            - Hash. A hash of the name/value pairs for the entity.
      # * +options+                  - Hash. Optional parameters.
      #
      # ==== Options
      #
      # Accepted key/value pairs in options parameter are:
      # * +:timeout+                 - Integer. A timeout in seconds.
      # * +:request_id+              - String. Provides a client-generated, opaque value with a 1 KB character limit that is recorded
      #                                in the analytics logs when storage analytics logging is enabled.
      #
      # See http://msdn.microsoft.com/en-us/library/azure/hh452242
      #
      # Returns the ETag for the entity on success
      def insert_or_replace_entity(table_name, entity_values, options = {})
        options[:create_if_not_exists] = true
        update_entity(table_name, entity_values, options)
      end

      # Public: Deletes an existing entity in the table.
      #
      # ==== Attributes
      #
      # * +table_name+               - String. The table name
      # * +partition_key+            - String. The partition key
      # * +row_key+                  - String. The row key
      # * +options+                  - Hash. Optional parameters.
      #
      # ==== Options
      #
      # Accepted key/value pairs in options parameter are:
      # * +:if_match+                - String. A matching condition which is required for update (optional, Default="*")
      # * +:timeout+                 - Integer. A timeout in seconds.
      # * +:request_id+              - String. Provides a client-generated, opaque value with a 1 KB character limit that is recorded
      #                                in the analytics logs when storage analytics logging is enabled.
      #
      # See http://msdn.microsoft.com/en-us/library/azure/dd135727
      #
      # Returns nil on success
      def delete_entity(table_name, partition_key, row_key, options = {})
        if_match = "*"
        if_match = options[:if_match] if options[:if_match]

        call(:delete, entities_uri(table_name, partition_key, row_key, new_query(options)), nil, { "If-Match" => if_match }, options)
        nil
      end

      # Public: Executes a batch of operations.
      #
      # ==== Attributes
      #
      # * +batch+                    - The Azure::Storage::Table::Batch instance to execute.
      # * +options+                  - Hash. Optional parameters.
      #
      # ==== Options
      #
      # Accepted key/value pairs in options parameter are:
      # * +:timeout+                 - Integer. A timeout in seconds.
      # * +:request_id+              - String. Provides a client-generated, opaque value with a 1 KB character limit that is recorded
      #                                in the analytics logs when storage analytics logging is enabled.
      # * +:location_mode+           - LocationMode. Specifies the location mode used to decide 
      #                                which location the request should be sent to.
      #
      # See http://msdn.microsoft.com/en-us/library/azure/dd894038
      #
      # Returns an array of results, one for each operation in the batch
      def execute_batch(batch, options = {})
        headers = {
          HeaderConstants::CONTENT_TYPE => "multipart/mixed; boundary=#{batch.batch_id}",
          HeaderConstants::ACCEPT => Table::Serialization.get_accept_string(options[:accept]),
          "Accept-Charset" => "UTF-8"
        }

        body = batch.to_body
        options[:request_location_mode] = RequestLocationMode::PRIMARY_OR_SECONDARY
        response = call(:post, generate_uri("/$batch", new_query(options), options), body, headers, options, true)
        batch.parse_response(response)
      rescue => e
        raise_with_response(e, response)
      end

      # Public: Gets an existing entity in the table.
      #
      # ==== Attributes
      #
      # * +table_name+               - String. The table name
      # * +partition_key+            - String. The partition key
      # * +row_key+                  - String. The row key
      # * +options+                  - Hash. Optional parameters.
      #
      # ==== Options
      #
      # Accepted key/value pairs in options parameter are:
      # * +:timeout+                 - Integer. A timeout in seconds.
      # * +:request_id+              - String. Provides a client-generated, opaque value with a 1 KB character limit that is recorded
      #                                in the analytics logs when storage analytics logging is enabled.
      # * +:location_mode+           - LocationMode. Specifies the location mode used to decide 
      #                                which location the request should be sent to.
      #
      # Returns an Azure::Storage::Table::Entity instance on success
      def get_entity(table_name, partition_key, row_key, options = {})
        options[:partition_key] = partition_key
        options[:row_key] = row_key
        results = query_entities(table_name, options)
        results.length > 0 ? results[0] : nil
      end

      # Protected: Generate the URI for the collection of tables.
      #
      # Returns a URI
      protected
        def collection_uri(query = {}, options = {})
          generate_uri("Tables", query, options)
        end

      # Public: Generate the URI for a specific table.
      #
      # ==== Attributes
      #
      # * +name+ - The table name. If this is a URI, we just return this
      #
      # Returns a URI
      public
      def table_uri(name, query = {}, options = {})
        return name if name.kind_of? ::URI
        generate_uri("Tables('#{name}')", query, options)
      end

      # Public: Generate the URI for an entity or group of entities in a table.
      # If both the 'partition_key' and 'row_key' are specified, then the URI
      # will match the entity under those specific keys.
      #
      # ==== Attributes
      #
      # * +table_name+    - The table name
      # * +partition_key+ - The desired partition key (optional)
      # * +row_key+       - The desired row key (optional)
      #
      # Returns a URI
      public
      def entities_uri(table_name, partition_key = nil, row_key = nil, query = {}, options = {})
        return table_name if table_name.kind_of? ::URI

        path = if partition_key && row_key
          "%s(PartitionKey='%s',RowKey='%s')" % [
            table_name.encode("UTF-8"), encodeODataUriValue(partition_key.encode("UTF-8")), encodeODataUriValue(row_key.encode("UTF-8"))
          ]
               else
                 "%s()" % table_name.encode("UTF-8")
               end

        uri = generate_uri(path, query, options)
        qs = []
        if query
          query.each do | key, val |
            key = key.encode("UTF-8")
            val = val.encode("UTF-8")

            if key[0] == "$"
              qs.push "#{key}#{::URI.encode_www_form("" => val)}"
            else
              qs.push ::URI.encode_www_form(key => val)
            end
          end
        end
        uri.query = qs.join "&" if qs.length > 0
        uri
      end

      protected
        def encodeODataUriValues(values)
          new_values = []
          values.each do |value|
            new_values.push encodeODataUriValue(value)
          end
          new_values
        end

      protected
        def encodeODataUriValue(value)
          # Replace each single quote (') with double single quotes ('') not double
          # quotes (")
          value = value.gsub("'", "''")

          # Encode the special URL characters
          value = URI.escape(value)

          value
        end

      protected
        def raise_with_response(e, response)
          raise e if response.nil?
          raise "Response header: #{response.headers.inspect}\nResponse body: #{response.body.inspect}\n#{e.inspect}\n#{e.backtrace.join("\n")}"
        end

      protected
        def call(method, uri, body = nil, headers = {}, options = {}, is_batch = false)
          # Add JSON Content-Type header if is_batch is false because default is Atom.
          headers[HeaderConstants::CONTENT_TYPE] = HeaderConstants::JSON_CONTENT_TYPE_VALUE unless is_batch
          headers[HeaderConstants::DATA_SERVICE_VERSION] = TableConstants::DEFAULT_DATA_SERVICE_VERSION
          super(method, uri, body, headers, options)
        end

      protected
        def new_query(options = {})
          options[:timeout].nil? ? {} : { QueryStringConstants::TIMEOUT => options[:timeout].to_s }
        end
    end
  end
end

Azure::Storage::TableService = Azure::Storage::Table::TableService
