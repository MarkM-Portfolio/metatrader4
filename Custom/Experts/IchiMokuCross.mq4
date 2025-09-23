#property version "5.00"
#property strict

input double VolumeSize = 0.01;
input bool CloseSetEnable = false;
input int ATRPeriod = 14;
input int MagicNumber = 1212;

string localTime = TimeToStr(TimeLocal(), TIME_DATE|TIME_SECONDS);
string timeStamp = TimeToStr(TimeLocal(), TIME_SECONDS);
string channelTradeAction = NULL;
bool isRSI = false;
bool isStochRSI = false;
bool isTechAnalysis = false;
bool isRSIOver = false;
bool isStochOver = false;
bool isOverTrade = false;
bool isReversalOrder = false;
int buyCount = 0;
int sellCount = 0;
int currencyBuyCount = 0;
int currencySellCount = 0;
int currencyTotalOrders = 0;
double closeSet = 0;
// for Pro Spread currency names with "+"
string symbol = Symbol();
int replace = StringReplace(symbol, "+", "");
string period = IntegerToString(Period());
string closeSetMode = DoubleToString(closeSet);

void OnTick() {

   localTime = TimeToStr(TimeLocal(), TIME_DATE|TIME_SECONDS);
   timeStamp = TimeToStr(TimeLocal(), TIME_SECONDS);
   
   if (isNewTick()) {
      // Print("----!!!!----- NEW TICK ----!!!!-----");
      OrderCounter();

      if (IsNewIchiMokuTrend()) {
        if (currencyTotalOrders != 0) {
            Print("ICHIMOKU CROSSED CLOSING...!");
            CloseOrders();
        } else {
            string filename = StringConcatenate(symbol, Period(), "-orderType.txt");

            int filehandle_r = FileOpen(filename, FILE_READ|FILE_TXT);
            channelTradeAction = FileReadString(filehandle_r);
            FileClose(filehandle_r);

            PrepareOrder();
            NewOrder();
        }
      } else {
            if (channelTradeAction != NULL) {
                double Tenkan = iIchimoku(Symbol(), Period(), 9, 26, 52, MODE_TENKANSEN, 1); //red
                double Kijun = iIchimoku(Symbol(), Period(), 9, 26, 52, MODE_KIJUNSEN, 1); //blue
                bool barPower = (channelTradeAction == "buy") ? bullsPowerCheck() > bearsPowerCheck() : bearsPowerCheck() > bullsPowerCheck();
                double barOpen = iOpen(symbol, Period(), 0);
                int barOpenCounter = 0;
                string filename = StringConcatenate(symbol, Period(), "-orderType.txt");

                int filehandle_r = FileOpen(filename, FILE_READ|FILE_TXT);
                channelTradeAction = FileReadString(filehandle_r);
                FileClose(filehandle_r);

                if (channelTradeAction == "buy") {
                    if (Tenkan < barOpen) {
                        barOpenCounter++;
                        if (barOpenCounter == 3 && barPower) {
                        Print("Re-opening Order!!!");
                        // channelTradeAction = "buy";
                        barOpenCounter = 0;
                        PrepareOrder();
                        NewOrder();
                        //    reOpenOrder = false;
                        }
                    }
                }
                // SELL - Close is Above Tenkan = CLOSED (Open is Below Tenkan confirm twice)
                if (channelTradeAction == "sell") {
                    if (Tenkan > barOpen) {
                        barOpenCounter++;
                        if (barOpenCounter == 3  && barPower) {
                        Print("Re-opening Order!!!");
                        // channelTradeAction = "sell";
                        barOpenCounter = 0;
                        PrepareOrder();
                        NewOrder();
                        //    reOpenOrder = false;
                        }
                    }
                }
            }
      }

      if (currencyTotalOrders != 0) {
         CheckOpenOrders();  
      }
   }

   if (IsNewCandle()) {
      Print("----++++----- NEW CANDLE ----++++-----");
      Print("Local Time (PH): ", localTime);

    //   if (currencyTotalOrders == 0) {
    //      PrepareOrder();
    //      NewOrder();
    //   }

   }
}

bool isNewTick() {
   static datetime lastTime = 0;
   datetime tickTime = TimeCurrent();
   int seconds = (int)(tickTime-lastTime);
   lastTime = tickTime;
   bool result = (seconds != 0);

   return(result);
}

