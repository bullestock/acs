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
    updated_members = Array.new
    added_members = Array.new
    nologin_members = Array.new
    excluded_members = Array.new
    members.each { |m|
      id = m["MemberId"].to_i
      number = m["MemberNumber"]
      first_name = m["FirstName"]
      last_name = m["LastName"]
      login = m["MemberField6"]
      name = "#{first_name} #{last_name}"
      activities = m["Activities"].to_i
      if !activity_ids.include?(activities)
        excluded_members << name
        next
      end

      u = User.find_by(member_id: id)
      if u
        #puts "Member #{name} (ID #{id}) already exists"
        updated_members << name
      else
        #puts "Member #{name} does not exist"
        added_members << name
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
      u.login = login
      if !login || login.empty?
        nologin_members << name
      end
      active_members << id
      u.save
    }
    # Deactivate remaining members
    User.all.each { |u|
      if !active_members.include? u.member_id
        #puts "Member #{u.name} (ID #{u.member_id}) is no longer active"
        u.active = false
        u.save
      end
    }
    # Output statistics
    puts "Updated #{updated_members.size}, added #{added_members.size}, excluded #{excluded_members.size}."
    puts "Total #{active_members.size} active members."
    puts "#{nologin_members.size} members have no login."
  end
end
