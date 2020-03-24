class HTTP::Server::Context
  def marten
    @marten ||= Marten::Server::Context.new(self)
  end
end
