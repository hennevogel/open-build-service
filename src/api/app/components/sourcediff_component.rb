class SourcediffComponent < ApplicationComponent
  attr_accessor :bs_request, :action, :refresh, :diff_to_superseded

  delegate :diff_label, to: :helpers
  delegate :diff_data, to: :helpers

  def initialize(bs_request:, action:, diff_to_superseded: nil)
    super

    @bs_request = bs_request
    @action = action
    @diff_to_superseded = diff_to_superseded
  end

  def commentable
    BsRequestAction.find(@action.id)
  end

  def source_package
    Package.get_by_project_and_name(@action.source_project, @action.source_package, { follow_multibuild: true })
  rescue Package::UnknownObjectError, Project::Errors::UnknownObjectError
    # Ignore these exceptions on purpose
  end

  def target_package
    # For not accepted maintenance incident requests, the package is not there.
    return nil unless @action.target_package

    Package.get_by_project_and_name(@action.target_project, @action.target_package, { follow_multibuild: true })
  rescue Package::UnknownObjectError, Project::Errors::UnknownObjectError
    # Ignore these exceptions on purpose
  end
end
