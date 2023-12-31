module Marten
  module CLI
    class Manage
      module Command
        class New < Base
          module Templates
            def self.app_files(context : Context)
              files = Array(Tuple(String, String)).new

              src_path = "src/#{context.name}/"

              files << {"#{src_path}app.cr", ECR.render("#{__DIR__}/templates/app/src/app/app.cr.ecr")}
              files << {"#{src_path}cli.cr", ECR.render("#{__DIR__}/templates/app/src/app/cli.cr.ecr")}
              files << {"#{src_path}routes.cr", ECR.render("#{__DIR__}/templates/app/src/app/routes.cr.ecr")}
              files << {"#{src_path}emails/.gitkeep", gitkeep}
              files << {"#{src_path}handlers/.gitkeep", gitkeep}
              files << {"#{src_path}migrations/.gitkeep", gitkeep}
              files << {"#{src_path}models/.gitkeep", gitkeep}
              files << {"#{src_path}schemas/.gitkeep", gitkeep}
              files << {"#{src_path}templates/.gitkeep", gitkeep}
              files << {"src/#{context.name}.cr", ECR.render("#{__DIR__}/templates/app/src/app.cr.ecr")}
              files << {".editorconfig", editorconfig}
              files << {".gitignore", gitignore}
              files << {"shard.yml", ECR.render("#{__DIR__}/templates/app/shard.yml.ecr")}

              files << {"spec/spec_helper.cr", ECR.render("#{__DIR__}/templates/app/spec/spec_helper.cr.ecr")}

              files
            end

            def self.project_files(context : Context)
              files = Array(Tuple(String, String)).new

              # Config files
              files << {"config/initializers/.gitkeep", gitkeep}
              files << {
                "config/settings/base.cr",
                ECR.render("#{__DIR__}/templates/project/config/settings/base.cr.ecr"),
              }
              files << {
                "config/settings/development.cr",
                ECR.render("#{__DIR__}/templates/project/config/settings/development.cr.ecr"),
              }
              files << {
                "config/settings/production.cr",
                ECR.render("#{__DIR__}/templates/project/config/settings/production.cr.ecr"),
              }
              files << {
                "config/settings/test.cr",
                ECR.render("#{__DIR__}/templates/project/config/settings/test.cr.ecr"),
              }
              files << {"config/routes.cr", ECR.render("#{__DIR__}/templates/project/config/routes.cr.ecr")}

              # Spec files
              files << {"spec/spec_helper.cr", ECR.render("#{__DIR__}/templates/project/spec/spec_helper.cr.ecr")}

              # Source files
              files << {"src/assets/css/app.css", ECR.render("#{__DIR__}/templates/project/src/assets/css/app.css.ecr")}
              files << {"src/cli.cr", ECR.render("#{__DIR__}/templates/project/src/cli.cr.ecr")}
              files << {"src/project.cr", ECR.render("#{__DIR__}/templates/project/src/project.cr.ecr")}
              files << {"src/server.cr", ECR.render("#{__DIR__}/templates/project/src/server.cr.ecr")}
              files << {"src/emails/.gitkeep", gitkeep}
              files << {"src/handlers/.gitkeep", gitkeep}
              files << {"src/migrations/.gitkeep", gitkeep}
              files << {"src/models/.gitkeep", gitkeep}
              files << {"src/schemas/.gitkeep", gitkeep}
              files << {
                "src/templates/base.html",
                ECR.render("#{__DIR__}/templates/project/src/templates/base.html.ecr"),
              }

              # Other files
              files << {".editorconfig", editorconfig}
              files << {".gitignore", gitignore}
              files << {"manage.cr", ECR.render("#{__DIR__}/templates/project/manage.cr.ecr")}
              files << {"shard.yml", ECR.render("#{__DIR__}/templates/project/shard.yml.ecr")}

              # Add authentification files if needed.
              if context.targets_auth?
                files << {
                  "spec/apps/auth/emails/password_reset_email_spec.cr",
                  ECR.render("#{__DIR__}/templates/project/spec/apps/auth/emails/password_reset_email_spec.cr.ecr"),
                }
                files << {
                  "spec/apps/auth/emails/spec_helper.cr",
                  ECR.render("#{__DIR__}/templates/project/spec/apps/auth/emails/spec_helper.cr.ecr"),
                }
                files << {
                  "spec/apps/auth/handlers/concerns/require_anonymous_user_spec.cr",
                  ECR.render(
                    "#{__DIR__}/templates/project/spec/apps/auth/handlers/concerns/require_anonymous_user_spec.cr.ecr"
                  ),
                }
                files << {
                  "spec/apps/auth/handlers/concerns/require_signed_in_user_spec.cr",
                  ECR.render(
                    "#{__DIR__}/templates/project/spec/apps/auth/handlers/concerns/require_signed_in_user_spec.cr.ecr"
                  ),
                }
                files << {
                  "spec/apps/auth/handlers/concerns/spec_helper.cr",
                  ECR.render("#{__DIR__}/templates/project/spec/apps/auth/handlers/concerns/spec_helper.cr.ecr"),
                }
                files << {
                  "spec/apps/auth/handlers/password_reset_confirm_handler_spec.cr",
                  ECR.render(
                    "#{__DIR__}/templates/project/spec/apps/auth/handlers/password_reset_confirm_handler_spec.cr.ecr"
                  ),
                }
                files << {
                  "spec/apps/auth/handlers/password_reset_initiate_handler_spec.cr",
                  ECR.render(
                    "#{__DIR__}/templates/project/spec/apps/auth/handlers/password_reset_initiate_handler_spec.cr.ecr"
                  ),
                }
                files << {
                  "spec/apps/auth/handlers/password_update_handler_spec.cr",
                  ECR.render(
                    "#{__DIR__}/templates/project/spec/apps/auth/handlers/password_update_handler_spec.cr.ecr"
                  ),
                }
                files << {
                  "spec/apps/auth/handlers/profile_handler_spec.cr",
                  ECR.render("#{__DIR__}/templates/project/spec/apps/auth/handlers/profile_handler_spec.cr.ecr"),
                }
                files << {
                  "spec/apps/auth/handlers/sign_in_handler_spec.cr",
                  ECR.render("#{__DIR__}/templates/project/spec/apps/auth/handlers/sign_in_handler_spec.cr.ecr"),
                }
                files << {
                  "spec/apps/auth/handlers/sign_out_handler_spec.cr",
                  ECR.render("#{__DIR__}/templates/project/spec/apps/auth/handlers/sign_out_handler_spec.cr.ecr"),
                }
                files << {
                  "spec/apps/auth/handlers/sign_up_handler_spec.cr",
                  ECR.render("#{__DIR__}/templates/project/spec/apps/auth/handlers/sign_up_handler_spec.cr.ecr"),
                }
                files << {
                  "spec/apps/auth/handlers/spec_helper.cr",
                  ECR.render("#{__DIR__}/templates/project/spec/apps/auth/handlers/spec_helper.cr.ecr"),
                }
                files << {
                  "spec/apps/auth/spec_helper.cr",
                  ECR.render("#{__DIR__}/templates/project/spec/apps/auth/spec_helper.cr.ecr"),
                }
                files << {
                  "spec/apps/auth/schemas/password_reset_confirm_schema_spec.cr",
                  ECR.render(
                    "#{__DIR__}/templates/project/spec/apps/auth/schemas/password_reset_confirm_schema_spec.cr.ecr"
                  ),
                }
                files << {
                  "spec/apps/auth/schemas/password_reset_initiate_schema_spec.cr",
                  ECR.render(
                    "#{__DIR__}/templates/project/spec/apps/auth/schemas/password_reset_initiate_schema_spec.cr.ecr"
                  ),
                }
                files << {
                  "spec/apps/auth/schemas/password_update_schema_spec.cr",
                  ECR.render(
                    "#{__DIR__}/templates/project/spec/apps/auth/schemas/password_update_schema_spec.cr.ecr"
                  ),
                }
                files << {
                  "spec/apps/auth/schemas/sign_in_schema_spec.cr",
                  ECR.render("#{__DIR__}/templates/project/spec/apps/auth/schemas/sign_in_schema_spec.cr.ecr"),
                }
                files << {
                  "spec/apps/auth/schemas/sign_up_schema_spec.cr",
                  ECR.render("#{__DIR__}/templates/project/spec/apps/auth/schemas/sign_up_schema_spec.cr.ecr"),
                }
                files << {
                  "spec/apps/auth/schemas/spec_helper.cr",
                  ECR.render("#{__DIR__}/templates/project/spec/apps/auth/schemas/spec_helper.cr.ecr"),
                }
                files << {
                  "spec/apps/spec_helper.cr",
                  ECR.render("#{__DIR__}/templates/project/spec/apps/spec_helper.cr.ecr"),
                }
                files << {
                  "src/apps/auth/emails/password_reset_email.cr",
                  ECR.render("#{__DIR__}/templates/project/src/apps/auth/emails/password_reset_email.cr.ecr"),
                }
                files << {
                  "src/apps/auth/handlers/concerns/require_anonymous_user.cr",
                  ECR.render(
                    "#{__DIR__}/templates/project/src/apps/auth/handlers/concerns/require_anonymous_user.cr.ecr"
                  ),
                }
                files << {
                  "src/apps/auth/handlers/concerns/require_signed_in_user.cr",
                  ECR.render(
                    "#{__DIR__}/templates/project/src/apps/auth/handlers/concerns/require_signed_in_user.cr.ecr"
                  ),
                }
                files << {
                  "src/apps/auth/handlers/password_reset_confirm_handler.cr",
                  ECR.render(
                    "#{__DIR__}/templates/project/src/apps/auth/handlers/password_reset_confirm_handler.cr.ecr"
                  ),
                }
                files << {
                  "src/apps/auth/handlers/password_reset_initiate_handler.cr",
                  ECR.render(
                    "#{__DIR__}/templates/project/src/apps/auth/handlers/password_reset_initiate_handler.cr.ecr"
                  ),
                }
                files << {
                  "src/apps/auth/handlers/password_update_handler.cr",
                  ECR.render(
                    "#{__DIR__}/templates/project/src/apps/auth/handlers/password_update_handler.cr.ecr"
                  ),
                }
                files << {
                  "src/apps/auth/handlers/profile_handler.cr",
                  ECR.render("#{__DIR__}/templates/project/src/apps/auth/handlers/profile_handler.cr.ecr"),
                }
                files << {
                  "src/apps/auth/handlers/sign_in_handler.cr",
                  ECR.render("#{__DIR__}/templates/project/src/apps/auth/handlers/sign_in_handler.cr.ecr"),
                }
                files << {
                  "src/apps/auth/handlers/sign_out_handler.cr",
                  ECR.render("#{__DIR__}/templates/project/src/apps/auth/handlers/sign_out_handler.cr.ecr"),
                }
                files << {
                  "src/apps/auth/handlers/sign_up_handler.cr",
                  ECR.render("#{__DIR__}/templates/project/src/apps/auth/handlers/sign_up_handler.cr.ecr"),
                }
                files << {
                  "src/apps/auth/migrations/0001_create_auth_user_table.cr",
                  ECR.render(
                    "#{__DIR__}/templates/project/src/apps/auth/migrations/0001_create_auth_user_table.cr.ecr"
                  ),
                }
                files << {
                  "src/apps/auth/models/user.cr",
                  ECR.render("#{__DIR__}/templates/project/src/apps/auth/models/user.cr.ecr"),
                }
                files << {
                  "src/apps/auth/schemas/password_reset_confirm_schema.cr",
                  ECR.render("#{__DIR__}/templates/project/src/apps/auth/schemas/password_reset_confirm_schema.cr.ecr"),
                }
                files << {
                  "src/apps/auth/schemas/password_reset_initiate_schema.cr",
                  ECR.render(
                    "#{__DIR__}/templates/project/src/apps/auth/schemas/password_reset_initiate_schema.cr.ecr"
                  ),
                }
                files << {
                  "src/apps/auth/schemas/password_update_schema.cr",
                  ECR.render(
                    "#{__DIR__}/templates/project/src/apps/auth/schemas/password_update_schema.cr.ecr"
                  ),
                }
                files << {
                  "src/apps/auth/schemas/sign_in_schema.cr",
                  ECR.render("#{__DIR__}/templates/project/src/apps/auth/schemas/sign_in_schema.cr.ecr"),
                }
                files << {
                  "src/apps/auth/schemas/sign_up_schema.cr",
                  ECR.render("#{__DIR__}/templates/project/src/apps/auth/schemas/sign_up_schema.cr.ecr"),
                }
                files << {
                  "src/apps/auth/templates/auth/emails/password_reset.html",
                  ECR.render(
                    "#{__DIR__}/templates/project/src/apps/auth/templates/auth/emails/password_reset.html.ecr"
                  ),
                }
                files << {
                  "src/apps/auth/templates/auth/password_reset_confirm.html",
                  ECR.render(
                    "#{__DIR__}/templates/project/src/apps/auth/templates/auth/password_reset_confirm.html.ecr"
                  ),
                }
                files << {
                  "src/apps/auth/templates/auth/password_reset_initiate.html",
                  ECR.render(
                    "#{__DIR__}/templates/project/src/apps/auth/templates/auth/password_reset_initiate.html.ecr"
                  ),
                }
                files << {
                  "src/apps/auth/templates/auth/password_update.html",
                  ECR.render(
                    "#{__DIR__}/templates/project/src/apps/auth/templates/auth/password_update.html.ecr"
                  ),
                }
                files << {
                  "src/apps/auth/templates/auth/profile.html",
                  ECR.render("#{__DIR__}/templates/project/src/apps/auth/templates/auth/profile.html.ecr"),
                }
                files << {
                  "src/apps/auth/templates/auth/sign_in.html",
                  ECR.render("#{__DIR__}/templates/project/src/apps/auth/templates/auth/sign_in.html.ecr"),
                }
                files << {
                  "src/apps/auth/templates/auth/sign_up.html",
                  ECR.render("#{__DIR__}/templates/project/src/apps/auth/templates/auth/sign_up.html.ecr"),
                }
                files << {"src/apps/auth/app.cr", ECR.render("#{__DIR__}/templates/project/src/apps/auth/app.cr.ecr")}
                files << {"src/apps/auth/cli.cr", ECR.render("#{__DIR__}/templates/project/src/apps/auth/cli.cr.ecr")}
                files << {
                  "src/apps/auth/routes.cr",
                  ECR.render("#{__DIR__}/templates/project/src/apps/auth/routes.cr.ecr"),
                }
              end

              files
            end

            private def self.editorconfig
              ECR.render("#{__DIR__}/templates/shared/.editorconfig.ecr")
            end

            private def self.gitignore
              ECR.render("#{__DIR__}/templates/shared/.gitignore.ecr")
            end

            private def self.gitkeep
              ECR.render("#{__DIR__}/templates/shared/.gitkeep.ecr")
            end
          end
        end
      end
    end
  end
end
