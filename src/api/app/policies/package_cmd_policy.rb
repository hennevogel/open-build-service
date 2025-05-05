class PackageCmdPolicy < ApplicationPolicy
  def initialize(user_context, record)
    @user = user_context.user
    @project = user_context.project
    @record = record

    raise Pundit::NotAuthorizedError, 'record does not exist' unless record
  end

  def updatepatchinfo?
  end

  def importchannel?
  end

  def unlock?
  end

  def addchannels?
  end

  def addcontainers?
  end

  def enablechannel?
  end

  def getprojectservices?
  end

  def showlinked?
    binding.pry
    return ProjectPolicy.new(user, record.project).update? if record.readonly?
  end

  def collectbuildenv?
  end

  def instantiate?
  end

  def undelete?
  end

  def createSpecFileTemplate?
  end

  def rebuild?
  end

  def commit?
  end

  def commitfilelist?
  end

  def diff?
  end

  def linkdiff?
  end

  def servicediff?
  end

  def copy?
  end

  def release?
  end

  def waitservice?
  end

  def mergeservice?
  end

  def runservice?
  end

  def deleteuploadrev?
  end

  def linktobranch?
  end

  def branch?
  end

  def fork?
  end

  def set_flag?
  end

  def remove_flag?
  end
end
