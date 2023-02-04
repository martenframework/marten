module Auth
  class PasswordResetConfirmSchema < Marten::Schema
    field :password1, :string, max_size: 128, strip: false
    field :password2, :string, max_size: 128, strip: false

    validate :validate_password

    def validate_password
      return unless validated_data["password1"]? && validated_data["password2"]?

      if validated_data["password1"] != validated_data["password2"]
        errors.add("The two password fields do not match")
      end
    end
  end
end
