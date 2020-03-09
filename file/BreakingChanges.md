Tracking Breaking Changes in 2.0.0

* This module now supports Ruby versions to 2.3 through 2.7

Tracking Breaking Changes in 1.0.0

* This module now only consists of functionalities to access Azure Storage File Service.
* Creating File Client using `Azure::Storage::Client.create` is now deprecated. To create a File client, users have to choose from `Azure::Storage::File::FileService::create`, `Azure::Storage::File::FileService::create_development`, ``Azure::Storage::File::FileService::create_from_env`, `Azure::Storage::File::FileService::create_from_connection_string` or `Azure::Storage::File::FileService.new`. The parameters remain unchanged.
