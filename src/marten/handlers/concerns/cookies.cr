module Marten
  module Handlers
    # Provides helpers methods to interact with cookies.
    module Cookies
      # Returns the cookies for the current request.
      delegate cookies, to: request
    end
  end
end
