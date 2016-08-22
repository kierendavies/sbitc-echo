require 'google/apis/calendar_v3'
require 'googleauth'
require 'googleauth/stores/file_token_store'
require 'fileutils'

module GoogleCalendar
  OOB_URI = 'urn:ietf:wg:oauth:2.0:oob'
  APPLICATION_NAME = 'SBITC Echo'
  CLIENT_SECRETS_PATH = 'config/google_client_secret.json'
  CREDENTIALS_PATH = File.join(Dir.home, '.credentials', 'calendar-ruby-sbitc-echo.yaml')
  SCOPE = Google::Apis::CalendarV3::AUTH_CALENDAR_READONLY

  def self.authorize
    FileUtils.mkdir_p(File.dirname(CREDENTIALS_PATH))

    client_id = Google::Auth::ClientId.from_file(CLIENT_SECRETS_PATH)
    token_store = Google::Auth::Stores::FileTokenStore.new(file: CREDENTIALS_PATH)
    authorizer = Google::Auth::UserAuthorizer.new(
      client_id, SCOPE, token_store)
    user_id = 'default'
    credentials = authorizer.get_credentials(user_id)
    if credentials.nil?
      url = authorizer.get_authorization_url(
        base_url: OOB_URI)
      puts 'Open the following URL in the browser and enter the resulting code after authorization'
      puts url
      code = gets
      credentials = authorizer.get_and_store_credentials_from_code(
        user_id: user_id, code: code, base_url: OOB_URI)
    end
    credentials
  end

  def self.service
    @@service ||= begin
      service = Google::Apis::CalendarV3::CalendarService.new
      service.client_options.application_name = APPLICATION_NAME
      service.authorization = authorize
      service
    end
  end

  def self.current_event
    begin
      event = service.list_events(
        'primary',
        max_results: 1,
        single_events: true,
        order_by: 'startTime',
        time_min: Time.now.iso8601
      ).items.first
    rescue Google::Apis::ClientError
      return nil
    end

    if event.start.date_time.nil?
      return nil
    end

    if (event.start.date_time - DateTime.now) * 24 < 1
      {
        name: event.summary,
        start_time: event.start.date_time,
        end_time: event.end.date_time,
        attendees: if event.attendees.nil?
          [event.organizer.display_name]
        else
          event.attendees.map(&:display_name)
        end
      }
    else
      nil
    end
  end
end
