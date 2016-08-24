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

require 'azure/core/auth/signer'

module Azure::Storage::Core
  module Auth
    class SharedAccessSignatureSigner < Azure::Core::Auth::Signer

      attr :account_name, :sas_token

      # Public: Initialize the Signer with a SharedAccessSignature
      #
      # @param account_name [String] The account name. Defaults to the one in the global configuration.
      # @param sas_token [String]   The sas token to be used for signing
      def initialize(account_name=Azure::Storage.storage_account_name, sas_token=Azure::Storage.storage_sas_token)
        @account_name = account_name
        @sas_token = sas_token
      end

      def sign_request(req)
        req.uri = URI.parse(req.uri.to_s + (req.uri.query.nil? ? '?' : '&') + sas_token.sub(/^\?/,'') + '&api-version=' + Azure::Storage::Default::STG_VERSION)
      end

    end
  end
end
