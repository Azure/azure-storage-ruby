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
require "adal"
require "azure/storage/common"
require "azure/storage/common/core/auth/shared_access_signature"
require "integration/test_helper"
require "net/http"

describe Azure::Storage::Common::Core::Auth::SharedAccessSignature do
  subject {
    tenant_id = ENV.fetch("AZURE_TENANT_ID", nil)
    client_id = ENV.fetch("AZURE_CLIENT_ID", nil)
    client_secret = ENV.fetch("AZURE_CLIENT_SECRET", nil)
    storage_account_name = SERVICE_CREATE_OPTIONS()[:storage_account_name]

    if tenant_id.nil? || client_id.nil? || client_secret.nil?
      skip "AAD credentials not provided"
    end

    auth_ctx = ADAL::AuthenticationContext.new("login.microsoftonline.com", tenant_id)
    client_cred = ADAL::ClientCredential.new(client_id, client_secret)
    token = auth_ctx.acquire_token_for_client("https://storage.azure.com/", client_cred)
    access_token = token.access_token

    token_credential = Azure::Storage::Common::Core::TokenCredential.new access_token
    token_signer = Azure::Storage::Common::Core::Auth::TokenSigner.new token_credential
    client = Azure::Storage::Common::Client::create(storage_account_name: storage_account_name, signer: token_signer)
    Azure::Storage::Blob::BlobService.new(api_version: "2018-11-09", client: client)
  }

  let(:generator) {
    user_delegation_key = subject.get_user_delegation_key(Time.now - 60 * 5, Time.now + 60 * 15)
    storage_account_name = SERVICE_CREATE_OPTIONS()[:storage_account_name]

    Azure::Storage::Common::Core::Auth::SharedAccessSignature.new(storage_account_name, "", user_delegation_key)
  }

  describe "#blob_service_sas_for_container" do
    let(:container_name) { ContainerNameHelper.name }
    let(:block_blob_name) { BlobNameHelper.name }
    let(:content) { content = ""; 512.times.each { |i| content << "@" }; content }

    before {
      subject.create_container container_name
      subject.create_block_blob container_name, block_blob_name, content
    }

    after { ContainerNameHelper.clean }

    it "fetches blob from sas uri" do
      uri = generator.signed_uri(subject.generate_uri("#{container_name}/#{block_blob_name}"), false, service: "b", permissions: "r", expiry: (Time.now.utc + 60 * 10).iso8601)
      _(Net::HTTP.get(uri)).must_equal content
    end
  end
end
