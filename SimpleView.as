package
{
	import com.arkavis.log4as.*;
	import com.arkavis.ui.*;
	import com.arkavis.UrlHelper;
	
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.MouseEvent;

	public class SimpleView extends MovieClip
	{	
		protected var log:LogManager = LogManager.GetLogger();
		
		public var _boardTiles = new Array();
		public var _playField:Widget;
		public var _genericMessagePanel:GenericMessagePanel;
		public var _joiningPanel:JoiningPanel;
		public var _startGamePanel:StartGamePanel;
		public var _blockMask;
		public var _restartBtn;
		public var _menuPanel;
		public var _scoreTF;
		public var _scoresWidget;
		public var _tileSize = 120;
		public var _model:TicTacToe;
		
		public function SimpleView(model)
		{
			log.info("initializing view - model = "+model);
			_model = model;
			_model.addEventListener(TicTacToe.MOVE_MADE, onMoveMade);
			_model.addEventListener(TicTacToe.GAME_OVER, onGameOver);
			_model.addEventListener(TicTacToe.SERVER_READY, onServerReady);
			_model.addEventListener(TicTacToe.RESTART_GAME, onRestart);
			_model.addEventListener(TicTacToe.START_GAME, onStart);
			_model.addEventListener(TicTacToe.READY, onReady);
			_model.addEventListener(TicTacToe.JOINING, onJoining);
			super();
		}
		
		// event handling
		
		private function onGameOver(e:GameOverEvent)
		{	
			log.debug("view-onGameOver");
			var message = "";
			switch (e.result)
			{
				case TicTacToe.RESULT_BOARD_FULL:
					message = "board full!";
					break;
				case TicTacToe.RESULT_DRAW:
					message = "DRAW!";
					break;
				case TicTacToe.RESULT_VICTORY:
					message = "YOU WIN!";
					break;
				case TicTacToe.RESULT_DEFEAT:
					message = "YOU LOOSE!";
					break;
			}
			displayMessage(message);
			
			_blockMask.visible = true;
			_restartBtn.visible = true;
			if (this._model._playerId == 1)
				displayScore(_model._numberOfVictories, _model._numberOfDefeats);
			else
				displayScore(_model._numberOfDefeats, _model._numberOfVictories);
		}
		
		private function onServerReady(e:ServerReadyEvent)
		{	
			displayId(e.nearId);	
		}
		
		private function onMoveMade(e:MoveMadeEvent)
		{
			log.debug("view-onMoveMade");
			setTile(e.column, e.row, e.byMyself);		
		}
		
		private function onStart(e:StartEvent)
		{
			log.info("onStart block="+e.blockAtStart); 
			_playField.visible = true;	
			_restartBtn.visible = false;
			_scoresWidget.show();
					
			if (e.blockAtStart)
				blockView();
			else
				unblockView();
		}
		
		private function onReady(e:Event)
		{
			showPlayField();
		}
		
		private function onJoining(e:Event)
		{
			this.displayMessage("Joining..");
		}
		
		private function onRestart(e:Event)
		{
			cleanBoard();
		}
		
		private function okBtnClickHandler(e:MouseEvent)
		{
			log.info(_joiningPanel.keyTF.text);
			_model.setupIncomingStream(_joiningPanel.keyTF.text);
		}
		
		//public methods
		
		public function init()
		{log.info("1111");
			_startGamePanel.visible = false;
			_genericMessagePanel.visible = false;
			_joiningPanel.visible = false;
			_blockMask.visible = false;
			_restartBtn.visible = false;
		}
		
		public function buildUI()
		{
			if (stage == null)
				throw Error("stage is null. Probably view hasn't been added to the stage yet.");
				
			_playField = new Widget();
			createBoard(_playField,_tileSize,0);
			addChild(_playField);
			_playField.setPosition(StagePositions.CENTER);
		
			_menuPanel = new MenuPanel();
			addChild(_menuPanel);
			_menuPanel.setPosition(StagePositions.CENTER);
			
			_genericMessagePanel = new GenericMessagePanel();
			addChild(_genericMessagePanel);
			_genericMessagePanel.setPosition(StagePositions.CENTER);
			
			_startGamePanel = new StartGamePanel();
			addChild(_startGamePanel);
			_startGamePanel.setPosition(StagePositions.CENTER);
			
			_joiningPanel = new JoiningPanel();
			_joiningPanel.keyTF.text = "";
			addChild(_joiningPanel);
			_joiningPanel.setPosition(StagePositions.CENTER);
			_menuPanel.joinGameBtn.visible = false;
		
			_blockMask = new MovieClip();
			_blockMask.graphics.beginFill(0xFF0000);  
			_blockMask.graphics.drawRect(0, 0, stage.stageWidth,stage.stageHeight);
			_blockMask.graphics.endFill();
			_blockMask.alpha = 0;
			addChild(_blockMask);
			//_blockMask.setPosition(StagePositions.CENTER);
			
			_restartBtn = new RestartButton();
			_restartBtn.x = 400;
			_restartBtn.y = 400;
			addChild(_restartBtn);
			//_restartBtn.setPosition(StagePositions.CENTER);
			
			_scoresWidget = new ScoresWidget();
			_scoresWidget.x = 10;
			_scoresWidget.y = 400;
			_scoresWidget.hide();
			addChild(_scoresWidget);
			
			_menuPanel.startGameBtn.addEventListener(MouseEvent.CLICK, startGameClickHandler, false, 0, true);
			_menuPanel.joinGameBtn.addEventListener(MouseEvent.CLICK, joinGameClickHandler, false, 0, true);
			_joiningPanel.okBtn.addEventListener(MouseEvent.CLICK, okBtnClickHandler, false, 0, true);
			_joiningPanel.closeBtn.addEventListener(MouseEvent.CLICK, joiningCloseBtnClickHandler, false, 0, true);
			_startGamePanel.closeBtn.addEventListener(MouseEvent.CLICK, startGamePanelCloseBtnClickHandler, false, 0, true);
			_restartBtn.addEventListener(MouseEvent.CLICK, restartBtnClickHandler, false, 0, true);
		}
		
		//private methods

		private function createBoard(container, tileSize = 100, borderSize = 0)
		{
			for (var i:int = 0; i < 3; i++)
			{
				var a = new Array();
				_boardTiles.push(a);

				for (var j:int = 0; j < 3; j++)
				{
					var tile:Tile = new Tile();
					tile.width = _tileSize;
					tile.height = _tileSize;
					tile.x = i * tile.width;
					tile.y = j * tile.height;
					log.info("tile.x = "+tile.x);
					container.addChild(tile);
					tile.name = "t" + j.toString() + i.toString();
					tile.addEventListener(MouseEvent.CLICK, boardClickHandler, false, 0, true);
					a.push(tile);
				}
			}
			
			var board:MovieClip = new MovieClip();
			board.graphics.lineStyle(3);
			board.graphics.moveTo(borderSize+tileSize,borderSize);
			board.graphics.lineTo(borderSize+tileSize, borderSize+tileSize*3);
			board.graphics.moveTo(borderSize+2*tileSize,borderSize);
			board.graphics.lineTo(borderSize+2*tileSize, borderSize+tileSize*3);

			board.graphics.moveTo(borderSize, borderSize+tileSize);
			board.graphics.lineTo(borderSize+tileSize*3, borderSize+tileSize);
			board.graphics.moveTo(borderSize, borderSize+2*tileSize);
			board.graphics.lineTo(borderSize+tileSize*3, borderSize+2*tileSize);

			container.addChild(board);
			container.visible = false;
		}

		private function displayMessage(m)
		{	
			_genericMessagePanel.messageTF.text = m;
			_genericMessagePanel.visible = true;
		}

		private function restartBtnClickHandler(e:MouseEvent)
		{
			_model.restartAllClients();
		}
	
		private function cleanBoard()
		{
			for (var i:int = 0; i < 3; i++)
			{
				for (var j:int = 0; j < 3; j++)
				{
					_boardTiles[i][j].visible = true;
					var c = _playField.getChildByName("c" + i.toString() + j.toString());
					log.debug("i="+i+" j="+j+" child:"+c);
					if (c != null)
						_playField.removeChild(c);
				}
			}
		}

		private function startGameClickHandler(e:MouseEvent)
		{
		//	_blockAtStart = false;
			_startGamePanel.show();
			_model.startAsServer();
		}
		
		private function joinGameClickHandler(e:MouseEvent)
		{
			_joiningPanel.visible = true;
			stage.focus = _joiningPanel.keyTF;
			_joiningPanel.keyTF.setSelection( 0, _joiningPanel.keyTF.text.length);
			
			_model.joinGame();
		}

		private function joiningCloseBtnClickHandler(e:MouseEvent)
		{
			_joiningPanel.hide();
		}

		private function startGamePanelCloseBtnClickHandler(e:MouseEvent)
		{
			_startGamePanel.hide();
		}

		private function boardClickHandler(e:MouseEvent)
		{
			_model.makeMove(e.target.name);
		}

		private function displayId(id)
		{
			_startGamePanel.keyTF.text = UrlHelper.createUrl(_model.invitationBaseUrl,{invite:id, game:_model.gameId});
			// _model.invitationBaseUrl+"?invite="+id+"&game="+_model.gameId; 
			stage.focus = _startGamePanel.keyTF;
			_startGamePanel.keyTF.setSelection( 0, _startGamePanel.keyTF.text.length);
		}
	
		private function showPlayField()
		{
			_startGamePanel.visible = false;
			_joiningPanel.visible = false;
			_menuPanel.visible = false;
		}
		
		private function setTile(col, row, byMyself)
		{
			log.debug("setTile:"+col+","+row+","+byMyself);
			var tile = _boardTiles[col][row];
			log.info("tile="+tile);
			tile.visible = false;
			log.info("_playerId="+_model._playerId+" byMyself="+byMyself);
			var c;
			if (((_model._playerId == 2) && byMyself) || ((_model._playerId == 1) && !byMyself))
				c = new Circle();
			else
				c = new Cross();
				
			c.width = _tileSize;
			c.height = _tileSize;
			c.x = tile.x;
			c.y = tile.y;
			_playField.addChild(c);
			c.name = "c" + col.toString() + row.toString();
	
			toggleBlockState();
		}

		private function toggleBlockState()
		{
			_blockMask.visible = !_blockMask.visible;
			log.info("_blockMask.visible = "+_blockMask.visible);
			_genericMessagePanel.messageTF.text = "Waiting for opponent";
			_genericMessagePanel.visible = _blockMask.visible;
		}
		
		private function blockView()
		{
			displayMessage("Waiting for opponent");
			_blockMask.visible = true;
		}
		
		private function unblockView()
		{
			_genericMessagePanel.visible = false;
			_blockMask.visible = false;
		}
		
		private function displayScore(v, d)
		{
			this._scoresWidget.player1ScoreTF.text = v.toString();
			this._scoresWidget.player2ScoreTF.text = d.toString();
		}
	}
}