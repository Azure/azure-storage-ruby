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
require "azure/storage/service/serialization"

require "azure/storage/table/guid"
require "azure/storage/table/edmtype"
require "azure/storage/table/entity"

require "time"
require "date"
require "json"

module Azure
  module Storage
    module Table
      # This is a class that serializes the request/response body for table
      # service.
      module Serialization
        include Azure::Storage::Service::Serialization

        def self.hash_to_json(h)
          newhash = {}
          h.map do |key, val|
            type = Table::EdmType.property_type(val)
            type_key = key.is_a?(Symbol) ? key.to_s + TableConstants::ODATA_TYPE_SUFFIX : key + TableConstants::ODATA_TYPE_SUFFIX
            newhash[key] = EdmType::serialize_value(type, val)
            newhash[type_key] = type unless type.nil? || type.empty? || h.key?(type_key)
          end
          JSON newhash
        end

        def self.table_entries_from_json(json)
          table_entries_from_hash(hash_from_json(json))
        end

        def self.hash_from_json(json)
          JSON.parse(json)
        end

        def self.table_entries_from_hash(h)
          values = []
          if h["value"]
            h["value"].each do |name|
              values.push(name)
            end
          elsif h["TableName"]
            values = h
          end
          values
        end

        def self.entity_from_json(json)
          entity_from_hash(hash_from_json(json))
        end

        def self.entities_from_json(json)
          entities_hash = hash_from_json(json)
          entities_hash["value"].nil? ? [entity_from_hash(entities_hash)] : entities_from_hash(entities_hash)
        end

        def self.entities_from_hash(h)
          entities = []
          h["value"].each { |entity_hash|
            entities.push(entity_from_hash(entity_hash))
          }
          entities
        end

        def self.entity_from_hash(h)
          Entity.new do |entity|
            entity.etag = h.delete(TableConstants::ODATA_ETAG)
            properties = {}
            h.each do |k, v|
              type = h[k + TableConstants::ODATA_TYPE_SUFFIX]
              properties[k] = EdmType::deserialize_value(v, type.nil? ? EdmType::property_type(v) : type)
            end
            entity.properties = properties
          end
        end

        def self.get_accept_string(accept_type = :min_meta)
          case accept_type
          when :no_meta
            HeaderConstants::ODATA_NO_META
          when :min_meta
            HeaderConstants::ODATA_MIN_META
          when :full_meta
            HeaderConstants::ODATA_FULL_META
          when nil
            HeaderConstants::ODATA_MIN_META
          else
            accept_type
          end
        end
      end
    end
  end
end
