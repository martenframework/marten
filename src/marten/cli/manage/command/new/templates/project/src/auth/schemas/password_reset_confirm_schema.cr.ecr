module Auth
  class PasswordResetConfirmSchema < Marten::Schema
    field :password1, :string, max_size: 128, strip: false
    field :password2, :string, max_size: 128, strip: false

    validate :validate_password

    private def validate_password
      return unless password1? && password2?

      if password1 != password2
        errors.add("The two password fields do not match")
      end
    end
  end
end
