2018.1 - version 1.0.1
* Resolved an issue where user cannot use Gem package using `gem install`.

2018.1 - version 1.0.0

* This module now only consists of functionalities to access Azure Storage File Service.
* Creating File Client using `Azure::Storage::Client.create` is now deprecated. To create a File client, users have to choose from `Azure::Storage::File::FileService::create`, `Azure::Storage::File::FileService::create_development`, ``Azure::Storage::File::FileService::create_from_env`, `Azure::Storage::File::FileService::create_from_connection_string` or `Azure::Storage::File::FileService.new`. The parameters remain unchanged.
* Added convenience API `Azure::Storage::File::FileService::create_file_from_content` to support large payload upload from local to file.
