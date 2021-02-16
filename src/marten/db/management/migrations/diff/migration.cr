module Marten
  module DB
    module Management
      module Migrations
        class Diff
          class Migration
            getter app_label
            getter name
            getter operations
            getter dependencies

            def initialize(
              @app_label : String,
              @name : String,
              @operations : Array(DB::Migration::Operation::Base),
              @dependencies : Array(Tuple(String, String))
            )
              if @operations.size == 1
                @name += "_#{@operations.first.describe.downcase.gsub(" ", "_")}"
              else
                @name += "_auto"
              end
            end

            def serialize
              ECR.render "#{__DIR__}/migration.ecr"
            end
          end
        end
      end
    end
  end
end