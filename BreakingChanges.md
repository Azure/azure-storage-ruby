**Note: This BreakingChanges.md file is deprecated after version 0.15.0-preview, please refer to the BreakingChange.md in each package for future change logs.** 

Tracking Breaking Changes in 0.14.0-preview

QUEUE
* The return type of `Azure::Storage::Queue::create_message` is changed from `nil` to an `Azure::Storage::Queue::Message` object.

Tracking Breaking Changes in 0.13.0-preview

TABLE
* The return type `Azure::Service::EnumerationResult` of `query_tables` has a changed structure. Now the `'updated'` will not be contained, and is flattened to a structure in the form of `{ {"TableName" => "tableone"}, {"TableName" => "tabletwo"}, {"TableName" => "tablethree"}}`.
* The `Azure::Storage::Table::Entity` does not contain `:table` and `updated` anymore. The updated time can be found in `:properties`.
* The return type of `get_table` is changed to a Hash that contains full metadata returned from the server when query the table.
* The method `Azure::Storage::Table::EdmType::unserialize_query_value` is renamed to `deserialize_value`.

Tracking Breaking Changes in 0.11.0-preview

ALL
* `Azure::Storage::Core::Auth::SharedAccessSignature.generate` is renamed to `generate_service_sas_token`.
* `Azure::Storage::Core::Auth::SharedAccessSignature.signed_uri` requires `use_account_sas` as the second parameter.
* Removed the support for the Shared Key Lite.

Tracking Breaking Changes in 0.10.0-preview

ALL
* Require "azure-storage" instead of "azure_storage".

BLOB
* The `create_blob_pages` method is renamed to `put_blob_pages`.
* The `create_blob_block` method is renamed to `put_blob_block`.
* The `acquire_lease` method is renamed to `acquire_blob_lease`.
* The `renew_lease` method is renamed to `renew_blob_lease`.
* The `release_lease` method is renamed to `release_blob_lease`.
* The `break_lease` method is renamed to `break_blob_lease`.
