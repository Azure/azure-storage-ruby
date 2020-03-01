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
require "azure/storage/common/core/auth/shared_access_signature"

describe Azure::Storage::Common::Core::Auth::SharedAccessSignature do
  subject { Azure::Storage::File::FileService.create(SERVICE_CREATE_OPTIONS()) }
  let(:generator) { Azure::Storage::Common::Core::Auth::SharedAccessSignature.new(SERVICE_CREATE_OPTIONS()[:storage_account_name], SERVICE_CREATE_OPTIONS()[:storage_access_key]) }

  describe "#file_service_sas_for_share" do
    let(:share_name) { ShareNameHelper.name }
    let(:directory_name) { FileNameHelper.name }
    let(:file_name) { FileNameHelper.name }
    let(:file_length) { 1024 }
    let(:content) { content = ""; file_length.times.each { |i| content << "@" }; content }
    before {
      subject.create_share share_name
      subject.create_directory share_name, directory_name
      subject.create_file share_name, directory_name, file_name, file_length
      subject.put_file_range share_name, directory_name, file_name, 0, file_length - 1, content
    }
    after { ShareNameHelper.clean }

    it "create a file with SAS in connection string" do
      sas_token = generator.generate_service_sas_token "#{share_name}", service: "f", resource: "s", permissions: "c", protocol: "https"
      connection_string = "FileEndpoint=https://#{ENV['AZURE_STORAGE_ACCOUNT']}.file.core.windows.net;SharedAccessSignature=#{sas_token}"
      client = Azure::Storage::File::FileService::create_from_connection_string connection_string

      new_file_name = FileNameHelper.name
      new_file = subject.create_file share_name, directory_name, new_file_name, file_length
      _(new_file).wont_be_nil
      _(new_file.name).must_equal new_file_name
      _(new_file.properties[:last_modified]).wont_be_nil
      _(new_file.properties[:etag]).wont_be_nil
      _(new_file.properties[:content_length]).wont_be_nil
    end

    it "create a file with share permission" do
      sas_token = generator.generate_service_sas_token "#{share_name}", service: "f", resource: "s", permissions: "c", protocol: "https"
      client = Azure::Storage::File::FileService.new({ storage_account_name: SERVICE_CREATE_OPTIONS()[:storage_account_name], storage_sas_token: sas_token })

      new_file_name = FileNameHelper.name
      new_file = subject.create_file share_name, directory_name, new_file_name, file_length
      _(new_file).wont_be_nil
      _(new_file.name).must_equal new_file_name
      _(new_file.properties[:last_modified]).wont_be_nil
      _(new_file.properties[:etag]).wont_be_nil
      _(new_file.properties[:content_length]).wont_be_nil
    end

    it "write a file with share permission" do
      sas_token = generator.generate_service_sas_token "#{share_name}", service: "f", resource: "s", permissions: "c", protocol: "https"
      client = Azure::Storage::File::FileService.new({ storage_account_name: SERVICE_CREATE_OPTIONS()[:storage_account_name], storage_sas_token: sas_token })

      new_file_name = FileNameHelper.name
      new_file = subject.create_file share_name, directory_name, new_file_name, file_length
      _(new_file).wont_be_nil

      sas_token = generator.generate_service_sas_token "#{share_name}", service: "f", resource: "s", permissions: "w", protocol: "https"
      client = Azure::Storage::File::FileService.new({ storage_account_name: SERVICE_CREATE_OPTIONS()[:storage_account_name], storage_sas_token: sas_token })

      file = subject.put_file_range share_name, directory_name, new_file_name, 0, file_length - 1, content
      _(file).wont_be_nil
      _(file.name).must_equal new_file_name
    end

    it "reads a file property with share permission" do
      sas_token = generator.generate_service_sas_token "#{share_name}", service: "f", resource: "s", permissions: "r", protocol: "https"
      client = Azure::Storage::File::FileService.new({ storage_account_name: SERVICE_CREATE_OPTIONS()[:storage_account_name], storage_sas_token: sas_token })

      file_properties = client.get_file_properties share_name, directory_name, file_name
      _(file_properties).wont_be_nil
      _(file_properties.name).must_equal file_name
      _(file_properties.properties[:last_modified]).wont_be_nil
      _(file_properties.properties[:etag]).wont_be_nil
      _(file_properties.properties[:content_length]).must_equal file_length
      _(file_properties.properties[:type]).must_equal "File"
    end

    it "list a file with share permission" do
      sas_token = generator.generate_service_sas_token "#{share_name}", service: "f", resource: "s", permissions: "l", protocol: "https"
      client = Azure::Storage::File::FileService.new({ storage_account_name: SERVICE_CREATE_OPTIONS()[:storage_account_name], storage_sas_token: sas_token })
      files = client.list_directories_and_files share_name, nil
      _(files).wont_be_nil
      assert files.length > 0
    end

    it "deletes a file with share permission" do
      sas_token = generator.generate_service_sas_token "#{share_name}", service: "f", resource: "s", permissions: "d", protocol: "https,http"
      client = Azure::Storage::File::FileService.new({ storage_account_name: SERVICE_CREATE_OPTIONS()[:storage_account_name], storage_sas_token: sas_token })
      result = client.delete_file share_name, directory_name, file_name
      _(result).must_be_nil
    end

    it "create a file with file permission" do
      sas_token = generator.generate_service_sas_token "#{share_name}/#{directory_name}/#{file_name}", service: "f", resource: "f", permissions: "c", protocol: "https"
      client = Azure::Storage::File::FileService.new({ storage_account_name: SERVICE_CREATE_OPTIONS()[:storage_account_name], storage_sas_token: sas_token })

      new_file_name = FileNameHelper.name
      new_file = subject.create_file share_name, directory_name, new_file_name, file_length
      _(new_file).wont_be_nil
      _(new_file.name).must_equal new_file_name
      _(new_file.properties[:last_modified]).wont_be_nil
      _(new_file.properties[:etag]).wont_be_nil
      _(new_file.properties[:content_length]).wont_be_nil
    end

    it "write a file with file permission" do
      sas_token = generator.generate_service_sas_token "#{share_name}/#{directory_name}/#{file_name}", service: "f", resource: "f", permissions: "c", protocol: "https"
      client = Azure::Storage::File::FileService.new({ storage_account_name: SERVICE_CREATE_OPTIONS()[:storage_account_name], storage_sas_token: sas_token })

      new_file_name = FileNameHelper.name
      new_file = subject.create_file share_name, directory_name, new_file_name, file_length
      _(new_file).wont_be_nil

      sas_token = generator.generate_service_sas_token "#{share_name}/#{directory_name}/#{file_name}", service: "f", resource: "f", permissions: "w", protocol: "https"
      client = Azure::Storage::File::FileService.new({ storage_account_name: SERVICE_CREATE_OPTIONS()[:storage_account_name], storage_sas_token: sas_token })

      file = subject.put_file_range share_name, directory_name, new_file_name, 0, file_length - 1, content
      _(file).wont_be_nil
      _(file.name).must_equal new_file_name
    end

    it "reads a file property with file permission" do
      sas_token = generator.generate_service_sas_token "#{share_name}/#{directory_name}/#{file_name}", service: "f", resource: "f", permissions: "r", protocol: "https"
      client = Azure::Storage::File::FileService.new({ storage_account_name: SERVICE_CREATE_OPTIONS()[:storage_account_name], storage_sas_token: sas_token })
      file_properties = client.get_file_properties share_name, directory_name, file_name
      _(file_properties).wont_be_nil
      _(file_properties.name).must_equal file_name
      _(file_properties.properties[:last_modified]).wont_be_nil
      _(file_properties.properties[:etag]).wont_be_nil
      _(file_properties.properties[:content_length]).must_equal file_length
      _(file_properties.properties[:type]).must_equal "File"
    end

    it "deletes a file with file permission" do
      sas_token = generator.generate_service_sas_token "#{share_name}/#{directory_name}/#{file_name}", service: "f", resource: "f", permissions: "d", protocol: "https"
      client = Azure::Storage::File::FileService.new({ storage_account_name: SERVICE_CREATE_OPTIONS()[:storage_account_name], storage_sas_token: sas_token })
      result = client.delete_file share_name, directory_name, file_name
      _(result).must_be_nil
    end
  end
end
