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
require "integration/test_helper"
require "azure/storage/table/table_service"
require "azure/core/http/http_error"

describe Azure::Storage::Table::TableService do
  describe "#get_table" do
    subject { Azure::Storage::Table::TableService.new }
    let(:table_name) { TableNameHelper.name }
    before { subject.create_table table_name }
    after { TableNameHelper.clean }

    it "gets the last updated time of a valid table" do
      result = subject.get_table table_name
      result.must_be_kind_of Hash
      result["TableName"].must_equal table_name
    end

    it "errors on an invalid table" do
      assert_raises(Azure::Core::Http::HTTPError) do
         subject.get_table "this_table.cannot-exist!"
       end
    end
  end
end
