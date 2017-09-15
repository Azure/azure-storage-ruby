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
require "rake/testtask"
require "rubygems/package_task"
require "dotenv/tasks"
require "yard"

namespace :storage do
  gem_spec = eval(File.read("./azure-storage.gemspec"))
  Gem::PackageTask.new(gem_spec) do |pkg|
    pkg.need_zip = false
    pkg.need_tar = false
    pkg.package_dir = "pkg_azure_storage"
  end
end

YARD::Rake::YardocTask.new do |t|
  t.files   = ["lib/**/*.rb"]
  t.options = [""]
  t.stats_options = ["--list-undoc"]
end

task :publishDoc do
  desc "Generate documents and publish to GitHub Pages"
  repo = %x(git config remote.origin.url).gsub(/^git:/, "https:")
  deploy_branch = "gh-pages"
  if repo.match(/github\.com\.git$/)
    deploy_branch = "master"
  end
  system "git remote set-url --push origin #{repo}"
  system "git remote set-branches --add origin #{deploy_branch}"
  system "git fetch -q"
  if ("#{ENV['GIT_NAME']}" != "")
    system "git config user.name '#{ENV['GIT_NAME']}'"
  end
  if ("#{ENV['GIT_EMAIL']}" != "")
    system "git config user.email '#{ENV['GIT_EMAIL']}'"
  end
  system 'git config credential.helper "store --file=.git/credentials"'
  File.open(".git/credentials", "w") do |f|
    f.write("https://#{ENV['GH_TOKEN']}:x-oauth-basic@github.com")
  end
  system "rake yard"
  system "git checkout gh-pages"
  system "mv doc/* ./ -f"
  system "rm doc -rf"
  system "git add *"
  system "git commit -m \"update document\""
  system "git push"
  system "git checkout master"
  File.delete ".git/credentials"
end

namespace :test do
  task require_environment: :dotenv do
    unset_environment = [
      ENV.fetch("AZURE_STORAGE_ACCOUNT", nil),
      ENV.fetch("AZURE_STORAGE_ACCESS_KEY", nil),
      ENV.fetch("AZURE_STORAGE_CONNECTION_STRING", nil)
    ].include?(nil)

    abort "[ABORTING] Configure your environment to run the integration tests" if unset_environment
  end

  Rake::TestTask.new :unit do |t|
    t.pattern = "test/unit/**/*_test.rb"
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
    t.test_files = Dir["test/integration/**/*_test.rb"].reject do |path|
      path.include?("database")
    end
    t.verbose = true
    t.libs = %w(lib test)
  end

  task integration: :require_environment

  namespace :integration do
    def component_task(component)
      Rake::TestTask.new component do |t|
        t.pattern = "test/integration/#{component}/**/*_test.rb"
        t.verbose = true
        t.libs = %w(lib test)
      end

      task component => "test:require_environment"
    end

    component_task :storage
  end

  namespace :storage do

    Rake::TestTask.new :unit do |t|
      t.pattern = "test/unit/storage/**/*_test.rb"
      t.verbose = true
      t.libs = %w(lib test)
    end

    task require_storage_env: :dotenv do
      unset_environment = [
        ENV.fetch("AZURE_STORAGE_ACCOUNT", nil),
        ENV.fetch("AZURE_STORAGE_ACCESS_KEY", nil),
        ENV.fetch("AZURE_STORAGE_CONNECTION_STRING", nil)
      ].include?(nil)

      abort "[ABORTING] Configure your environment to run the storage integration tests" if unset_environment
    end


    Rake::TestTask.new :integration do |t|
      t.pattern = "test/integration/storage/**/*_test.rb"
      t.verbose = true
      t.libs = %w(lib test)
    end

    task integration: :require_storage_env
  end

  task cleanup: :require_environment do
    $:.unshift "lib"
    require "azure/storage"

    Azure.configure do |config|
      config.access_key     = ENV.fetch("AZURE_STORAGE_ACCESS_KEY")
      config.account_name   = ENV.fetch("AZURE_STORAGE_ACCOUNT")
    end
  end
end

task test: %w(test:unit test:integration)

task default: :test
