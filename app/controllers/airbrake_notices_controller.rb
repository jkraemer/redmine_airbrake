class AirbrakeNoticesController < ActionController::Base

  def create
    User.current = User.anonymous

    if notice = parse_request
      if notice.api_key_valid?
        if issue = notice.save
          case api_version
          when 2
            key = RedmineAirbrake.rails5? ? :plain : :text
            render status: 200,
                   key => "Received notification.\n<id>#{issue.id}</id>"

          when 3
            render status: 201,
                   json: { issue_id: issue.id, issue_url: issue_url(issue) }
          end
        else
          render status: 400, json: { error: 'Could not process request.' }
        end
      else
        render status: 403, json: { error: 'Access denied. Redmine API is disabled or key is invalid.' }
      end
    end
  end

  private

  def api_version
    @api_version ||= if params[:version] =~ /\Av(\d)\z/
      $1.to_i
    end
  end

  def parse_request
    if logger.debug?
      logger.debug "Airbrake request:\n#{request.raw_post}"
    end
    case api_version
    when 2
      RedmineAirbrake::Notice::V2.new request.raw_post
    when 3
      RedmineAirbrake::Notice::V3.new request.raw_post, find_v3_config
    else
      render text: 'unsupported API version',
             status: 404 and return false
    end
  end

  def find_v3_config
    unless config = params[:key].presence
      if config = request.headers["Authorization"].presence
        config.sub!(/\ABearer /, '')
        config = CGI.unescape config
      end
    end
    JSON.parse config if config
  end
end
