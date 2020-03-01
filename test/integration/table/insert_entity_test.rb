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
  describe "#insert_entity" do
    subject { Azure::Storage::Table::TableService.create(SERVICE_CREATE_OPTIONS()) }
    let(:table_name) { TableNameHelper.name }

    let(:entity_properties) {
      {
        "PartitionKey" => "testingpartition",
        "RowKey" => "abcd123",
        "CustomDoubleProperty" => 3.141592,
        "CustomDoubleTrailingZeroProperty" => 1.0,
        "CustomDoublePrecisionProperty" => "1.012345678901234567890",
        "CustomInt32Property" => 37,
        "CustomInt64Property" => 2**32,
        "CustomInt64NegProperty" => -(2**32),
        "CustomGUIDProperty" => Azure::Storage::Table::GUID.new("81425519-6394-43e4-ac6e-28d91f5c3921"),
        "CustomStringProperty" => "CustomPropertyValue",
        "CustomBinaryProperty" => "\x01\x02\x03".force_encoding("BINARY"),
        "CustomDateProperty" => Time.now,
        "CustomDatePrecisionProperty" => Time.at(946684800, 123456.7),
        "CustomIntegerProperty" => 37,
        "CustomTrueProperty" => true,
        "CustomFalseProperty" => false,
        "CustomNilProperty" => nil
      }
    }

    before {
      subject.create_table table_name
    }
    after { TableNameHelper.clean }
    it "creates an entity" do
      result = subject.insert_entity table_name, entity_properties
      _(result).must_be_kind_of Azure::Storage::Table::Entity
      entity_properties.each { |k, v|
        if entity_properties[k].class == Time
          _(floor_to(result.properties[k].to_f, 6)).must_equal floor_to(entity_properties[k].to_f, 6)
        else
          _(result.properties[k]).must_equal entity_properties[k]
        end
      }
    end

    def floor_to(num, x)
      (num * 10**x).floor.to_f / 10**x
    end

    it "errors on an invalid table name" do
      assert_raises(Azure::Core::Http::HTTPError) do
        subject.insert_entity "this_table.cannot-exist!", entity_properties
      end
    end

    it "errors on an invalid partition key" do
      assert_raises(Azure::Core::Http::HTTPError) do
        entity = entity_properties.dup
        entity["PartitionKey"] = "this/partition\\key#is?invalid"
        subject.insert_entity table_name, entity
      end
    end

    it "errors on an invalid row key" do
      assert_raises(Azure::Core::Http::HTTPError) do
        entity = entity_properties.dup
        entity["RowKey"] = "this/row\\key#is?invalid"
        subject.insert_entity table_name, entity
      end
    end
  end
end
