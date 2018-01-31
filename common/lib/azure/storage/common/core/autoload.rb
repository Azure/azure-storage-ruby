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

module Azure
  module Storage
    module Common
      module Core
        autoload :HttpClient,                     "azure/storage/common/core/http_client"
        autoload :Utility,                        "azure/storage/common/core/utility"
        autoload :Logger,                         "azure/storage/common/core/utility"
        autoload :Error,                          "azure/storage/common/core/error"
        autoload :TokenCredential,                "azure/storage/common/core/token_credential.rb"

        module Auth
          autoload :SharedKey,                    "azure/storage/common/core/auth/shared_key.rb"
          autoload :SharedAccessSignature,        "azure/storage/common/core/auth/shared_access_signature_generator.rb"
          autoload :SharedAccessSignatureSigner,  "azure/storage/common/core/auth/shared_access_signature_signer.rb"
          autoload :AnonymousSigner,              "azure/storage/common/core/auth/anonymous_signer.rb"
          autoload :TokenSigner,                  "azure/storage/common/core/auth/token_signer.rb"
        end

        module Filter
          autoload :RetryPolicyFilter,            "azure/storage/common/core/filter/retry_filter"
          autoload :LinearRetryPolicyFilter,      "azure/storage/common/core/filter/linear_retry_filter"
          autoload :ExponentialRetryPolicyFilter, "azure/storage/common/core/filter/exponential_retry_filter"
        end
      end
    end
  end
end
