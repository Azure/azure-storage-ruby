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
require 'integration/test_helper'
require 'azure/storage/core/auth/shared_access_signature'

describe Azure::Storage::Core::Auth::SharedAccessSignature do
  subject { Azure::Storage::Queue::QueueService.new }
  let(:generator) { Azure::Storage::Core::Auth::SharedAccessSignature.new }
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

  it 'reads a message in the queue with a SAS in connection string' do
    sas_token = generator.generate_service_sas_token queue_name, { service: 'q', permissions: 'r', protocol: 'https,http' }
    connection_string = "QueueEndpoint=https://#{ENV['AZURE_STORAGE_ACCOUNT']}.queue.core.windows.net;SharedAccessSignature=#{sas_token}"
    sas_client = Azure::Storage::Client::create_from_connection_string connection_string
    client = sas_client.queue_client
    message = client.peek_messages queue_name, { number_of_messages: 2 }
    message.wont_be_nil
    assert message.length > 1
  end

  it 'reads a message in the queue with a SAS' do
    sas_token = generator.generate_service_sas_token queue_name, { service: 'q', permissions: 'r', protocol: 'https,http' }
    signer = Azure::Storage::Core::Auth::SharedAccessSignatureSigner.new Azure::Storage.storage_account_name, sas_token
    client = Azure::Storage::Queue::QueueService.new(signer: signer)
    message = client.peek_messages queue_name, { number_of_messages: 2 }
    message.wont_be_nil
    assert message.length > 1
  end

  it 'adds a message to the queue with a SAS' do
    sas_token = generator.generate_service_sas_token queue_name, { service: 'q', permissions: 'a', protocol: 'https' }
    signer = Azure::Storage::Core::Auth::SharedAccessSignatureSigner.new Azure::Storage.storage_account_name, sas_token
    client = Azure::Storage::Queue::QueueService.new(signer: signer)
    result = client.create_message queue_name, message_3
    result.must_be_nil
  end

  it 'processes and updates a message to the queue with a SAS' do
    sas_token = generator.generate_service_sas_token queue_name, { service: 'q', permissions: 'up', protocol: 'https,http' }
    signer = Azure::Storage::Core::Auth::SharedAccessSignatureSigner.new Azure::Storage.storage_account_name, sas_token
    client = Azure::Storage::Queue::QueueService.new(signer: signer)
    message = client.list_messages queue_name, 10
    new_pop_receipt, time_next_visible = client.update_message queue_name, message[0].id, message[0].pop_receipt, 'updated message', 10
    new_pop_receipt.wont_be_nil
    time_next_visible.wont_be_nil
  end

  it 'deletes a message in the queue with a SAS' do
    sas_token = generator.generate_service_sas_token queue_name, { service: 'q', permissions: 'p', protocol: 'https,http' }
    signer = Azure::Storage::Core::Auth::SharedAccessSignatureSigner.new Azure::Storage.storage_account_name, sas_token
    client = Azure::Storage::Queue::QueueService.new(signer: signer)
    message = client.list_messages queue_name, 10
    client.delete_message queue_name, message[0].id, message[0].pop_receipt
  end
end
