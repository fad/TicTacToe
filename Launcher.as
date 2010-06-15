﻿package{	import com.arkavis.Console;	import com.arkavis.UrlHelper;	import com.arkavis.log4as.LogManager;	import com.arkavis.log4as.TraceLogger;		import flash.display.LoaderInfo;	import flash.display.MovieClip;	import flash.external.ExternalInterface;		public class Launcher extends MovieClip	{		protected var log:LogManager = LogManager.GetLogger();		var game;				public function Launcher()		{			ExternalInterface.addCallback("connectToGame", connectToGame);					var consoleConfig = {width:stage.stageWidth,height:300,color:0x111111,fontColor:0xFFFFFF,fontSize:14};			var console:Console = new Console(consoleConfig);			game = new TicTacToe();			game.Connection = new StratusConnection();			var view = new SimpleView(game);			addChild(view);			view.buildUI();						console.setSystem(game);			addChild(console);			//console.maximize();			//console.hide();						LogManager.LogLevel = LogManager.LogLevels.DEBUG;			LogManager.addLogger(new TraceLogger());			LogManager.addLogger(console);			log.info("initializing game");						var params:Object = LoaderInfo(this.root.loaderInfo).parameters;			var invitationCode = params["invite"];			log.info("invite="+invitationCode);			if (invitationCode != undefined)				game.invitationCode = invitationCode;			var siteUrl = params["siteUrl"];			log.info("siteUrl="+siteUrl);			if (siteUrl != undefined)				game.invitationBaseUrl = siteUrl;			var gameId = params["gameId"];			log.info("gameId="+gameId);			if (gameId != undefined)				game.gameId = gameId;			var siteId = params["siteId"];			log.info("siteId="+siteId);						game.init();				view.init();			}				// to be called from js		public function connectToGame(id)		{			log.info("connecting to game");			log.info("game id="+id);			game.invitationCode = id;			game.init();		}	}}