module Auth
  class SignInSchema < Marten::Schema
    property user : User?

    field :email, :email
    field :password, :string, max_size: 128, strip: false

    validate :validate_credentials

    private def validate_credentials
      return unless validated_data["email"]? && validated_data["password"]?
      self.user = MartenAuth.authenticate(
        validated_data["email"].as(String),
        validated_data["password"].as(String)
      )
      return if !self.user.nil?

      errors.add("Please enter a correct email address and password. Note that both fields may be case-sensitive.")
    end
  end
end
