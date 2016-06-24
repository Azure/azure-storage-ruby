2016.07 - version 0.10.2

ALL
* Fixed the issue that cannot run against storage emulator on Windows.
* Fixed the issue that it doesn't run as a singleton when it calls Azure::Storage.setup.

2016.05 - version 0.10.1

ALL
* Replaced the core module by the 'azure-core' gem.
* Stopped maintaining the support for Ruby 1.9.
* Added support for retry filters.

2016.03 - version 0.10.0

ALL
* Separated out parts of Azure Storage previously found in the Azure SDK 0.7.0 to establish an independent release cycle.
* Supported Ruby 1.9.3, 2.0, 2.1 and 2.2.
* Updated to storage service version 2015-02-21. 
* Fixed issue where previous query's parameters were used, causing authentication to fail (https://github.com/Azure/azure-sdk-for-ruby/issues/276).
* Fixed the issue that the Content-MD5 is overwritten when request body exists, regardless the input value.
* Refined the code for setting service properties to be compatible with the XML schema.

BLOB
* Added support for container lease operations.
* Added support for changing the ID of an existing lease.
* Added support for copying from source blob URI.
* Added support for aborting copying a blob.
* Added support for creating an append blob.
* Added support for appending a block to an appendblob.
* Added support for the content disposition property of a blob.
* Added support for resizing a page blob.
* Added support for setting a page blob's sequence number.
* Fixed the issue where conditional headers for some APIs could not be set.
* Fixed the issue where the request fails when calling list_page_blob_ranges with start range and end range.
* Renamed create_blob_block to put_blob_block.
* Renamed create_blob_pages to put_blob_pages.