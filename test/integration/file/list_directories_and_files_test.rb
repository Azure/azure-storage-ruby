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

describe Azure::Storage::File::FileService do
  subject { Azure::Storage::File::FileService.create(SERVICE_CREATE_OPTIONS()) }
  after { ShareNameHelper.clean }

  describe "#list_directories" do
    let(:share_name) { ShareNameHelper.name }
    let(:prefix) { FileNameHelper.name }
    let(:directories_names) { [prefix + FileNameHelper.name, prefix + FileNameHelper.name, FileNameHelper.name] }
    let(:sub_directories_names) { [FileNameHelper.name, FileNameHelper.name, FileNameHelper.name] }
    let(:metadata) { { "CustomMetadataProperty" => "CustomMetadataValue" } }
    before {
      subject.create_share share_name, metadata: metadata
      directories_names.each { |directory_name|
        subject.create_directory share_name, directory_name, metadata: metadata

        sub_directories_names.each { |sub_directory_name|
          sub_directory_path = ::File.join(directory_name, sub_directory_name)
          subject.create_directory share_name, sub_directory_path, metadata: metadata
        }
      }
    }

    it "lists the level_1 directories for the account" do
      result = subject.list_directories_and_files share_name, nil
      found = 0
      result.each { |directory|
        found += 1 if directories_names.include? directory.name
      }
      _(found).must_equal directories_names.length
    end

    it "lists the level_2 directories for the account" do
      result = subject.list_directories_and_files share_name, nil
      found = 0
      result.each { |directory|
        found += 1 if directories_names.include? directory.name

        sub_result =  subject.list_directories_and_files share_name, directory.name
        sub_result.each { |sub_directory_path|
          found += 1
        }
      }
      _(found).must_equal directories_names.length + directories_names.length * sub_directories_names.length
    end

    it "lists the shares for the account with max results" do
      result = subject.list_directories_and_files(share_name, nil, max_results: 1)
      _(result.length).must_equal 1
      first_directory = result[0]
      result.continuation_token.wont_equal ""

      result = subject.list_directories_and_files(share_name, nil, max_results: 2, marker: result.continuation_token)
      _(result.length).must_equal 2
      result[0].name.wont_equal first_directory.name
    end

    it "lists directories with the prefix" do
      result = subject.list_directories_and_files share_name, nil, prefix: prefix
      found = 0
      result.each { |directory|
        found += 1 if directories_names.include? directory.name
      }
      count = 0
      directories_names.each { |name|
        count += 1 if name.start_with? prefix
      }
      _(found).must_equal count
    end

    it "lists directories with the directory's name as prefix" do
      result = subject.list_directories_and_files(share_name, nil, prefix: directories_names[0])
      _(result.length).must_equal 1
      _(result.continuation_token).must_equal ""
      _(result[0].name).must_equal directories_names[0]
    end

    it "lists directories with a prefix that does not exist" do
      result = subject.list_directories_and_files(share_name, nil, prefix: directories_names[0] + "nonexistsuffix")
      _(result.length).must_equal 0
      _(result.continuation_token).must_equal ""
    end
  end

  describe "#list_directories_and_files" do
    let(:share_name) { FileNameHelper.name }
    let(:prefix) { FileNameHelper.name }
    let(:directories_names) { [FileNameHelper.name, FileNameHelper.name, FileNameHelper.name] }
    let(:sub_directories_names) { [FileNameHelper.name, FileNameHelper.name, FileNameHelper.name] }
    let(:file_names) { [prefix + FileNameHelper.name, prefix + FileNameHelper.name, FileNameHelper.name] }
    let(:file_length) { 1024 }
    let(:metadata) { { "CustomMetadataProperty" => "CustomMetadataValue" } }
    before {
      subject.create_share share_name, metadata: metadata
      directories_names.each { |directory_name|
        # Create level 1 directories
        subject.create_directory share_name, directory_name, metadata: metadata

        # Create level 1 files
        file_names.each { |file_name|
          subject.create_file share_name, directory_name, file_name, file_length, metadata: metadata
        }

        # Create level 2 directories
        sub_directories_names.each { |sub_directory_name|
          sub_directory_path = ::File.join(directory_name, sub_directory_name)
          subject.create_directory share_name, sub_directory_path, metadata: metadata
        }
      }
    }

    it "lists the level_2 directories and files for the account" do
      result = subject.list_directories_and_files share_name, directories_names[0]
      directory_found = 0
      file_found = 0
      result.each { |entry|
        directory_found += 1 if sub_directories_names.include?(entry.name) && entry.is_a?(Azure::Storage::File::Directory::Directory)
        file_found += 1 if file_names.include?(entry.name) && entry.is_a?(Azure::Storage::File::File)
      }
      _(directory_found).must_equal sub_directories_names.length
      _(file_found).must_equal file_names.length
    end

    it "lists the files with prefix" do
      result = subject.list_directories_and_files share_name, directories_names[0], prefix: prefix
      found = 0
      result.each { |file|
        found += 1 if file_names.include? file.name
      }
      count = 0
      file_names.each { |name|
        count += 1 if name.start_with? prefix
      }
      _(found).must_equal count
    end
  end
end
