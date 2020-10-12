module Marten
  module DB
    module Management
      module Migrations
        class Runner
          enum ProgressType
            MIGRATION_APPLY_BACKWARD_START
            MIGRATION_APPLY_BACKWARD_SUCCESS
            MIGRATION_APPLY_FORWARD_START
            MIGRATION_APPLY_FORWARD_SUCCESS
          end
        end
      end
    end
  end
end
