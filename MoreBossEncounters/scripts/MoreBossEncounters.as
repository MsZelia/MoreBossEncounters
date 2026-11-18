package
{
   import Shared.*;
   import Shared.AS3.*;
   import Shared.AS3.Data.*;
   import Shared.AS3.Events.*;
   import com.adobe.serialization.json.*;
   import fl.motion.*;
   import flash.display.*;
   import flash.events.*;
   import flash.filters.*;
   import flash.geom.*;
   import flash.net.*;
   import flash.system.*;
   import flash.text.*;
   import flash.ui.*;
   import flash.utils.*;
   import utils.*;
   
   public class MoreBossEncounters extends MovieClip
   {
      
      public static const MOD_NAME:String = "MoreBossEncounters";
      
      public static const MOD_VERSION:String = "1.0.0";
      
      public static const FULL_MOD_NAME:String = MOD_NAME + " " + MOD_VERSION;
      
      public static const CONFIG_FILE:String = "../MoreBossEncounters.json";
      
      public static const CONFIG_RELOAD_TIME:uint = 6200;
      
      private static const TITLE_HUDMENU:String = "HUDMenu";
      
      private var topLevel:* = null;
      
      private var configTimer:Timer;
      
      private var lastConfig:String;
      
      private var QuestTrackerProvider:*;
      
      private var EncounterHealthMeterArray:*;
      
      private var encounterObjectives:Array = [];
      
      private var previouslyEncounterQuestActive:Boolean = false;
      
      private var debugQuestId:String = "";
      
      private var isHostile:Boolean = true;
      
      private var icon:int = 0;
      
      private var level:int = 0;
      
      public function MoreBossEncounters()
      {
         super();
         addEventListener(Event.ADDED_TO_STAGE,this.addedToStageHandler,false,0,true);
      }
      
      public static function ShowHUDMessage(message:String) : void
      {
         GlobalFunc.ShowHUDMessage("[" + FULL_MOD_NAME + "] " + message);
      }
      
      public function addedToStageHandler(event:Event) : *
      {
         removeEventListener(Event.ADDED_TO_STAGE,this.addedToStageHandler);
         addEventListener(Event.REMOVED_FROM_STAGE,this.removedFromStageHandler,false,0,true);
         this.topLevel = stage.getChildAt(0);
         if(Boolean(this.topLevel))
         {
            if(getQualifiedClassName(this.topLevel) == TITLE_HUDMENU)
            {
               this.QuestTrackerProvider = BSUIDataManager.GetDataFromClient("QuestTrackerProvider");
               BSUIDataManager.Subscribe("QuestTrackerProvider",this.onQuestTrackerUpdate);
               this.EncounterHealthMeterArray = BSUIDataManager.GetDataFromClient("EncounterHealthMeterArray");
               this.EncounterHealthMeterArray.addEventListener(Event.CHANGE,this.onEncounterHealthMeterUpdate,false,int.MAX_VALUE);
               this.initTimers();
            }
            else
            {
               ShowHUDMessage("Error: mod must be loaded by HUDMenu!");
            }
         }
         else
         {
            ShowHUDMessage("Not added to stage: " + getQualifiedClassName(this.topLevel));
         }
      }
      
      public function removedFromStageHandler(event:Event) : *
      {
         removeEventListener(Event.REMOVED_FROM_STAGE,this.removedFromStageHandler);
         BSUIDataManager.Unsubscribe("QuestTrackerProvider",this.onQuestTrackerUpdate);
         this.EncounterHealthMeterArray.removeEventListener(Event.CHANGE,this.onEncounterHealthMeterUpdate);
         if(this.configTimer)
         {
            this.configTimer.removeEventListener(TimerEvent.TIMER,this.loadConfig);
         }
      }
      
      public function initTimers() : void
      {
         this.configTimer = new Timer(CONFIG_RELOAD_TIME);
         this.configTimer.addEventListener(TimerEvent.TIMER,this.loadConfig,false,0,true);
         this.configTimer.start();
      }
      
      public function loadConfig() : void
      {
         var loaderComplete:Function;
         var ioErrorHandler:Function;
         var url:URLRequest = null;
         var loader:URLLoader = null;
         try
         {
            loaderComplete = function(event:Event):void
            {
               var jsonData:Object;
               var line:uint;
               try
               {
                  if(lastConfig != loader.data)
                  {
                     jsonData = new JSONDecoder(loader.data,false).getValue();
                     MoreBossEncountersConfig.init(jsonData);
                     onQuestTrackerUpdate(QuestTrackerProvider);
                     lastConfig = loader.data;
                  }
               }
               catch(e:JSONParseError)
               {
                  line = e.text.substr(0,e.location).match(/\n/g).length + 1;
                  ShowHUDMessage("Error parsing config: " + e.message + " in line " + line);
               }
               catch(e:Error)
               {
                  ShowHUDMessage("Error initializing config: " + e);
               }
            };
            ioErrorHandler = function(e:IOErrorEvent):void
            {
               ShowHUDMessage("Error loading config: " + e.text);
               MoreBossEncountersConfig.init({});
            };
            url = new URLRequest(CONFIG_FILE);
            loader = new URLLoader();
            loader.load(url);
            loader.addEventListener(Event.COMPLETE,loaderComplete,false,0,true);
            loader.addEventListener(IOErrorEvent.IO_ERROR,ioErrorHandler,false,0,true);
         }
         catch(e:Error)
         {
            ShowHUDMessage("Error loading config: " + e);
         }
      }
      
      public function get isReloadable() : Boolean
      {
         return true;
      }
      
      public function get config() : Object
      {
         return MoreBossEncountersConfig.get();
      }
      
      private function onQuestTrackerUpdate(event:*) : void
      {
         var hasEncounterQuest:Boolean;
         var quest:*;
         var cfgQuest:Object;
         var questIdHex:String;
         var progressObjectives:Array = [];
         try
         {
            if(!config)
            {
               return;
            }
            hasEncounterQuest = false;
            this.debugQuestId = "";
            if(event.data && event.data.quests && event.data.quests.length)
            {
               for each(quest in event.data.quests)
               {
                  questIdHex = ("0000" + quest.questId.toString(16).toUpperCase()).substr(-8,8);
                  if((cfgQuest = config.showQuests[questIdHex]) != null)
                  {
                     this.isHostile = cfgQuest.isHostile;
                     this.icon = cfgQuest.icon;
                     this.level = cfgQuest.level;
                     progressObjectives = quest.objectives.filter(function(obj:*):Boolean
                     {
                        return obj.progress != -1;
                     });
                  }
                  else if(config.showAll && config.hideQuests.indexOf(questIdHex) == -1)
                  {
                     this.isHostile = false;
                     this.icon = 0;
                     this.level = 0;
                     if(config.debug)
                     {
                        this.debugQuestId = questIdHex;
                     }
                     progressObjectives = quest.objectives.filter(function(obj:*):Boolean
                     {
                        return obj.progress != -1;
                     });
                  }
                  if(progressObjectives.length)
                  {
                     this.encounterObjectives = GlobalFunc.CloneObject(progressObjectives);
                     hasEncounterQuest = true;
                     break;
                  }
               }
            }
            if(!hasEncounterQuest)
            {
               this.encounterObjectives = [];
               this.isHostile = true;
               this.icon = 0;
               this.level = 0;
            }
         }
         catch(e:*)
         {
            ShowHUDMessage("onQuestTrackerUpdate error: " + e);
         }
      }
      
      private function onEncounterHealthMeterUpdate(event:FromClientDataEvent) : void
      {
         var i:int;
         var meter:*;
         var objectives:Array;
         var pct:Number;
         var pctStr:String;
         try
         {
            if(!config)
            {
               return;
            }
            if(this.encounterObjectives.length)
            {
               this.previouslyEncounterQuestActive = true;
               for(i in event.data.EncounterHealthMeterArray)
               {
                  meter = event.data.EncounterHealthMeterArray[i];
                  if(this.encounterObjectives.length > i)
                  {
                     if(config.showPercent)
                     {
                        pct = this.encounterObjectives[i].progress * 100;
                        pctStr = pct == int(pct) ? pct.toFixed(0) : pct.toFixed(config.percentDecimals);
                        meter.Name = (this.debugQuestId.length ? "[" + this.debugQuestId + "] " : "") + this.encounterObjectives[i].title + " (" + pctStr + "%)";
                     }
                     else
                     {
                        meter.Name = (this.debugQuestId.length ? "[" + this.debugQuestId + "] " : "") + this.encounterObjectives[i].title;
                     }
                     meter.Percent = this.encounterObjectives[i].progress;
                     meter.EncounterIconType = this.icon;
                     meter.EncounterIconLevel = this.level;
                     meter.IsHostile = this.isHostile;
                  }
                  else
                  {
                     meter.Percent = -1;
                     meter.IsHostile = true;
                  }
               }
            }
            else if(this.previouslyEncounterQuestActive)
            {
               this.previouslyEncounterQuestActive = false;
               for each(meter in event.data.EncounterHealthMeterArray)
               {
                  meter.Percent = -1;
                  meter.IsHostile = true;
               }
            }
            else
            {
               for each(meter in event.data.EncounterHealthMeterArray)
               {
                  if(meter.Percent != -1)
                  {
                     if(config.showPercent)
                     {
                        pct = meter.Percent * 100;
                        pctStr = pct == int(pct) ? pct.toFixed(0) : pct.toFixed(config.percentDecimals);
                        meter.Name = meter.Name.split(" (")[0] + " (" + pctStr + "%)";
                     }
                     else if(meter.Name.indexOf("%)") != -1)
                     {
                        meter.Name = meter.Name.split(/ \(([0-9]*[.])?[0-9]+%\)/)[0];
                     }
                  }
               }
            }
         }
         catch(e:*)
         {
            ShowHUDMessage("onEncounterHealthMeterUpdate error: " + error);
         }
      }
   }
}

