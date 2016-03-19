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

          @access_key = Base64.strict_decode64(access_key)
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
