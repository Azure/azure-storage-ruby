2018.1 - version 1.0.1
* Resolved an issue where user cannot use Gem package using `gem install`.

2018.1 - version 1.0.0

* This module now consists of functionalities to support service client library modules.
* All namespaces in this module now begin with "Azure::Storage::Common" instead of "Azure::Storage".
* Resolved an issue where user tries to access `Azure::Storage::Common::Default::signer` would throw `undefined method 'signer' for Azure::Storage::Default:Module`.
