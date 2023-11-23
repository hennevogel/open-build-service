require 'xmlhash'
module Person
  class TokenController < ApplicationController
    before_action :set_package, :set_operation, only: :create
    before_action :set_token, only: :destroy
    after_action :verify_policy_scoped, only: :index
    after_action :verify_authorized, only: %i[create delete]

    # GET /person/<login>/token
    def index
      @list = policy_scope(Token)
    end

    # POST /person/<login>/token
    def create
      @token = Token.token_type(@operation).new(description: params[:description],
                                                        executor: User.session!,
                                                        package: @package,
                                                        scm_token: params[:scm_token])
      authorize @token

      if @thing.save
        render_ok
      else
        render_error(status: 400, errorcode: 'invalid_token', message: "Failed to create token: #{@token.errors.full_messages.to_sentence}.")
      end
    end

    # DELETE /person/<login>/token/<id>
    def destroy
      authorize @token

      @token.destroy

      render_ok
    end

    private

    def set_token
      @token = User.session!.tokens.find(params[:id])
    end

    def set_package
      return unless params[:project] || params[:package]

      @package = Package.get_by_project_and_name(params[:project], params[:package], follow_multibuild: true)
    end

    def set_operation
      @operation = params[:operation] || 'runservice'
    end

    def pundit_user
      displayed_user = User.find_by!(login: params[:login])
      return displayed_user if User.session!.is_admin?

      if displayed_user != User.session!
        raise Pundit::NotAuthorizedError, record: displayed_user
      else
        User.session!
      end
    end
  end
end
