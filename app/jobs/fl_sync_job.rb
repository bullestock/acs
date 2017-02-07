require 'rest-client'
require 'json'

class FlSyncJob < ActiveJob::Base
  queue_as :default

  def self.perform(*args)
    puts "Synch: #{args}"
    secret = YAML.load_file('secret.yml')
    creds = secret['credentials']
    user = creds[0]
    password = creds[1]
    getall_url = secret['getall']
    url = "https://#{user}:#{password}@#{getall_url}"
    members = JSON.parse(RestClient.get(url, {accept: :json}))
    activity_ids = secret['activity_ids']
    active_members = Array.new
    members.each { |m|
      id = m["MemberId"]
      number = m["MemberNumber"]
      first_name = m["FirstName"]
      last_name = m["LastName"]
      activities = m["Activities"].to_i
      if !activity_ids.include?(activities)
        puts "Excluding member: #{first_name} #{last_name} where Activities is #{m['Activities']}"
      end

      u = User.find_by(member_id: id)
      if u
        puts "Member #{first_name} #{last_name} already exists"
      else
        puts "Member #{first_name} #{last_name} does not exist"
        u = User.new
        u.access_to = Array.new
        u.can_login = false
        u.can_provision = false
        u.can_deprovision = false
      end
      u.active = true
      u.member_id = id
      u.fl_id = number
      u.first_name = first_name
      u.last_name = last_name
      u.active = true
      # update...
      active_members << id
      u.save
    }
    # TODO: Deactivate remaining members
    puts "Found #{active_members.size} active members"
  end
end
