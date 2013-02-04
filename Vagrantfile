Vagrant::Config.run do |config|
  config.vm.host_name = "rubygems"
  config.vm.box = "precise64"
  config.vm.box_url = "http://files.vagrantup.com/precise64.box"
  config.vm.network :hostonly, "192.168.33.100"
  config.vm.forward_port 3000, 3000
  config.vm.customize ["modifyvm", :id, "--memory", 1024]
  config.vm.share_folder "v-root", "/vagrant", ".", :nfs => !(ENV["OS"] =~ /windows/i)
  if File.directory?(File.expand_path("./.apt-cache/partial/"))
    config.vm.share_folder "apt-cache", "/var/cache/apt/archives", "./.apt-cache", :owner => "root", :group => "root"
  end 
  config.vm.provision :shell, :path => "script/vagrant-keep-agent-forwarding"
  config.vm.provision :shell, :path => "script/vagrant-provision"
end
