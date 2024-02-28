RSpec.describe Package, '.copy_from' do
  let(:user) { create(:confirmed_user) }
  let(:project) { create(:project) }
  let(:package) { build(:package, project: project, title: Random.alphanumeric(5)) }
  let(:source_project) { create(:project) }
  let(:source_package) do
    source_package_with_flags = create(:package, project: source_project, title: Random.alphanumeric(5))
    create(:debuginfo_flag, package: source_package_with_flags)
    create(:publish_flag, package: source_package_with_flags)
    source_package_with_flags
  end

  before do
    login user
    allow(Backend::Api::Sources::Package).to receive_messages(meta: source_package.to_axml, copy: true)
  end

  subject { package.copy_from(source_project_name: source_project.name, source_package_name: source_package.name) }

  it 'copies create a new package' do
    expect { subject }.to change { project.packages.count }.from(0).to(1)
  end

  it 'copies the source_package attributes' do
    expect { subject }.to change(package, :title).from(package.title).to(source_package.title)
  end

  it 'copies the source_package flags' do
    expect { subject }.to change { package.flags.count }.from(0).to(2)
  end

  context 'package already exists' do
    let!(:package) do
      package_with_flag = create(:package, project: project)
      create(:build_flag, package: package_with_flag)
      package_with_flag
    end

    it 'does not create a new package' do
      expect { subject }.not_to change { project.packages.count }
    end

    it 'copies the source_package attributes' do
      expect { subject }.to change(package, :title).from(package.title).to(source_package.title)
    end

    it 'copies the source_package flags' do
      expect { subject }.to change { package.flags.count }.from(1).to(2)
    end
  end

  context 'special packages' do
    let(:source_package) { create(:package, name: '_pattern') }

    it 'errors' do
      expect(subject).to be_falsey
      expect(package.errors).to contain_exactly('Copy from _pattern special packages not allowed')
    end
  end

  context 'backend error on copy' do
    before do
      allow(Backend::Api::Sources::Package).to receive(:copy).and_raise(Backend::Error, 'something went wrong')
    end

    it 'does not create a new package' do
      expect { subject }.to raise_error(Backend::Error)
      expect(project.packages.count).to eq(0)
    end
  end
end
