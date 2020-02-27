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
require 'openssl'
require 'base64'

module Azure
  module Core
    module Auth
      # Utility class to sign strings with HMAC-256 and then encode the
      # signed string using Base64.
      class Signer
        # The access key for the account
        attr :access_key

        # Initialize the Signer.
        #
        # @param access_key [String] The access_key encoded in Base64.
        def initialize(access_key)
          if access_key.nil?
            raise ArgumentError, 'Signing key must be provided'
          end

          @access_key = Base64.decode64(access_key)
        end

        # Generate an HMAC signature.
        #
        # @param body [String] The string to sign.
        #
        # @return [String] a Base64 String signed with HMAC.
        def sign(body)
          signed = OpenSSL::HMAC.digest('sha256', access_key, body)
          Base64.strict_encode64(signed)
        end

      end
    end
  end
end
