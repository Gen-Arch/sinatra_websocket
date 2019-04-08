

def open_log(log)
  File.open(log, 'a+').tap do |logger|
    logger.binmode
    logger.sync = true
  end
end

while true
  sleep 1
  logs = ["test1.log", "test2.log", "test3.log"]
  log_name = logs.sample
  log = open_log(log_name)
  print "input(#{log_name}) : "
  text = gets
  log.syswrite(text)
end
