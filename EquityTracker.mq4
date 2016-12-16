
#property copyright   "Copyright 2016, toomyem@toomyem.net"
#property link        "https://www.mql5.com"
#property version     "1.0"
#property strict
#property description "Automatically close all open and pending position based on desired equity level"

input double WantedEquity = 0.0; // Wanted equity (in currency)
input double WantedGain = 0.0;   // Wanted equity gain (in %)
input double SLEquity = 0.0;     // Minimum equity before SL
input double SLPercent = 75;     // SL level (% of balance)

double TargetEquity = 0;
double MinimumEquity = 0;

int OnInit() {
   int InitCode = INIT_SUCCEEDED;
   
   if(WantedEquity > 0.0) {
      TargetEquity = WantedEquity;
   } else {
      TargetEquity = AccountBalance() * (1 + WantedGain/100.0);
   }

   if(SLEquity > 0.0) {
      MinimumEquity = SLEquity;
   } else {
      MinimumEquity = AccountBalance() * (SLPercent/100.0);
   }
   
   if(TargetEquity > AccountEquity() && MinimumEquity < AccountEquity()) {
      CreateLabel("TargetEquity", 10, 50, StringFormat("Target Equity = %G", TargetEquity));
      CreateLabel("MinimumEquity", 10, 50-18, StringFormat("Minimum Equity = %G", MinimumEquity));
   } else {
      InitCode = INIT_PARAMETERS_INCORRECT;
   }

   return(InitCode);
}

void CreateLabel(string name, int x, int y, string value = "") {
   if(ObjectFind(name) >= 0) {
      ObjectDelete(ChartID(), name);
   }

   ObjectCreate(ChartID(), name, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(ChartID(), name, OBJPROP_CORNER, CORNER_RIGHT_LOWER);
   ObjectSetInteger(ChartID(), name, OBJPROP_ANCHOR, ANCHOR_RIGHT_UPPER);
   ObjectSetInteger(ChartID(), name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(ChartID(), name, OBJPROP_YDISTANCE, y);
   ObjectSetText(name, value);
}

void UpdateLabel(string name, string value) {
   ObjectSetText(name, value);
}

void OnDeinit(const int reason) {
   EventKillTimer();
}

void OnTick() {
   if(SLEquity == 0.0 && MinimumEquity < AccountBalance() * (SLPercent/100.0)) {
      MinimumEquity = AccountBalance() * (SLPercent/100.0);
      UpdateLabel("MinimumEquity", StringFormat("Minimum Equity = %G", MinimumEquity));
   }

   if(OrdersTotal() > 0) {
      if(AccountEquity() > TargetEquity) {
         Print("Target equity reached, closing all positions");
         CloseAllOrders();
         ExpertRemove();
      } else if(AccountEquity() < MinimumEquity) {
         Print("Equity dropped too low, closing all positions");
         CloseAllOrders();
         ExpertRemove();
      }
   }
}

void CloseAllOrders() {
   for(int i = OrdersTotal()-1; i >= 0; i--) {
      if(OrderSelect(i, SELECT_BY_POS)) {
         switch(OrderType()) {
            case OP_BUY:
               if(!OrderClose(OrderTicket(), OrderLots(), Bid, 3)) {
                  Print("Close buy failed");
               }
               break;

            case OP_SELL:
               if(!OrderClose(OrderTicket(), OrderLots(), Ask, 3)) {
                  Print("Close sell failed");
               }
               break;

            default:
               break;
         }
      }
   }

   for(int i = OrdersTotal()-1; i >= 0; i--) {
      if(OrderSelect(i, SELECT_BY_POS)) {
         switch(OrderType()) {
            case OP_BUYLIMIT:
            case OP_SELLLIMIT:
            case OP_BUYSTOP:
            case OP_SELLSTOP:
               if(!OrderDelete(OrderTicket(), clrNONE)) {
                  Print("Delete failed");
               }
               break;
               
            default:
               break;
         }
      }
   }
}

/*
void CloseAllOrders() {
   while(OrdersTotal() > 0) {
      if(OrderSelect(0, SELECT_BY_POS)) {
         int ticket = OrderTicket();
         switch(OrderType()) {
            case OP_BUYLIMIT:
            case OP_SELLLIMIT:
            case OP_BUYSTOP:
            case OP_SELLSTOP:
               if(!OrderDelete(ticket, clrNONE)) {
                  Print("Delete failed");
               }
               break;

            case OP_BUY:
               if(!OrderClose(ticket, OrderLots(), Bid, 3)) {
                  Print("Close buy failed");
               }
               break;

            case OP_SELL:
               if(!OrderClose(ticket, OrderLots(), Ask, 3)) {
                  Print("Close sell failed");
               }
               break;

            default:
               break;
         }
      }
   }
}
*/
