require "./concerns/*"

module Auth
  class PasswordUpdateHandler < Marten::Handlers::Schema
    include RequireSignedInUser

    schema PasswordUpdateSchema
    template_name "auth/password_update.html"
    success_route_name "auth:profile"

    before_schema_validation :prepare_schema
    after_successful_schema_validation :process_password_reset_request

    private def prepare_schema
      schema.user = request.user!
    end

    private def process_password_reset_request
      flash[:notice] = "You've successfully updated your password!"

      request.user!.set_password(self.schema.new_password!)
      request.user!.save!

      MartenAuth.update_session_auth_hash(request, request.user!)
    end
  end
end
