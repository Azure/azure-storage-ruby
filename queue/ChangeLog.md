2018.1 - version 1.0.1
* Resolved an issue where user cannot use Gem package using `gem install`.

2018.1 - version 1.0.0

* This module now only consists of functionalities to access Azure Storage Queue Service.
* Creating Queue Client using `Azure::Storage::Client.create` is now deprecated. To create a Queue client, users have to choose from `Azure::Storage::Queue::QueueService::create`, `Azure::Storage::Queue::QueueService::create_development`, ``Azure::Storage::Queue::QueueService::create_from_env`, `Azure::Storage::Queue::QueueService::create_from_connection_string` or `Azure::Storage::Queue::QueueService.new`. The parameters remain unchanged.
* Resolved an issue where decoding messages could throw unexpected exception when message text is empty.
