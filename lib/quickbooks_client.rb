require "quickbooks-ruby"
require 'oauth2'
require 'puma'
require 'json'
require 'rack'

class QuickbooksClient
  attr_reader :oauth_client, :realm_id

  def initialize(client_id:, client_secret:, refresh_token: nil, realm_id: nil, environment: 'sandbox', redirect_uri: 'http://localhost:8000/callback')
    @client_id = client_id
    @client_secret = client_secret
    @refresh_token = refresh_token
    @realm_id = realm_id
    @environment = environment
    @redirect_uri = redirect_uri
    @access_token = nil
    @access_token_expiry = nil
    @is_authenticating = false

    setup_oauth_client
  end

  def authenticate
    unless @refresh_token && @realm_id
      start_oauth_flow
      raise 'Failed to obtain required tokens from OAuth flow' unless @refresh_token && @realm_id
    end

    refresh_access_token if token_expired?
    setup_quickbooks_service
  end

  def service(entity_type)
    raise 'Not authenticated. Call authenticate() first' unless @access_token

    service_class = "Quickbooks::Service::#{entity_type}".constantize
    service = service_class.new
    service.company_id = @realm_id
    service.access_token = @access_token
    service
  end

  private

  def setup_oauth_client
    base_url = @environment == 'production' ?
      'https://oauth.platform.intuit.com/oauth2/v1' :
      'https://oauth.platform.intuit.com/oauth2/v1'

    @oauth_client = OAuth2::Client.new(
      @client_id,
      @client_secret,
      site: 'https://appcenter.intuit.com',
      authorize_url: '/connect/oauth2',
      token_url: base_url + '/tokens/bearer'
    )
  end

  def setup_quickbooks_service
    # Services are created on demand via service() method
    true
  end

  def token_expired?
    !@access_token || !@access_token_expiry || Time.now >= @access_token_expiry
  end

  def refresh_access_token
    unless @refresh_token
      start_oauth_flow
      raise 'Failed to obtain refresh token from OAuth flow' unless @refresh_token
    end

    begin
      token = OAuth2::AccessToken.new(@oauth_client, '', refresh_token: @refresh_token)
      new_token = token.refresh!

      @access_token = OAuth2::AccessToken.new(@oauth_client, new_token.token)
      @access_token_expiry = Time.now + (new_token.expires_in || 3600)

      new_token
    rescue StandardError => e
      raise "Failed to refresh QuickBooks token: #{e.message}"
    end
  end

  def start_oauth_flow
    return if @is_authenticating

    @is_authenticating = true
    port = 8000
    server_thread = nil

    # Create a Rack app to handle the OAuth callback
    app = lambda do |env|
      request = Rack::Request.new(env)

      if request.path == '/callback' && request.params['code']
        begin
          auth_code = request.params['code']
          @realm_id = request.params['realmId']

          token = @oauth_client.auth_code.get_token(
            auth_code,
            redirect_uri: @redirect_uri
          )

          @refresh_token = token.refresh_token
          @access_token = OAuth2::AccessToken.new(@oauth_client, token.token)
          @access_token_expiry = Time.now + (token.expires_in || 3600)

          save_tokens_to_env

          success_html = <<~HTML
            <html>
              <body style="
                display: flex;
                flex-direction: column;
                justify-content: center;
                align-items: center;
                height: 100vh;
                margin: 0;
                font-family: Arial, sans-serif;
                background-color: #f5f5f5;
              ">
                <h2 style="color: #2E8B57;">✓ Successfully connected to QuickBooks!</h2>
                <p>You can close this window now.</p>
              </body>
            </html>
          HTML

          # Schedule server shutdown
          Thread.new do
            sleep 1
            @is_authenticating = false
            server_thread&.kill
          end

          [200, { 'Content-Type' => 'text/html' }, [success_html]]
        rescue StandardError => e
          warn "Error during token creation: #{e.message}"

          error_html = <<~HTML
            <html>
              <body style="
                display: flex;
                flex-direction: column;
                justify-content: center;
                align-items: center;
                height: 100vh;
                margin: 0;
                font-family: Arial, sans-serif;
                background-color: #fff0f0;
              ">
                <h2 style="color: #d32f2f;">Error connecting to QuickBooks</h2>
                <p>Please check the console for more details.</p>
              </body>
            </html>
          HTML

          @is_authenticating = false
          [500, { 'Content-Type' => 'text/html' }, [error_html]]
        end
      else
        [404, { 'Content-Type' => 'text/plain' }, ['Not Found']]
      end
    end

    # Start Puma server in a thread
    server_thread = Thread.new do
      Puma::Server.new(app).tap do |server|
        server.add_tcp_listener '127.0.0.1', port
        server.run.join
      end
    end

    # Give server time to start
    sleep 0.5

    # Generate authorization URL
    auth_url = @oauth_client.auth_code.authorize_url(
      redirect_uri: @redirect_uri,
      scope: 'com.intuit.quickbooks.accounting',
      state: 'testState'
    )

    # Open browser
    system("open '#{auth_url}'") || system("xdg-open '#{auth_url}'") || system("start '#{auth_url}'")

    # Wait for OAuth flow to complete
    sleep 0.5 while @is_authenticating
    server_thread&.kill
  end

  def save_tokens_to_env
    env_path = File.expand_path('../../.env', __dir__)

    if File.exist?(env_path)
      env_content = File.read(env_path)
      lines = env_content.split("\n")

      update_env_var(lines, 'QUICKBOOKS_REFRESH_TOKEN', @refresh_token) if @refresh_token
      update_env_var(lines, 'QUICKBOOKS_REALM_ID', @realm_id) if @realm_id

      File.write(env_path, lines.join("\n"))
    end
  end

  def update_env_var(lines, name, value)
    index = lines.index { |line| line.start_with?("#{name}=") }
    if index
      lines[index] = "#{name}=#{value}"
    else
      lines << "#{name}=#{value}"
    end
  end
end
