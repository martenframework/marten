module Auth
  class PasswordResetEmail < Marten::Email
    to @user.email!
    subject "Reset your password"
    template_name "auth/emails/password_reset.html"

    def initialize(@user : User, @request : Marten::HTTP::Request)
    end

    def context
      {
        uid:                  Base64.urlsafe_encode(@user.pk.to_s),
        password_reset_token: MartenAuth.generate_password_reset_token(@user),
        request:              @request,
      }
    end
  end
end
