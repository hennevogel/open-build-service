RSpec.describe CleanupNotificationsJob do
  include ActiveJob::TestHelper

  describe '#perform' do
    it 'only deletes old notifications' do
      create(:notification_bs_request, :stale)
      create(:notification_bs_request)

      expect { described_class.new.perform }.to change(Notification, :count).by(-1)
    end
  end
end
