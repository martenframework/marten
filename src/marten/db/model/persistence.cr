module Marten
  module DB
    abstract class Model
      module Persistence
        # :nodoc:
        @destroyed : Bool = false

        # :nodoc:
        @new_record : Bool = true

        protected setter new_record
      end
    end
  end
end
