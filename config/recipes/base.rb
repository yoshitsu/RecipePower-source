def template(from, to)
  erb = File.read(File.expand_path("../templates/#{from}", __FILE__))
  erbstr = ERB.new(erb).result(binding)
  upload! StringIO.new(erbstr), to
end

def set_default(name, *args, &block)
  set(name, *args, &block) unless defined?(name) # exists?(name)
end

namespace :deploy do
  desc "Install everything onto the server"
  task :install do
    on roles(:app) do |host|
      sudo "apt-get -y update"
      # Maybe libcurl3-dev ?
      sudo "apt-get -y install ruby1.9.1-dev libmagickcore-dev libmagickwand-dev zlib1g-dev build-essential libssl-dev libreadline-dev libyaml-dev libxml2-dev libxslt1-dev libcurl4-openssl-dev python-software-properties"
    end
  end

  desc "Ensure the deploy directory is setup"
  task :ensure_www do
    on roles(:app) do |host|
      if test "[ ! -d #{deploy_to} ]"
        path = ""
        # Make sure that the directories on the deployment path exist and are owned by :user
        deploy_to.split('/').each { |dir|
          next if dir.length == 0
          path << "/#{dir}"
          if test "[ ! -d #{path} ]"
            sudo "mkdir -p #{path}"
            sudo "chown #{fetch :user}:#{fetch :user} #{path}"
            # execute "chmod 0775 #{path}"
          end
        }
        execute "chmod g+s #{deploy_to}"
        execute "mkdir #{deploy_to}/{releases,shared}"
        # execute "chmod 0770 #{deploy_to}/{releases,shared}"
        # execute "chown #{fetch :user} #{deploy_to}/{releases,shared}"
      end
    end
  end
  # after "rbenv:install", "deploy:ensure_www"
  after "deploy:install", "deploy:ensure_www"
end
