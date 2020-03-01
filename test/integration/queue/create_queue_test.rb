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
require "azure/core/http/http_error"

describe Azure::Storage::Queue::QueueService do
  let(:user_agent_prefix) { "azure_storage_ruby_integration_test" }
  subject {
    Azure::Storage::Queue::QueueService.create(SERVICE_CREATE_OPTIONS()) { |headers|
      headers["User-Agent"] = "#{user_agent_prefix}; #{headers['User-Agent']}"
    }
  }

  describe "#create_queue" do
    let(:queue_name) { QueueNameHelper.name }
    let(:metadata) { { "custommetadata" => "CustomMetadataValue" } }
    after { QueueNameHelper.clean }

    it "creates a queue with a valid name" do
      result = subject.create_queue queue_name
      _(result).must_be_nil
    end

    it "creates a queue with a valid name and metadata" do
      result = subject.create_queue queue_name, metadata: metadata
      _(result).must_be_nil

      message_count, queue_metadata = subject.get_queue_metadata queue_name

      metadata.each { |k, v|
        _(queue_metadata).must_include k
        _(queue_metadata[k]).must_equal v
      }
    end

    it "errors on an invalid queue name" do
      assert_raises(Azure::Core::Http::HTTPError) do
        subject.create_queue "this_queue.cannot-exist!"
      end
    end
  end
end
