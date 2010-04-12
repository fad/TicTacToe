package 
{
    import flash.events.Event;
   
    public class ServerReadyEvent extends Event
    {
        public var nearId:String;
     
        public function ServerReadyEvent(type:String, nearId:String, bubbles:Boolean = false, cancelable:Boolean = false)
        {
            super(type, bubbles, cancelable);     
            this.nearId = nearId;
        }
   
        public override function clone():Event
        {
            return new ServerReadyEvent(type, this.nearId, bubbles, cancelable);
        }
       
        public override function toString():String
        {
            return formatToString("ServerReadyEvent", "nearId", "type", "bubbles", "cancelable");
        }
     }
}