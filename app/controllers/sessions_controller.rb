class SessionsController < Devise::SessionsController
  skip_before_action :authenticate_user!, only: [ :demo ]
  skip_before_action :block_demo_mutations, only: [ :demo, :exit_demo ]

  def demo
    demo_user = User.find_by(email: "demo@seedlingscheduler.com", demo: true)

    if demo_user
      sign_in(demo_user, event: :authentication)
      flash[:notice] = "Welcome to the demo! Explore freely - changes won't save. Sign up to create your own garden."
      redirect_to tasks_path
    else
      flash[:alert] = "Demo account not found. Please contact support."
      redirect_to root_path
    end
  end

  def exit_demo
    sign_out(current_user) if current_user&.demo?
    redirect_to new_user_registration_path, notice: "Ready to create your own garden? Sign up below!"
  end
end
