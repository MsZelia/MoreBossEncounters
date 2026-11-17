package
{
   import Shared.GlobalFunc;
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
         config.showQuests = config.showQuests != null ? config.showQuests : {
            "006AD506":{
               "isHostile":true,
               "icon":1,
               "level":3
            },
            "00583D14":{
               "isHostile":true,
               "icon":1,
               "level":3
            }
         };
         for each(var q in config.showQuests)
         {
            q.isHostile = Boolean(q.isHostile);
            q.icon = GlobalFunc.Clamp(Parser.parseNumber(q.icon,0),0,2);
            if(q.icon == 0)
            {
               q.level = 0;
            }
            else
            {
               q.level = GlobalFunc.Clamp(Parser.parseNumber(q.level,0),0,3);
            }
            if(q.level == 0)
            {
               q.icon = 0;
            }
         }
         _config = config;
         return _config;
      }
   }
}

