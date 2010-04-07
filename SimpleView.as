package
{
	import com.arkavis.log4as.*;
	import com.arkavis.ui.*;
	
	import flash.display.MovieClip;
	import flash.events.MouseEvent;
	import flash.text.TextField;

	public class SimpleView extends MovieClip
	{	
		protected var log:LogManager = LogManager.GetLogger();
		
		private var boardTiles = new Array();
		private var _playField:Widget;
		private var _genericMessagePanel:GenericMessagePanel;
		private var _joiningPanel:JoiningPanel;
		private var _startGamePanel:StartGamePanel;
		private var _blockMask;
		private var _restartBtn;
		private var _menuPanel;
		private var _scoreTF;
		private var _tileSize = 120;
		var _model;
		
		public function SimpleView(model)
		{
			log.info("initializing view - model="+model);
			_model = model;
			super();
		}
		
		public function buildUI()
		{
			if (stage == null)
				throw Error("stage is null. Probably view hasn't been added to the stage yet.");
				
			_playField = new Widget();
			createBoard(_playField,_tileSize,0);
			this.addChild(_playField);
			_playField.setPosition(StagePositions.CENTER);
		
			_menuPanel = new MenuPanel();
			this.addChild(_menuPanel);
			_menuPanel.setPosition(StagePositions.CENTER);
			
			_genericMessagePanel = new GenericMessagePanel();
			this.addChild(_genericMessagePanel);
			_genericMessagePanel.setPosition(StagePositions.CENTER);
			
			_startGamePanel = new StartGamePanel();
			this.addChild(_startGamePanel);
			_startGamePanel.setPosition(StagePositions.CENTER);
			
			_joiningPanel = new JoiningPanel();
			_joiningPanel.keyTF.text = "";
			this.addChild(_joiningPanel);
			_joiningPanel.setPosition(StagePositions.CENTER);
			
			_scoreTF = new TextField();
			_scoreTF.x = 300;
			_scoreTF.y = 10;
			_scoreTF.text = "0:0";
			this.addChild(_scoreTF);
			//_scoreTF.setPosition(StagePositions.CENTER_TOP);
		
			_blockMask = new MovieClip();
			_blockMask.graphics.beginFill(0xFF0000);  
			_blockMask.graphics.drawRect(0, 0, stage.stageWidth,stage.stageHeight);
			_blockMask.graphics.endFill();
			_blockMask.alpha = 0;
			this.addChild(_blockMask);
			//_blockMask.setPosition(StagePositions.CENTER);
			
			_restartBtn = new RestartButton();
			_restartBtn.x = 400;
			_restartBtn.y = 400;
			this.addChild(_restartBtn);
			//_restartBtn.setPosition(StagePositions.CENTER);
			
			_menuPanel.startGameBtn.addEventListener(MouseEvent.CLICK, startGameClickHandler, false, 0, true);
			_menuPanel.joinGameBtn.addEventListener(MouseEvent.CLICK, joinGameClickHandler, false, 0, true);
			_joiningPanel.okBtn.addEventListener(MouseEvent.CLICK, okBtnClickHandler, false, 0, true);
			_joiningPanel.closeBtn.addEventListener(MouseEvent.CLICK, joiningCloseBtnClickHandler, false, 0, true);
			_startGamePanel.closeBtn.addEventListener(MouseEvent.CLICK, startGamePanelCloseBtnClickHandler, false, 0, true);
			_restartBtn.addEventListener(MouseEvent.CLICK, restartBtnClickHandler, false, 0, true);
		}

		private function createBoard(container, tileSize = 100, borderSize = 0)
		{
			for (var i:int = 0; i < 3; i++)
			{
				var a = new Array();
				boardTiles.push(a);

				for (var j:int = 0; j < 3; j++)
				{
					var tile:Tile = new Tile();
					tile.width = _tileSize;
					tile.height = _tileSize;
					tile.x = i * tile.width;
					tile.y = j * tile.height;
					log.info("tile.x="+tile.x);
					container.addChild(tile);
					tile.name = "t" + j.toString() + i.toString();
					tile.addEventListener(MouseEvent.CLICK, boardClickHandler, false, 0, true);
					a.push(tile);
				}
			}
			
			var board:MovieClip = new MovieClip();
			board.graphics.lineStyle(1);
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

	
		function init()
		{
			_startGamePanel.visible = false;
			_genericMessagePanel.visible = false;
			_joiningPanel.visible = false;
			_blockMask.visible = false;
			_restartBtn.visible = false;
		}

		 function displayMessage(m)
		{
			_genericMessagePanel.messageTF.text = m;
			_genericMessagePanel.show();
		}

		 function restartBtnClickHandler(e:MouseEvent)
		{
			_model.restartGame();
			_model.sendMessage("restart");
		}
	
		function startGame(block)
		{
			_playField.visible = true;			
			if (block)
				toggleState();
		}

		function cleanBoard()
		{
			for (var i:int = 0; i < 3; i++)
			{
				for (var j:int = 0; j < 3; j++)
				{
					boardTiles[i][j].visible = true;
					var c = _playField.getChildByName("c" + i.toString() + j.toString());
					log.debug("i="+i+" j="+j+" child:"+c);
					if (c != null)
						_playField.removeChild(c);
				}
			}
		}

		function startGameClickHandler(e:MouseEvent)
		{
		//	_blockAtStart = false;
			_startGamePanel.show();
			_model.startAsServer();
		}
		
		function joinGameClickHandler(e:MouseEvent)
		{
			_joiningPanel.visible = true;
			stage.focus = _joiningPanel.keyTF;
			_joiningPanel.keyTF.setSelection( 0, _joiningPanel.keyTF.text.length);
			
			_model.joinGame();
		}
		
		function okBtnClickHandler(e:MouseEvent)
		{
			log.info(_joiningPanel.keyTF.text);
			_model.setupIncomingStream(_joiningPanel.keyTF.text);
		}

		function joiningCloseBtnClickHandler(e:MouseEvent)
		{
			_joiningPanel.hide();
		}

		function startGamePanelCloseBtnClickHandler(e:MouseEvent)
		{
			_startGamePanel.hide();
		}

		function boardClickHandler(e:MouseEvent)
		{
			//e.target.visible = false;
			_model.makeMove(e.target.name);
		}

		function displayId(id)
		{
			_startGamePanel.keyTF.text = id;
			stage.focus = _startGamePanel.keyTF;
			_startGamePanel.keyTF.setSelection( 0, _startGamePanel.keyTF.text.length);
		}
	
		function showPlayField()
		{
			_startGamePanel.visible = false;
			_joiningPanel.visible = false;
			_menuPanel.visible = false;
		}
		
		function setTile(col, row, byMyself)
		{
			var tile = boardTiles[col][row];
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
	
			toggleState();
		}

		function toggleState()
		{
			_blockMask.visible = !_blockMask.visible;
			log.info("_blockMask.visible = "+_blockMask.visible);
			_genericMessagePanel.messageTF.text="Waiting for opponent";
			_genericMessagePanel.visible = _blockMask.visible;
		}
		
		function onGameOver()
		{
			_blockMask.visible = true;
			_restartBtn.visible = true;
			displayScore(_model._numberOfVictories, _model._numberOfDefeats);
		}
		
		function displayScore(v, d)
		{
			_scoreTF.text = v.toString()+":"+d.toString();
		}
	}
}