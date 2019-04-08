require 'sinatra'
require 'sinatra-websocket'
require 'sinatra/reloader' if development?

set :sockets, []

helpers do
  def open_log(log)
    File.open(log, 'a+').tap do |logger|
      logger.binmode
      logger.sync = true
    end
  end
end

get '/' do
  erb :index
end

get '/file' do
  filename = "#{params[:log]}.log"
  send_file filename, :filename => filename, :type => 'Application/octet-stream'
end

get '/websocket' do
  log = "#{params[:log]}.log"
  io = open(log, 'w+')

  if request.websocket?
    request.websocket do |ws|
      ws.onopen do
        Thread.new {while true; io.each_char {|ch| sleep 0.05; ws.send(ch)} end}
        settings.sockets << ws
      end
      ws.onmessage do |msg|
        write = open_log(log)
        write.puts msg
      end

      ws.onclose do
        warn("close #{log}")
        settings.sockets.delete(ws)
      end
    end
  end
end

__END__
@@ index
<html>
<body>
<h1>Simple Echo & Chat Server</h1>
<div id="msgs"></div>
<form id="form">
<input type="text" id="input" value=""></input>
</form>
</body>

<script type="text/javascript">
window.onload = function(){
  (function(){
    var show = function(el){
      return function(msg){
        if(msg === '\n') {
            el.innerHTML = el.innerHTML + '<br />';
        }else{
          el.innerHTML = el.innerHTML + msg;
        }
      }
    }(document.getElementById('msgs'));

    var ws       = new WebSocket('ws://' + window.location.host + '/websocket?log=test');
    ws.onopen    = function()  { show('websocket opened<br />'); };
    ws.onclose   = function()  { show('websocket closed<br />'); }
    ws.onmessage = function(m) { show(m.data); };

    var sender = function(f){
      var input     = document.getElementById('input');
      input.onclick = function(){ input.value = "" };
      f.onsubmit    = function(){
        ws.send(input.value);
        input.value = "";
        return false;
      }
    }(document.getElementById('form'));
  })();
}
</script>
</html>
