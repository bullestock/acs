set :output, "/var/log/acs/schedule.log"

every 5.minutes do
  runner "FlSyncJob.perform"
end
