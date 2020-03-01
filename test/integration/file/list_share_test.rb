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

describe Azure::Storage::File::FileService do
  subject { Azure::Storage::File::FileService.create(SERVICE_CREATE_OPTIONS()) }
  after { ShareNameHelper.clean }

  describe "#list_shares" do
    let(:share_names) { [ShareNameHelper.name, ShareNameHelper.name, ShareNameHelper.name] }
    let(:metadata) { { "CustomMetadataProperty" => "CustomMetadataValue" } }
    before {
      share_names.each { |c|
        subject.create_share c, metadata: metadata
      }
    }

    it "lists the shares for the account" do
      result = subject.list_shares
      found = 0
      result.each { |c|
        found += 1 if share_names.include? c.name
      }
      _(found).must_equal share_names.length
    end

    it "lists the shares for the account with max results" do
      result = subject.list_shares(max_results: 1)
      _(result.length).must_equal 1
      first_share = result[0]
      result.continuation_token.wont_equal("")

      result = subject.list_shares(max_results: 2, marker: result.continuation_token)
      _(result.length).must_equal 2
      result[0].name.wont_equal first_share.name
    end

    it "returns metadata if the :metadata=>true option is used" do
      result = subject.list_shares(metadata: true)

      found = 0
      result.each { |c|
        if share_names.include? c.name
          found += 1
          metadata.each { |k, v|
            _(c.metadata).must_include k.downcase
            _(c.metadata[k.downcase]).must_equal v
          }
        end
      }
      _(found).must_equal share_names.length
    end
  end
end
