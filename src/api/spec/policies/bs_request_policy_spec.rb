require 'rails_helper'

class CommandContext
  attr_reader :user, :params

  def initialize(user, params)
    @user = user
    @params = params
  end
end

# rubocop:disable RSpec/RepeatedExample
# This cop is currently not recognizing the permissions block as separate examples

RSpec.describe BsRequestPolicy do
  let(:options) { Hash.new }
  let(:bs_request) { BsRequest.new }
  let(:admin_user) { CommandContext.new(create(:admin_user), options) }
  let(:anonymous_user) { CommandContext.new(create(:user_nobody), options) }
  let(:user) { CommandContext.new(create(:confirmed_user), options) }

  subject { BsRequestPolicy }

  permissions :create? do
    it { is_expected.to permit(user, bs_request) }
    it { is_expected.not_to permit(anonymous_user, bs_request) }
  end

  permissions :destroy? do
    it { is_expected.to permit(admin_user, bs_request) }
    it { is_expected.not_to permit(user, bs_request) }
    it { is_expected.not_to permit(anonymous_user, bs_request) }
  end

  permissions :update? do
    it { is_expected.to permit(admin_user, bs_request) }
    it { is_expected.not_to permit(user, bs_request) }
    it { is_expected.not_to permit(anonymous_user, bs_request) }
  end

  permissions :changestate? do
    it { is_expected.not_to permit(anonymous_user, bs_request) }

    context 'new -> deleted' do
      let(:bs_request) { BsRequest.new(state: 'new') }
      let(:options) { { new_state: 'deleted' } }

      it { is_expected.to permit(admin_user, bs_request) }
      it { is_expected.not_to permit(user, bs_request) }
    end

    context 'new -> declined' do
      let(:bs_request) { BsRequest.new(state: 'new') }
      let(:options) { { new_state: 'declined' } }

      it { is_expected.to permit(user, bs_request) }
    end

    context 'new -> accepted' do
      let(:bs_request) { BsRequest.new(state: 'new') }
      let(:options) { { new_state: 'accepted' } }

      it { is_expected.to permit(user, bs_request) }
    end

    context 'new -> review' do
      let(:bs_request) { BsRequest.new(state: 'new') }
      let(:options) { { new_state: 'review' } }

      it { is_expected.to permit(user, bs_request) }
    end

    context 'new -> revoked' do
      let(:bs_request) { BsRequest.new(state: 'new') }
      let(:options) { { new_state: 'revoked' } }

      it { is_expected.to permit(user, bs_request) }
    end

    context 'new -> superseded' do
      let(:bs_request) { BsRequest.new(state: 'new') }
      let(:options) { { new_state: 'superseded' } }

      it { is_expected.to permit(user, bs_request) }
    end
    # TODO:
    # deleted -> new
    # deleted -> declined
    # deleted -> accepted
    # deleted -> review
    # deleted -> revoked
    # deleted -> superseded
    # declined -> new
    # declined -> deleted
    # declined -> accepted
    # declined -> review
    # declined -> revoked
    # declined -> superseded
    # accepted -> new
    # accepted -> deleted
    # accepted -> declined
    # accepted -> review
    # accepted -> revoked
    # accepted -> superseded
    # review -> new
    # review -> deleted
    # review -> declined
    # review -> accepted
    # review -> revoked
    # review -> superseded
    # revoked -> new
    # revoked -> deleted
    # revoked -> declined
    # revoked -> accepted
    # revoked -> review
    # revoked -> superseded
    # superseded -> new
    # superseded -> deleted
    # superseded -> declined
    # superseded -> accepted
    # superseded -> review
    # superseded -> revoked
  end
end

# rubocop:enable RSpec/RepeatedExample
