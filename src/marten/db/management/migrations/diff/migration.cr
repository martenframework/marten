module Marten
  module DB
    module Management
      module Migrations
        class Diff
          class Migration
            include CanFormatStringsOrSymbols

            @version : String

            getter app_label
            getter dependencies
            getter name
            getter operations
            getter replacements
            getter version

            setter operations
            setter replacements

            def initialize(
              @app_label : String,
              @name : String,
              @operations : Array(DB::Migration::Operation::Base),
              @dependencies : Array(Tuple(String, String)),
              @replacements = Array(Tuple(String, String)).new
            )
              @version = @name.dup

              name = if @operations.size == 1
                       @name + "_#{@operations.first.describe.downcase.gsub(" ", "_")}"
                     else
                       @name + "_auto"
                     end

              @name = name.size > Record::NAME_MAX_SIZE ? @name + "_auto" : name
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
