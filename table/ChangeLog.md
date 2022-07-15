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

* This module now only consists of functionalities to access Azure Storage Table Service.
* Creating Table Client using `Azure::Storage::Client.create` is now deprecated. To create a Table client, users have to choose from `Azure::Storage::Table::TableService::create`, `Azure::Storage::Table::TableService::create_development`, ``Azure::Storage::Table::TableService::create_from_env`, `Azure::Storage::Table::TableService::create_from_connection_string` or `Azure::Storage::Table::TableService.new`. The parameters remain unchanged.
* Added support for Batch operation to perform a single `QueryEntity` operation.
* Resolved an issue where users used connection string to initialize Table Service and use batch operation would fail.
