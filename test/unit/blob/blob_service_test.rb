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
require "azure/storage/blob"

describe Azure::Storage::Blob::BlobService do
  let(:user_agent_prefix) { "azure_storage_ruby_unit_test" }
  subject {
    Azure::Storage::Blob::BlobService::create({ storage_account_name: "mockaccount", storage_access_key: "YWNjZXNzLWtleQ==" })
  }
  let(:serialization) { Azure::Storage::Blob::Serialization }
  let(:uri) { URI.parse "http://foo.com" }
  let(:query) { {} }
  let(:x_ms_version) { Azure::Storage::Blob::Default::STG_VERSION }
  let(:user_agent) { Azure::Storage::Blob::Default::USER_AGENT }
  let(:request_headers) { {} }
  let(:request_body) { "request-body" }

  let(:response_headers) { {} }
  let(:response_body) { mock() }
  let(:response) { mock() }

  before {
    response.stubs(:body).returns(response_body)
    response.stubs(:headers).returns(response_headers)
    subject.stubs(:call).returns(response)
  }

  describe "#create_from_connection_string" do
    let(:service) { Azure::Storage::Blob::BlobService }

    it "returns nil for a valid connection string" do
      assert_raises(Azure::Storage::Common::InvalidConnectionStringError) {
        Azure::Storage::Blob::BlobService.create_from_connection_string("invalid")
      }
    end
  end

  describe "#get_user_delegation_key" do
    let(:response_body) {
      '<?xml version="1.0" encoding="utf-8"?>
<UserDelegationKey>
    <SignedOid>aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa</SignedOid>
    <SignedTid>bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb</SignedTid>
    <SignedStart>2020-01-24T13:24:33Z</SignedStart>
    <SignedExpiry>2020-01-24T14:24:33Z</SignedExpiry>
    <SignedService>b</SignedService>
    <SignedVersion>2018-11-09</SignedVersion>
    <Value>abcdefgh1234567890=?.,:-</Value>
</UserDelegationKey>'
    }

    it "validates that start is before expiry" do
      now = Time.now
      assert_raises(ArgumentError) {
        subject.get_user_delegation_key(now, now - 1)
      }
    end

    it "validates that start and expiry are within 7 days of current time" do
      now = Time.now
      days = 60 * 60 * 24
      assert_raises(ArgumentError) {
        subject.get_user_delegation_key(now, now + 8 * days)
      }
      assert_raises(ArgumentError) {
        subject.get_user_delegation_key(now + 8 * days, now)
      }
    end

    it "returns a user delegation key for the account" do
      now = Time.now
      result = subject.get_user_delegation_key(now, now + 100)
      _(result).must_be_kind_of Azure::Storage::Common::Service::UserDelegationKey
    end
  end

  describe "#list_containers" do
    let(:verb) { :get }
    let(:options) { { request_location_mode: Azure::Storage::Common::RequestLocationMode::PRIMARY_OR_SECONDARY} }
    let(:container_enumeration_result) { Azure::Storage::Common::Service::EnumerationResults.new }

    before {
      subject.stubs(:containers_uri).with({}, options).returns(uri)
      subject.stubs(:call).with(verb, uri, nil, {}, options).returns(response)
      serialization.stubs(:container_enumeration_results_from_xml).with(response_body).returns(container_enumeration_result)
    }

    it "assembles a URI for the request" do
      subject.expects(:containers_uri).with({}, options).returns(uri)
      subject.list_containers
    end

    it "calls StorageService#call with the prepared request" do
      subject.list_containers
    end

    it "deserializes the response" do
      serialization.expects(:container_enumeration_results_from_xml).with(response_body).returns(container_enumeration_result)
      subject.list_containers
    end

    it "returns a list of containers for the account" do
      result = subject.list_containers
      _(result).must_be_kind_of Azure::Storage::Common::Service::EnumerationResults
    end

    describe "when the options Hash is used" do
      before {
        serialization.expects(:container_enumeration_results_from_xml).with(response_body).returns(container_enumeration_result)
      }

      it "modifies the URI query parameters when provided a :prefix value" do
        query = { "prefix" => "pre" }
        local_call_options = { prefix: "pre" }.merge options
        
        subject.expects(:containers_uri).with(query, local_call_options).returns(uri)
        subject.expects(:call).with(:get, uri, nil, {}, local_call_options).returns(response)
        subject.list_containers local_call_options
      end

      it "modifies the URI query parameters when provided a :marker value" do
        query = { "marker" => "mark" }
        local_call_options = { marker: "mark" }.merge options
        
        subject.expects(:containers_uri).with(query, local_call_options).returns(uri)
        subject.expects(:call).with(:get, uri, nil, {}, local_call_options).returns(response)
        subject.list_containers local_call_options
      end

      it "modifies the URI query parameters when provided a :max_results value" do
        query = { "maxresults" => "5" }
        local_call_options = { max_results: 5 }.merge options

        subject.expects(:containers_uri).with(query, local_call_options).returns(uri)
        subject.expects(:call).with(:get, uri, nil, {}, local_call_options).returns(response)
        subject.list_containers local_call_options
      end

      it "modifies the URI query parameters when provided a :metadata value" do
        query = { "include" => "metadata" }
        local_call_options = { metadata: true }.merge options

        subject.expects(:containers_uri).with(query, local_call_options).returns(uri)
        subject.expects(:call).with(:get, uri, nil, {}, local_call_options).returns(response)
        subject.list_containers local_call_options
      end

      it "modifies the URI query parameters when provided a :timeout value" do
        query = { "timeout" => "37" }
        local_call_options = { timeout: 37 }.merge options
        
        subject.expects(:containers_uri).with(query, local_call_options).returns(uri)
        subject.expects(:call).with(:get, uri, nil, {}, local_call_options).returns(response)
        subject.list_containers local_call_options
      end

      it "does not modify the URI query parameters when provided an unknown value" do
        local_call_options = { unknown_key: "some_value" }.merge options

        subject.expects(:containers_uri).with({}, local_call_options).returns(uri)
        subject.expects(:call).with(:get, uri, nil, {}, local_call_options).returns(response)
        subject.list_containers local_call_options
      end
    end
  end

  describe "container functions" do
    let(:container_name) { "container-name" }
    let(:container) { Azure::Storage::Blob::Container::Container.new }

    describe "#create_container" do

      let(:verb) { :put }
      before {
        subject.stubs(:container_uri).with(container_name, {}).returns(uri)
        subject.stubs(:call).with(verb, uri, nil, request_headers, {}).returns(response)
        serialization.stubs(:container_from_headers).with(response_headers).returns(container)
      }

      it "assembles a URI for the request" do
        subject.expects(:container_uri).with(container_name, {}).returns(uri)
        subject.create_container container_name
      end

      it "calls StorageService#call with the prepared request" do
        subject.expects(:call).with(verb, uri, nil, request_headers, {}).returns(response)
        subject.create_container container_name
      end

      it "deserializes the response" do
        serialization.expects(:container_from_headers).with(response_headers).returns(container)
        subject.create_container container_name
      end

      it "returns a new container" do
        result = subject.create_container container_name

        _(result).must_be_kind_of Azure::Storage::Blob::Container::Container
        _(result.name).must_equal container_name
      end

      describe "when optional metadata parameter is used" do
        let(:container_metadata) {
          {
            "MetadataKey" => "MetaDataValue",
            "MetadataKey1" => "MetaDataValue1"
          }
        }

        before do
          request_headers = {
            "x-ms-meta-MetadataKey" => "MetaDataValue",
            "x-ms-meta-MetadataKey1" => "MetaDataValue1"
          }
          subject.stubs(:container_uri).with(container_name, {}).returns(uri)
          serialization.stubs(:container_from_headers).with(response_headers).returns(container)
          subject.stubs(:call).with(verb, uri, nil, request_headers, {}).returns(response)
        end

        it "adds metadata to the request headers" do
          subject.stubs(:call).with(verb, uri, nil, request_headers, container_metadata).returns(response)
          subject.create_container container_name, container_metadata
        end
      end

      describe "when optional public_access_level parameter is used" do
        let(:public_access_level) { "public-access-level-value" }
        let(:options) { { public_access_level: public_access_level } }

        before do
          request_headers = { "x-ms-blob-public-access" => public_access_level }
          subject.stubs(:container_uri).with(container_name, {}).returns(uri)
          subject.stubs(:call).with(verb, uri, nil, request_headers, options).returns(response)
          serialization.stubs(:container_from_headers).with(response_headers).returns(container)
        end

        it "adds public_access_level to the request headers" do
          subject.create_container container_name, options
        end
      end
    end

    describe "#delete_container" do
      let(:verb) { :delete }
      before {
        response.stubs(:success?).returns(true)
        subject.stubs(:container_uri).with(container_name, {}).returns(uri)
        subject.stubs(:call).with(verb, uri, nil, {}, {}).returns(response)
      }

      it "assembles a URI for the request" do
        subject.expects(:container_uri).with(container_name, {}).returns(uri)
        subject.delete_container container_name
      end

      it "calls StorageService#call with the prepared request" do
        subject.expects(:call).with(verb, uri, nil, {}, {}).returns(response)
        subject.delete_container container_name
      end

      it "returns nil on success" do
        result = subject.delete_container container_name
        _(result).must_equal nil
      end
    end

    describe "#get_container_properties" do
      let(:verb) { :get }
      let(:options) { { request_location_mode: Azure::Storage::Common::RequestLocationMode::PRIMARY_OR_SECONDARY} }
      let(:container_properties) { {} }

      before {
        container.properties = container_properties
        response_headers = {}
        subject.stubs(:container_uri).with(container_name, {}, options).returns(uri)
        subject.stubs(:call).with(verb, uri, nil, {}, {}).returns(response)
        serialization.stubs(:container_from_headers).with(response_headers).returns(container)
      }

      it "assembles a URI for the request" do
        subject.expects(:container_uri).with(container_name, {}, options).returns(uri)
        subject.get_container_properties container_name
      end

      it "calls StorageService#call with the prepared request" do
        subject.expects(:call).with(verb, uri, nil, {}, options).returns(response)
        subject.get_container_properties container_name
      end

      it "deserializes the response" do
        serialization.expects(:container_from_headers).with(response_headers).returns(container)
        subject.get_container_properties container_name
      end

      it "returns a container, with it's properties attribute populated" do
        result = subject.get_container_properties container_name
        _(result).must_be_kind_of Azure::Storage::Blob::Container::Container
        _(result.name).must_equal container_name
        _(result.properties).must_equal container_properties
      end
    end

    describe "#get_container_metadata" do
      let(:verb) { :get }
      let(:options) { { request_location_mode: Azure::Storage::Common::RequestLocationMode::PRIMARY_OR_SECONDARY} }
      let(:container_metadata) { { "MetadataKey" => "MetaDataValue", "MetadataKey1" => "MetaDataValue1" } }
      let(:response_headers) { { "x-ms-meta-MetadataKey" => "MetaDataValue", "x-ms-meta-MetadataKey1" => "MetaDataValue1" } }

      before {
        query.update("comp" => "metadata")
        response.stubs(:headers).returns(response_headers)
        subject.stubs(:container_uri).with(container_name, query, options).returns(uri)
        subject.stubs(:call).with(verb, uri, nil, {}, options).returns(response)

        container.metadata = container_metadata
        serialization.stubs(:container_from_headers).with(response_headers).returns(container)
      }

      it "assembles a URI for the request" do
        subject.expects(:container_uri).with(container_name, query, options).returns(uri)
        subject.get_container_metadata container_name
      end

      it "calls StorageService#call with the prepared request" do
        subject.expects(:call).with(verb, uri, nil, {}, options).returns(response)
        subject.get_container_metadata container_name
      end

      it "deserializes the response" do
        serialization.expects(:container_from_headers).with(response_headers).returns(container)
        subject.get_container_metadata container_name
      end

      it "returns a container, with it's metadata attribute populated" do
        result = subject.get_container_metadata container_name
        _(result).must_be_kind_of Azure::Storage::Blob::Container::Container
        _(result.name).must_equal container_name
        _(result.metadata).must_equal container_metadata
      end
    end

    describe "#get_container_acl" do
      let(:verb) { :get }
      let(:options) { { request_location_mode: Azure::Storage::Common::RequestLocationMode::PRIMARY_OR_SECONDARY} }
      let(:signed_identifier) { Azure::Storage::Common::Service::SignedIdentifier.new }
      let(:signed_identifiers) { [signed_identifier] }

      before {
        query.update("comp" => "acl")
        response.stubs(:headers).returns({})
        response_body.stubs(:length).returns(37)
        subject.stubs(:container_uri).with(container_name, query, options).returns(uri)
        subject.stubs(:call).with(verb, uri, nil, {}, {}).returns(response)

        serialization.stubs(:container_from_headers).with(response_headers).returns(container)
        serialization.stubs(:signed_identifiers_from_xml).with(response_body).returns(signed_identifiers)
      }

      it "assembles a URI for the request" do
        subject.expects(:container_uri).with(container_name, query, options).returns(uri)
        subject.get_container_acl container_name
      end

      it "calls StorageService#call with the prepared request" do
        subject.expects(:call).with(verb, uri, nil, {}, options).returns(response)
        subject.get_container_acl container_name
      end

      it "deserializes the response" do
        serialization.expects(:container_from_headers).with(response_headers).returns(container)
        serialization.expects(:signed_identifiers_from_xml).with(response_body).returns(signed_identifiers)
        subject.get_container_acl container_name
      end

      it "returns a container and an ACL" do
        returned_container, returned_acl = subject.get_container_acl container_name

        _(returned_container).must_be_kind_of Azure::Storage::Blob::Container::Container
        _(returned_container.name).must_equal container_name

        _(returned_acl).must_be_kind_of Array
        _(returned_acl[0]).must_be_kind_of Azure::Storage::Common::Service::SignedIdentifier
      end
    end

    describe "#set_container_acl" do
      let(:verb) { :put }
      let(:public_access_level) { "any-public-access-level" }

      before {
        query.update("comp" => "acl")
        request_headers["x-ms-blob-public-access"] = public_access_level

        response.stubs(:headers).returns({})
        subject.stubs(:container_uri).with(container_name, query).returns(uri)
        subject.stubs(:call).with(verb, uri, nil, request_headers, {}).returns(response)
        serialization.stubs(:container_from_headers).with(response_headers).returns(container)
      }

      it "assembles a URI for the request" do
        subject.expects(:container_uri).with(container_name, query).returns(uri)
        subject.set_container_acl container_name, public_access_level
      end

      it "calls StorageService#call with the prepared request" do
        subject.expects(:call).with(verb, uri, nil, request_headers, {}).returns(response)
        subject.set_container_acl container_name, public_access_level
      end


      it "deserializes the response" do
        serialization.expects(:container_from_headers).with(response_headers).returns(container)
        subject.set_container_acl container_name, public_access_level
      end

      it "returns a container and an ACL" do
        returned_container, returned_acl = subject.set_container_acl container_name, public_access_level

        _(returned_container).must_be_kind_of Azure::Storage::Blob::Container::Container
        _(returned_container.name).must_equal container_name
        _(returned_container.public_access_level).must_equal public_access_level

        _(returned_acl).must_be_kind_of Array
      end

      describe "when the public_access_level parameter is set to 'container'" do
        let(:public_access_level) { "container" }
        before {
          request_headers["x-ms-blob-public-access"] = public_access_level
        }

        it "sets the x-ms-blob-public-access header" do
          subject.expects(:call).with(verb, uri, nil, request_headers, {}).returns(response)
          subject.set_container_acl container_name, public_access_level
        end

        describe "when a signed_identifiers value is provided" do
          let(:signed_identifier) { Azure::Storage::Common::Service::SignedIdentifier.new }
          let(:signed_identifiers) { [signed_identifier] }
          before {
            subject.stubs(:call).with(verb, uri, request_body, request_headers, {}).returns(response)
            serialization.stubs(:signed_identifiers_to_xml).with(signed_identifiers).returns(request_body)
          }

          it "serializes the request contents" do
            serialization.expects(:signed_identifiers_to_xml).with(signed_identifiers).returns(request_body)
            options = { signed_identifiers: signed_identifiers }
            subject.stubs(:call).with(verb, uri, request_body, request_headers, options).returns(response)
            subject.set_container_acl container_name, public_access_level, options
          end

          it "returns a container and an ACL" do
            options = { signed_identifiers: signed_identifiers }
            subject.stubs(:call).with(verb, uri, request_body, request_headers, options).returns(response)
            returned_container, returned_acl = subject.set_container_acl container_name, public_access_level, options

            _(returned_container).must_be_kind_of Azure::Storage::Blob::Container::Container
            _(returned_container.name).must_equal container_name
            _(returned_container.public_access_level).must_equal public_access_level

            _(returned_acl).must_be_kind_of Array
            _(returned_acl[0]).must_be_kind_of Azure::Storage::Common::Service::SignedIdentifier
          end
        end
      end

      describe "when the public_access_level parameter is set to nil" do
        let(:public_access_level) { nil }
        before {
          request_headers.delete "x-ms-blob-public-access"
        }

        it "sets the x-ms-blob-public-access header" do
          subject.expects(:call).with(verb, uri, nil, request_headers, {}).returns(response)
          subject.set_container_acl container_name, public_access_level
        end
      end

      describe "when the public_access_level parameter is set to empty string" do
        let(:public_access_level) { "" }
        before {
          request_headers.delete "x-ms-blob-public-access"
        }

        it "sets the x-ms-blob-public-access header" do
          subject.expects(:call).with(verb, uri, nil, request_headers, {}).returns(response)
          subject.set_container_acl container_name, public_access_level
        end
      end
    end

    describe "#set_container_metadata" do
      let(:verb) { :put }
      let(:container_metadata) { { "MetadataKey" => "MetaDataValue", "MetadataKey1" => "MetaDataValue1" } }
      let(:request_headers) {
        { "x-ms-meta-MetadataKey" => "MetaDataValue",
         "x-ms-meta-MetadataKey1" => "MetaDataValue1"
         }
      }

      before {
        query.update("comp" => "metadata")
        response.stubs(:success?).returns(true)
        subject.stubs(:container_uri).with(container_name, query).returns(uri)
        subject.stubs(:call).with(verb, uri, nil, request_headers, {}).returns(response)
      }

      it "assembles a URI for the request" do
        subject.expects(:container_uri).with(container_name, query).returns(uri)
        subject.set_container_metadata container_name, container_metadata
      end

      it "calls StorageService#call with the prepared request" do
        subject.expects(:call).with(verb, uri, nil, request_headers, {}).returns(response)
        subject.set_container_metadata container_name, container_metadata
      end

      it "returns nil on success" do
        result = subject.set_container_metadata container_name, container_metadata
        _(result).must_equal nil
      end
    end

    describe "#list_blobs" do
      let(:verb) { :get }
      let(:query) { { "comp" => "list" } }
      let(:options) { { request_location_mode: Azure::Storage::Common::RequestLocationMode::PRIMARY_OR_SECONDARY} }
      let(:blob_enumeration_results) { Azure::Storage::Common::Service::EnumerationResults.new }

      before {
        subject.stubs(:container_uri).with(container_name, query, options).returns(uri)
        subject.stubs(:call).with(verb, uri, nil, {}, options).returns(response)
        response.stubs(:success?).returns(true)
        serialization.stubs(:blob_enumeration_results_from_xml).with(response_body).returns(blob_enumeration_results)
      }

      it "assembles a URI for the request" do
        subject.expects(:container_uri).with(container_name, query, options).returns(uri)
        subject.list_blobs container_name
      end

      it "calls StorageService#call with the prepared request" do
        subject.expects(:call).with(verb, uri, nil, {}, options).returns(response)
        subject.list_blobs container_name
      end

      it "deserializes the response" do
        serialization.expects(:blob_enumeration_results_from_xml).with(response_body).returns(blob_enumeration_results)
        subject.list_blobs container_name
      end

      it "returns a list of blobs for the container" do
        result = subject.list_blobs container_name
        _(result).must_be_kind_of Azure::Storage::Common::Service::EnumerationResults
      end

      describe "when the options Hash is used" do
        before {
          response.expects(:success?).returns(true)
          serialization.expects(:blob_enumeration_results_from_xml).with(response_body).returns(blob_enumeration_results)
        }

        it "modifies the URI query parameters when provided a :prefix value" do
          query["prefix"] = "pre"
          local_call_options = { prefix: "pre" }.merge options
          subject.expects(:container_uri).with(container_name, query, local_call_options).returns(uri)
          subject.expects(:call).with(:get, uri, nil, {}, local_call_options).returns(response)
          subject.list_blobs container_name, local_call_options
        end

        it "modifies the URI query parameters when provided a :delimiter value" do
          query["delimiter"] = "delim"
          local_call_options = { delimiter: "delim" }.merge options
          subject.expects(:container_uri).with(container_name, query, local_call_options).returns(uri)
          subject.expects(:call).with(:get, uri, nil, {}, local_call_options).returns(response)
          subject.list_blobs container_name, local_call_options
        end

        it "modifies the URI query parameters when provided a :marker value" do
          query["marker"] = "mark"
          local_call_options = { marker: "mark" }.merge options
          subject.expects(:container_uri).with(container_name, query, local_call_options).returns(uri)
          subject.expects(:call).with(:get, uri, nil, {}, local_call_options).returns(response)
          subject.list_blobs container_name, local_call_options
        end

        it "modifies the URI query parameters when provided a :max_results value" do
          query["maxresults"] = "5"
          local_call_options = { max_results: 5 }.merge options
          subject.expects(:container_uri).with(container_name, query, local_call_options).returns(uri)
          subject.expects(:call).with(:get, uri, nil, {}, local_call_options).returns(response)
          subject.list_blobs container_name, local_call_options
        end

        it "modifies the URI query parameters when provided a :metadata value" do
          query["include"] = "metadata"
          local_call_options = { metadata: true }.merge options
          subject.expects(:container_uri).with(container_name, query, local_call_options).returns(uri)
          subject.expects(:call).with(:get, uri, nil, {}, local_call_options).returns(response)
          subject.list_blobs container_name, local_call_options
        end

        it "modifies the URI query parameters when provided a :snapshots value" do
          query["include"] = "snapshots"
          local_call_options = { snapshots: true }.merge options
          subject.expects(:container_uri).with(container_name, query, local_call_options).returns(uri)
          subject.expects(:call).with(:get, uri, nil, {}, local_call_options).returns(response)
          subject.list_blobs container_name, local_call_options
        end

        it "modifies the URI query parameters when provided a :uncommittedblobs value" do
          query["include"] = "uncommittedblobs"
          local_call_options = { uncommittedblobs: true }.merge options
          subject.expects(:container_uri).with(container_name, query, local_call_options).returns(uri)
          subject.expects(:call).with(:get, uri, nil, {}, local_call_options).returns(response)
          subject.list_blobs container_name, local_call_options
        end

        it "modifies the URI query parameters when provided a :copy value" do
          query["include"] = "copy"
          local_call_options = { copy: true }.merge options
          subject.expects(:container_uri).with(container_name, query, local_call_options).returns(uri)
          subject.expects(:call).with(:get, uri, nil, {}, local_call_options).returns(response)
          subject.list_blobs container_name, local_call_options
        end

        it "modifies the URI query parameters when provided more than one of :metadata, :snapshots, :uncommittedblobs or :copy values" do
          query["include"] = "metadata,snapshots,uncommittedblobs,copy"
          local_call_options = {
            copy: true,
            metadata: true,
            snapshots: true,
            uncommittedblobs: true
          }.merge options
          subject.expects(:container_uri).with(container_name, query, local_call_options).returns(uri)
          subject.expects(:call).with(:get, uri, nil, {}, local_call_options).returns(response)
          subject.list_blobs container_name, local_call_options
        end

        it "modifies the URI query parameters when provided a :timeout value" do
          query["timeout"] = "37"
          local_call_options = { timeout: 37 }.merge options
          subject.expects(:container_uri).with(container_name, query, local_call_options).returns(uri)
          subject.expects(:call).with(:get, uri, nil, {}, local_call_options).returns(response)
          subject.list_blobs container_name, local_call_options
        end

        it "does not modify the URI query parameters when provided an unknown value" do
          local_call_options = { unknown_key: "some_value" }.merge options
          subject.expects(:container_uri).with(container_name, query, local_call_options).returns(uri)
          subject.expects(:call).with(:get, uri, nil, {}, local_call_options).returns(response)
          subject.list_blobs container_name, local_call_options
        end
      end
    end

    describe "blob functions" do
      let(:blob_name) { "blob-name" }
      let(:blob) { Azure::Storage::Blob::Blob.new }

      describe "#create_page_blob" do
        let(:verb) { :put }
        let(:blob_length) { 37 }
        let(:request_headers) {
          {
            "x-ms-blob-type" => "PageBlob",
            "Content-Length" => 0.to_s,
            "x-ms-blob-content-length" => blob_length.to_s,
            "x-ms-sequence-number" => 0.to_s,
            "x-ms-blob-content-type" => "application/octet-stream"
          }
        }

        before {
          subject.stubs(:blob_uri).with(container_name, blob_name, {}).returns(uri)
          subject.stubs(:call).with(verb, uri, nil, request_headers, {}).returns(response)
          serialization.stubs(:blob_from_headers).with(response_headers).returns(blob)
        }

        it "assembles a URI for the request" do
          subject.expects(:blob_uri).with(container_name, blob_name, {}).returns(uri)
          subject.create_page_blob container_name, blob_name, blob_length
        end

        it "calls StorageService#call with the prepared request" do
          subject.expects(:call).with(verb, uri, nil, request_headers, {}).returns(response)
          subject.create_page_blob container_name, blob_name, blob_length
        end

        it "returns a Blob on success" do
          result = subject.create_page_blob container_name, blob_name, blob_length
          _(result).must_be_kind_of Azure::Storage::Blob::Blob
          _(result).must_equal blob
          _(result.name).must_equal blob_name
        end

        describe "when the options Hash is used" do
          it "modifies the request headers when provided a :sequence_number value" do
            request_headers["x-ms-sequence-number"] = 37.to_s
            options = { sequence_number: 37.to_s }
            subject.stubs(:call).with(verb, uri, nil, request_headers, options).returns(response)
            subject.create_page_blob container_name, blob_name, blob_length, options
          end

          it "modifies the request headers when provided a :content_type value" do
            request_headers["x-ms-blob-content-type"] = "bct-value"
            options = { content_type: "bct-value" }
            subject.stubs(:call).with(verb, uri, nil, request_headers, options).returns(response)
            subject.create_page_blob container_name, blob_name, blob_length, options
          end

          it "modifies the request headers when provided a :content_encoding value" do
            request_headers["x-ms-blob-content-encoding"] = "bce-value"
            options = { content_encoding: "bce-value" }
            subject.stubs(:call).with(verb, uri, nil, request_headers, options).returns(response)
            subject.create_page_blob container_name, blob_name, blob_length, options
          end

          it "modifies the request headers when provided a :content_language value" do
            request_headers["x-ms-blob-content-language"] = "bcl-value"
            options = { content_language: "bcl-value" }
            subject.stubs(:call).with(verb, uri, nil, request_headers, options).returns(response)
            subject.create_page_blob container_name, blob_name, blob_length, options
          end

          it "modifies the request headers when provided a :content_md5 value" do
            request_headers["x-ms-blob-content-md5"] = "bcm-value"
            options = { content_md5: "bcm-value" }
            subject.stubs(:call).with(verb, uri, nil, request_headers, options).returns(response)
            subject.create_page_blob container_name, blob_name, blob_length, options
          end

          it "modifies the request headers when provided a :cache_control value" do
            request_headers["x-ms-blob-cache-control"] = "bcc-value"
            options = { cache_control: "bcc-value" }
            subject.stubs(:call).with(verb, uri, nil, request_headers, options).returns(response)
            subject.create_page_blob container_name, blob_name, blob_length, options
          end

          it "modifies the request headers when provided a :content_disposition value" do
            request_headers["x-ms-blob-content-disposition"] = "bcd-value"
            options = { content_disposition: "bcd-value" }
            subject.stubs(:call).with(verb, uri, nil, request_headers, options).returns(response)
            subject.create_page_blob container_name, blob_name, blob_length, options
          end

          it "modifies the request headers when provided a :transactional_md5 value" do
            request_headers["Content-MD5"] = "tm-value"
            options = { transactional_md5: "tm-value" }
            subject.stubs(:call).with(verb, uri, nil, request_headers, options).returns(response)
            subject.create_page_blob container_name, blob_name, blob_length, options
          end

          it "modifies the request headers when provided a :metadata value" do
            request_headers["x-ms-meta-MetadataKey"] = "MetaDataValue"
            request_headers["x-ms-meta-MetadataKey1"] = "MetaDataValue1"
            options = { metadata: { "MetadataKey" => "MetaDataValue", "MetadataKey1" => "MetaDataValue1" } }
            subject.stubs(:call).with(verb, uri, nil, request_headers, options).returns(response)
            subject.create_page_blob container_name, blob_name, blob_length, options
          end

          it "does not modify the request headers when provided an unknown value" do
            options = { unknown_key: "some_value" }
            subject.stubs(:call).with(verb, uri, nil, request_headers, options).returns(response)
            subject.create_page_blob container_name, blob_name, blob_length, options
          end
        end
      end

      describe "#incremental_copy_blob" do
        let(:verb) { :put }
        let(:query) { { "comp" => "incrementalcopy" } }
        let(:source_uri) { "https://dummy.uri" }
        let(:request_headers) {
          {
            "x-ms-copy-source" => source_uri
          }
        }
        let(:copy_id) { "copy-id" }
        let(:copy_status) { "copy-status" }

        before {
          subject.stubs(:blob_uri).with(container_name, blob_name, query).returns(uri)
          subject.stubs(:call).with(verb, uri, nil, request_headers, {}).returns(response)
          response.stubs(:success?).returns(true)
          response_headers["x-ms-copy-id"] = copy_id
          response_headers["x-ms-copy-status"] = copy_status
        }

        it "assembles a URI for the request" do
          subject.expects(:blob_uri).with(container_name, blob_name, query).returns(uri)
          subject.incremental_copy_blob container_name, blob_name, source_uri
        end

        it "calls StorageService#call with the prepared request" do
          subject.expects(:call).with(verb, uri, nil, request_headers, {}).returns(response)
          subject.incremental_copy_blob container_name, blob_name, source_uri
        end

        it "returns 'x-ms-copy-id' and 'x-ms-copy-status' on success" do
          result = subject.incremental_copy_blob container_name, blob_name, source_uri
          _(result[0]).must_equal copy_id
          _(result[1]).must_equal copy_status
        end
      end

      describe "#put_blob_pages" do
        let(:verb) { :put }
        let(:start_range) { 255 }
        let(:end_range) { 512 }
        let(:content) { "some content" }
        let(:query) { { "comp" => "page" } }
        let(:request_headers) {
          {
            "x-ms-page-write" => "update",
            "x-ms-range" => "bytes=#{start_range}-#{end_range}",
            "Content-Type" => ""
          }
        }

        before {
          subject.stubs(:blob_uri).with(container_name, blob_name, query).returns(uri)
          subject.stubs(:call).with(verb, uri, content, request_headers, {}).returns(response)
          serialization.stubs(:blob_from_headers).with(response_headers).returns(blob)
        }

        it "assembles a URI for the request" do
          subject.expects(:blob_uri).with(container_name, blob_name, query).returns(uri)
          subject.put_blob_pages container_name, blob_name, start_range, end_range, content
        end

        it "calls StorageService#call with the prepared request" do
          subject.expects(:call).with(verb, uri, content, request_headers, {}).returns(response)
          subject.put_blob_pages container_name, blob_name, start_range, end_range, content
        end

        it "returns a Blob on success" do
          result = subject.put_blob_pages container_name, blob_name, start_range, end_range, content
          _(result).must_be_kind_of Azure::Storage::Blob::Blob
          _(result).must_equal blob
          _(result.name).must_equal blob_name
        end

        describe "when the options Hash is used" do
          it "modifies the request headers when provided a :if_sequence_number_eq value" do
            request_headers["x-ms-if-sequence-number-eq"] = "isne-value"
            options = { if_sequence_number_eq: "isne-value" }
            subject.stubs(:call).with(verb, uri, content, request_headers, options).returns(response)
            subject.put_blob_pages container_name, blob_name, start_range, end_range, content, options
          end

          it "modifies the request headers when provided a :if_sequence_number_lt value" do
            request_headers["x-ms-if-sequence-number-lt"] = "isnlt-value"
            options = { if_sequence_number_lt: "isnlt-value" }
            subject.stubs(:call).with(verb, uri, content, request_headers, options).returns(response)
            subject.put_blob_pages container_name, blob_name, start_range, end_range, content, options
          end

          it "modifies the request headers when provided a :if_sequence_number_le value" do
            request_headers["x-ms-if-sequence-number-le"] = "isnle-value"
            options = { if_sequence_number_le: "isnle-value" }
            subject.stubs(:call).with(verb, uri, content, request_headers, options).returns(response)
            subject.put_blob_pages container_name, blob_name, start_range, end_range, content, options
          end

          it "modifies the request headers when provided a :if_modified_since value" do
            request_headers["If-Modified-Since"] = "ims-value"
            options = { if_modified_since: "ims-value" }
            subject.stubs(:call).with(verb, uri, content, request_headers, options).returns(response)
            subject.put_blob_pages container_name, blob_name, start_range, end_range, content, options
          end

          it "modifies the request headers when provided a :if_unmodified_since value" do
            request_headers["If-Unmodified-Since"] = "iums-value"
            options = { if_unmodified_since: "iums-value" }
            subject.stubs(:call).with(verb, uri, content, request_headers, options).returns(response)
            subject.put_blob_pages container_name, blob_name, start_range, end_range, content, options
          end

          it "modifies the request headers when provided a :if_match value" do
            request_headers["If-Match"] = "im-value"
            options = { if_match: "im-value" }
            subject.stubs(:call).with(verb, uri, content, request_headers, options).returns(response)
            subject.put_blob_pages container_name, blob_name, start_range, end_range, content, options
          end

          it "modifies the request headers when provided a :if_none_match value" do
            request_headers["If-None-Match"] = "inm-value"
            options = { if_none_match: "inm-value" }
            subject.stubs(:call).with(verb, uri, content, request_headers, options).returns(response)
            subject.put_blob_pages container_name, blob_name, start_range, end_range, content, options
          end


          it "does not modify the request headers when provided an unknown value" do
            options = { unknown_key: "some_value" }
            subject.stubs(:call).with(verb, uri, content, request_headers, options).returns(response)
            subject.put_blob_pages container_name, blob_name, start_range, end_range, content, options
          end
        end
      end

      describe "#clear_blob_pages" do
        let(:verb) { :put }
        let(:query) { { "comp" => "page" } }
        let(:start_range) { 255 }
        let(:end_range) { 512 }
        let(:request_headers) {
          {
            "x-ms-range" => "bytes=#{start_range}-#{end_range}",
            "x-ms-page-write" => "clear",
            "Content-Type" => ""
          }
        }

        before {
          subject.stubs(:blob_uri).with(container_name, blob_name, query).returns(uri)
          subject.stubs(:call).with(verb, uri, nil, request_headers, {}).returns(response)
          serialization.stubs(:blob_from_headers).with(response_headers).returns(blob)
        }

        it "assembles a URI for the request" do
          subject.expects(:blob_uri).with(container_name, blob_name, query).returns(uri)
          subject.clear_blob_pages container_name, blob_name, start_range, end_range
        end

        it "calls StorageService#call with the prepared request" do
          subject.expects(:call).with(verb, uri, nil, request_headers, {}).returns(response)
          subject.clear_blob_pages container_name, blob_name, start_range, end_range
        end

        it "returns a Blob on success" do
          result = subject.clear_blob_pages container_name, blob_name, start_range, end_range
          _(result).must_be_kind_of Azure::Storage::Blob::Blob
          _(result).must_equal blob
          _(result.name).must_equal blob_name
        end

        # describe "when start_range is provided" do
        #   let(:start_range){ 255 }
        #   before { request_headers["x-ms-range"]="#{start_range}-" }

        #   it "modifies the request headers with the desired range" do
        #     subject.expects(:call).with(verb, uri, nil, request_headers).returns(response)
        #     subject.clear_blob_pages container_name, blob_name, start_range
        #   end
        # end

        # describe "when end_range is provided" do
        #   let(:end_range){ 512 }
        #   before { request_headers["x-ms-range"]="0-#{end_range}" }

        #   it "modifies the request headers with the desired range" do
        #     subject.expects(:call).with(verb, uri, nil, request_headers).returns(response)
        #     subject.clear_blob_pages container_name, blob_name, nil, end_range
        #   end
        # end

        # describe "when both start_range and end_range are provided" do
        #   before { request_headers["x-ms-range"]="bytes=#{start_range}-#{end_range}" }

        #   it "modifies the request headers with the desired range" do
        #     subject.expects(:call).with(verb, uri, nil, request_headers).returns(response)
        #     subject.clear_blob_pages container_name, blob_name, start_range, end_range
        #   end
        # end
      end

      describe "#put_blob_block" do
        require "base64"

        let(:verb) { :put }
        let(:content) { "some content" }
        let(:block_id) { "block-id" }
        let(:server_generated_content_md5) { "server-content-md5" }
        let(:request_headers) { {} }

        before {
          query.update("comp" => "block", "blockid" => Base64.strict_encode64(block_id))
          response_headers["Content-MD5"] = server_generated_content_md5
          subject.stubs(:blob_uri).with(container_name, blob_name, query).returns(uri)
          subject.stubs(:call).with(verb, uri, content, request_headers, {}).returns(response)
        }

        it "assembles a URI for the request" do
          subject.expects(:blob_uri).with(container_name, blob_name, query).returns(uri)
          subject.put_blob_block container_name, blob_name, block_id, content
        end

        it "calls StorageService#call with the prepared request" do
          subject.expects(:call).with(verb, uri, content, request_headers, {}).returns(response)
          subject.put_blob_block container_name, blob_name, block_id, content
        end

        it "returns content MD5 on success" do
          result = subject.put_blob_block container_name, blob_name, block_id, content
          _(result).must_equal server_generated_content_md5
        end

        describe "when the options Hash is used" do
          it "modifies the request headers when provided a :content_md5 value" do
            request_headers["Content-MD5"] = "content-md5"
            options = { content_md5: "content-md5" }
            subject.stubs(:call).with(verb, uri, content, request_headers, options).returns(response)
            subject.put_blob_block container_name, blob_name, block_id, content, options
          end

          it "does not modify the request headers when provided an unknown value" do
            options = { unknown_key: "some_value" }
            subject.stubs(:call).with(verb, uri, content, request_headers, options).returns(response)
            subject.put_blob_block container_name, blob_name, block_id, content, options
          end
        end
      end

      describe "#create_block_blob" do
        let(:verb) { :put }
        let(:content) { "some content" }
        let(:request_headers) {
          {
            "x-ms-blob-type" => "BlockBlob",
            "x-ms-blob-content-type" => "text/plain; charset=#{content.encoding}"
          }
        }

        before {
          subject.stubs(:blob_uri).with(container_name, blob_name, {}).returns(uri)
          subject.stubs(:call).with(verb, uri, content, request_headers, {}).returns(response)
          serialization.stubs(:blob_from_headers).with(response_headers).returns(blob)
        }

        it "assembles a URI for the request" do
          subject.create_block_blob container_name, blob_name, content
        end

        it "calls StorageService#call with the prepared request" do
          subject.expects(:call).with(verb, uri, content, request_headers, {}).returns(response)
          subject.create_block_blob container_name, blob_name, content
        end

        it "returns a Blob on success" do
          result = subject.create_block_blob container_name, blob_name, content
          _(result).must_be_kind_of Azure::Storage::Blob::Blob
          _(result).must_equal blob
          _(result.name).must_equal blob_name
        end

        describe "when the options Hash is used" do
          it "modifies the request headers when provided a :content_type value" do
            request_headers["x-ms-blob-content-type"] = "bct-value"
            options = { content_type: "bct-value" }
            subject.stubs(:call).with(verb, uri, content, request_headers, options).returns(response)
            subject.create_block_blob container_name, blob_name, content, options
          end

          it "modifies the request headers when provided a :content_encoding value" do
            request_headers["x-ms-blob-content-encoding"] = "bce-value"
            options = { content_encoding: "bce-value" }
            subject.stubs(:call).with(verb, uri, content, request_headers, options).returns(response)
            subject.create_block_blob container_name, blob_name, content, options
          end

          it "modifies the request headers when provided a :content_language value" do
            request_headers["x-ms-blob-content-language"] = "bcl-value"
            options = { content_language: "bcl-value" }
            subject.stubs(:call).with(verb, uri, content, request_headers, options).returns(response)
            subject.create_block_blob container_name, blob_name, content, options
          end

          it "modifies the request headers when provided a :content_md5 value" do
            request_headers["x-ms-blob-content-md5"] = "bcm-value"
            options = { content_md5: "bcm-value" }
            subject.stubs(:call).with(verb, uri, content, request_headers, options).returns(response)
            subject.create_block_blob container_name, blob_name, content, options
          end

          it "modifies the request headers when provided a :cache_control value" do
            request_headers["x-ms-blob-cache-control"] = "bcc-value"
            options = { cache_control: "bcc-value" }
            subject.stubs(:call).with(verb, uri, content, request_headers, options).returns(response)
            subject.create_block_blob container_name, blob_name, content, options
          end

          it "modifies the request headers when provided a :content_disposition value" do
            request_headers["x-ms-blob-content-disposition"] = "bcd-value"
            options = { content_disposition: "bcd-value" }
            subject.stubs(:call).with(verb, uri, content, request_headers, options).returns(response)
            subject.create_block_blob container_name, blob_name, content, options
          end

          it "modifies the request headers when provided a :transactional_md5 value" do
            request_headers["Content-MD5"] = "tm-value"
            options = { transactional_md5: "tm-value" }
            subject.stubs(:call).with(verb, uri, content, request_headers, options).returns(response)
            subject.create_block_blob container_name, blob_name, content, options
          end

          it "modifies the request headers when provided a :metadata value" do
            request_headers["x-ms-meta-MetadataKey"] = "MetaDataValue"
            request_headers["x-ms-meta-MetadataKey1"] = "MetaDataValue1"
            options = { metadata: { "MetadataKey" => "MetaDataValue", "MetadataKey1" => "MetaDataValue1" } }
            subject.stubs(:call).with(verb, uri, content, request_headers, options).returns(response)
            subject.create_block_blob container_name, blob_name, content, options
          end

          it "does not modify the request headers when provided an unknown value" do
            options = { unknown_key: "some_value" }
            subject.stubs(:call).with(verb, uri, content, request_headers, options).returns(response)
            subject.create_block_blob container_name, blob_name, content, options
          end
        end
      end

      describe "#commit_blob_blocks" do
        let(:verb) { :put }
        let(:request_body) { "body" }
        let(:block_list) { mock() }
        let(:request_headers) { { "x-ms-blob-content-type" => "application/octet-stream" } }

        before {
          query.update("comp" => "blocklist")
          response.stubs(:success?).returns(true)
          subject.stubs(:blob_uri).with(container_name, blob_name, query).returns(uri)
          serialization.stubs(:block_list_to_xml).with(block_list).returns(request_body)
          subject.stubs(:call).with(verb, uri, request_body, request_headers, {}).returns(response)
        }

        it "assembles a URI for the request" do
          subject.expects(:blob_uri).with(container_name, blob_name, query).returns(uri)
          subject.commit_blob_blocks container_name, blob_name, block_list
        end

        it "calls StorageService#call with the prepared request" do
          subject.expects(:call).with(verb, uri, request_body, request_headers, {}).returns(response)
          subject.commit_blob_blocks container_name, blob_name, block_list
        end

        it "serializes the block list" do
          serialization.expects(:block_list_to_xml).with(block_list).returns(request_body)
          subject.commit_blob_blocks container_name, blob_name, block_list
        end

        it "returns nil on success" do
          result = subject.commit_blob_blocks container_name, blob_name, block_list
          _(result).must_equal nil
        end

        describe "when the options Hash is used" do
          it "modifies the request headers when provided a :transactional_md5 value" do
            request_headers["Content-MD5"] = "tm-value"
            options = { transactional_md5: "tm-value" }
            subject.stubs(:call).with(verb, uri, request_body, request_headers, options).returns(response)
            subject.commit_blob_blocks container_name, blob_name, block_list, options
          end

          it "modifies the request headers when provided a :content_type value" do
            request_headers["x-ms-blob-content-type"] = "bct-value"
            options = { content_type: "bct-value" }
            subject.stubs(:call).with(verb, uri, request_body, request_headers, options).returns(response)
            subject.commit_blob_blocks container_name, blob_name, block_list, options
          end

          it "modifies the request headers when provided a :content_encoding value" do
            request_headers["x-ms-blob-content-encoding"] = "bce-value"
            options = { content_encoding: "bce-value" }
            subject.stubs(:call).with(verb, uri, request_body, request_headers, options).returns(response)
            subject.commit_blob_blocks container_name, blob_name, block_list, options
          end

          it "modifies the request headers when provided a :content_language value" do
            request_headers["x-ms-blob-content-language"] = "bcl-value"
            options = { content_language: "bcl-value" }
            subject.stubs(:call).with(verb, uri, request_body, request_headers, options).returns(response)
            subject.commit_blob_blocks container_name, blob_name, block_list, options
          end

          it "modifies the request headers when provided a :content_md5 value" do
            request_headers["x-ms-blob-content-md5"] = "bcm-value"
            options = { content_md5: "bcm-value" }
            subject.stubs(:call).with(verb, uri, request_body, request_headers, options).returns(response)
            subject.commit_blob_blocks container_name, blob_name, block_list, options
          end

          it "modifies the request headers when provided a :cache_control value" do
            request_headers["x-ms-blob-cache-control"] = "bcc-value"
            options = { cache_control: "bcc-value" }
            subject.stubs(:call).with(verb, uri, request_body, request_headers, options).returns(response)
            subject.commit_blob_blocks container_name, blob_name, block_list, options
          end

          it "modifies the request headers when provided a :content_disposition value" do
            request_headers["x-ms-blob-content-disposition"] = "bcd-value"
            options = { content_disposition: "bcd-value" }
            subject.stubs(:call).with(verb, uri, request_body, request_headers, options).returns(response)
            subject.commit_blob_blocks container_name, blob_name, block_list, options
          end

          it "modifies the request headers when provided a :if_modified_since value" do
            request_headers["If-Modified-Since"] = "ims-value"
            options = { if_modified_since: "ims-value" }
            subject.stubs(:call).with(verb, uri, request_body, request_headers, options).returns(response)
            subject.commit_blob_blocks container_name, blob_name, block_list, options
          end

          it "modifies the request headers when provided a :if_unmodified_since value" do
            request_headers["If-Unmodified-Since"] = "iums-value"
            options = { if_unmodified_since: "iums-value" }
            subject.stubs(:call).with(verb, uri, request_body, request_headers, options).returns(response)
            subject.commit_blob_blocks container_name, blob_name, block_list, options
          end

          it "modifies the request headers when provided a :if_match value" do
            request_headers["If-Match"] = "im-value"
            options = { if_match: "im-value" }
            subject.stubs(:call).with(verb, uri, request_body, request_headers, options).returns(response)
            subject.commit_blob_blocks container_name, blob_name, block_list, options
          end

          it "modifies the request headers when provided a :if_none_match value" do
            request_headers["If-None-Match"] = "inm-value"
            options = { if_none_match: "inm-value" }
            subject.stubs(:call).with(verb, uri, request_body, request_headers, options).returns(response)
            subject.commit_blob_blocks container_name, blob_name, block_list, options
          end

          it "modifies the request headers when provided a :metadata value" do
            request_headers["x-ms-meta-MetadataKey"] = "MetaDataValue"
            request_headers["x-ms-meta-MetadataKey1"] = "MetaDataValue1"
            options = { metadata: { "MetadataKey" => "MetaDataValue", "MetadataKey1" => "MetaDataValue1" } }
            subject.stubs(:call).with(verb, uri, request_body, request_headers, options).returns(response)
            subject.commit_blob_blocks container_name, blob_name, block_list, options
          end

          it "does not modify the request headers when provided an unknown value" do
            options = { unknown_key: "some_value" }
            subject.stubs(:call).with(verb, uri, request_body, request_headers, options).returns(response)
            subject.commit_blob_blocks container_name, blob_name, block_list, options
          end
        end
      end

      describe "#list_blob_blocks" do
        let(:verb) { :get }
        let(:query) { { "comp" => "blocklist", "blocklisttype" => "all" } }
        let(:options) { { request_location_mode: Azure::Storage::Common::RequestLocationMode::PRIMARY_OR_SECONDARY} }
        let(:blob_block_list) { [Azure::Storage::Blob::Block.new] }

        before {
          subject.stubs(:blob_uri).with(container_name, blob_name, query, options).returns(uri)
          subject.stubs(:call).with(verb, uri, nil, {}, { blocklist_type: :all }.merge(options)).returns(response)
          serialization.stubs(:block_list_from_xml).with(response_body).returns(blob_block_list)
        }

        it "assembles a URI for the request" do
          local_call_options = { blocklist_type: :all }.merge options
          subject.expects(:blob_uri).with(container_name, blob_name, query, local_call_options).returns(uri)
          subject.list_blob_blocks container_name, blob_name
        end

        it "calls StorageService#call with the prepared request" do
          local_call_options = { blocklist_type: :all }.merge options
          subject.expects(:blob_uri).with(container_name, blob_name, query, local_call_options).returns(uri)
          subject.expects(:call).with(verb, uri, nil, {}, local_call_options).returns(response)
          subject.list_blob_blocks container_name, blob_name
        end

        it "deserializes the response" do
          local_call_options = { blocklist_type: :all }.merge options
          subject.expects(:blob_uri).with(container_name, blob_name, query, local_call_options).returns(uri)
          serialization.expects(:block_list_from_xml).with(response_body).returns(blob_block_list)
          subject.list_blob_blocks container_name, blob_name
        end

        it "returns a list of blocks for the block blob" do
          local_call_options = { blocklist_type: :all }.merge options
          subject.expects(:blob_uri).with(container_name, blob_name, query, local_call_options).returns(uri)
          result = subject.list_blob_blocks container_name, blob_name
          _(result).must_be_kind_of Array
          _(result.first).must_be_kind_of Azure::Storage::Blob::Block
        end

        describe "when blocklist_type is provided" do
          it "modifies the request query when the value is :all" do
            query["blocklisttype"] = "all"
            local_call_options = { blocklist_type: :all }.merge options
            subject.expects(:blob_uri).with(container_name, blob_name, query, local_call_options).returns(uri)
            subject.stubs(:call).with(verb, uri, nil, {}, local_call_options).returns(response)
            subject.list_blob_blocks container_name, blob_name, local_call_options
          end

          it "modifies the request query when the value is :uncommitted" do
            query["blocklisttype"] = "uncommitted"
            local_call_options = { blocklist_type: :uncommitted }.merge options
            subject.expects(:blob_uri).with(container_name, blob_name, query, local_call_options).returns(uri)
            subject.stubs(:call).with(verb, uri, nil, {}, local_call_options).returns(response)
            subject.list_blob_blocks container_name, blob_name, local_call_options
          end

          it "modifies the request query when the value is :committed" do
            query["blocklisttype"] = "committed"
            local_call_options = { blocklist_type: :committed }.merge options
            subject.expects(:blob_uri).with(container_name, blob_name, query, local_call_options).returns(uri)
            subject.stubs(:call).with(verb, uri, nil, {}, local_call_options).returns(response)
            subject.list_blob_blocks container_name, blob_name, local_call_options
          end
        end

        describe "when snapshot is provided" do
          it "modifies the request query with the provided value" do
            query["snapshot"] = "snapshot-id"
            local_call_options = { snapshot: "snapshot-id" }.merge options
            subject.expects(:blob_uri).with(container_name, blob_name, query, local_call_options).returns(uri)
            subject.stubs(:call).with(verb, uri, nil, {}, local_call_options).returns(response)
            subject.list_blob_blocks container_name, blob_name, local_call_options
          end
        end
      end

      describe "#list_page_blob_ranges" do
        let(:verb) { :get }
        let(:query) { { "comp" => "pagelist" } }
        let(:options) { { request_location_mode: Azure::Storage::Common::RequestLocationMode::PRIMARY_OR_SECONDARY} }
        let(:page_list) { [[0, 511], [512, 1023]] }

        before {
          subject.stubs(:blob_uri).with(container_name, blob_name, query, options).returns(uri)
          subject.stubs(:call).with(verb, uri, nil, request_headers, options).returns(response)
          serialization.stubs(:page_list_from_xml).with(response_body).returns(page_list)
        }

        it "assembles a URI for the request" do
          subject.expects(:blob_uri).with(container_name, blob_name, query, options).returns(uri)
          subject.list_page_blob_ranges container_name, blob_name
        end

        it "calls StorageService#call with the prepared request" do
          subject.expects(:call).with(verb, uri, nil, request_headers, options).returns(response)
          subject.list_page_blob_ranges container_name, blob_name
        end

        it "deserializes the response" do
          subject.stubs(:blob_uri).with(container_name, blob_name, query, options).returns(uri)
          serialization.expects(:page_list_from_xml).with(response_body).returns(page_list)
          subject.list_page_blob_ranges container_name, blob_name
        end

        it "returns a list of ranges for the page blob" do
          result = subject.list_page_blob_ranges container_name, blob_name
          _(result).must_be_kind_of Array
          _(result.first).must_be_kind_of Array
          _(result.first.first).must_be_kind_of Integer
          _(result.first.first.next).must_be_kind_of Integer
        end

        # describe "when start_range is provided" do
        #   let(:start_range){ 255 }
        #   before { request_headers["x-ms-range"]="#{start_range}-" }

        #   it "modifies the request headers with the desired range" do
        #     subject.expects(:call).with(verb, uri, nil, request_headers).returns(response)
        #     subject.list_page_blob_ranges container_name, blob_name, start_range
        #   end
        # end

        # describe "when end_range is provided" do
        #   let(:end_range){ 512 }
        #   before { request_headers["x-ms-range"]="0-#{end_range}" }

        #   it "modifies the request headers with the desired range" do
        #     subject.expects(:call).with(verb, uri, nil, request_headers).returns(response)
        #     subject.list_page_blob_ranges container_name, blob_name, nil, end_range
        #   end
        # end

        describe "when both start_range and end_range are provided" do
          let(:start_range) { 255 }
          let(:end_range) { 512 }
          let(:request_headers) { {} }

          it "modifies the request headers with the desired range" do
            request_headers["x-ms-range"] = "bytes=#{start_range}-#{end_range}"
            local_call_options = { start_range: start_range, end_range: end_range }.merge options
            subject.expects(:blob_uri).with(container_name, blob_name, query, local_call_options).returns(uri)
            subject.expects(:call).with(verb, uri, nil, request_headers, local_call_options).returns(response)
            subject.list_page_blob_ranges container_name, blob_name, local_call_options
          end
        end

        describe "when snapshot is provided" do
          it "modifies the request query with the provided value" do
            query["snapshot"] = "snapshot-id"
            local_call_options = { snapshot: "snapshot-id" }.merge options
            subject.expects(:blob_uri).with(container_name, blob_name, query, local_call_options).returns(uri)
            subject.stubs(:call).with(verb, uri, nil, request_headers, local_call_options).returns(response)
            subject.list_page_blob_ranges container_name, blob_name, local_call_options
          end
        end

        describe "when the option hash is used" do
          it "modifies the request headers when provided a :if_modified_since value" do
            request_headers["If-Modified-Since"] = "ims-value"
            local_call_options = { if_modified_since: "ims-value" }.merge options
            subject.expects(:blob_uri).with(container_name, blob_name, query, local_call_options).returns(uri)
            subject.stubs(:call).with(verb, uri, nil, request_headers, local_call_options).returns(response)
            subject.list_page_blob_ranges container_name, blob_name, local_call_options
          end

          it "modifies the request headers when provided a :if_unmodified_since value" do
            request_headers["If-Unmodified-Since"] = "iums-value"
            local_call_options = { if_unmodified_since: "iums-value" }.merge options
            subject.expects(:blob_uri).with(container_name, blob_name, query, local_call_options).returns(uri)
            subject.stubs(:call).with(verb, uri, nil, request_headers, local_call_options).returns(response)
            subject.list_page_blob_ranges container_name, blob_name, local_call_options
          end

          it "modifies the request headers when provided a :if_match value" do
            request_headers["If-Match"] = "im-value"
            local_call_options = { if_match: "im-value" }.merge options
            subject.expects(:blob_uri).with(container_name, blob_name, query, local_call_options).returns(uri)
            subject.stubs(:call).with(verb, uri, nil, request_headers, local_call_options).returns(response)
            subject.list_page_blob_ranges container_name, blob_name, local_call_options
          end

          it "modifies the request headers when provided a :if_none_match value" do
            request_headers["If-None-Match"] = "inm-value"
            local_call_options = { if_none_match: "inm-value" }.merge options
            subject.expects(:blob_uri).with(container_name, blob_name, query, local_call_options).returns(uri)
            subject.stubs(:call).with(verb, uri, nil, request_headers, local_call_options).returns(response)
            subject.list_page_blob_ranges container_name, blob_name, local_call_options
          end
        end
      end

      describe "#resize_page_blob" do
        let(:verb) { :put }
        let(:query) { { "comp" => "properties" } }
        let(:size) { 2048 }
        let(:request_headers) { { "x-ms-blob-content-length" => size.to_s } }

        before {
          subject.stubs(:blob_uri).with(container_name, blob_name, query).returns(uri)
          subject.stubs(:call).with(verb, uri, nil, request_headers, {}).returns(response)
        }

        it "resizes the page blob" do
          subject.expects(:call).with(verb, uri, nil, request_headers, content_length: size).returns(response)
          subject.resize_page_blob container_name, blob_name, size
        end

        describe "when the option hash is used" do
          it "modifies the request headers when provided a :if_modified_since value" do
            request_headers["If-Modified-Since"] = "ims-value"
            options = { content_length: size, if_modified_since: "ims-value" }
            subject.stubs(:call).with(verb, uri, nil, request_headers, options).returns(response)
            subject.resize_page_blob container_name, blob_name, size, options
          end

          it "modifies the request headers when provided a :if_unmodified_since value" do
            request_headers["If-Unmodified-Since"] = "iums-value"
            options = { content_length: size, if_unmodified_since: "iums-value" }
            subject.stubs(:call).with(verb, uri, nil, request_headers, options).returns(response)
            subject.resize_page_blob container_name, blob_name, size, options
          end

          it "modifies the request headers when provided a :if_match value" do
            request_headers["If-Match"] = "im-value"
            options = { content_length: size, if_match: "im-value" }
            subject.stubs(:call).with(verb, uri, nil, request_headers, options).returns(response)
            subject.resize_page_blob container_name, blob_name, size, options
          end

          it "modifies the request headers when provided a :if_none_match value" do
            request_headers["If-None-Match"] = "inm-value"
            options = { content_length: size, if_none_match: "inm-value" }
            subject.stubs(:call).with(verb, uri, nil, request_headers, options).returns(response)
            subject.resize_page_blob container_name, blob_name, size, options
          end
        end
      end

      describe "#set_sequence_number" do
        let(:verb) { :put }
        let(:query) { { "comp" => "properties" } }
        let(:action) { :update }
        let(:number) { 1024 }
        let(:request_headers) { {} }

        before {
          subject.stubs(:blob_uri).with(container_name, blob_name, query).returns(uri)
          subject.stubs(:call).with(verb, uri, nil, request_headers, {}).returns(response)
        }

        it 'set the page blob\'s sequence number' do
          options = { sequence_number_action: action, sequence_number: number }
          subject.expects(:call).with(verb, uri, nil, request_headers, options).returns(response)
          request_headers["x-ms-sequence-number-action"] = action.to_s
          request_headers["x-ms-blob-sequence-number"] = number.to_s
          subject.set_sequence_number container_name, blob_name, action, number
        end

        it 'set the page blob\'s sequence number to the higher of current or the value in the request' do
          action = :max
          options = { sequence_number_action: action, sequence_number: number }
          subject.expects(:call).with(verb, uri, nil, request_headers, options).returns(response)
          request_headers["x-ms-sequence-number-action"] = action.to_s
          request_headers["x-ms-blob-sequence-number"] = number.to_s
          subject.set_sequence_number container_name, blob_name, action, number
        end

        it 'increase the page blob\'s sequence number by 1' do
          action = :increment
          options = { sequence_number_action: action, sequence_number: nil }
          subject.expects(:call).with(verb, uri, nil, request_headers, options).returns(response)
          request_headers["x-ms-sequence-number-action"] = action.to_s
          subject.set_sequence_number container_name, blob_name, action, nil
        end

        it 'increase the page blob\'s sequence number should ignore the number' do
          action = :increment
          options = { sequence_number_action: action, sequence_number: number }
          subject.expects(:call).with(verb, uri, nil, request_headers, options).returns(response)
          request_headers["x-ms-sequence-number-action"] = action.to_s
          subject.set_sequence_number container_name, blob_name, action, number
        end

        describe "when the option hash is used" do
          before {
            request_headers["x-ms-sequence-number-action"] = action.to_s
            request_headers["x-ms-blob-sequence-number"] = number.to_s
          }

          it "modifies the request headers when provided a :if_modified_since value" do
            request_headers["If-Modified-Since"] = "ims-value"
            options = { sequence_number_action: action, sequence_number: number, if_modified_since: "ims-value" }
            subject.stubs(:call).with(verb, uri, nil, request_headers, options).returns(response)
            subject.set_sequence_number container_name, blob_name, action, number, options
          end

          it "modifies the request headers when provided a :if_unmodified_since value" do
            request_headers["If-Unmodified-Since"] = "iums-value"
            options = { sequence_number_action: action, sequence_number: number, if_unmodified_since: "iums-value" }
            subject.stubs(:call).with(verb, uri, nil, request_headers, options).returns(response)
            subject.set_sequence_number container_name, blob_name, action, number, options
          end

          it "modifies the request headers when provided a :if_match value" do
            request_headers["If-Match"] = "im-value"
            options = { sequence_number_action: action, sequence_number: number, if_match: "im-value" }
            subject.stubs(:call).with(verb, uri, nil, request_headers, options).returns(response)
            subject.set_sequence_number container_name, blob_name, action, number, options
          end

          it "modifies the request headers when provided a :if_none_match value" do
            request_headers["If-None-Match"] = "inm-value"
            options = { sequence_number_action: action, sequence_number: number, if_none_match: "inm-value" }
            subject.stubs(:call).with(verb, uri, nil, request_headers, options).returns(response)
            subject.set_sequence_number container_name, blob_name, action, number, options
          end
        end
      end

      describe "#create_append_blob" do
        let(:verb) { :put }
        let(:request_headers) {
          {
            "x-ms-blob-type" => "AppendBlob",
            "Content-Length" => 0.to_s,
            "x-ms-blob-content-type" => "application/octet-stream"
          }
        }

        before {
          subject.stubs(:blob_uri).with(container_name, blob_name, {}).returns(uri)
          subject.stubs(:call).with(verb, uri, nil, request_headers, {}).returns(response)
          serialization.stubs(:blob_from_headers).with(response_headers).returns(blob)
        }

        it "assembles a URI for the request" do
          subject.expects(:blob_uri).with(container_name, blob_name, {}).returns(uri)
          subject.create_append_blob container_name, blob_name
        end

        it "calls StorageService#call with the prepared request" do
          subject.expects(:call).with(verb, uri, nil, request_headers, {}).returns(response)
          subject.create_append_blob container_name, blob_name
        end

        it "returns a Blob on success" do
          result = subject.create_append_blob container_name, blob_name
          _(result).must_be_kind_of Azure::Storage::Blob::Blob
          _(result).must_equal blob
          _(result.name).must_equal blob_name
        end

        describe "when the options Hash is used" do
          it "modifies the request headers when provided a :content_type value" do
            request_headers["x-ms-blob-content-type"] = "bct-value"
            options = { content_type: "bct-value" }
            subject.stubs(:call).with(verb, uri, nil, request_headers, options).returns(response)
            subject.create_append_blob container_name, blob_name, options
          end

          it "modifies the request headers when provided a :content_encoding value" do
            request_headers["x-ms-blob-content-encoding"] = "bce-value"
            options = { content_encoding: "bce-value" }
            subject.stubs(:call).with(verb, uri, nil, request_headers, options).returns(response)
            subject.create_append_blob container_name, blob_name, options
          end

          it "modifies the request headers when provided a :content_language value" do
            request_headers["x-ms-blob-content-language"] = "bcl-value"
            options = { content_language: "bcl-value" }
            subject.stubs(:call).with(verb, uri, nil, request_headers, options).returns(response)
            subject.create_append_blob container_name, blob_name, options
          end

          it "modifies the request headers when provided a :content_md5 value" do
            request_headers["x-ms-blob-content-md5"] = "bcm-value"
            options = { content_md5: "bcm-value" }
            subject.stubs(:call).with(verb, uri, nil, request_headers, options).returns(response)
            subject.create_append_blob container_name, blob_name, options
          end

          it "modifies the request headers when provided a :cache_control value" do
            request_headers["x-ms-blob-cache-control"] = "bcc-value"
            options = { cache_control: "bcc-value" }
            subject.stubs(:call).with(verb, uri, nil, request_headers, options).returns(response)
            subject.create_append_blob container_name, blob_name, options
          end

          it "modifies the request headers when provided a :content_disposition value" do
            request_headers["x-ms-blob-content-disposition"] = "bcd-value"
            options = { content_disposition: "bcd-value" }
            subject.stubs(:call).with(verb, uri, nil, request_headers, options).returns(response)
            subject.create_append_blob container_name, blob_name, options
          end

          it "modifies the request headers when provided a :transactional_md5 value" do
            request_headers["Content-MD5"] = "tm-value"
            options = { transactional_md5: "tm-value" }
            subject.stubs(:call).with(verb, uri, nil, request_headers, options).returns(response)
            subject.create_append_blob container_name, blob_name, options
          end


          it "modifies the request headers when provided a :if_modified_since value" do
            request_headers["If-Modified-Since"] = "ims-value"
            options = { if_modified_since: "ims-value" }
            subject.stubs(:call).with(verb, uri, nil, request_headers, options).returns(response)
            subject.create_append_blob container_name, blob_name, options
          end

          it "modifies the request headers when provided a :if_unmodified_since value" do
            request_headers["If-Unmodified-Since"] = "iums-value"
            options = { if_unmodified_since: "iums-value" }
            subject.stubs(:call).with(verb, uri, nil, request_headers, options).returns(response)
            subject.create_append_blob container_name, blob_name, options
          end

          it "modifies the request headers when provided a :if_match value" do
            request_headers["If-Match"] = "im-value"
            options = { if_match: "im-value" }
            subject.stubs(:call).with(verb, uri, nil, request_headers, options).returns(response)
            subject.create_append_blob container_name, blob_name, options
          end

          it "modifies the request headers when provided a :if_none_match value" do
            request_headers["If-None-Match"] = "inm-value"
            options = { if_none_match: "inm-value" }
            subject.stubs(:call).with(verb, uri, nil, request_headers, options).returns(response)
            subject.create_append_blob container_name, blob_name, options
          end

          it "modifies the request headers when provided a :metadata value" do
            request_headers["x-ms-meta-MetadataKey"] = "MetaDataValue"
            request_headers["x-ms-meta-MetadataKey1"] = "MetaDataValue1"
            options = { metadata: { "MetadataKey" => "MetaDataValue", "MetadataKey1" => "MetaDataValue1" } }
            subject.stubs(:call).with(verb, uri, nil, request_headers, options).returns(response)
            subject.create_append_blob container_name, blob_name, options
          end

          it "does not modify the request headers when provided an unknown value" do
            options = { unknown_key: "some_value" }
            subject.stubs(:call).with(verb, uri, nil, request_headers, options).returns(response)
            subject.create_append_blob container_name, blob_name, options
          end
        end
      end

      describe "#append_blob_block" do
        let(:verb) { :put }
        let(:content) { "some content" }
        let(:content_md5) { "123aBfE=" }
        let(:lease_id) { "lease_id" }
        let(:max_size) { 123 }
        let(:append_position) { 999 }
        let(:request_headers) { {} }

        before {
          query.update("comp" => "appendblock")
          subject.stubs(:blob_uri).with(container_name, blob_name, query).returns(uri)
          subject.stubs(:call).with(verb, uri, content, request_headers, {}).returns(response)
        }

        it "assembles a URI for the request" do
          subject.expects(:blob_uri).with(container_name, blob_name, query).returns(uri)
          subject.append_blob_block container_name, blob_name, content
        end

        it "calls StorageService#call with the prepared request" do
          subject.expects(:call).with(verb, uri, content, request_headers, {}).returns(response)
          subject.append_blob_block container_name, blob_name, content
        end

        describe "when the options Hash is used" do
          it "modifies the request headers when provided a :content_md5 value" do
            request_headers["Content-MD5"] = content_md5
            options = { content_md5: content_md5 }
            subject.stubs(:call).with(verb, uri, content, request_headers, options).returns(response)
            subject.append_blob_block container_name, blob_name, content, options
          end

          it "modifies the request headers when provided a :lease_id value" do
            request_headers["x-ms-lease-id"] = lease_id
            options = { lease_id: lease_id }
            subject.stubs(:call).with(verb, uri, content, request_headers, options).returns(response)
            subject.append_blob_block container_name, blob_name, content, options
          end

          it "modifies the request headers when provided a :max_size value" do
            request_headers["x-ms-blob-condition-maxsize"] = max_size
            options = { max_size: max_size }
            subject.stubs(:call).with(verb, uri, content, request_headers, options).returns(response)
            subject.append_blob_block container_name, blob_name, content, options
          end

          it "modifies the request headers when provided a :append_position value" do
           request_headers["x-ms-blob-condition-appendpos"] = append_position
           options = { append_position: append_position }
           subject.stubs(:call).with(verb, uri, content, request_headers, options).returns(response)
           subject.append_blob_block container_name, blob_name, content, options
         end

          it "modifies the request headers when provided a :if_modified_since value" do
            request_headers["If-Modified-Since"] = "ims-value"
            options = { if_modified_since: "ims-value" }
            subject.stubs(:call).with(verb, uri, content, request_headers, options).returns(response)
            subject.append_blob_block container_name, blob_name, content, options
          end

          it "modifies the request headers when provided a :if_unmodified_since value" do
            request_headers["If-Unmodified-Since"] = "iums-value"
            options = { if_unmodified_since: "iums-value" }
            subject.stubs(:call).with(verb, uri, content, request_headers, options).returns(response)
            subject.append_blob_block container_name, blob_name, content, options
          end

          it "modifies the request headers when provided a :if_match value" do
            request_headers["If-Match"] = "im-value"
            options = { if_match: "im-value" }
            subject.stubs(:call).with(verb, uri, content, request_headers, options).returns(response)
            subject.append_blob_block container_name, blob_name, content, options
          end

          it "modifies the request headers when provided a :if_none_match value" do
            request_headers["If-None-Match"] = "inm-value"
            options = { if_none_match: "inm-value" }
            subject.stubs(:call).with(verb, uri, content, request_headers, options).returns(response)
            subject.append_blob_block container_name, blob_name, content, options
          end

          it "does not modify the request headers when provided an unknown value" do
            options = { unknown_key: "some_value" }
            subject.stubs(:call).with(verb, uri, content, request_headers, options).returns(response)
            subject.append_blob_block container_name, blob_name, content, options
          end
        end
      end

      describe "#set_blob_properties" do
        let(:verb) { :put }
        let(:request_headers) { {} }

        before {
          query.update("comp" => "properties")
          response.stubs(:success?).returns(true)
          subject.stubs(:blob_uri).with(container_name, blob_name, query).returns(uri)
          subject.stubs(:call).with(verb, uri, nil, request_headers, {}).returns(response)
        }

        it "assembles a URI for the request" do
          subject.expects(:blob_uri).with(container_name, blob_name, query).returns(uri)
          subject.set_blob_properties container_name, blob_name
        end

        it "calls StorageService#call with the prepared request" do
          subject.expects(:call).with(verb, uri, nil, request_headers, {}).returns(response)
          subject.set_blob_properties container_name, blob_name
        end

        it "returns nil on success" do
          result = subject.set_blob_properties container_name, blob_name
          _(result).must_equal nil
        end

        describe "when the options Hash is used" do
          it "modifies the request headers when provided a :content_type value" do
            request_headers["x-ms-blob-content-type"] = "bct-value"
            options = { content_type: "bct-value" }
            subject.stubs(:call).with(verb, uri, nil, request_headers, options).returns(response)
            subject.set_blob_properties container_name, blob_name, options
          end

          it "modifies the request headers when provided a :content_encoding value" do
            request_headers["x-ms-blob-content-encoding"] = "bce-value"
            options = { content_encoding: "bce-value" }
            subject.stubs(:call).with(verb, uri, nil, request_headers, options).returns(response)
            subject.set_blob_properties container_name, blob_name, options
          end

          it "modifies the request headers when provided a :content_language value" do
            request_headers["x-ms-blob-content-language"] = "bcl-value"
            options = { content_language: "bcl-value" }
            subject.stubs(:call).with(verb, uri, nil, request_headers, options).returns(response)
            subject.set_blob_properties container_name, blob_name, options
          end

          it "modifies the request headers when provided a :content_md5 value" do
            request_headers["x-ms-blob-content-md5"] = "bcm-value"
            options = { content_md5: "bcm-value" }
            subject.stubs(:call).with(verb, uri, nil, request_headers, options).returns(response)
            subject.set_blob_properties container_name, blob_name, options
          end

          it "modifies the request headers when provided a :cache_control value" do
            request_headers["x-ms-blob-cache-control"] = "bcc-value"
            options = { cache_control: "bcc-value" }
            subject.stubs(:call).with(verb, uri, nil, request_headers, options).returns(response)
            subject.set_blob_properties container_name, blob_name, options
          end

          it "modifies the request headers when provided a :content_length value" do
            request_headers["x-ms-blob-content-length"] = "37"
            options = { content_length: 37.to_s }
            subject.stubs(:call).with(verb, uri, nil, request_headers, options).returns(response)
            subject.set_blob_properties container_name, blob_name, options
          end

          it "modifies the request headers when provided a :content_disposition value" do
            request_headers["x-ms-blob-content-disposition"] = "bcd-value"
            options = { content_disposition: "bcd-value" }
            subject.stubs(:call).with(verb, uri, nil, request_headers, options).returns(response)
            subject.set_blob_properties container_name, blob_name, options
          end

          it "modifies the request headers when provided a :sequence_number_action value" do
            request_headers["x-ms-sequence-number-action"] = "anyvalue"
            options = { sequence_number_action: :anyvalue }
            subject.stubs(:call).with(verb, uri, nil, request_headers, options).returns(response)
            subject.set_blob_properties container_name, blob_name, options
          end

          it "modifies the request headers when provided a :sequence_number value" do
            request_headers["x-ms-sequence-number-action"] = :max.to_s
            request_headers["x-ms-blob-sequence-number"] = "37"
            options = { sequence_number_action: :max, sequence_number: 37 }
            subject.stubs(:call).with(verb, uri, nil, request_headers, options).returns(response)
            subject.set_blob_properties container_name, blob_name, options
          end

          it "does not modify the request headers when provided an unknown value" do
            options = { unknown_key: "some_value" }
            subject.stubs(:call).with(verb, uri, nil, request_headers, options).returns(response)
            subject.set_blob_properties container_name, blob_name, options
          end
        end
      end

      describe "#set_blob_metadata" do
        let(:verb) { :put }
        let(:blob_metadata) { { "MetadataKey" => "MetaDataValue", "MetadataKey1" => "MetaDataValue1" } }
        let(:request_headers) { { "x-ms-meta-MetadataKey" => "MetaDataValue", "x-ms-meta-MetadataKey1" => "MetaDataValue1"} }

        before {
          query.update("comp" => "metadata")
          response.stubs(:success?).returns(true)
          subject.stubs(:blob_uri).with(container_name, blob_name, query).returns(uri)
          subject.stubs(:call).with(verb, uri, nil, request_headers, {}).returns(response)
        }

        it "assembles a URI for the request" do
          subject.expects(:blob_uri).with(container_name, blob_name, query).returns(uri)
          subject.set_blob_metadata container_name, blob_name, blob_metadata
        end

        it "calls StorageService#call with the prepared request" do
          subject.expects(:call).with(verb, uri, nil, request_headers, {}).returns(response)
          subject.set_blob_metadata container_name, blob_name, blob_metadata
        end

        it "returns nil on success" do
          result = subject.set_blob_metadata container_name, blob_name, blob_metadata
          _(result).must_equal nil
        end
      end

      describe "#get_blob_properties" do
        let(:verb) { :head }
        let(:options) { { request_location_mode: Azure::Storage::Common::RequestLocationMode::PRIMARY_OR_SECONDARY} }
        let(:request_headers) { {} }

        before {
          subject.stubs(:blob_uri).with(container_name, blob_name, query, options).returns(uri)
          subject.stubs(:call).with(verb, uri, nil, request_headers, {}).returns(response)
          serialization.stubs(:blob_from_headers).with(response_headers).returns(blob)
        }

        it "assembles a URI for the request" do
          subject.expects(:blob_uri).with(container_name, blob_name, query, options).returns(uri)
          subject.get_blob_properties container_name, blob_name
        end

        it "calls StorageService#call with the prepared request" do
          subject.expects(:call).with(verb, uri, nil, request_headers, options).returns(response)
          subject.get_blob_properties container_name, blob_name
        end

        it "returns the blob on success" do
          result = subject.get_blob_properties container_name, blob_name

          _(result).must_be_kind_of Azure::Storage::Blob::Blob
          _(result).must_equal blob
          _(result.name).must_equal blob_name
        end

        describe "when snapshot is provided" do
          let(:snapshot) { "snapshot" }
          before { query["snapshot"] = snapshot }

          it "modifies the blob uri query string with the snapshot" do
            local_call_options = { snapshot: snapshot }.merge options
            subject.stubs(:call).with(verb, uri, nil, request_headers, local_call_options).returns(response)
            subject.expects(:blob_uri).with(container_name, blob_name, query, local_call_options).returns(uri)
            subject.get_blob_properties container_name, blob_name, local_call_options
          end

          it "sets the snapshot value on the returned blob" do
            local_call_options = { snapshot: snapshot }.merge options
            subject.expects(:blob_uri).with(container_name, blob_name, query, local_call_options).returns(uri)
            subject.stubs(:call).with(verb, uri, nil, request_headers, local_call_options).returns(response)
            result = subject.get_blob_properties container_name, blob_name, local_call_options
            _(result.snapshot).must_equal snapshot
          end
        end
      end

      describe "#get_blob_metadata" do
        let(:verb) { :get }
        let(:options) { { request_location_mode: Azure::Storage::Common::RequestLocationMode::PRIMARY_OR_SECONDARY} }
        let(:request_headers) { {} }

        before {
          query["comp"] = "metadata"

          subject.stubs(:blob_uri).with(container_name, blob_name, query, options).returns(uri)
          subject.stubs(:call).with(verb, uri, nil, request_headers, options).returns(response)
          serialization.stubs(:blob_from_headers).with(response_headers).returns(blob)
        }

        it "assembles a URI for the request" do
          subject.expects(:blob_uri).with(container_name, blob_name, query, options).returns(uri)
          subject.get_blob_metadata container_name, blob_name
        end

        it "calls StorageService#call with the prepared request" do
          subject.expects(:call).with(verb, uri, nil, request_headers, options).returns(response)
          subject.get_blob_metadata container_name, blob_name
        end

        it "returns the blob on success" do
          result = subject.get_blob_metadata container_name, blob_name

          _(result).must_be_kind_of Azure::Storage::Blob::Blob
          _(result).must_equal blob
          _(result.name).must_equal blob_name
        end

        describe "when snapshot is provided" do
          let(:snapshot) { "snapshot" }
          before {
            query["snapshot"] = snapshot
            subject.stubs(:blob_uri).with(container_name, blob_name, query).returns(uri)
          }

          it "modifies the blob uri query string with the snapshot" do
            local_call_options = { snapshot: snapshot }.merge options
            subject.expects(:blob_uri).with(container_name, blob_name, query, local_call_options).returns(uri)
            subject.stubs(:call).with(verb, uri, nil, request_headers, local_call_options).returns(response)
            subject.get_blob_metadata container_name, blob_name, local_call_options
          end

          it "sets the snapshot value on the returned blob" do
            local_call_options = { snapshot: snapshot }.merge options
            subject.expects(:blob_uri).with(container_name, blob_name, query, local_call_options).returns(uri)
            subject.stubs(:call).with(verb, uri, nil, request_headers, local_call_options).returns(response)
            result = subject.get_blob_metadata container_name, blob_name, local_call_options
            _(result.snapshot).must_equal snapshot
          end
        end
      end

      describe "#get_blob" do
        let(:verb) { :get }
        let(:options) { { request_location_mode: Azure::Storage::Common::RequestLocationMode::PRIMARY_OR_SECONDARY} }

        before {
          response.stubs(:success?).returns(true)

          subject.stubs(:blob_uri).with(container_name, blob_name, query, options).returns(uri)
          subject.stubs(:call).with(verb, uri, nil, request_headers, options).returns(response)
          serialization.stubs(:blob_from_headers).with(response_headers).returns(blob)
        }

        it "assembles a URI for the request" do
          subject.expects(:blob_uri).with(container_name, blob_name, query, options).returns(uri)
          subject.get_blob container_name, blob_name
        end

        it "calls StorageService#call with the prepared request" do
          subject.expects(:call).with(verb, uri, nil, request_headers, options).returns(response)
          subject.get_blob container_name, blob_name
        end

        it "returns the blob and blob contents on success" do
          returned_blob, returned_blob_contents = subject.get_blob container_name, blob_name

          _(returned_blob).must_be_kind_of Azure::Storage::Blob::Blob
          _(returned_blob).must_equal blob

          _(returned_blob_contents).must_equal response_body
        end

        describe "when snapshot is provided" do
          let(:source_snapshot) { "source-snapshot" }
          before { query["snapshot"] = source_snapshot }

          it "modifies the blob uri query string with the snapshot" do
            local_call_options = { snapshot: source_snapshot }.merge options
            subject.expects(:blob_uri).with(container_name, blob_name, query, local_call_options).returns(uri)
            subject.stubs(:call).with(verb, uri, nil, request_headers, local_call_options).returns(response)
            subject.get_blob container_name, blob_name, local_call_options
          end
        end

        # describe "when start_range is provided" do
        #   let(:start_range){ 255 }
        #   before { request_headers["x-ms-range"]="#{start_range}-" }

        #   it "modifies the request headers with the desired range" do
        #     subject.expects(:call).with(verb, uri, nil, request_headers).returns(response)
        #     subject.get_blob container_name, blob_name, start_range
        #   end
        # end

        # describe "when end_range is provided" do
        #   let(:end_range){ 512 }
        #   before { request_headers["x-ms-range"]="0-#{end_range}" }

        #   it "modifies the request headers with the desired range" do
        #     subject.expects(:call).with(verb, uri, nil, request_headers).returns(response)
        #     subject.get_blob container_name, blob_name, nil, end_range
        #   end
        # end

        describe "when both start_range and end_range are provided" do
          let(:start_range) { 255 }
          let(:end_range) { 512 }
          before {
            request_headers["x-ms-range"] = "bytes=#{start_range}-#{end_range}"
          }

          it "modifies the request headers with the desired range" do
            local_call_options = { start_range: start_range, end_range: end_range }.merge options
            subject.expects(:blob_uri).with(container_name, blob_name, query, local_call_options).returns(uri)
            subject.expects(:call).with(verb, uri, nil, request_headers, local_call_options).returns(response)
            subject.get_blob container_name, blob_name, local_call_options
          end
        end

        describe "when get_content_md5 is true" do
          let(:get_content_md5) { true }

          describe "and a range is specified" do
            let(:start_range) { 255 }
            let(:end_range) { 512 }
            before {
              request_headers["x-ms-range"] = "bytes=#{start_range}-#{end_range}"
              request_headers["x-ms-range-get-content-md5"] = "true"
            }

            it "modifies the request headers to include the x-ms-range-get-content-md5 header" do
              local_call_options = { start_range: start_range, end_range: end_range, get_content_md5: true }.merge options
              subject.expects(:blob_uri).with(container_name, blob_name, query, local_call_options).returns(uri)
              subject.expects(:call).with(verb, uri, nil, request_headers, local_call_options).returns(response)
              subject.get_blob container_name, blob_name, local_call_options
            end
          end

          describe "and a range is NOT specified" do
            it "does not modify the request headers" do
              local_call_options = { get_content_md5: true }.merge options
              subject.expects(:blob_uri).with(container_name, blob_name, query, local_call_options).returns(uri)
              subject.expects(:call).with(verb, uri, nil, request_headers, local_call_options).returns(response)
              subject.get_blob container_name, blob_name, local_call_options
            end
          end
        end
      end

      describe "#delete_blob" do
        let(:verb) { :delete }

        before {
          response.stubs(:success?).returns(true)
          request_headers["x-ms-delete-snapshots"] = "include"

          subject.stubs(:blob_uri).with(container_name, blob_name, query).returns(uri)
          subject.stubs(:call).with(verb, uri, nil, request_headers, delete_snapshots: :include).returns(response)
        }

        it "assembles a URI for the request" do
          subject.expects(:blob_uri).with(container_name, blob_name, query).returns(uri)
          subject.delete_blob container_name, blob_name
        end

        it "calls StorageService#call with the prepared request" do
          subject.expects(:call).with(verb, uri, nil, request_headers, delete_snapshots: :include).returns(response)
          subject.delete_blob container_name, blob_name
        end

        it "returns nil on success" do
          result = subject.delete_blob container_name, blob_name
          _(result).must_equal nil
        end

        describe "when snapshot is provided" do
          let(:source_snapshot) { "source-snapshot" }
          before {
            request_headers.delete "x-ms-delete-snapshots"
            query["snapshot"] = source_snapshot
          }

          it "modifies the blob uri query string with the snapshot" do
            options = { snapshot: source_snapshot }
            subject.stubs(:call).with(verb, uri, nil, request_headers, options).returns(response)
            subject.expects(:blob_uri).with(container_name, blob_name, query).returns(uri)
            subject.delete_blob container_name, blob_name, options
          end

          it "does not include a x-ms-delete-snapshots header" do
            options = { snapshot: source_snapshot }
            subject.expects(:call).with(verb, uri, nil, request_headers, options).returns(response)
            subject.delete_blob container_name, blob_name, options
          end
        end

        describe "when delete_snapshots is provided" do
          let(:delete_snapshots) { :anyvalue }
          before { request_headers["x-ms-delete-snapshots"] = delete_snapshots.to_s }

          it "modifies the request headers with the provided value" do
            options = { delete_snapshots: delete_snapshots }
            subject.expects(:call).with(verb, uri, nil, request_headers, options).returns(response)
            subject.delete_blob container_name, blob_name, options
          end
        end

        describe "when snapshot is provided and delete_snapshots is provided" do
          let(:source_snapshot) { "source-snapshot" }
          let(:delete_snapshots) { :anyvalue }
          before {
            request_headers.delete "x-ms-delete-snapshots"
            query["snapshot"] = source_snapshot
          }

          it "modifies the blob uri query string with the snapshot" do
            options = { snapshot: source_snapshot, delete_snapshots: delete_snapshots }
            subject.stubs(:call).with(verb, uri, nil, request_headers, options).returns(response)
            subject.expects(:blob_uri).with(container_name, blob_name, query).returns(uri)
            subject.delete_blob container_name, blob_name, options
          end

          it "does not include a x-ms-delete-snapshots header" do
            options = { snapshot: source_snapshot, delete_snapshots: delete_snapshots }
            subject.stubs(:call).with(verb, uri, nil, request_headers, options).returns(response)
            subject.expects(:call).with(verb, uri, nil, request_headers, options).returns(response)
            subject.delete_blob container_name, blob_name, options
          end
        end
      end

      describe "#create_blob_snapshot" do
        let(:verb) { :put }
        let(:snapshot_id) { "snapshot-id" }

        before {
          query["comp"] = "snapshot"

          response_headers["x-ms-snapshot"] = snapshot_id

          subject.stubs(:blob_uri).with(container_name, blob_name, query).returns(uri)
          subject.stubs(:call).with(verb, uri, nil, request_headers, {}).returns(response)
        }

        it "assembles a URI for the request" do
          subject.expects(:blob_uri).with(container_name, blob_name, query).returns(uri)
          subject.create_blob_snapshot container_name, blob_name
        end

        it "calls StorageService#call with the prepared request" do
          subject.expects(:call).with(verb, uri, nil, request_headers, {}).returns(response)
          subject.create_blob_snapshot container_name, blob_name
        end

        it "returns the snapshot id on success" do
          result = subject.create_blob_snapshot container_name, blob_name
          _(result).must_be_kind_of String
          _(result).must_equal snapshot_id
        end

        describe "when the options Hash is used" do
          it "modifies the request headers when provided a :if_modified_since value" do
            request_headers["If-Modified-Since"] = "ims-value"
            options = { if_modified_since: "ims-value" }
            subject.expects(:call).with(verb, uri, nil, request_headers, options).returns(response)
            subject.create_blob_snapshot container_name, blob_name, options
          end

          it "modifies the request headers when provided a :if_unmodified_since value" do
            request_headers["If-Unmodified-Since"] = "iums-value"
            options = { if_unmodified_since: "iums-value" }
            subject.expects(:call).with(verb, uri, nil, request_headers, options).returns(response)
            subject.create_blob_snapshot container_name, blob_name, options
          end

          it "modifies the request headers when provided a :if_match value" do
            request_headers["If-Match"] = "im-value"
            options = { if_match: "im-value" }
            subject.expects(:call).with(verb, uri, nil, request_headers, options).returns(response)
            subject.create_blob_snapshot container_name, blob_name, options
          end

          it "modifies the request headers when provided a :if_none_match value" do
            request_headers["If-None-Match"] = "inm-value"
            options = { if_none_match: "inm-value" }
            subject.expects(:call).with(verb, uri, nil, request_headers, options).returns(response)
            subject.create_blob_snapshot container_name, blob_name, options
          end

          it "modifies the request headers when provided a :metadata value" do
            request_headers["x-ms-meta-MetadataKey"] = "MetaDataValue"
            request_headers["x-ms-meta-MetadataKey1"] = "MetaDataValue1"
            options = { metadata: { "MetadataKey" => "MetaDataValue", "MetadataKey1" => "MetaDataValue1" } }
            subject.expects(:call).with(verb, uri, nil, request_headers, options).returns(response)
            subject.create_blob_snapshot container_name, blob_name, options
          end

          it "does not modify the request headers when provided an unknown value" do
            options = { unknown_key: "some_value" }
            subject.expects(:call).with(verb, uri, nil, request_headers, options).returns(response)
            subject.create_blob_snapshot container_name, blob_name, options
          end
        end
      end

      describe "#copy_blob" do
        let(:verb) { :put }
        let(:source_container_name) { "source-container-name" }
        let(:source_blob_name) { "source-blob-name" }
        let(:source_uri) { URI.parse("http://dummy.uri/source") }

        let(:copy_id) { "copy-id" }
        let(:copy_status) { "copy-status" }

        before {
          request_headers["x-ms-copy-source"] = source_uri.to_s

          response_headers["x-ms-copy-id"] = copy_id
          response_headers["x-ms-copy-status"] = copy_status

          subject.stubs(:blob_uri).with(container_name, blob_name, {}).returns(uri)
          subject.stubs(:blob_uri).with(source_container_name, source_blob_name, query).returns(source_uri)
          subject.stubs(:call).with(verb, uri, nil, request_headers, {}).returns(response)
        }

        it "assembles a URI for the request" do
          subject.expects(:blob_uri).with(container_name, blob_name, {}).returns(uri)
          subject.copy_blob container_name, blob_name, source_container_name, source_blob_name
        end

        it "assembles the source URI and places it in the header" do
          subject.expects(:blob_uri).with(source_container_name, source_blob_name, query).returns(source_uri)
          subject.copy_blob container_name, blob_name, source_container_name, source_blob_name
        end

        it "calls with source URI" do
          subject.expects(:blob_uri).with(container_name, blob_name, {}).returns(uri)
          subject.expects(:call).with(verb, uri, nil, request_headers, {}).returns(response)
          subject.copy_blob_from_uri container_name, blob_name, source_uri.to_s
        end

        it "calls StorageService#call with the prepared request" do
          subject.expects(:call).with(verb, uri, nil, request_headers, {}).returns(response)
          subject.copy_blob container_name, blob_name, source_container_name, source_blob_name
        end

        it "returns the copy id and copy status on success" do
          returned_copy_id, returned_copy_status = subject.copy_blob container_name, blob_name, source_container_name, source_blob_name
          _(returned_copy_id).must_equal copy_id
          _(returned_copy_status).must_equal copy_status
        end

        describe "when snapshot is provided" do
          let(:source_snapshot) { "source-snapshot" }
          before {
            query["snapshot"] = source_snapshot
          }

          it "modifies the source blob uri query string with the snapshot" do
            subject.expects(:blob_uri).with(source_container_name, source_blob_name, query).returns(source_uri)
            options = { source_snapshot: source_snapshot }
            subject.stubs(:call).with(verb, uri, nil, request_headers, options).returns(response)
            subject.copy_blob container_name, blob_name, source_container_name, source_blob_name, options
          end
        end

        describe "when the options Hash is used" do
          it "modifies the request headers when provided a :dest_if_modified_since value" do
            request_headers["If-Modified-Since"] = "ims-value"
            options = { dest_if_modified_since: "ims-value" }
            subject.expects(:call).with(verb, uri, nil, request_headers, options).returns(response)
            subject.copy_blob container_name, blob_name, source_container_name, source_blob_name, options
          end

          it "modifies the request headers when provided a :dest_if_unmodified_since value" do
            request_headers["If-Unmodified-Since"] = "iums-value"
            options = { dest_if_unmodified_since: "iums-value" }
            subject.expects(:call).with(verb, uri, nil, request_headers, options).returns(response)
            subject.copy_blob container_name, blob_name, source_container_name, source_blob_name, options
          end

          it "modifies the request headers when provided a :dest_if_match value" do
            request_headers["If-Match"] = "im-value"
            options = { dest_if_match: "im-value" }
            subject.expects(:call).with(verb, uri, nil, request_headers, options).returns(response)
            subject.copy_blob container_name, blob_name, source_container_name, source_blob_name, options
          end

          it "modifies the request headers when provided a :dest_if_none_match value" do
            request_headers["If-None-Match"] = "inm-value"
            options = { dest_if_none_match: "inm-value" }
            subject.expects(:call).with(verb, uri, nil, request_headers, options).returns(response)
            subject.copy_blob container_name, blob_name, source_container_name, source_blob_name, options
          end

          it "modifies the request headers when provided a :source_if_modified_since value" do
            request_headers["x-ms-source-if-modified-since"] = "ims-value"
            options = { source_if_modified_since: "ims-value" }
            subject.expects(:call).with(verb, uri, nil, request_headers, options).returns(response)
            subject.copy_blob container_name, blob_name, source_container_name, source_blob_name, options
          end

          it "modifies the request headers when provided a :source_if_unmodified_since value" do
            request_headers["x-ms-source-if-unmodified-since"] = "iums-value"
            options = { source_if_unmodified_since: "iums-value" }
            subject.expects(:call).with(verb, uri, nil, request_headers, options).returns(response)
            subject.copy_blob container_name, blob_name, source_container_name, source_blob_name, options
          end

          it "modifies the request headers when provided a :source_if_match value" do
            request_headers["x-ms-source-if-match"] = "im-value"
            options = { source_if_match: "im-value" }
            subject.expects(:call).with(verb, uri, nil, request_headers, options).returns(response)
            subject.copy_blob container_name, blob_name, source_container_name, source_blob_name, options
          end

          it "modifies the request headers when provided a :source_if_none_match value" do
            request_headers["x-ms-source-if-none-match"] = "inm-value"
            options = { source_if_none_match: "inm-value" }
            subject.expects(:call).with(verb, uri, nil, request_headers, options).returns(response)
            subject.copy_blob container_name, blob_name, source_container_name, source_blob_name, options
          end

          it "modifies the request headers when provided a :metadata value" do
            request_headers["x-ms-meta-MetadataKey"] = "MetaDataValue"
            request_headers["x-ms-meta-MetadataKey1"] = "MetaDataValue1"
            options = { metadata: { "MetadataKey" => "MetaDataValue", "MetadataKey1" => "MetaDataValue1" } }
            subject.expects(:call).with(verb, uri, nil, request_headers, options).returns(response)
            subject.copy_blob container_name, blob_name, source_container_name, source_blob_name, options
          end

          it "does not modify the request headers when provided an unknown value" do
            options = { unknown_key: "some_value" }
            subject.expects(:call).with(verb, uri, nil, request_headers, options).returns(response)
            subject.copy_blob container_name, blob_name, source_container_name, source_blob_name, options
          end
        end
      end

      describe "#abort_copy_blob" do
        let(:verb) { :put }
        let(:lease_id) { "lease-id" }
        let(:copy_id) { "copy-id" }

        before {
          request_headers["x-ms-copy-action"] = "abort"

          query.update("comp" => "copy", "copyid" => copy_id)
          subject.stubs(:blob_uri).with(container_name, blob_name, query).returns(uri)

        }

        it "abort copy a blob" do
          subject.expects(:blob_uri).with(container_name, blob_name, query).returns(uri)
          subject.abort_copy_blob container_name, blob_name, copy_id
        end

        # it "abort copy a blob with an active lease" do
        #   request_headers["x-ms-lease-id"] = lease_id
        #   subject.expects(:blob_uri).with(container_name, blob_name, query).returns(uri)
        #   options = { lease_id: lease_id }
        #   subject.stubs(:call).with(verb, uri, nil, request_headers, options).returns(response)
        #   subject.abort_copy_blob container_name, blob_name, copy_id, options
        # end
      end

      describe "lease functions" do
        let(:verb) { :put }
        let(:lease_id) { "lease-id" }

        before {
          query.update("comp" => "lease")
          subject.stubs(:blob_uri).with(container_name, blob_name, query).returns(uri)
          subject.stubs(:container_uri).with(container_name, query).returns(uri)
          subject.stubs(:call).with(verb, uri, nil, request_headers, {}).returns(response)
        }

        describe "#acquire_blob_lease" do
          before {
            request_headers["x-ms-lease-action"] = "acquire"
            request_headers["x-ms-lease-duration"] = "-1"

            response.stubs(:success?).returns(true)
            response_headers["x-ms-lease-id"] = lease_id
          }

          it "assembles a URI for the request" do
            subject.expects(:blob_uri).with(container_name, blob_name, query).returns(uri)
            subject.acquire_blob_lease container_name, blob_name
          end

          it "calls StorageService#call with the prepared request" do
            subject.expects(:call).with(verb, uri, nil, request_headers, {}).returns(response)
            subject.acquire_blob_lease container_name, blob_name
          end

          it "returns lease id on success" do
            result = subject.acquire_blob_lease container_name, blob_name
            _(result).must_equal lease_id
          end

          describe "when passed a duration" do
            let(:duration) { 37 }
            before { request_headers["x-ms-lease-duration"] = "37" }

            it "modifies the headers to include the provided duration value" do
              options = { duration: duration }
              subject.expects(:call).with(verb, uri, nil, request_headers, options).returns(response)
              subject.acquire_blob_lease container_name, blob_name, options
            end
          end

          describe "when passed a proposed_lease_id" do
            let(:default_duration) { -1 }
            let(:proposed_lease_id) { "proposed-lease-id" }
            before { request_headers["x-ms-proposed-lease-id"] = proposed_lease_id }

            it "modifies the headers to include the proposed lease id" do
              options = { duration: default_duration, proposed_lease_id: proposed_lease_id }
              subject.expects(:call).with(verb, uri, nil, request_headers, options).returns(response)
              subject.acquire_blob_lease container_name, blob_name, options
            end
          end
        end

        describe "#renew_blob_lease" do
          before {
            request_headers["x-ms-lease-action"] = "renew"
            request_headers["x-ms-lease-id"] = lease_id

            response.stubs(:success?).returns(true)
            response_headers["x-ms-lease-id"] = lease_id
          }

          it "assembles a URI for the request" do
            subject.expects(:blob_uri).with(container_name, blob_name, query).returns(uri)
            subject.renew_blob_lease container_name, blob_name, lease_id
          end

          it "calls StorageService#call with the prepared request" do
            subject.expects(:call).with(verb, uri, nil, request_headers, {}).returns(response)
            subject.renew_blob_lease container_name, blob_name, lease_id
          end

          it "returns lease id on success" do
            result = subject.renew_blob_lease container_name, blob_name, lease_id
            _(result).must_equal lease_id
          end
        end

        describe "#change_blob_lease" do
          let (:proposed_lease_id) { "proposed-lease-id" }
          before {
            request_headers["x-ms-lease-action"] = "change"
            request_headers["x-ms-lease-id"] = lease_id
            request_headers["x-ms-proposed-lease-id"] = proposed_lease_id

            response.stubs(:success?).returns(true)
            response_headers["x-ms-lease-id"] = proposed_lease_id
          }

          it "assembles a URI for the request" do
            subject.expects(:blob_uri).with(container_name, blob_name, query).returns(uri)
            subject.change_blob_lease container_name, blob_name, lease_id, proposed_lease_id
          end

          it "calls StorageService#call with the prepared request" do
            subject.expects(:call).with(verb, uri, nil, request_headers, {}).returns(response)
            subject.change_blob_lease container_name, blob_name, lease_id, proposed_lease_id
          end

          it "returns lease id on success" do
            result = subject.change_blob_lease container_name, blob_name, lease_id, proposed_lease_id
            _(result).must_equal proposed_lease_id
          end
        end

        describe "#release_blob_lease" do
          before {
            request_headers["x-ms-lease-action"] = "release"
            request_headers["x-ms-lease-id"] = lease_id

            response.stubs(:success?).returns(true)
          }

          it "assembles a URI for the request" do
            subject.expects(:blob_uri).with(container_name, blob_name, query).returns(uri)
            subject.release_blob_lease container_name, blob_name, lease_id
          end

          it "calls StorageService#call with the prepared request" do
            subject.expects(:call).with(verb, uri, nil, request_headers, {}).returns(response)
            subject.release_blob_lease container_name, blob_name, lease_id
          end

          it "returns nil on success" do
            result = subject.release_blob_lease container_name, blob_name, lease_id
            _(result).must_equal nil
          end
        end

        describe "#break_blob_lease" do
          let(:lease_time) { 38 }
          before {
            request_headers["x-ms-lease-action"] = "break"

            response.stubs(:success?).returns(true)
            response_headers["x-ms-lease-time"] = lease_time.to_s
          }

          it "assembles a URI for the request" do
            subject.expects(:blob_uri).with(container_name, blob_name, query).returns(uri)
            subject.break_blob_lease container_name, blob_name
          end

          it "calls StorageService#call with the prepared request" do
            subject.expects(:call).with(verb, uri, nil, request_headers, {}).returns(response)
            subject.break_blob_lease container_name, blob_name
          end

          it "returns lease time on success" do
            result = subject.break_blob_lease container_name, blob_name
            _(result).must_equal lease_time
          end

          describe "when passed an optional break period" do
            let(:break_period) { 37 }
            before { request_headers["x-ms-lease-break-period"] = break_period.to_s }

            it "modifies the request headers to include a break period" do
              option = { break_period: break_period }
              subject.expects(:call).with(verb, uri, nil, request_headers, option).returns(response)
              subject.break_blob_lease container_name, blob_name, option
            end
          end
        end

        describe "#acquire_container_lease" do
          before {
            request_headers["x-ms-lease-action"] = "acquire"
            request_headers["x-ms-lease-duration"] = "-1"

            response.stubs(:success?).returns(true)
            response_headers["x-ms-lease-id"] = lease_id
          }

          it "assembles a URI for the request" do
            subject.expects(:container_uri).with(container_name, query).returns(uri)
            subject.acquire_container_lease container_name
          end

          it "calls StorageService#call with the prepared request" do
            subject.expects(:call).with(verb, uri, nil, request_headers, {}).returns(response)
            subject.acquire_container_lease container_name
          end

          it "returns lease id on success" do
            result = subject.acquire_container_lease container_name
            _(result).must_equal lease_id
          end

          describe "when passed a duration" do
            let(:duration) { 37 }
            before { request_headers["x-ms-lease-duration"] = "37" }

            it "modifies the headers to include the provided duration value" do
              options = { duration: duration }
              subject.expects(:call).with(verb, uri, nil, request_headers, options).returns(response)
              subject.acquire_container_lease container_name, options
            end
          end

          describe "when passed a proposed_lease_id" do
            let(:default_duration) { -1 }
            let(:proposed_lease_id) { "proposed-lease-id" }
            before { request_headers["x-ms-proposed-lease-id"] = proposed_lease_id }

            it "modifies the headers to include the proposed lease id" do
              options = { duration: default_duration, proposed_lease_id: proposed_lease_id }
              subject.expects(:call).with(verb, uri, nil, request_headers, options).returns(response)
              subject.acquire_container_lease container_name, options
            end
          end
        end

        describe "#renew_container_lease" do
          before {
            request_headers["x-ms-lease-action"] = "renew"
            request_headers["x-ms-lease-id"] = lease_id

            response.stubs(:success?).returns(true)
            response_headers["x-ms-lease-id"] = lease_id
          }

          it "assembles a URI for the request" do
            subject.expects(:container_uri).with(container_name, query).returns(uri)
            subject.renew_container_lease container_name, lease_id
          end

          it "calls StorageService#call with the prepared request" do
            subject.expects(:call).with(verb, uri, nil, request_headers, {}).returns(response)
            subject.renew_container_lease container_name, lease_id
          end

          it "returns lease id on success" do
            result = subject.renew_container_lease container_name, lease_id
            _(result).must_equal lease_id
          end
        end

        describe "#release_container_lease" do
          before {
            request_headers["x-ms-lease-action"] = "release"
            request_headers["x-ms-lease-id"] = lease_id

            response.stubs(:success?).returns(true)
          }

          it "assembles a URI for the request" do
            subject.expects(:container_uri).with(container_name, query).returns(uri)
            subject.release_container_lease container_name, lease_id
          end

          it "calls StorageService#call with the prepared request" do
            subject.expects(:call).with(verb, uri, nil, request_headers, {}).returns(response)
            subject.release_container_lease container_name, lease_id
          end

          it "returns nil on success" do
            result = subject.release_container_lease container_name, lease_id
            _(result).must_equal nil
          end
        end

        describe "#break_container_lease" do
          let(:lease_time) { 39 }
          before {
            request_headers["x-ms-lease-action"] = "break"

            response.stubs(:success?).returns(true)
            response_headers["x-ms-lease-time"] = lease_time.to_s
          }

          it "assembles a URI for the request" do
            subject.expects(:container_uri).with(container_name, query).returns(uri)
            subject.break_container_lease container_name
          end

          it "calls StorageService#call with the prepared request" do
            subject.expects(:call).with(verb, uri, nil, request_headers, {}).returns(response)
            subject.break_container_lease container_name
          end

          it "returns lease time on success" do
            result = subject.break_container_lease container_name
            _(result).must_equal lease_time
          end

          describe "when passed an optional break period" do
            let(:break_period) { 35 }
            before { request_headers["x-ms-lease-break-period"] = break_period.to_s }

            it "modifies the request headers to include a break period" do
              options = { break_period: break_period }
              subject.expects(:call).with(verb, uri, nil, request_headers, options).returns(response)
              subject.break_container_lease container_name, options
            end
          end
        end
      end
    end
  end

  class MockBlobService < Azure::Storage::Blob::BlobService
    def containers_uri(query = {})
      super
    end

    def container_uri(name, query = {})
      super
    end

    def blob_uri(container_name, blob_name, query = {})
      super
    end
  end

  describe "uri functions" do
    subject { MockBlobService.new({ storage_account_name: "mockaccount", storage_access_key: "YWNjZXNzLWtleQ==" }) }

    let(:container_name) { "container" }
    let(:blob_name) { "blob" }
    let(:query) { { "param" => "value", "param 1" => "value 1" } }
    let(:host_uri) { "http://dummy.uri" }

    before {
      subject.storage_service_host[:primary] = host_uri
    }

    describe "#containers_uri" do
      it "returns a containers URI" do
        result = subject.containers_uri
        _(result).must_be_kind_of URI
        _(result.scheme).must_equal "http"
        _(result.host).must_equal "dummy.uri"
        _(result.path).must_equal "/"
        _(result.query).must_equal "comp=list"
      end

      it "encodes optional query has as uri parameters" do
        result = subject.containers_uri query
        _(result.query).must_equal "comp=list&param=value&param+1=value+1"
      end
    end

    describe "#container_uri" do
      it "returns a container URI" do
        result = subject.container_uri container_name
        _(result).must_be_kind_of URI
        _(result.scheme).must_equal "http"
        _(result.host).must_equal "dummy.uri"
        _(result.path).must_equal "/container"
        _(result.query).must_equal "restype=container"
      end

      it "encodes optional query has as uri parameters" do
        result = subject.container_uri container_name, query
        _(result.query).must_equal "restype=container&param=value&param+1=value+1"
      end

      it "returns the same URI instance when the first parameter is a URI" do
        random_uri = URI.parse("http://random.uri")
        result = subject.container_uri random_uri
        _(result).must_equal random_uri
      end
    end

    describe "#blob_uri" do
      it "returns a blob URI" do
        result = subject.blob_uri container_name, blob_name
        _(result).must_be_kind_of URI
        _(result.scheme).must_equal "http"
        _(result.host).must_equal "dummy.uri"
        _(result.path).must_equal "/container/blob"
      end

      it "encodes optional query has as uri parameters" do
        result = subject.blob_uri container_name, blob_name, query
        _(result.query).must_equal "param=value&param+1=value+1"
      end
    end
  end
end
