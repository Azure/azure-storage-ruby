#-------------------------------------------------------------------------
# # Copyright (c) Microsoft and contributors. All rights reserved.
#
# The MIT License(MIT)

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files(the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and / or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions :

# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#--------------------------------------------------------------------------

require 'azure/storage/core/autoload'

module Azure

  autoload :Storage,                      'azure/storage/core'

  module Storage
    autoload :Default,                    'azure/storage/default'
    autoload :Configurable,               'azure/storage/configurable'
    autoload :Client,                     'azure/storage/client'
    autoload :ClientOptions,              'azure/storage/client_options'
    
    module Auth
      autoload :SharedAccessSignature,    'azure/storage/core/auth/shared_access_signature'
    end

    module Service
      autoload :Serialization,            'azure/storage/service/serialization'
      autoload :StorageService,           'azure/storage/service/storage_service'
    end

    module Blob
      autoload :Blob,                     'azure/storage/blob/blob'
      autoload :Block,                    'azure/storage/blob/block'
      autoload :Page,                     'azure/storage/blob/page'
      autoload :Append,                   'azure/storage/blob/append'
      autoload :Container,                'azure/storage/blob/container'
      autoload :Serialization,            'azure/storage/blob/serialization'
      autoload :BlobService,              'azure/storage/blob/blob_service'
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

    module File
      autoload :FileService,              'azure/storage/file/file_service'
      autoload :Share,                    'azure/storage/file/share'
      autoload :Directory,                'azure/storage/file/directory'
      autoload :File,                     'azure/storage/file/file'
      autoload :Serialization,            'azure/storage/file/serialization'
    end

  end
end