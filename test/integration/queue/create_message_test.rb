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

  describe "#create_message" do
    let(:queue_name) { QueueNameHelper.name }
    let(:message_text) { "message text random value: #{QueueNameHelper.name}" }
    before { subject.create_queue queue_name }
    after { QueueNameHelper.clean }

    it "creates a message in the specified queue and returns nil on success" do
      result = subject.create_message(queue_name, message_text)
      result.wont_be_nil
      result.wont_be_empty
      result.length.must_equal 1
      result[0].message_text.must_be_nil
      result[0].pop_receipt.wont_be_nil
      result[0].id.wont_be_nil

      result = subject.peek_messages queue_name
      result.wont_be_nil
      result.wont_be_empty
      result.length.must_equal 1
      result[0].message_text.must_equal message_text
    end

    describe "when the options hash is used" do
      let(:visibility_timeout) { 3 }
      let(:message_ttl) { 600 }

      it "the :visibility_timeout option causes the message to be invisible for a period of time" do
        result = subject.create_message(queue_name, message_text, visibility_timeout: visibility_timeout)
        result.wont_be_nil
        result.wont_be_empty
        result.length.must_equal 1
        result[0].message_text.must_be_nil
        result[0].pop_receipt.wont_be_nil
        result[0].id.wont_be_nil

        result = subject.peek_messages queue_name
        result.length.must_equal 0
        sleep(visibility_timeout)

        result = subject.peek_messages queue_name
        result.length.must_equal 1
        result.wont_be_empty
        result[0].message_text.must_equal message_text
      end

      it "the :message_ttl option modifies the expiration_date of the message" do
        result = subject.create_message(queue_name, message_text, message_ttl: message_ttl)
        result.wont_be_nil
        result.wont_be_empty
        result.length.must_equal 1
        result[0].message_text.must_be_nil
        result[0].pop_receipt.wont_be_nil
        result[0].id.wont_be_nil

        result = subject.peek_messages queue_name
        result.wont_be_nil
        result.wont_be_empty
        message = result[0]
        message.message_text.must_equal message_text
        Time.parse(message.expiration_time).to_i.must_equal Time.parse(message.insertion_time).to_i + message_ttl
      end
    end

    it "errors on an non-existent queue" do
      assert_raises(Azure::Core::Http::HTTPError) do
        subject.create_message QueueNameHelper.name, message_text
      end
    end
  end
end
