module Marten
  module DB
    module Errors
      # Represents an error raised when a problem is detected with a specific model field.
      class InvalidField < Exception; end

      # Represents an error raised when a create / save operation fails because of an invalid record.
      class InvalidRecord < Exception; end

      # Represents an error raised when a get query returned more than one result.
      class MultipleRecordsFound < Exception; end

      # Represents an error raised when an attempt to delete an object targeted by protected relation (many to one or
      # one to one) is made.
      class ProtectedRecord < Exception; end

      # Represents an error raised when an inexistent record is queried for a specific model. This exception is
      # automatically subclassed for every model class.
      class RecordNotFound < Exception; end

      # Represents an explicit rollback error that can be raised from inside a transaction block. By default exceptions
      # happening inside a transaction block are resurfaced outside of it, but this is not the case with
      # `Marten::DB::Errors::Rollback` exceptions: when this specific exception is raised from inside a transaction
      # block, the transaction will be rollbacked and the transaction block will return `false`.
      class Rollback < Exception; end

      # Represents an error raised when a suspicious file operation is identified.
      class SuspiciousFileOperation < Exception; end

      # Represents an error raised when a field value cannot be processed because it doesn't have the expected type.
      # This can happen when initializing model objects using unexpected values and types.
      class UnexpectedFieldValue < Exception; end

      # Represents an error raised when an unknown database connection is requested.
      class UnknownConnection < Exception; end

      # Represents an error raised when an inexistent field is requested for a specific model.
      class UnknownField < Exception; end

      # Represents an error raised when an inexistent predicate is requested for a specific query.
      class UnknownPredicate < Exception; end

      # Represents an error raised when a condition is not met on a particular query set in order to perform a specific
      # operation.
      class UnmetQuerySetCondition < Exception; end

      # Represents an error raised when a condition is not met on a particular object in order to be saved. This error
      # is not related to model instances validation.
      class UnmetSaveCondition < Exception; end
    end
  end
end
