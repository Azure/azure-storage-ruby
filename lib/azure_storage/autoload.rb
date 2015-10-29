#-------------------------------------------------------------------------
# # Copyright (c) Microsoft and contributors. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#--------------------------------------------------------------------------

require 'azure_storage/core/autoload'

module Azure

  autoload :Storage,                      'azure_storage/core'
  autoload :Configurable,                 'azure_storage/configurable'

  module Storage
    
    autoload :Client,                     'azure_storage/client'
    autoload :ClientOptions,              'azure_storage/core/client_options'

    module Auth
      autoload :SharedAccessSignature,    'azure_storage/auth/shared_access_signature'
      autoload :SharedKey,                'azure_storage/auth/shared_key'
      autoload :SharedKeyLite,            'azure_storage/auth/shared_key_lite'
    end

    module Service
      autoload :Serialization,            'azure_storage/service/serialization'
      autoload :StorageService,           'azure_storage/service/storage_service'
    end

    module Blob
      autoload :BlobService,              'azure_storage/blob/blob_service'
      autoload :Blob,                     'azure_storage/blob/blob'
      autoload :Block,                    'azure_storage/blob/block'
      autoload :Container,                'azure_storage/blob/container'
      autoload :Serialization,            'azure_storage/blob/serialization'
    end

    module Queue
      autoload :QueueService,             'azure_storage/queue/queue_service'
      autoload :Message,                  'azure_storage/queue/message'
      autoload :Queue,                    'azure_storage/queue/queue'
    end

    module Table
      autoload :TableService,             'azure_storage/table/table_service'
      autoload :Batch,                    'azure_storage/table/batch'
      autoload :Query,                    'azure_storage/table/query'
    end

  end
end
