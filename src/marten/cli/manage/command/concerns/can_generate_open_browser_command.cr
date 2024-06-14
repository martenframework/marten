module Marten
  module CLI
    class Manage
      module Command
        module CanGenerateOpenBrowserCommand
          def generate_open_command(url : String) : String
            open_command = ""

            {% if flag?(:linux) %}
              open_command = "xdg-open #{url}" # Linux
            {% elsif flag?(:win32) || flag?(:win64) %}
              open_command = "start #{url}" # Windows
            {% else %}
              open_command = "open #{url}" # macOS
            {% end %}

            open_command
          end
        end
      end
    end
  end
end
