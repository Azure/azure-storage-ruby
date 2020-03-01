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
require "azure/core/http/http_error"
require "integration/test_helper"

describe Azure::Storage::File::FileService do
  subject { Azure::Storage::File::FileService.create(SERVICE_CREATE_OPTIONS()) }
  after { ShareNameHelper.clean }

  describe "#create_share" do
    let(:share_name) { ShareNameHelper.name }

    it "creates the share" do
      share = subject.create_share share_name
      _(share.name).must_equal share_name
    end

    it "creates the share with custom metadata" do
      metadata = { "CustomMetadataProperty" => "CustomMetadataValue" }
      share = subject.create_share share_name, metadata: metadata

      _(share.name).must_equal share_name
      _(share.metadata).must_equal metadata
      share = subject.get_share_metadata share_name

      metadata.each { |k, v|
        _(share.metadata).must_include k.downcase
        _(share.metadata[k.downcase]).must_equal v
      }
    end

    it "errors if the share already exists" do
      subject.create_share share_name

      assert_raises(Azure::Core::Http::HTTPError) do
        subject.create_share share_name
      end
    end

    it "errors if the share name is invalid" do
      assert_raises(Azure::Core::Http::HTTPError) do
        subject.create_share "this_share.cannot-exist!"
      end
    end
  end
end
