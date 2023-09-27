module ProjectFinderMethods
  extend ActiveSupport::Concern

  class_methods do
    def check_access?(project)
      return false if project.nil?
      # check for 'access' flag

      return true unless Relationship.forbidden_project_ids.include?(project.id)

      # simple check for involvement --> involved users can access project.id, User.session!
      project.relationships.groups.includes(:group).any? do |grouprel|
        # check if User.session! belongs to group.
        User.session!.is_in_group?(grouprel.group) ||
          # FIXME: please do not do special things here for ldap. please cover this in a generic group model.
          (CONFIG['ldap_mode'] == :on &&
            CONFIG['ldap_group_support'] == :on &&
            UserLdapStrategy.user_in_group_ldap?(User.session!, grouprel.group_id))
      end
    end

    # This finder is checking for
    #   - a Project in the database
    #   - read authorization of the Project in the database
    #   - a Project from an interconnect
    #
    # The return value is either
    #   - an instance of Project
    #   - a string for a Project from an interconnect
    #   - UnknownObjectError or ReadAccessError exceptions
    def get_by_name(name, opts = {})
      dbp = find_by_name(name, skip_check_access: true)
      if dbp.nil?
        dbp, remote_name = find_remote_project(name)
        return dbp.name + ':' + remote_name if dbp

        raise Project::Errors::UnknownObjectError, "Project not found: #{name}"
      end
      if opts[:includeallpackages]
        Package.joins(:flags).where(project_id: dbp.id).where("flags.flag='sourceaccess'").find_each do |pkg|
          raise ReadAccessError, name unless Package.check_access?(pkg)
        end
      end

      raise ReadAccessError, name unless check_access?(dbp)

      dbp
    end

    # check existence of a project (local or remote)
    def exists_by_name(name)
      local_project = find_by_name(name, skip_check_access: true)
      if local_project.nil?
        find_remote_project(name).present?
      else
        check_access?(local_project)
      end
    end

    # FIXME: to be obsoleted, this function is not throwing exceptions on problems
    # use get_by_name or exists_by_name instead
    def find_by_name(name, opts = {})
      dbp = find_by(name: name)

      return if dbp.nil?
      return if !opts[:skip_check_access] && !check_access?(dbp)

      dbp
    end

    def find_by_attribute_type(attrib_type)
      Project.joins(:attribs).where(attribs: { attrib_type_id: attrib_type.id })
    end

    def find_remote_project(name, skip_access = false)
      return unless name

      fragments = name.split(':')

      while fragments.length > 1
        remote_project = [fragments.pop, remote_project].compact.join(':')
        local_project = fragments.join(':')

        logger.debug "Trying to find local project #{local_project}, remote_project #{remote_project}"

        project = Project.find_by(name: local_project)
        if project && (skip_access || check_access?(project)) && project.defines_remote_instance?
          logger.debug "Found local project #{project.name} for #{remote_project} with remoteurl #{project.remoteurl}"
          return project, remote_project
        end
      end
      nil
    end
  end
  # end class_methods

  def exists_package?(name, opts = {})
    pkg = if opts[:follow_project_links]
            # Look for any package with name in all our linked projects
            Package.find_by(project: expand_linking_to, name: name)
          else
            packages.find_by_name(name)
          end
    if pkg.nil?
      # local project, but package may be in a linked remote one
      opts[:allow_remote_packages] && Package.exists_on_backend?(name, self.name)
    else
      Package.check_access?(pkg)
    end
  end

  # find a package in a project and its linked projects
  def find_package(package_name, check_update_project = nil, processed = {})
    # cycle check in linked projects
    if processed[self]
      str = name
      processed.keys.each do |key|
        str = str + ' -- ' + key.name
      end
      raise CycleError, "There is a cycle in project link defintion at #{str}"
    end
    processed[self] = 1

    # package exists in this project
    pkg = nil
    pkg = update_instance.packages.find_by_name(package_name) if check_update_project
    pkg = packages.find_by_name(package_name) if pkg.nil?
    return pkg if pkg && Package.check_access?(pkg)

    # search via all linked projects
    linking_to.each do |lp|
      raise CycleError, 'project links against itself, this is not allowed' if self == lp.linked_db_project

      pkg = if lp.linked_db_project.nil?
              # We can't get a package object from a remote instance ... how shall we handle this ?
              nil
            else
              lp.linked_db_project.find_package(package_name, check_update_project, processed)
            end
      unless pkg.nil?
        return pkg if Package.check_access?(pkg)
      end
    end

    # no package found
    processed.delete(self)
    nil
  end
end
