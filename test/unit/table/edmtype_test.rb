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

describe Azure::Storage::Table::EdmType do
  describe "#serialize_query_value" do
    it "correctly serializes int64 query values" do
      value = 2**128 + 1256231
      serializedValue = Azure::Storage::Table::EdmType.serialize_query_value(value)
      _(serializedValue).must_equal value.to_s + "L"
    end

    it "correctly serializes int32 query values" do
      value = 2
      serializedValue = Azure::Storage::Table::EdmType.serialize_query_value(value)
      _(serializedValue).must_equal "2"
    end

    it "correctly serializes datetime query values" do
      value = DateTime.new(2001, 2, 3, 4, 5, 6)
      serializedValue = Azure::Storage::Table::EdmType.serialize_query_value(value)
      _(serializedValue).must_equal "datetime'2001-02-03T04:05:06+00:00'"
    end

    it "correctly serializes guid query values" do
      value = Azure::Storage::Table::GUID.new("81425519-6394-43e4-ac6e-28d91f5c3921")
      serializedValue = Azure::Storage::Table::EdmType.serialize_query_value(value)
      _(serializedValue).must_equal "guid'81425519-6394-43e4-ac6e-28d91f5c3921'"
    end

    it "correctly serializes float query values" do
      value = 1.2
      serializedValue = Azure::Storage::Table::EdmType.serialize_query_value(value)
      _(serializedValue).must_equal "1.2"
    end

    it "correctly serializes string query values" do
      value = "string"
      serializedValue = Azure::Storage::Table::EdmType.serialize_query_value(value)
      _(serializedValue).must_equal "string"
    end

    it "correctly serializes binary query values" do
      value = "1".force_encoding("BINARY")
      serializedValue = Azure::Storage::Table::EdmType.serialize_query_value(value)
      _(serializedValue).must_equal "X'31'"
    end
  end

  describe "#deserialize_query_value" do
    it "correctly deserializes int64 query values" do
      value = "340282366920938463463374607431769467687"
      deserializedValue = Azure::Storage::Table::EdmType.deserialize_value(value, "Edm.Int64")
      _(deserializedValue).must_equal (2**128 + 1256231)
    end

    it "correctly deserializes int32 query values" do
      value = "2"
      deserializedValue = Azure::Storage::Table::EdmType.deserialize_value(value, "Edm.Int32")
      _(deserializedValue).must_equal 2
    end

    it "correctly deserializes datetime query values" do
      value = "2001-02-03T04:05:06+00:00"
      deserializedValue = Azure::Storage::Table::EdmType.deserialize_value(value, "Edm.DateTime")
      _(deserializedValue).must_equal Time.new(2001, 2, 3, 4, 5, 6, "+00:00")
    end

    it "correctly deserializes guid query values" do
      value = "81425519-6394-43e4-ac6e-28d91f5c3921"
      deserializedValue = Azure::Storage::Table::EdmType.deserialize_value(value, "Edm.Guid")
      _(deserializedValue).must_equal Azure::Storage::Table::GUID.new("81425519-6394-43e4-ac6e-28d91f5c3921")
    end

    it "correctly deserializes float query values" do
      value = "1.2"
      deserializedValue = Azure::Storage::Table::EdmType.deserialize_value(value, "Edm.Double")
      _(deserializedValue).must_equal 1.2
    end

    it "correctly deserializes string query values" do
      value = "string"
      deserializedValue = Azure::Storage::Table::EdmType.deserialize_value(value, "Edm.String")
      _(deserializedValue).must_equal "string"
    end

    it "correctly deserializes binary query values" do
      value = "MTIzNDU=".force_encoding("BINARY")
      deserializedValue = Azure::Storage::Table::EdmType.deserialize_value(value, "Edm.Binary")
      _(deserializedValue).must_equal "12345"
    end
  end
end
