class UsersController < ApplicationController
  
  before_action :redirect_non_admin_user, only: :destroy
  before_action :redirect_non_user, only: :show

  def index
    @user = current_user
  end

  def show
    
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

    #Top 10 most popular stocks
    @popular_stocks = Stock.popular_stocks(10)

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
    referrer = Referral.find_by(referral_code: referral_hash[:referral_code]).inviter

    #create new referral code spot in database if referral code is from admin (to provide unlimited invites from admin)
    unless referrer == nil
      referrer.referrals.create!(referral_code: referral_hash[:referral_code], email: "noemail@noemail.com") if referrer.admin
    end

    #Look to see if referral code matches the one that exists in the database, and whether there is an empty slot
    referral_spots = Referral.where(referral_code: referral_hash[:referral_code], invited_id: nil)


    #this saves the new user to the database.
  	if @user.valid? && referral_spots.exists?
      @user.save
      log_in @user

      #save user referral
      @referral = referral_spots.first
      @referral.invited_id = @user.id
      @referral.save

      #function 'generate_code' returns a random 6 digit code
      referral_code = generate_code
      
      #generate 3 referrals for new user to share with friends
      3.times { @user.referrals.create!(referral_code: referral_code, email: @user.email) }

      WelcomemailerWorker.new.perform(@user.id)
      InvitefriendsmailerWorker.new.perform(@user.id)
      #UserMailer.welcome_mailer(@user.id).deliver_now
      #UserMailer.invite_friends_mailer(@user.id).deliver_later
      #redirect to user profile page
  		render :js => "window.location = '/welcome'" # have to use a js redirect here because the form has remote:true

  	else
      @disable_nav = true

      #Adds invalid referral code error message to user object if referral code is invalid
      @user.invalid_referral if referral_spots.exists? == false
      respond_to do |format|
        format.js{}
      end
      #session[:errors] = @user.errors.full_messages
    end
	end


  #ADMIN CONTROLS
  def destroy
    User.find_by(username: params[:username]).destroy
    flash[:success] = "User deleted"
    redirect_to users_url
  end


  private

	  def user_params
	    params.require(:user).permit(:username, :email, :password,
	                                 :password_confirmation, :image)
	  end

    def referral_params
      params.require(:referral).permit(:referral_code)
    end


end
