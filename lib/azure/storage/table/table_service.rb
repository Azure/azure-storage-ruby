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
require 'azure/storage/service/storage_service'

require 'azure/storage/table/auth/shared_key'
require 'azure/storage/table/serialization'
require 'azure/storage/table/entity'

module Azure::Storage
  module Table
    class TableService < Service::StorageService

      def initialize(options = {}, &block)
        client_config = options[:client] || Azure::Storage
        signer = options[:signer] || client_config.signer || Auth::SharedKey.new(client_config.storage_account_name, client_config.storage_access_key)
        super(signer, client_config.storage_account_name, options, &block)
        @host = client.storage_table_host
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
      #
      # See http://msdn.microsoft.com/en-us/library/azure/dd135729
      #
      # @return [nil] on success
      def create_table(table_name, options={})
        query = { }
        query['timeout'] = options[:timeout].to_s if options[:timeout]

        body = Table::Serialization.hash_to_entry_xml({"TableName" => table_name}).to_xml
        call(:post, collection_uri(query), body, {}, options)
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
      def delete_table(table_name, options={})
        query = { }
        query["timeout"] = options[:timeout].to_s if options[:timeout]

        call(:delete, table_uri(table_name, query), nil, {}, options)
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
      #
      # Returns the last updated time for the table
      def get_table(table_name, options={})
        query = { }
        query["timeout"] = options[:timeout].to_s if options[:timeout]

        response = call(:get, table_uri(table_name, query), nil, {}, options)
        results = Table::Serialization.hash_from_entry_xml(response.body)
        results[:updated]
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
      #
      # See http://msdn.microsoft.com/en-us/library/azure/dd179405
      #
      # Returns an array with an extra continuation_token property on success
      def query_tables(options={})
        query = { }
        query["NextTableName"] = options[:next_table_token] if options[:next_table_token]
        query["timeout"] = options[:timeout].to_s if options[:timeout]
        uri = collection_uri(query)

        response = call(:get, uri, nil, {}, options)
        entries = Table::Serialization.entries_from_feed_xml(response.body) || []

        values = Azure::Service::EnumerationResults.new(entries)
        values.continuation_token = response.headers["x-ms-continuation-NextTableName"]
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
      #
      # See http://msdn.microsoft.com/en-us/library/azure/jj159100
      #
      # Returns a list of Azure::Storage::Entity::SignedIdentifier instances
      def get_table_acl(table_name, options={})
        query = { 'comp' => 'acl'}
        query['timeout'] = options[:timeout].to_s if options[:timeout]

        response = call(:get, generate_uri(table_name, query), nil, {'x-ms-version' => '2012-02-12'}, options)

        signed_identifiers = []
        signed_identifiers = Table::Serialization.signed_identifiers_from_xml response.body unless response.body == nil or response.body.length < 1
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
      def set_table_acl(table_name, options={})
        query = { 'comp' => 'acl'}
        query['timeout'] = options[:timeout].to_s if options[:timeout]

        uri = generate_uri(table_name, query)
        body = nil
        body = Table::Serialization.signed_identifiers_to_xml options[:signed_identifiers] if options[:signed_identifiers] && options[:signed_identifiers].length > 0

        call(:put, uri, body, {'x-ms-version' => '2012-02-12'}, options)
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
      #
      # See http://msdn.microsoft.com/en-us/library/azure/dd179433
      #
      # Returns a Azure::Storage::Entity::Table::Entity
      def insert_entity(table_name, entity_values, options={})
        body = Table::Serialization.hash_to_entry_xml(entity_values).to_xml

        query = { }
        query['timeout'] = options[:timeout].to_s if options[:timeout]

        response = call(:post, entities_uri(table_name, nil, nil, query), body, {}, options)
        result = Table::Serialization.hash_from_entry_xml(response.body)

        Entity.new do |entity|
          entity.table = table_name
          entity.updated = result[:updated]
          entity.etag = response.headers['etag'] || result[:etag]
          entity.properties = result[:properties]
        end
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
      #
      # See http://msdn.microsoft.com/en-us/library/azure/dd179421
      #
      # Returns an array with an extra continuation_token property on success
      def query_entities(table_name, options={})
        query ={}
        query["$select"] = options[:select].join ',' if options[:select]
        query["$filter"] = options[:filter] if options[:filter]
        query["$top"] = options[:top].to_s if options[:top] unless options[:partition_key] and options[:row_key]
        query["NextPartitionKey"] = options[:continuation_token][:next_partition_key] if options[:continuation_token] and options[:continuation_token][:next_partition_key]
        query["NextRowKey"] = options[:continuation_token][:next_row_key] if options[:continuation_token] and options[:continuation_token][:next_row_key]
        query["timeout"] = options[:timeout].to_s if options[:timeout]

        uri = entities_uri(table_name, options[:partition_key], options[:row_key], query)
        response = call(:get, uri, nil, {"DataServiceVersion" => "2.0;NetFx"}, options)

        entities = Azure::Service::EnumerationResults.new

        results = (options[:partition_key] and options[:row_key]) ? [Table::Serialization.hash_from_entry_xml(response.body)] : Table::Serialization.entries_from_feed_xml(response.body)
        
        results.each do |result|
          entity = Entity.new do |e|
            e.table = table_name
            e.updated = result[:updated]
            e.etag = response.headers["etag"] || result[:etag]
            e.properties = result[:properties]
          end
          entities.push entity
        end if results

        entities.continuation_token = nil
        entities.continuation_token = { 
          :next_partition_key=> response.headers["x-ms-continuation-NextPartitionKey"], 
          :next_row_key => response.headers["x-ms-continuation-NextRowKey"]
          } if response.headers["x-ms-continuation-NextPartitionKey"]

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
      def update_entity(table_name, entity_values, options={})
        if_match = "*"
        if_match = options[:if_match] if options[:if_match]

        query = { }
        query["timeout"] = options[:timeout].to_s if options[:timeout]

        uri = entities_uri(table_name, 
          entity_values[:PartitionKey] || entity_values['PartitionKey'],
          entity_values[:RowKey] || entity_values["RowKey"], query)

        headers = {}
        headers["If-Match"] = if_match || "*" unless options[:create_if_not_exists]

        body = Table::Serialization.hash_to_entry_xml(entity_values).to_xml

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
      def merge_entity(table_name, entity_values, options={})
        if_match = "*"
        if_match = options[:if_match] if options[:if_match]

        query = { }
        query["timeout"] = options[:timeout].to_s if options[:timeout]

        uri = entities_uri(table_name, 
          entity_values[:PartitionKey] || entity_values['PartitionKey'],
          entity_values[:RowKey] || entity_values['RowKey'], query)

        headers = { "X-HTTP-Method"=> "MERGE" }
        headers["If-Match"] = if_match || "*" unless options[:create_if_not_exists]

        body = Table::Serialization.hash_to_entry_xml(entity_values).to_xml

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
      def insert_or_merge_entity(table_name, entity_values, options={})
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
      def insert_or_replace_entity(table_name, entity_values, options={})
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
      def delete_entity(table_name, partition_key, row_key, options={})
        if_match = "*"
        if_match = options[:if_match] if options[:if_match]

        query = { }
        query["timeout"] = options[:timeout].to_s if options[:timeout]
        call(:delete, entities_uri(table_name, partition_key, row_key, query), nil, { "If-Match"=> if_match }, options)
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
      #
      # See http://msdn.microsoft.com/en-us/library/azure/dd894038
      #
      # Returns an array of results, one for each operation in the batch
      def execute_batch(batch, options={})
        headers = {
          'Content-Type' => "multipart/mixed; boundary=#{batch.batch_id}",
          'Accept' => 'application/atom+xml,application/xml',
          'Accept-Charset'=> 'UTF-8'
        }

        query = { }
        query["timeout"] = options[:timeout].to_s if options[:timeout]

        body = batch.to_body
        response = call(:post, generate_uri('/$batch', query), body, headers, options)
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
      #
      # Returns an Azure::Storage::Table::Entity instance on success
      def get_entity(table_name, partition_key, row_key, options={})
        options[:partition_key] = partition_key
        options[:row_key] = row_key
        results = query_entities(table_name, options)
        results.length > 0 ? results[0] : nil
      end

      # Protected: Generate the URI for the collection of tables.
      #
      # Returns a URI
      protected
      def collection_uri(query={})
        generate_uri("Tables", query)
      end

      # Public: Generate the URI for a specific table.
      #
      # ==== Attributes
      #
      # * +name+ - The table name. If this is a URI, we just return this
      #
      # Returns a URI
      public
      def table_uri(name, query={})
        return name if name.kind_of? ::URI
        generate_uri("Tables('#{name}')", query)
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
      def entities_uri(table_name, partition_key=nil, row_key=nil, query={})
        return table_name if table_name.kind_of? ::URI

        path = if partition_key && row_key
               "%s(PartitionKey='%s',RowKey='%s')" % [
                 table_name.encode("UTF-8"), encodeODataUriValue(partition_key.encode("UTF-8")), encodeODataUriValue(row_key.encode("UTF-8"))
               ]
               else
                 "%s()" % table_name.encode("UTF-8")
               end

        uri = generate_uri(path)
        qs = []
        if query
          query.each do | key, val |
            key = key.encode("UTF-8")
            val = val.encode("UTF-8")

            if key[0] == "$"
              qs.push "#{key}#{::URI.encode_www_form(""=>val)}"
            else
              qs.push ::URI.encode_www_form(key=>val)
            end
          end
        end
        uri.query = qs.join '&' if qs.length > 0
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
    end
  end
end

Azure::Storage::TableService = Azure::Storage::Table::TableService
