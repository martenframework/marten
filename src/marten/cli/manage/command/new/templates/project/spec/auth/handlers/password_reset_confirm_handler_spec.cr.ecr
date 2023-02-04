require "./spec_helper"

describe Auth::PasswordResetConfirmHandler do
  describe "#get" do
    it "redirects to the sign in page if no user can be found" do
      url = Marten.routes.reverse("auth:password_reset_confirm", uid: Base64.urlsafe_encode("-1"), token: "token")
      response = Marten::Spec.client.get(url)

      response.status.should eq 302
      response.headers["Location"].should eq Marten.routes.reverse("auth:sign_in")
    end

    it "redirects to the profile page if the user is already authenticated" do
      user = create_user(email: "test@example.com", password: "insecure")

      url = Marten.routes.reverse("auth:password_reset_confirm", uid: Base64.urlsafe_encode(user.pk.to_s), token: "tkn")

      Marten::Spec.client.sign_in(user)
      response = Marten::Spec.client.get(url)

      response.status.should eq 302
      response.headers["Location"].should eq Marten.routes.reverse("auth:profile")
    end

    it "redirects to the sign in page if the specified token is invalid" do
      user = create_user(email: "test@example.com", password: "insecure")

      url = Marten.routes.reverse("auth:password_reset_confirm", uid: Base64.urlsafe_encode(user.pk.to_s), token: "bad")

      response = Marten::Spec.client.get(url)

      response.status.should eq 302
      response.headers["Location"].should eq Marten.routes.reverse("auth:sign_in")
    end

    it "redirects to the same page and hides the token in the session if the user ID and token are valid" do
      user = create_user(email: "test@example.com", password: "insecure")
      uid = Base64.urlsafe_encode(user.pk.to_s)
      password_reset_token = MartenAuth.generate_password_reset_token(user)

      url = Marten.routes.reverse("auth:password_reset_confirm", uid: uid, token: password_reset_token)
      response = Marten::Spec.client.get(url)

      response.status.should eq 302
      response.headers["Location"].should eq(
        Marten.routes.reverse("auth:password_reset_confirm", uid: uid, token: "set-password")
      )

      Marten::Spec.client.session["_password_reset_token"].should eq password_reset_token
    end

    it "shows the password reset form if the token was previously set in the session for a GET request" do
      user = create_user(email: "test@example.com", password: "insecure")
      uid = Base64.urlsafe_encode(user.pk.to_s)

      Marten::Spec.client.session["_password_reset_token"] = MartenAuth.generate_password_reset_token(user)

      url = Marten.routes.reverse("auth:password_reset_confirm", uid: uid, token: "set-password")
      response = Marten::Spec.client.get(url)

      response.status.should eq 200
      response.content.includes?("Reset password").should be_true
    end
  end

  describe "#post" do
    it "resets the password and redirects to the sign in page if the token is in the session for a POST request" do
      user = create_user(email: "test@example.com", password: "insecure")
      uid = Base64.urlsafe_encode(user.pk.to_s)

      Marten::Spec.client.session["_password_reset_token"] = MartenAuth.generate_password_reset_token(user)

      url = Marten.routes.reverse("auth:password_reset_confirm", uid: uid, token: "set-password")
      response = Marten::Spec.client.post(url, data: {"password1" => "newpassword", "password2" => "newpassword"})

      response.status.should eq 302
      response.headers["Location"].should eq Marten.routes.reverse("auth:sign_in")

      user.reload.check_password("newpassword").should be_true
    end
  end
end
