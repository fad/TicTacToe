package
{
	import com.arkavis.log4as.LogManager;
	
	import flash.events.*;
	import flash.net.*;
	import flash.utils.*;
	
	public class StratusConnection extends EventDispatcher implements IConnection
	{
		protected var log:LogManager = LogManager.GetLogger();
		
		protected static const RTMFP_END_POINT:String = "rtmfp://stratus.adobe.com/";
		protected static const ADOBE_DEV_KEY:String = "a212b33c2171391cb7a427ff-76077b3c37cd";

		private var _netConnection:NetConnection;
		private var _streamOutgoing:NetStream;
		private var _streamIncoming:NetStream;
		
		var model;
		public function set Model(m):void
		{
			model = m;
		}
		
		public function StratusConnection()
		{
		}
		
		public function setupConnectionForJoining():void
		{
			//SETUP CONNECTION TO STRATUS
			log.info("Connecting");
			_netConnection = new NetConnection();
			_netConnection.addEventListener(NetStatusEvent.NET_STATUS, netConnectionHandler);
			_netConnection.connect(RTMFP_END_POINT + ADOBE_DEV_KEY + "/");
		}
		
		public function setupIncomingStream(id:String):void
		{
			log.debug("setupIncomingStream id="+id);
			log.debug("_streamIncoming="+_streamIncoming);
			log.debug("_netConnection="+_netConnection);
			log.debug("_netConnection.connected="+_netConnection.connected);
			if (id.length != 64)
				throw new Error("peer ID is incorrect!");
			if (_streamIncoming)
				return;
			
			log.debug("_netConnection.connected="+_netConnection.connected);
			
			_streamIncoming = new NetStream(_netConnection,id);
			_streamIncoming.client = this;
			_streamIncoming.addEventListener(NetStatusEvent.NET_STATUS, netStreamHandler, false, 0, true);
			_streamIncoming.play("TicTacToe");
			//_video.attachNetStream(_streamIncoming);
			dispatchEvent(new Event(ConnectionStatus.READY));
		}

		
		public function netStreamHandler(e:NetStatusEvent):void
		{
			if (e.target == _streamIncoming)
			{
				trace("Incoming NetStream Handler:",e.info.code);
			}
			if (e.target == _streamOutgoing)
			{
				trace("Outgoing NetStream Handler:",e.info.code);
			}
			if (e.info.code == "NetStream.Play.Start")
			{
				if (e.target == _streamOutgoing)
				{
					_streamOutgoing.send("|RtmpSampleAccess", true, true);
					setTimeout(dispatchEvent, 1000, new Event(Event.CONNECT));
				}
			}
		}

		public function setupConnection():void
		{
			//SETUP CONNECTION TO STRATUS
			log.info("Connecting");
			_netConnection = new NetConnection();
			_netConnection.addEventListener(NetStatusEvent.NET_STATUS, netConnectionHandler);
			_netConnection.connect(RTMFP_END_POINT + ADOBE_DEV_KEY + "/");
		}
		
		public function netConnectionHandler(e:NetStatusEvent):void
		{
			if (e.info.code == "NetConnection.Connect.Success")
			{
				log.info("_playerId="+model._playerId);
				setupOutgoingStream(model._playerId == 2);
			}
		}

		public function setupOutgoingStream(joining:Boolean = false):void
		{
			log.info("joining="+joining);
			log.info('setting up outgoing stream');
			_streamOutgoing = new NetStream(_netConnection,NetStream.DIRECT_CONNECTIONS);
			
			_streamOutgoing.addEventListener(NetStatusEvent.NET_STATUS, netStreamHandler, false, 0, true);
			var out:Object = new Object();
			out.parent = this;
			out.onPeerConnect = function(subscriber:NetStream):Boolean 
			{
				log.info("Subscriber Connected:"+subscriber.farID);
				this.parent.setupIncomingStream(subscriber.farID);
				
				model.startGame();
				return true;
			};
			_streamOutgoing.client = out;
			_streamOutgoing.publish("TicTacToe");

			if (!joining)
				dispatchEvent(new ServerReadyEvent(ConnectionStatus.SERVER_READY,_netConnection.nearID));
		}

		public function sendMessage(m:Object):void
		{
			_streamOutgoing.send("receive",m);
		}
		
		public function receive(m:Object):void
		{
			log.debug("received: "+m);

			if (m == "restart")
			{
				model.restartGame();
			}
			else
			{
				var pos = m.indexOf(":");
				var tileName = m.substring(pos + 1);
				log.info("tile:"+tileName);
				model.setTile(tileName, false);
			}
		}	

	}
}