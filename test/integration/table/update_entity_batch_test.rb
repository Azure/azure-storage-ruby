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
  describe "#update_entity_batch" do
    subject { Azure::Storage::Table::TableService.create(SERVICE_CREATE_OPTIONS()) }
    let(:table_name) { TableNameHelper.name }

    let(:entity_properties) {
      {
        "PartitionKey" => "testingpartition",
        "RowKey" => "abcd1234_existing",
        "CustomStringProperty" => "CustomPropertyValue",
        "CustomIntegerProperty" => 37,
        "CustomBooleanProperty" => true,
        "CustomDateProperty" => Time.now
      }
    }

    before {
      subject.create_table table_name
      subject.insert_entity table_name, entity_properties
      @existing_etag = ""

      exists = false
      begin
        existing = subject.get_entity table_name, entity_properties["PartitionKey"], entity_properties["RowKey"]
        @existing_etag = existing.etag
        exists = true
      rescue
      end

      assert exists, "cannot verify existing record"
    }

    after { TableNameHelper.clean }

    it "updates an existing entity, removing any properties not included in the update operation" do
      batch = Azure::Storage::Table::Batch.new table_name, entity_properties["PartitionKey"]
      batch.update entity_properties["RowKey"],         "PartitionKey" => entity_properties["PartitionKey"],
        "RowKey" => entity_properties["RowKey"],
        "NewCustomProperty" => "NewCustomValue"
      etags = subject.execute_batch batch

      # etag for first (and only) operation
      _(etags[0]).must_be_kind_of String
      etags[0].wont_equal @existing_etag

      result = subject.get_entity table_name, entity_properties["PartitionKey"], entity_properties["RowKey"]

      _(result).must_be_kind_of Azure::Storage::Table::Entity

      # removed all existing props
      entity_properties.each { |k, v|
        result.properties.wont_include k unless k == "PartitionKey" || k == "RowKey"
      }

      # and has the new one
      _(result.properties["NewCustomProperty"]).must_equal "NewCustomValue"
    end

    it "updates an existing entity, removing any properties not included in the update operation and adding nil one" do
      batch = Azure::Storage::Table::Batch.new table_name, entity_properties["PartitionKey"]
      batch.update entity_properties["RowKey"],         "PartitionKey" => entity_properties["PartitionKey"],
        "RowKey" => entity_properties["RowKey"],
        "NewCustomProperty" => nil
      etags = subject.execute_batch batch

      # etag for first (and only) operation
      _(etags[0]).must_be_kind_of String
      etags[0].wont_equal @existing_etag

      result = subject.get_entity table_name, entity_properties["PartitionKey"], entity_properties["RowKey"]

      _(result).must_be_kind_of Azure::Storage::Table::Entity

      # removed all existing props
      entity_properties.each { |k, v|
        result.properties.wont_include k unless k == "PartitionKey" || k == "RowKey"
      }

      # and has the new one
      _(result.properties["NewCustomProperty"]).must_equal nil
    end

    it "errors on a non-existing row key" do
      assert_raises(RuntimeError) do
        entity = entity_properties.dup
        entity["RowKey"] = "this-row-key-does-not-exist"

        batch = Azure::Storage::Table::Batch.new table_name, entity["PartitionKey"]
        batch.update entity["RowKey"], entity
        etags = subject.execute_batch batch
      end
    end

    it "errors on an invalid table name" do
      assert_raises(RuntimeError) do
        batch = Azure::Storage::Table::Batch.new "this_table.cannot-exist!", entity_properties["PartitionKey"]
        batch.update entity_properties["RowKey"], entity_properties
        etags = subject.execute_batch batch
      end
    end

    it "errors on an invalid partition key" do
      assert_raises(RuntimeError) do
        entity = entity_properties.dup
        entity["PartitionKey"] = "this/partition_key#is?invalid"

        batch = Azure::Storage::Table::Batch.new table_name, entity["PartitionKey"]
        batch.update entity["RowKey"], entity
        etags = subject.execute_batch batch
      end
    end

    it "errors on an invalid row key" do
      assert_raises(RuntimeError) do
        entity = entity_properties.dup
        entity["RowKey"] = "this/row_key#is?invalid"

        batch = Azure::Storage::Table::Batch.new table_name, entity["PartitionKey"]
        batch.update entity["RowKey"], entity
        etags = subject.execute_batch batch
      end
    end
  end
end
