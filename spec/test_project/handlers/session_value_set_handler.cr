class SessionValueSetHandler < Marten::Handlers::Base
  def dispatch
    session["foo"] = "bar"
    head 200
  end
end
