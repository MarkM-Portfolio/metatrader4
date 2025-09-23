#property version   "1.00"
#property strict

input bool Auto = true;
input int Factor = 5;
input double VolumeSize = 0.01;
input int StopLoss = 200; //default for Auto
input int TakeProfit = 200;
input int ATRPeriod = 14;
input int MagicNumber = 1212;

string channelTradeAction;
string prevChannelTradeAction = NULL;
bool isDoneTrade = false;
bool rsiAction = false;
bool stochRsiAction = false;
double atr;
int buyCount = 0;
int sellCount = 0;

void OnTick() {
   if (IsNewCandle()) {
      Print("----++++----- NEW CANDLE ----++++-----");

      CheckOpenOrders();
      Print("BUY Orders Total +-----> ", buyCount);
      Print("SELL Orders Total +-----> ", sellCount);

      channelTradeAction = ChannelTraderCheck();

      if (channelTradeAction != NULL) {
         Print("Ready to " + ToUpper(channelTradeAction) + " ...");

         rsiAction = RSICheck();
         stochRsiAction = StochRSICheck();

         if (!rsiAction || !stochRsiAction) {
            Print("INDICATORS are incorrect +-----> ", rsiAction, " | ", stochRsiAction);
         }
      }
      
      if (channelTradeAction != NULL && rsiAction && stochRsiAction) { // Uncomment to Test
         Print("Condition are met. Trading NOW !!! +-----> ", rsiAction, " | ", stochRsiAction);

         atr = ATRcheck();

         int orderType = (channelTradeAction == "buy" ? OP_BUY : OP_SELL);
         double openPrice = (channelTradeAction == "buy" ? Ask : Bid);
         color orderColor = (channelTradeAction == "buy" ? clrBlue : clrRed);
         double buySL; double buyTP; double sellSL; double sellTP;

         if (!Auto) {
            /* Version 1 */
            buySL = openPrice - (StopLoss *  atr);
            buyTP = openPrice + (TakeProfit * atr);
            sellSL = openPrice + (StopLoss * atr);
            sellTP = openPrice - (TakeProfit * atr);
         } else {
            /* Version 2 */
            buySL = openPrice - (StopLoss * atr);
            buyTP = openPrice + (openPrice * atr);
            sellSL = openPrice + (StopLoss * atr);
            sellTP = openPrice - (openPrice * atr);
         }

         int Slipage = 5;

         if (!isDoneTrade) {
            if (channelTradeAction == "buy" && buyCount <= 10) { // limit to 10 buy orders
               for( int i=1; i<=Factor; i++ ) {
                  int ticket = OrderSend(Symbol(), orderType, VolumeSize, openPrice, Slipage, buySL, buyTP, NULL, MagicNumber, 0, orderColor);
               }

               Print("**** BUYING NOW!!! ");
               Print("ATR +-----> ", atr);
               Print("Price +-----> ", openPrice);
               Print("SL +-----> ", buySL);
               Print("TP +-----> ", buyTP);
            }
            if (channelTradeAction == "sell" && sellCount <= 10) { // limit to 10 sell orders
               for( int i=1; i<=Factor; i++ ) {
                  int ticket = OrderSend(Symbol(), orderType, VolumeSize, openPrice, Slipage, sellSL, sellTP, NULL, MagicNumber, 0, orderColor);
               }

               Print("**** SELLING NOW!!! ");
               Print("ATR +-----> ", atr);
               Print("Price +-----> ", openPrice);
               Print("SL +-----> ", sellSL);
               Print("TP +-----> ", sellTP);
            }
         }

         isDoneTrade = true;

         Print("END channelTradeAction +-----> ", channelTradeAction);
         Print("END prevChannelTradeAction +-----> ", prevChannelTradeAction);
         Print("END isDoneTrade +-----> ", isDoneTrade);
      }
   }
}

bool IsNewCandle() {
   static datetime currentTime =	0;
	bool result	= (currentTime!=Time[0]);

	if (result) currentTime	= Time[0];

	return(result);
}

