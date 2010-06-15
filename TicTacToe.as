package 
{
	import com.arkavis.log4as.*;
	import com.arkavis.ui.*;
	
	import flash.display.*;
	import flash.events.*;
	import flash.net.*;
	import flash.utils.Timer;
	import flash.external.ExternalInterface;

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
		
		private var _blockAtStart = false;
		public var _numberOfVictories:Number = 0;
		public var _numberOfDefeats:Number = 0;
		public var _playerId:int = -1;

		public var invitationCode:String = "";
		public var invitationBaseUrl:String = "";
		public var gameId:String = "";
		
		private var model:TicTacToeModel;

		public function set Connection(c:IConnection)
		{
			_connection = c;	
			_connection.Game = this;
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
			ExternalInterface.call("sendGameId",e.nearId);
			dispatchEvent(new ServerReadyEvent(TicTacToe.SERVER_READY,e.nearId));
		}

		//public methods
		
		public function TicTacToe()
		{
			model = new TicTacToeModel();
			model.addEventListener(TicTacToeModel.GAME_OVER, onGameOver);
			model.addEventListener(TicTacToe.MOVE_MADE, onMoveMade);
		}
		
		private function onMoveMade(e:MoveMadeEvent)
		{
			dispatchEvent(new MoveMadeEvent(TicTacToe.MOVE_MADE, e.column, e.row, e.byMyself));
		}
		private function onGameOver(e:GameOverEvent)
		{
			log.info("onGameOver - Result = "+e.result);
			switch (e.result)
			{
				case TicTacToeModel.RESULT_BOARD_FULL:
					_blockAtStart = !_blockAtStart;
					dispatchEvent(new GameOverEvent(TicTacToe.GAME_OVER, TicTacToe.RESULT_BOARD_FULL));
					break;
				case TicTacToeModel.RESULT_DRAW:
					_blockAtStart = !_blockAtStart;
					dispatchEvent(new GameOverEvent(TicTacToe.GAME_OVER, TicTacToe.RESULT_DRAW));
					break;
				case TicTacToeModel.RESULT_PLAYER_ONE_WINS:
					addToScore([1,0]);
					break;
				case TicTacToeModel.RESULT_PLAYER_TWO_WINS:
					addToScore([0,1]);
					break;
			}
		}
		
		private function addToScore(playerWins:Array)
		{
			if(playerWins[_playerId])
			{
				_blockAtStart = true;
				_numberOfVictories++;
				dispatchEvent(new GameOverEvent(TicTacToe.GAME_OVER, TicTacToe.RESULT_VICTORY));
			}
			else
			{
				_blockAtStart = false;
				_numberOfDefeats++;
				dispatchEvent(new GameOverEvent(TicTacToe.GAME_OVER, TicTacToe.RESULT_DEFEAT));
			}
		}
		
		public function init()
		{
			model.reset();
	
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
			model.reset();
		
			dispatchEvent(new Event(TicTacToe.RESTART_GAME));
			init();
			startGame();
		}
		
		public function setTile(tileName, byMyself)
		{
			log.info("tileName="+tileName);

			var row = tileName.substring(1,2);
			var col = tileName.substring(2);

			log.info("t="+tileName+",r="+row+",c="+col);
			var mark = byMyself ? 1:0;
			//model._board[row][col] = mark;
			if (byMyself)
				model.setTile(row,col,_playerId);
			else
			{
				var enemyId = (_playerId == 0) ? 1 : 0;
				model.setTile(row,col,enemyId);
			}
				
			//model.checkBoard();
		}
		
	}
}