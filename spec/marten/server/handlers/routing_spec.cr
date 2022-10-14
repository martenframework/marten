require "./spec_helper"

describe Marten::Server::Handlers::Routing do
  describe "#call" do
    it "executes the resolved handler and sets the obtained response on the context for a route with no parameters" do
      handler = Marten::Server::Handlers::Routing.new

      context = HTTP::Server::Context.new(
        request: ::HTTP::Request.new(
          method: "GET",
          resource: "/dummy",
          headers: HTTP::Headers{"Host" => "example.com", "Accept-Language" => "FR,en;q=0.5"}
        ),
        response: ::HTTP::Server::Response.new(io: IO::Memory.new)
      )

      handler.call(context)

      context.marten.response.not_nil!.content.should eq "It works!"
    end

    it "executes the resolved handler and sets the obtained response on the context for a route with parameters" do
      handler = Marten::Server::Handlers::Routing.new

      context = HTTP::Server::Context.new(
        request: ::HTTP::Request.new(
          method: "GET",
          resource: "/dummy/42/and/foobar",
          headers: HTTP::Headers{"Host" => "example.com", "Accept-Language" => "FR,en;q=0.5"}
        ),
        response: ::HTTP::Server::Response.new(io: IO::Memory.new)
      )

      handler.call(context)

      context.marten.response.not_nil!.content.should eq "It works!"
    end

    it "raises Marten::Routing::Errors::NoResolveMatch if the requested route cannot be resolved" do
      handler = Marten::Server::Handlers::Routing.new

      context = HTTP::Server::Context.new(
        request: ::HTTP::Request.new(
          method: "GET",
          resource: "/unknown/42",
          headers: HTTP::Headers{"Host" => "example.com", "Accept-Language" => "FR,en;q=0.5"}
        ),
        response: ::HTTP::Server::Response.new(io: IO::Memory.new)
      )

      expect_raises(Marten::Routing::Errors::NoResolveMatch) do
        handler.call(context)
      end
    end
  end
end