bool IsNewCandle() {
    static datetime currentTime =	0;
    bool result	= (currentTime != Time[0]);

    if (result) currentTime	= Time[0];

    return(result);
}

bool IsNewIchiMokuTrend() {
   double Tenkan = iIchimoku(Symbol(), Period(), 9, 26, 52, MODE_TENKANSEN, 1); //red
   double Kijun = iIchimoku(Symbol(), Period(), 9, 26, 52, MODE_KIJUNSEN, 1); //blue
   string nextChannelTradeAction = NULL;
   string filename = StringConcatenate(symbol, Period(), "-orderType.txt");
   bool isNewIchiMoku = false;

   // Print("Tenkan (red): ", Tenkan, " Kijun (blue): ", Kijun);

    if (channelTradeAction == NULL) {
        if (FileIsExist(filename)) {
            int filehandle_r = FileOpen(filename, FILE_READ|FILE_TXT);
            channelTradeAction = FileReadString(filehandle_r);
            FileClose(filehandle_r);

            if (Tenkan > Kijun) {
                nextChannelTradeAction = "buy";
            } else if (Tenkan < Kijun) {
                nextChannelTradeAction = "sell";
            } else { // if equal
                nextChannelTradeAction = NULL;
                channelTradeAction = NULL;
                FileDelete(filename);
            }

            if (nextChannelTradeAction != NULL && nextChannelTradeAction != channelTradeAction) {
                if (currencyTotalOrders == 0) {
                    Print("TRIGGER NEW TRADE!");
                    int filehandle_w = FileOpen(filename, FILE_WRITE|FILE_TXT);
                    FileWriteString(filehandle_w, nextChannelTradeAction);
                    FileClose(filehandle_w);
                }

                isNewIchiMoku = true;
            }

            if (nextChannelTradeAction != NULL && nextChannelTradeAction == channelTradeAction) {
                isNewIchiMoku = false;
            }
        } else {
            if (Tenkan > Kijun) {
                channelTradeAction = "buy";
            } else if (Tenkan < Kijun) {
                channelTradeAction = "sell";
            } else { // if equal
                channelTradeAction = NULL;
                FileDelete(filename);
            }

            if (channelTradeAction != NULL) {
                int filehandle_w = FileOpen(filename, FILE_WRITE|FILE_TXT);
                FileWriteString(filehandle_w, channelTradeAction);
                FileClose(filehandle_w);
            }

            isNewIchiMoku= true;
        }
    }


    if (channelTradeAction != NULL) {
        if (FileIsExist(filename)) {
            int filehandle_r = FileOpen(filename, FILE_READ|FILE_TXT);
            channelTradeAction = FileReadString(filehandle_r);
            FileClose(filehandle_r);

            if (Tenkan > Kijun) {
                nextChannelTradeAction = "buy";
            } else if (Tenkan < Kijun) {
                nextChannelTradeAction = "sell";
            } else { // if equal
                nextChannelTradeAction = NULL;
                channelTradeAction = NULL;
                FileDelete(filename);
            }

            if (nextChannelTradeAction != NULL && nextChannelTradeAction != channelTradeAction) {
                if (currencyTotalOrders == 0) {
                    Print("SWITCH ORDERTYPE TO: ", nextChannelTradeAction);
                    int filehandle_w = FileOpen(filename, FILE_WRITE|FILE_TXT);
                    FileWriteString(filehandle_w, nextChannelTradeAction);
                    FileClose(filehandle_w);
                }

                isNewIchiMoku = true;
            }

            if (nextChannelTradeAction != NULL && nextChannelTradeAction == channelTradeAction) {
                isNewIchiMoku = false;
            }

        }
    }

   return isNewIchiMoku;
}

string IchimokuCheck() {
   double Tenkan = iIchimoku(Symbol(), Period(), 9, 26, 52, MODE_TENKANSEN, 1); //red
   double Kijun = iIchimoku(Symbol(), Period(), 9, 26, 52, MODE_KIJUNSEN, 1); //blue

   // Print("Tenkan (red): ", Tenkan, " Kijun (blue): ", Kijun);

   if (Tenkan > Kijun) {
      channelTradeAction = "buy";
   } else if (Tenkan < Kijun) {
      channelTradeAction = "sell";
   } else { // if equal
      channelTradeAction = NULL;
   }

   return channelTradeAction;
}

