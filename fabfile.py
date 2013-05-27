import time
from fabric.api import run, execute, env

environment = "production"

env.use_ssh_config = True
env.hosts = ["konklone.com"]

branch = "master"
repo = "git://github.com/konklone/konklone.git"

home = "/home/klondike/webapps/konklone/konklone"
shared_path = "%s/shared" % home
version_path = "%s/versions/%s" % (home, time.strftime("%Y%m%d%H%M%S"))
current_path = "%s/current" % home

gems_dir = "/home/klondike/webapps/konklone/gems"
bin_path = "/home/klondike/webapps/konklone/bin"


# can be run only as part of deploy

def checkout():
  run('git clone -q -b %s %s %s' % (branch, repo, version_path))

def links():
  run("ln -s %s/config.yml %s/config/config.yml" % (shared_path, version_path))
  run("ln -s %s/config.ru %s/config.ru" % (shared_path, version_path))
  run("ln -s %s/unicorn.rb %s/unicorn.rb" % (shared_path, version_path))
  run("mkdir %s/tmp" % version_path)

def dependencies():
  run("cd %s && bundle install --local --path=%s" % (version_path, gems_dir))

def create_indexes():
  run("cd %s && bundle exec rake create_indexes" % version_path)

def make_current():
  run('rm -f %s && ln -s %s %s' % (current_path, version_path, current_path))

def set_crontab():
  run("cd %s && bundle exec rake set_crontab environment=%s current_path=%s" % (current_path, environment, current_path))

def prune_releases():
  pass


## can be run on their own

def start():
  run("%s/start" % bin_path)

def stop():
  run("%s/stop" % bin_path)

def restart():
  run("touch %s/tmp/restart.txt" % current_path)



def deploy():
  execute(checkout)
  execute(links)
  execute(dependencies)
  execute(create_indexes)
  execute(make_current)
  execute(set_crontab)
  execute(restart)
  execute(prune_releases)