Tracking Breaking Changes in 0.10.0
ALL
* Require "azure-storage" instead of "azure_storage".

BLOB
* The create_blob_pages method is renamed to put_blob_pages.
* The create_blob_block method is renamed to put_blob_block.
* The acquire_lease method is renamed to acquire_blob_lease.
* The renew_lease method is renamed to renew_blob_lease.
* The release_lease method is renamed to release_blob_lease.
* The break_lease method is renamed to break_blob_lease.
