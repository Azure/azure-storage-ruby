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
  subject { Azure::Storage::Queue::QueueService.create(SERVICE_CREATE_OPTIONS()) }

  describe "#informative_errors_queue" do
    let(:queue_name) { QueueNameHelper.name }
    after { QueueNameHelper.clean }

    it "exception message should be valid" do
      # getting metadata from a non existent should throw
      begin
        subject.get_queue_metadata queue_name
        flunk "No exception"
      rescue Azure::Core::Http::HTTPError => error
        _(error.status_code).must_equal 404
        _(error.type).must_equal "QueueNotFound"
        _(error.description.start_with?("The specified queue does not exist.")).must_equal true
      end
    end
  end
end
