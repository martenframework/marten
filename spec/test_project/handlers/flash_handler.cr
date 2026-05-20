class FlashHandler < Marten::Handlers::Base
  def dispatch
    flash[:notice] = "Hello, world!"
    head :ok
  end
end
