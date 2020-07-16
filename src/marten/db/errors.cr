module Marten
  module DB
    module Errors
      # Represents an error raised when a problem is detected with a specific model field.
      class InvalidField < Exception; end

      # Represents an error raised when an inexistent field is requested for a specific model.
      class UnknownField < Exception; end

      # Represents an error raised when an inexistent predicate is requested for a specific query.
      class UnknownPredicate < Exception; end

      # Represents an error raised when an inexistent record is queried for a specific model. This exception is
      # automatically subclassed for every model class.
      class RecordNotFound < Exception; end

      # Represents an error raised when a get query returned more than one result.
      class MultipleRecordsFound < Exception; end
    end
  end
end
