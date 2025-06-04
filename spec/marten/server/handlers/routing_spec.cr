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

      context.marten.request.route?.not_nil!.rule.name.should eq "dummy"
      context.marten.request.route?.not_nil!.rule.path.should eq "/dummy"
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

      context.marten.request.route?.not_nil!.rule.name.should eq "dummy_with_id_and_scope"
      context.marten.request.route?.not_nil!.rule.path.should eq "/dummy/<id:int>/and/<scope:slug>"
      context.marten.response.not_nil!.content.should eq "It works!"
    end

    it "logs an entry indicating the matched handler in debug mode" do
      handler = Marten::Server::Handlers::Routing.new

      context = HTTP::Server::Context.new(
        request: ::HTTP::Request.new(
          method: "GET",
          resource: "/dummy",
          headers: HTTP::Headers{"Host" => "example.com", "Accept-Language" => "FR,en;q=0.5"}
        ),
        response: ::HTTP::Server::Response.new(io: IO::Memory.new)
      )

      with_overridden_setting("debug", true) do
        Log.capture do |logs|
          handler.call(context)

          logs.check(:info, /Routed to: DummyHandler/i)
        end

        context.marten.response.not_nil!.content.should eq "It works!"
      end
    end

    context "with the trailing_slash setting set to do_nothing" do
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

        handler.call(context)
        context.marten.response.not_nil!.status.should eq(404)
        context.marten.response.not_nil!.content.should eq "The requested resource was not found."
      end
    end

    context "with the trailing_slash setting set to add" do
      around_each do |t|
        with_overridden_setting("trailing_slash", :add) do
          with_overridden_setting("allowed_hosts", ["example.com"]) do
            t.run
          end
        end
      end

      it "raises if the requested route cannot be resolved and ends with a slash" do
        handler = Marten::Server::Handlers::Routing.new

        context = HTTP::Server::Context.new(
          request: ::HTTP::Request.new(
            method: "GET",
            resource: "/unknown/42/",
            headers: HTTP::Headers{"Host" => "example.com", "Accept-Language" => "FR,en;q=0.5"}
          ),
          response: ::HTTP::Server::Response.new(io: IO::Memory.new)
        )

        handler.call(context)
        context.marten.response.not_nil!.status.should eq(404)
        context.marten.response.not_nil!.content.should eq "The requested resource was not found."
      end

      it "raises if the request route is the root" do
        handler = Marten::Server::Handlers::Routing.new

        context = HTTP::Server::Context.new(
          request: ::HTTP::Request.new(
            method: "GET",
            resource: "",
            headers: HTTP::Headers{"Host" => "example.com", "Accept-Language" => "FR,en;q=0.5"}
          ),
          response: ::HTTP::Server::Response.new(io: IO::Memory.new)
        )

        handler.call(context)
        context.marten.response.not_nil!.status.should eq(404)
        context.marten.response.not_nil!.content.should eq "The requested resource was not found."
      end

      it "returns a permanent redirect if the requested route cannot be resolved and does not end with a slash" do
        handler = Marten::Server::Handlers::Routing.new

        context = HTTP::Server::Context.new(
          request: ::HTTP::Request.new(
            method: "GET",
            resource: "/unknown/42",
            headers: HTTP::Headers{"Host" => "example.com", "Accept-Language" => "FR,en;q=0.5"}
          ),
          response: ::HTTP::Server::Response.new(io: IO::Memory.new)
        )

        handler.call(context)

        context.marten.response.should be_a Marten::HTTP::Response::MovedPermanently
        context.marten.response.not_nil!.headers["Location"].should eq "http://example.com/unknown/42/"
      end
    end

    context "with the trailing_slash setting set to remove" do
      around_each do |t|
        with_overridden_setting("trailing_slash", :remove) do
          with_overridden_setting("allowed_hosts", ["example.com"]) do
            t.run
          end
        end
      end

      it "raises if the requested route cannot be resolved and does not end with a slash" do
        handler = Marten::Server::Handlers::Routing.new

        context = HTTP::Server::Context.new(
          request: ::HTTP::Request.new(
            method: "GET",
            resource: "/unknown/42",
            headers: HTTP::Headers{"Host" => "example.com", "Accept-Language" => "FR,en;q=0.5"}
          ),
          response: ::HTTP::Server::Response.new(io: IO::Memory.new)
        )

        handler.call(context)
        context.marten.response.not_nil!.status.should eq(404)
        context.marten.response.not_nil!.content.should eq "The requested resource was not found."
      end

      it "raises if the requested route is the root" do
        handler = Marten::Server::Handlers::Routing.new

        context = HTTP::Server::Context.new(
          request: ::HTTP::Request.new(
            method: "GET",
            resource: "/",
            headers: HTTP::Headers{"Host" => "example.com", "Accept-Language" => "FR,en;q=0.5"}
          ),
          response: ::HTTP::Server::Response.new(io: IO::Memory.new)
        )

        handler.call(context)
        context.marten.response.not_nil!.status.should eq(404)
        context.marten.response.not_nil!.content.should eq "The requested resource was not found."
      end

      it "returns a permanent redirect if the requested route cannot be resolved and ends with a slash" do
        handler = Marten::Server::Handlers::Routing.new

        context = HTTP::Server::Context.new(
          request: ::HTTP::Request.new(
            method: "GET",
            resource: "/unknown/42/",
            headers: HTTP::Headers{"Host" => "example.com", "Accept-Language" => "FR,en;q=0.5"}
          ),
          response: ::HTTP::Server::Response.new(io: IO::Memory.new)
        )

        handler.call(context)

        context.marten.response.should be_a Marten::HTTP::Response::MovedPermanently
        context.marten.response.not_nil!.headers["Location"].should eq "http://example.com/unknown/42"
      end
    end
  end
end
