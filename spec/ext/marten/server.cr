module Marten::Server
  # :nodoc:
  def self.reset_instance : Nil
    @@instance = nil
  end
end
