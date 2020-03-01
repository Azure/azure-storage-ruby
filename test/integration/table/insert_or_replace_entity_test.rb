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
  describe "#insert_or_replace_entity" do
    subject { Azure::Storage::Table::TableService.create(SERVICE_CREATE_OPTIONS()) }
    let(:table_name) { TableNameHelper.name }

    let(:entity_properties) {
      {
        "PartitionKey" => "testingpartition",
        "CustomStringProperty" => "CustomPropertyValue",
        "CustomIntegerProperty" => 37,
        "CustomBooleanProperty" => true,
        "CustomDateProperty" => Time.now
      }
    }

    before {
      subject.create_table table_name
    }

    after { TableNameHelper.clean }

    it "creates an entity if it does not already exist" do
      entity = entity_properties.dup
      entity["RowKey"] = "abcd1234"

      does_not_exist = true
      begin
        subject.get_entity table_name, entity["PartitionKey"], entity["RowKey"]
        does_not_exist = false
      rescue
      end

      assert does_not_exist

      etag = subject.insert_or_replace_entity table_name, entity
      _(etag).must_be_kind_of String

      result = subject.get_entity table_name, entity["PartitionKey"], entity["RowKey"]

      _(result).must_be_kind_of Azure::Storage::Table::Entity
      _(result.etag).must_equal etag

      entity.each { |k, v|
        unless entity[k].class == Time
          _(result.properties[k]).must_equal entity[k]
        else
          _(result.properties[k].to_i).must_equal entity[k].to_i
        end
      }
    end

    it "updates an existing entity, removing any properties not included in the update operation" do
      entity = entity_properties.dup
      entity["RowKey"] = "abcd1234_existing"

      result = subject.insert_entity table_name, entity

      existing_etag = ""

      exists = false
      begin
        existing = subject.get_entity table_name, entity["PartitionKey"], entity["RowKey"]
        existing_etag = existing.etag
        exists = true
      rescue
      end

      assert exists, "cannot verify existing record"

      etag = subject.insert_or_replace_entity table_name,         "PartitionKey" => entity["PartitionKey"],
        "RowKey" => entity["RowKey"],
        "NewCustomProperty" => "NewCustomValue"

      _(etag).must_be_kind_of String
      etag.wont_equal existing_etag

      result = subject.get_entity table_name, entity["PartitionKey"], entity["RowKey"]

      _(result).must_be_kind_of Azure::Storage::Table::Entity

      # removed all existing props
      entity.each { |k, v|
        result.properties.wont_include k unless k == "PartitionKey" || k == "RowKey"
      }

      # and has the new one
      _(result.properties["NewCustomProperty"]).must_equal "NewCustomValue"
    end

    it "errors on an invalid table name" do
      assert_raises(Azure::Core::Http::HTTPError) do
        entity = entity_properties.dup
        entity["RowKey"] = "row_key"
        subject.insert_or_replace_entity "this_table.cannot-exist!", entity
      end
    end

    it "errors on an invalid partition key" do
      assert_raises(Azure::Core::Http::HTTPError) do
        entity = entity_properties.dup
        entity["PartitionKey"] = "this/partition_key#is?invalid"
        entity["RowKey"] = "row_key"
        subject.insert_or_replace_entity table_name, entity
      end
    end

    it "errors on an invalid row key" do
      assert_raises(Azure::Core::Http::HTTPError) do
        entity = entity_properties.dup
        entity["RowKey"] = "this/partition_key#is?invalid"
        subject.insert_or_replace_entity table_name, entity
      end
    end
  end
end
