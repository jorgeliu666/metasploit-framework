module SessionEventServlet
  def self.api_path
    '/api/v1/session-events'
  end

  def self.api_path_with_id
    "#{SessionEventServlet.api_path}/?:id?"
  end

  def self.registered(app)
    app.get SessionEventServlet.api_path_with_id, &get_session_event
    app.post SessionEventServlet.api_path, &report_session_event
  end

  #######
  private

  #######

  def self.get_session_event
    lambda {
      warden.authenticate!
      begin
        sanitized_params = sanitize_params(params, env['rack.request.query_hash'])
        data, pagination_total = get_db.session_events(sanitized_params)
        data = data.first if is_single_object?(data, sanitized_params)
        if pagination_total.nil?
          set_json_data_response(response: data)
        else
          set_json_data_response(response: data, merge_data: { 'pagination_total' => pagination_total })
        end
      rescue StandardError => e
        print_error_and_create_response(error: e, message: 'There was an error retrieving session events:', code: 500)
      end
    }
  end

  def self.report_session_event
    lambda {
      warden.authenticate!
      job = lambda { |opts|
        get_db.report_session_event(opts)
      }
      exec_report_job(request, &job)
    }
  end
end
