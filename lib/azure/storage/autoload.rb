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

require 'azure/storage/core/autoload'

module Azure

  autoload :Storage,                      'azure/storage/core'

  module Storage
    autoload :Configurable,               'azure/storage/configurable'
    autoload :Client,                     'azure/storage/client'
    autoload :ClientOptions,              'azure/storage/core/client_options'
    
    module Auth
      autoload :SharedAccessSignature,    'azure/storage/core/auth/shared_access_signature'
      autoload :SharedKey,                'azure/storage/core/auth/shared_key'
      autoload :SharedKeyLite,            'azure/storage/core/auth/shared_key_lite'
    end

    module Service
      autoload :Serialization,            'azure/storage/service/serialization'
      autoload :StorageService,           'azure/storage/service/storage_service'
    end

    module Blob
      autoload :BlobService,              'azure/storage/blob/blob_service'
      autoload :Blob,                     'azure/storage/blob/blob'
      autoload :Block,                    'azure/storage/blob/block'
      autoload :Container,                'azure/storage/blob/container'
      autoload :Serialization,            'azure/storage/blob/serialization'
    end

    module Queue
      autoload :QueueService,             'azure/storage/queue/queue_service'
      autoload :Message,                  'azure/storage/queue/message'
      autoload :Queue,                    'azure/storage/queue/queue'
    end

    module Table
      autoload :TableService,             'azure/storage/table/table_service'
      autoload :Batch,                    'azure/storage/table/batch'
      autoload :Query,                    'azure/storage/table/query'
    end

  end
end
