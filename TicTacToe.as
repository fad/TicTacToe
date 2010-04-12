package 
{
	import com.arkavis.log4as.*;
	import com.arkavis.ui.*;
	
	import flash.display.*;
	import flash.events.*;
	import flash.net.*;
	import flash.utils.Timer;
	import flash.utils.setTimeout;

	public class TicTacToe extends EventDispatcher
	{
		protected var log:LogManager = LogManager.GetLogger();

		public static var MOVE_MADE = "MOVE";
		public static var RESULT_DEFEAT = "DEFEAT";
		public static var RESULT_VICTORY = "VICTORY";
		public static var RESULT_DRAW = "DRAW";
		public static var RESULT_BOARD_FULL = "BOARD_FULL";
		public static var START_GAME = "START";
		public static var RESTART_GAME = "RESTART";
		public static var GAME_OVER = "GAME_OVER";
		public static var SERVER_READY = "SERVER_READY";
		public static var READY = "READY";
		public static var JOINING = "JOINING";
		
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
		public var _playerId:int = -1;

		public var invitationCode:String = "";

		//public methods
		
		public function TicTacToe()
		{
		}
		
		public function init()
		{
			_movesMade = 0;
			
			if  (invitationCode != "")
			{
				dispatchEvent(new Event(TicTacToe.JOINING));
				joinGame();
				
				var timer:Timer = new Timer(1000,1);
				timer.addEventListener("timer", joinExistingGame);
				timer.start();
			}
		}
		
		function joinExistingGame(e:TimerEvent)
		{
			log.info("JOINING: "+invitationCode);
			setupIncomingStream(invitationCode);
			invitationCode = "";
		}
		
		public function startAsServer()
		{
			_playerId = 1;
			_blockAtStart = false;
			setupConnection();
		}

		public function joinGame()
		{
			_playerId = 2;
			_blockAtStart = true;
			setupConnectionForJoining();
		}
		

		public function setupConnectionForJoining():void
		{
			//SETUP CONNECTION TO STRATUS
			log.info("Connecting");
			_netConnection = new NetConnection();
			_netConnection.addEventListener(NetStatusEvent.NET_STATUS, netConnectionHandler);
			_netConnection.connect(RTMFP_END_POINT + ADOBE_DEV_KEY + "/");
		}

		public function restartAllClients()
		{
			sendMessage("restart");
			restartGame();
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

		public function makeMove(tileName)
		{
			setTile(tileName, true);
			sendMessage("move:"+tileName);
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
			dispatchEvent(new Event(TicTacToe.READY));
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
		//private methods
		
		private function startGame()
		{
			log.info("starting game");
			log.debug("_playerId="+_playerId);
			log.debug("_blockAtStart="+_blockAtStart);
			dispatchEvent(new StartEvent(TicTacToe.START_GAME, _blockAtStart));
		}
	
		private function restartGame()
		{
			log.info("restarting game");
			for (var i:int = 0; i < 3; i++)
				for (var j:int = 0; j < 3; j++)
					_board[i][j] = null;
		
			dispatchEvent(new Event(TicTacToe.RESTART_GAME));
			init();
			startGame();
		}

		private function setupConnection():void
		{
			//SETUP CONNECTION TO STRATUS
			log.info("Connecting");
			_netConnection = new NetConnection();
			_netConnection.addEventListener(NetStatusEvent.NET_STATUS, netConnectionHandler);
			_netConnection.connect(RTMFP_END_POINT + ADOBE_DEV_KEY + "/");
		}
		
		private function netConnectionHandler(e:NetStatusEvent):void
		{
			if (e.info.code == "NetConnection.Connect.Success")
			{
				log.info("_playerId="+_playerId);
				setupOutgoingStream(_playerId == 2);
			}
		}

		private function setupOutgoingStream(joining = false):void
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
				
				startGame();
				return true;
			};
			_streamOutgoing.client = out;
			_streamOutgoing.publish("TicTacToe");

			if (!joining)
				dispatchEvent(new ServerReadyEvent(TicTacToe.SERVER_READY,_netConnection.nearID));
		}

		private function sendMessage(m)
		{
			_streamOutgoing.send("receive",m);
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
			
			dispatchEvent(new MoveMadeEvent(TicTacToe.MOVE_MADE, col, row, byMyself));
			checkBoard();
		}
		
		private function boardToString()
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
		
		private function getWinningPlayers()
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

		private function checkBoard()
		{
			log.info("checking board");
			log.debug(boardToString());
			var playersWin = getWinningPlayers()
			var gameOver = false;
			var result;
			
			if (playersWin[0]  && playersWin[1])
			{
				_blockAtStart = !_blockAtStart;
				dispatchEvent(new GameOverEvent(TicTacToe.GAME_OVER, TicTacToe.RESULT_DRAW));
			}
			else if (playersWin[0])
			{
				_blockAtStart = false;
				_numberOfDefeats++;
				dispatchEvent(new GameOverEvent(TicTacToe.GAME_OVER, TicTacToe.RESULT_DEFEAT));
			}
			else if (playersWin[1])
			{
				_blockAtStart = true;
				_numberOfVictories++;
				dispatchEvent(new GameOverEvent(TicTacToe.GAME_OVER, TicTacToe.RESULT_VICTORY));
			}
			else if (_movesMade == 9)
			{
				_blockAtStart = !_blockAtStart;
				dispatchEvent(new GameOverEvent(TicTacToe.GAME_OVER, TicTacToe.RESULT_BOARD_FULL));
			}
		}
	}
}