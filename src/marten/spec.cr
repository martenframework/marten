require "spec"

module Marten
  module Spec
    def self.flush_databases
      Marten::DB::Connection.registry.values.each do |connection|
        Marten::DB::Management::SchemaEditor.run_for(connection) do |schema_editor|
          schema_editor.flush_model_tables
        end
      end
    end

    def self.setup_databases
      Marten::DB::Connection.registry.values.each do |connection|
        Marten::DB::Management::SchemaEditor.run_for(connection) do |schema_editor|
          schema_editor.sync_models
        end
      end
    end
  end
end

Spec.before_suite &->Marten.setup
Spec.before_suite &->Marten::Spec.setup_databases
Spec.after_each &->Marten::Spec.flush_databases
