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

require 'azure/storage/table/guid'

require "time"
require "date"

module Azure::Storage
  module Table
    module EdmType
      # Public: Get the Edm type of an object
      #
      # value - Object. An typed instance
      #
      # Returns the Edm type as a String
      def self.property_type(value)
        case value
        when Float
          "Edm.Double"
        when Date, Time, DateTime
          "Edm.DateTime"
        when Integer
          value.abs < 2**31 ? "Edm.Int32" : "Edm.Int64"
        when TrueClass, FalseClass
          "Edm.Boolean"
        when GUID
          "Edm.Guid"
        when IO, File
          "Edm.Binary"
        when String
          value.encoding.names.include?("BINARY") ? "Edm.Binary" : ""
        else
          value.kind_of?(IO) ? "Edm.Binary" : ""
        end
      end

      # Public: Get the value of a property in a serialized way
      #
      # value - Object. An typed instance
      #
      # Returns the Edm type as a String
      def self.serialize_value(type, value)
        case type
        when "Edm.Double", "Edm.Int32", "Edm.Int64", "Edm.Guid", "Edm.String", nil
          value.to_s
        when "Edm.Binary"
          Base64.encode64(value.to_s).chomp("\n")
        when "Edm.DateTime"
          value.xmlschema(7)
        when "Edm.Boolean"
          if value.nil?
            ''
          else
            value == true ? '1' : '0'
          end
        else
          value.to_s
        end
      end

      # Public: Serializes EDM value into proper value to be used in query.
      # 
      # value - String. The value to serialize.
      #
      # Returns the serialized value
      def self.serialize_query_value(value)
        case value
        when Date, Time, DateTime
          "datetime'#{value.iso8601}'"
        when TrueClass, FalseClass
          value ? "true" : "false"
        when Float, Integer
          value.abs < 2**31 ? value.to_s : value.to_s + "L"
        when GUID
          "guid'#{value.to_s}'"
        when IO, File
          "X'" + value.to_s.unpack("H*").join("") + "'"
        else
          if value != nil && value.encoding.names.include?("BINARY")
            "X'" + value.to_s.unpack("H*").join("") + "'"
          else
            # NULL also is treated as EdmType::STRING
            value.to_s.gsub("'","''");
          end
        end
      end

      # Public: Convert a serialized value into an typed object
      #
      # value - String. The Edm value
      # type  - String. The Edm datatype
      #
      # Returns an typed object
      def self.unserialize_query_value(value, type)
        case type
        when "Edm.DateTime"
          Time.parse(value)
        when "Edm.Double"
          Float(value)
        when "Edm.Int32", "Edm.Int64"
          Integer(value)
        when "Edm.Boolean"
          /true/i === value
        when "Edm.Guid"
          GUID.new(value.to_s)
        when "Edm.Binary"
          Base64.decode64(value.to_s).force_encoding("BINARY")
        else
          value.to_s
        end
      end
    end
  end
end