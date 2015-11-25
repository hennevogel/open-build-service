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

end
