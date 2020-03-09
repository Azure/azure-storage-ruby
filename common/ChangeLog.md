2020.3 - version 2.0.0
* This module now supports Ruby versions to 2.3 through 2.7
* Add support for generating user delegation shared access signatures.
* Update the storage API version used to generate shared access signatures to 2018-11-09.
* This module now contains azure-core which was originally in azure-ruby-asm-core.
* The following dependency version was bumped up to the specified version for security update:
    Nokogiri 1.10.4
    Faraday  1.0.0
    Rake     13.0
* Now reuses the HTTP Client on host level.

2018.11 - version 1.1.0
* Added the support for sending a request with a bearer token.
* Added the configuration for SSL versions.
* Fixed the issue that the retry interval could be negative. [#121]
* Fixed the timeout issue when the resource doesn't exist. [#122]

2018.1 - version 1.0.1
* Resolved an issue where user cannot use Gem package using `gem install`.

2018.1 - version 1.0.0

* This module now consists of functionalities to support service client library modules.
* All namespaces in this module now begin with "Azure::Storage::Common" instead of "Azure::Storage".
* Resolved an issue where user tries to access `Azure::Storage::Common::Default::signer` would throw `undefined method 'signer' for Azure::Storage::Default:Module`.
