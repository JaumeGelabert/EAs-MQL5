//+------------------------------------------------------------------+
//|                                            Local&CurrentTime.mq5 |
//|                                                         Falsitus |
//|                                  https://www.gelabertcapital.com |
//+------------------------------------------------------------------+
#property copyright "Falsitus"
#property link      "https://www.gelabertcapital.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
  {
//---
   MqlDateTime STime;

   datetime time_current=TimeCurrent(STime);
   Alert("Time Current ",time_current," day of week ",EnumToString((ENUM_DAY_OF_WEEK)STime.day_of_week));

   datetime time_local=TimeLocal(STime);
   Alert("Time Local ",time_local," day of week ",EnumToString((ENUM_DAY_OF_WEEK)STime.day_of_week));

   int DayOfWeek = (ENUM_DAY_OF_WEEK)STime.day_of_week;
   Alert("Hoy es ", EnumToString((ENUM_DAY_OF_WEEK)STime.day_of_week));

   Alert(EnumToString(ENUM_DAY_OF_WEEK(0))); //SUNDAY
   Alert(EnumToString(ENUM_DAY_OF_WEEK(1))); //MONDAY
   Alert(EnumToString(ENUM_DAY_OF_WEEK(2))); //TUESDAY
   Alert(EnumToString(ENUM_DAY_OF_WEEK(3))); //WEDNESDAY
   Alert(EnumToString(ENUM_DAY_OF_WEEK(4))); //THURSDAY
   Alert(EnumToString(ENUM_DAY_OF_WEEK(5))); //FRIDAY
   Alert(EnumToString(ENUM_DAY_OF_WEEK(6))); //SATURDAY

   if(DayOfWeek > 0 && DayOfWeek < 6)
     {
      Alert("Entre semana");
     }
   else
      if(DayOfWeek == 0 || DayOfWeek == 6)
        {
         Alert("Fin de semana");
        }
  }

//+------------------------------------------------------------------+