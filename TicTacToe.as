package 
{
	import com.arkavis.log4as.*;
	import com.arkavis.ui.*;
	
	import flash.display.*;
	import flash.events.*;
	import flash.net.*;
	import flash.utils.Timer;

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
		
		private var _movesMade:int;
		private var _board = [[null,null,null],[null,null,null],[null,null,null]];
		private var _blockAtStart = false;
		public var _numberOfVictories:Number = 0;
		public var _numberOfDefeats:Number = 0;
		public var _playerId:int = -1;

		public var invitationCode:String = "";

		public function set Connection(c:IConnection)
		{
			_connection = c;	
			_connection.Model = this;
			_connection.addEventListener(ConnectionStatus.READY, onConnectionReady);
			_connection.addEventListener(ConnectionStatus.SERVER_READY, onConnectionServerReady);
		}
		var _connection:IConnection;

		private function onConnectionReady(e:Event)
		{
			dispatchEvent(new Event(TicTacToe.READY));
		}

		private function onConnectionServerReady(e:ServerReadyEvent)
		{
			dispatchEvent(new ServerReadyEvent(TicTacToe.SERVER_READY,e.nearId));
		}

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
			_connection.setupConnection();
		}

		public function joinGame()
		{
			_playerId = 2;
			_blockAtStart = true;
			setupConnectionForJoining();
		}
		

		public function setupConnectionForJoining():void
		{
			_connection.setupConnectionForJoining();
		}
		
		public function setupIncomingStream(id:String):void
		{
			_connection.setupIncomingStream(id);
		}
		
		//ok methods
		
		public function restartAllClients()
		{
			_connection.sendMessage("restart");
			restartGame();
		}

		public function makeMove(tileName)
		{
			setTile(tileName, true);
			_connection.sendMessage("move:"+tileName);
		}	
		
	
		//private methods
		
		public function startGame()
		{
			log.info("starting game");
			log.debug("_playerId="+_playerId);
			log.debug("_blockAtStart="+_blockAtStart);
			dispatchEvent(new StartEvent(TicTacToe.START_GAME, _blockAtStart));
		}
	
		public function restartGame()
		{
			log.info("restarting game");
			for (var i:int = 0; i < 3; i++)
				for (var j:int = 0; j < 3; j++)
					_board[i][j] = null;
		
			dispatchEvent(new Event(TicTacToe.RESTART_GAME));
			init();
			startGame();
		}
		
		public function setTile(tileName, byMyself)
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