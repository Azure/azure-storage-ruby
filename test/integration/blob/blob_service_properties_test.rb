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
require "integration/test_helper"
require "azure/storage/blob/blob_service"

describe Azure::Storage::Blob::BlobService do
  subject { Azure::Storage::Blob::BlobService.create(SERVICE_CREATE_OPTIONS()) }

  describe "#set_service_properties" do
    it "sets the service properties without version" do
      properties = Azure::Storage::Common::Service::StorageServiceProperties.new
      properties.logging.delete = true
      properties.logging.read = true
      properties.logging.write = true
      properties.logging.retention_policy.enabled = true
      properties.logging.retention_policy.days = 10

      properties.hour_metrics.enabled = true
      properties.hour_metrics.include_apis = true
      properties.hour_metrics.retention_policy.enabled = true
      properties.hour_metrics.retention_policy.days = 10

      result = subject.set_service_properties properties
      _(result).must_be_nil
    end

    it "sets the service properties use default values" do
     properties = Azure::Storage::Common::Service::StorageServiceProperties.new
     result = subject.set_service_properties properties
     _(result).must_be_nil
   end

    describe "#set_service_properties with logging" do
      it "with retention" do
        properties = Azure::Storage::Common::Service::StorageServiceProperties.new
        properties.logging.delete = true
        properties.logging.read = true
        properties.logging.write = true
        properties.logging.retention_policy.enabled = true
        properties.logging.retention_policy.days = 10

        result = subject.set_service_properties properties
        _(result).must_be_nil
      end

      it "without retention" do
        properties = Azure::Storage::Common::Service::StorageServiceProperties.new
        properties.logging.delete = false
        properties.logging.read = true
        properties.logging.write = true
        properties.logging.retention_policy.enabled = false
        properties.logging.retention_policy.days = 10

        result = subject.set_service_properties properties
        _(result).must_be_nil
      end
    end

    describe "#set_service_properties with metrics" do
      it "with hour metrics" do
        properties = Azure::Storage::Common::Service::StorageServiceProperties.new
        properties.hour_metrics.enabled = true
        properties.hour_metrics.include_apis = true
        properties.hour_metrics.retention_policy.enabled = true
        properties.hour_metrics.retention_policy.days = 10

        result = subject.set_service_properties properties
        _(result).must_be_nil
      end

      it "with minuite metrics" do
        properties = Azure::Storage::Common::Service::StorageServiceProperties.new
        properties.minute_metrics.enabled = true
        properties.minute_metrics.include_apis = false
        properties.minute_metrics.retention_policy.enabled = true
        properties.minute_metrics.retention_policy.days = 10

        result = subject.set_service_properties properties
        _(result).must_be_nil
      end

      it "without retention" do
        properties = Azure::Storage::Common::Service::StorageServiceProperties.new
        properties.hour_metrics.enabled = true
        properties.hour_metrics.include_apis = false
        properties.hour_metrics.retention_policy.enabled = false

        properties.minute_metrics.enabled = false
        properties.minute_metrics.include_apis = true
        properties.minute_metrics.retention_policy.enabled = false
        properties.minute_metrics.retention_policy.days = 10

        result = subject.set_service_properties properties
        _(result).must_be_nil
      end
    end

    describe "#set_service_properties with CORS" do
      let(:cors_properties) { Azure::Storage::Common::Service::StorageServiceProperties.new }
      let(:cors_rule) { Azure::Storage::Common::Service::CorsRule.new }
      before {
        cors_properties.cors.cors_rules.clear
        cors_rule.allowed_origins = ["www.ab.com", "www.bc.com"]
        cors_rule.allowed_methods = ["GET", "PUT"]
        cors_rule.max_age_in_seconds = 60
        cors_rule.exposed_headers = ["x-ms-meta-data*", "x-ms-meta-source*", "x-ms-meta-abc", "x-ms-meta-bcd"]
        cors_rule.allowed_headers = ["x-ms-meta-data*", "x-ms-meta-target*", "x-ms-meta-xyz", "x-ms-meta-foo"]
      }

      it "nil CORS" do
        properties = Azure::Storage::Common::Service::StorageServiceProperties.new
        properties.cors = Azure::Storage::Common::Service::Cors.new

        result = subject.set_service_properties properties
        _(result).must_be_nil
      end

      it "sets CORS rules" do
        cors_properties.cors.cors_rules.push cors_rule

        result = subject.set_service_properties cors_properties
        _(result).must_be_nil
      end

      it "sets CORS with duplicated rules" do
        cors_properties.cors.cors_rules.push cors_rule
        cors_properties.cors.cors_rules.push cors_rule

        result = subject.set_service_properties cors_properties
        _(result).must_be_nil
      end

      it "sets CORS rules without allowed_origins" do
       cors_rule.allowed_origins = nil
       cors_properties.cors.cors_rules.push cors_rule

       exception = assert_raises (Azure::Core::Http::HTTPError) do
         subject.set_service_properties cors_properties
       end
       refute_nil(exception.message.index "InvalidXmlDocument (400): XML specified is not syntactically valid")
     end

      it "sets CORS rules with empty allowed_origins" do
        cors_rule.allowed_origins = []
        cors_properties.cors.cors_rules.push cors_rule

        exception = assert_raises (Azure::Core::Http::HTTPError) do
          subject.set_service_properties cors_properties
        end
        refute_nil(exception.message.index "InvalidXmlNodeValue (400): The value for one of the XML nodes is not in the correct format")
      end

      it "sets CORS rules without allowed_methods" do
        cors_rule.allowed_methods = nil
        cors_properties.cors.cors_rules.push cors_rule

        exception = assert_raises (Azure::Core::Http::HTTPError) do
          subject.set_service_properties cors_properties
        end
        refute_nil(exception.message.index "InvalidXmlDocument (400): XML specified is not syntactically valid")
      end

      it "sets CORS rules with empty allowed_methods" do
        cors_rule.allowed_methods = []
        cors_properties.cors.cors_rules.push cors_rule

        exception = assert_raises (Azure::Core::Http::HTTPError) do
          subject.set_service_properties cors_properties
        end
        refute_nil(exception.message.index "InvalidXmlNodeValue (400): The value for one of the XML nodes is not in the correct format")
      end

      it "sets CORS rules without exposed_headers" do
        cors_rule.exposed_headers = nil
        cors_properties.cors.cors_rules.push cors_rule

        exception = assert_raises (Azure::Core::Http::HTTPError) do
          subject.set_service_properties cors_properties
        end
        refute_nil(exception.message.index "InvalidXmlDocument (400): XML specified is not syntactically valid")
      end

      it "sets CORS rules with empty exposed_headers" do
        cors_rule.exposed_headers = []
        cors_properties.cors.cors_rules.push cors_rule

        result = subject.set_service_properties cors_properties
        _(result).must_be_nil
      end

      it "sets CORS rules without allowed_headers" do
        cors_rule.allowed_headers = nil
        cors_properties.cors.cors_rules.push cors_rule

        exception = assert_raises (Azure::Core::Http::HTTPError) do
          subject.set_service_properties cors_properties
        end
        refute_nil(exception.message.index "InvalidXmlDocument (400): XML specified is not syntactically valid")
      end

      it "sets CORS rules with default allowed_headers" do
        cors_rule.allowed_headers = []
        cors_properties.cors.cors_rules.push cors_rule

        result = subject.set_service_properties cors_properties
        _(result).must_be_nil
      end
    end
  end

  describe "#get_service_properties" do
    it "gets service properties" do
      properties = Azure::Storage::Common::Service::StorageServiceProperties.new
      properties.logging.delete = false
      properties.logging.read = true
      properties.logging.write = true
      properties.logging.retention_policy.enabled = true
      properties.logging.retention_policy.days = 2

      properties.hour_metrics.enabled = true
      properties.hour_metrics.include_apis = false
      properties.hour_metrics.retention_policy.enabled = false

      properties.minute_metrics.enabled = true
      properties.minute_metrics.include_apis = true
      properties.minute_metrics.retention_policy.enabled = true
      properties.minute_metrics.retention_policy.days = 4

      properties.cors = Azure::Storage::Common::Service::Cors.new
      rule = Azure::Storage::Common::Service::CorsRule.new
      rule.allowed_origins = ["www.cd.com", "www.ef.com"]
      rule.allowed_methods = ["GET", "PUT"]
      rule.max_age_in_seconds = 20
      rule.exposed_headers = ["x-ms-meta-data*", "x-ms-meta-abc"]
      rule.allowed_headers = ["x-ms-meta-target*", "x-ms-meta-xyz"]
      properties.cors.cors_rules.push rule

      result = subject.set_service_properties properties
      _(result).must_be_nil
      sleep(5.0) # Wait for the setting being effective

      result = subject.get_service_properties
      _(result.logging).wont_be_nil
      _(result.logging.version).must_equal "1.0"
      result.logging.delete = false
      result.logging.read = true
      result.logging.write = true
      _(result.logging.retention_policy.enabled).must_equal true
      _(result.logging.retention_policy.days).must_equal 2

      _(result.hour_metrics.version).must_equal "1.0"
      _(result.hour_metrics.enabled).must_equal true
      _(result.hour_metrics.retention_policy.enabled).must_equal false

      _(result.minute_metrics.version).must_equal "1.0"
      _(result.minute_metrics.enabled).must_equal true
      _(result.minute_metrics.include_apis).must_equal true
      _(result.minute_metrics.retention_policy.enabled).must_equal true
      _(result.minute_metrics.retention_policy.days).must_equal 4

      _(result.cors.cors_rules.length).must_equal 1
      _(result.cors.cors_rules[0].allowed_origins).must_include "www.cd.com"
      _(result.cors.cors_rules[0].allowed_origins).must_include "www.ef.com"
      _(result.cors.cors_rules[0].allowed_methods).must_include "GET"
      _(result.cors.cors_rules[0].allowed_methods).must_include "PUT"
      _(result.cors.cors_rules[0].exposed_headers).must_include "x-ms-meta-data*"
      _(result.cors.cors_rules[0].exposed_headers).must_include "x-ms-meta-abc"
      _(result.cors.cors_rules[0].allowed_headers).must_include "x-ms-meta-target*"
      _(result.cors.cors_rules[0].allowed_headers).must_include "x-ms-meta-xyz"
      _(result.cors.cors_rules[0].max_age_in_seconds).must_equal rule.max_age_in_seconds
    end
  end
end
