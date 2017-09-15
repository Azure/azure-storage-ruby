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
  subject { Azure::Storage::Queue::QueueService.new }

  describe "#list_messages_encoded" do
    let(:queue_name) { QueueNameHelper.name }
    let(:message_text) { "some random text " + QueueNameHelper.name }
    before {
      subject.create_queue queue_name
      subject.create_message queue_name, message_text, encode: true
    }
    after { QueueNameHelper.clean }

    it "returns a message from the queue, marking it as invisible" do
      result = subject.list_messages queue_name, 3, decode: true
      result.wont_be_nil
      result.wont_be_empty
      result.length.must_equal 1
      message = result[0]
      message.message_text.must_equal message_text

      # queue should be empty
      result = subject.list_messages queue_name, 1, decode: true
      result.must_be_empty
    end

    it "returns multiple messages if passed the optional parameter" do
      msg_text2 = "some random text " + QueueNameHelper.name
      subject.create_message queue_name, msg_text2, encode: true

      result = subject.list_messages queue_name, 3, number_of_messages: 2, decode: true
      result.wont_be_nil
      result.wont_be_empty
      result.length.must_equal 2
      result[0].message_text.must_equal message_text
      result[1].message_text.must_equal msg_text2
      result[0].id.wont_equal result[1].id
    end

    it "the visibility_timeout parameter sets the message invisible for the period of time pending delete/update" do
      result = subject.list_messages queue_name, 3, decode: true
      result.wont_be_nil
      result.wont_be_empty
      result.length.must_equal 1
      message = result[0]
      message.message_text.must_equal message_text

      # queue should be empty
      result = subject.list_messages queue_name, 1, decode: true
      result.must_be_empty

      sleep(3)

      # same message is back at the top of the queue after timeout period
      result = subject.list_messages queue_name, 3, decode: true
      result.wont_be_nil
      result.wont_be_empty
      result.length.must_equal 1
      message2 = result[0]
      message2.id.must_equal message.id
    end
  end
end
