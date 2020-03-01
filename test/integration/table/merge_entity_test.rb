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
  describe "#merge_entity" do
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

    it "updates an existing entity, merging the properties" do
      etag = subject.merge_entity table_name,         PartitionKey: entity_properties["PartitionKey"],
        RowKey: entity_properties["RowKey"],
        NewCustomProperty: "NewCustomValue"
      _(etag).must_be_kind_of String
      etag.wont_equal @existing_etag

      result = subject.get_entity table_name, entity_properties["PartitionKey"], entity_properties["RowKey"]

      _(result).must_be_kind_of Azure::Storage::Table::Entity
      _(result.properties["PartitionKey"]).must_equal entity_properties["PartitionKey"]
      _(result.properties["RowKey"]).must_equal entity_properties["RowKey"]

      # retained all existing props
      entity_properties.each { |k, v|
        unless entity_properties[k].class == Time
          _(result.properties[k]).must_equal entity_properties[k]
        else
          _(result.properties[k].to_i).must_equal entity_properties[k].to_i
        end
      }

      # and has the new one
      _(result.properties["NewCustomProperty"]).must_equal "NewCustomValue"
    end

    it "errors on a non-existing row key" do
      assert_raises(Azure::Core::Http::HTTPError) do
        entity = entity_properties.dup
        entity["RowKey"] = "this-row-key-does-not-exist"
        subject.merge_entity table_name, entity
      end
    end

    it "errors on an invalid table name" do
      assert_raises(Azure::Core::Http::HTTPError) do
        subject.merge_entity "this_table.cannot-exist!", entity_properties
      end
    end

    it "errors on an invalid partition key" do
      assert_raises(Azure::Core::Http::HTTPError) do
        entity = entity_properties.dup
        entity["PartitionKey"] = "this/partition_key#is?invalid"
        subject.merge_entity table_name, entity
      end
    end

    it "errors on an invalid row key" do
      assert_raises(Azure::Core::Http::HTTPError) do
        entity = entity_properties.dup
        entity["RowKey"] = "this/row_key#is?invalid"
        subject.merge_entity table_name, entity
      end
    end
  end
end
