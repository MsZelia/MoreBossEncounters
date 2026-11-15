package
{
   import utils.Parser;
   
   public class MoreBossEncountersConfig
   {
      
      private static var _config:Object;
      
      public function MoreBossEncountersConfig()
      {
         super();
      }
      
      public static function get() : Object
      {
         return _config;
      }
      
      public static function init(jsonObject:*) : Object
      {
         var config:* = jsonObject;
         config.showPercent = Boolean(config.showPercent);
         config.percentDecimals = Parser.parsePositiveNumber(config.percentDecimals,0);
         config.showAll = Boolean(config.showAll);
         _config = config;
         return _config;
      }
   }
}

