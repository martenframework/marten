class SessionValueGetHandler < Marten::Handlers::Base
  def dispatch
    respond session["foo"]?.to_s
  end
end
