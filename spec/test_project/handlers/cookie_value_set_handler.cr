class CookieValueSetHandler < Marten::Handlers::Base
  def dispatch
    cookies["foo"] = "bar"
    head 200
  end
end
