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
require "integration/test_helper"
require "azure/core/http/http_error"

describe Azure::Storage::Table::TableService do
  describe "#query_entities" do
    subject { Azure::Storage::Table::TableService.create(SERVICE_CREATE_OPTIONS()) }
    let(:table_name) { TableNameHelper.name }
    let(:entities_per_partition) { 3 }
    let(:partitions) { ["part1", "part2", "part3"] }
    let(:entities) {
      entities = {}
      index = 0
      partitions.each { |p|
        entities[p] = []
        (0..entities_per_partition).each { |i|
          entities[p].push "entity-#{index}"
          index += 1
        }
      }
      entities
    }
    let(:entity_properties) {
      {
        "CustomStringProperty" => "CustomPropertyValue",
        "CustomIntegerProperty" => 37,
        "CustomBooleanProperty" => true,
        "CustomDateProperty" => Time.now
      }
    }
    before {
      subject.create_table table_name
      partitions.each { |p|
        entities[p].each { |e|
          entity = entity_properties.dup
          entity[:PartitionKey] = p
          entity[:RowKey] = e
          subject.insert_entity table_name, entity
        }
      }
    }

    after { TableNameHelper.clean }

    it "Queries a table for list of entities" do
      result = subject.query_entities table_name
      _(result).must_be_kind_of Array
      _(result.length).must_equal ((partitions.length + 1) * entities_per_partition)

      result.each { |e|
        _(entities[e.properties["PartitionKey"]]).must_include e.properties["RowKey"]
        entity_properties.each { |k, v|
          unless v.class == Time
            _(e.properties[k]).must_equal v
          else
            _(e.properties[k].to_i).must_equal v.to_i
          end
        }
      }
    end

    it "can constrain by partition and row key, returning zero or one entity" do
      partition = partitions[0]
      row_key = entities[partition][0]

      result = subject.query_entities table_name, partition_key: partition, row_key: row_key
      _(result).must_be_kind_of Array
      _(result.length).must_equal 1

      result.each { |e|
        _(e.properties["RowKey"]).must_equal row_key
        entity_properties.each { |k, v|
          unless v.class == Time
            _(e.properties[k]).must_equal v
          else
            _(e.properties[k].to_i).must_equal v.to_i
          end
        }
      }
    end

    it "can project a subset of properties, populating sparse properties with nil" do
      projection = ["CustomIntegerProperty", "ThisPropertyDoesNotExist"]
      puts "#########################################"
      result = subject.query_entities table_name, select: projection
      _(result).must_be_kind_of Array
      _(result.length).must_equal ((partitions.length + 1) * entities_per_partition)

      result.each { |e|
        _(e.properties.length).must_equal projection.length
        _(e.properties["CustomIntegerProperty"]).must_equal entity_properties["CustomIntegerProperty"]
        _(e.properties).must_include "ThisPropertyDoesNotExist"
        _(e.properties["ThisPropertyDoesNotExist"]).must_equal ""
      }
    end

    it "can filter by one or more properties, returning a matching set of entities" do
      subject.insert_entity table_name, entity_properties.merge("PartitionKey" => "filter-test-partition",
        "RowKey" => "filter-test-key",
        "CustomIntegerProperty" => entity_properties["CustomIntegerProperty"] + 1,
        "CustomBooleanProperty" => false)

      filter = "CustomIntegerProperty gt #{entity_properties["CustomIntegerProperty"]} and CustomBooleanProperty eq false"
      result = subject.query_entities table_name, filter: filter
      _(result).must_be_kind_of Array
      _(result.length).must_equal 1
      _(result.first.properties["PartitionKey"]).must_equal "filter-test-partition"

      filter = "CustomIntegerProperty gt #{entity_properties["CustomIntegerProperty"]} and CustomBooleanProperty eq true"
      result = subject.query_entities table_name, filter: filter
      _(result).must_be_kind_of Array
      _(result.length).must_equal 0
    end

    it "can limit the result set using the top parameter" do
      result = subject.query_entities table_name, top: 3
      _(result).must_be_kind_of Array
      _(result.length).must_equal 3
      _(result.continuation_token).wont_be_nil
    end

    it "can page results using the top parameter and continuation_token" do
      result = subject.query_entities table_name, top: 3
      _(result).must_be_kind_of Array
      _(result.length).must_equal 3
      _(result.continuation_token).wont_be_nil

      result2 = subject.query_entities table_name, top: 3, continuation_token: result.continuation_token
      _(result2).must_be_kind_of Array
      _(result2.length).must_equal 3
      _(result2.continuation_token).wont_be_nil

      result3 = subject.query_entities table_name, top: 3, continuation_token: result2.continuation_token
      _(result3).must_be_kind_of Array
      _(result3.length).must_equal 3
      _(result3.continuation_token).wont_be_nil

      result4 = subject.query_entities table_name, top: 3, continuation_token: result3.continuation_token
      _(result4).must_be_kind_of Array
      _(result4.length).must_equal 3
      _(result4.continuation_token).must_be_nil
    end

    it "can combine projection, filtering, and paging in the same query" do
      subject.insert_entity table_name, entity_properties.merge("PartitionKey" => "filter-test-partition",
        "RowKey" => "filter-test-key",
        "CustomIntegerProperty" => entity_properties["CustomIntegerProperty"] + 1,
        "CustomBooleanProperty" => false)

      filter = "CustomIntegerProperty eq #{entity_properties["CustomIntegerProperty"]}"
      projection = ["PartitionKey", "CustomIntegerProperty"]
      result = subject.query_entities table_name, select: projection, filter: filter, top: 3
      _(result).must_be_kind_of Array
      _(result.length).must_equal 3
      _(result.continuation_token).wont_be_nil

      _(result.first.properties["CustomIntegerProperty"]).must_equal entity_properties["CustomIntegerProperty"]
      _(result.first.properties["PartitionKey"]).wont_be_nil
      _(result.first.properties.length).must_equal 2

      result2 = subject.query_entities table_name, select: projection, filter: filter, top: 3, continuation_token: result.continuation_token
      _(result2).must_be_kind_of Array
      _(result2.length).must_equal 3
      _(result2.continuation_token).wont_be_nil

      result3 = subject.query_entities table_name, select: projection, filter: filter, top: 3, continuation_token: result2.continuation_token
      _(result3).must_be_kind_of Array
      _(result3.length).must_equal 3
      _(result3.continuation_token).wont_be_nil

      result4 = subject.query_entities table_name, select: projection, filter: filter, top: 3, continuation_token: result3.continuation_token
      _(result4).must_be_kind_of Array
      _(result4.length).must_equal 3
      _(result4.continuation_token).must_be_nil
    end

  end
end
