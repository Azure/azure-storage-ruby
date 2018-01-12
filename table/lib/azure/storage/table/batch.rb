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
require "securerandom"
require "azure/core/http/http_error"

module Azure::Storage
  module Table
    # Represents a batch of table operations.
    #
    # Example usage:
    #
    # svc = TableSerice.new
    #
    # batch = Batch.new "table", "partition"
    # batch.insert "row1", {"meta"=>"data"}
    # batch.insert "row2", {"meta"=>"data"}
    #
    # results = svc.execute_batch batch
    #
    class Batch
      def initialize(table, partition, &block)
        @table = table
        @partition = partition
        @operations = []
        @entity_keys = []
        @batch_id = "batch_" + SecureRandom.uuid
        @changeset_id = "changeset_" + SecureRandom.uuid

        self.instance_eval(&block) if block_given?
      end

      private
        attr_reader :table
        attr_reader :partition

        attr_accessor :operations
        attr_accessor :entity_keys
        attr_accessor :changeset_id

      public
      attr_accessor :batch_id

      protected
        class ResponseWrapper
          def initialize(hash)
            @hash = hash
          end

          def uri
            @hash[:uri]
          end

          def status_code
            @hash[:status_code].to_i
          end

          def body
            @hash[:body]
          end
        end

      protected
        def add_operation(method, row_key = nil, body = nil, headers = nil)
          raise Azure::Storage::Common::Core::StorageError.new("Get operation should be the only operation in the batch.") if operations.length > 0 && (method == :get || operations[0][:method] == :get)
          op = {
            method: method,
            row_key: row_key,
            body: body,
            headers: headers.merge(
              Azure::Storage::Common::HeaderConstants::CONTENT_TYPE => Azure::Storage::Common::HeaderConstants::JSON_CONTENT_TYPE_VALUE,
              Azure::Storage::Common::HeaderConstants::DATA_SERVICE_VERSION => TableConstants::DEFAULT_DATA_SERVICE_VERSION
            )
          }
          operations.push op
        end

      protected
        def check_entity_key(key)
          raise ArgumentError, "Only allowed to perform a single operation per entity, and there is already a operation registered in this batch for the key: #{key}." if entity_keys.include? key
          entity_keys.push key
        end

      public
      def parse_response(response)
        responses = BatchResponse.parse response.body, (!operations.empty? && operations[0][:method] == :get)
        new_responses = []

        (0..responses.length - 1).each { |index|
          operation = operations[index]
          response = responses[index]

          if response[:status_code].to_i > 299
            # failed
            error = Azure::Core::Http::HTTPError.new(ResponseWrapper.new(response.merge(uri: operation[:uri])))
            error.description = response[:message] if (error.description || "").strip == ""
            raise error
          else
            # success
            case operation[:method]
            when :post, :get
              # entity from body
              entity = Serialization.entity_from_json(response[:body])

              entity.etag = response[:headers]["etag"] if entity.etag.nil?

              new_responses.push entity
            when :put, :merge
              # etag from headers
              new_responses.push response[:headers]["etag"]
            when :delete
              # true
              new_responses.push nil
            end
          end
        }

        new_responses
      end

      public
      def to_body(table_service)
        body = ""
        body.define_singleton_method(:add_line) do |a| self << (a || nil) + "\n" end

        is_get = true if !operations.empty? && operations[0][:method] == :get

        body.add_line "--#{batch_id}"
        body.add_line "Content-Type: multipart/mixed; boundary=#{changeset_id}" unless is_get
        body.add_line "" unless is_get

        operations.each { |op|
          uri = table_service.entities_uri(@table, @partition, op[:row_key])
          body.add_line "--#{changeset_id}" unless is_get
          body.add_line "Content-Type: application/http"
          body.add_line "Content-Transfer-Encoding: binary"
          body.add_line ""
          body.add_line "#{op[:method].to_s.upcase} #{uri} HTTP/1.1"

          if op[:headers]
            op[:headers].each { |k, v|
              body.add_line "#{k}: #{v}"
            }
          end

          if op[:body]
            body.add_line "Content-Length: #{op[:body].bytesize}"
            body.add_line ""
            body.add_line op[:body]
          else
            body.add_line ""
          end

        }
        body.add_line "--#{changeset_id}--" unless is_get
        body.add_line "--#{batch_id}--"
      end

      # Public: Inserts new entity to the table.
      #
      # ==== Attributes
      #
      # * +row_key+       - String. The row key
      # * +entity_values+ - Hash. A hash of the name/value pairs for the entity.
      # * +options+       - Hash. Optional parameters.
      #
      # ==== Options
      #
      # Accepted key/value pairs in options parameter are:
      # * +:accept+              - String. Specifies the accepted content-type of the response payload. Possible values are:
      #                             :no_meta
      #                             :min_meta
      #                             :full_meta
      # * +:prefer+              - String. Specifies whether the response should include the inserted entity in the payload. Possible values are:
      #                             Azure::Storage::Common::HeaderConstants::PREFER_CONTENT
      #                             Azure::Storage::Common::HeaderConstants::PREFER_NO_CONTENT
      #
      # See http://msdn.microsoft.com/en-us/library/azure/dd179433
      public
      def insert(row_key, entity_values, options = {})
        check_entity_key(row_key)

        headers = { Azure::Storage::Common::HeaderConstants::ACCEPT => Serialization.get_accept_string(options[:accept]) }
        headers[Azure::Storage::Common::HeaderConstants::PREFER] = options[:prefer] unless options[:prefer].nil?

        body = Serialization.hash_to_json({
            "PartitionKey" => partition,
            "RowKey" => row_key
          }.merge(entity_values)
        )

        add_operation(:post, nil, body, headers)
        self
      end

      # Public: Gets entity from the table.
      #
      # ==== Attributes
      #
      # * +row_key+       - String. The row key
      # * +options+       - Hash. Optional parameters.
      #
      # ==== Options
      #
      # Accepted key/value pairs in options parameter are:
      # * +:accept+              - String. Specifies the accepted content-type of the response payload. Possible values are:
      #                             :no_meta
      #                             :min_meta
      #                             :full_meta
      #
      # See http://msdn.microsoft.com/en-us/library/azure/dd179433
      public
      def get(row_key, options = {})
        check_entity_key(row_key)

        headers = { Azure::Storage::Common::HeaderConstants::ACCEPT => Serialization.get_accept_string(options[:accept]) }

        add_operation(:get, row_key, nil, headers)
        self
      end

      # Public: Updates an existing entity in a table. The Update Entity operation replaces
      # the entire entity and can be used to remove properties.
      #
      # ==== Attributes
      #
      # * +row_key+       - String. The row key
      # * +entity_values+ - Hash. A hash of the name/value pairs for the entity.
      # * +options+       - Hash. Optional parameters.
      #
      # ==== Options
      #
      # Accepted key/value pairs in options parameter are:
      # * :if_match              - String. A matching condition which is required for update (optional, Default="*")
      # * :create_if_not_exists  - Boolean. If true, and partition_key and row_key do not reference and existing entity,
      #   that entity will be inserted. If false, the operation will fail. (optional, Default=false)
      # * +:accept+              - String. Specifies the accepted content-type of the response payload. Possible values are:
      #                             :no_meta
      #                             :min_meta
      #                             :full_meta
      #
      # See http://msdn.microsoft.com/en-us/library/azure/dd179427
      public
      def update(row_key, entity_values, options = {})
        check_entity_key(row_key)

        headers = { Azure::Storage::Common::HeaderConstants::ACCEPT => Serialization.get_accept_string(options[:accept]) }
        headers["If-Match"] = options[:if_match] || "*" unless options[:create_if_not_exists]

        body = Serialization.hash_to_json(entity_values)

        add_operation(:put, row_key, body, headers)
        self
      end

      # Public: Updates an existing entity by updating the entity's properties. This operation
      # does not replace the existing entity, as the update_entity operation does.
      #
      # ==== Attributes
      #
      # * +row_key+         - String. The row key
      # * +entity_values+   - Hash. A hash of the name/value pairs for the entity.
      # * +options+         - Hash. Optional parameters.
      #
      # ==== Options
      #
      # Accepted key/value pairs in options parameter are:
      # * +if_match+              - String. A matching condition which is required for update (optional, Default="*")
      # * +create_if_not_exists+  - Boolean. If true, and partition_key and row_key do not reference and existing entity,
      #   that entity will be inserted. If false, the operation will fail. (optional, Default=false)
      # * +:accept+              - String. Specifies the accepted content-type of the response payload. Possible values are:
      #                             :no_meta
      #                             :min_meta
      #                             :full_meta
      #
      # See http://msdn.microsoft.com/en-us/library/azure/dd179392
      public
      def merge(row_key, entity_values, options = {})
        check_entity_key(row_key)

        headers = { Azure::Storage::Common::HeaderConstants::ACCEPT => Serialization.get_accept_string(options[:accept]) }
        headers["If-Match"] = options[:if_match] || "*" unless options[:create_if_not_exists]

        body = Serialization.hash_to_json(entity_values)

        add_operation(:merge, row_key, body, headers)
        self
      end

      # Public: Inserts or updates an existing entity within a table by merging new property values into the entity.
      #
      # ==== Attributes
      #
      # * +row_key+               - String. The row key
      # * +entity_values+         - Hash. A hash of the name/value pairs for the entity.
      #
      # See http://msdn.microsoft.com/en-us/library/azure/hh452241
      public
      def insert_or_merge(row_key, entity_values)
        merge(row_key, entity_values, create_if_not_exists: true)
        self
      end

      # Public: Inserts or updates a new entity into a table.
      #
      # ==== Attributes
      #
      # * +row_key+               - String. The row key
      # * +entity_values+         - Hash. A hash of the name/value pairs for the entity.
      #
      # See http://msdn.microsoft.com/en-us/library/azure/hh452242
      public
      def insert_or_replace(row_key, entity_values)
        update(row_key, entity_values, create_if_not_exists: true)
        self
      end

      # Public: Deletes an existing entity in the table.
      #
      # ==== Attributes
      #
      # * +row_key+       - String. The row key
      # * +options+       - Hash. Optional parameters.
      #
      # ==== Options
      #
      # Accepted key/value pairs in options parameter are:
      # * +if_match+      - String. A matching condition which is required for update (optional, Default="*")
      # * +:accept+              - String. Specifies the accepted content-type of the response payload. Possible values are:
      #                             :no_meta
      #                             :min_meta
      #                             :full_meta
      #
      # See http://msdn.microsoft.com/en-us/library/azure/dd135727
      public
      def delete(row_key, options = {})
        headers = {
          Azure::Storage::Common::HeaderConstants::ACCEPT => Serialization.get_accept_string(options[:accept]),
          "If-Match" => options[:if_match] || "*"
        }
        add_operation(:delete, row_key, nil, headers)
        self
      end
    end
  end
end
