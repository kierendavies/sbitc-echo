require 'sucker_punch'

class EndMeetingJob
  include SuckerPunch::Job

  def perform
    puts "running the job with data: #{data}"
  end
end
