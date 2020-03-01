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
require "unit/test_helper"
require "azure/storage/common"
require "azure/core/http/http_request"
require "azure/core/http/signer_filter"

describe Azure::Storage::Common::Service::StorageService do

  let(:uri) { URI.parse "http://dummy.uri/resource" }
  let(:verb) { :get }

  subject do
    storage_service = Azure::Storage::Common::Service::StorageService.new(nil, nil, { client: Azure::Storage::Common::Client.create_from_connection_string(ENV["AZURE_STORAGE_CONNECTION_STRING"]) })
    storage_service.storage_service_host[:primary] = "http://dumyhost.uri"
    storage_service.storage_service_host[:secondary] = "http://dumyhost-secondary.uri"
    storage_service
  end

  describe "#call" do
    let(:mock_request) { mock() }
    let(:mock_signer_filter) { mock() }
    let(:mock_headers) { {
        "Other-Header" => "SomeValue",
        "Custom-Header" => "PreviousValue",
        "connection" => "PreviousValue"
    } }

    before do
      Azure::Core::Http::HttpRequest.stubs(:new).with(verb, uri, anything).returns(mock_request)
      Azure::Core::Http::SignerFilter.stubs(:new).returns(mock_signer_filter)

      mock_request.expects(:call)
    end

    it "adds a client request id" do
      Azure::Core::Http::HttpRequest.stubs(:new).with(verb,
                                                      uri,
                                                      body: nil,
                                                      headers: { "x-ms-client-request-id" => "client-request-id" },
                                                      client: nil).returns(mock_request)
      mock_request.expects(:with_filter).with(mock_signer_filter, {})
      subject.call(verb, uri, nil, { request_id: "client-request-id" })
    end

    it "adds a SignerFilter to the HTTP pipeline" do
      mock_request.expects(:with_filter).with(mock_signer_filter, {})
      subject.call(verb, uri)
    end

    describe "when passed the optional headers arguement" do
      before do
        Azure::Core::Http::HttpRequest.stubs(:new).with(verb,
                                                        uri,
                                                        body: nil,
                                                        headers: { "Custom-Header" => "CustomValue" },
                                                        client: nil).returns(mock_request)
        mock_request.expects(:with_filter).with(mock_signer_filter, {})
      end

      it "passes the custom headers into the request initializer" do
        subject.call(verb, uri, nil, "Custom-Header" => "CustomValue")
      end
    end

    describe "when passed the optional body arguement" do
      before do
        mock_request.expects(:with_filter).with(mock_signer_filter, {})
      end

      it "passes the body to the to HttpRequest" do
        Azure::Core::Http::HttpRequest.stubs(:new).with(verb, uri, "body").returns(mock_request)
        subject.call(verb, uri, "body")
      end
    end

    describe "when with_filter was called" do
      before do
        mock_request.expects(:with_filter).with(mock_signer_filter, {})
      end

      it "builds the HTTP pipeline by passing the filters to the HTTPRequest" do
        filter = mock()
        filter1 = mock()

        subject.with_filter filter
        subject.with_filter filter1

        mock_request.expects(:with_filter).with(filter, {})
        mock_request.expects(:with_filter).with(filter1, {})

        subject.call(verb, uri)
      end
    end
  end

  describe "#with_filter" do
    it "appends filters to a list of filters that will be used in the #call method" do
      initial_length = subject.filters.length
      filter = mock()
      subject.with_filter filter
      _(subject.filters.length).must_equal initial_length + 1
    end

    it "accepts object instances as filters" do
      filter = mock()
      subject.with_filter filter
      _(subject.filters.last).must_equal filter
    end

    it "accepts blocks as filters" do
      subject.with_filter do |a, b|
      end
      _(subject.filters.last.class).must_equal Proc
    end

    it "preserves the order of the filters" do
      subject.filters = []

      filter = mock()
      filter1 = mock()

      subject.with_filter filter
      subject.with_filter filter1
      subject.with_filter do |a, b|
      end

      _(subject.filters.first).must_equal filter
      _(subject.filters[1]).must_equal filter1
      _(subject.filters.last.class).must_equal Proc
    end
  end

  describe "#get_service_properties" do
    let(:query) { {} }
    let(:service_properties_xml) { Fixtures["storage_service_properties"] }
    let(:service_properties) { Azure::Storage::Common::Service::StorageServiceProperties.new }
    let(:response) {
      response = mock()
      response.stubs(:body).returns(service_properties_xml)
      response
    }

    let(:service_properties_uri) { URI.parse "http://dummy.uri/service/properties" }

    before do
      Azure::Storage::Common::Service::Serialization.stubs(:service_properties_from_xml).with(service_properties_xml).returns(service_properties)
      subject.stubs(:service_properties_uri).with(query).returns(service_properties_uri)
      subject.stubs(:call).with(:get, service_properties_uri, nil, {}, {}).returns(response)
    end

    it "calls the service_properties_uri method to determine the correct uri" do
      subject.expects(:service_properties_uri).returns(service_properties_uri)
      subject.get_service_properties
    end

    it "gets the response from the HTTP API" do
      subject.expects(:call).with(:get, service_properties_uri, nil, {}, {}).returns(response)
      subject.get_service_properties
    end

    it "deserializes the response from xml" do
      Azure::Storage::Common::Service::Serialization.expects(:service_properties_from_xml).with(service_properties_xml).returns(service_properties)
      subject.get_service_properties
    end

    it "modifies the URI query parameters when provided a :timeout value" do
      query.update("timeout" => "30")
      subject.expects(:service_properties_uri).with(query).returns(service_properties_uri)

      options = { timeout: 30 }
      subject.expects(:call).with(:get, service_properties_uri, nil, {}, options).returns(response)
      subject.get_service_properties options
    end

    it "returns a StorageServiceProperties instance" do
      result = subject.get_service_properties
      _(result).must_be_kind_of Azure::Storage::Common::Service::StorageServiceProperties
    end
  end

  describe "#set_service_properties" do
    let(:query) { {} }
    let(:service_properties_xml) { Fixtures["storage_service_properties"] }
    let(:service_properties) { Azure::Storage::Common::Service::StorageServiceProperties.new }
    let(:response) {
      response = mock()
      response.stubs(:success?).returns(true)
      response
    }

    let(:service_properties_uri) { URI.parse "http://dummy.uri/service/properties" }

    before do
      Azure::Storage::Common::Service::Serialization.stubs(:service_properties_to_xml).with(service_properties).returns(service_properties_xml)
      subject.stubs(:service_properties_uri).with(query).returns(service_properties_uri)
      subject.stubs(:call).with(:put, service_properties_uri, service_properties_xml, {}, {}).returns(response)
    end

    it "calls the service_properties_uri method to determine the correct uri" do
      subject.expects(:service_properties_uri).returns(service_properties_uri)
      subject.set_service_properties service_properties
    end

    it "posts to the HTTP API" do
      subject.expects(:call).with(:put, service_properties_uri, service_properties_xml, {}, {}).returns(response)
      subject.set_service_properties service_properties
    end

    it "modifies the URI query parameters when provided a :timeout value" do
      query.update("timeout" => "30")
      subject.expects(:service_properties_uri).with(query).returns(service_properties_uri)

      options = { timeout: 30 }
      subject.expects(:call).with(:put, service_properties_uri, service_properties_xml, {}, options).returns(response)
      subject.set_service_properties service_properties, options
    end

    it "serializes the StorageServiceProperties object to xml" do
      Azure::Storage::Common::Service::Serialization.expects(:service_properties_to_xml).with(service_properties).returns(service_properties_xml)
      subject.set_service_properties service_properties
    end

    it "returns nil on success" do
      result = subject.set_service_properties service_properties
      assert_nil result
    end
  end

  describe "service_properties_uri" do
    it "returns an instance of URI" do
      _(subject.service_properties_uri).must_be_kind_of URI
    end

    it "uses the value of the host property as the base of the url" do
      _(subject.service_properties_uri.to_s).must_include subject.host
      subject.host = "http://something.else"
      _(subject.service_properties_uri.to_s).must_include subject.host
    end

    it "sets a query string that specifies the storage service properties endpoint" do
      _(subject.service_properties_uri.query).must_include "restype=service&comp=properties"
    end
  end

  describe "#get_service_stats" do
    let(:query) { {} }
    let(:service_stats_xml) { Fixtures["storage_service_stats"] }
    let(:service_stats) { Azure::Storage::Common::Service::StorageServiceStats.new }
    let(:options) {
      {
        location_mode: Azure::Storage::Common::LocationMode::SECONDARY_ONLY,
        request_location_mode: Azure::Storage::Common::RequestLocationMode::SECONDARY_ONLY
      }
    }
    let(:response) {
      response = mock()
      response.stubs(:body).returns(service_stats_xml)
      response
    }

    let(:service_stats_uri) { URI.parse "http://dummy.uri/service/stats" }

    before do
      Azure::Storage::Common::Service::Serialization.stubs(:service_stats_from_xml).with(service_stats_xml).returns(service_stats)
      subject.stubs(:service_stats_uri).with(query, options).returns(service_stats_uri)
      subject.stubs(:call).with(:get, service_stats_uri, nil, {}, options).returns(response)
    end

    it "calls the service_stats_uri method to determine the correct uri" do
      subject.expects(:service_stats_uri).with(query, options).returns(service_stats_uri)
      subject.get_service_stats
    end

    it "gets the response from the HTTP API" do
      subject.expects(:call).with(:get, service_stats_uri, nil, {}, options).returns(response)
      subject.get_service_stats
    end

    it "deserializes the response from xml" do
      Azure::Storage::Common::Service::Serialization.expects(:service_stats_from_xml).with(service_stats_xml).returns(service_stats)
      subject.get_service_stats
    end

    it "modifies the URI query parameters when provided a :timeout value" do
      timeout_option = { timeout: 30 } 
      query.update("timeout" => "30")
      call_options = timeout_option.merge options
      subject.expects(:service_stats_uri).with(query, call_options).returns(service_stats_uri)
      subject.expects(:call).with(:get, service_stats_uri, nil, {}, call_options).returns(response)
      subject.get_service_stats timeout_option
    end

    it "returns a StorageServiceStats instance" do
      result = subject.get_service_stats
      _(result).must_be_kind_of Azure::Storage::Common::Service::StorageServiceStats
    end
  end

  describe "service_stats_uri" do
    it "returns an instance of URI" do
      _(subject.service_stats_uri).must_be_kind_of URI
    end

    it "uses the value of the host property as the base of the url" do
      _(subject.service_stats_uri.to_s).must_include subject.host
      subject.host = "http://something.else"
      _(subject.service_stats_uri.to_s).must_include subject.host
    end

    it "sets a query string that specifies the storage service stats endpoint" do
      _(subject.service_stats_uri.query).must_include "restype=service&comp=stats"
    end
  end

  describe "#add_metadata_to_headers" do
    it "prefixes header names with x-ms-meta- but does not modify the values" do
      headers = {}
      Azure::Storage::Common::Service::StorageService.add_metadata_to_headers({ "Foo" => "Bar" }, headers)
      _(headers.keys).must_include "x-ms-meta-Foo"
      _(headers["x-ms-meta-Foo"]).must_equal "Bar"
    end

    it "updates any existing x-ms-meta-* headers with the new values" do
      headers = { "x-ms-meta-Foo" => "Foo" }
      Azure::Storage::Common::Service::StorageService.add_metadata_to_headers({ "Foo" => "Bar" }, headers)
      _(headers["x-ms-meta-Foo"]).must_equal "Bar"
    end
  end

  describe "#generate_uri" do
    it "returns a URI instance" do
      _(subject.generate_uri).must_be_kind_of ::URI
    end

    describe "when called with no arguments" do
      it "returns the StorageService host URL" do
        _(subject.generate_uri.to_s).must_equal "http://dumyhost.uri/"
      end
    end

    describe "when passed an optional path" do
      it "adds the path to the host url" do
        _(subject.generate_uri("resource/entity/").path).must_equal "/resource/entity/"
      end

      it "correctly joins the path if the host url contained a path" do
        subject.storage_service_host[:primary] = "http://dummy.uri/host/path"
        _(subject.generate_uri("resource/entity/").path).must_equal "/host/path/resource/entity/"
      end
    end

    describe "when passed an Hash of query parameters" do
      it "encodes the keys" do
        _(subject.generate_uri("", "key !" => "value").query).must_include "key+%21=value"
      end

      it "encodes the values" do
        _(subject.generate_uri("", "key" => "value !").query).must_include "key=value+%21"
      end

      it "sets the query string to the encoded result" do
        _(subject.generate_uri("", "key" => "value !", "key !" => "value").query).must_equal "key=value+%21&key+%21=value"
      end

      describe "when the query parameters include a timeout key" do
        it "overrides the default timeout" do
          _(subject.generate_uri("", "timeout" => 45).query).must_equal "timeout=45"
        end
      end

      describe "when the query parameters are nil" do
        it "does not include any query parameters" do
          assert_nil subject.generate_uri("", nil).query
        end
      end
    end

    describe "when passed an optional location" do
      it "default location should be primary" do
        _(subject.generate_uri("", nil).to_s).must_equal "http://dumyhost.uri/"
      end

      it "primary location should work" do
        _(subject.generate_uri("", nil, { location_mode: Azure::Storage::Common::LocationMode::PRIMARY_ONLY}).to_s).must_equal "http://dumyhost.uri/"
      end

      it "secondary location should work" do
        _(subject.generate_uri("", nil, 
          { location_mode: Azure::Storage::Common::LocationMode::SECONDARY_ONLY, 
            request_location_mode: Azure::Storage::Common::RequestLocationMode::PRIMARY_OR_SECONDARY}).to_s).must_equal "http://dumyhost-secondary.uri/"
      end

      it "raise exception when primary only" do
        assert_raises(Azure::Storage::Common::InvalidOptionsError) do
          subject.generate_uri "", nil, { location_mode: Azure::Storage::Common::LocationMode::PRIMARY_ONLY, request_location_mode: Azure::Storage::Common::RequestLocationMode::SECONDARY_ONLY }
        end
      end

      it "raise exception when secondary only" do
        assert_raises(Azure::Storage::Common::InvalidOptionsError) do
          subject.generate_uri "", nil, { location_mode: Azure::Storage::Common::LocationMode::SECONDARY_ONLY, request_location_mode: Azure::Storage::Common::RequestLocationMode::PRIMARY_ONLY }
        end
      end
    end
  end
end
