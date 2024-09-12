require "./spec_helper"

describe Marten::Core::DebugModeLoggable do
  describe "::debug_mode_debug_log" do
    it "logs a debug message when the debug mode is enabled" do
      Log.capture do |logs|
        with_overridden_setting("debug", true) do
          Marten::Core::DebugModeLoggable.debug_mode_debug_log("Test message")
        end

        logs.check(:debug, /Test message/)
      end
    end

    it "does not log a debug message when the debug mode is not enabled" do
      Log.capture do |logs|
        with_overridden_setting("debug", false) do
          Marten::Core::DebugModeLoggable.debug_mode_debug_log("Test message")
        end

        logs.empty
      end
    end
  end

  describe "::debug_mode_info_log" do
    it "logs an info message when the debug mode is enabled" do
      Log.capture do |logs|
        with_overridden_setting("debug", true) do
          Marten::Core::DebugModeLoggable.debug_mode_info_log("Test message")
        end

        logs.check(:info, /Test message/)
      end
    end

    it "does not log an info message when the debug mode is not enabled" do
      Log.capture do |logs|
        with_overridden_setting("debug", false) do
          Marten::Core::DebugModeLoggable.debug_mode_info_log("Test message")
        end

        logs.empty
      end
    end
  end
end
