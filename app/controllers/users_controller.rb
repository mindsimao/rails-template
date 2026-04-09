class UsersController < ApplicationController
  before_action :require_admin

  def index
    @users = User.order(:name)
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    @user.password = SecureRandom.hex(16)

    if @user.save
      @user.send_reset_password_instructions
      redirect_to users_path, notice: "#{@user.name} was invited and will receive a password setup email."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @user = User.find(params[:id])
    @user.destroy!
    redirect_to users_path, notice: "#{@user.name} was removed."
  end

  private
    def user_params
      params.expect(user: [ :name, :email, :admin ])
    end

    def require_admin
      redirect_to root_path, alert: "Not authorized." unless current_user&.admin?
    end
end
