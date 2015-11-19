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
require 'azure/storage/core/filtered_service'
require 'azure/storage/core/http/signer_filter'
require 'azure/storage/core/auth/shared_key'

module Azure
  module Core
    # A base class for Service implementations
    class SignedService < FilteredService

      # Create a new instance of the SignedService
      #
      # @param signer         [Azure::Core::Auth::Signer]. An implementation of Signer used for signing requests. (optional, Default=Azure::Storage::Auth::SharedKey.new)
      # @param account_name   [String] The account name (optional, Default=Azure::Storage.config.storage_account_name)
      # @param options        [Hash] options
      def initialize(signer=nil, account_name=nil, options={})
        super('', options)
        signer ||= Azure::Storage::Auth::SharedKey.new(client.storage_account_name, client.storage_access_key)
        @account_name = account_name || client.storage_account_name
        @signer = signer
        filters.unshift Core::Http::SignerFilter.new(signer) if signer
      end

      attr_accessor :account_name
      attr_accessor :signer

      def call(method, uri, body=nil, headers=nil)
        super(method, uri, body, headers)
      end
    end
  end
end