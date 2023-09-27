module PackageFinderMethods
  extend ActiveSupport::Concern

  class_methods do
    def check_access?(package)
      return false if package.nil?
      return false unless package.instance_of?(Package)

      Project.check_access?(package.project)
    end

    def check_cache(project, package, opts)
      @key = { 'get_by_project_and_name' => 1, :package => package, :opts => opts }

      @key[:user] = User.session.cache_key_with_version if User.session

      # the cache is only valid if the user, prj and pkg didn't change
      @key[:project] = if project.is_a?(Project)
                         project.id
                       else
                         project
                       end
      pid, old_pkg_time, old_prj_time = Rails.cache.read(@key)
      if pid
        pkg = Package.where(id: pid).includes(:project).first
        return pkg if pkg && pkg.updated_at == old_pkg_time && pkg.project.updated_at == old_prj_time

        Rails.cache.delete(@key) # outdated anyway
      end
      nil
    end

    def internal_get_project(project)
      return project if project.is_a?(Project)
      return if Project.is_remote_project?(project)

      Project.get_by_name(project)
    end

    # returns an object of package or raises an exception
    # should be always used when a project is required
    # in case you don't access sources or build logs in any way use
    # use_source: false to skip check for sourceaccess permissions
    # function returns a nil object in case the package is on remote instance
    def get_by_project_and_name(project, package, opts = {})
      opts = { use_source: true, follow_project_links: true,
              follow_multibuild: false, check_update_project: false }.merge(opts)

      package = striping_multibuild_suffix(package) if opts[:follow_multibuild]

      pkg = check_cache(project, package, opts)
      return pkg if pkg

      prj = internal_get_project(project)
      return unless prj # remote prjs

      return nil if prj.scmsync.present?

      if pkg.nil? && opts[:follow_project_links]
        pkg = prj.find_package(package, opts[:check_update_project])
      elsif pkg.nil?
        pkg = prj.update_instance.packages.find_by_name(package) if opts[:check_update_project]
        pkg = prj.packages.find_by_name(package) if pkg.nil?
      end

      # FIXME: Why is this returning nil (the package is not found) if _ANY_ of the
      # linking projects is remote? What if one of the linking projects is local
      # and the other one remote?
      if pkg.nil? && opts[:follow_project_links]
        # in case we link to a remote project we need to assume that the
        # backend may be able to find it even when we don't have the package local
        prj.expand_all_projects.each do |p|
          return nil unless p.is_a?(Project)
        end
      end

      raise UnknownObjectError, "Package not found: #{project}/#{package}" unless pkg
      raise ReadAccessError, "#{project}/#{package}" unless check_access?(pkg)

      pkg.check_source_access! if opts[:use_source]

      Rails.cache.write(@key, [pkg.id, pkg.updated_at, prj.updated_at])
      pkg
    end

    def get_by_project_and_name!(project, package, opts = {})
      pkg = get_by_project_and_name(project, package, opts)
      raise UnknownObjectError, "Package not found: #{project}/#{package}" unless pkg

      pkg
    end

    # to check existens of a project (local or remote)
    def exists_by_project_and_name(project, package, opts = {})
      opts = { follow_project_links: true, allow_remote_packages: false, follow_multibuild: false }.merge(opts)
      package = striping_multibuild_suffix(package) if opts[:follow_multibuild]
      begin
        prj = Project.get_by_name(project)
      rescue Project::UnknownObjectError
        return false
      end
      return opts[:allow_remote_packages] && exists_on_backend?(package, project) unless prj.is_a?(Project)

      prj.exists_package?(package, opts)
    end

    def exists_on_backend?(package, project)
      !Backend::Connection.get(Package.source_path(project, package)).nil?
    rescue Backend::Error
      false
    end

    def find_by_project_and_name(project, package)
      PackagesFinder.new.by_package_and_project(package, project).first
    end

    def find_by_attribute_type(attrib_type, package = nil)
      PackagesFinder.new.find_by_attribute_type(attrib_type, package)
    end

    def find_by_attribute_type_and_value(attrib_type, value, package = nil)
      PackagesFinder.new.find_by_attribute_type_and_value(attrib_type, value, package)
    end
  end
end
