module Marten::DB::Model::PersistenceSpec
  class Record < Marten::Model
    field :id, :big_int, primary_key: true, auto: true
    field :name, :string, max_size: 255, default: "default name"

    field :before_create_track, :string, max_size: 255, default: "unset"
    field :after_create_track, :string, max_size: 255, default: "unset"

    field :before_update_track, :string, max_size: 255, default: "unset"
    field :after_update_track, :string, max_size: 255, default: "unset"

    field :before_save_track, :string, max_size: 255, default: "unset"
    field :after_save_track, :string, max_size: 255, default: "unset"

    field :after_create_commit_track, :string, max_size: 255, default: "unset"
    field :after_update_commit_track, :string, max_size: 255, default: "unset"
    field :after_save_commit_track, :string, max_size: 255, default: "unset"
    field :after_delete_commit_track, :string, max_size: 255, default: "unset"

    field :after_create_rollback_track, :string, max_size: 255, default: "unset"
    field :after_update_rollback_track, :string, max_size: 255, default: "unset"
    field :after_save_rollback_track, :string, max_size: 255, default: "unset"
    field :after_delete_rollback_track, :string, max_size: 255, default: "unset"

    before_create :set_before_create_track
    after_create :set_after_create_track

    before_update :set_before_update_track
    after_update :set_after_update_track

    before_save :set_before_save_track
    after_save :set_after_save_track

    before_delete :set_before_delete_track
    after_delete :set_after_delete_track

    after_create_commit :set_after_create_commit_track
    after_update_commit :set_after_update_commit_track
    after_save_commit :set_after_save_commit_track
    after_delete_commit :set_after_delete_commit_track

    after_create_rollback :set_after_create_rollback_track
    after_update_rollback :set_after_update_rollback_track
    after_save_rollback :set_after_save_rollback_track
    after_delete_rollback :set_after_delete_rollback_track

    property before_delete_track : String? = nil
    property after_delete_track : String? = nil

    private def set_before_create_track
      self.before_create_track = "before_create"
    end

    private def set_after_create_track
      self.after_create_track = "after_create"
    end

    private def set_before_update_track
      self.before_update_track = "before_update"
    end

    private def set_after_update_track
      self.after_update_track = "after_update"
    end

    private def set_before_save_track
      self.before_save_track = "before_save"
    end

    private def set_after_save_track
      self.after_save_track = "after_save"
    end

    private def set_before_delete_track
      self.before_delete_track = "before_delete"
    end

    private def set_after_delete_track
      self.after_delete_track = "after_delete"
    end

    private def set_after_create_commit_track
      self.after_create_commit_track = "after_create_commit"
    end

    private def set_after_update_commit_track
      self.after_update_commit_track = "after_update_commit"
    end

    private def set_after_save_commit_track
      self.after_save_commit_track = "after_save_commit"
    end

    private def set_after_delete_commit_track
      self.after_delete_commit_track = "after_delete_commit"
    end

    private def set_after_create_rollback_track
      self.after_create_rollback_track = "after_create_rollback"
    end

    private def set_after_update_rollback_track
      self.after_update_rollback_track = "after_update_rollback"
    end

    private def set_after_save_rollback_track
      self.after_save_rollback_track = "after_save_rollback"
    end

    private def set_after_delete_rollback_track
      self.after_delete_rollback_track = "after_delete_rollback"
    end
  end
end
