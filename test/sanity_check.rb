  require "azure/storage/common"
  require "azure/storage/blob"
  require "azure/storage/table"
  require "azure/storage/queue"
  require "azure/storage/file"

  raise StandardError.new "Failed to load Common module" if Azure::Storage::Common::Version.nil?
  raise StandardError.new "Failed to load Blob module" if Azure::Storage::Blob::Version.nil?
  raise StandardError.new "Failed to load Queue module" if Azure::Storage::Queue::Version.nil?
  raise StandardError.new "Failed to load Table module" if Azure::Storage::Table::Version.nil?
  raise StandardError.new "Failed to load File module" if Azure::Storage::File::Version.nil?

  puts "Installed gem version of common is #{Azure::Storage::Common::Version}"
  puts "Installed gem version of blob is #{Azure::Storage::Blob::Version}"
  puts "Installed gem version of queue is #{Azure::Storage::Queue::Version}"
  puts "Installed gem version of table is #{Azure::Storage::Table::Version}"
  puts "Installed gem version of file is #{Azure::Storage::File::Version}"