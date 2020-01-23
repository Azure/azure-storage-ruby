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
require "test_helper"
require "azure/storage/common"
require "base64"
require "uri"

describe Azure::Storage::Common::Core::Auth::SharedAccessSignature do
  let(:path) { "example/path" }
  let(:service_type) { "blob" }
  let(:service_options) {
    {
      service:              "b",
      permissions:          "rwd",
      start:                "2020-12-10T00:00:00Z",
      expiry:               "2020-12-11T00:00:00Z",
      resource:             "b",
      protocol:             "https,http",
      ip_range:             "168.1.5.60-168.1.5.70",
      cache_control:        "public",
      content_disposition:  "inline, filename=nyan.cat",
      content_encoding:     "gzip",
      content_language:     "English",
      content_type:         "binary"
    }
  }
  let(:account_options) {
    {
      service:             "b",
      permissions:         "rwd",
      start:               "2020-12-10T00:00:00Z",
      expiry:              "2020-12-11T00:00:00Z",
      resource:            "b",
      protocol:            "https,http",
      ip_range:            "168.1.5.60-168.1.5.70"
    }
  }
  let(:access_account_name) { "account-name" }
  let(:access_key_base64) { Base64.strict_encode64("access-key") }

  subject { Azure::Storage::Common::Core::Auth::SharedAccessSignature.new(access_account_name, access_key_base64) }

  describe "#signable_string" do
    it "constructs a string for service in the required format" do
      _(subject.signable_string_for_service(service_type, path, service_options)).must_equal(
        "rwd\n#{Time.parse('2020-12-10T00:00:00Z').utc.iso8601}\n#{Time.parse('2020-12-11T00:00:00Z').utc.iso8601}\n" +
        "/blob/account-name/example/path\n\n168.1.5.60-168.1.5.70\nhttps,http\n#{Azure::Storage::Common::Default::STG_VERSION}\n" +
        "b\n\n" +
        "public\ninline, filename=nyan.cat\ngzip\nEnglish\nbinary"
      )
    end

    it "constructs a string for account in the required format" do
      _(subject.signable_string_for_account(account_options)).must_equal(
        "account-name\nrwd\nb\nb\n#{Time.parse('2020-12-10T00:00:00Z').utc.iso8601}\n#{Time.parse('2020-12-11T00:00:00Z').utc.iso8601}\n168.1.5.60-168.1.5.70\nhttps,http\n#{Azure::Storage::Common::Default::STG_VERSION}\n"
      )
    end
  end

  describe "#canonicalized_resource" do
    it "prefixes and concatenates account name and resource path with forward slashes" do
      _(subject.canonicalized_resource(service_type, path)).must_equal "/blob/account-name/example/path"
    end
  end

  describe "#signed_uri" do
    it "maps options to the abbreviated API versions for service" do
      uri = URI(subject.signed_uri(URI(path), false, service_options))
      query_hash = Hash[URI.decode_www_form(uri.query)]
      _(query_hash["sp"]).must_equal "rwd"
      _(query_hash["st"]).must_equal Time.parse("2020-12-10T00:00:00Z").utc.iso8601
      _(query_hash["se"]).must_equal Time.parse("2020-12-11T00:00:00Z").utc.iso8601
      _(query_hash["sr"]).must_equal "b"
      _(query_hash["sip"]).must_equal "168.1.5.60-168.1.5.70"
      _(query_hash["spr"]).must_equal "https,http"
      _(query_hash["rscc"]).must_equal "public"
      _(query_hash["rscd"]).must_equal "inline, filename=nyan.cat"
      _(query_hash["rsce"]).must_equal "gzip"
      _(query_hash["rscl"]).must_equal "English"
      _(query_hash["rsct"]).must_equal "binary"
    end

    it "maps options to the abbreviated API versions for account" do
      uri = URI(subject.signed_uri(URI(path), true, account_options))
      query_hash = Hash[URI.decode_www_form(uri.query)]
      _(query_hash["ss"]).must_equal "b"
      _(query_hash["srt"]).must_equal "b"
      _(query_hash["sp"]).must_equal "rwd"
      _(query_hash["st"]).must_equal Time.parse("2020-12-10T00:00:00Z").utc.iso8601
      _(query_hash["se"]).must_equal Time.parse("2020-12-11T00:00:00Z").utc.iso8601
      _(query_hash["sip"]).must_equal "168.1.5.60-168.1.5.70"
      _(query_hash["spr"]).must_equal "https,http"
    end

    it "correctly maps service type when given full blob url and no service" do
      blob_url = File.join("https://#{access_account_name}.blob.core.windows.net", path)
      uri = URI(subject.signed_uri(URI(blob_url), true, account_options.merge(service: nil)))
      query_hash = Hash[URI.decode_www_form(uri.query)]
      _(query_hash["ss"]).must_equal "b"
      _(query_hash["srt"]).must_equal "b"
    end
  end
end
