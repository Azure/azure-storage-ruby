#-------------------------------------------------------------------------
# # Copyright (c) Microsoft and contributors. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#--------------------------------------------------------------------------

require 'azure/storage/core/auth/signer'

module Azure::Storage
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
        ori_uri = req.uri
        URI.parse(ori_uri.to_s + (ori_uri.query.nil? ? '?' : '&') + sas_token.sub(/^\?/,'') + '&api-version=' + Azure::Storage::Default::STG_VERSION)
      end

    end
  end
end
