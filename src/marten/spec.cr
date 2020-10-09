require "spec"

module Marten
  module Spec
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
