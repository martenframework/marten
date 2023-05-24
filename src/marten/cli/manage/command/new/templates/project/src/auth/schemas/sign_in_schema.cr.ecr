module Auth
  class SignInSchema < Marten::Schema
    property user : User?

    field :email, :email
    field :password, :string, max_size: 128, strip: false

    validate :validate_credentials

    private def validate_credentials
      return unless email? && password?
      self.user = MartenAuth.authenticate(email!, password!)
      return if !self.user.nil?

      errors.add("Please enter a correct email address and password. Note that both fields may be case-sensitive.")
    end
  end
end
