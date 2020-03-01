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

describe Azure::Storage::Queue::QueueService do
  subject { Azure::Storage::Queue::QueueService.create(SERVICE_CREATE_OPTIONS()) }

  describe "#delete_queue" do
    let(:queue_name) { QueueNameHelper.name }
    before { subject.create_queue queue_name }
    after { QueueNameHelper.clean }

    it "deletes a queue and returns nil on success" do
      result = subject.delete_queue(queue_name)
      _(result).must_be_nil
      result = subject.list_queues
      result.each { |q| q.name.wont_equal queue_name }
    end

    it "errors on an non-existent queue" do
      assert_raises(Azure::Core::Http::HTTPError) do
        subject.delete_queue QueueNameHelper.name
      end
    end

    it "errors on an invalid queue" do
      assert_raises(Azure::Core::Http::HTTPError) do
        subject.delete_queue "this_queue.cannot-exist!"
      end
    end
  end
end
