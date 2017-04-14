class Log < ActiveRecord::Base
  belongs_to :user

  before_create :set_timestamp
  def set_timestamp
    self.stamp = Time.now
  end
end
