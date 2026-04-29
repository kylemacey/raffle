class UsersController < ApplicationController
  before_action :set_user, only: %i[ show edit update destroy ]
  before_action :set_roles, only: %i[ new edit create update ]
  before_action -> { require_permission!("users.manage") }

  # GET /users or /users.json
  def index
    @users = User.includes(roles: :permissions).order(:name, :id)
  end

  # GET /users/1 or /users/1.json
  def show
  end

  # GET /users/new
  def new
    @user = User.new
  end

  # GET /users/1/edit
  def edit
  end

  # POST /users or /users.json
  def create
    @user = User.new(user_params)
    return render(:new, status: :forbidden) unless authorize_role_assignment!(@user)

    respond_to do |format|
      if @user.save
        format.html { redirect_to user_url(@user), notice: "User was successfully created." }
        format.json { render :show, status: :created, location: @user }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /users/1 or /users/1.json
  def update
    return render(:edit, status: :forbidden) unless authorize_role_assignment!(@user)

    respond_to do |format|
      if @user.update(user_params)
        format.html { redirect_to user_url(@user), notice: "User was successfully updated." }
        format.json { render :show, status: :ok, location: @user }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /users/1 or /users/1.json
  def destroy
    @user.destroy

    respond_to do |format|
      format.html { redirect_to users_url, notice: "User was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_user
      @user = User.includes(roles: :permissions).find(params[:id])
    end

    def set_roles
      @roles = Role.includes(:permissions).ordered
      @roles = @roles.where.not(key: "platform_admin") unless current_user_can?("super_admin.assign")
    end

    # Only allow a list of trusted parameters through.
    def user_params
      permitted = params.require(:user).permit(:name, :pin, role_ids: [])
      permitted.delete(:role_ids) unless current_user_can?("roles.assign")
      permitted[:role_ids] = normalized_role_ids if permitted.key?(:role_ids)
      permitted
    end

    def authorize_role_assignment!(user)
      return true unless params.dig(:user, :role_ids)

      unless current_user_can?("roles.assign")
        user.errors.add(:base, "You are not authorized to assign roles.")
        return false
      end

      platform_admin = Role.find_by(key: "platform_admin")
      return true unless platform_admin

      requested_platform_admin = submitted_role_ids.include?(platform_admin.id)
      existing_platform_admin = user.persisted? && user.role_ids.include?(platform_admin.id)

      return true if current_user_can?("super_admin.assign")
      return true unless requested_platform_admin && !existing_platform_admin

      user.errors.add(:base, "You are not authorized to assign SuperAdmin.")
      false
    end

    def normalized_role_ids
      role_ids = submitted_role_ids
      platform_admin = Role.find_by(key: "platform_admin")

      if platform_admin && !current_user_can?("super_admin.assign") && @user&.role_ids&.include?(platform_admin.id)
        role_ids << platform_admin.id
      end

      role_ids.uniq
    end

    def submitted_role_ids
      Array(params.dig(:user, :role_ids)).reject(&:blank?).map(&:to_i)
    end
end
