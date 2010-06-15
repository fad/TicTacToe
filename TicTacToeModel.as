package
{
	import com.arkavis.log4as.*;
	
	import flash.events.EventDispatcher;
	
	public class TicTacToeModel extends EventDispatcher
	{
		public static var GAME_OVER = "GAME_OVER";
		public static var RESULT_PLAYER_ONE_WINS = "RESULT_PLAYER_ONE_WINS";
		public static var RESULT_PLAYER_TWO_WINS = "RESULT_PLAYER_TWO_WINS";
		public static var RESULT_DRAW = "RESULT_DRAW";
		public static var RESULT_BOARD_FULL = "RESULT_BOARD_FULL";
		
		protected var log:LogManager = LogManager.GetLogger();
		
		protected var _board = [[null,null,null],[null,null,null],[null,null,null]];
		protected var _movesMade:int = 0;
		
		public function TicTacToeModel()
		{
		}

		public function reset()
		{
			_board = [[null,null,null],[null,null,null],[null,null,null]];
			_movesMade = 0;
		}

		public function setTile(row:Number, col:Number, playerId:Number)
		{		
			log.debug("model-setTile");	
			_movesMade++;
			_board[row][col] = playerId;	
			dispatchEvent(new MoveMadeEvent(TicTacToe.MOVE_MADE, col, row, playerId));
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
		
		private function getWinningPlayers():Array
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

		public function checkBoard()
		{
			log.info("model-checkBoard");
			log.debug(boardToString());
			var playersWin = getWinningPlayers()
			var gameOver = false;
			var result;
			
			if (playersWin[0]  && playersWin[1])
			{
				dispatchEvent(new GameOverEvent(TicTacToeModel.GAME_OVER, TicTacToeModel.RESULT_DRAW));
			}
			else if (playersWin[0])
			{
				dispatchEvent(new GameOverEvent(TicTacToeModel.GAME_OVER, TicTacToeModel.RESULT_PLAYER_ONE_WINS));
			}
			else if (playersWin[1])
			{
				dispatchEvent(new GameOverEvent(TicTacToeModel.GAME_OVER, TicTacToeModel.RESULT_PLAYER_TWO_WINS));
			}
			else if (_movesMade == 9)
			{
				dispatchEvent(new GameOverEvent(TicTacToeModel.GAME_OVER, TicTacToeModel.RESULT_BOARD_FULL));
			}
		}
	}
}