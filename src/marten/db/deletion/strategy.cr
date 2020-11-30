module Marten
  module DB
    module Deletion
      enum Strategy
        CASCADE
        DO_NOTHING
        PROTECT
        SET_NULL
      end
    end
  end
end
