module Marten
  module DB
    abstract class Model
      module Persistence
        # :nodoc:
        @new_record : Bool = true

        protected setter new_record
      end
    end
  end
end