bool RSICheck() {
   string indicatorName = "\\Custom\\FINWAZE RSI CROSSOVER BASIC";
   double red = iCustom(Symbol(), Period(), indicatorName, 14, 14, 0.618, 0, 0); //finwaze 14  
   double black = iCustom(Symbol(), Period(), indicatorName, 14, 14, 0.618, 1, 0); //RSI 14
   isRSI = false;
   isRSIOver = false;

//    Print("RSI Red (finwaze14) ---> ", red);
//    Print("RSI Black (RSI14) ---> ", black);

   if (channelTradeAction == "buy" && black > red) {
      // if black is greater thank red = BUY
      if (black >= 70 && red >= 65) {  // Overbought
         Print("RSI OVERBOUGHT !!");
         isRSIOver = true;
      } else {
         isRSIOver = false;
      }
      isRSI = true;
      // Print("BUY RSI Check --> ", isRSI);
   }

   if (channelTradeAction == "sell" && black < red) {
      // if black is less thank red = SELL
      if (black <= 30 && red <= 35) {   // Oversold
         Print("RSI OVERSOLD !!");
         isRSIOver = true;
      } else {
         isRSIOver = false;
      }
      isRSI = true;
      // Print("SELL RSI Check --> ", isRSI);
   }

   return isRSI;
}

bool StochRSICheck() {
   string indicatorName = "\\Custom\\FINWAZE STOCHRSI VER 3";
   double black = iCustom(Symbol(), Period(), indicatorName, 3, 3, 14, 14, PRICE_CLOSE, 0, 0); //K
   double red = iCustom(Symbol(), Period(), indicatorName, 3, 3, 14, 14, PRICE_CLOSE, 1, 0); //D
   isStochRSI = false;
   isStochOver = false;

//    Print("Stoch RSI Red (D) ---> ", red);
//    Print("Stoch RSI Black (K) ---> ", black);

   if (channelTradeAction == "buy" && black > red) {
      // if black is greater thank red = BUY
      if (black >= 80 && red >= 75) {  // Overbought
         Print("StochRSI OVERBOUGHT !! Won't Trade.");
         isStochOver = true;
      } else {
         isStochOver = false;
      }
      isStochRSI = true;
      // Print("BUY Stoch RSI Check --> ", isStochRSI);
   }

   if (channelTradeAction == "sell" && black < red) {
      // if black is less thank red = SELL
      if (black <= 20 && red <= 25) {   // Oversold
         Print("StochRSI OVERSOLD !! Won't Trade.");
         isStochOver = true;
      } else {
         isStochOver = false;
      }
      isStochRSI = true;
      // Print("SELL Stoch RSI Check --> ", isStochRSI);
   }

   return isStochRSI;
}

bool TechnicalAnalysisCheck() {
   string techAnalysisAction = NULL;
   string filename = StringConcatenate(symbol, Period(), "-technical.txt");

   int filehandle_r = FileOpen(filename, FILE_READ|FILE_TXT);
   techAnalysisAction = FileReadString(filehandle_r);
   FileClose(filehandle_r);
   
   isTechAnalysis = false;

   if (channelTradeAction == techAnalysisAction) {
      isTechAnalysis = true;
   } else {
      isTechAnalysis = false;
   }

   return isTechAnalysis;
}

