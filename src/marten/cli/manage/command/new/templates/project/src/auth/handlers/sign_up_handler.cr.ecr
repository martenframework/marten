module Auth
  class SignUpHandler < Marten::Handlers::RecordCreate
    include RequireAnonymousUser

    model User
    schema SignUpSchema
    template_name "auth/sign_up.html"
    success_route_name "auth:profile"

    def process_valid_schema
      self.record = model.new(email: schema.validated_data["email"])
      self.record.as(User).set_password(schema.validated_data["password1"].as(String))
      self.record.try(&.save!)

      user = MartenAuth.authenticate(
        schema.validated_data["email"].as(String),
        schema.validated_data["password1"].as(String)
      )
      MartenAuth.sign_in(request, user.not_nil!)

      redirect(success_url)
    end
  end
end
