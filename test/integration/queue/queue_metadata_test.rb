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
  describe "#set/get_queue_metadata" do
    let(:queue_name) { QueueNameHelper.name }
    before {
      subject.create_queue queue_name
      subject.create_message queue_name, "some random text " + QueueNameHelper.name
    }
    after { QueueNameHelper.clean }

    it "can set and retrieve queue metadata" do
      result = subject.set_queue_metadata queue_name, "CustomMetadataProperty" => "Custom Metadata Value"
      _(result).must_be_nil

      message_count, metadata = subject.get_queue_metadata queue_name
      _(message_count).must_equal 1

      # note: case insensitive! even though it was sent in mixed case, it will be returned in downcase
      _(metadata).must_include "custommetadataproperty"
      _(metadata["custommetadataproperty"]).must_equal "Custom Metadata Value"
    end
  end
end
