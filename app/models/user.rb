class User < ActiveRecord::Base
  has_and_belongs_to_many :machines
  has_secure_password
end
