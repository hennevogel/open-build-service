module SCMExceptionHandler
  extend ActiveSupport::Concern

  rescue_from Octokit::Error, Gitlab::Error::ResponseError, GiteaAPI::V1::Client::GiteaApiError do |exception|
    @workflow_run.update(response_body: exception.message, status: 'fail') if @workflow_run&.persisted?
    render_error(status: 422, errorcode: exception.class.name.underscore.tr('/', '_'), message: exception.message)
  end

  rescue_from Gitlab::Error::Parsing do |exception|
    @workflow_run.update(response_body: 'impossible to parse response body received from Gitlab', status: 'fail') if @workflow_run&.persisted?
    render_error(status: 422, errorcode: 'gitlab_error_parsing', message: exception.message)
  end

  rescue_from OpenSSL::SSL::SSLError do |exception|
    @workflow_run.update(response_body: exception.message, status: 'fail') if @workflow_run&.persisted?
    render_error(status: 422, errorcode: 'openssl_error', message: exception.message)
  end

  def initialize(event_payload, event_subscription_payload, scm_token, workflow_run = nil)
    @event_payload = event_payload.deep_symbolize_keys
    @event_subscription_payload = event_subscription_payload.deep_symbolize_keys
    @scm_token = scm_token
    @workflow_run = workflow_run
  end

  private

  def log_to_workflow_run(exception, scm)
    if @event_payload[:project] && @event_payload[:package]
      target_url = Rails.application.routes.url_helpers.package_show_url(@event_payload[:project],
                                                                         @event_payload[:package],
                                                                         host: Configuration.obs_url)
    end

    @workflow_run.save_scm_report_failure("Failed to report back to #{scm}: #{scm_exception_message}",
                                          {
                                            api_endpoint: @event_subscription_payload[:api_endpoint],
                                            commit_sha: @event_subscription_payload[:commit_sha],
                                            state: @state,
                                            status_options: {
                                              context: "OBS: #{@event_payload[:package]} - #{@event_payload[:repository]}/#{@event_payload[:arch]}",
                                              target_url: target_url
                                            },
                                            # GitHub / Gitea
                                            target_repository_full_name: @event_subscription_payload[:target_repository_full_name],
                                            # GitLab
                                            project_id: @event_subscription_payload[:project_id],
                                            path_with_namespace: @event_subscription_payload[:path_with_namespace]
                                          })
  end
end
