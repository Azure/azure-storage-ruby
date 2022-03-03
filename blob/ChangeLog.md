2021.12 - version 2.0.3
* Lifted Ruby-version-based restrictions on Nokogiri version.

2021.10 - version 2.0.2
* Allowed to use any version 1.x of Nokogiri for Ruby version later than or equal to 2.5.0.
* Added access tier information and creation time of blob in response.

2020.8 - version 2.0.1
* Bumped up Nokogiri version to 1.11.0.rc2 for Ruby version later than or equal to 2.4.0.

2020.3 - version 2.0.0
* This module now supports Ruby versions to 2.3 through 2.7.
* Service version is upgraded to 2018-11-09.
* Add support for generating user delegation shared access signatures.

2018.11 - version 1.1.0
* Added the support for sending a request with a bearer token.

2018.1 - version 1.0.1
* Resolved an issue where user cannot use Gem package using `gem install`.

2018.1 - version 1.0.0

* This module now only consists of functionalities to access Azure Storage Blob Service.
* Creating Blob Client using `Azure::Storage::Client.create` is now deprecated. To create a Blob client, users have to choose from `Azure::Storage::Blob::BlobService::create`, `Azure::Storage::Blob::BlobService::create_development`, ``Azure::Storage::Blob::BlobService::create_from_env`, `Azure::Storage::Blob::BlobService::create_from_connection_string` or `Azure::Storage::Blob::BlobService.new`. The parameters remain unchanged.
* Added following convenience APIs to support large payload upload from given content to append or page blob, to make block blob consistent with API name, added an alias for `create_block_blob` as well.
  - Azure::Storage::Blob::BlobService::create_block_blob_from_content
  - Azure::Storage::Blob::BlobService::create_page_blob_from_content
  - Azure::Storage::Blob::BlobService::create_append_blob_from_content
* Added the support for `Azure::Storage::Blob::BlobService::create_block_blob` to handle large payload that used to require making multiple `Azure::Storage::Blob::BlobService::put_blob_block` calls and calling `Azure::Storage::Blob::BlobService::commit_blob_blocks`.
* The default `Content-Type` for a newly created page blob or append blob will now be `application/octet-stream`, which matches the description of [REST doc](https://docs.microsoft.com/en-us/rest/api/storageservices/put-blob)
* Resolved an issue where parsing XML content would sometimes throw unexpected failures.
* Resolved an issue where users send "increment" as `:sequence_number_action` option for `Azure::Storage::Blob::BlobService::set_blob_properties` would not be recognized.
