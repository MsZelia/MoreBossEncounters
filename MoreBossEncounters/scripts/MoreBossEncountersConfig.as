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
         config.hideQuests = config.hideQuests != null && config.hideQuests is Array ? config.hideQuests : [];
         for(var i in config.hideQuests)
         {
            config.hideQuests[i] = config.hideQuests[i].toUpperCase();
         }
         config.showQuests = config.showQuests != null ? config.showQuests : {};
         for each(var q in config.showQuests)
         {
            q.isHostile = Boolean(q.isHostile);
         }
         _config = config;
         return _config;
      }
   }
}

