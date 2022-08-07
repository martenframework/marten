require "./spec_helper"

describe Marten::Server::Context do
  describe "#request" do
    it "returns returns a Marten context initialized from the HTTP request" do
      server_context = Marten::Server::Context.new(
        HTTP::Server::Context.new(
          request: ::HTTP::Request.new(
            method: "GET",
            resource: "/foo",
            headers: HTTP::Headers{"Host" => "unknown.com", "Accept-Language" => "FR,en;q=0.5"}
          ),
          response: ::HTTP::Server::Response.new(io: IO::Memory.new)
        )
      )

      server_context.request.method.should eq "GET"
      server_context.request.path.should eq "/foo"
      server_context.request.headers[:HOST].should eq "unknown.com"
      server_context.request.headers[:ACCEPT_LANGUAGE].should eq "FR,en;q=0.5"
    end
  end

  describe "#response" do
    it "returns nil by default" do
      server_context = Marten::Server::Context.new(
        HTTP::Server::Context.new(
          request: ::HTTP::Request.new(
            method: "GET",
            resource: "/foo",
            headers: HTTP::Headers{"Host" => "unknown.com", "Accept-Language" => "FR,en;q=0.5"}
          ),
          response: ::HTTP::Server::Response.new(io: IO::Memory.new)
        )
      )

      server_context.response.should be_nil
    end

    it "returns the assigned response if applicable" do
      server_context = Marten::Server::Context.new(
        HTTP::Server::Context.new(
          request: ::HTTP::Request.new(
            method: "GET",
            resource: "/foo",
            headers: HTTP::Headers{"Host" => "unknown.com", "Accept-Language" => "FR,en;q=0.5"}
          ),
          response: ::HTTP::Server::Response.new(io: IO::Memory.new)
        )
      )

      response = Marten::HTTP::Response.new("It works!", status: 200)

      server_context.response = response
      server_context.response.should eq response
    end
  end

  describe "#response=" do
    it "allows to assign a response object to the context" do
      server_context = Marten::Server::Context.new(
        HTTP::Server::Context.new(
          request: ::HTTP::Request.new(
            method: "GET",
            resource: "/foo",
            headers: HTTP::Headers{"Host" => "unknown.com", "Accept-Language" => "FR,en;q=0.5"}
          ),
          response: ::HTTP::Server::Response.new(io: IO::Memory.new)
        )
      )

      response = Marten::HTTP::Response.new("It works!", status: 200)

      server_context.response = response
      server_context.response.should eq response
    end
  end
end
