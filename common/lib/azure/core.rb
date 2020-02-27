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

require 'rubygems'
require 'nokogiri'
require 'faraday'
require 'faraday_middleware'

module Azure
  module Core
    autoload :Utility,                        'azure/core/utility'
    autoload :Logger,                         'azure/core/utility'
    autoload :Error,                          'azure/core/error'
    autoload :Service,                        'azure/core/service'
    autoload :FilteredService,                'azure/core/filtered_service'
    autoload :SignedService,                  'azure/core/signed_service'
    autoload :Default,                        'azure/core/default'
    module Auth
      autoload :SharedKey,                    'azure/core/auth/shared_key'
      autoload :Signer,                       'azure/core/auth/signer'
      autoload :Authorizer,                   'azure/core/auth/authorizer'
      autoload :SharedKeyLite,                'azure/core/auth/shared_key_lite'
    end
    module Http
      autoload :DebugFilter,                  'azure/core/http/debug_filter'
      autoload :HTTPError,                    'azure/core/http/http_error'
      autoload :HttpFilter,                   'azure/core/http/http_filter'
      autoload :HttpRequest,                  'azure/core/http/http_request'
      autoload :HttpResponse,                 'azure/core/http/http_response'
      autoload :RetryPolicy,                  'azure/core/http/retry_policy'
      autoload :SignerFilter,                 'azure/core/http/signer_filter'
    end
  end

end
