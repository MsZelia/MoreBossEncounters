package
{
   import Shared.*;
   import Shared.AS3.*;
   import Shared.AS3.Data.*;
   import Shared.AS3.Events.*;
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
   
   public class MoreBossEncounters extends MovieClip
   {
      
      public static const MOD_NAME:String = "MoreBossEncounters";
      
      public static const MOD_VERSION:String = "1.0.0";
      
      public static const FULL_MOD_NAME:String = MOD_NAME + " " + MOD_VERSION;
      
      private static const TITLE_HUDMENU:String = "HUDMenu";
      
      private static const QUEST_ID_NEUROLOGICAL_WARFARE:uint = 7001350;
      
      private static const QUEST_ID_A_COLOSSAL_PROBLEM:uint = 5782804;
      
      private var topLevel:* = null;
      
      private var EncounterHealthMeterArray:*;
      
      private var encounterQuest:* = null;
      
      private var previouslyEncounterQuestActive:Boolean = false;
      
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
               BSUIDataManager.Subscribe("QuestTrackerProvider",this.onQuestTrackerUpdate);
               this.EncounterHealthMeterArray = BSUIDataManager.GetDataFromClient("EncounterHealthMeterArray");
               this.EncounterHealthMeterArray.addEventListener(Event.CHANGE,this.onEncounterHealthMeterUpdate,false,int.MAX_VALUE);
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
      }
      
      public function get isReloadable() : Boolean
      {
         return true;
      }
      
      private function onQuestTrackerUpdate(event:FromClientDataEvent) : void
      {
         var i:int;
         var quests:Array;
         var hasEncounterQuest:Boolean;
         try
         {
            if(event.data && event.data.quests && event.data.quests.length)
            {
               quests = event.data.quests;
               hasEncounterQuest = false;
               i = 0;
               while(i < quests.length)
               {
                  if(quests[i].questId == QUEST_ID_A_COLOSSAL_PROBLEM || quests[i].questId == QUEST_ID_NEUROLOGICAL_WARFARE)
                  {
                     this.encounterQuest = GlobalFunc.CloneObject(quests[i]);
                     hasEncounterQuest = true;
                  }
                  i++;
               }
               if(!hasEncounterQuest)
               {
                  this.encounterQuest = null;
               }
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
         try
         {
            if(this.encounterQuest != null)
            {
               this.previouslyEncounterQuestActive = true;
               objectives = encounterQuest.objectives.filter(function(obj:*):Boolean
               {
                  return obj.progress != -1;
               });
               for(i in event.data.EncounterHealthMeterArray)
               {
                  meter = event.data.EncounterHealthMeterArray[i];
                  if(objectives.length > i)
                  {
                     meter.Name = objectives[i].title;
                     meter.Percent = objectives[i].progress;
                     meter.EncounterIconType = 1;
                     meter.EncounterIconLevel = 2;
                     meter.IsHostile = true;
                  }
                  else
                  {
                     meter.Name = "";
                     meter.Percent = -1;
                     meter.EncounterIconType = 0;
                     meter.EncounterIconLevel = 0;
                  }
               }
            }
            else if(this.previouslyEncounterQuestActive)
            {
               this.previouslyEncounterQuestActive = false;
               for each(meter in event.data.EncounterHealthMeterArray)
               {
                  meter.Name = "";
                  meter.Percent = -1;
                  meter.EncounterIconType = 0;
                  meter.EncounterIconLevel = 0;
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

