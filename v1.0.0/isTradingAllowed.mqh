//+------------------------------------------------------------------+
//|                                             isTradingAllowed.mqh |
//|                                                         Falsitus |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Falsitus"
#property link      ""
//+------------------------------------------------------------------+
//| defines                                                          |
//+------------------------------------------------------------------+
// #define MacrosHello   "Hello, world!"
// #define MacrosYear    2010
//+------------------------------------------------------------------+
//| DLL imports                                                      |
//+------------------------------------------------------------------+
// #import "user32.dll"
//   int      SendMessageA(int hWnd,int Msg,int wParam,int lParam);
// #import "my_expert.dll"
//   int      ExpertRecalculate(int wParam,int lParam);
// #import
//+------------------------------------------------------------------+
//| EX5 imports                                                      |
//+------------------------------------------------------------------+
// #import "stdlib.ex5"
//   string ErrorDescription(int error_code);
// #import
//+------------------------------------------------------------------+
bool isTradingAllowed()
  {
   bool IsTradeAllowed = TerminalInfoInteger(TERMINAL_TRADE_ALLOWED);
   if(!IsTradeAllowed)
     {
      int errorId = GetLastError();
      if(errorId == 0) //Boton de Autotrading esta deshabilitado
        {
         Alert(" ");
         Alert("------------------------------------------------------------------");
         Alert("Habilitar AutoTrading!");
         Alert("Haz click en el boton de la barra superior. Debe aparecer en verde.");
         Alert("------------------------------------------------------------------");
        }
      else //--- Enviamos el errorID para comprobar que es en la documentacion
        {
         Alert(" ");
         Alert("------------------------------------------------------------------");
         Alert("Error Id: ", errorId);
         Alert("Comprobar archivo --> isTradingAllowed.mqh");
         Alert("------------------------------------------------------------------");
        }
      ExpertRemove(); //Si no se puede operar, cerramos el EA
      return false; //Devolvemos FALSE para que no se ejecute el codigo en el documento principal
     }
   else
      if(IsTradeAllowed) //Si todo funciona correctamente
        {
         Alert(" ");
         Alert("------------------------------------------------------------------");
         Alert("AUTOTRADING HABILITADO. Proceso de arranque correcto.");
         Alert("------------------------------------------------------------------");
         return true; //Devolvemos TRUE para que se ejecute el codigo en el documento principal
        }
   Alert("Comprobar <isTradingAllowed.mqh>. ERROR INESPERADO");
   return false; //En el caso de que no se de ninguna de las dos condiciones anteriores, devolvemos FALSE.
  };
//+------------------------------------------------------------------+
