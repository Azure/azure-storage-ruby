require "test_helper"

describe Azure::Storage::Core::HttpClient do
  subject { Azure::Storage }

  let :uri do
    URI("https://management.core.windows.net")
  end

  describe "#agents" do

    describe "ssl vs non ssl uris" do
      it "should set verify true if using ssl" do
        Azure::Storage.client.agents(uri).ssl[:verify].must_equal true
      end

      it "should not set ssl if not using ssl" do
        Azure::Storage.client.agents("http://localhost").ssl.must_be_empty
      end
    end

    describe "when using a http proxy" do
      let(:http_proxy_uri) { URI("http://localhost:80") }

      before do
        ENV["HTTP_PROXY"] = http_proxy_uri.to_s
      end

      after do
        ENV["HTTP_PROXY"] = nil
      end

      it "should set the proxy configuration information on the http connection" do
        Azure::Storage::Client.create().agents(uri).proxy.uri.must_equal http_proxy_uri
      end
    end

    describe "when using a https proxy" do
      let(:https_proxy_uri) { URI("https://localhost:443") }

      before do
        ENV["HTTPS_PROXY"] = https_proxy_uri.to_s
      end

      after do
        ENV["HTTPS_PROXY"] = nil
      end

      it "should set the proxy configuration information on the https connection" do
        Azure::Storage::Client.create().agents(uri).proxy.uri.must_equal https_proxy_uri
      end
    end
  end
end
