2018.1 - version 1.0.1
* Resolved an issue where user cannot use Gem package using `gem install`.

2018.1 - version 1.0.0

* This module now only consists of functionalities to access Azure Storage Table Service.
* Creating Table Client using `Azure::Storage::Client.create` is now deprecated. To create a Table client, users have to choose from `Azure::Storage::Table::TableService::create`, `Azure::Storage::Table::TableService::create_development`, ``Azure::Storage::Table::TableService::create_from_env`, `Azure::Storage::Table::TableService::create_from_connection_string` or `Azure::Storage::Table::TableService.new`. The parameters remain unchanged.
* Added support for Batch operation to perform a single `QueryEntity` operation.
* Resolved an issue where users used connection string to initialize Table Service and use batch operation would fail.
