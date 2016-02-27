# QUICK Development Setup

Through the use of Docker and the build_fast.sh script, you can build this app in minutes instead of hours.  Even if you don't have Ruby on Rails installed on your host OS, you can build this app and finish the tests in a matter of minutes instead of hours.

## PREREQUISITES
* You must be using a 64-bit host OS and machine.  This app uses Toxiproxy, which is incompatible with 32-bit systems.
* Your computer probably needs VT-x or AMD-v.  If your computer lacks this feature, you may have difficulty running the tmux command in a Docker container.
* You must have Docker installed.  Go to https://docs.docker.com/machine/install-machine/ for more details on getting started.  Please note systemd is a requirement for Docker Engine.  If your Linux distro has disabled this feature, you need to enable it.

## Setting Up Docker
1. Through Docker Machine, go to a command line shell window and git clone the 64-bit Debian Jessie Docker image repository at https://github.com/jhsu802701/docker-64bit-debian-jessie .
2. Enter the command `sh rbenv-rubygems.sh`.
3. Enter the resulting rbenv-rubygems.sh directory and enter the command `sh download_new_image.sh`.  This downloads the jhsu802701/debian-jessie-rbenv-rubygems Docker image and then runs it.  This image comes pre-installed with this project's version of Ruby, this project's version of Rails, and other necessary ingredients.  This allows you to bypass the long waits necessary to download and install everything you need to work on this project.
4. In the resulting Docker container, go to the shared directory and download this rubygems.org repository.
5. Enter the command `tmux` to split your access among multiple windows.  You will need three tmux windows.
6. In the first tmux window, enter the command `redis-server`.  This runs the Redis server, which is a necessary part of this project.
7. In the second tmux window, go to the rubygems.org project's root directory and enter the command `sh build_prepare.sh`.
8. In the third tmux window, go to the rubygem.org project's root directory, and enter the command `sh build_fast.sh`.  In a few minutes, this project will be built, and all tests will pass.
