Tracking Breaking Changes in 2.0.0

* This module now supports Ruby versions to 2.3 through 2.7

Tracking Breaking Changes in 1.0.0

* This module now only consists of functionalities to access Azure Storage Table Service.
* Creating Table Client using `Azure::Storage::Client.create` is now deprecated. To create a Table client, users have to choose from `Azure::Storage::Table::TableService::create`, `Azure::Storage::Table::TableService::create_development`, ``Azure::Storage::Table::TableService::create_from_env`, `Azure::Storage::Table::TableService::create_from_connection_string` or `Azure::Storage::Table::TableService.new`. The parameters remain unchanged.
