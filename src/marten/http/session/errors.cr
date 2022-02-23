module Marten
  module HTTP
    module Session
      module Errors
        # Represents an error that is raised when an unknown session store is requested.
        class UnknownStore < Exception; end
      end
    end
  end
end
