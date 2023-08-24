require "./spec_helper"

describe Auth::ProfileHandler do
  describe "#get" do
    it "redirects to the sign in page if the user is not authenticated" do
      url = Marten.routes.reverse("auth:profile")

      response = Marten::Spec.client.get(url)

      response.status.should eq 302
      response.headers["Location"].should eq Marten.routes.reverse("auth:sign_in")
    end

    it "shows the profile page of the authenticated user" do
      user = create_user(email: "test@example.com", password: "insecure")

      url = Marten.routes.reverse("auth:profile")

      Marten::Spec.client.sign_in(user)
      response = Marten::Spec.client.get(url)

      response.status.should eq 200
      response.content.includes?("Profile").should be_true
    end
  end
end