string ChannelTraderCheck() {
   string filename = StringConcatenate(Symbol(), Period(), "-orderType.txt");

   if (FileIsExist(filename)) {
      int filehandle_r = FileOpen(filename, FILE_READ|FILE_TXT);
      prevChannelTradeAction = FileReadString(filehandle_r);
      FileClose(filehandle_r);
   }

   string indicatorName = "\\Custom\\FINWAZE CHANNEL TRADER";
   double buyArrow = iCustom(Symbol(), Period(), indicatorName, 4, 500, 3, 1); //BUY
   double sellArrow = iCustom(Symbol(), Period(), indicatorName, 4, 500, 2, 1); //SELL

   Print("Get Signal BUY +-----> ", buyArrow);
   Print("Get Signal SELL +-----> ", sellArrow);

   if (buyArrow != EMPTY_VALUE && buyArrow > 0) {
      Print("Buy Arrow +-----> ", buyArrow);
      channelTradeAction = "buy";
      isDoneTrade = false;
   } else if (sellArrow != EMPTY_VALUE && sellArrow > 0) {
      Print("Sell Arrow +-----> ", sellArrow);
      channelTradeAction = "sell";
      isDoneTrade = false;
   } else {
      if (prevChannelTradeAction != NULL) {
         Print("SAME Signal !!! +-----> ", prevChannelTradeAction); // detected as no arrow signal but same signal but lower value
         if (isDoneTrade) {
            Print("Already TRADED previously !!! "); // no arrow signal
            channelTradeAction = NULL;
            isDoneTrade = true;
         } else {
            Print("Haven't TRADED yet !!! ");
            channelTradeAction = prevChannelTradeAction;
            isDoneTrade = false;
         }
      } else {
         Print("NO Arrow Signal !!! "); // no arrow signal
         channelTradeAction = NULL;
         isDoneTrade = false;
      }
   }

   if (channelTradeAction != NULL) {
      int filehandle_w = FileOpen(filename, FILE_WRITE|FILE_TXT);
      FileWriteString(filehandle_w, channelTradeAction);
      FileClose(filehandle_w);

      int filehandle_r = FileOpen(filename, FILE_READ|FILE_TXT);
      prevChannelTradeAction = FileReadString(filehandle_r);
      FileClose(filehandle_r);
   } else {
      Print("NO VALUE for channelTradeAction..");
   }

   Print("START channelTradeAction +-----> ", channelTradeAction);
   Print("START prevChannelTradeAction +-----> ", prevChannelTradeAction);
   Print("START isDoneTrade +-----> ", isDoneTrade);

   Comment("ATR +-----> ", ATRcheck(), ", Channel +-----> ", ToUpper(prevChannelTradeAction), ", Highest +-----> ", (prevChannelTradeAction == "buy") ? buyArrow : sellArrow);

   return channelTradeAction;
}
	
bool RSICheck() {
   string indicatorName = "\\Custom\\FINWAZE RSI CROSSOVER BASIC";
   double red = iCustom(Symbol(), Period(), indicatorName, 14, 14, 0.618, 0, 1); //RSI 14
   double black = iCustom(Symbol(), Period(), indicatorName, 14, 14, 0.618, 1, 1); //finwaze 14

   // Print("V1 RSI Red ---> ", red);
   // Print("V1 RSI Black ---> ", black);

   if (channelTradeAction == "buy" && black > red) {
   // if black is greater thank red = BUY
      rsiAction = true;
      // Print("BUY RSI Check --> ", rsiAction);
   }

   if (channelTradeAction == "sell" && black < red) {
   // if black is less thank red = SELL
      rsiAction = true;
      // Print("SELL RSI Check --> ", rsiAction);
   }

   return rsiAction;
}

bool StochRSICheck() {
   string indicatorName = "\\Custom\\FINWAZE STOCHRSI VER 3";
   double red = iCustom(Symbol(), Period(), indicatorName, 3, 3, 14, 14, PRICE_CLOSE, 0, 1); //D
   double black = iCustom(Symbol(), Period(), indicatorName, 3, 3, 14, 14, PRICE_CLOSE, 1, 1); //K

   // Print("V1 Stoch RSI Red (D) ---> ", red);
   // Print("V1 Stoch RSI Black (K) ---> ", black);

   if (channelTradeAction == "buy" && black > red) {
   // if black is greater thank red = BUY
      stochRsiAction = true;
      // Print("BUY Stoch RSI Check --> ", stochRsiAction);
   }

   if (channelTradeAction == "sell" && black < red) {
   // if black is less thank red = SELL
      stochRsiAction = true;
      // Print("SELL Stoch RSI Check --> ", stochRsiAction);
   }

   return stochRsiAction;
}

double ATRcheck() {
   atr = iATR(Symbol(), Period(), ATRPeriod, 1);
   // double points = NormalizeDouble(atr, Digits); 
   // int atr_in_points=(int)round(points / Point());
   // double pips = NormalizeDouble(atr, Digits - 1 * (Digits == 3 || Digits == 5));
   // int atr_in_pips=(int)round(pips / Point());

   // double ATR_IN_POINTS = atr * MathPow(10, Digits - 0);
   // double ATR_IN_PIPS = atr * MathPow(10, Digits - 1); 

   // Print("ATR true value ---> ", atr); // 9.999999999998899e-05
   // Print("ATR to DOUBLE POINTS ---> ", points); // 0.0001
   // Print("ATR to INT POINTS ---> ", atr_in_points); // 10
   // Print("ATR to DOUBLE PIPS ---> ", pips); // 0.0001
   // Print("ATR to INT PIPS ---> ", atr_in_pips); // 10
   // Print("ATR to ATR_IN_POINTS ---> ", ATR_IN_POINTS); // 9.999999999998899
   // Print("ATR to INT ATR_IN_PIPS ---> ", ATR_IN_PIPS); // 0.9999999999998899

   return atr;
}

bool CheckOpenOrders(){ 
   Print("CheckOpenOrders Now!");

   for( int i=0; i<OrdersTotal(); i++ ) { 
      if(OrderSelect( i, SELECT_BY_POS, MODE_TRADES )) {
         if(OrderType() == 0) { // buy orders
            Print(i);
            buyCount = i;
         }
         if(OrderType() == 1) { // sell orders
            Print(i);
            sellCount = i;
         }
      } 
   }

   return false; 
} 

string ToUpper(string text) { 
   StringToUpper(text);
   return text; 
}