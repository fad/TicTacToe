package
{
	import flash.events.Event;

	public class StartEvent extends Event
	{
		public var blockAtStart:Boolean;
		
		public function StartEvent(type:String, blockAtStart:Boolean, bubbles:Boolean=false, cancelable:Boolean=false)
		{	
			this.blockAtStart = blockAtStart;
			super(type, bubbles, cancelable);
		}
		
	}
}