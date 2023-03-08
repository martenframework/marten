module Marten
  module Handlers
    module Defaults
      module Debug
        class ServerError < Handler
          class Frame
            @snippet_lines : Array(Tuple(String, Int32, Bool))?

            getter filepath
            getter line_number
            getter index

            def initialize(@filepath : String, @line_number : Int32, @index : Int32)
            end

            def filename
              filepath.split('/').last
            end

            def dep_name
              case filepath
              when .includes?("/marten/")
                "marten"
              when .includes?("/crystal/"), .includes?("/crystal-lang/")
                "crystal"
              when /lib\/(?<name>[^\/]+)\/.+/
                $~["name"]
              end
            end

            def snippet_lines
              @snippet_lines ||= begin
                lines = [] of Tuple(String, Int32, Bool)

                if File.exists?(filepath)
                  lines += File.read_lines(filepath).map_with_index do |code, line_index|
                    next unless (line_number - 5..line_number + 5).includes?(line_index + 1)
                    {HTML.escape(code), line_index + 1, line_index + 1 == line_number}
                  end
                end

                lines.compact
              end
            end
          end
        end
      end
    end
  end
end
