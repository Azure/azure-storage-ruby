require "unit/test_helper"

describe Azure::Storage::Common::Core::HttpClient do
  subject { Azure::Storage }

  let(:uri) { URI("https://management.core.windows.net") }
  let(:proxy_uri) { URI("http://localhost:3128") }

  describe "#agents" do
    describe "reusing a connection when connecting to the same host" do
      let(:client) { Azure::Storage::Common::Client::create }

      it "should use the same connection when reconnecting to the same host" do
        uri1 = URI("https://management.core.windows.net/uri1")
        uri2 = URI("https://management.core.windows.net/uri2")

        agent1 = client.agents(uri1)
        agent2 = client.agents(uri2)

        _(agent1).must_equal agent2
      end
    end

    describe "ssl vs non ssl uris" do
      it "should set verify true if using ssl" do
        _(Azure::Storage::Common::Client::create.agents(uri).ssl[:verify]).must_equal true
      end

      it "should not set ssl if not using ssl" do
        _(Azure::Storage::Common::Client::create.agents("http://localhost").ssl).must_be_empty
      end
    end

    describe "when using a http proxy" do
      before do
        ENV["HTTP_PROXY"] = proxy_uri.to_s
      end

      after do
        ENV["HTTP_PROXY"] = nil
      end

      it "should not set the proxy configuration information if only a http is configured" do
        _(Azure::Storage::Common::Client::create.agents(uri).proxy).must_be_nil
      end
    end

    describe "when using a https proxy" do
      before do
        ENV["HTTPS_PROXY"] = proxy_uri.to_s
      end

      after do
        ENV["HTTPS_PROXY"] = nil
      end

      it "should set the proxy configuration information on the https connection" do
        _(Azure::Storage::Common::Client::create.agents(uri).proxy.uri).must_equal proxy_uri
      end
    end

    describe "when using a https proxy with no_proxy containing the URL" do
      let(:https_proxy_uri) { URI("http://localhost:3128") }

      before do
        ENV["HTTPS_PROXY"] = https_proxy_uri.to_s
        ENV["NO_PROXY"] = "localhost,.windows.net"
      end

      after do
        ENV["HTTPS_PROXY"] = nil
        ENV["NO_PROXY"] = nil
      end

      it "should not set the proxy configuration because of the NO_PROXY" do
        _(Azure::Storage::Common::Client::create.agents(uri).proxy).must_be_nil
      end
    end

    describe "when using a https proxy with no_proxy that doesn't contain the URL" do
      before do
        ENV["HTTPS_PROXY"] = proxy_uri.to_s
        ENV["NO_PROXY"] = "localhost,.microsoft.net"
      end

      after do
        ENV["HTTPS_PROXY"] = nil
        ENV["NO_PROXY"] = nil
      end

      it "should not set the proxy configuration because of the NO_PROXY" do
        _(Azure::Storage::Common::Client::create.agents(uri).proxy.uri).must_equal proxy_uri
      end
    end
  end
end
