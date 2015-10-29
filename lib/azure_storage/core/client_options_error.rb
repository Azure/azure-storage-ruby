
module Azure::Storage

  class InvalidConnectionStringError < StorageError
    def initialize(message = SR::INVALID_CONNECTION_STRING)
    	super(message)
    end
  end

  class InvalidOptionsError < StorageError
    def initialize(message = SR::INVALID_CLIENT_OPTIONS)
      super(message)
    end
  end

end