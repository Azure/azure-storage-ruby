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
require 'rake/testtask'
require 'rubygems/package_task'
require 'dotenv/tasks'

namespace :storage do
  gem_spec = eval(File.read('./azure-storage.gemspec'))
  Gem::PackageTask.new(gem_spec) do |pkg|
    pkg.need_zip = false
    pkg.need_tar = false
    pkg.package_dir = 'pkg_azure_storage'
  end
end

namespace :test do
  task :require_environment => :dotenv do
    unset_environment = [
      ENV.fetch('AZURE_STORAGE_ACCOUNT', nil),
      ENV.fetch('AZURE_STORAGE_ACCESS_KEY', nil),
      ENV.fetch('AZURE_STORAGE_CONNECTION_STRING', nil)
    ].include?(nil)

    abort '[ABORTING] Configure your environment to run the integration tests' if unset_environment
  end

  Rake::TestTask.new :unit do |t|
    t.pattern = 'test/unit/**/*_test.rb'
    t.verbose = true
    t.libs = %w(lib test)
  end

  namespace :unit do
    def component_task(component)
      Rake::TestTask.new component do |t|
        t.pattern = "test/unit/#{component}/**/*_test.rb"
        t.verbose = true
        t.libs = %w(lib test)
      end
    end

    component_task :storage
  end

  Rake::TestTask.new :integration do |t|
    t.test_files = Dir['test/integration/**/*_test.rb'].reject do |path|
      path.include?('database')
    end
    t.verbose = true
    t.libs = %w(lib test)
  end

  task :integration => :require_environment

  namespace :integration do
    def component_task(component)
      Rake::TestTask.new component do |t|
        t.pattern = "test/integration/#{component}/**/*_test.rb"
        t.verbose = true
        t.libs = %w(lib test)
      end

      task component => 'test:require_environment'
    end

    component_task :storage
  end

  namespace :storage do

    Rake::TestTask.new :unit do |t|
      t.pattern = 'test/unit/storage/**/*_test.rb'
      t.verbose = true
      t.libs = %w(lib test)
    end

    task :require_storage_env => :dotenv do
      unset_environment = [
        ENV.fetch('AZURE_STORAGE_ACCOUNT', nil),
        ENV.fetch('AZURE_STORAGE_ACCESS_KEY', nil),
        ENV.fetch('AZURE_STORAGE_CONNECTION_STRING', nil)
      ].include?(nil)

      abort '[ABORTING] Configure your environment to run the storage integration tests' if unset_environment
    end


    Rake::TestTask.new :integration do |t|
      t.pattern = 'test/integration/storage/**/*_test.rb'
      t.verbose = true
      t.libs = %w(lib test)
    end

    task :integration => :require_storage_env
  end

  task :cleanup => :require_environment do
    $:.unshift 'lib'
    require 'azure/storage'

    Azure.configure do |config|
      config.access_key     = ENV.fetch('AZURE_STORAGE_ACCESS_KEY')
      config.account_name   = ENV.fetch('AZURE_STORAGE_ACCOUNT')
    end
  end
end

task :test => %w(test:unit test:integration)

task :default => :test
