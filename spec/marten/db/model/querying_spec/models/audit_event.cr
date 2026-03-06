module Marten::DB::Model::QueryingSpec
  class AuditEvent < Marten::Model
    enum EventKind
      LOGIN
      LOGOUT
    end

    enum PermissionKind
      LOGIN
      MANAGE
    end

    field :id, :big_int, primary_key: true, auto: true
    field :name, :string, max_size: 255
    field :kind, :enum, values: EventKind
  end
end
