require "spec"

require "./cli"
require "./spec/**"

module Marten
  # Provides helpers and tools allowing to ease the process of writing specs for Marten projects.
  module Spec
    @@client : Client?

    # Clears the testing client.
    #
    # This method is automatically called after each spec.
    def self.clear_client : Nil
      @@client = nil
    end

    # Clears collected emails.
    #
    # This method is only relevant if the current emailing backend is an instance of
    # `Marten::Emailing::Backend::Development` that was initialized with `collect_emails: true`.
    #
    # This method is automatically called after each spec.
    def self.clear_collected_emails : Nil
      Marten::Emailing::Backend::Development.delivered_emails.clear
    end

    # Returns an array of all the emails that were delivered as part of the spec.
    #
    # Note that this method will return an empty array if the emailing backend is not set to an instance of the
    # development backend that was initialized with `collect_emails: true`. For example:
    #
    # ```
    # Marten.configure :test do |config|
    #   # [...]
    #   config.emailing.backend = Marten::Emailing::Backend::Development.new(collect_emails: true, print_emails: false)
    # end
    # ```
    def self.delivered_emails : Array(Emailing::Email)
      Marten::Emailing::Backend::Development.delivered_emails
    end

    # Returns an instance of the testing client.
    #
    # The testing client allows to issue requests to the server and obtain the associated responses. Note that this
    # method is memoized on a per-spec basis.
    def self.client : Client
      @@client ||= Client.new
    end

    # Flushes all the databases.
    #
    # This method is automatically called after each spec.
    def self.flush_databases
      Marten::DB::Connection.registry.values.each do |conn|
        Marten::DB::Management::SchemaEditor.run_for(conn) do |schema_editor|
          schema_editor.flush_model_tables
        end
      end
    end

    # Setup all the databases by ensuring that model tables are up-to-date.
    #
    # This method is automatically called before each spec suite.
    def self.setup_databases
      Marten::DB::Connection.registry.values.each do |conn|
        if !conn.test_database?
          raise "No test database name is explicitly defined for database connection '#{conn.alias}', cancelling..."
        end

        Marten::DB::Management::SchemaEditor.run_for(conn) do |schema_editor|
          schema_editor.sync_models
        end
      end
    end
  end
end

Spec.before_suite &->Marten.setup
Spec.before_suite &->Marten::Spec.setup_databases
Spec.after_each &->Marten::Spec.flush_databases
Spec.after_each &->Marten::Spec.clear_collected_emails
Spec.after_each &->Marten::Spec.clear_client
