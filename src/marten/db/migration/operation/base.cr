require "../../concerns/can_format_strings_or_symbols"

module Marten
  module DB
    abstract class Migration
      module Operation
        # Base abstract class for migration operations.
        #
        # A migration operation is responsible for (i) mutating project states in order to identify changes to a given
        # set of models and (ii) mutating actual databases (applying or unapplying a given operation at the database
        # level).
        abstract class Base
          include CanFormatStringsOrSymbols

          @faked = false

          # Allows to set whether or not the mutation should be faked.
          setter faked

          # Returns a human-friendly description of what the operation is doing.
          abstract def describe : String

          # Applies the operation in a backward way at the database level.
          #
          # For most operation, this will involve "unapplying" whatever was done as part of the `#mutate_db_forward`
          # method.
          abstract def mutate_db_backward(
            app_label : String,
            schema_editor : Management::SchemaEditor::Base,
            from_state : Management::ProjectState,
            to_state : Management::ProjectState
          ) : Nil

          # Applies the operation at the database level.
          abstract def mutate_db_forward(
            app_label : String,
            schema_editor : Management::SchemaEditor::Base,
            from_state : Management::ProjectState,
            to_state : Management::ProjectState
          ) : Nil

          # Applies the operation at the project state level.
          abstract def mutate_state_forward(app_label : String, state : Management::ProjectState) : Nil

          # Combines the specified operation with the current one and return an array of corresponding operations.
          abstract def optimize(operation : Base) : Optimization::Result

          # Returns `true` if the operation references the specified table column.
          abstract def references_column?(other_table_name : String, other_column_name : String) : Bool

          # Returns `true` if the operation references the specified table.
          abstract def references_table?(other_table_name : String) : Bool

          # Renders a serialized version of the mutation.
          #
          # This method is used when generating migrations: the serialized operation is inserted in the `#plan` method
          # of the generated migration.
          abstract def serialize : String

          # Returns `true` if the mutation should be faked.
          def faked? : Bool
            @faked
          end
        end
      end
    end
  end
end
