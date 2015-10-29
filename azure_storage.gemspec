#-------------------------------------------------------------------------
# # Copyright (c) Microsoft and contributors. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#--------------------------------------------------------------------------
require 'date'

require File.expand_path('../lib/azure_storage/version', __FILE__)

Gem::Specification.new do |s|
  s.name    = 'azure_storage'
  s.version = Azure::Storage::Version
  s.authors     = ['Microsoft Corporation']
  s.email       = 'azureruby@microsoft.com'
  s.description = 'Microsoft Azure Storage Client Library for Ruby'
  s.summary     = 'Official Ruby client library to consume Azure Storage services'
  s.homepage    = 'http://github.com/azure/azure-sdk-for-ruby/storage'
  s.license     = 'Apache License, Version 2.0'
  s.files       = `git ls-files ./lib/azure_storage`.split("\n") + `git ls-files ./lib/azure/core`.split("\n") << 'lib/azure_storage.rb'
  
  s.required_ruby_version = '>= 1.9.3'

  s.add_runtime_dependency('addressable',             '~> 2.3')
  s.add_runtime_dependency('faraday',                 '~> 0.9')
  s.add_runtime_dependency('faraday_middleware',      '~> 0.10')
  s.add_runtime_dependency('json',                    '~> 1.8')
  s.add_runtime_dependency('mime-types',              '~> 2.0')
  s.add_runtime_dependency('nokogiri',                '~> 1.6')
  s.add_runtime_dependency('systemu',                 '~> 2.6')
  s.add_runtime_dependency('thor',                    '~> 0.19')
  s.add_runtime_dependency('uuid',                    '~> 2.0')

  # Please add development dependency in azure.spec
end
