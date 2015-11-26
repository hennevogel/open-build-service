module Webui::HasFlags

  def create_flag
    authorize main_object, :update?

    @flag = main_object.flags.new( status: params[:status], flag: params[:flag] )
    @flag.architecture = Architecture.find_by_name(params[:architecture])
    @flag.repo = params[:repository] unless params[:repository].blank?

    respond_to do |format|
      if @flag.save
        # FIXME: This should happen in Flag or even better in Project/Package
        main_object.store
        format.js
      else
        format.json { render json: @flag.errors, status: :unprocessable_entity }
      end
    end
  end

  def toggle_flag
    authorize main_object, :update?

    @flag = Flag.find(params[:flag])
    @flag.status = @flag.status == 'enable' ? 'disable' : 'enable'

    respond_to do |format|
      if @flag.save
        # FIXME: This should happen in Flag or even better in Project/Package
        main_object.store
        format.js
      else
        format.json { render json: @flag.errors, status: :unprocessable_entity }
      end
    end
  end

  def remove_flag
    authorize main_object, :update?

    @flag = Flag.find(params[:flag])
    main_object.flags.destroy(@flag)

    respond_to do |format|
      # FIXME: This should happen in Flag or even better in Project/Package
      main_object.store
      format.js
    end
  end

  def get_build_flags
    build_flags = Hash.new

    build_flags['all'] = Array.new
    flag = main_object.flags.with_repositories(nil).with_architectures(nil).first
    if flag
      build_flags['all'] << flag
    else
      build_flags['all'] << main_object.flags.new( flag: 'build', status: Flag.default_state('build') )
    end

    main_object.architectures.each do |architecture|
      flag = main_object.flags.with_repositories(nil).with_architectures(architecture.id).first
      if flag
        build_flags['all'] << flag
      else
        build_flags['all'] << main_object.flags.new( flag: 'build', architecture: architecture, status: build_flags['all'][0].status )
      end
    end

    main_object.repositories.each do |repository|
      build_flags[repository.name] = Array.new
      flag = main_object.flags.with_repositories(repository.name).with_architectures(nil).first
      if flag
        build_flags[repository.name] << flag
      else
        build_flags[repository.name] << main_object.flags.new( flag: 'build', repo: repository.name, status: build_flags['all'][0].status )
      end
      main_object.architectures.each do |architecture|
        flag = main_object.flags.with_repositories(repository.name).with_architectures(architecture.id).first
        if flag
          build_flags[repository.name] << flag
        else
          build_flags[repository.name] << main_object.flags.new( flag: 'build',
                                                       repo: repository.name,
                                                       architecture: architecture,
                                                       status: build_flags[repository.name][0].status )
        end
      end
    end

    return build_flags
  end


  def get_build_flags_moi(flag_type)
    the_flags = {}
    [nil].concat(main_object.repositories.map{|repo| repo.name}).each do |repository|
      the_flags[repository] = []
      [nil].concat(main_object.architectures).each do |architecture|
        architecture_id = architecture ? architecture.id : nil
        flag = main_object.flags.with_repositories(repository).with_architectures(architecture_id).first
        unless flag
          status = (repository.nil? && architecture.nil?) ? Flag.default_state('build') : the_flags[nil].first.status
          flag = main_object.flags.new( flag: flag_type, repo: repository, architecture: architecture, status: status )
        end
        the_flags[repository] << flag
      end
    end
    the_flags['all'] = the_flags.delete(nil)
    the_flags
  end

  def existing_flag(options = {})
    main_object.flags.where(
      repo: options[:repo], architecture: options[:architecture]
    ).first
  end

  def temporary_flag(attributes = {})
    attributes.update(flag: "build") # make it configurable
    attributes[:status] = Flag.default_state("build") unless attributes[:status]

    main_object.flags.new(attributes)
  end

  def fetch_flag(options = {})
    existing_flag(options) || temporary_flag(options)
  end

  def get_build_flags_alt
    flags = { "all" => [] }
    flags["all"] << fetch_flag

    status = flags["all"].first.status

    main_object.architectures.each do |arch|
      flags["all"] << fetch_flag(architecture: arch, status: status)
    end

    main_object.repositories.each do |repo|
      flags[repo.name] = []
      flags[repo.name] << fetch_flag(repo: repo.name, status: status)

      main_object.architectures.each do |arch|
        flags[repo.name] << fetch_flag(repo: repo.name, architecture: arch, status: status)
      end
    end

    flags
  end

end
