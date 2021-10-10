require "./spec_helper"

describe Marten::Middleware do
  describe "#chain" do
    it "calls the current middleware and then the next middleware in the chain if one is configured" do
      middleware1 = Marten::MiddlewareSpec::Test1.new
      middleware2 = Marten::MiddlewareSpec::Test2.new
      middleware1.next = middleware2

      response = middleware1.chain(
        Marten::HTTP::Request.new(
          ::HTTP::Request.new(
            method: "GET",
            resource: "",
            headers: HTTP::Headers{"Host" => "example.com", "Accept-Language" => "FR,en;q=0.5"}
          )
        ),
        ->{ Marten::HTTP::Response.new("It works!", content_type: "text/plain", status: 200) }
      )

      response.cookies["c1"].should eq "val1"
      response.cookies["c2"].should eq "val2"
    end

    it "calls the current middleware and then returns the result of the response proc if there is no next middleware" do
      middleware = Marten::MiddlewareSpec::Test1.new

      response = middleware.chain(
        Marten::HTTP::Request.new(
          ::HTTP::Request.new(
            method: "GET",
            resource: "",
            headers: HTTP::Headers{"Host" => "example.com", "Accept-Language" => "FR,en;q=0.5"}
          )
        ),
        ->{ Marten::HTTP::Response.new("It works!", content_type: "text/plain", status: 200) }
      )

      response.cookies["c1"].should eq "val1"
      response.cookies["c2"]?.should be_nil
    end
  end
end

module Marten::MiddlewareSpec
  class Test1 < Marten::Middleware
    def call(request : Marten::HTTP::Request, get_response : Proc(Marten::HTTP::Response)) : Marten::HTTP::Response
      response = get_response.call
      response.cookies.set("c1", "val1")
      response
    end
  end

  class Test2 < Marten::Middleware
    def call(request : Marten::HTTP::Request, get_response : Proc(Marten::HTTP::Response)) : Marten::HTTP::Response
      response = get_response.call
      response.cookies.set("c2", "val2")
      response
    end
  end
end
