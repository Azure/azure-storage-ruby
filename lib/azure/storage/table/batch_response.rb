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
module Azure::Storage
  module Table
    module BatchResponse
      def self.parse(data)
        context = { 
          :lines => data.lines.to_a,
          :index=> 0,
          :responses => []
        }

        find(context) { |c| batch_boundary c }
        find(context) { |c| batch_headers c }
        
        while(find(context){ |c| changeset_boundary_or_end c } == :boundary)
          find(context) { |c| changeset_headers c }
          find(context) { |c| response c }
          find(context) { |c| response_headers c }
          find(context) { |c| response_body c }
        end

        context[:responses]
      end

      def self.find(context, &block)
        while(context[:index] < context[:lines].length)
          result = block.call(context)
          return result if result
          context[:index] +=1
        end
      end

      def self.response_body(context)
        end_of_body = nil
        end_of_body = changeset_boundary_or_end(context.dup.merge!({:index=>context[:index] + 1})) if context[:index] < (context[:lines].length - 1)

        if end_of_body
          context[:responses].last[:body] ||= ""
          context[:responses].last[:body] << current_line(context)
          return context[:responses].last[:body]
        else 
          context[:responses].last[:body] ||= ""
          context[:responses].last[:body] << current_line(context)
          return nil
        end
      end

      def self.response_headers(context)
        match = /(.*): (.*)/.match(current_line(context))

        if context[:responses].last[:headers] and not match
          context[:index] += 1
          return context[:responses].last[:headers]
        elsif match
          context[:responses].last[:headers] ||= {}
          context[:responses].last[:headers][match[1].downcase] = match[2].strip
          return nil
        else
          return nil
        end
      end

      def self.response(context)
        match = /HTTP\/1.1 (\d*) (.*)/.match(current_line(context))
        return nil unless match
        response = {:status_code => match[1], :message => match[2] }
        context[:responses].push response
      end
      
      def self.changeset_headers(context)
        current_line(context).strip ==  ''
      end

      def self.changeset_boundary_or_end(context)
        match_boundary = /--changesetresponse_(.*)/.match(current_line(context))
        match_end = /--changesetresponse_(.*)--/.match(current_line(context))

        (match_boundary and not match_end) ? :boundary : (match_end ? :end : nil)
      end

      def self.batch_headers(context)
        match = /(.*): (.*)/.match(current_line(context))

        if context[:batch_headers] and not match
          return context[:batch_headers]
        elsif match
          context[:batch_headers] ||= {}
          context[:batch_headers][match[1].downcase] = match[2]
          return nil
        else
          return nil
        end
      end

      def self.batch_boundary(context)
        match = /--batchresponse_(.*)/.match(current_line(context))
        match ? match[1] : nil
      end
      
      def self.current_line(context)
        context[:lines][context[:index]]
      end
    end
  end
end
