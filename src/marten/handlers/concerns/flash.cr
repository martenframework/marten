module Marten
  module Handlers
    # Provides helpers methods to interact with the flash store.
    module Flash
      # Returns the flash store for the considered request.
      delegate flash, to: request
    end
  end
end