void CheckOpenOrders() {
   RefreshRates();

   string indicatorName = "\\Custom\\FINWAZE STOCHRSI VER 3";
   double black = iCustom(Symbol(), Period(), indicatorName, 3, 3, 14, 14, PRICE_CLOSE, 0, 0); //K
   double red = iCustom(Symbol(), Period(), indicatorName, 3, 3, 14, 14, PRICE_CLOSE, 1, 0); //D
   double totalProfit = NULL;
   double currencyProfit = NULL;
   int factor = 0;
   int Slippage = 0;
   
   if (Period() > 60) { // H1 above
      if (TimeHour(TimeLocal()) >= 13 && TimeHour(TimeLocal()) <= 21) { // peak hours 1PM-09:59PM
         factor = 200;
      } else { // sleeping hours 10PM-12PM
         factor = 160;
      }
      if (isStochOver) {
         factor = 120;
      }
      if (isOverTrade) {
         factor = 100;
      }
   } else if (Period() == 60) {  // H1
      if (TimeHour(TimeLocal()) >= 13 && TimeHour(TimeLocal()) <= 21) { // peak hours 1PM-09:59PM
         factor = 100;
      } else { // sleeping hours 10PM-12PM
         factor = 80;
      }
      if (isStochOver) {
         factor = 60;
      }
      if (isOverTrade) {
         factor = 50;
      }
   } else { // H1 below
      if (TimeHour(TimeLocal()) >= 13 && TimeHour(TimeLocal()) <= 21) { // peak hours 1PM-09:59PM
         factor = 50;
      } else { // sleeping hours 10PM-12PM
         factor = 25;
      }
      if (isStochOver) {
         factor = 20;
      }
      if (isOverTrade) {
         factor = 15;
      }
   }

   /* TEST OFFLINE */
   // factor = -15; // test and comment out closeSet

   double getProfit = VolumeSize * factor;
   string takeProfit = NULL;
   string initFactor = NULL;
   string newFactor = NULL;
   string borderFactor = NULL;

   long barVolume = iVolume(symbol, Period(), 0);
   double barClose = iClose(symbol, Period(), 0);
   double barHigh = iHigh(symbol, Period(), 0);
   double barLow = iLow(symbol, Period(), 0);
   double barLine = (channelTradeAction == "buy") ? barHigh : barLow;
   bool barPower = (channelTradeAction == "buy") ? bullsPowerCheck() > bearsPowerCheck() : bearsPowerCheck() > bullsPowerCheck();

   string filename0 = StringConcatenate(symbol, Period(), "-initFactor.txt");
   string filename1 = StringConcatenate(symbol, Period(), "-takeProfit.txt");
   string filename2 = StringConcatenate(symbol, Period(), "-newFactor.txt");
   string filename3 = StringConcatenate(symbol, Period(), "-borderFactor.txt");

   // store initialized
   int filehandle0_w = FileOpen(filename0, FILE_WRITE|FILE_TXT);
   FileWriteString(filehandle0_w, IntegerToString(factor));
   FileClose(filehandle0_w);

   int filehandle0_r = FileOpen(filename0, FILE_READ|FILE_TXT);
   initFactor = FileReadString(filehandle0_r);
   FileClose(filehandle0_r);

   if (FileIsExist(filename1)) {
      int filehandle1_r = FileOpen(filename1, FILE_READ|FILE_TXT);
      takeProfit = FileReadString(filehandle1_r);
      FileClose(filehandle1_r);
   }

   if (FileIsExist(filename2)) {
      int filehandle2_r = FileOpen(filename2, FILE_READ|FILE_TXT);
      newFactor = FileReadString(filehandle2_r);
      FileClose(filehandle2_r);
   }

   if (FileIsExist(filename3)) {
      int filehandle3_r = FileOpen(filename3, FILE_READ|FILE_TXT);
      borderFactor = FileReadString(filehandle3_r);
      FileClose(filehandle3_r);
   }

   if (newFactor != NULL) {
      factor = StrToInteger(newFactor);
   }

   getProfit = VolumeSize * factor;

   // close per currency
   for (int i=0; i<OrdersTotal(); i++) { 
      if(OrderSelect( i, SELECT_BY_POS, MODE_TRADES )) {
         if(OrderSymbol() == Symbol()) {
            currencyProfit = OrderProfit() + OrderSwap() + OrderCommission();

            // Print(">>> CURRENCY PROFIT (BASIS) +-----> ", currencyProfit);
            // Print(">>> TAKE PROFIT (BASIS) +-----> ", StringToDouble(takeProfit));
            // Print(">>> GET PROFIT (BASIS) +-----> ", getProfit);
            // Print(">>> INIT FACTOR (BASIS) +-----> ", StringToInteger(initFactor));
            // Print(">>> FACTOR (BASIS) +-----> ", factor);
            // Print(">>> NEW FACTOR (BASIS) +-----> ", StrToInteger(newFactor));
            // Print(">>> BORDER FACTOR (BASIS) +-----> ", StrToInteger(borderFactor));

            // set trailing stop
            if (currencyProfit > getProfit) {
               Print("INCREMENTING +-----> ", currencyProfit);
               int filehandle1_w = FileOpen(filename1, FILE_WRITE|FILE_TXT);
               FileWriteString(filehandle1_w, DoubleToStr(currencyProfit, 2));
               FileClose(filehandle1_w);

               // set factor border
               if (factor == StrToInteger(initFactor) + 5 && borderFactor == NULL) {
                  int filehandle3_w = FileOpen(filename3, FILE_WRITE|FILE_TXT);
                  FileWriteString(filehandle3_w, IntegerToString(factor));
                  FileClose(filehandle3_w);
               }

               if (factor == StrToInteger(borderFactor) + 5 && borderFactor != NULL) {
                  int filehandle3_w = FileOpen(filename3, FILE_WRITE|FILE_TXT);
                  FileWriteString(filehandle3_w, IntegerToString(factor));
                  FileClose(filehandle3_w);

                  int filehandle3_r = FileOpen(filename3, FILE_READ|FILE_TXT);
                  borderFactor = FileReadString(filehandle3_r);
                  FileClose(filehandle3_r);
               }

               // get profit now
               if (currencyProfit > StringToDouble(takeProfit) && takeProfit != NULL) {
                  Print("currencyProfit > StringToDouble(takeProfit) +++++MORE+++++");
                  if (OrderType() == OP_BUY && bearsPowerCheckValue() >= 0 && black > red) { // nearest trailing stop     
                  // if (OrderType() == OP_BUY && black > red) { // nearest trailing stop    
                     factor += 1;

                     Print("BULL POWER !! INCREASING FACTOR...", factor);
                     int filehandle2_w = FileOpen(filename2, FILE_WRITE|FILE_TXT);
                     FileWriteString(filehandle2_w, IntegerToString(factor));
                     FileClose(filehandle2_w);

                     break;
                  } else if (OrderType() == OP_SELL && bullsPowerCheckValue() <= 0 && black < red) { // nearest trailing stop 
                  // } else if (OrderType() == OP_SELL && black < red) { // nearest trailing stop 
                     factor += 1;

                     Print("BEAR POWER !! INCREASING FACTOR...", factor);
                     int filehandle2_w = FileOpen(filename2, FILE_WRITE|FILE_TXT);
                     FileWriteString(filehandle2_w, IntegerToString(factor));
                     FileClose(filehandle2_w);

                     break;
                  } else {
                     Print("TAKE PROFIT NOW +-----> ", currencyProfit);
                     FileDelete(filename0);
                     FileDelete(filename1);
                     FileDelete(filename2);
                     FileDelete(filename3);

                    //  if (!OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), Slippage)) {
                    //     Print("Order Not Close with Error! ", GetLastError());
                    //  }
                    
                    CloseOrders();

                     break;
                  }
               }

               if (currencyProfit < StringToDouble(takeProfit) && takeProfit != NULL) {
                  Print("currencyProfit < StringToDouble(takeProfit) +++++LESS+++++");
                  if (currencyProfit >= StrToInteger(borderFactor)) {
                     if (OrderType() == OP_BUY && barClose < barHigh) {
                        Print("TAKE PROFIT NOW +-----> ", currencyProfit);
                        FileDelete(filename0);
                        FileDelete(filename1);
                        FileDelete(filename2);
                        FileDelete(filename3);

                        // if (!OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), Slippage)) {
                        //    Print("Order Not Close with Error! ", GetLastError());
                        // }

                        CloseOrders();

                        // Re-order during momentum
                        // if (black > red) {
                        //    Print("Re-opening Order Momentum On Tick !!");
                        //    PrepareOrder();
                        //    NewOrder();
                        // }

                        break;
                     }
                     if (OrderType() == OP_SELL && barClose > barLow) {
                        Print("TAKE PROFIT NOW +-----> ", currencyProfit);
                        FileDelete(filename0);
                        FileDelete(filename1);
                        FileDelete(filename2);
                        FileDelete(filename3);

                        // if (!OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), Slippage)) {
                        //    Print("Order Not Close with Error! ", GetLastError());
                        // }

                        CloseOrders();

                        // Re-order during momentum
                        // if (black < red) {
                        //    Print("Re-opening Order Momentum On Tick !!");
                        //    PrepareOrder();
                        //    NewOrder();
                        // }

                        break;
                     }
                  }
               }
            }
         }
      }
   }

   closeSet = getProfit * 2;

   if (CloseSetEnable) {
      // get orders total profit 
      for (int i=0; i<OrdersTotal(); i++) { 
         if (OrderSelect( i, SELECT_BY_POS, MODE_TRADES )) {
            totalProfit += OrderProfit() + OrderSwap() + OrderCommission();
         }
      }
      // close set from total profit
      if (totalProfit >= closeSet) {
         Print("SET CLOSE PROFIT +-----> ", totalProfit);
         CloseOrders();
         FileDelete(filename0);
         FileDelete(filename1);
         FileDelete(filename2);
         FileDelete(filename3);
      }
   }

   double Tenkan = iIchimoku(Symbol(), Period(), 9, 26, 52, MODE_TENKANSEN, 1); //red
   double Kijun = iIchimoku(Symbol(), Period(), 9, 26, 52, MODE_KIJUNSEN, 1); //blue

   // cut loss
   for (int i=0; i<OrdersTotal(); i++) { 
      if(OrderSelect( i, SELECT_BY_POS, MODE_TRADES )) {
         if(OrderSymbol() == Symbol()) {
            // BUY - Close is Below Tenkan = CLOSED
            if (OrderType() == OP_BUY) {
               if (isStochOver && !barPower && black < red) {
                  Print("StochOver and RSI reversed On Tick !!");
                  Print("Trend Changed Now Closing!!");
                  FileDelete(filename0);
                  FileDelete(filename1);
                  FileDelete(filename2);
                  FileDelete(filename3);

                //   if (!OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), Slippage)) {
                //      Print("Order Not Close with Error! ", GetLastError());
                //   }
                
                    CloseOrders();
                  // Re-order during reversal
                  // Print("Re-opening Reversal Order On Tick !!");
                  // channelTradeAction = "sell";
                  // isReversalOrder = true;

                  // PrepareOrder();
                  // NewOrder();

                  break;
               }

               // if (isReversalOrder && black < red) { // nearest trailing stop   
               //    Print("Reversal Order CLOSED On Tick !!");
               //    Print("Trend Changed Now Closing!!");
               //    FileDelete(filename0);
               //    FileDelete(filename1);
               //    FileDelete(filename2);
               //    FileDelete(filename3);

               //    if (!OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), Slippage)) {
               //       Print("Order Not Close with Error! ", GetLastError());
               //    }

               //    break;
               // }
               
               if (!isReversalOrder && Tenkan > barClose) {
                  Print("Close Bar HIT On Tick !!");
                  if ((black + 2) < red) {
                     Print("Trend Changed Now Closing!!");
                     FileDelete(filename0);
                     FileDelete(filename1);
                     FileDelete(filename2);
                     FileDelete(filename3);

                     if (!OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), Slippage)) {
                        Print("Order Not Close with Error! ", GetLastError());
                     }

                     break;
                  }
               }
               // close if crossed on tick
               if (!isReversalOrder && Tenkan <= Kijun) {
                  if ((black + 2) < red) {
                     Print("CLOSE IF CROSSED ON TICK!!");
                     FileDelete(filename0);
                     FileDelete(filename1);
                     FileDelete(filename2);
                     FileDelete(filename3);
                    //  if (!OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), Slippage)) {
                    //     Print("Order Not Close with Error! ", GetLastError());
                    //  }

                    CloseOrders();

                     break;
                  }
               }
            }

            // SELL - Close is Above Tenkan = CLOSED
            if (OrderType() == OP_SELL) {
               if (isStochOver && !barPower && black > red) {
                  Print("StochOver and RSI reversed On Tick !!");
                  Print("Trend Changed Now Closing!!");
                  FileDelete(filename0);
                  FileDelete(filename1);
                  FileDelete(filename2);
                  FileDelete(filename3);
                //   if (!OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), Slippage)) {
                //      Print("Order Not Close with Error! ", GetLastError());
                //   }

                    CloseOrders();
                  //Re-order during reversal
                  // Print("Re-opening Reversal Order On Tick !!");
                  // channelTradeAction = "buy";
                  // isReversalOrder = true;

                  // PrepareOrder();
                  // NewOrder();

                  break;
               }

               // if (isReversalOrder && black > red) { // nearest trailing stop   
               //    Print("Reversal Order CLOSED On Tick !!");
               //    Print("Trend Changed Now Closing!!");
               //    FileDelete(filename0);
               //    FileDelete(filename1);
               //    FileDelete(filename2);
               //    FileDelete(filename3);

               //    if (!OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), Slippage)) {
               //       Print("Order Not Close with Error! ", GetLastError());
               //    }

               //    break;
               // }

               if (!isReversalOrder && Tenkan < barClose) {
                  Print("Close Bar HIT On Tick !!");
                  if ((black - 2) > red) {
                     Print("Trend Changed Now Closing!!");
                     FileDelete(filename0);
                     FileDelete(filename1);
                     FileDelete(filename2);
                     FileDelete(filename3);
                    //  if (!OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), Slippage)) {
                    //     Print("Order Not Close with Error! ", GetLastError());
                    //  }

                        CloseOrders();

                     break;
                  }
               }
               // close if crossed on tick
               if (!isReversalOrder && Tenkan >= Kijun) {
                  if ((black - 2) > red) {
                     Print("CLOSE IF CROSSED ON TICK!!");
                     FileDelete(filename0);
                     FileDelete(filename1);
                     FileDelete(filename2);
                     FileDelete(filename3);
                    //  if (!OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), Slippage)) {
                    //     Print("Order Not Close with Error! ", GetLastError());
                    //  }

                        CloseOrders();

                     break;
                  }
               }
            }
         }
      }
   }

   // Comment("Local Time (PH): ", localTime, " TOTAL Orders +-----> ", OrdersTotal(), " Currency TOTAL Orders: ", currencyTotalOrders, " @ ", symbol, ", BUY +-----> ", buyCount, ", SELL +-----> ", sellCount, " IS OVER TRADE? +-----> ", isOverTrade, " CLOSE SET +-----> ", closeSet, " SINGLE CLOSE  +-----> ", getProfit);
   // Comment("Reversal Order: ", isReversalOrder, " isTrendReversed: ", isTrendReversed, " Re-OrderReversal: ", ReOrderReversal, " Bears: ", bearsPowerCheckValue(), " Bulls: ", bullsPowerCheckValue(), " isStochOver: ", isStochOver, " isOverTrade: ", isOverTrade, " isCloseSet: ", (CloseSetEnable) ? closeSetMode : ToUpper("Disabled"), " || INIT FACTOR: ", initFactor, " FACTOR: ", factor, " BORDER FACTOR: ", borderFactor, " GETPROFIT: ", getProfit, " TAKEPROFIT: ", takeProfit, " CURRENCYPROFIT: ", currencyProfit);
   Comment("Reversal Order: ", isReversalOrder, " Bears: ", bearsPowerCheckValue(), " Bulls: ", bullsPowerCheckValue(), " isStochOver: ", isStochOver, " isOverTrade: ", isOverTrade, " isCloseSet: ", (CloseSetEnable) ? closeSetMode : ToUpper("Disabled"), " || INIT FACTOR: ", initFactor, " FACTOR: ", factor, " BORDER FACTOR: ", borderFactor, " GETPROFIT: ", getProfit, " TAKEPROFIT: ", takeProfit, " CURRENCYPROFIT: ", currencyProfit);
} 

