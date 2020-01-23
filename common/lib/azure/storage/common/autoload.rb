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

require "rubygems"
require "nokogiri"
require "base64"
require "openssl"
require "uri"
require "faraday"
require "faraday_middleware"

require "azure/storage/common/core/autoload"
require "azure/storage/common/default"

module Azure
  module Storage
    autoload :Common,                       "azure/storage/common/core"
    module Common
      autoload :Default,                    "azure/storage/common/default"
      autoload :Configurable,               "azure/storage/common/configurable"
      autoload :Client,                     "azure/storage/common/client"
      autoload :ClientOptions,              "azure/storage/common/client_options"

      module Auth
        autoload :SharedAccessSignature,    "azure/storage/common/core/auth/shared_access_signature"
      end

      module Service
        autoload :Serialization,            "azure/storage/common/service/serialization"
        autoload :SignedIdentifier,         "azure/storage/common/service/signed_identifier"
        autoload :AccessPolicy,             "azure/storage/common/service/access_policy"
        autoload :StorageService,           "azure/storage/common/service/storage_service"
        autoload :CorsRule,                 "azure/storage/common/service/cors_rule"
        autoload :EnumerationResults,       "azure/storage/common/service/enumeration_results"
        autoload :UserDelegationKey,        "azure/storage/common/service/user_delegation_key"
      end
    end
  end
end
