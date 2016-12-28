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
require 'azure/storage/table/table_service'
require 'azure/storage/table/edmtype'

module Azure::Storage
  module Table
    class Query
      def initialize(table="", partition=nil, row=nil, &block)
        @table = table
        @partition_key = partition
        @row_key = row
        @fields = []
        @filters = []
        @top_n = nil
        @table_service = Azure::Storage::Table::TableService.new
        self.instance_eval(&block) if block_given?
      end
        
      attr_reader :table
      attr_reader :partition_key
      attr_reader :row_key

      attr_reader :fields
      attr_reader :filters
      attr_reader :top_n

      attr_reader :next_partition_key
      attr_reader :next_row_key

      attr_reader :table_service

      def from(table_name)
        @table = table_name
        self
      end

      def partition(partition_key)
        @partition_key = partition_key
        self
      end

      def row(row_key)
        @row_key = row_key
        self
      end

      def select(*p)
        @fields.concat(p)
        self
      end

      def where(*p)
        @filters.push(p)
        self
      end
      
      def top(n)
        @top_n = n
        self
      end

      def next_partition(next_partition_key)
        @next_partition_key = next_partition_key
        self
      end

      def next_row(next_row_key)
        @next_row_key = next_row_key
        self
      end

      def execute
        @table_service.query_entities(@table, {
          :partition_key => @partition_key,
          :row_key => @row_key, 
          :select => @fields.map{ |f| f.to_s },
          :filter => _build_filter_string,
          :top => (@top_n ? @top_n.to_i : @top_n),
          :continuation_token => { 
            :next_partition_key => @next_partition_key,
            :next_row_key => @next_row_key
          }
        })
      end

      def _build_filter_string
        result = ""
        clauses = []
        filters.each { |f|
          clauses.push "#{f[0]} #{f[1]} #{Azure::Storage::Table::EdmType.serialize_query_value(f[2])}"
        }
        return nil if clauses.length == 0 
        
        result << clauses.join(" and ")
        result
      end
    end
  end
end