require "./spec_helper"

describe Auth::RequireAnonymousUser do
  describe "#process_dispatch" do
    it "generates the expected redirect response if the current user is authenticated" do
      user = create_user(email: "test@example.com", password: "insecure")

      request = Marten::HTTP::Request.new(method: "GET", resource: "/test/xyz")
      request.session = Marten::HTTP::Session::Store::Cookie.new("sessionkey")
      MartenAuth.sign_in(request, user)

      handler = Auth::RequireAnonymousUserSpec::TestHandler.new(request)
      response = handler.process_dispatch

      response.status.should eq 302
      response.headers["Location"].should eq Marten.routes.reverse("auth:profile")
    end

    it "does not redirect if the user is anonymous" do
      user = create_user(email: "test@example.com", password: "insecure")

      request = Marten::HTTP::Request.new(method: "GET", resource: "/test/xyz")

      handler = Auth::RequireAnonymousUserSpec::TestHandler.new(request)
      response = handler.process_dispatch

      response.status.should eq 200
      response.content.should eq "It works!"
    end
  end
end

module Auth::RequireAnonymousUserSpec
  class TestHandler < Marten::Handler
    include Auth::RequireAnonymousUser

    def get
      respond "It works!"
    end
  end
end
