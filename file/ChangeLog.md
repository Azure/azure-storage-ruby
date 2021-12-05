2021.12 - version 2.0.4
* Lifted Ruby-version-based restrictions on Nokogiri version.

2021.10 - version 2.0.3
* Allowed to use any version 1.x of Nokogiri for Ruby version later than or equal to 2.5.0.

2020.8 - version 2.0.2
* Bumped up Nokogiri version to 1.11.0.rc2 for Ruby version later than or equal to 2.4.0.

2020.3 - version 2.0.1
* Resolved the issue where a wrong version of 'azure-storage-common' is depended on.

2020.3 - version 2.0.0
* This module now supports Ruby versions to 2.3 through 2.7

2018.1 - version 1.0.1
* Resolved an issue where user cannot use Gem package using `gem install`.

2018.1 - version 1.0.0

* This module now only consists of functionalities to access Azure Storage File Service.
* Creating File Client using `Azure::Storage::Client.create` is now deprecated. To create a File client, users have to choose from `Azure::Storage::File::FileService::create`, `Azure::Storage::File::FileService::create_development`, ``Azure::Storage::File::FileService::create_from_env`, `Azure::Storage::File::FileService::create_from_connection_string` or `Azure::Storage::File::FileService.new`. The parameters remain unchanged.
* Added convenience API `Azure::Storage::File::FileService::create_file_from_content` to support large payload upload from local to file.
