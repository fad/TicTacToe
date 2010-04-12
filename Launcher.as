package
{
	import com.arkavis.Console;
	import com.arkavis.log4as.LogManager;
	import com.arkavis.log4as.TraceLogger;
	
	import flash.display.LoaderInfo;
	import flash.display.MovieClip;
	
	public class Launcher extends MovieClip
	{
		protected var log:LogManager = LogManager.GetLogger();
		
		public function Launcher()
		{
			var consoleConfig = {width:stage.stageWidth,height:150,color:0x111111,fontColor:0xFFFFFF,fontSize:14};
			var console:Console = new Console(consoleConfig);

			var model = new TicTacToe();
			model.Connection = new StratusConnection();
			var view = new SimpleView(model);
			addChild(view);
			view.buildUI();
			
			console.setSystem(model);
			addChild(console);
			console.minimize();
			//console.hide();
			
			LogManager.LogLevel = LogManager.LogLevels.DEBUG;
			LogManager.addLogger(new TraceLogger());
			LogManager.addLogger(console);
			log.info("initializing game");
			
			var params:Object = LoaderInfo(this.root.loaderInfo).parameters;
			var invitationCode = params["invite"];
			log.info("invite="+invitationCode);
			if (invitationCode != undefined)
				model.invitationCode = invitationCode;
			
			model.init();	
			view.init();		
				
		}
	}
}