void PrepareOrder() {
//    if (!isReversalOrder) {
//       channelTradeAction = IchimokuCheck();
//    }

   isRSI = RSICheck();
   isStochRSI = StochRSICheck();

   if (!isRSI || !isStochRSI) {
      Print("RSI Indicators are WRONG +-----> ", isRSI, " | ", isStochRSI);
   }

   if (isRSI && isStochRSI) {
      Print("RSI Indicators are CORRECT +-----> ", isRSI, " | ", isStochRSI);
      isTechAnalysis = TechnicalAnalysisCheck();
      Print("Proceeding to Technical Analysis Check +-----> ", isTechAnalysis);
      if (isRSIOver && isStochOver) {  // check overbought & oversold
         isOverTrade = true;
         Print("Overbought/Oversold...");
      } else {
         isOverTrade = false;
      }
   }
}

void NewOrder() {
   /* TEST OFFLINE */
   // channelTradeAction = "buy";
   // isRSI = true;
   // isStochRSI = true;
   // isTechAnalysis = true;
   // isOverTrade = false;

   if (isReversalOrder) {
      isTechAnalysis = true;
   }

   // if (channelTradeAction != NULL && currencyTotalOrders == 0 && isRSI && isStochRSI && isTechAnalysis) {
   if (channelTradeAction != NULL && currencyTotalOrders == 0 && isRSI && isStochRSI) {
      Print("Ready to " + ToUpper(channelTradeAction) + " ...");

      int orderType = (channelTradeAction == "buy" ? OP_BUY : OP_SELL);
      double openPrice = (channelTradeAction == "buy" ? Ask : Bid);
      color orderColor = (channelTradeAction == "buy" ? clrBlue : clrRed);
      double buySL; double buyTP; double sellSL; double sellTP;

      int Slipage = 5;

      if (channelTradeAction == "buy") {
         int ticket = OrderSend(Symbol(), orderType, VolumeSize, openPrice, Slipage, 0, 0, symbol + period + " TEST_v5.0 " + timeStamp, MagicNumber, 0, orderColor);

         Print("**** BUYING NOW!!! ");
         Print("Price +-----> ", openPrice);
         Print("SL +-----> ", buySL);
         Print("TP +-----> ", buyTP);
      }
      if (channelTradeAction == "sell") {
         int ticket = OrderSend(Symbol(), orderType, VolumeSize, openPrice, Slipage, 0, 0, symbol + period + " TEST_v5.0 " + timeStamp, MagicNumber, 0, orderColor);

         Print("**** SELLING NOW!!! ");
         Print("Price +-----> ", openPrice);
         Print("SL +-----> ", sellSL);
         Print("TP +-----> ", sellTP);
      }
   }
}

