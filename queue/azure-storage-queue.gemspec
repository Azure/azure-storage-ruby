# frozen_string_literal: true

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
require "date"

require_relative "./lib/azure/storage/queue/version"

Gem::Specification.new do |s|
  s.name        = "azure-storage-queue"
  s.version     = Azure::Storage::Queue::Version
  s.authors     = ["Microsoft Corporation"]
  s.email       = "ascl@microsoft.com"
  s.description = "Microsoft Azure Storage Queue Client Library for Ruby"
  s.summary     = "Official Ruby client library to consume Azure Storage Queue service"
  s.homepage    = "http://github.com/azure/azure-storage-ruby"
  s.license     = "MIT"
  s.files       = `git ls-files ./lib/azure/storage/queue/`.split("\n") << "./lib/azure/storage/queue.rb"

  s.required_ruby_version = ">= 2.3.0"

  s.add_runtime_dependency("azure-storage-common",    "~> 2.0")
  s.add_runtime_dependency("nokogiri",                "~> 1", ">= 1.10.8")
  s.add_development_dependency("dotenv",              "~> 2.0")
  s.add_development_dependency("minitest",            "~> 5")
  s.add_development_dependency("minitest-reporters",  "~> 1")
  s.add_development_dependency("mocha",               "~> 1.0")
  s.add_development_dependency("rake",                "~> 13.0")
  s.add_development_dependency("timecop",             "~> 0.7")
  s.add_development_dependency("yard",                "~> 0.9", ">= 0.9.11")
end
