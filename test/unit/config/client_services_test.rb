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
require 'test_helper'

describe Azure::Storage::Client do

  describe 'create client with options' do
    let(:azure_storage_account) {"testStorageAccount"}
    let(:azure_storage_access_key) {"testKey1"}
    subject {Azure::Storage::Client.create(storage_account_name: azure_storage_account, storage_access_key: azure_storage_access_key)}

    it 'should create a blob client' do
      subject.storage_account_name.must_equal azure_storage_account
      subject.blobClient.host.must_equal "https://#{azure_storage_account}.blob.core.windows.net"
    end

    it 'should create a table client' do
      subject.storage_account_name.must_equal azure_storage_account
      subject.tableClient.host.must_equal "https://#{azure_storage_account}.table.core.windows.net"
    end
    
    it 'should create a queue client' do
      subject.storage_account_name.must_equal azure_storage_account
      subject.queueClient.host.must_equal "https://#{azure_storage_account}.queue.core.windows.net"
    end
  end
end
