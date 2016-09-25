worker_processes 2 # this should be >= nr_cpus
pid "/home/eric/konklone.com/shared/unicorn.pid"

working_directory "/home/eric/konklone.com/current"

# in production, direct all logs to /dev/null
# (this happens by default on daemonization anyway)
stdout_path "/home/eric/log/konklone-unicorn.log"
stderr_path "/home/eric/log/konklone-unicorn-error.log"
