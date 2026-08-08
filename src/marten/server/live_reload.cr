module Marten
  module Server
    module LiveReload
      @@watcher : FileWatcher?

      DEFAULT_WATCH_PATTERNS = [
        "src/**/*.cr",
        "src/**/*.ecr",
        "src/**/*.html",
        "src/assets/**/*",
        "config/**/*",
      ]

      def self.running? : Bool
        !@@watcher.nil?
      end

      def self.start(patterns = DEFAULT_WATCH_PATTERNS) : Nil
        return if running?
        setup_watcher(patterns)
      end

      def self.stop : Nil
        if watcher = @@watcher
          watcher.stop
          @@watcher = nil
        end
      end

      private def self.setup_watcher(patterns)
        # Create the watcher synchronously so running? can reflect state immediately
        watcher = FileWatcher.new(patterns: patterns)
        watcher.on_change do
          Marten::Handlers::LiveReload.broadcast("reload")
        end
        @@watcher = watcher
        # Start watching asynchronously
        spawn do
          watcher.start
        end
      end
    end
  end
end
