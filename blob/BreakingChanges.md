Tracking Breaking Changes in 2.0.0

* This module now supports Ruby versions to 2.3 through 2.7

Tracking Breaking Changes in 1.0.0

* This module now only consists of functionalities to access Azure Storage Blob Service.
* Creating Blob Client using `Azure::Storage::Client.create` is now deprecated. To create a Blob client, users have to choose from `Azure::Storage::Blob::BlobService::create`, `Azure::Storage::Blob::BlobService::create_development`, ``Azure::Storage::Blob::BlobService::create_from_env`, `Azure::Storage::Blob::BlobService::create_from_connection_string` or `Azure::Storage::Blob::BlobService.new`. The parameters remain unchanged.
* The default `Content-Type` for a newly created page blob or append blob will now be `application/octet-stream`, which matches the description of [REST doc](https://docs.microsoft.com/en-us/rest/api/storageservices/put-blob)
* The API "Azure::Storage::Blob::BlobService::create_block_blob" can now upload content that is larger than 256MB instead of reporting failure.
