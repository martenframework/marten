module Auth
  class SignUpSchema < Marten::Schema
    field :email, :email
    field :password1, :string, max_size: 128, strip: false
    field :password2, :string, max_size: 128, strip: false

    validate :validate_email
    validate :validate_password

    private def validate_email
      return unless email?

      if User.filter(email__iexact: email).exists?
        errors.add(:email, "This email address is already taken")
      end
    end

    private def validate_password
      return unless password1? && password2?

      if password1 != password2
        errors.add("The two password fields do not match")
      end
    end
  end
end
