require 'sucker_punch'

class EndMeetingJob
  include SuckerPunch::Job

  def perform data
    puts "running the job with data: #{data}"
  end
end
