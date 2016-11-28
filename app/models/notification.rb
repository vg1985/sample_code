class Notification < ActiveRecord::Base
  belongs_to :user
  default_scope { order('created_at DESC') }

  validates :user, presence: true

  def self.unread
    where(read_at: nil)
  end

  def self.mark_bulk_as_read
    update_all(read_at: DateTime.now)
  end

  def mark_as_read
    self.read_at = DateTime.now
    self.save
  end
end
