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

describe Azure::Storage do

  before do
    @account_name = "mockaccount"
    @access_key = "YWNjZXNzLWtleQ=="

    @account_key_options = {
      storage_account_name: @account_name,
      storage_access_key: @access_key
    }

    @removed = clear_storage_envs
    set_storage_envs(@account_key_options)
  end

  it "should setup a singleton by calling setup" do
    client = Azure::Storage.client
    client.wont_be_nil
    client.storage_account_name.must_equal(@account_name)
  end

  it "should delegate class methods to Azure::Storage::Client" do
    class Azure::Storage::Client
      def mock_method
        "hehe"
      end
    end

    Azure::Storage.mock_method.must_equal("hehe")
  end

  after do
    restore_storage_envs(@removed)
  end
end
