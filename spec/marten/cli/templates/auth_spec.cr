require "./spec_helper"

describe Marten::CLI::Templates::Auth do
  describe "#app_files" do
    it "returns the expected files for the given app context" do
      app_context = Marten::CLI::Templates::App::Context.new("my_auth")
      files = Marten::CLI::Templates::Auth.app_files(app_context)

      files.map(&.first).should eq(
        [
          "app.cr",
          "cli.cr",
          "routes.cr",
          "emails/password_reset_email.cr",
          "handlers/concerns/require_anonymous_user.cr",
          "handlers/concerns/require_signed_in_user.cr",
          "handlers/password_reset_confirm_handler.cr",
          "handlers/password_reset_initiate_handler.cr",
          "handlers/password_update_handler.cr",
          "handlers/profile_handler.cr",
          "handlers/sign_in_handler.cr",
          "handlers/sign_out_handler.cr",
          "handlers/sign_up_handler.cr",
          "migrations/0001_create_my_auth_user_table.cr",
          "models/user.cr",
          "schemas/password_reset_confirm_schema.cr",
          "schemas/password_reset_initiate_schema.cr",
          "schemas/password_update_schema.cr",
          "schemas/sign_in_schema.cr",
          "schemas/sign_up_schema.cr",
          "templates/my_auth/emails/password_reset.html",
          "templates/my_auth/password_reset_confirm.html",
          "templates/my_auth/password_reset_initiate.html",
          "templates/my_auth/password_update.html",
          "templates/my_auth/profile.html",
          "templates/my_auth/sign_in.html",
          "templates/my_auth/sign_up.html",
        ]
      )
    end
  end

  describe "#spec_files" do
    it "returns the expected files for the given app context" do
      app_context = Marten::CLI::Templates::App::Context.new("my_auth")
      files = Marten::CLI::Templates::Auth.spec_files(app_context)

      files.map(&.first).should eq(
        [
          "apps/my_auth/emails/password_reset_email_spec.cr",
          "apps/my_auth/emails/spec_helper.cr",
          "apps/my_auth/handlers/concerns/require_anonymous_user_spec.cr",
          "apps/my_auth/handlers/concerns/require_signed_in_user_spec.cr",
          "apps/my_auth/handlers/concerns/spec_helper.cr",
          "apps/my_auth/handlers/password_reset_confirm_handler_spec.cr",
          "apps/my_auth/handlers/password_reset_initiate_handler_spec.cr",
          "apps/my_auth/handlers/password_update_handler_spec.cr",
          "apps/my_auth/handlers/profile_handler_spec.cr",
          "apps/my_auth/handlers/sign_in_handler_spec.cr",
          "apps/my_auth/handlers/sign_out_handler_spec.cr",
          "apps/my_auth/handlers/sign_up_handler_spec.cr",
          "apps/my_auth/handlers/spec_helper.cr",
          "apps/my_auth/spec_helper.cr",
          "apps/my_auth/schemas/password_reset_confirm_schema_spec.cr",
          "apps/my_auth/schemas/password_reset_initiate_schema_spec.cr",
          "apps/my_auth/schemas/password_update_schema_spec.cr",
          "apps/my_auth/schemas/sign_in_schema_spec.cr",
          "apps/my_auth/schemas/sign_up_schema_spec.cr",
          "apps/my_auth/schemas/spec_helper.cr",
        ]
      )
    end
  end
end
