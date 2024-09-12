abstract class DB::Statement
  include Marten::Core::DebugModeLoggable

  protected def emit_log(args : Enumerable)
    debug_mode_debug_log("Executing query: #{command}")
  end
end
