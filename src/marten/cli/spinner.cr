module Marten
  module CLI
    # Represents a simple spinner that can be used while a task is being performed in a terminal.
    class Spinner
      def self.start(*args, **kwargs, &)
        spinner = new(*args, **kwargs).start
        yield
      ensure
        spinner.not_nil!.stop
      end

      def initialize(@text : String, @io : IO)
      end

      def start : self
        self.running = true
        refresh_spinner

        spawn do
          while running?
            refresh_spinner if proceed_to_next_frame?
            Fiber.yield
          end
        end

        self
      end

      def stop : self
        self.running = false
        flush_line
        self
      end

      private FRAMES = [
        "⠋",
        "⠙",
        "⠹",
        "⠸",
        "⠼",
        "⠴",
        "⠦",
        "⠧",
        "⠇",
        "⠏",
      ]
      private FRAMES_INTERVAL = 80.milliseconds

      private getter io
      private getter text

      private property current_frame_index : Int32 = 0
      private property last_frame_printed_at : Time? = nil
      private property? running = false

      private def flush_line
        io.print("\33[2K\r")
      end

      private def proceed_to_next_frame?
        last_frame_printed_at.nil? || last_frame_printed_at.not_nil! < FRAMES_INTERVAL.ago
      end

      private def refresh_spinner
        self.current_frame_index += 1
        self.current_frame_index %= FRAMES.size

        flush_line

        io.print("#{FRAMES[current_frame_index]} ")
        io.print(text)

        self.last_frame_printed_at = Time.utc
      end
    end
  end
end
