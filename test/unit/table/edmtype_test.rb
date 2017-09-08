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
require "azure/storage/table/edmtype"

require "azure/storage/table/guid"

describe Azure::Storage::Table::EdmType do
  describe "#serialize_query_value" do
    it "correctly serializes int64 query values" do
      value = 2**128 + 1256231
      serializedValue = Azure::Storage::Table::EdmType.serialize_query_value(value)
      serializedValue.must_equal value.to_s + "L"
    end

    it "correctly serializes int32 query values" do
      value = 2
      serializedValue = Azure::Storage::Table::EdmType.serialize_query_value(value)
      serializedValue.must_equal "2"
    end

    it "correctly serializes datetime query values" do
      value = DateTime.new(2001,2,3,4,5,6)
      serializedValue = Azure::Storage::Table::EdmType.serialize_query_value(value)
      serializedValue.must_equal "datetime'2001-02-03T04:05:06+00:00'"
    end

    it "correctly serializes guid query values" do
      value = Azure::Storage::Table::GUID.new("81425519-6394-43e4-ac6e-28d91f5c3921")
      serializedValue = Azure::Storage::Table::EdmType.serialize_query_value(value)
      serializedValue.must_equal "guid'81425519-6394-43e4-ac6e-28d91f5c3921'"
    end

    it "correctly serializes float query values" do
      value = 1.2
      serializedValue = Azure::Storage::Table::EdmType.serialize_query_value(value)
      serializedValue.must_equal "1.2"
    end

    it "correctly serializes string query values" do
      value = "string"
      serializedValue = Azure::Storage::Table::EdmType.serialize_query_value(value)
      serializedValue.must_equal "string"
    end

    it "correctly serializes binary query values" do
      value = "1".force_encoding("BINARY")
      serializedValue = Azure::Storage::Table::EdmType.serialize_query_value(value)
      serializedValue.must_equal "X'31'"
    end
  end

  describe "#unserialize_query_value" do
    it "correctly unserializes int64 query values" do
      value = "340282366920938463463374607431769467687"
      unserializedValue = Azure::Storage::Table::EdmType.unserialize_value(value, "Edm.Int64")
      unserializedValue.must_equal (2**128 + 1256231)
    end

    it "correctly unserializes int32 query values" do
      value = "2"
      unserializedValue = Azure::Storage::Table::EdmType.unserialize_value(value, "Edm.Int32")
      unserializedValue.must_equal 2
    end

    it "correctly unserializes datetime query values" do
      value = "2001-02-03T04:05:06+00:00"
      unserializedValue = Azure::Storage::Table::EdmType.unserialize_value(value, "Edm.DateTime")
      unserializedValue.must_equal Time.new(2001, 2, 3, 4, 5, 6, "+00:00")
    end

    it "correctly unserializes guid query values" do
      value = "81425519-6394-43e4-ac6e-28d91f5c3921"
      unserializedValue = Azure::Storage::Table::EdmType.unserialize_value(value, "Edm.Guid")
      unserializedValue.must_equal Azure::Storage::Table::GUID.new("81425519-6394-43e4-ac6e-28d91f5c3921")
    end

    it "correctly unserializes float query values" do
      value = "1.2"
      unserializedValue = Azure::Storage::Table::EdmType.unserialize_value(value, "Edm.Double")
      unserializedValue.must_equal 1.2
    end

    it "correctly unserializes string query values" do
      value = "string"
      unserializedValue = Azure::Storage::Table::EdmType.unserialize_value(value, "Edm.String")
      unserializedValue.must_equal "string"
    end

    it "correctly unserializes binary query values" do
      value = "MTIzNDU=".force_encoding("BINARY")
      unserializedValue = Azure::Storage::Table::EdmType.unserialize_value(value, "Edm.Binary")
      unserializedValue.must_equal "12345"
    end
  end
end