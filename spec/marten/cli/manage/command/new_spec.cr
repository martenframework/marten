require "./spec_helper"

describe Marten::CLI::Manage::Command::New do
  describe "#run" do
    around_each do |t|
      FileUtils.rm_rf(Marten::CLI::Manage::Command::NewSpec::PATH)
      FileUtils.mkdir(Marten::CLI::Manage::Command::NewSpec::PATH)
      FileUtils.cd(Marten::CLI::Manage::Command::NewSpec::PATH) { t.run }
      FileUtils.rm_rf(Marten::CLI::Manage::Command::NewSpec::PATH)
    end

    it "uses the iterative mode when no structure type is specified" do
      stdin = IO::Memory.new("project\ndummy_project\nsqlite3\nyes")
      stdout = IO::Memory.new
      stderr = IO::Memory.new

      command = Marten::CLI::Manage::Command::New.new(
        options: [] of String,
        stdin: stdin,
        stdout: stdout,
        stderr: stderr
      )

      command.handle

      output = stdout.rewind.gets_to_end

      output.includes?("Structure type ('project or 'app'):").should be_true
      output.includes?("Project name:").should be_true
      output.includes?("Include authentication [yes/no]?").should be_true
      output.includes?("Database:").should be_true

      Marten::CLI::Manage::Command::NewSpec::PROJECT_WITH_AUTH_FILES.each do |path|
        File.exists?(File.join(".", "dummy_project", path)).should be_true, "File #{path} does not exist"
      end
    end

    it "properly takes into account the with auth question answer" do
      stdin = IO::Memory.new("project\ndummy_project\nsqlite3\nno")
      stdout = IO::Memory.new
      stderr = IO::Memory.new

      command = Marten::CLI::Manage::Command::New.new(
        options: [] of String,
        stdin: stdin,
        stdout: stdout,
        stderr: stderr
      )

      command.handle

      output = stdout.rewind.gets_to_end

      output.includes?("Structure type ('project or 'app'):").should be_true
      output.includes?("Project name:").should be_true
      output.includes?("Include authentication [yes/no]?").should be_true
      output.includes?("Database:").should be_true

      Marten::CLI::Manage::Command::NewSpec::PROJECT_FILES.each do |path|
        File.exists?(File.join(".", "dummy_project", path)).should be_true, "File #{path} does not exist"
      end
    end

    it "prints an error if an invalid project type is specified" do
      stdout = IO::Memory.new
      stderr = IO::Memory.new

      command = Marten::CLI::Manage::Command::New.new(
        options: ["unknown"],
        stdout: stdout,
        stderr: stderr
      )

      command.handle

      stderr.rewind.gets_to_end.includes?("Unrecognized structure type, you must use 'project or 'app'").should be_true
    end

    it "uses the interactive mode to create a project when no name is specified" do
      stdin = IO::Memory.new("dummy_project\nsqlite3\nyes")
      stdout = IO::Memory.new
      stderr = IO::Memory.new

      command = Marten::CLI::Manage::Command::New.new(
        options: ["project"],
        stdin: stdin,
        stdout: stdout,
        stderr: stderr
      )

      command.handle

      output = stdout.rewind.gets_to_end

      output.includes?("Structure type ('project or 'app'):").should be_false
      output.includes?("Project name:").should be_true
      output.includes?("Include authentication [yes/no]?").should be_true
      output.includes?("Database:").should be_true

      Marten::CLI::Manage::Command::NewSpec::PROJECT_WITH_AUTH_FILES.each do |path|
        File.exists?(File.join(".", "dummy_project", path)).should be_true, "File #{path} does not exist"
      end
    end

    it "uses the interactive mode to create an app when no name is specified" do
      stdin = IO::Memory.new("dummy_app")
      stdout = IO::Memory.new
      stderr = IO::Memory.new

      command = Marten::CLI::Manage::Command::New.new(
        options: ["app"],
        stdin: stdin,
        stdout: stdout,
        stderr: stderr
      )

      command.handle

      output = stdout.rewind.gets_to_end

      output.includes?("Structure type ('project or 'app'):").should be_false
      output.includes?("App name:").should be_true
      output.includes?("Include authentication [yes/no]?").should be_false
      output.includes?("Database:").should be_false

      Marten::CLI::Manage::Command::NewSpec::APP_FILES.each do |path|
        File.exists?(File.join(".", "dummy_app", path)).should be_true, "File #{path} does not exist"
      end
    end

    it "prints an error when trying to use --with-auth for an app structure" do
      stdout = IO::Memory.new
      stderr = IO::Memory.new

      command = Marten::CLI::Manage::Command::New.new(
        options: ["app", "dummy_project", "--with-auth"],
        stdout: stdout,
        stderr: stderr
      )

      command.handle

      stderr.rewind.gets_to_end.includes?("--with-auth can only be used when creating new projects").should be_true
    end

    it "creates a new project structure" do
      stdout = IO::Memory.new

      command = Marten::CLI::Manage::Command::New.new(
        options: ["project", "dummy_project"],
        stdout: stdout
      )

      command.handle

      Marten::CLI::Manage::Command::NewSpec::PROJECT_FILES.each do |path|
        File.exists?(File.join(".", "dummy_project", path)).should be_true, "File #{path} does not exist"
      end
    end

    it "creates a new project structure with authentication" do
      stdout = IO::Memory.new

      command = Marten::CLI::Manage::Command::New.new(
        options: ["project", "dummy_project", "--with-auth"],
        stdout: stdout
      )

      command.handle

      Marten::CLI::Manage::Command::NewSpec::PROJECT_WITH_AUTH_FILES.each do |path|
        File.exists?(File.join(".", "dummy_project", path)).should be_true, "File #{path} does not exist"
      end
    end

    it "creates a new app structure" do
      stdout = IO::Memory.new

      command = Marten::CLI::Manage::Command::New.new(
        options: ["app", "dummy_app"],
        stdout: stdout
      )

      command.handle

      Marten::CLI::Manage::Command::NewSpec::APP_FILES.each do |path|
        File.exists?(File.join(".", "dummy_app", path)).should be_true, "File #{path} does not exist"
      end
    end

    it "creates a new project structure in a custom directory using the --dir option" do
      stdout = IO::Memory.new

      command = Marten::CLI::Manage::Command::New.new(
        options: ["project", "dummy_project", "--dir=sub/custom"],
        stdout: stdout
      )

      command.handle

      Marten::CLI::Manage::Command::NewSpec::PROJECT_FILES.each do |path|
        File.exists?(File.join(".", "sub", "custom", path)).should be_true, "File #{path} does not exist"
      end
    end

    it "creates a new project structure in a custom directory using the -d option" do
      stdout = IO::Memory.new

      command = Marten::CLI::Manage::Command::New.new(
        options: ["project", "dummy_project", "-d", "sub/custom"],
        stdout: stdout
      )

      command.handle

      Marten::CLI::Manage::Command::NewSpec::PROJECT_FILES.each do |path|
        File.exists?(File.join(".", "sub", "custom", path)).should be_true, "File #{path} does not exist"
      end
    end

    it "creates a new app structure in a custom directory the --dir option" do
      stdout = IO::Memory.new

      command = Marten::CLI::Manage::Command::New.new(
        options: ["app", "dummy_app", "--dir=sub/custom"],
        stdout: stdout
      )

      command.handle

      Marten::CLI::Manage::Command::NewSpec::APP_FILES.each do |path|
        File.exists?(File.join(".", "sub", "custom", path)).should be_true, "File #{path} does not exist"
      end
    end

    it "creates a new app structure in a custom directory the -d option" do
      stdout = IO::Memory.new

      command = Marten::CLI::Manage::Command::New.new(
        options: ["app", "dummy_app", "-d", "sub/custom"],
        stdout: stdout
      )

      command.handle

      Marten::CLI::Manage::Command::NewSpec::APP_FILES.each do |path|
        File.exists?(File.join(".", "sub", "custom", path)).should be_true, "File #{path} does not exist"
      end
    end

    it "prompts the user for the structure type again if the provided value is invalid" do
      stdin = IO::Memory.new("bad\nproject\ndummy_project\nsqlite3\nyes")
      stdout = IO::Memory.new
      stderr = IO::Memory.new

      command = Marten::CLI::Manage::Command::New.new(
        options: [] of String,
        stdin: stdin,
        stdout: stdout,
        stderr: stderr
      )

      command.handle

      output = stdout.rewind.gets_to_end

      output.includes?("Structure type ('project or 'app'):").should be_true
      output.includes?("Project name:").should be_true
      output.includes?("Include authentication [yes/no]?").should be_true
      output.includes?("Database:").should be_true

      Marten::CLI::Manage::Command::NewSpec::PROJECT_WITH_AUTH_FILES.each do |path|
        File.exists?(File.join(".", "dummy_project", path)).should be_true, "File #{path} does not exist"
      end
    end

    it "prints an error when trying to use --database with an unsupported engine" do
      stdout = IO::Memory.new
      stderr = IO::Memory.new

      command = Marten::CLI::Manage::Command::New.new(
        options: ["app", "dummy_project", "--database", "oracle"],
        stdout: stdout,
        stderr: stderr
      )

      command.handle

      err_output = stderr.rewind.gets_to_end

      err_output.includes?("Invalid database. Supported databases are: mysql, postgresql, sqlite3.").should be_true
    end

    it "configures sqlite3 as database when no --database is provided" do
      stdout = IO::Memory.new
      stderr = IO::Memory.new

      command = Marten::CLI::Manage::Command::New.new(
        options: ["project", "dummy_project"],
        stdout: stdout,
        stderr: stderr
      )

      command.handle

      File.read("./dummy_project/shard.yml").should contain "github: crystal-lang/crystal-sqlite3"
      File.read("./dummy_project/config/settings/base.cr").should contain "db.backend = :sqlite"
    end

    it "configures sqlite3 if no database value is provided in interactive mode" do
      stdin = IO::Memory.new("bad\nproject\ndummy_project\n\nyes")
      stdout = IO::Memory.new
      stderr = IO::Memory.new

      command = Marten::CLI::Manage::Command::New.new(
        options: [] of String,
        stdin: stdin,
        stdout: stdout,
        stderr: stderr
      )

      command.handle

      File.read("./dummy_project/shard.yml").should contain "github: crystal-lang/crystal-sqlite3"
      File.read("./dummy_project/config/settings/base.cr").should contain "db.backend = :sqlite"
    end

    it "configures sqlite3 as database when --database=sqlite3 is provided" do
      stdout = IO::Memory.new
      stderr = IO::Memory.new

      command = Marten::CLI::Manage::Command::New.new(
        options: ["project", "dummy_project", "--database", "sqlite3"],
        stdout: stdout,
        stderr: stderr
      )

      command.handle

      File.read("./dummy_project/shard.yml").should contain "github: crystal-lang/crystal-sqlite3"
      File.read("./dummy_project/config/settings/base.cr").should contain "db.backend = :sqlite"
    end

    it "configures mysql as database when --database=mysql is provided" do
      stdout = IO::Memory.new
      stderr = IO::Memory.new

      command = Marten::CLI::Manage::Command::New.new(
        options: ["project", "dummy_project", "--database", "mysql"],
        stdout: stdout,
        stderr: stderr
      )

      command.handle

      File.read("./dummy_project/shard.yml").should contain "github: crystal-lang/crystal-mysql"
      File.read("./dummy_project/config/settings/base.cr").should contain "db.backend = :mysql"
    end

    it "configures postgresql as database when --database=postgresql is provided" do
      stdout = IO::Memory.new
      stderr = IO::Memory.new

      command = Marten::CLI::Manage::Command::New.new(
        options: ["project", "dummy_project", "--database", "postgresql"],
        stdout: stdout,
        stderr: stderr
      )

      command.handle

      File.read("./dummy_project/shard.yml").should contain "github: will/crystal-pg"
      File.read("./dummy_project/config/settings/base.cr").should contain "db.backend = :postgresql"
    end
  end
