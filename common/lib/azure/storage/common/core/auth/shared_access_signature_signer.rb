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

require "azure/core/auth/signer"

module Azure::Storage::Common::Core
  module Auth
    class SharedAccessSignatureSigner < Azure::Core::Auth::Signer
      attr :account_name, :sas_token
      attr_accessor :api_ver

      # Public: Initialize the Signer with a SharedAccessSignature
      #
      # @param api_ver      [String] The api version of the service.
      # @param account_name [String] The account name. Defaults to the one in the global configuration.
      # @param sas_token    [String] The sas token to be used for signing
      def initialize(api_ver, account_name = "", sas_token = "")
        if account_name.empty? || sas_token.empty?
          client = Azure::Storage::Common::Client.create_from_env
          account_name = client.storage_account_name if account_name.empty?
          sas_token = client.storage_sas_token if sas_token.empty?
        end
        @api_ver = api_ver
        @account_name = account_name
        @sas_token = sas_token
      end

      def sign_request(req)
        req.uri = URI.parse(req.uri.to_s + (req.uri.query.nil? ? "?" : "&") + sas_token.sub(/^\?/, "") + "&api-version=" + @api_ver)
        req
      end
    end
  end
end
