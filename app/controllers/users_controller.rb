class UsersController < ApplicationController
  
  #only allows admin_user (see private methods) to make delete requests on users
  before_action :admin_user, only: :destroy

  #this method automatically loads the index view newuser/new.html.erb. 
  #And all variables with @ are available in the view.
  #the Newuser.new creates a new user from the model.
  
  def index
    @users = User.all
  end

  def show
    return if user_logged_in? #redirects the user to the login page if they are not logged in.
    
    #Logged in user
    @current_user = current_user

    #Target user
    @user = User.find_by(username: params[:username])

    #All active predictions by target user
    @predictions = Prediction.where(active: 1, user_id: @user.id)

    #All streams about target user
    @streams = @user.streams
    @streams = @streams.paginate(page: params[:page], per_page: 10)

    #Determines relationship between current user and target user
    @target = @user

    @comment_header = "Comment on #{params[:username]}"
    @comment_stream_inputs = "User:#{@user.id}"

    @comment_landing_page = "users:#{@user.username}"
    @stream_comment_landing_page = "users:#{@user.username}"

    respond_to do |format|
      format.html
      format.js
    end
  end

  def new
  	@user = User.new #create an empty user to be passed into the user creation form.

    #If referral code in url matches database, then load that referral object
    unless params[:ref] == nil
      @referral = Referral.find_by(referral_code: params[:ref].to_i )
      #If referral code is not found in database, set to an empty referral object. 
      @referral = Referral.new if @referral == nil

    else
      @referral = Referral.new
    end

    @disable_nav = true
  end

  def create

    #this uses the result from the user_params function to create a new user.
  	@user = User.new(user_params)

    referral_hash = referral_params
    
    #Look to see if referral code matches the one that exists in the database
    @referral = Referral.find_by(referral_code: referral_hash[:referral_code])

    #Make @referral object invalid (nil) if user_id already exists for that referral code
    if @referral != nil
      @referral = nil if @referral.user_id != nil
    end

    #this saves the new user to the database.
  	if @user.valid? && @referral != nil 
      @user.save
      log_in @user

      @referral.user_id = @user.id
      @referral.save

      UserMailer.welcome_mailer(@user.id)

      #redirect to user profile page

  		render :js => "window.location = '/welcome'"

  	else
      @disable_nav = true

      #Adds invalid referral code error message to user object if referral code is invalid
      @user.invalid_referral if @referral == nil
      respond_to do |format|
        format.js{}
      end
      #session[:errors] = @user.errors.full_messages
  		#redirect_to "/signup" #we're in the same template, so it assumes this controller, and this is the method name to go to.
    end
	end

  def destroy
      User.find_by(username: params[:username]).destroy
      flash[:success] = "User deleted"
      redirect_to users_url
  end


  private

	  def user_params
	  	#This returns a version of the params hash with only the permitted attributes.
	  	#So :user get's returned, but wittled down to just these 4 attributes.
	  	#params[:user] is what returns the values from the form in hash.
	  	#One way of creating a new user from the params hash would be @user = User.new(params[:user])
	  	#instead we use this very fancy line below that also permits only specific form fields.
	  	#user is the object created by passing the @user variable into the Ruby form.
	    params.require(:user).permit(:username, :email, :password,
	                                 :password_confirmation, :image)
	  end

    def referral_params
      params.require(:referral).permit(:referral_code)
    end

    def admin_user
      redirect_to(root_url) unless current_user.admin?
    end


end