end

module Marten::CLI::Manage::Command::NewSpec
  PATH = "spec/marten/cli/manage/command/new_spec"

  APP_FILES = [
    "spec/spec_helper.cr",
    "src/dummy_app.cr",
    "src/dummy_app/app.cr",
    "src/dummy_app/cli.cr",
    "src/dummy_app/emails/.gitkeep",
    "src/dummy_app/handlers/.gitkeep",
    "src/dummy_app/migrations/.gitkeep",
    "src/dummy_app/models/.gitkeep",
    "src/dummy_app/routes.cr",
    "src/dummy_app/schemas/.gitkeep",
    "src/dummy_app/templates/.gitkeep",
    ".editorconfig",
    ".gitignore",
    "shard.yml",
  ]

  PROJECT_FILES = [
    "config/initializers/.gitkeep",
    "config/settings/base.cr",
    "config/settings/development.cr",
    "config/settings/production.cr",
    "config/settings/test.cr",
    "config/routes.cr",
    "spec/spec_helper.cr",
    "src/cli.cr",
    "src/project.cr",
    "src/server.cr",
    "src/assets/css/app.css",
    "src/emails/.gitkeep",
    "src/handlers/.gitkeep",
    "src/migrations/.gitkeep",
    "src/models/.gitkeep",
    "src/schemas/.gitkeep",
    "src/templates/base.html",
    ".editorconfig",
    ".gitignore",
    "manage.cr",
    "shard.yml",
  ]

  PROJECT_WITH_AUTH_FILES = [
    "config/initializers/.gitkeep",
    "config/settings/base.cr",
    "config/settings/development.cr",
    "config/settings/production.cr",
    "config/settings/test.cr",
    "config/routes.cr",
    "spec/apps/auth/emails/password_reset_email_spec.cr",
    "spec/apps/auth/emails/spec_helper.cr",
    "spec/apps/auth/handlers/concerns/require_anonymous_user_spec.cr",
    "spec/apps/auth/handlers/concerns/require_signed_in_user_spec.cr",
    "spec/apps/auth/handlers/concerns/spec_helper.cr",
    "spec/apps/auth/handlers/password_reset_confirm_handler_spec.cr",
    "spec/apps/auth/handlers/password_reset_initiate_handler_spec.cr",
    "spec/apps/auth/handlers/profile_handler_spec.cr",
    "spec/apps/auth/handlers/sign_in_handler_spec.cr",
    "spec/apps/auth/handlers/sign_out_handler_spec.cr",
    "spec/apps/auth/handlers/sign_up_handler_spec.cr",
    "spec/apps/auth/handlers/spec_helper.cr",
    "spec/apps/auth/spec_helper.cr",
    "spec/apps/auth/schemas/password_reset_confirm_schema_spec.cr",
    "spec/apps/auth/schemas/password_reset_initiate_schema_spec.cr",
    "spec/apps/auth/schemas/sign_in_schema_spec.cr",
    "spec/apps/auth/schemas/sign_up_schema_spec.cr",
    "spec/apps/auth/schemas/spec_helper.cr",
    "spec/spec_helper.cr",
    "src/apps/auth/emails/password_reset_email.cr",
    "src/apps/auth/handlers/concerns/require_anonymous_user.cr",
    "src/apps/auth/handlers/concerns/require_signed_in_user.cr",
    "src/apps/auth/handlers/password_reset_confirm_handler.cr",
    "src/apps/auth/handlers/password_reset_initiate_handler.cr",
    "src/apps/auth/handlers/profile_handler.cr",
    "src/apps/auth/handlers/sign_in_handler.cr",
    "src/apps/auth/handlers/sign_out_handler.cr",
    "src/apps/auth/handlers/sign_up_handler.cr",
    "src/apps/auth/migrations/0001_create_auth_user_table.cr",
    "src/apps/auth/models/user.cr",
    "src/apps/auth/schemas/password_reset_confirm_schema.cr",
    "src/apps/auth/schemas/password_reset_initiate_schema.cr",
    "src/apps/auth/schemas/sign_in_schema.cr",
    "src/apps/auth/schemas/sign_up_schema.cr",
    "src/apps/auth/templates/auth/emails/password_reset.html",
    "src/apps/auth/templates/auth/password_reset_confirm.html",
    "src/apps/auth/templates/auth/password_reset_initiate.html",
    "src/apps/auth/templates/auth/profile.html",
    "src/apps/auth/templates/auth/sign_in.html",
    "src/apps/auth/templates/auth/sign_up.html",
    "src/apps/auth/app.cr",
    "src/apps/auth/cli.cr",
    "src/apps/auth/routes.cr",
    "src/cli.cr",
    "src/project.cr",
    "src/server.cr",
    "src/assets/css/app.css",
    "src/emails/.gitkeep",
    "src/handlers/.gitkeep",
    "src/migrations/.gitkeep",
    "src/models/.gitkeep",
    "src/schemas/.gitkeep",
    "src/templates/base.html",
    ".editorconfig",
    ".gitignore",
    "manage.cr",
    "shard.yml",
  ]
end
