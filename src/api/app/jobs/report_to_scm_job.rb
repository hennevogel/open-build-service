class ReportToSCMJob < CreateJob
  ALLOWED_EVENTS = ['Event::BuildFail', 'Event::BuildSuccess', 'Event::RequestStatechange'].freeze

  rescue_from Octokit::Error, Gitlab::Error::ResponseError, GiteaAPI::V1::Client::GiteaApiError do |exception|
    @workflow_run.update(response_body: exception.message, status: 'fail') if @workflow_run&.persisted?
  end

  rescue_from Gitlab::Error::Parsing do |exception|
    @workflow_run.update(response_body: 'impossible to parse response body received from Gitlab', status: 'fail') if @workflow_run&.persisted?
  end

  queue_as :scm

  def perform(event_id)
    return false unless perform_job?(event_id)

    matched_event_subscription.each do |event_subscription|
      SCMStatusReporter.new(@event.payload,
                            event_subscription.payload,
                            event_subscription.token.scm_token,
                            event_subscription.workflow_run,
                            event_subscription.eventtype).call
    end
    true
  end

  private

  def perform_job?(event_id)
    @event = Event::Base.find(event_id)
    return false unless @event.undone_jobs.positive?

    @event_type = @event.eventtype
    return false unless ALLOWED_EVENTS.include?(@event_type)

    @event_package_or_request = if @event_type == 'Event::RequestStatechange'
                                  BsRequest.find_by_number(@event.payload['number'])
                                else
                                  Package.find_by_project_and_name(@event.payload['project'], Package.striping_multibuild_suffix(@event.payload['package']))
                                end

    return false if @event_package_or_request.blank?

    true
  end

  def matched_event_subscription
    EventSubscriptionsFinder.new(event_package_or_request: @event_package_or_request)
                            .for_scm_channel_with_token(event_type: @event_type)
  end
end
