class BsRequestPolicy

  def initialize(command_context, record)
    @user = command_context.user
    @params = command_context.params
    @record = record
  end

  def create?
    return false if @user.is_nobody?

    # new request should not have an id (BsRequest#number)
    return false if @record.number

    return true if [nil, @user.login].include?(@record.approver) || @user.is_admin?

    false
  end

  def update?
    return true if @user.is_admin?

    false
  end

  def destroy?
    return true if @user.is_admin?

    false
  end

  # Commands
  def changestate?
    return false if @user.is_nobody?

    return @user.run_as { @record.permission_check_change_state(@params) }
  end

  def changereviewstate?
  end

  def assignreview?
  end

  def addreview
  end

  def setpriority
  end

  def setincident
  end

  def setacceptat
  end

  def approve
  end

  def cancelapproval
  end
end
