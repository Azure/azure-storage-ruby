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
require "azure/storage/common"

describe Azure::Storage::Common::Core::TokenCredential do

  describe "when create token credentials" do

    it "should be able to refresh by several threads" do
      initial_token = "initial_access_token"
      token_credential = Azure::Storage::Common::Core::TokenCredential.new initial_token

      threads = []
      current = nil
      15.times do |i|
        threads[i] = Thread.new do
          sleep(rand(0)/10.0)
          Thread.current["index"] = i
          token_credential.renew_token "refreshed_token_#{i}"
          current = i
        end
      end
      
      threads.each { |t| t.join }
      _(current).wont_be_nil
      _(token_credential.token).must_equal "refreshed_token_#{current}"
    end

  end
end
