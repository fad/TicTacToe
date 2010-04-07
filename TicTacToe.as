package 
{
	import flash.display.*;
	import flash.text.TextField;
	import flash.net.*;
	import flash.events.*;
	import flash.utils.setTimeout;

	import com.arkavis.log4as.*;
	import com.arkavis.ui.*;
	import com.arkavis.Console;

	public class TicTacToe extends Sprite
	{
		protected var log:LogManager = LogManager.GetLogger();

		protected static const RTMFP_END_POINT:String = "rtmfp://stratus.adobe.com/";
		protected static const ADOBE_DEV_KEY:String = "a212b33c2171391cb7a427ff-76077b3c37cd";

		private var _netConnection:NetConnection;
		private var _streamOutgoing:NetStream;
		private var _streamIncoming:NetStream;
		private var _movesMade:int;
		private var _board = [[null,null,null],[null,null,null],[null,null,null]];
		private var _blockAtStart = false;
		public var _numberOfVictories:Number = 0;
		public var _numberOfDefeats:Number = 0;
		public var _playerId = -1;
		
		var _view;

		public function TicTacToe()
		{
			_view = new SimpleView(this);
			addChild(_view); //needed for the console beeing on top of everything
			_view.buildUI();
			
			var consoleConfig = {width:stage.stageWidth,height:150,color:0x111111,fontColor:0xFFFFFF,fontSize:14};
			var _console:Console = new Console(consoleConfig);
			_console.setSystem(this);
			addChild(_console);
			_console.hide();

			LogManager.LogLevel = LogManager.LogLevels.DEBUG;
			LogManager.addLogger(new TraceLogger());
			LogManager.addLogger(_console);
			log.info("initializing game");

			//_view.Constructor();
			init();
		}
		
		private function init()
		{
			_view.init();
			_movesMade = 0;
		}
	
		private function startGame()
		{
			log.debug("_playerId="+_playerId);
			log.debug("_blockAtStart="+_blockAtStart);
			_view.startGame(_blockAtStart);
		}
	
		public function restartGame()
		{
			log.info("restarting game");
			for (var i:int = 0; i < 3; i++)
				for (var j:int = 0; j < 3; j++)
					_board[i][j] = null;
		
			_view.cleanBoard();
			init();
			startGame();
		}

		function startAsServer()
		{
			_playerId = 1;
			setupConnection();
		}
	
		function joinGame()
		{
			_playerId = 2;
			_blockAtStart = true;
			setupConnectionForJoining();
		}
	
		public function makeMove(tileName)
		{
			setTile(tileName, true);
			sendMessage("move:"+tileName);
		}

		protected function setupConnection():void
		{
			//SETUP CONNECTION TO STRATUS
			log.info("Connecting");
			_netConnection = new NetConnection();
			_netConnection.addEventListener(NetStatusEvent.NET_STATUS, netConnectionHandler);
			_netConnection.connect(RTMFP_END_POINT + ADOBE_DEV_KEY + "/");
		}

		protected function setupConnectionForJoining():void
		{
			//SETUP CONNECTION TO STRATUS
			log.info("Connecting");
			_netConnection = new NetConnection();
			_netConnection.addEventListener(NetStatusEvent.NET_STATUS, netConnectionHandler);
			_netConnection.connect(RTMFP_END_POINT + ADOBE_DEV_KEY + "/");
		}

		protected function netConnectionHandler(e:NetStatusEvent):void
		{
			if (e.info.code == "NetConnection.Connect.Success")
			{
				log.info("_playerId="+_playerId);
				setupOutgoingStream(_playerId == 2);
			}
		}

		protected function setupOutgoingStream(joining = false):void
		{
			log.info("joining="+joining);
			//SETUP OUTGOING STREAM
			log.info('setting up outgoing stream');
			_streamOutgoing = new NetStream(_netConnection,NetStream.DIRECT_CONNECTIONS);
			//
			_streamOutgoing.addEventListener(NetStatusEvent.NET_STATUS, netStreamHandler, false, 0, true);
			var out:Object = new Object();
			out.parent = this;
			out.onPeerConnect = function(subscriber:NetStream):Boolean 
			{
				log.info("Subscriber Connected:"+subscriber.farID);
				this.parent.setupIncomingStream(subscriber.farID);
				
				startGame();
				return true;
			};
			_streamOutgoing.client = out;
			_streamOutgoing.publish("TicTacToe");

			if (!joining)
				_view.displayId(_netConnection.nearID);
		}

		public function setupIncomingStream(id:String):void
		{
			if (id.length != 64)
				throw new Error("peer ID is incorrect!");
			if (_streamIncoming)
				return;
				
			_streamIncoming = new NetStream(_netConnection,id);
			_streamIncoming.client = this;
			_streamIncoming.addEventListener(NetStatusEvent.NET_STATUS, netStreamHandler, false, 0, true);
			_streamIncoming.play("TicTacToe");
			//_video.attachNetStream(_streamIncoming);
			_view.showPlayField();
		}
	

		protected function netStreamHandler(e:NetStatusEvent):void
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


		public function sendMessage(m)
		{
			_streamOutgoing.send("receive",m);
		}

		public function receive(m):void
		{
			log.debug("received: "+m);

			if (m == "restart")
			{
				restartGame();
			}
			else
			{
				var pos = m.indexOf(":");
				var tileName = m.substring(pos + 1);
				log.info("tile:"+tileName);
				setTile(tileName, false);
			}
		}

		private function setTile(tileName, byMyself)
		{
			log.info("tileName="+tileName);
			_movesMade++;
			var row = tileName.substring(1,2);
			var col = tileName.substring(2);

			log.info("t="+tileName+",r="+row+",c="+col);
			var mark = byMyself ? 1:0;
			_board[row][col] = mark;
			
			_view.setTile(col, row, byMyself)
			checkBoard();
		}
		function boardToString()
		{
			var s = "";
			for (var i:int = 0; i < 3; i++)
			{
				for (var j:int = 0; j < 3; j++)
				{
					var c = "_";
					if (_board[i][j] == 1)
					{
						c = "x";
					}
					if (_board[i][j] == 0)
					{
						c = "o";
					}
					s += c;
				}
				s+="\n";
			}
			return s;
		}
		
		function getWinningPlayers()
		{
			var playersWin = [false,false];
			for (var m:int = 0; m < 2; m++)
			{
				var currentPlayerWins=false;
				for (var i:int = 0; i < 3; i++)
					if ((_board[i][0] == m) && (_board[i][1] == m) && (_board[i][2] == m))
						currentPlayerWins=true;
				for (var j:int = 0; j < 3; j++)
					if ((_board[0][j] == m) && (_board[1][j] == m) && (_board[2][j] == m))
						currentPlayerWins=true;
				if ((_board[0][0] == m) && (_board[1][1] == m) && (_board[2][2] == m))
					currentPlayerWins=true;
				if ((_board[2][0] == m) && (_board[1][1] == m) && (_board[0][2] == m))
					currentPlayerWins=true;
				
				playersWin[m] = currentPlayerWins;
			}
			return playersWin;
		}

		function checkBoard()
		{
			log.info("checking board");
			log.debug(boardToString());
			var playersWin = getWinningPlayers()
			var gameOver=false;
			if (playersWin[0]  && playersWin[1])
			{
				//log.info("DRAW!");
				_view.displayMessage("DRAW!");
				gameOver=true;
				_blockAtStart = !_blockAtStart;
			}
			else if (playersWin[0])
			{
				_view.displayMessage("YOU LOOSE!");
				_blockAtStart=false;
				_numberOfDefeats++;
				gameOver=true;
			}
			else if (playersWin[1])
			{
				_view.displayMessage("YOU WIN!");
				_blockAtStart=true;
				_numberOfVictories++;
				gameOver=true;
			}
			else if (_movesMade == 9)
			{
				_view.displayMessage("NO WINNERS");
				gameOver=true;
				_blockAtStart = !_blockAtStart;
			}

			if (gameOver)
			{
				_view.onGameOver()
			}
		}
	}
}