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
require "unit/test_helper"
require "azure/storage/table"
require "time"

describe Azure::Storage::Table::Serialization do
  subject { Azure::Storage::Table::Serialization }

  describe "#hash_to_json" do
    let(:query_entities_response_json) { Fixtures["query_entities_response"] }
    let(:query_entities_response_hash) {
      {
        "odata.metadata" => "https://mytest.table.core.windows.net/$metadata#xyxnnunbmu/@Element",
        "odata.etag" => "W/\"datetime'2017-09-12T03%3A40%3A08.358891Z'\"",
        "PartitionKey" => "part2",
        "RowKey" => "entity-6",
        "Timestamp" => Time.parse("2017-09-12T03:40:08.358891Z"),
        "CustomStringProperty" => "CustomPropertyValue",
        "CustomIntegerProperty" => 37,
        "CustomBooleanProperty" => true,
        "CustomDateProperty@odata.type" => "Edm.DateTime",
        "CustomDateProperty" => Time.parse("2017-09-12T03:40:06.463953Z")
      }
    }
    it "serialize a hash to JSON string" do
      result = subject.hash_to_json(query_entities_response_hash)
      _(result).must_equal query_entities_response_json
    end
  end

  describe "#table_entries_from_json" do

    let(:query_tables_json) { Fixtures["query_tables"] }
    let(:table_entries) {
      [
        { "TableName" => "aapilycmrr" },
        { "TableName" => "bbfbbpbsmm" },
        { "TableName" => "dfkvsheskq" },
        { "TableName" => "ecxataxwrl" },
        { "TableName" => "edhakjwlho" },
        { "TableName" => "evsxufolvc" },
        { "TableName" => "gjbcwdgevl" },
        { "TableName" => "jwqiijvkcz" },
        { "TableName" => "lhulazoqvz" },
        { "TableName" => "lraeudqsxw" },
        { "TableName" => "lrxqpcdbqb" },
        { "TableName" => "ndiekmdvwh" },
        { "TableName" => "soyvdmcffy" },
        { "TableName" => "zridlgeizl" }
      ]
    }

    it "deserialize a table entries from json" do
      result = subject.table_entries_from_json(query_tables_json)
      _(result).must_equal table_entries
    end
  end

  describe "#entity_from_json" do
    let(:entity_json) { Fixtures["insert_entity_response_entry"] }

    it "create an entity from JSON" do
      result = subject.entity_from_json(entity_json)
      _(result).must_be_kind_of Azure::Storage::Table::Entity
      _(result.etag).must_equal "sampleetag"
      _(result.properties).must_equal("PartitionKey" => "abcd321", "RowKey" => "abcd123" , "CustomDoubleProperty" => "3.141592")
    end
  end

  describe "#entities_from_json" do
    let(:multiple_entities_json) { Fixtures["multiple_entities_payload"] }

    it "create entities array from JSON string" do
      result = subject.entities_from_json(multiple_entities_json)
      result.each do |e|
        _(e.properties["PartitionKey"]).must_include "part"
        _(e.properties["RowKey"]).must_include "entity-"
        _(e.properties["Timestamp"]).must_include "2017-09-12"
        _(e.properties["CustomStringProperty"]).must_equal "CustomPropertyValue"
        _(e.properties["CustomIntegerProperty"]).must_equal 37
        _(e.properties["CustomBooleanProperty"]).must_equal true
        _(e.properties["CustomDateProperty"].to_i).must_equal Time.parse("2017-09-12 03:40:23 UTC").to_i
      end
    end
  end

  describe "#get_accept_string" do
    let(:expected_results) {
      {
        no_meta: Azure::Storage::Common::HeaderConstants::ODATA_NO_META,
        min_meta: Azure::Storage::Common::HeaderConstants::ODATA_MIN_META,
        full_meta: Azure::Storage::Common::HeaderConstants::ODATA_FULL_META,
        Azure::Storage::Common::HeaderConstants::ODATA_NO_META => Azure::Storage::Common::HeaderConstants::ODATA_NO_META,
        Azure::Storage::Common::HeaderConstants::ODATA_MIN_META => Azure::Storage::Common::HeaderConstants::ODATA_MIN_META,
        Azure::Storage::Common::HeaderConstants::ODATA_FULL_META => Azure::Storage::Common::HeaderConstants::ODATA_FULL_META,
        "nonsense" => "nonsense"
      }
    }

    it "create accept string with input" do
      expected_results.each do |k, v|
        _(subject.get_accept_string(k)).must_equal v
      end
    end
  end
end
