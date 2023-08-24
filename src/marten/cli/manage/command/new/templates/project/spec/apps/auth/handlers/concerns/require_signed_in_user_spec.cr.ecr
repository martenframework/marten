require "./spec_helper"

describe Auth::RequireSignedInUser do
  describe "#process_dispatch" do
    it "generates the expected redirect response if the current user is not signed in" do
      user = create_user(email: "test@example.com", password: "insecure")

      request = Marten::HTTP::Request.new(method: "GET", resource: "/test/xyz")

      handler = Auth::RequireSignedInUserSpec::TestHandler.new(request)
      response = handler.process_dispatch

      response.status.should eq 302
      response.headers["Location"].should eq Marten.routes.reverse("auth:sign_in")
    end

    it "does not redirect if the user is signed in" do
      user = create_user(email: "test@example.com", password: "insecure")

      request = Marten::HTTP::Request.new(method: "GET", resource: "/test/xyz")
      request.session = Marten::HTTP::Session::Store::Cookie.new("sessionkey")
      MartenAuth.sign_in(request, user)

      handler = Auth::RequireSignedInUserSpec::TestHandler.new(request)
      response = handler.process_dispatch

      response.status.should eq 200
      response.content.should eq "It works!"
    end
  end
end

module Auth::RequireSignedInUserSpec
  class TestHandler < Marten::Handler
    include Auth::RequireSignedInUser

    def get
      respond "It works!"
    end
  end
end
