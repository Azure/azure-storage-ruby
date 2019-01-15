# frozen_string_literal: true

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
module Azure::Storage
  module Queue
    module Serialization
      include Azure::Storage::Common::Service::Serialization

      def self.queue_messages_from_xml(xml, decode)
        xml = slopify(xml)

        expect_node("QueueMessagesList", xml)
        results = []
        return results unless (xml > "QueueMessage").any?

        if xml.QueueMessage.count == 0
          results.push(queue_message_from_xml(xml.QueueMessage, decode))
        else
          xml.QueueMessage.each { |message_node|
            results.push(queue_message_from_xml(message_node, decode))
          }
        end

        results
      end

      def self.queue_message_from_xml(xml, decode)
        xml = slopify(xml)
        expect_node("QueueMessage", xml)

        Message.new do |msg|
          msg.id = xml.MessageId.text if (xml > "MessageId").any?
          msg.insertion_time = xml.InsertionTime.text if (xml > "InsertionTime").any?
          msg.expiration_time = xml.ExpirationTime.text if (xml > "ExpirationTime").any?
          msg.dequeue_count = xml.DequeueCount.text.to_i if (xml > "DequeueCount").any?
          msg.message_text = xml.MessageText.text if (xml > "MessageText").any?
          msg.time_next_visible = xml.TimeNextVisible.text if (xml > "TimeNextVisible").any?
          msg.pop_receipt = xml.PopReceipt.text if (xml > "PopReceipt").any?

          msg.message_text = Base64.decode64(msg.message_text) if msg.message_text && decode
        end
      end

      def self.message_to_xml(message_text, encode)
        if encode
          builder = Nokogiri::XML::Builder.new do |xml|
            xml.QueueMessage { xml.MessageText Base64.strict_encode64(message_text) }
          end
        else
          builder = Nokogiri::XML::Builder.new(encoding: "utf-8") do |xml|
            xml.QueueMessage { xml.MessageText message_text.encode("utf-8") }
          end
        end
        builder.to_xml
      end

      def self.queue_enumeration_results_from_xml(xml)
        xml = slopify(xml)
        expect_node("EnumerationResults", xml)

        results = enumeration_results_from_xml(xml, Azure::Storage::Common::Service::EnumerationResults.new)

        return results unless (xml > "Queues").any? && ((xml > "Queues") > "Queue").any?

        if xml.Queues.Queue.count == 0
          results.push(queue_from_xml(xml.Queues.Queue))
        else
          xml.Queues.Queue.each { |queue_node|
            results.push(queue_from_xml(queue_node))
          }
        end

        results
      end

      def self.queue_from_xml(xml)
        xml = slopify(xml)
        expect_node("Queue", xml)

        queue = Queue.new
        queue.name = xml.Name.text if (xml > "Name").any?
        queue.metadata = metadata_from_xml(xml.Metadata) if (xml > "Metadata").any?

        queue
      end
    end
  end
end
