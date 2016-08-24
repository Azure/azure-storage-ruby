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
    module Core
      autoload :HttpClient,                     'azure/storage/core/http_client'
      autoload :Utility,                        'azure/storage/core/utility'
      autoload :Logger,                         'azure/storage/core/utility'
      autoload :Error,                          'azure/storage/core/error'
      
      module Auth
        autoload :SharedKey,                    'azure/storage/core/auth/shared_key.rb'
        autoload :SharedAccessSignature,        'azure/storage/core/auth/shared_access_signature_generator.rb'
        autoload :SharedAccessSignatureSigner,  'azure/storage/core/auth/shared_access_signature_signer.rb'
      end
      
      module Filter
        autoload :RetryPolicyFilter,            'azure/storage/core/filter/retry_filter'
        autoload :LinearRetryPolicyFilter,      'azure/storage/core/filter/linear_retry_filter'
        autoload :ExponentialRetryPolicyFilter, 'azure/storage/core/filter/exponential_retry_filter'
      end
    end
  end
end