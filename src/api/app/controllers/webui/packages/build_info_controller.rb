module Webui
  module Packages
    class BuildInfoController < Packages::MainController
      before_action :set_project
      before_action :set_package
      before_action :set_repository
      before_action :set_architecture

      def index
        @buildinfo = Rails.cache.fetch('buildinfo-dario', expires_in: 30.minutes) do
          Xmlhash.parse(Backend::Api::BuildResults::Status.build_info(project_name: @project,
                                                                      package_name: @package_name,
                                                                      repository_name: @repository,
                                                                      architecture_name: @architecture,
                                                                      debug: true))
        end
      end
    end
  end
end
