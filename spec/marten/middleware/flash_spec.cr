require "./spec_helper"

describe Marten::Middleware::Flash do
  describe "#call" do
    it "associates a flash store to the request and populates it from the session" do
      session_store = Marten::HTTP::Session::Store::Cookie.new("sessionkey")
      session_store["_flash"] = {
        "discard" => [] of String,
        "flashes" => {"foo" => "bar", "alert" => "bad"},
      }.to_json

      raw_request = ::HTTP::Request.new(
        method: "GET",
        resource: "/test/xyz",
        headers: HTTP::Headers{"Host" => "example.com"},
      )
      request = Marten::HTTP::Request.new(raw_request)
      request.session = session_store

      middleware = Marten::Middleware::Flash.new
      middleware.call(
        request,
        ->{ Marten::HTTP::Response.new("It works!", content_type: "text/plain", status: 200) }
      )

      request.flash.should be_a Marten::HTTP::FlashStore
      request.flash["foo"].should eq "bar"
      request.flash["alert"].should eq "bad"
    end

    it "persists new flash messages as expected to the session when processing the response" do
      session_store = Marten::HTTP::Session::Store::Cookie.new("sessionkey")
      session_store["_flash"] = {
        "discard" => [] of String,
        "flashes" => {"foo" => "bar", "alert" => "bad"},
      }.to_json

      raw_request = ::HTTP::Request.new(
        method: "GET",
        resource: "/test/xyz",
        headers: HTTP::Headers{"Host" => "example.com"},
      )
      request = Marten::HTTP::Request.new(raw_request)
      request.session = session_store

      middleware = Marten::Middleware::Flash.new
      middleware.call(
        request,
        ->{
          request.flash["newkey"] = "newval"
          Marten::HTTP::Response.new("It works!", content_type: "text/plain", status: 200)
        }
      )

      request.session["_flash"].should eq({"discard" => [] of String, "flashes" => {"newkey" => "newval"}}.to_json)
    end
  end
end
