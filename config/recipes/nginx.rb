namespace :nginx do
  desc "Install latest stable release of nginx"
  task :install do
    on roles(:web) do
      sudo "add-apt-repository --yes ppa:nginx/stable"
      sudo "apt-get -y update"
      sudo "apt-get -y install nginx"
    end
  end
  after "deploy:install", "nginx:install"

  desc "Setup nginx configuration for this application"
  task :setup do
    on roles(:web) do
      template "nginx_unicorn.erb", "/tmp/nginx_conf"
      sudo "mv /tmp/nginx_conf /etc/nginx/sites-enabled/#{fetch :application}"
      sudo "rm -f /etc/nginx/sites-enabled/default"
      sudo "service nginx stop"
      sudo "service nginx start"
    end
  end
  # after "deploy:setup", "nginx:setup"
  after "deploy:published", "nginx:setup"

  %w[start stop restart].each do |command|
    desc "#{command} nginx"
    task command do
      on roles(:web) do
        # test("env | grep S3_BUCKET")
        # test("env | grep AWS_ACCESS_KEY_ID")
        if command == "stop"
          sudo "rm -f /tmp/unicorn.#{fetch :application}.sock"
        end
      end
    end
  end
end
