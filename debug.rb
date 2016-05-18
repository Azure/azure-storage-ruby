require "azure/storage"

#tables = Azure::Storage::Table::TableService.new
#tables.create_table("testtable")
#tables.delete_table("testtable")

blobs = Azure::Storage::Blob::BlobService.new
blobs.with_filter(Azure::Storage::Core::Filter::ExponentialRetryPolicyFilter.new)
blobs.list_blobs "xy-test1"

#puts "#{blobs.list_blobs "xy-test1"}"