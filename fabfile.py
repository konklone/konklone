import time
from fabric.api import run, execute, env

environment = "production"

env.use_ssh_config = True
env.hosts = ["new.konklone.com"]

branch = "master"
repo = "git://github.com/konklone/konklone.git"

home = "/home/konklone/konklone"
shared_path = "%s/shared" % home
version_path = "%s/versions/%s" % (home, time.strftime("%Y%m%d%H%M%S"))
current_path = "%s/current" % home


# can be run only as part of deploy

def checkout():
  run('git clone -q -b %s %s %s' % (branch, repo, version_path))

def links():
  run("ln -s %s/config.yml %s/config/config.yml" % (shared_path, version_path))
  run("ln -s %s/config.ru %s/config.ru" % (shared_path, version_path))
  run("ln -s %s/unicorn.rb %s/unicorn.rb" % (shared_path, version_path))
  run("mkdir %s/tmp" % version_path)

def dependencies():
  run("cd %s && bundle install --local" % version_path)

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
  run("cd %s && unicorn -D -l %s/%s.sock -c unicorn.rb" % (current_path, shared_path, username))

def stop():
  run("kill `cat %s/unicorn.pid`" % shared_path)

def restart():
  stop()
  start()
  # run("kill -HUP `cat %s/unicorn.pid`" % shared_path)


def deploy():
  execute(checkout)
  execute(links)
  execute(dependencies)
  execute(create_indexes)
  execute(make_current)
  execute(set_crontab)
  execute(restart)

# only difference is it uses start instead of restart
def deploy_cold():
  execute(checkout)
  execute(links)
  execute(dependencies)
  execute(create_indexes)
  execute(make_current)
  execute(set_crontab)
  execute(start)