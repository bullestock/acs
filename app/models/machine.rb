class Machine < ActiveRecord::Base
  has_and_belongs_to_many :users
  validates :name, uniqueness: true

  before_save :default_values
  def default_values
    self.api_token = SecureRandom.hex(32)
  end
end
