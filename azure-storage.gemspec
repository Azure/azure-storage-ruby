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
require 'date'

require File.expand_path('../lib/azure/storage/version', __FILE__)

Gem::Specification.new do |s|
  s.name        = 'azure-storage'
  s.version     = Azure::Storage::Version
  s.authors     = ['Microsoft Corporation']
  s.email       = 'ascl@microsoft.com'
  s.description = 'Microsoft Azure Storage Client Library for Ruby'
  s.summary     = 'Official Ruby client library to consume Azure Storage services'
  s.homepage    = 'http://github.com/azure/azure-storage-ruby'
  s.license     = 'MIT'
  s.files       = `git ls-files ./lib/azure/storage`.split("\n") << 'lib/azure/storage.rb'
  
  s.required_ruby_version = '>= 1.9.3'

  s.add_runtime_dependency('azure-core',              '~> 0.1')
  s.add_runtime_dependency('faraday',                 '~> 0.9')
  s.add_runtime_dependency('faraday_middleware',      '~> 0.10')
  if RUBY_VERSION < "2.1.0"
    s.add_runtime_dependency('nokogiri',              '~> 1.6.0')
  else
    s.add_runtime_dependency('nokogiri',              '~> 1.7', '< 1.8')
  end
  
  s.add_development_dependency('dotenv',              '~> 2.0')
  s.add_development_dependency('minitest',            '~> 5')
  s.add_development_dependency('minitest-reporters',  '~> 1')
  s.add_development_dependency('mocha',               '~> 1.0')
  s.add_development_dependency('rake',                '~> 10.0')
  s.add_development_dependency('timecop',             '~> 0.7')
  s.add_development_dependency('yard',                '~> 0.8')
end
