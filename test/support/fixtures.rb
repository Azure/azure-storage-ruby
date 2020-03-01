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
require "azure/core/http/retry_policy"

Fixtures = Hash.new do |hash, fixture|
  if path = Fixtures.xml?(fixture)
    hash[fixture] = path.read
  elsif path = Fixtures.json?(fixture)
    hash[fixture] = path.read
  elsif path = Fixtures.file?(fixture)
    hash[fixture] = path
  end
end

def Fixtures.root
  Pathname("../../fixtures").expand_path(__FILE__)
end

def Fixtures.file?(fixture)
  path = root.join(fixture)
  path.file? && path
end

def Fixtures.xml?(fixture)
  file?("#{fixture}.xml")
end

def Fixtures.json?(fixture)
  file?("#{fixture}.json")
end

module Azure
  module Core
    Fixtures = Hash.new do |hash, fixture|
      if path = Fixtures.xml?(fixture)
        hash[fixture] = path.read
      elsif path = Fixtures.file?(fixture)
        hash[fixture] = path
      end
    end
    def Fixtures.root
      Pathname("../../fixtures").expand_path(__FILE__)
    end
    def Fixtures.file?(fixture)
      path = root.join(fixture)
      path.file? && path
    end
    def Fixtures.xml?(fixture)
      file?("#{fixture}.xml")
    end
    
    class FixtureRetryPolicy < Azure::Core::Http::RetryPolicy
      def initialize
        super &:should_retry?
      end
      def should_retry?(response, retry_data)
        retry_data[:error].inspect.include?('Error: Retry')
      end
    end

    class NewUriRetryPolicy < Azure::Core::Http::RetryPolicy
      def initialize
        @count = 1
        super &:should_retry?
      end

      def should_retry?(response, retry_data)
        retry_data[:uri] = URI.parse "http://bar.com"
        @count = @count - 1
        @count >= 0
      end
    end

  end
end
