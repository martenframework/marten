module Marten
  module Emailing
    module Backend
      # Abstract emailing backend.
      #
      # Emailing backends are responsible for delivering emails and must implement a single `#deliver` method.
      abstract class Base
        abstract def deliver(email : Email)
      end
    end
  end
end
