module Marten
  module Core
    # Provides debug logging capabilities.
    #
    # This module can be included in classes that need to generate log entries when the debug mode is enabled only.
    module DebugModeLoggable
      # Logs a debug mode-only debug message.
      macro debug_mode_debug_log(message)
        Log.debug { (Log.context.metadata[:prefix]?.try(&.to_s) || "") + {{message}} } if Marten.settings.debug?
      end

      # Logs a debug mode-only info message.
      macro debug_mode_info_log(message)
        Log.info { (Log.context.metadata[:prefix]?.try(&.to_s) || "") + {{message}} } if Marten.settings.debug?
      end
    end
  end
end
