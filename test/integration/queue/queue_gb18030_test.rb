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
require "azure/storage/blob/blob_service"

describe "Queue GB-18030" do
  subject { Azure::Storage::Queue::QueueService.create(SERVICE_CREATE_OPTIONS()) }

  let(:queue_name) { QueueNameHelper.name }

  before {
    subject.create_queue queue_name
  }

  it "Read/Write Queue Name UTF-8" do
    # Expected results: Failure, because the Queue
    # name can only contain ASCII
    # characters, per the Queue Service spec.
    GB18030TestStrings.get.each { |k, v|
      begin
        subject.create_queue queue_name + v.encode("UTF-8")
        flunk "No exception"
      rescue
        # Add validation?
      end
    }
  end

  it "Read/Write Queue Name GB-18030" do
    # Expected results: Failure, because the Queue
    # name can only contain ASCII
    # characters, per the Queue Service spec.
    GB18030TestStrings.get.each { |k, v|
      begin
        subject.create_queue queue_name + v.encode("GB18030")
        flunk "No exception"
      rescue
        # Add validation?
      end
    }
  end

  it "Read/Write Queue Metadata UTF-8 key" do
    GB18030TestStrings.get.each { |k, v|
      begin
        metadata = { "custommetadata" + v.encode("UTF-8") => "CustomMetadataValue" }
        subject.set_queue_metadata queue_name, metadata
        flunk "No exception"
      rescue Azure::Core::Http::HTTPError => error
        _(error.status_code).must_equal 400
      end
    }
  end

  it "Read/Write Queue Metadata GB-18030 key" do
    GB18030TestStrings.get.each { |k, v|
      begin
        metadata = { "custommetadata" + v.encode("GB18030") => "CustomMetadataValue" }
        subject.set_queue_metadata queue_name, metadata
        flunk "No exception"
      rescue Azure::Core::Http::HTTPError => error
        _(error.status_code).must_equal 400
      end
    }
  end

  it "Read/Write Queue Metadata UTF-8 value" do
    GB18030TestStrings.get.each { |k, v|
      begin
        metadata = { "custommetadata" => "CustomMetadataValue" + v.encode("UTF-8") }
        subject.set_queue_metadata queue_name, metadata
        flunk "No exception"
      rescue Azure::Core::Http::HTTPError => error
        # TODO: Error should really be 400
        _(error.status_code).must_equal 403
      end
    }
  end

  it "Read/Write Queue Metadata GB-18030 value" do
    GB18030TestStrings.get.each { |k, v|
      begin
        metadata = { "custommetadata" => "CustomMetadataValue" + v.encode("GB18030") }
        subject.set_queue_metadata queue_name, metadata
        flunk "No exception"
      rescue Azure::Core::Http::HTTPError => error
        # TODO: Error should really be 400
        _(error.status_code).must_equal 403
      end
    }
  end

  it "Read/Write Queue Content UTF-8" do
    GB18030TestStrings.get.each { |k, v|
      content = v.encode("UTF-8")
      subject.create_message queue_name, content
      messages = subject.list_messages queue_name, 500
      message = messages.first
      returned_content = message.message_text
      _(returned_content).must_equal content
      subject.delete_message queue_name, message.id, message.pop_receipt
    }
  end

  # Fails because of
  # https://github.com/appfog/azure-sdk-for-ruby/issues/295
  it "Read/Write Queue Content GB18030" do
    GB18030TestStrings.get.each { |k, v|
      content = v.encode("GB18030")
      subject.create_message queue_name, content
      messages = subject.list_messages queue_name, 500
      message = messages.first
      returned_content = message.message_text
      _(returned_content.encode("UTF-8")).must_equal content.encode("UTF-8")
      subject.delete_message queue_name, message.id, message.pop_receipt
    }
  end

end
