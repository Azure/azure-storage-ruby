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
require "azure/storage/file"

describe Azure::Storage::File::FileService do
  let(:user_agent_prefix) { "azure_storage_ruby_unit_test" }
  subject {
    Azure::Storage::File::FileService.new {}
  }
  let(:serialization) { Azure::Storage::File::Serialization }
  let(:uri) { URI.parse "http://foo.com" }
  let(:query) { {} }
  let(:x_ms_version) { Azure::Storage::File::Default::STG_VERSION }
  let(:user_agent) { Azure::Storage::File::Default::USER_AGENT }
  let(:request_headers) { {} }
  let(:request_body) { "request-body" }

  let(:response_headers) { {} }
  let(:response_body) { mock() }
  let(:response) { mock() }

  let(:share_name) { "share-name" }
  let(:directory_path) { "directory_path" }

  before {
    response.stubs(:body).returns(response_body)
    response.stubs(:headers).returns(response_headers)
    subject.stubs(:call).returns(response)
  }

  describe "#list_shares" do
    let(:verb) { :get }
    let(:options) { { request_location_mode: Azure::Storage::Common::RequestLocationMode::PRIMARY_OR_SECONDARY} }
    let(:shares_enumeration_result) { Azure::Storage::Common::Service::EnumerationResults.new }

    before {
      subject.stubs(:shares_uri).with({}, options).returns(uri)
      subject.stubs(:call).with(verb, uri, nil, {}, {}).returns(response)
      serialization.stubs(:share_enumeration_results_from_xml).with(response_body).returns(shares_enumeration_result)
    }

    it "assembles a URI for the request" do
      subject.expects(:shares_uri).with({}, options).returns(uri)
      subject.list_shares
    end

    it "calls StorageService#call with the prepared request" do
      subject.list_shares
    end

    it "deserializes the response" do
      serialization.expects(:share_enumeration_results_from_xml).with(response_body).returns(shares_enumeration_result)
      subject.list_shares
    end

    it "returns a list of containers for the account" do
      result = subject.list_shares
      _(result).must_be_kind_of Azure::Storage::Common::Service::EnumerationResults
    end

    describe "when the options Hash is used" do
      before {
        serialization.expects(:share_enumeration_results_from_xml).with(response_body).returns(shares_enumeration_result)
      }

      it "modifies the URI query parameters when provided a :prefix value" do
        query = { "prefix" => "pre" }
        local_options = { prefix: "pre" }.merge options

        subject.expects(:shares_uri).with(query, local_options).returns(uri)
        subject.expects(:call).with(:get, uri, nil, {}, local_options).returns(response)
        subject.list_shares local_options
      end

      it "modifies the URI query parameters when provided a :marker value" do
        query = { "marker" => "mark" }
        local_options = { marker: "mark" }.merge options

        subject.expects(:shares_uri).with(query, local_options).returns(uri)
        subject.expects(:call).with(:get, uri, nil, {}, local_options).returns(response)
        subject.list_shares local_options
      end

      it "modifies the URI query parameters when provided a :max_results value" do
        query = { "maxresults" => "5" }
        local_options = { max_results: 5 }.merge options

        subject.expects(:shares_uri).with(query, local_options).returns(uri)
        subject.expects(:call).with(:get, uri, nil, {}, local_options).returns(response)
        subject.list_shares local_options
      end

      it "modifies the URI query parameters when provided a :metadata value" do
        query = { "include" => "metadata" }
        local_options = { metadata: true }.merge options

        subject.expects(:shares_uri).with(query, local_options).returns(uri)
        subject.expects(:call).with(:get, uri, nil, {}, local_options).returns(response)
        subject.list_shares local_options
      end

      it "modifies the URI query parameters when provided a :timeout value" do
        query = { "timeout" => "37" }
        local_options = { timeout: 37 }.merge options

        subject.expects(:shares_uri).with(query, local_options).returns(uri)
        subject.expects(:call).with(:get, uri, nil, {}, local_options).returns(response)
        subject.list_shares local_options
      end

      it "does not modify the URI query parameters when provided an unknown value" do
        local_options = { unknown_key: "some_value" }.merge options

        subject.expects(:shares_uri).with(query, local_options).returns(uri)
        subject.expects(:call).with(:get, uri, nil, {}, local_options).returns(response)
        subject.list_shares local_options
      end
    end
  end

  describe "share functions" do
    let(:share) { Azure::Storage::File::Share::Share.new }

    describe "#create_share" do
      let(:verb) { :put }
      before {
        subject.stubs(:share_uri).with(share_name, {}).returns(uri)
        subject.stubs(:call).with(verb, uri, nil, request_headers, {}).returns(response)
        serialization.stubs(:share_from_headers).with(response_headers).returns(share)
      }

      it "assembles a URI for the request" do
        subject.expects(:share_uri).with(share_name, {}).returns(uri)
        subject.create_share share_name
      end

      it "calls StorageService#call with the prepared request" do
        subject.expects(:call).with(verb, uri, nil, request_headers, {}).returns(response)
        subject.create_share share_name
      end

      it "deserializes the response" do
        serialization.expects(:share_from_headers).with(response_headers).returns(share)
        subject.create_share share_name
      end

      it "returns a new share" do
        result = subject.create_share share_name

        _(result).must_be_kind_of Azure::Storage::File::Share::Share
        _(result.name).must_equal share_name
      end

      describe "when optional metadata parameter is used" do
        let(:share_metadata) {
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
          subject.stubs(:share_uri).with(share_name, {}).returns(uri)
          serialization.stubs(:share_from_headers).with(response_headers).returns(share)
          subject.stubs(:call).with(verb, uri, nil, request_headers, {}).returns(response)
        end

        it "adds metadata to the request headers" do
          subject.stubs(:call).with(verb, uri, nil, request_headers, share_metadata).returns(response)
          subject.create_share share_name, share_metadata
        end
      end
    end

    describe "#delete_share" do
      let(:verb) { :delete }
      before {
        response.stubs(:success?).returns(true)
        subject.stubs(:share_uri).with(share_name, {}).returns(uri)
        subject.stubs(:call).with(verb, uri, nil, {}, {}).returns(response)
      }

      it "assembles a URI for the request" do
        subject.expects(:share_uri).with(share_name, {}).returns(uri)
        subject.delete_share share_name
      end

      it "calls StorageService#call with the prepared request" do
        subject.expects(:call).with(verb, uri, nil, {}, {}).returns(response)
        subject.delete_share share_name
      end

      it "returns nil on success" do
        result = subject.delete_share share_name
        _(result).must_equal nil
      end
    end

    describe "#set_share_properties" do
        let(:verb) { :put }
        let(:request_headers) { {} }

        before {
          query.update("comp" => "properties")
          response.stubs(:success?).returns(true)
          subject.stubs(:share_uri).with(share_name, query).returns(uri)
          subject.stubs(:call).with(verb, uri, nil, request_headers, {}).returns(response)
        }

        it "assembles a URI for the request" do
          subject.expects(:share_uri).with(share_name, query).returns(uri)
          subject.set_share_properties share_name
        end

        it "calls StorageService#call with the prepared request" do
          subject.expects(:call).with(verb, uri, nil, request_headers, {}).returns(response)
          subject.set_share_properties share_name
        end

        it "returns nil on success" do
          result = subject.set_share_properties share_name
          _(result).must_equal nil
        end

        describe "when the options Hash is used" do
          it "modifies the request headers when provided a :content_type value" do
            request_headers["x-ms-share-quota"] = "50"
            options = { quota: 50 }
            subject.stubs(:call).with(verb, uri, nil, request_headers, options).returns(response)
            subject.set_share_properties share_name, options
          end

          it "modifies the URI query parameters when provided a :timeout value" do
            query.merge!("timeout" => "37")
            subject.stubs(:share_uri).with(share_name, query).returns(uri)

            options = { timeout: 37 }
            subject.expects(:call).with(verb, uri, nil, request_headers, options).returns(response)
            subject.set_share_properties share_name, options
          end

          it "does not modify the request headers when provided an unknown value" do
            options = { unknown_key: "some_value" }
            subject.stubs(:call).with(verb, uri, nil, request_headers, options).returns(response)
            subject.set_share_properties share_name, options
          end
        end
      end

    describe "#get_share_properties" do
      let(:verb) { :get }
      let(:options) { { request_location_mode: Azure::Storage::Common::RequestLocationMode::PRIMARY_OR_SECONDARY} }
      let(:share_properties) { {} }

      before {
        share.properties = share_properties
        response_headers = {}
        subject.stubs(:share_uri).with(share_name, {}, options).returns(uri)
        subject.stubs(:call).with(verb, uri, nil, {}, {}).returns(response)
        serialization.stubs(:share_from_headers).with(response_headers).returns(share)
      }

      it "assembles a URI for the request" do
        subject.expects(:share_uri).with(share_name, {}, options).returns(uri)
        subject.get_share_properties share_name
      end

      it "calls StorageService#call with the prepared request" do
        subject.expects(:call).with(verb, uri, nil, {}, options).returns(response)
        subject.get_share_properties share_name
      end

      it "deserializes the response" do
        subject.expects(:call).with(verb, uri, nil, {}, options).returns(response)
        serialization.expects(:share_from_headers).with(response_headers).returns(share)
        subject.get_share_properties share_name
      end

      it "returns a share, with it's properties attribute populated" do
        result = subject.get_share_properties share_name
        _(result).must_be_kind_of Azure::Storage::File::Share::Share
        _(result.name).must_equal share_name
        _(result.properties).must_equal share_properties
      end
    end

    describe "#get_share_metadata" do
      let(:verb) { :get }
      let(:options) { { request_location_mode: Azure::Storage::Common::RequestLocationMode::PRIMARY_OR_SECONDARY} }
      let(:share_metadata) { { "MetadataKey" => "MetaDataValue", "MetadataKey1" => "MetaDataValue1" } }
      let(:response_headers) { { "x-ms-meta-MetadataKey" => "MetaDataValue", "x-ms-meta-MetadataKey1" => "MetaDataValue1" } }

      before {
        query.update("comp" => "metadata")
        response.stubs(:headers).returns(response_headers)
        subject.stubs(:share_uri).with(share_name, query, options).returns(uri)
        subject.stubs(:call).with(verb, uri, nil, {}, {}).returns(response)

        share.metadata = share_metadata
        serialization.stubs(:share_from_headers).with(response_headers).returns(share)
      }

      it "assembles a URI for the request" do
        subject.expects(:share_uri).with(share_name, query, options).returns(uri)
        subject.get_share_metadata share_name
      end

      it "calls StorageService#call with the prepared request" do
        subject.expects(:call).with(verb, uri, nil, {}, options).returns(response)
        subject.get_share_metadata share_name
      end

      it "deserializes the response" do
        subject.expects(:share_uri).with(share_name, query, options).returns(uri)
        serialization.expects(:share_from_headers).with(response_headers).returns(share)
        subject.get_share_metadata share_name
      end

      it "returns a share, with it's metadata attribute populated" do
        result = subject.get_share_metadata share_name
        _(result).must_be_kind_of Azure::Storage::File::Share::Share
        _(result.name).must_equal share_name
        _(result.metadata).must_equal share_metadata
      end
    end

    describe "#set_share_metadata" do
      let(:verb) { :put }
      let(:share_metadata) { { "MetadataKey" => "MetaDataValue", "MetadataKey1" => "MetaDataValue1" } }
      let(:request_headers) {
        { "x-ms-meta-MetadataKey" => "MetaDataValue",
         "x-ms-meta-MetadataKey1" => "MetaDataValue1"
         }
      }

      before {
        query.update("comp" => "metadata")
        response.stubs(:success?).returns(true)
        subject.stubs(:share_uri).with(share_name, query).returns(uri)
        subject.stubs(:call).with(verb, uri, nil, request_headers, {}).returns(response)
      }

      it "assembles a URI for the request" do
        subject.expects(:share_uri).with(share_name, query).returns(uri)
        subject.set_share_metadata share_name, share_metadata
      end

      it "calls StorageService#call with the prepared request" do
        subject.expects(:call).with(verb, uri, nil, request_headers, {}).returns(response)
        subject.set_share_metadata share_name, share_metadata
      end

      it "returns nil on success" do
        result = subject.set_share_metadata share_name, share_metadata
        _(result).must_equal nil
      end
    end

    describe "#get_share_acl" do
      let(:verb) { :get }
      let(:options) { { request_location_mode: Azure::Storage::Common::RequestLocationMode::PRIMARY_OR_SECONDARY} }
      let(:signed_identifier) { Azure::Storage::Common::Service::SignedIdentifier.new }
      let(:signed_identifiers) { [signed_identifier] }

      before {
        query.update("comp" => "acl")
        response.stubs(:headers).returns({})
        response_body.stubs(:length).returns(37)
        subject.stubs(:share_uri).with(share_name, query, options).returns(uri)
        subject.stubs(:call).with(verb, uri, nil, {}, {}).returns(response)

        serialization.stubs(:share_from_headers).with(response_headers).returns(share)
        serialization.stubs(:signed_identifiers_from_xml).with(response_body).returns(signed_identifiers)
      }

      it "assembles a URI for the request" do
        subject.expects(:share_uri).with(share_name, query, options).returns(uri)
        subject.get_share_acl share_name
      end

      it "calls StorageService#call with the prepared request" do
        subject.expects(:share_uri).with(share_name, query, options).returns(uri)
        subject.expects(:call).with(verb, uri, nil, {}, options).returns(response)
        subject.get_share_acl share_name
      end

      it "deserializes the response" do
        subject.expects(:share_uri).with(share_name, query, options).returns(uri)
        serialization.expects(:share_from_headers).with(response_headers).returns(share)
        serialization.expects(:signed_identifiers_from_xml).with(response_body).returns(signed_identifiers)
        subject.get_share_acl share_name
      end

      it "returns a share and an ACL" do
        returned_share, returned_acl = subject.get_share_acl share_name

        _(returned_share).must_be_kind_of Azure::Storage::File::Share::Share
        _(returned_share.name).must_equal share_name

        _(returned_acl).must_be_kind_of Array
        _(returned_acl[0]).must_be_kind_of Azure::Storage::Common::Service::SignedIdentifier
      end
    end

    describe "#set_share_acl" do
      let(:verb) { :put }

      before {
        query.update("comp" => "acl")

        response.stubs(:headers).returns({})
        subject.stubs(:share_uri).with(share_name, query).returns(uri)
        subject.stubs(:call).with(verb, uri, nil, request_headers, {}).returns(response)
        serialization.stubs(:share_from_headers).with(response_headers).returns(share)
      }

      it "assembles a URI for the request" do
        subject.expects(:share_uri).with(share_name, query).returns(uri)
        subject.set_share_acl share_name
      end

      it "calls StorageService#call with the prepared request" do
        subject.expects(:call).with(verb, uri, nil, request_headers, {}).returns(response)
        subject.set_share_acl share_name
      end

      it "deserializes the response" do
        serialization.expects(:share_from_headers).with(response_headers).returns(share)
        subject.set_share_acl share_name
      end

      it "returns a share and an ACL" do
        returned_share, returned_acl = subject.set_share_acl share_name

        _(returned_share).must_be_kind_of Azure::Storage::File::Share::Share
        _(returned_share.name).must_equal share_name

        _(returned_acl).must_be_kind_of Array
      end

      describe "when the signed_identifiers parameter is set" do
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
          subject.set_share_acl share_name, options
        end

        it "returns a share and an ACL" do
          options = { signed_identifiers: signed_identifiers }
          subject.stubs(:call).with(verb, uri, request_body, request_headers, options).returns(response)
          returned_share, returned_acl = subject.set_share_acl share_name, options

          _(returned_share).must_be_kind_of Azure::Storage::File::Share::Share
          _(returned_share.name).must_equal share_name

          _(returned_acl).must_be_kind_of Array
          _(returned_acl[0]).must_be_kind_of Azure::Storage::Common::Service::SignedIdentifier
        end
      end
    end

    describe "#get_share_stats" do
      let(:verb) { :get }
      let(:options) { { request_location_mode: Azure::Storage::Common::RequestLocationMode::PRIMARY_OR_SECONDARY} }
      let(:share_stats) { 10 }

      before {
        response_headers = {}
        query.update("comp" => "stats")
        subject.stubs(:share_uri).with(share_name, query, options).returns(uri)
        subject.stubs(:call).with(verb, uri, nil, {}, {}).returns(response)
        serialization.stubs(:share_from_headers).with(response_headers).returns(share)
        serialization.stubs(:share_stats_from_xml).with(response_body).returns(share_stats)
      }

      it "assembles a URI for the request" do
        subject.expects(:share_uri).with(share_name, query, options).returns(uri)
        subject.get_share_stats share_name
      end

      it "calls StorageService#call with the prepared request" do
        subject.expects(:call).with(verb, uri, nil, {}, options).returns(response)
        subject.get_share_stats share_name
      end

      it "deserializes the response" do
        subject.expects(:share_uri).with(share_name, query, options).returns(uri)
        serialization.expects(:share_from_headers).with(response_headers).returns(share)
        subject.get_share_stats share_name
      end

      it "returns a share, with it's properties attribute populated" do
        subject.expects(:share_uri).with(share_name, query, options).returns(uri)
        serialization.expects(:share_stats_from_xml).with(response_body).returns(share_stats)
        result = subject.get_share_stats share_name
        _(result).must_be_kind_of Azure::Storage::File::Share::Share
        _(result.name).must_equal share_name
        _(result.usage).must_equal share_stats
      end
    end
  end

  describe "directory functions" do
    let(:directory) { Azure::Storage::File::Directory::Directory.new }

    describe "#list_directories_and_files" do
      let(:verb) { :get }
      let(:query) { { "comp" => "list" } }
      let(:options) { { request_location_mode: Azure::Storage::Common::RequestLocationMode::PRIMARY_OR_SECONDARY} }
      let(:directories_and_files_enumeration_results) { Azure::Storage::Common::Service::EnumerationResults.new }

      before {
        subject.stubs(:directory_uri).with(share_name, directory_path, query, options).returns(uri)
        subject.stubs(:call).with(verb, uri, nil, {}, options).returns(response)
        response.stubs(:success?).returns(true)
        serialization.stubs(:directories_and_files_enumeration_results_from_xml).with(response_body).returns(directories_and_files_enumeration_results)
      }

      it "assembles a URI for the request" do
        subject.expects(:directory_uri).with(share_name, directory_path, query, options).returns(uri)
        subject.list_directories_and_files share_name, directory_path
      end

      it "calls StorageService#call with the prepared request" do
        subject.expects(:directory_uri).with(share_name, directory_path, query, options).returns(uri)
        subject.expects(:call).with(verb, uri, nil, {}, options).returns(response)
        subject.list_directories_and_files share_name, directory_path
      end

      it "deserializes the response" do
        serialization.expects(:directories_and_files_enumeration_results_from_xml).with(response_body).returns(directories_and_files_enumeration_results)
        subject.list_directories_and_files share_name, directory_path
      end

      it "returns a list of containers for the account" do
        subject.expects(:directory_uri).with(share_name, directory_path, query, options).returns(uri)
        result = subject.list_directories_and_files share_name, directory_path
        _(result).must_be_kind_of Azure::Storage::Common::Service::EnumerationResults
      end

      describe "when the options Hash is used" do
        before {
          response.expects(:success?).returns(true)
          serialization.expects(:directories_and_files_enumeration_results_from_xml).with(response_body).returns(directories_and_files_enumeration_results)
        }

        it "modifies the URI query parameters when provided a :marker value" do
          query["marker"] = "mark"
          local_options = { marker: "mark" }.merge(options)

          subject.expects(:directory_uri).with(share_name, directory_path, query, local_options).returns(uri)
          subject.expects(:call).with(:get, uri, nil, {}, local_options).returns(response)
          subject.list_directories_and_files share_name, directory_path, local_options
        end

        it "modifies the URI query parameters when provided a :max_results value" do
          query["maxresults"] = "5"
          local_options = { max_results: 5 }.merge options

          subject.expects(:directory_uri).with(share_name, directory_path, query, local_options).returns(uri)
          subject.expects(:call).with(:get, uri, nil, {}, local_options).returns(response)
          subject.list_directories_and_files share_name, directory_path, local_options
        end

        it "modifies the URI query parameters when provided a :timeout value" do
          query["timeout"] = "37"
          local_options = { timeout: 37 }.merge options

          subject.expects(:directory_uri).with(share_name, directory_path, query, local_options).returns(uri)
          subject.expects(:call).with(:get, uri, nil, {}, local_options).returns(response)
          subject.list_directories_and_files share_name, directory_path, local_options
        end

        it "does not modify the URI query parameters when provided an unknown value" do
          local_options = { unknown_key: "some_value" }.merge options

          subject.expects(:directory_uri).with(share_name, directory_path, query, local_options).returns(uri)
          subject.expects(:call).with(:get, uri, nil, {}, local_options).returns(response)
          subject.list_directories_and_files share_name, directory_path, local_options
        end
      end
    end

    describe "#get_directory_properties" do
      let(:verb) { :get }
      let(:query) { {} }
      let(:options) { { request_location_mode: Azure::Storage::Common::RequestLocationMode::PRIMARY_OR_SECONDARY} }
      let(:directory_properties) { {} }

      before {
        directory.properties = directory_properties
        response_headers = {}
        subject.stubs(:directory_uri).with(share_name, directory_path, query, options).returns(uri)
        subject.stubs(:call).with(verb, uri, nil, {}, options).returns(response)
        serialization.stubs(:directory_from_headers).with(response_headers).returns(directory)
      }

      it "assembles a URI for the request" do
        subject.expects(:directory_uri).with(share_name, directory_path, query, options).returns(uri)
        subject.get_directory_properties share_name, directory_path
      end

      it "calls StorageService#call with the prepared request" do
        subject.expects(:directory_uri).with(share_name, directory_path, query, options).returns(uri)
        subject.expects(:call).with(verb, uri, nil, {}, options).returns(response)
        subject.get_directory_properties share_name, directory_path
      end

      it "deserializes the response" do
        subject.expects(:directory_uri).with(share_name, directory_path, query, options).returns(uri)
        serialization.expects(:directory_from_headers).with(response_headers).returns(directory)
        subject.get_directory_properties share_name, directory_path
      end

      it "returns a share, with it's properties attribute populated" do
        result = subject.get_directory_properties share_name, directory_path
        _(result).must_be_kind_of Azure::Storage::File::Directory::Directory
        _(result.name).must_equal directory_path
        _(result.properties).must_equal directory_properties
      end
    end

    describe "#get_directory_metadata" do
      let(:verb) { :get }
      let(:options) { { request_location_mode: Azure::Storage::Common::RequestLocationMode::PRIMARY_OR_SECONDARY} }
      let(:directory_metadata) { { "MetadataKey" => "MetaDataValue", "MetadataKey1" => "MetaDataValue1" } }
      let(:response_headers) { { "x-ms-meta-MetadataKey" => "MetaDataValue", "x-ms-meta-MetadataKey1" => "MetaDataValue1" } }

      before {
        query.update("comp" => "metadata")
        response.stubs(:headers).returns(response_headers)
        subject.stubs(:directory_uri).with(share_name, directory_path, query, options).returns(uri)
        subject.stubs(:call).with(verb, uri, nil, {}, options).returns(response)

        directory.metadata = directory_metadata
        serialization.stubs(:directory_from_headers).with(response_headers).returns(directory)
      }

      it "assembles a URI for the request" do
        subject.expects(:directory_uri).with(share_name, directory_path, query, options).returns(uri)
        subject.get_directory_metadata share_name, directory_path
      end

      it "calls StorageService#call with the prepared request" do
        subject.expects(:call).with(verb, uri, nil, {}, options).returns(response)
        subject.get_directory_metadata share_name, directory_path
      end

      it "deserializes the response" do
        serialization.expects(:directory_from_headers).with(response_headers).returns(directory)
        subject.get_directory_metadata share_name, directory_path
      end

      it "returns a directory, with it's metadata attribute populated" do
        result = subject.get_directory_metadata share_name, directory_path
        _(result).must_be_kind_of Azure::Storage::File::Directory::Directory
        _(result.name).must_equal directory_path
        _(result.metadata).must_equal directory_metadata
      end
    end

    describe "#set_directory_metadata" do
      let(:verb) { :put }
      let(:directory_metadata) { { "MetadataKey" => "MetaDataValue", "MetadataKey1" => "MetaDataValue1" } }
      let(:request_headers) {
        { "x-ms-meta-MetadataKey" => "MetaDataValue",
         "x-ms-meta-MetadataKey1" => "MetaDataValue1"
         }
      }

      before {
        query.update("comp" => "metadata")
        response.stubs(:success?).returns(true)
        subject.stubs(:directory_uri).with(share_name, directory_path, query).returns(uri)
        subject.stubs(:call).with(verb, uri, nil, request_headers, {}).returns(response)
      }

      it "assembles a URI for the request" do
        subject.expects(:directory_uri).with(share_name, directory_path, query).returns(uri)
        subject.set_directory_metadata share_name, directory_path, directory_metadata
      end

      it "calls StorageService#call with the prepared request" do
        subject.expects(:call).with(verb, uri, nil, request_headers, {}).returns(response)
        subject.set_directory_metadata share_name, directory_path, directory_metadata
      end

      it "returns nil on success" do
        result = subject.set_directory_metadata share_name, directory_path, directory_metadata
        _(result).must_equal nil
      end
    end
  end

  describe "file functions" do
    let(:file_name) { "file-name" }
    let(:file) { Azure::Storage::File::File.new }

    describe "#create_file" do
      let(:verb) { :put }
      let(:file_length) { 37 }
      let(:request_headers) {
        {
          "x-ms-type" => "file",
          "Content-Length" => 0.to_s,
          "x-ms-content-length" => file_length.to_s,
          "x-ms-content-type" => "application/octet-stream"
        }
      }

      before {
        subject.stubs(:file_uri).with(share_name, directory_path, file_name, {}).returns(uri)
        subject.stubs(:call).with(verb, uri, nil, request_headers, {}).returns(response)
        serialization.stubs(:file_from_headers).with(response_headers).returns(file)
      }

      it "assembles a URI for the request" do
        subject.expects(:file_uri).with(share_name, directory_path, file_name, {}).returns(uri)
        subject.create_file share_name, directory_path, file_name, file_length
      end

      it "calls StorageService#call with the prepared request" do
        subject.expects(:call).with(verb, uri, nil, request_headers, {}).returns(response)
        subject.create_file share_name, directory_path, file_name, file_length
      end

      it "returns a Blob on success" do
        result = subject.create_file share_name, directory_path, file_name, file_length
        _(result).must_be_kind_of Azure::Storage::File::File
        _(result).must_equal file
        _(result.name).must_equal file_name
      end

      describe "when the options Hash is used" do
        it "modifies the request headers when provided a :content_type value" do
          request_headers["x-ms-content-type"] = "fct-value"
          options = { content_type: "fct-value" }
          subject.stubs(:call).with(verb, uri, nil, request_headers, options).returns(response)
          subject.create_file share_name, directory_path, file_name, file_length, options
        end

        it "modifies the request headers when provided a :content_encoding value" do
          request_headers["x-ms-content-encoding"] = "fce-value"
          options = { content_encoding: "fce-value" }
          subject.stubs(:call).with(verb, uri, nil, request_headers, options).returns(response)
          subject.create_file share_name, directory_path, file_name, file_length, options
        end

        it "modifies the request headers when provided a :content_language value" do
          request_headers["x-ms-content-language"] = "fcl-value"
          options = { content_language: "fcl-value" }
          subject.stubs(:call).with(verb, uri, nil, request_headers, options).returns(response)
          subject.create_file share_name, directory_path, file_name, file_length, options
        end

        it "modifies the request headers when provided a :content_md5 value" do
          request_headers["x-ms-content-md5"] = "cm-value"
          options = { content_md5: "cm-value" }
          subject.stubs(:call).with(verb, uri, nil, request_headers, options).returns(response)
          subject.create_file share_name, directory_path, file_name, file_length, options
        end

        it "modifies the request headers when provided a :cache_control value" do
          request_headers["x-ms-cache-control"] = "fcc-value"
          options = { cache_control: "fcc-value" }
          subject.stubs(:call).with(verb, uri, nil, request_headers, options).returns(response)
          subject.create_file share_name, directory_path, file_name, file_length, options
        end

        it "modifies the request headers when provided a :content_disposition value" do
          request_headers["x-ms-content-disposition"] = "fcd-value"
          options = { content_disposition: "fcd-value" }
          subject.stubs(:call).with(verb, uri, nil, request_headers, options).returns(response)
          subject.create_file share_name, directory_path, file_name, file_length, options
        end

        it "modifies the request headers when provided a :metadata value" do
          request_headers["x-ms-meta-MetadataKey"] = "MetaDataValue"
          request_headers["x-ms-meta-MetadataKey1"] = "MetaDataValue1"
          options = { metadata: { "MetadataKey" => "MetaDataValue", "MetadataKey1" => "MetaDataValue1" } }
          subject.stubs(:call).with(verb, uri, nil, request_headers, options).returns(response)
          subject.create_file share_name, directory_path, file_name, file_length, options
        end

        it "does not modify the request headers when provided an unknown value" do
          options = { unknown_key: "some_value" }
          subject.stubs(:call).with(verb, uri, nil, request_headers, options).returns(response)
          subject.create_file share_name, directory_path, file_name, file_length, options
        end
      end
    end

    describe "#put_file_range" do
      let(:verb) { :put }
      let(:start_range) { 255 }
      let(:end_range) { 512 }
      let(:content) { "some content" }
      let(:query) { { "comp" => "range" } }
      let(:request_headers) {
        {
          "x-ms-write" => "update",
          "x-ms-range" => "bytes=#{start_range}-#{end_range}"
        }
      }

      before {
        subject.stubs(:file_uri).with(share_name, directory_path, file_name, query).returns(uri)
        subject.stubs(:call).with(verb, uri, content, request_headers, {}).returns(response)
        serialization.stubs(:file_from_headers).with(response_headers).returns(file)
      }

      it "assembles a URI for the request" do
        subject.expects(:file_uri).with(share_name, directory_path, file_name, query).returns(uri)
        subject.put_file_range share_name, directory_path, file_name, start_range, end_range, content
      end

      it "calls StorageService#call with the prepared request" do
        subject.expects(:call).with(verb, uri, content, request_headers, {}).returns(response)
        subject.put_file_range share_name, directory_path, file_name, start_range, end_range, content
      end

      it "returns a Blob on success" do
        result = subject.put_file_range share_name, directory_path, file_name, start_range, end_range, content
        _(result).must_be_kind_of Azure::Storage::File::File
        _(result).must_equal file
        _(result.name).must_equal file_name
      end
    end

    describe "#clear_file_range" do
      let(:verb) { :put }
      let(:query) { { "comp" => "range" } }
      let(:start_range) { 255 }
      let(:end_range) { 512 }
      let(:request_headers) {
        {
          "x-ms-range" => "bytes=#{start_range}-#{end_range}",
          "x-ms-write" => "clear"
        }
      }

      before {
        subject.stubs(:file_uri).with(share_name, directory_path, file_name, query).returns(uri)
        subject.stubs(:call).with(verb, uri, nil, request_headers, {}).returns(response)
        serialization.stubs(:file_from_headers).with(response_headers).returns(file)
      }

      it "assembles a URI for the request" do
        subject.expects(:file_uri).with(share_name, directory_path, file_name, query).returns(uri)
        subject.clear_file_range share_name, directory_path, file_name, start_range, end_range
      end

      it "calls StorageService#call with the prepared request" do
        subject.expects(:call).with(verb, uri, nil, request_headers, {}).returns(response)
        subject.clear_file_range share_name, directory_path, file_name, start_range, end_range
      end

      it "returns a Blob on success" do
        result = subject.clear_file_range share_name, directory_path, file_name, start_range, end_range
        _(result).must_be_kind_of Azure::Storage::File::File
        _(result).must_equal file
        _(result.name).must_equal file_name
      end

      describe "when start_range is provided" do
        let(:start_range) { 255 }
        before { request_headers["x-ms-range"] = "bytes=#{start_range}-" }

        it "modifies the request headers with the desired range" do
          subject.expects(:call).with(verb, uri, nil, request_headers, {}).returns(response)
          subject.clear_file_range share_name, directory_path, file_name, start_range
        end
      end

      describe "when end_range is provided" do
        let(:end_range) { 512 }
        before { request_headers["x-ms-range"] = "bytes=0-#{end_range}" }

        it "modifies the request headers with the desired range" do
          subject.expects(:call).with(verb, uri, nil, request_headers, {}).returns(response)
          subject.clear_file_range share_name, directory_path, file_name, nil, end_range
        end
      end

      describe "when both start_range and end_range are provided" do
        before { request_headers["x-ms-range"] = "bytes=#{start_range}-#{end_range}" }

        it "modifies the request headers with the desired range" do
          subject.expects(:call).with(verb, uri, nil, request_headers, {}).returns(response)
          subject.clear_file_range share_name, directory_path, file_name, start_range, end_range
        end
      end
    end

    describe "#list_file_ranges" do
      let(:verb) { :get }
      let(:query) { { "comp" => "rangelist" } }
      let(:range_list) { [[0, 511], [512, 1023]] }
      let(:options) { { request_location_mode: Azure::Storage::Common::RequestLocationMode::PRIMARY_OR_SECONDARY} }

      before {
        subject.stubs(:file_uri).with(share_name, directory_path, file_name, query, options).returns(uri)
        subject.stubs(:call).with(verb, uri, nil, request_headers, {}).returns(response)
        serialization.stubs(:range_list_from_xml).with(response_body).returns(range_list)
      }

      it "assembles a URI for the request" do
        subject.expects(:file_uri).with(share_name, directory_path, file_name, query, options).returns(uri)
        subject.list_file_ranges share_name, directory_path, file_name
      end

      it "calls StorageService#call with the prepared request" do
        subject.expects(:call).with(verb, uri, nil, request_headers, options).returns(response)
        subject.list_file_ranges share_name, directory_path, file_name
      end

      it "deserializes the response" do
        serialization.expects(:range_list_from_xml).with(response_body).returns(range_list)
        subject.list_file_ranges share_name, directory_path, file_name
      end

      it "returns a list of ranges" do
        file, result = subject.list_file_ranges share_name, directory_path, file_name
        _(result).must_be_kind_of Array
        _(result.first).must_be_kind_of Array
        _(result.first.first).must_be_kind_of Integer
        _(result.first.first.next).must_be_kind_of Integer
      end

      describe "when start_range is provided" do
        let(:start_range) { 255 }
        before { request_headers["x-ms-range"] = "bytes=#{start_range}-" }

        it "modifies the request headers with the desired range" do
          local_call_options = { start_range: "#{start_range}".to_i }.merge options
          subject.expects(:file_uri).with(share_name, directory_path, file_name, query, local_call_options).returns(uri)
          subject.expects(:call).with(verb, uri, nil, request_headers, local_call_options).returns(response)
          subject.list_file_ranges share_name, directory_path, file_name, start_range: start_range
        end
      end

      describe "when end_range is provided" do
        let(:end_range) { 512 }
        before { request_headers["x-ms-range"] = "bytes=0-#{end_range}" }

        it "modifies the request headers with the desired range" do
          local_call_options = { start_range: 0, end_range: "#{end_range}".to_i }.merge options
          local_uri_options = { start_range: nil, end_range: "#{end_range}".to_i }.merge options

          subject.expects(:file_uri).with(share_name, directory_path, file_name, query, local_uri_options).returns(uri)
          subject.expects(:call).with(verb, uri, nil, request_headers, local_call_options).returns(response)
          subject.list_file_ranges share_name, directory_path, file_name, start_range: nil, end_range: end_range
        end
      end

      describe "when both start_range and end_range are provided" do
        let(:start_range) { 255 }
        let(:end_range) { 512 }
        let(:request_headers) { {} }

        it "modifies the request headers with the desired range" do
          request_headers["x-ms-range"] = "bytes=#{start_range}-#{end_range}"
          local_call_options = { start_range: start_range, end_range: end_range }.merge options

          subject.expects(:file_uri).with(share_name, directory_path, file_name, query, local_call_options).returns(uri)
          subject.expects(:call).with(verb, uri, nil, request_headers, local_call_options).returns(response)
          subject.list_file_ranges share_name, directory_path, file_name, local_call_options
        end
      end
    end

    describe "#resize_file" do
      let(:verb) { :put }
      let(:query) { { "comp" => "properties" } }
      let(:size) { 2048 }
      let(:request_headers) { {"x-ms-content-length" => size.to_s } }

      before {
        subject.stubs(:file_uri).with(share_name, directory_path, file_name, query).returns(uri)
        subject.stubs(:call).with(verb, uri, nil, request_headers, {}).returns(response)
      }

      it "resizes the file" do
        subject.expects(:call).with(verb, uri, nil, request_headers, content_length: size).returns(response)
        subject.resize_file share_name, directory_path, file_name, size
      end
    end

    describe "#set_file_properties" do
      let(:verb) { :put }
      let(:request_headers) { {} }

      before {
        query.update("comp" => "properties")
        response.stubs(:success?).returns(true)
        subject.stubs(:file_uri).with(share_name, directory_path, file_name, query).returns(uri)
        subject.stubs(:call).with(verb, uri, nil, request_headers, {}).returns(response)
      }

      it "assembles a URI for the request" do
        subject.expects(:file_uri).with(share_name, directory_path, file_name, query).returns(uri)
        subject.set_file_properties share_name, directory_path, file_name
      end

      it "calls StorageService#call with the prepared request" do
        subject.expects(:call).with(verb, uri, nil, request_headers, {}).returns(response)
        subject.set_file_properties share_name, directory_path, file_name
      end

      it "returns nil on success" do
        result = subject.set_file_properties share_name, directory_path, file_name
        _(result).must_equal nil
      end

      describe "when the options Hash is used" do
        it "modifies the request headers when provided a :content_type value" do
          request_headers["x-ms-content-type"] = "fct-value"
          options = { content_type: "fct-value" }
          subject.stubs(:call).with(verb, uri, nil, request_headers, options).returns(response)
          subject.set_file_properties share_name, directory_path, file_name, options
        end

        it "modifies the request headers when provided a :content_encoding value" do
          request_headers["x-ms-content-encoding"] = "fce-value"
          options = { content_encoding: "fce-value" }
          subject.stubs(:call).with(verb, uri, nil, request_headers, options).returns(response)
          subject.set_file_properties share_name, directory_path, file_name, options
        end

        it "modifies the request headers when provided a :content_language value" do
          request_headers["x-ms-content-language"] = "fcl-value"
          options = { content_language: "fcl-value" }
          subject.stubs(:call).with(verb, uri, nil, request_headers, options).returns(response)
          subject.set_file_properties share_name, directory_path, file_name, options
        end

        it "modifies the request headers when provided a :content_md5 value" do
          request_headers["x-ms-content-md5"] = "fcm-value"
          options = { content_md5: "fcm-value" }
          subject.stubs(:call).with(verb, uri, nil, request_headers, options).returns(response)
          subject.set_file_properties share_name, directory_path, file_name, options
        end

        it "modifies the request headers when provided a :cache_control value" do
          request_headers["x-ms-cache-control"] = "fcc-value"
          options = { cache_control: "fcc-value" }
          subject.stubs(:call).with(verb, uri, nil, request_headers, options).returns(response)
          subject.set_file_properties share_name, directory_path, file_name, options
        end

        it "modifies the request headers when provided a :content_length value" do
          request_headers["x-ms-content-length"] = "37"
          options = { content_length: 37.to_s }
          subject.stubs(:call).with(verb, uri, nil, request_headers, options).returns(response)
          subject.set_file_properties share_name, directory_path, file_name, options
        end

        it "modifies the request headers when provided a :content_disposition value" do
          request_headers["x-ms-content-disposition"] = "fcd-value"
          options = { content_disposition: "fcd-value" }
          subject.stubs(:call).with(verb, uri, nil, request_headers, options).returns(response)
          subject.set_file_properties share_name, directory_path, file_name, options
        end

        it "does not modify the request headers when provided an unknown value" do
          options = { unknown_key: "some_value" }
          subject.stubs(:call).with(verb, uri, nil, request_headers, options).returns(response)
          subject.set_file_properties share_name, directory_path, file_name, options
        end
      end
    end

    describe "#get_file_properties" do
      let(:verb) { :head }
      let(:options) { { request_location_mode: Azure::Storage::Common::RequestLocationMode::PRIMARY_OR_SECONDARY} }
      let(:request_headers) { {} }

      before {
        subject.stubs(:file_uri).with(share_name, directory_path, file_name, query).returns(uri)
        subject.stubs(:call).with(verb, uri, nil, request_headers, options).returns(response)
        serialization.stubs(:file_from_headers).with(response_headers).returns(file)
      }

      it "assembles a URI for the request" do
        subject.expects(:file_uri).with(share_name, directory_path, file_name, query, options).returns(uri)
        subject.get_file_properties share_name, directory_path, file_name
      end

      it "calls StorageService#call with the prepared request" do
        subject.expects(:file_uri).with(share_name, directory_path, file_name, query, options).returns(uri)
        subject.expects(:call).with(verb, uri, nil, request_headers, options).returns(response)
        subject.get_file_properties share_name, directory_path, file_name
      end

      it "returns the file on success" do
        subject.expects(:file_uri).with(share_name, directory_path, file_name, query, options).returns(uri)
        result = subject.get_file_properties share_name, directory_path, file_name

        _(result).must_be_kind_of Azure::Storage::File::File
        _(result).must_equal file
        _(result.name).must_equal file_name
      end
    end

    describe "#set_file_metadata" do
      let(:verb) { :put }
      let(:file_metadata) { { "MetadataKey" => "MetaDataValue", "MetadataKey1" => "MetaDataValue1" } }
      let(:request_headers) { { "x-ms-meta-MetadataKey" => "MetaDataValue", "x-ms-meta-MetadataKey1" => "MetaDataValue1"} }

      before {
        query.update("comp" => "metadata")
        response.stubs(:success?).returns(true)
        subject.stubs(:file_uri).with(share_name, directory_path, file_name, query).returns(uri)
        subject.stubs(:call).with(verb, uri, nil, request_headers, {}).returns(response)
      }

      it "assembles a URI for the request" do
        subject.expects(:file_uri).with(share_name, directory_path, file_name, query).returns(uri)
        subject.set_file_metadata share_name, directory_path, file_name, file_metadata
      end

      it "calls StorageService#call with the prepared request" do
        subject.expects(:call).with(verb, uri, nil, request_headers, {}).returns(response)
        subject.set_file_metadata share_name, directory_path, file_name, file_metadata
      end

      it "returns nil on success" do
        result = subject.set_file_metadata share_name, directory_path, file_name, file_metadata
        _(result).must_equal nil
      end
    end

    describe "#get_file_metadata" do
      let(:verb) { :get }
      let(:options) { { request_location_mode: Azure::Storage::Common::RequestLocationMode::PRIMARY_OR_SECONDARY} }
      # No header is added in the get_file_metadata. StorageService.call will add common headers.
      let(:request_headers) { {} }

      before {
        query["comp"] = "metadata"

        subject.stubs(:file_uri).with(share_name, directory_path, file_name, query, options).returns(uri)
        subject.stubs(:call).with(verb, uri, nil, request_headers, options).returns(response)
        serialization.stubs(:file_from_headers).with(response_headers).returns(file)
      }

      it "assembles a URI for the request" do
        subject.expects(:file_uri).with(share_name, directory_path, file_name, query, options).returns(uri)
        subject.get_file_metadata share_name, directory_path, file_name
      end

      it "calls StorageService#call with the prepared request" do
        subject.expects(:call).with(verb, uri, nil, request_headers, options).returns(response)
        subject.get_file_metadata share_name, directory_path, file_name
      end

      it "returns the file on success" do
        subject.expects(:file_uri).with(share_name, directory_path, file_name, query, options).returns(uri)
        result = subject.get_file_metadata share_name, directory_path, file_name

        _(result).must_be_kind_of Azure::Storage::File::File
        _(result).must_equal file
        _(result.name).must_equal file_name
      end
    end

    describe "#get_file" do
      let(:options) { { request_location_mode: Azure::Storage::Common::RequestLocationMode::PRIMARY_OR_SECONDARY} }
      let(:verb) { :get }

      before {
        response.stubs(:success?).returns(true)
        response_body = "file-contents"

        subject.stubs(:file_uri).with(share_name, directory_path, file_name, query, options).returns(uri)
        subject.stubs(:call).with(verb, uri, nil, request_headers, options).returns(response)
        serialization.stubs(:file_from_headers).with(response_headers).returns(file)
      }

      it "assembles a URI for the request" do
        subject.expects(:file_uri).with(share_name, directory_path, file_name, query, options).returns(uri)
        subject.get_file share_name, directory_path, file_name
      end

      it "calls StorageService#call with the prepared request" do
        subject.expects(:call).with(verb, uri, nil, request_headers, options).returns(response)
        subject.get_file share_name, directory_path, file_name
      end

      it "returns the file and file contents on success" do
        returned_file, returned_file_contents = subject.get_file share_name, directory_path, file_name

        _(returned_file).must_be_kind_of Azure::Storage::File::File
        _(returned_file).must_equal file
        _(returned_file_contents).must_equal response_body
      end

      describe "when start_range is provided" do
        let(:start_range) { 255 }
        before { request_headers["x-ms-range"] = "bytes=#{start_range}-" }

        it "modifies the request headers with the desired range" do
          local_options = { start_range: 255 }.merge(options)
          subject.expects(:file_uri).with(share_name, directory_path, file_name, query, local_options).returns(uri)
          subject.expects(:call).with(verb, uri, nil, request_headers, local_options).returns(response)
          subject.get_file share_name, directory_path, file_name, start_range: start_range
        end
      end

      describe "when end_range is provided" do
        let(:end_range) { 512 }
        before { request_headers["x-ms-range"] = "bytes=0-#{end_range}" }

        it "modifies the request headers with the desired range" do
          local_url_options = { start_range: nil, end_range: end_range }.merge(options)
          subject.expects(:file_uri).with(share_name, directory_path, file_name, query, local_url_options).returns(uri)

          local_call_options = { start_range: 0, end_range: end_range }.merge(options)
          subject.expects(:call).with(verb, uri, nil, request_headers, local_call_options).returns(response)
          subject.get_file share_name, directory_path, file_name, start_range: nil, end_range: end_range
        end
      end

      describe "when both start_range and end_range are provided" do
        let(:start_range) { 255 }
        let(:end_range) { 512 }
        before {
          request_headers["x-ms-range"] = "bytes=#{start_range}-#{end_range}"
        }

        it "modifies the request headers with the desired range" do
          local_options = { start_range: start_range, end_range: end_range }.merge(options)
          subject.expects(:file_uri).with(share_name, directory_path, file_name, query, local_options).returns(uri)
          subject.expects(:call).with(verb, uri, nil, request_headers, local_options).returns(response)
          subject.get_file share_name, directory_path, file_name, local_options
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
            local_options = { start_range: start_range, end_range: end_range, get_content_md5: true }.merge(options)
            subject.expects(:file_uri).with(share_name, directory_path, file_name, query, local_options).returns(uri)
            subject.expects(:call).with(verb, uri, nil, request_headers, local_options).returns(response)
            subject.get_file share_name, directory_path, file_name, local_options
          end
        end

        describe "and a range is NOT specified" do
          it "does not modify the request headers" do
            local_options = { get_content_md5: true }.merge(options)
            subject.expects(:file_uri).with(share_name, directory_path, file_name, query, local_options).returns(uri)
            subject.expects(:call).with(verb, uri, nil, request_headers, local_options).returns(response)
            subject.get_file share_name, directory_path, file_name, local_options
          end
        end
      end
    end

    describe "#delete_file" do
      let(:verb) { :delete }
      # No header is added in the delete_file. StorageService.call will add common headers.
      let(:request_headers) { {} }

      before {
        response.stubs(:success?).returns(true)

        subject.stubs(:file_uri).with(share_name, directory_path, file_name, query).returns(uri)
        subject.stubs(:call).with(verb, uri, nil, request_headers, {}).returns(response)
      }

      it "assembles a URI for the request" do
        subject.expects(:file_uri).with(share_name, directory_path, file_name, query).returns(uri)
        subject.delete_file share_name, directory_path, file_name
      end

      it "calls StorageService#call with the prepared request" do
        subject.expects(:call).with(verb, uri, nil, request_headers, {}).returns(response)
        subject.delete_file share_name, directory_path, file_name
      end

      it "returns nil on success" do
        result = subject.delete_file share_name, directory_path, file_name
        _(result).must_equal nil
      end
    end

    describe "#copy_file" do
      let(:verb) { :put }
      let(:source_share_name) { "source-share-name" }
      let(:source_directory_path) { "source-directory-path" }
      let(:source_file_name) { "source-file-name" }
      let(:source_uri) { URI.parse("http://dummy.uri/source") }

      let(:copy_id) { "copy-id" }
      let(:copy_status) { "copy-status" }

      before {
        request_headers["x-ms-copy-source"] = source_uri.to_s
        response_headers["x-ms-copy-id"] = copy_id
        response_headers["x-ms-copy-status"] = copy_status

        subject.stubs(:file_uri).with(share_name, directory_path, file_name, {}).returns(uri)
        subject.stubs(:file_uri).with(source_share_name, source_directory_path, source_file_name, query).returns(source_uri)
        subject.stubs(:call).with(verb, uri, nil, request_headers, {}).returns(response)
      }

      it "assembles a URI for the request" do
        subject.expects(:file_uri).with(share_name, directory_path, file_name, {}).returns(uri)
        subject.copy_file share_name, directory_path, file_name, source_share_name, source_directory_path, source_file_name
      end

      it "assembles the source URI and places it in the header" do
        subject.expects(:file_uri).with(source_share_name, source_directory_path, source_file_name, query).returns(source_uri)
        subject.copy_file share_name, directory_path, file_name, source_share_name, source_directory_path, source_file_name
      end

      it "calls with source URI" do
        subject.expects(:file_uri).with(share_name, directory_path, file_name, {}).returns(uri)
        subject.expects(:call).with(verb, uri, nil, request_headers, {}).returns(response)
        subject.copy_file_from_uri share_name, directory_path, file_name, source_uri.to_s
      end

      it "calls StorageService#call with the prepared request" do
        subject.expects(:call).with(verb, uri, nil, request_headers, {}).returns(response)
        subject.copy_file share_name, directory_path, file_name, source_share_name, source_directory_path, source_file_name
      end

      it "returns the copy id and copy status on success" do
        returned_copy_id, returned_copy_status = subject.copy_file share_name, directory_path, file_name, source_share_name, source_directory_path, source_file_name
        _(returned_copy_id).must_equal copy_id
        _(returned_copy_status).must_equal copy_status
      end

      describe "when the options Hash is used" do
        it "modifies the request headers when provided a :metadata value" do
          request_headers["x-ms-meta-MetadataKey"] = "MetaDataValue"
          request_headers["x-ms-meta-MetadataKey1"] = "MetaDataValue1"
          options = { metadata: { "MetadataKey" => "MetaDataValue", "MetadataKey1" => "MetaDataValue1" } }
          subject.expects(:call).with(verb, uri, nil, request_headers, options).returns(response)
          subject.copy_file share_name, directory_path, file_name, source_share_name, source_directory_path, source_file_name, options
        end

        it "does not modify the request headers when provided an unknown value" do
          options = { unknown_key: "some_value" }
          subject.expects(:call).with(verb, uri, nil, request_headers, options).returns(response)
          subject.copy_file share_name, directory_path, file_name, source_share_name, source_directory_path, source_file_name, options
        end
      end
    end

    describe "#abort_copy_file" do
      let(:verb) { :put }
      let(:lease_id) { "lease-id" }
      let(:copy_id) { "copy-id" }

      before {
        request_headers["x-ms-copy-action"] = "abort"

        query.update("comp" => "copy", "copyid" => copy_id)
        subject.stubs(:file_uri).with(share_name, directory_path, file_name, query).returns(uri)
      }

      it "abort copy a file" do
        subject.expects(:file_uri).with(share_name, directory_path, file_name, query).returns(uri)
        subject.abort_copy_file share_name, directory_path, file_name, copy_id
      end
    end
  end
end
