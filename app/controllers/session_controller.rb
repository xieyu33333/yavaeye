# encoding: UTF-8
post '/session/?' do
  case params[:identifier]
  when 'google'
    redirect settings.google_oauth_client.auth_code.authorize_url(scope: "https://www.googleapis.com/auth/userinfo.email",
      redirect_uri: "http://localhost:9292/auth/google/callback")
  when 'github'
    redirect settings.github_oauth_client.auth_code.authorize_url(scope: "user")
  else
    flash[:notice] = "缺少登录提供商"
    redirect '/'
  end
end

get '/auth/:provider/callback' do |provider|
  code = params['code']
  if code.blank?
    flash[:notice] = "认证错误..."
    redirect '/session/login'
  else
    if provider == "github"
      access_token = settings.github_oauth_client.auth_code.get_token(code)
      response = access_token.get("https://api.github.com/user")
      body = JSON.parse(response.body)
      email = body["email"] if body["email"]
      gravatar_id = body["gravatar_id"]
    elsif provider == "google"
      access_token = settings.google_oauth_client.auth_code.get_token(code, 'redirect_uri' => 'http://localhost:9292/auth/google/callback')
      response = access_token.get("https://www.googleapis.com/oauth2/v1/userinfo")
      body = JSON.parse(response.body)
      email = body["email"]
      gravatar_id = Digest::MD5.hexdigest(email)
    else
      flash[:notice] = "认证错误..."
      redirect '/session/login'
    end
    if @user = User.where(gravatar_id: gravatar_id).first
      session[:user_id] = @user.id.to_s
      remember_me @user
      flash[:notice] = "登录成功"
      redirect '/'
    else
      session[:user_email] = email
      session[:user_gravatar_id] = gravatar_id
      @user = User.new
      slim :'/user/new'
    end
  end
end

delete '/session/?' do
  session.delete 'user_id'
  forget_me
  flash[:notice] = "已注销"
  redirect "/"
end
