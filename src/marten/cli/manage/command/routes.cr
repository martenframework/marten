module Marten
  module CLI
    class Manage
      module Command
        class Routes < Base
          help "Display all the routes of the application."

          def run
            process_routes_map(Marten.routes)
          end

          private def process_routes_map(map, parent_path = "", parent_name = nil)
            map.rules.each do |rule|
              case rule
              when Marten::Routing::Rule::Path
                print_path(rule, parent_path, parent_name)
              when Marten::Routing::Rule::Map
                process_routes_map(rule.map, parent_path: rule.path, parent_name: rule.name)
              end
            end
          end

          private def print_path(rule, parent_path, parent_name)
            parts = [] of String

            parts << style(parent_path + rule.path, fore: :light_blue)
            parts << style("[#{parent_name.nil? ? rule.name : "#{parent_name}:#{rule.name}"}]", fore: :light_yellow)
            parts << "›"
            parts << style(rule.handler.name, fore: :light_green)

            if rule.handler.http_method_names != Handlers::Base.http_method_names
              parts << "(#{rule.handler.http_method_names.join(", ")})"
            end

            print(parts.join(" "))
          end
        end
      end
    end
  end
end
