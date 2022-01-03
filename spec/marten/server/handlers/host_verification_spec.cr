require "./spec_helper"

describe Marten::Server::Handlers::HostVerification do
  around_each do |t|
    original_allowed_hosts = Marten.settings.allowed_hosts
    original_debug = Marten.settings.debug
    original_use_x_forwarded_host = Marten.settings.use_x_forwarded_host

    Marten.settings.allowed_hosts = %w(example.com)

    t.run

    Marten.settings.allowed_hosts = original_allowed_hosts
    Marten.settings.debug = original_debug
    Marten.settings.use_x_forwarded_host = original_use_x_forwarded_host
  end

  describe "#call" do
    it "raises Marten::HTTP::Errors::UnexpectedHost if the host is not allowed" do
      handler = Marten::Server::Handlers::HostVerification.new

      context = HTTP::Server::Context.new(
        request: ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "unknown.com", "Accept-Language" => "FR,en;q=0.5"}
        ),
        response: ::HTTP::Server::Response.new(io: IO::Memory.new)
      )

      expect_raises(Marten::HTTP::Errors::UnexpectedHost) do
        handler.call(context)
      end
    end
  end
end
