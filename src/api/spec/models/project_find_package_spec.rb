require 'rails_helper'

RSpec.describe Project, '.find_package' do
  # follow_multibuild is tested in spec/models/concerns/multibuild_package_spec.rb
  # use_source is tested in spec/models/user_has_local_permission_spec.rb

  let(:package) { create(:package) }
  let(:project) { package.project }

  subject { project.find_package(package.name) }

  context 'local package' do
    it { expect(subject).to eq(package) }
  end

  context 'project links' do
    # By default find_package will "follow" project links and triest to find the Package from the Project the link points to.
    # https://github.com/openSUSE/open-build-service/wiki/Links#project-links
    let(:link_target) { create(:project) }
    let(:project) { create(:project, link_to: link_target) }

    subject { project.find_package(package.name) }

    context 'and local project provides package and linked project not' do
      let(:package) { create(:package, project: project) }

      it 'returns the package from the link' do
        expect(subject.project).equal?(link_target)
      end
    end

    context 'and linked project provides package and local project not' do
      let(:package) { create(:package, project: link_target) }

      it 'returns the package from the link' do
        expect(subject.project).equal?(link_target)
      end
    end

    context 'and linked project provides package and local project also provides package' do
      let(:package_in_linked_project) { create(:package, project: link_target) }
      let(:package) { create(:package, name: package_in_linked_project.name, project: project) }

      it 'returns the package from the link' do
        expect(subject.project).equal?(link_target)
      end
    end

    context 'and linked project does not provide package and local project also not' do
      let(:package) { build(:package, name: 'i_do_not_exist') }

      it 'returns nil' do
        expect(subject).to be_nil
      end
    end
  end
end
