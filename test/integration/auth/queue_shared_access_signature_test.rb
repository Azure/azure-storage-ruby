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
require "azure/storage/common/core/auth/shared_access_signature"

describe Azure::Storage::Common::Core::Auth::SharedAccessSignature do
  subject { Azure::Storage::Queue::QueueService.create(SERVICE_CREATE_OPTIONS()) }
  let(:generator) { Azure::Storage::Common::Core::Auth::SharedAccessSignature.new(SERVICE_CREATE_OPTIONS()[:storage_account_name], SERVICE_CREATE_OPTIONS()[:storage_access_key]) }
  let(:names_generator) { NameGenerator.new }
  let(:queue_name) { QueueNameHelper.name }
  let(:message_1) { names_generator.name }
  let(:message_2) { names_generator.name }
  let(:message_3) { names_generator.name }
  before {
    subject.create_queue queue_name
    subject.create_message queue_name, message_1
    subject.create_message queue_name, message_2
  }
  after { QueueNameHelper.clean }

  it "reads a message in the queue with a SAS in connection string" do
    sas_token = generator.generate_service_sas_token queue_name, service: "q", permissions: "r", protocol: "https,http"
    connection_string = "QueueEndpoint=https://#{SERVICE_CREATE_OPTIONS()[:storage_account_name]}.queue.core.windows.net;SharedAccessSignature=#{sas_token}"
    client = Azure::Storage::Queue::QueueService::create_from_connection_string connection_string
    message = client.peek_messages queue_name, number_of_messages: 2
    _(message).wont_be_nil
    assert message.length > 1
  end

  it "reads a message in the queue with a SAS" do
    sas_token = generator.generate_service_sas_token queue_name, service: "q", permissions: "r", protocol: "https,http"
    client = Azure::Storage::Queue::QueueService.new({ storage_account_name: SERVICE_CREATE_OPTIONS()[:storage_account_name], storage_sas_token: sas_token })
    message = client.peek_messages queue_name, number_of_messages: 2
    _(message).wont_be_nil
    assert message.length > 1
  end

  it "adds a message to the queue with a SAS" do
    sas_token = generator.generate_service_sas_token queue_name, service: "q", permissions: "a", protocol: "https"
    client = Azure::Storage::Queue::QueueService.new({ storage_account_name: SERVICE_CREATE_OPTIONS()[:storage_account_name], storage_sas_token: sas_token })
    result = client.create_message queue_name, message_3
    _(result).wont_be_nil
    result.wont_be_empty
    _(result.length).must_equal 1
    _(result[0].message_text).must_be_nil
    _(result[0].pop_receipt).wont_be_nil
    _(result[0].id).wont_be_nil
  end

  it "processes and updates a message to the queue with a SAS" do
    sas_token = generator.generate_service_sas_token queue_name, service: "q", permissions: "up", protocol: "https,http"
    client = Azure::Storage::Queue::QueueService.new({ storage_account_name: SERVICE_CREATE_OPTIONS()[:storage_account_name], storage_sas_token: sas_token })
    message = client.list_messages queue_name, 10
    new_pop_receipt, time_next_visible = client.update_message queue_name, message[0].id, message[0].pop_receipt, "updated message", 10
    _(new_pop_receipt).wont_be_nil
    _(time_next_visible).wont_be_nil
  end

  it "deletes a message in the queue with a SAS" do
    sas_token = generator.generate_service_sas_token queue_name, service: "q", permissions: "p", protocol: "https,http"
    client = Azure::Storage::Queue::QueueService.new({ storage_account_name: SERVICE_CREATE_OPTIONS()[:storage_account_name], storage_sas_token: sas_token })
    message = client.list_messages queue_name, 10
    client.delete_message queue_name, message[0].id, message[0].pop_receipt
  end
end
