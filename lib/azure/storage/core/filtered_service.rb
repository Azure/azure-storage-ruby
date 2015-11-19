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
require 'azure/storage/core/service'

module Azure
  module Core
    # A base class for Service implementations
    class FilteredService < Service

      # Create a new instance of the FilteredService
      # 
      # @param host     [String] The hostname. (optional, Default empty)
      # @param options  [Hash] options including {:client} (optional, Default {})
      def initialize(host='', options={})
        super
        @filters = []
      end

      attr_accessor :filters

      def call(method, uri, body=nil, headers=nil)
        super(method, uri, body, headers) do |request|
          filters.each { |filter| request.with_filter filter } if filters
        end
      end

      def with_filter(filter=nil, &block)
        filter = filter || block
        filters.push filter if filter
      end
    end
  end
end