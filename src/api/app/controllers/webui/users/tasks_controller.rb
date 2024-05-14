module Webui
  module Users
    class TasksController < WebuiController
      # TODO: Remove this when we'll refactor kerberos_auth
      before_action :kerberos_auth
      before_action -> { authorize(%i[users task]) }

      after_action :verify_authorized

      def index
        if Flipper.enabled?(:tasks_page_redesign, User.session)

          @requests = nil
          render :index_beta
        end
      end
    end
  end
end
