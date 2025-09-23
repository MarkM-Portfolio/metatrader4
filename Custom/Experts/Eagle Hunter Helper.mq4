#property version   "1.00"
#property strict

input double GetProfit = 1.0;
input int MagicNumber = 1212;

void OnTick() {
   CheckOpenOrders(); // check orders and close if profit
}

void CheckOpenOrders(){ 
   Print("CheckOpenOrders Now!");
   RefreshRates();

   int buyCounter = 0;
   int sellCounter = 0;
   double totalProfit = NULL;
   int Slippage = 0;

   // get orders total profit 
   for ( int i=OrdersTotal()-1; i >= 0; i-- ) {
      if(OrderSelect( i, SELECT_BY_POS, MODE_TRADES )) {
         totalProfit += OrderProfit() + OrderSwap() + OrderCommission();
      }
   }

   if (totalProfit >= GetProfit) {
      CloseOrders();
   }

   Comment("TOTAL Orders +-----> ", OrdersTotal(), ", TOTAL Profit +-----> ", totalProfit, ", GET Profit +-----> ", GetProfit);
   Print("TOTAL Profit +-----> ", totalProfit);
} 

void CloseOrders() {
   Print("xxx Closing All Open Orders xxx");
   
   int Slippage = 0;

   for ( int i=OrdersTotal()-1; i >= 0; i-- ) {
      if(OrderSelect( i, SELECT_BY_POS, MODE_TRADES )) {
         if(OrderSymbol() == Symbol()) {
            if(!OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), Slippage)) {
               Print("Order Not Close with Error! ", GetLastError());
            }  
         }
      }
   }
}
