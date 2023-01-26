class SecureRequestRequireHandler < Marten::Handlers::Base
  def dispatch
    if request.secure?
      head 200
    else
      head 403
    end
  end
end
