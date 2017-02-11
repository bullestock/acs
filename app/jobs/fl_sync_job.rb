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
      id = m["MemberId"].to_i
      number = m["MemberNumber"]
      first_name = m["FirstName"]
      last_name = m["LastName"]
      name = "#{first_name} #{last_name}"
      activities = m["Activities"].to_i
      if !activity_ids.include?(activities)
        puts "Excluding member: #{name} where Activities is #{m['Activities']}"
        next
      end

      u = User.find_by(member_id: id)
      if u
        puts "Member #{name} (ID #{id}) already exists"
      else
        puts "Member #{name} does not exist"
        u = User.new
        u.access_to = Array.new
        u.can_login = false
        u.can_provision = false
        u.can_deprovision = false
      end
      u.active = true
      u.member_id = id
      u.fl_id = number
      u.name = name
      u.active = true
      active_members << id
      u.save
    }
    # Deactivate remaining members
    puts "Found #{active_members.size} active members"
    puts active_members.inspect
    User.all.each { |u|
      if !active_members.include? u.member_id
        puts "Member #{u.name} (ID #{u.member_id}) is no longer active"
        u.active = false
        u.save
      end
    }
  end
end