void CloseOrders() {
   Print("xxx Closing All Open Orders xxx");
//    string filename = StringConcatenate(symbol, Period(), "-orderType.txt");
//    FileDelete(filename);
   int Slippage = 0;

   for (int i=0; i<OrdersTotal(); i++ ) { 
      if (OrderSelect( i, SELECT_BY_POS, MODE_TRADES )) {
         if (OrderSymbol() == Symbol()) {
            if (!OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), Slippage)) {
               Print("Order Not Close with Error! ", GetLastError());
            }  
         }
      }
   }
   
   channelTradeAction = NULL;
   isReversalOrder = false;
   OrderCounter();
}

void OrderCounter() {
   int buyCounter = 0;
   int sellCounter = 0;
   int currencyBuyCounter = 0;
   int currencySellCounter = 0;

   for (int i=0; i<OrdersTotal(); i++) { 
      if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
         if (OrderType() == OP_BUY) { // buy orders
            buyCounter++;
            if(OrderSymbol() == Symbol()) {
               currencyBuyCounter++;
            }
         }
         if (OrderType() == OP_SELL) { // sell orders
            sellCounter++;
            if (OrderSymbol() == Symbol()) {
               currencySellCounter++;
            }
         }
      } 
   }

   buyCount = buyCounter;
   sellCount = sellCounter;
   currencyBuyCount = currencyBuyCounter;
   currencySellCount = currencySellCounter;
   currencyTotalOrders = currencyBuyCount + currencySellCount;
}

double ATRCheck() {
   double atr = iATR(Symbol(), Period(), ATRPeriod, 1);

   return atr;
}

double bullsPowerCheckValue() {
   double bullsPower = iBullsPower(NULL, 0, 13, PRICE_CLOSE, 0);

   return bullsPower;
}

double bearsPowerCheckValue() {
   double bearsPower = iBearsPower(NULL, 0, 13, PRICE_CLOSE, 0);

   return bearsPower;
}

double bullsPowerCheck() {
   double bullsPower = iBullsPower(NULL, 0, 13, PRICE_CLOSE, 0);

   if (bullsPower < 0) bullsPower *= -1;

   return bullsPower;
}

double bearsPowerCheck() {
   double bearsPower = iBearsPower(NULL, 0, 13, PRICE_CLOSE, 0);

   if (bearsPower < 0) bearsPower *= -1;

   return bearsPower;
}

string ToUpper(string text) { 
   StringToUpper(text);
   return text; 
}
