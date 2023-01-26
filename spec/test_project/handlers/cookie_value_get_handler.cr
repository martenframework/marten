class CookieValueGetHandler < Marten::Handlers::Base
  def dispatch
    respond cookies["foo"]?.to_s
  end
end
