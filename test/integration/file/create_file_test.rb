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
require 'azure/core/http/http_error'
require 'integration/test_helper'

describe Azure::Storage::File::FileService do
  subject { Azure::Storage::File::FileService.new }
  after { ShareNameHelper.clean }

  describe '#create_file' do
    let(:share_name) { ShareNameHelper.name }
    let(:directory_name) { FileNameHelper.name }
    let(:file_name) { FileNameHelper.name }
    let(:file_length) { 1024 }
    before {
      subject.create_share share_name
      subject.create_directory share_name, directory_name
    }

    it 'creates the file' do
      file = subject.create_file share_name, directory_name, file_name, file_length
      file.name.must_equal file_name

      file = subject.get_file_properties share_name, directory_name, file_name
      file.properties[:content_length].must_equal file_length
    end

    it 'creates the file with custom metadata' do
      metadata = { 'CustomMetadataProperty' => 'CustomMetadataValue'}
      file = subject.create_file share_name, directory_name, file_name, file_length, { :metadata => metadata }
      
      file.name.must_equal file_name
      file.metadata.must_equal metadata
      file = subject.get_file_metadata share_name, directory_name, file_name

      metadata.each { |k,v|
        file.metadata.must_include k.downcase
        file.metadata[k.downcase].must_equal v
      }
    end

    it 'no errors if the file already exists' do
      subject.create_file share_name, directory_name, file_name, file_length
      subject.create_file share_name, directory_name, file_name, file_length + file_length
      file = subject.get_file_properties share_name, directory_name, file_name
      file.name.must_equal file_name
      file.properties[:content_length].must_equal file_length * 2
    end
    
    it 'errors if the difilerectory name is invalid' do
      assert_raises(Azure::Core::Http::HTTPError) do
        subject.create_file share_name, directory_name, 'this_file/cannot/exist!', file_length
      end
    end
  end
end

