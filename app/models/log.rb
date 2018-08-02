class Log < ActiveRecord::Base
  belongs_to :user

  before_create :set_timestamp
  def set_timestamp
    self.stamp = Time.now
  end

  scope :like, ->(args) { Log.joins("INNER JOIN machines m on m.id = logs.logger_id INNER JOIN users u on u.id = logs.user_id").where("message ilike '%#{args}%' OR m.name ilike '%#{args}%' OR u.name ilike '%#{args}%'")}
end
