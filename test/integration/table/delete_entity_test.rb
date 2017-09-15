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
require "azure/storage/table/table_service"
require "azure/core/http/http_error"

describe Azure::Storage::Table::TableService do
  describe "#delete_entity" do
    subject { Azure::Storage::Table::TableService.new }
    let(:table_name) { TableNameHelper.name }

    let(:entity_properties) {
      {
        "PartitionKey" => "testingpartition",
        "RowKey" => "abcd123",
        "CustomStringProperty" => "CustomPropertyValue",
        "CustomIntegerProperty" => 37,
        "CustomBooleanProperty" => true,
        "CustomDateProperty" => Time.now
      }
    }

    before {
      subject.create_table table_name
      subject.insert_entity table_name, entity_properties
    }
    after { TableNameHelper.clean }

    it "deletes an entity" do
      result = subject.delete_entity table_name, entity_properties["PartitionKey"], entity_properties["RowKey"]
      result.must_be_nil

      # query entity to make sure it was deleted
      assert_raises(Azure::Core::Http::HTTPError, "ResourceNotFound (404): The specified resource does not exist.") do
        subject.get_entity table_name, entity_properties["PartitionKey"], entity_properties["RowKey"]
      end
    end

    it "deletes complex keys" do
      entity = entity_properties.dup

      entity["RowKey"] = "key with spaces"
      subject.insert_entity table_name, entity
      result = subject.delete_entity table_name, entity["PartitionKey"], entity["RowKey"]
      result.must_be_nil

      entity["RowKey"] = "key'with'quotes"
      subject.insert_entity table_name, entity
      result = subject.delete_entity table_name, entity["PartitionKey"], entity["RowKey"]
      result.must_be_nil

      # Uncomment when issue 145 (Cannot use GB-18030 characters in strings) is fixed
      #entity["RowKey"] = "keyWithUnicode" + 0xE.chr + 0x8B.chr + 0xA4.chr
      #subject.insert_entity table_name, entity
      #result = subject.delete_entity table_name, entity["PartitionKey"], entity["RowKey"]
      #result.must_be_nil

      entity["RowKey"] = "Qbert_Says=.!@%^&"
      subject.insert_entity table_name, entity
      result = subject.delete_entity table_name, entity["PartitionKey"], entity["RowKey"]
      result.must_be_nil
    end

    it "errors on an invalid table name" do
      assert_raises(Azure::Core::Http::HTTPError) do
        subject.delete_entity "this_table.cannot-exist!", entity_properties["PartitionKey"], entity_properties["RowKey"]
      end
    end

    it "errors on an invalid partition key" do
      assert_raises(Azure::Core::Http::HTTPError) do
        subject.delete_entity table_name, "this_partition/key#is_invalid", entity_properties["RowKey"]
      end
    end

    it "errors on an invalid row key" do
      assert_raises(Azure::Core::Http::HTTPError) do
        subject.delete_entity table_name, entity_properties["PartitionKey"], "thisrow/key#is_invalid"
      end
    end
  end
end
