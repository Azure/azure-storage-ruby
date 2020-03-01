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
require "azure/storage/queue/queue_service"

describe Azure::Storage::Queue::QueueService do
  subject { Azure::Storage::Queue::QueueService.create(SERVICE_CREATE_OPTIONS()) }

  describe "#peek_messages" do
    let(:queue_name) { QueueNameHelper.name }
    let(:message_text) { "some random text " + QueueNameHelper.name }
    before {
      subject.create_queue queue_name
      subject.create_message queue_name, message_text
    }
    after { QueueNameHelper.clean }

    it "returns a message from the queue without marking it as invisible" do
      result = subject.peek_messages queue_name
      _(result).wont_be_nil
      result.wont_be_empty
      _(result.length).must_equal 1
      message = result[0]
      _(message.message_text).must_equal message_text

      # the same message is returned on another call, because it's still at the top of the queue
      result = subject.peek_messages queue_name
      _(result).wont_be_nil
      result.wont_be_empty
      _(result.length).must_equal 1
      _(result[0].id).must_equal message.id
    end

    it "returns multiple messages if passed the optional parameter" do
      msg_text2 = "some random text " + QueueNameHelper.name
      subject.create_message queue_name, msg_text2

      result = subject.peek_messages queue_name, number_of_messages: 2
      _(result).wont_be_nil
      result.wont_be_empty
      _(result.length).must_equal 2
      _(result[0].message_text).must_equal message_text
      _(result[1].message_text).must_equal msg_text2
      result[0].id.wont_equal result[1].id
    end
  end
end
