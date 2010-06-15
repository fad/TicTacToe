package
{
	import flash.events.Event;

	public class GameOverEvent extends Event
	{	
		public var result:String;
		
		public function GameOverEvent(type:String, result:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			this.result = result;
			super(type, bubbles, cancelable);
		}
	}
}