module Marten
  module Server
    # A simple file watcher that monitors files for changes.
    # Used by the live reload server to detect when files have been modified.
    class FileWatcher
      property patterns : Array(String)
      property debounce : Time::Span
      @on_change : Proc(Nil)?
      @running = false
      @last_change = Time.monotonic
      @timestamps = {} of String => Time

      def initialize(@patterns = [] of String, @debounce = 1.second)
      end

      # Set the callback to be called when files change
      def on_change(&block : -> Nil)
        @on_change = block
      end

      # Start watching for file changes
      def start : Nil
        return if @running
        @running = true

        while @running
          check_for_changes
          sleep(POLL_INTERVAL)
        end
      end

      # Stop watching for file changes
      def stop : Nil
        @running = false
      end

      private POLL_INTERVAL = 0.5.seconds

      private def check_for_changes
        changed = false

        patterns.each do |pattern|
          Dir.glob(pattern) do |file|
            next if file.ends_with?(".tmp")
            next if file.ends_with?(".lock")

            begin
              current_time = File.info(file).modification_time
              if @timestamps[file]? != current_time
                @timestamps[file] = current_time
                changed = true
              end
            rescue ex : File::Error | Exception
              # File may have been removed or is temporarily inaccessible; skip it
              next
            end
          end
        end

        if changed && (Time.monotonic - @last_change) > @debounce
          @last_change = Time.monotonic
          @on_change.try &.call
        end
      end
    end
  end
end
