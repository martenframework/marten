module Marten
  module CLI
    class Manage
      module Command
        class New < Base
          abstract class Template
            @full_path : Path

            getter context

            def initialize(@context : Context)
              @full_path = @context.expanded_dir.join(path)
            end

            abstract def path
            abstract def target

            def render
              Dir.mkdir_p(@full_path.dirname)
              File.write(@full_path, to_s)
            end
          end
        end
      end
    end
  end
end
