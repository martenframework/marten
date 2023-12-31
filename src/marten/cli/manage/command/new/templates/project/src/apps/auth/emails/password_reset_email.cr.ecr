module Auth
  class PasswordResetEmail < Marten::Email
    to @user.email!
    subject "Reset your password"
    template_name "auth/emails/password_reset.html"
    before_render :prepare_context

    def initialize(@user : User, @request : Marten::HTTP::Request)
    end

    private def prepare_context
      context[:uid] = Base64.urlsafe_encode(@user.pk.to_s)
      context[:password_reset_token] = MartenAuth.generate_password_reset_token(@user)
      context[:request] = @request
    end
  end
end
