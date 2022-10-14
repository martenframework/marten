module Marten
  module Handlers
    # Provides helpers methods to interact with the session store.
    module Session
      # Returns the session store for the considered request.
      delegate session, to: request
    end
  end
end
