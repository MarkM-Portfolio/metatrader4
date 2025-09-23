#property copyright "HKD © 2024 All Rights Reserved."
#property link "https://hkdsolutionsfx.com/"
#property description "Author: MMM"
#property icon "hkd.ico"
#property strict
#define VERSION "1.3"

input double VolumeSize = 0.10;
input bool MegaTrendConfirm = true;
input int SLPoints = 200;
input int SLPointsNews = 500;
input int SLPointsGold = 1000;
input int SLPointsNewsGold = 1000;
input bool ForceTPMultiplier = false;
input double ForceTPMultiplierValue = 1.30;
input bool NewsCloseTrade = true;
input bool NewsTradeOn = true;
input bool StandardHrsTrade = false;
input bool WindowHrsTrade = false;
input bool NonStopTrade = true;
input bool CloseSetEnable = false;
input bool ReferLowerChart = false;
input bool ReferHigherChartLoss = false;
input int OrderLimit = 4;
input int Slippage = 0;
input int MagicNumber = 1212;

string localTime = TimeToStr(TimeLocal(), TIME_DATE|TIME_SECONDS);
string timeStamp = TimeToStr(TimeLocal(), TIME_DATE | TIME_MINUTES | TIME_SECONDS);
string channelTradeAction = NULL;
string megaTrendCheck = NULL;
bool stopTrade = false;
bool orderDanger = false;
bool newsOrder = false;
bool isMegaTrend = false;
string currentDate = NULL;
string isNewsOn = NULL;
string filenameNewsOn;
int refPeriod; int cutPeriod;
int buyCount = 0;
int sellCount = 0;
int currencyBuyCount = 0;
int currencySellCount = 0;
int currencyTotalOrders = 0;
int buyLimitCounter = 0;
int sellLimitCounter = 0;
int orderLimitCounter = 0;
double closeSet = 0;
// for Pro Spread currency names with "+"
string symbol = Symbol();
int period = Period();
string symbol_str;
string period_str;
string closeSetMode = DoubleToString(closeSet);

void OnTick() {

   localTime = TimeToStr(TimeLocal(), TIME_DATE | TIME_SECONDS);
   timeStamp = TimeToStr(TimeLocal(), TIME_DATE | TIME_MINUTES | TIME_SECONDS);
   symbol_str = RemoveTrailingSigns(symbol);
   period_str = PeriodToString(period);

   if (StandardHrsTrade) {
      if (TimeHour(TimeLocal()) >= 13) { // trading hours
         stopTrade = false;
      } else {
         stopTrade = true;
         if (TimeDayOfWeek(TimeLocal()) == 6) { // if after Friday close orders
            CloseOrders();
         }
      }
   }
   if (WindowHrsTrade) {
      if (TimeHour(TimeLocal()) >= 4 && TimeHour(TimeLocal()) <= 8) { // stop and close trade after 4AM until 9AM
         stopTrade = true;
         CloseOrders();
      } else { // start trade at 9AM
         stopTrade = false;
      }
   }

   if (NonStopTrade) {
      if (TimeDayOfWeek(TimeLocal()) == 6) { // if after Friday close orders
         CloseOrders();
      } else {
         stopTrade = false;
      }
   }

   if (ReferLowerChart) { // use M1 chart in M5 timeframe
      refPeriod = ReferChart();
   } else {
      refPeriod = Period();
   }

   if (ReferHigherChartLoss) { // use M15 chart in M5 timeframe
      cutPeriod = CutLossChart();
   } else {
      cutPeriod = Period();
   }
   
   if (isNewTick()) {
      // Print("----!!!!----- NEW TICK ----!!!!-----");
      OrderCounter();

      if (currencyTotalOrders != 0 && !stopTrade) {
         if (NewsCloseTrade) {
            CheckNews();
            if (isNewsOn == "ONLINE" && orderDanger && !newsOrder) {
               // Force Close Order
               if (!OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), Slippage)) {
                  Print("Order Not Close with Error! ", GetLastError());
               }
               newsOrder = false;
            } else {
               isNewsOn = NULL;
               CheckOpenOrders();
            }
         } else {
            isNewsOn = NULL;
            CheckOpenOrders();
         }
      }

      // if (currencyTotalOrders == 0 && !stopTrade && orderLimitCounter <= OrderLimit) {
      if (currencyTotalOrders == 0 && !stopTrade) {
         if (NewsTradeOn) {
            CheckNews();
            if (isNewsOn == "ONLINE" && orderDanger) {
               newsOrder = true;
               PrepareOrder();
               NewOrder();
            } else {
               isNewsOn = NULL;
               newsOrder = false;
               PrepareOrder();
               NewOrder();
            }
            // if (NewsTradeOn && isNewsOn == "ONLINE" && !stopTrade) {
            //    FileDelete(filenameNewsOn);
            //    isNewsOn = NULL;
            // }
         } else {
            isNewsOn = NULL;
            newsOrder = false;
            PrepareOrder();
            NewOrder();
         }

         // if (!stopTrade && isNewsOn != "ONLINE") {
         //    PrepareOrder();
         //    NewOrder();
         // }
      }
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

int ReferChart() {
   if (Period() == 1) {
      refPeriod = 5;
   } else if(Period() == 5) {
      refPeriod = 1;
   } else if (Period() == 15) {
      refPeriod = 5;
   } else if (Period() == 30) {
      refPeriod = 15;
   } else if (Period() == 60) {
      refPeriod = 30;
   } else if (Period() == 240) {
      refPeriod = 60;
   } else if (Period() == 1440) {
      refPeriod = 240;
   } else {
      refPeriod = 1440;
   }

   return refPeriod;
}

int CutLossChart() {
   if (Period() == 1) {
      cutPeriod = 5;
   } else if(Period() == 5) {
      cutPeriod = 15;
   } else if (Period() == 15) {
      cutPeriod = 30;
   } else if (Period() == 30) {
      cutPeriod = 60;
   } else if (Period() == 60) {
      cutPeriod = 240;
   } else if (Period() == 240) {
      cutPeriod = 1440;
   } else {
      cutPeriod = 10080;
   }

   return cutPeriod;
}

string SniperCheck() {

   double sniperResistance = iCustom(Symbol(), Period(), "\\Custom\\HKD Sniper", "", false, false, false, false, "alert.wav", "current", true, 1, 0);
   double sniperSupport = iCustom(Symbol(), Period(), "\\Custom\\HKD Sniper", "", false, false, false, false, "alert.wav", "current", true, 2, 0);
   double sniperValue = iCustom(Symbol(), Period(), "\\Custom\\HKD Sniper", "", false, false, false, false, "alert.wav", "current", true, 7, 0);
   double kijunRSI = iCustom(Symbol(), Period(), "\\Custom\\HKD RSI", Period(), 14, 25, 15.0, 14, false, false, false, false, false, false, "alert2.wav", 1, 0);

   channelTradeAction = NULL;

   // Print("Sniper Value: ", sniperValue, " Sniper Support: ", sniperSupport, " Sniper Resistance: ", sniperResistance);
   // Print("Kijun RSI: ", kijunRSI);

   if (sniperValue < sniperSupport) {
      if (!newsOrder && kijunRSI < -25) {
         channelTradeAction = "buy"; // Normal
      }
      if (newsOrder) {
         channelTradeAction = "sell";
      }
   }

   if (sniperValue > sniperResistance) {
      if (!newsOrder && kijunRSI > 25) {
         channelTradeAction = "sell"; // Normal
      }
      if (newsOrder) {
         channelTradeAction = "buy";
      }
   }

   return channelTradeAction;
}

void CheckOpenOrders() {
   RefreshRates();

   // int factor = 0;
   int factor;
   
   if (Period() > 60) { // H1 above
      if (TimeHour(TimeLocal()) >= 13 && TimeHour(TimeLocal()) <= 21) { // peak hours 1PM-09:59PM
         factor = 200;
      } else { // sleeping hours 10PM-12PM
         factor = 160;
      }
   } else if (Period() == 60 || Period() == 30) {  // H1 and M30
      if (TimeHour(TimeLocal()) >= 13 && TimeHour(TimeLocal()) <= 21) { // peak hours 1PM-09:59PM
         factor = 120;
      } else { // sleeping hours 10PM-12PM
         factor = 100;
      }
   } else if (Period() == 15 || Period() == 5 || Period() == 1) {  // H1 and M30
      if (TimeHour(TimeLocal()) >= 13 && TimeHour(TimeLocal()) <= 21) { // peak hours 1PM-09:59PM
         factor = 25;
      } else { // sleeping hours 10PM-12PM
         factor = 25;
      }
   } else { // Daily
      if (TimeHour(TimeLocal()) >= 13 && TimeHour(TimeLocal()) <= 21) { // peak hours 1PM-09:59PM
         factor = 500;
      } else { // sleeping hours 10PM-12PM
         factor = 500;
      }
   }

   // Set factor for GOLD
   if (symbol_str == "XAUUSD") { // Increase TP factor for GOLD
      if (TimeHour(TimeLocal()) >= 13 && TimeHour(TimeLocal()) <= 21) { // peak hours 1PM-09:59PM
         factor = 35;
      } else { // sleeping hours 10PM-12PM
         factor = 25;
      }
   }

   // Set factor during news trade
   if (newsOrder) {
      factor = 100;
   }

   /* TEST OFFLINE */
   // factor = -15; // test and comment out closeSet
   double totalProfit = NULL;
   // double currencyProfit = NULL;
   // string takeProfit = NULL;
   // string initFactor = NULL;
   // string newFactor = NULL;
   // string borderFactor = NULL;

   long barVolume = iVolume(symbol_str, Period(), 0);
   double barClose = iClose(symbol_str, Period(), 0);
   double barOpen = iOpen(symbol_str, Period(), 0);
   double barHigh = iHigh(symbol_str, Period(), 0);
   double barLow = iLow(symbol_str, Period(), 0);
   double barLine = (channelTradeAction == "buy") ? barHigh : barLow;
   bool barPower = (channelTradeAction == "buy") ? bullsPowerCheck() > bearsPowerCheck() : bearsPowerCheck() > bullsPowerCheck();

   string takeProfit; string initFactor;
   string newFactor; string borderFactor;

   string filename0 = StringConcatenate(symbol_str, Period(), "-initFactor.txt");
   string filename1 = StringConcatenate(symbol_str, Period(), "-takeProfit.txt");
   string filename2 = StringConcatenate(symbol_str, Period(), "-newFactor.txt");
   string filename3 = StringConcatenate(symbol_str, Period(), "-borderFactor.txt");

   if (FileIsExist(filename0)) {
      int filehandle0_r = FileOpen(filename0, FILE_READ|FILE_TXT);
      initFactor = FileReadString(filehandle0_r);
      FileClose(filehandle0_r);
   } else {
      // store initialized
      int filehandle0_w = FileOpen(filename0, FILE_WRITE|FILE_TXT);
      FileWriteString(filehandle0_w, IntegerToString(factor));
      FileClose(filehandle0_w);

      int filehandle0_r = FileOpen(filename0, FILE_READ|FILE_TXT);
      initFactor = FileReadString(filehandle0_r);
      FileClose(filehandle0_r);
   }

   // if factor changes reset factor and assign to init
   if (factor != StrToInteger(initFactor)) {
      // store initialized
      int filehandle0_w = FileOpen(filename0, FILE_WRITE|FILE_TXT);
      FileWriteString(filehandle0_w, IntegerToString(factor));
      FileClose(filehandle0_w);

      int filehandle0_r = FileOpen(filename0, FILE_READ|FILE_TXT);
      initFactor = FileReadString(filehandle0_r);
      FileClose(filehandle0_r);
   }

   if (FileIsExist(filename1)) {
      int filehandle1_r = FileOpen(filename1, FILE_READ|FILE_TXT);
      takeProfit = FileReadString(filehandle1_r);
      FileClose(filehandle1_r);
   }

   if (FileIsExist(filename2)) {
      int filehandle2_r = FileOpen(filename2, FILE_READ|FILE_TXT);
      newFactor = FileReadString(filehandle2_r);
      FileClose(filehandle2_r);
      // override factor if newFactor has value
      factor = StrToInteger(newFactor);
   }

   // if (FileIsExist(filename3)) {
   //    int filehandle3_r = FileOpen(filename3, FILE_READ|FILE_TXT);
   //    borderFactor = FileReadString(filehandle3_r);
   //    FileClose(filehandle3_r);
   // }

   double getProfit = VolumeSize * factor;
   // double totalProfit; 
   double currencyProfit;
   // int basepoint = newsOrder ? TPFactorBasePointNews : TPFactorBasePoint; 
   // int borderpoint = newsOrder ? TPFactorBorderPointNews : TPFactorBorderPoint;

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
               if (ForceTPMultiplier) {
                  // force take profit
                  if ((currencyProfit >= getProfit * ForceTPMultiplierValue)) {
                     Print("TAKE PROFIT NOW +-----> ", currencyProfit);
                     FileDelete(filename0);
                     FileDelete(filename1);
                     FileDelete(filename2);
                     FileDelete(filename3);

                     if (!OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), Slippage)) {
                        Print("Order Not Close with Error! ", GetLastError());
                     }

                     newsOrder = false;

                     break;
                  }
               }

               if (!FileIsExist(filename1)) {
                  int filehandle1_w = FileOpen(filename1, FILE_WRITE|FILE_TXT);
                  FileWriteString(filehandle1_w, DoubleToStr(currencyProfit, 2));
                  FileClose(filehandle1_w);

                  break;
                  // break if takeprofit value is not in memory
               } else {
                  // get profit now
                  if (currencyProfit > StringToDouble(takeProfit)) {
                     Print("currencyProfit > StringToDouble(takeProfit) +++++MORE+++++");

                     int filehandle1_w = FileOpen(filename1, FILE_WRITE|FILE_TXT);
                     FileWriteString(filehandle1_w, DoubleToStr(currencyProfit, 2));
                     FileClose(filehandle1_w);

                     if (OrderType() == OP_BUY) {
                        // if (bearsPowerCheckValue() >= 0) { // nearest trailing stop
                        if (barClose > barOpen) { // nearest trailing stop 
                           // factor += 1;

                           // Print("BULL POWER !! INCREASING FACTOR...", factor);
                           // int filehandle2_w = FileOpen(filename2, FILE_WRITE|FILE_TXT);
                           // FileWriteString(filehandle2_w, IntegerToString(factor));
                           // FileClose(filehandle2_w);

                           break;
                        } else {
                           Print("TAKE PROFIT NOW +-----> ", currencyProfit);
                           FileDelete(filename0);
                           FileDelete(filename1);
                           FileDelete(filename2);
                           FileDelete(filename3);

                           if (!OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), Slippage)) {
                              Print("Order Not Close with Error! ", GetLastError());
                           }

                           newsOrder = false;

                           break;
                        }
                     }

                     if (OrderType() == OP_SELL) {
                        // if (bullsPowerCheckValue() <= 0) { // nearest trailing stop 
                        if (barClose < barOpen) { // nearest trailing stop 
                           // factor += 1;

                           // Print("BEAR POWER !! INCREASING FACTOR...", factor);
                           // int filehandle2_w = FileOpen(filename2, FILE_WRITE|FILE_TXT);
                           // FileWriteString(filehandle2_w, IntegerToString(factor));
                           // FileClose(filehandle2_w);

                           break;
                        } else {
                           Print("TAKE PROFIT NOW +-----> ", currencyProfit);
                           FileDelete(filename0);
                           FileDelete(filename1);
                           FileDelete(filename2);
                           FileDelete(filename3);

                           if (!OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), Slippage)) {
                              Print("Order Not Close with Error! ", GetLastError());
                           }

                           newsOrder = false;

                           break;
                        }
                     }

                     // if (OrderType() == OP_BUY) {
                     //    if (bearsPowerCheckValue() >= 0) { // nearest trailing stop
                     //       factor += 1;

                     //       Print("BULL POWER !! INCREASING FACTOR...", factor);
                     //       int filehandle2_w = FileOpen(filename2, FILE_WRITE|FILE_TXT);
                     //       FileWriteString(filehandle2_w, IntegerToString(factor));
                     //       FileClose(filehandle2_w);

                     //       break;
                     //    } else {
                     //       Print("TAKE PROFIT NOW +-----> ", currencyProfit);
                     //       FileDelete(filename0);
                     //       FileDelete(filename1);
                     //       FileDelete(filename2);
                     //       FileDelete(filename3);

                     //       if (!OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), Slippage)) {
                     //          Print("Order Not Close with Error! ", GetLastError());
                     //       }

                     //       newsOrder = false;

                     //       break;
                     //    }
                     // }

                     // if (OrderType() == OP_SELL) {
                     //    if (bullsPowerCheckValue() <= 0) { // nearest trailing stop 
                     //       factor += 1;

                     //       Print("BEAR POWER !! INCREASING FACTOR...", factor);
                     //       int filehandle2_w = FileOpen(filename2, FILE_WRITE|FILE_TXT);
                     //       FileWriteString(filehandle2_w, IntegerToString(factor));
                     //       FileClose(filehandle2_w);

                     //       break;
                     //    } else {
                     //       Print("TAKE PROFIT NOW +-----> ", currencyProfit);
                     //       FileDelete(filename0);
                     //       FileDelete(filename1);
                     //       FileDelete(filename2);
                     //       FileDelete(filename3);

                     //       if (!OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), Slippage)) {
                     //          Print("Order Not Close with Error! ", GetLastError());
                     //       }

                     //       newsOrder = false;

                     //       break;
                     //    }
                     // }
                  }

                  if (currencyProfit <= StringToDouble(takeProfit)) {
                     Print("currencyProfit <= StringToDouble(takeProfit) +++++LESS+++++");

                     int filehandle1_w = FileOpen(filename1, FILE_WRITE|FILE_TXT);
                     FileWriteString(filehandle1_w, DoubleToStr(currencyProfit, 2));
                     FileClose(filehandle1_w);

                     // int filehandle1_r = FileOpen(filename1, FILE_READ|FILE_TXT);
                     // newTakeProfit = FileReadString(filehandle1_r);
                     // FileClose(filehandle1_r);

                     if (OrderType() == OP_BUY && barClose < barHigh) {
                        Print("TAKE PROFIT NOW +-----> ", currencyProfit);
                        FileDelete(filename0);
                        FileDelete(filename1);
                        FileDelete(filename2);
                        FileDelete(filename3);

                        if (!OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), Slippage)) {
                           Print("Order Not Close with Error! ", GetLastError());
                        }

                        newsOrder = false;

                        break;
                     }
                     if (OrderType() == OP_SELL && barClose > barLow) {
                        Print("TAKE PROFIT NOW +-----> ", currencyProfit);
                        FileDelete(filename0);
                        FileDelete(filename1);
                        FileDelete(filename2);
                        FileDelete(filename3);

                        if (!OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), Slippage)) {
                           Print("Order Not Close with Error! ", GetLastError());
                        }

                        newsOrder = false;

                        break;
                     }
                  }
               }
            } else {
               // if currencyProfit is less.. reset all
               FileDelete(filename0);
               FileDelete(filename1);
               FileDelete(filename2);
               FileDelete(filename3);
            }
         }
      }
   }

   // // close per currency
   // for (int i=0; i<OrdersTotal(); i++) { 
   //    if(OrderSelect( i, SELECT_BY_POS, MODE_TRADES )) {
   //       if(OrderSymbol() == Symbol()) {
   //          currencyProfit = OrderProfit() + OrderSwap() + OrderCommission();

   //          // Print(">>> CURRENCY PROFIT (BASIS) +-----> ", currencyProfit);
   //          // Print(">>> TAKE PROFIT (BASIS) +-----> ", StringToDouble(takeProfit));
   //          // Print(">>> GET PROFIT (BASIS) +-----> ", getProfit);
   //          // Print(">>> INIT FACTOR (BASIS) +-----> ", StringToInteger(initFactor));
   //          // Print(">>> FACTOR (BASIS) +-----> ", factor);
   //          // Print(">>> NEW FACTOR (BASIS) +-----> ", StrToInteger(newFactor));
   //          // Print(">>> BORDER FACTOR (BASIS) +-----> ", StrToInteger(borderFactor));

   //          // set trailing stop
   //          if (currencyProfit > getProfit) {
   //             // force take profit
   //             if ((currencyProfit >= getProfit * ForceTakeProfit)) {
   //                Print("TAKE PROFIT NOW +-----> ", currencyProfit);
   //                FileDelete(filename0);
   //                FileDelete(filename1);
   //                FileDelete(filename2);
   //                FileDelete(filename3);

   //                if (!OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), Slippage)) {
   //                   Print("Order Not Close with Error! ", GetLastError());
   //                }

   //                newsOrder = false;

   //                break;
   //             }

   //             Print("INCREMENTING +-----> ", currencyProfit);
   //             int filehandle1_w = FileOpen(filename1, FILE_WRITE|FILE_TXT);
   //             FileWriteString(filehandle1_w, DoubleToStr(currencyProfit, 2));
   //             FileClose(filehandle1_w);

   //             // set factor border
   //             if (factor == StrToInteger(initFactor) + basepoint && borderFactor == NULL) {
   //                int filehandle3_w = FileOpen(filename3, FILE_WRITE|FILE_TXT);
   //                FileWriteString(filehandle3_w, IntegerToString(factor));
   //                FileClose(filehandle3_w);
   //             }

   //             if (factor == StrToInteger(borderFactor) + borderpoint && borderFactor != NULL) {
   //                int filehandle3_w = FileOpen(filename3, FILE_WRITE|FILE_TXT);
   //                FileWriteString(filehandle3_w, IntegerToString(factor));
   //                FileClose(filehandle3_w);

   //                int filehandle3_r = FileOpen(filename3, FILE_READ|FILE_TXT);
   //                borderFactor = FileReadString(filehandle3_r);
   //                FileClose(filehandle3_r);
   //             }

   //             // get profit now
   //             if (currencyProfit > StringToDouble(takeProfit) && takeProfit != NULL) {
   //                Print("currencyProfit > StringToDouble(takeProfit) +++++MORE+++++");
   //                if (OrderType() == OP_BUY && bearsPowerCheckValue() >= 0) { // nearest trailing stop
   //                   factor += 1;

   //                   Print("BULL POWER !! INCREASING FACTOR...", factor);
   //                   int filehandle2_w = FileOpen(filename2, FILE_WRITE|FILE_TXT);
   //                   FileWriteString(filehandle2_w, IntegerToString(factor));
   //                   FileClose(filehandle2_w);

   //                   break;
   //                } else if (OrderType() == OP_SELL && bullsPowerCheckValue() <= 0) { // nearest trailing stop 
   //                   factor += 1;

   //                   Print("BEAR POWER !! INCREASING FACTOR...", factor);
   //                   int filehandle2_w = FileOpen(filename2, FILE_WRITE|FILE_TXT);
   //                   FileWriteString(filehandle2_w, IntegerToString(factor));
   //                   FileClose(filehandle2_w);

   //                   break;
   //                } else {
   //                   Print("TAKE PROFIT NOW +-----> ", currencyProfit);
   //                   FileDelete(filename0);
   //                   FileDelete(filename1);
   //                   FileDelete(filename2);
   //                   FileDelete(filename3);

   //                   if (!OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), Slippage)) {
   //                      Print("Order Not Close with Error! ", GetLastError());
   //                   }

   //                   newsOrder = false;

   //                   break;
   //                }
   //             }

   //              if (currencyProfit <= StringToDouble(takeProfit) && takeProfit != NULL) {
   //                Print("currencyProfit < StringToDouble(takeProfit) +++++LESS+++++");
   //                if (currencyProfit > (StrToInteger(borderFactor) * VolumeSize)) {
   //                   if (OrderType() == OP_BUY && barClose < barHigh) {
   //                      Print("TAKE PROFIT NOW +-----> ", currencyProfit);
   //                      FileDelete(filename0);
   //                      FileDelete(filename1);
   //                      FileDelete(filename2);
   //                      FileDelete(filename3);

   //                      if (!OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), Slippage)) {
   //                         Print("Order Not Close with Error! ", GetLastError());
   //                      }

   //                      newsOrder = false;

   //                      break;
   //                   }
   //                   if (OrderType() == OP_SELL && barClose > barLow) {
   //                      Print("TAKE PROFIT NOW +-----> ", currencyProfit);
   //                      FileDelete(filename0);
   //                      FileDelete(filename1);
   //                      FileDelete(filename2);
   //                      FileDelete(filename3);

   //                      if (!OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), Slippage)) {
   //                         Print("Order Not Close with Error! ", GetLastError());
   //                      }

   //                      newsOrder = false;

   //                      break;
   //                   }
   //                }
   //             }
   //          }
   //       }
   //    }
   // }

   closeSet = getProfit * 2;

   if (CloseSetEnable) {
      // get orders total profit 
      for (int i=0; i<OrdersTotal(); i++) { 
         if (OrderSelect( i, SELECT_BY_POS, MODE_TRADES )) {
            totalProfit += OrderProfit() + OrderSwap() + OrderCommission();
         }

         newsOrder = false;
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

   Comment("Is News Order: ", newsOrder, " Stop Trade (News): ", stopTrade, " isCloseSet: ", (CloseSetEnable) ? closeSetMode : ToUpper("Disabled"), " || INIT FACTOR: ", initFactor, " FACTOR: ", factor, " NEW FACTOR: ", newFactor, " BORDER FACTOR: ", borderFactor, " GETPROFIT: ", getProfit, " TAKEPROFIT: ", takeProfit, " CURRENCYPROFIT: ", currencyProfit, " BUY LIMIT: ", (Period() != 60) ? IntegerToString(buyLimitCounter) + "/" + IntegerToString(OrderLimit) : ToUpper("Disabled"), " SELL LIMIT: ", (Period() != 60) ? IntegerToString(sellLimitCounter) + "/" + IntegerToString(OrderLimit) : ToUpper("Disabled"));
} 

void PrepareOrder() {

   channelTradeAction = SniperCheck();
   megaTrendCheck = MegaTrendCheck();
   
   Print("channelTradeAction: ", channelTradeAction);
   Print("megaTrendCheck: ", megaTrendCheck);
}

void NewOrder() {
   /* TEST OFFLINE */
   // channelTradeAction = "buy";

   isMegaTrend = false;
   if (MegaTrendConfirm && !newsOrder && Period() != 1) { // exclude M1 & news orders for Mega Trend
      if (channelTradeAction == megaTrendCheck) {
         isMegaTrend = true;
      }
   } else {
      isMegaTrend = true; // ELSE force true to bypass new order
   }

   if (channelTradeAction != NULL && currencyTotalOrders == 0 && !stopTrade && isMegaTrend) {
      Print("Ready to " + ToUpper(channelTradeAction) + " ...");

      int orderType = (channelTradeAction == "buy" ? OP_BUY : OP_SELL);
      double openPrice = (channelTradeAction == "buy" ? MarketInfo(Symbol(), MODE_ASK) : MarketInfo(Symbol(), MODE_BID));
      color orderColor = (channelTradeAction == "buy" ? clrBlue : clrRed);
      // initialize SL & TP to zero (0)
      double buySL = 0; double sellSL = 0;
      double buyTP = 0; double sellTP = 0;
      string comment;

      if (!newsOrder) {
         comment = TimeTo12HourFormat(timeStamp, false) + " " + symbol_str + "(" + period_str + ") HKD Forex " + VERSION;

         if (SLPoints != 0) { // only catch non-zero inputs
            buySL = openPrice - (Point() * SLPoints);
            sellSL = openPrice + (Point() * SLPoints);
         }

         if (SLPointsGold != 0) { // only catch non-zero inputs
            if (symbol_str == "XAUUSD") { // SL for GOLD
               buySL = openPrice - (Point() * SLPointsGold);
               sellSL = openPrice + (Point() * SLPointsGold);
            }
         }
      }

      if (newsOrder) { // SL during News
         comment = "NEWS >> " + TimeTo12HourFormat(timeStamp, false) + ") HKD Forex " + VERSION;

         if (SLPointsNews != 0) { // only catch non-zero inputs
            buySL = openPrice - (Point() * SLPointsNews);
            sellSL = openPrice + (Point() * SLPointsNews);
         }

         if (SLPointsNewsGold != 0) { // only catch non-zero inputs
            if (symbol_str == "XAUUSD") { // SL for GOLD
               buySL = openPrice - (Point() * SLPointsNewsGold);
               sellSL = openPrice + (Point() * SLPointsNewsGold);
            }
         }
      }

      if (channelTradeAction == "buy") {
         int ticket = OrderSend(Symbol(), orderType, VolumeSize, openPrice, Slippage, buySL, buyTP, comment, MagicNumber, 0, orderColor);

         Print("**** BUYING NOW!!! ");
         Print("Price +-----> ", openPrice);
         Print("SL +-----> ", buySL);
         Print("TP +-----> ", buyTP);
         // No order limit for H1
         if (Period() != 60 && orderLimitCounter <= OrderLimit) {
            buyLimitCounter++;
         }
      }

      if (channelTradeAction == "sell") {
         int ticket = OrderSend(Symbol(), orderType, VolumeSize, openPrice, Slippage, sellSL, sellTP, comment, MagicNumber, 0, orderColor);

         Print("**** SELLING NOW!!! ");
         Print("Price +-----> ", openPrice);
         Print("SL +-----> ", sellSL);
         Print("TP +-----> ", sellTP);
         // No order limit for H1
         if (Period() != 60 && orderLimitCounter <= OrderLimit) {
            sellLimitCounter++;
         }
      }
      // No order limit for H1
      if (Period() != 60 && orderLimitCounter <= OrderLimit) {
         orderLimitCounter++;
      }
   }
}

void CloseOrders() {
   Print("xxx Closing All Open Orders xxx");

   if (NonStopTrade) { // close only positive profit 
      stopTrade = true;
      for (int i=0; i<OrdersTotal(); i++ ) { 
         if (OrderSelect( i, SELECT_BY_POS, MODE_TRADES )) {
            if (OrderSymbol() == Symbol()) {
               if (OrderProfit() + OrderSwap() + OrderCommission() > 0) {
                  if (!OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), Slippage)) {
                     Print("Order Not Close with Error! ", GetLastError());
                  }  
               }
            }
         }
      }

      string filename0 = StringConcatenate(symbol_str, Period(), "-initFactor.txt");
      string filename1 = StringConcatenate(symbol_str, Period(), "-takeProfit.txt");
      string filename2 = StringConcatenate(symbol_str, Period(), "-newFactor.txt");
      string filename3 = StringConcatenate(symbol_str, Period(), "-borderFactor.txt");

      FileDelete(filename0);
      FileDelete(filename1);
      FileDelete(filename2);
      FileDelete(filename3);
   } else {
      for (int i=0; i<OrdersTotal(); i++ ) { 
         if (OrderSelect( i, SELECT_BY_POS, MODE_TRADES )) {
            if (OrderSymbol() == Symbol()) {
               if (!OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), Slippage)) {
                  Print("Order Not Close with Error! ", GetLastError());
               }  
            }
         }
      }

      string filename0 = StringConcatenate(symbol_str, Period(), "-initFactor.txt");
      string filename1 = StringConcatenate(symbol_str, Period(), "-takeProfit.txt");
      string filename2 = StringConcatenate(symbol_str, Period(), "-newFactor.txt");
      string filename3 = StringConcatenate(symbol_str, Period(), "-borderFactor.txt");

      FileDelete(filename0);
      FileDelete(filename1);
      FileDelete(filename2);
      FileDelete(filename3);
   }

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

bool CheckNews() {

   string base =  StringFormat("%.3s", symbol_str);
   string quote = StringSubstr(symbol_str, 3, StringLen(symbol_str)-2);

   // string localHour = IntegerToString(TimeHour(TimeLocal()));
   // string localMins = IntegerToString(TimeMinute(TimeLocal()));
   // string localNewsTime = StringConcatenate(localHour, ":", localMins);

   datetime currentLocalTime = TimeLocal();
   datetime newTime = currentLocalTime - (15 * 60); // Subtract 15 minutes (15 * 60 seconds)
   int newHour = TimeHour(newTime);
   int newMinute = TimeMinute(newTime);
   string newHourString = IntegerToString(newHour);
   string newMinuteString = IntegerToString(newMinute);
   // Ensure minutes are formatted as two digits
   if (newMinute < 10)
      newMinuteString = "0" + newMinuteString;
   string localNewsTime = StringConcatenate(newHourString, ":", newMinuteString);
   filenameNewsOn = StringConcatenate(symbol_str, Period(), "-newsOn.txt");

   // stopTrade = false;
   orderDanger = false;

   string fileBASE1 = StringConcatenate(base, "1", "-news.txt");
   string fileBASE2 = StringConcatenate(base, "2", "-news.txt");
   string fileBASE3 = StringConcatenate(base, "3", "-news.txt");
   string fileBASE4 = StringConcatenate(base, "4", "-news.txt");
   string fileBASE5 = StringConcatenate(base, "5", "-news.txt");
   string fileBASE6 = StringConcatenate(base, "6", "-news.txt");
   string fileBASE7 = StringConcatenate(base, "7", "-news.txt");
   string fileBASE8 = StringConcatenate(base, "8", "-news.txt");
   string fileBASE9 = StringConcatenate(base, "9", "-news.txt");
   string fileBASE10 = StringConcatenate(base, "10", "-news.txt");

   string fileQUOTE1 = StringConcatenate(quote, "1", "-news.txt");
   string fileQUOTE2 = StringConcatenate(quote, "2", "-news.txt");
   string fileQUOTE3 = StringConcatenate(quote, "3", "-news.txt");
   string fileQUOTE4 = StringConcatenate(quote, "4", "-news.txt");
   string fileQUOTE5 = StringConcatenate(quote, "5", "-news.txt");
   string fileQUOTE6 = StringConcatenate(quote, "6", "-news.txt");
   string fileQUOTE7 = StringConcatenate(quote, "7", "-news.txt");
   string fileQUOTE8 = StringConcatenate(quote, "8", "-news.txt");
   string fileQUOTE9 = StringConcatenate(quote, "9", "-news.txt");
   string fileQUOTE10 = StringConcatenate(quote, "10", "-news.txt");

   string filename0 = StringConcatenate(symbol_str, Period(), "-initFactor.txt");
   string filename1 = StringConcatenate(symbol_str, Period(), "-takeProfit.txt");
   string filename2 = StringConcatenate(symbol_str, Period(), "-newFactor.txt");
   string filename3 = StringConcatenate(symbol_str, Period(), "-borderFactor.txt");

   // Stop News
   for (int i=0; i<OrdersTotal(); i++) { 
      if(OrderSelect( i, SELECT_BY_POS, MODE_TRADES )) {
         if(OrderSymbol() == Symbol()) {
            if (FileIsExist(fileBASE1) || FileIsExist(fileBASE2) || FileIsExist(fileBASE3) || FileIsExist(fileBASE4) || FileIsExist(fileBASE5) || FileIsExist(fileBASE6) || FileIsExist(fileBASE7) || FileIsExist(fileBASE8) || FileIsExist(fileBASE9) || FileIsExist(fileBASE10)) {
               int fileBASE1_r = FileOpen(fileBASE1, FILE_READ|FILE_TXT);
               int fileBASE2_r = FileOpen(fileBASE2, FILE_READ|FILE_TXT);
               int fileBASE3_r = FileOpen(fileBASE3, FILE_READ|FILE_TXT);
               int fileBASE4_r = FileOpen(fileBASE4, FILE_READ|FILE_TXT);
               int fileBASE5_r = FileOpen(fileBASE5, FILE_READ|FILE_TXT);
               int fileBASE6_r = FileOpen(fileBASE6, FILE_READ|FILE_TXT);
               int fileBASE7_r = FileOpen(fileBASE7, FILE_READ|FILE_TXT);
               int fileBASE8_r = FileOpen(fileBASE8, FILE_READ|FILE_TXT);
               int fileBASE9_r = FileOpen(fileBASE9, FILE_READ|FILE_TXT);
               int fileBASE10_r = FileOpen(fileBASE10, FILE_READ|FILE_TXT);

               string base1 = FileReadString(fileBASE1_r);
               string base2 = FileReadString(fileBASE2_r);
               string base3 = FileReadString(fileBASE3_r);
               string base4 = FileReadString(fileBASE4_r);
               string base5 = FileReadString(fileBASE5_r);
               string base6 = FileReadString(fileBASE6_r);
               string base7 = FileReadString(fileBASE7_r);
               string base8 = FileReadString(fileBASE8_r);
               string base9 = FileReadString(fileBASE9_r);
               string base10 = FileReadString(fileBASE10_r);

               FileClose(fileBASE1_r);
               FileClose(fileBASE2_r);
               FileClose(fileBASE3_r);
               FileClose(fileBASE4_r);
               FileClose(fileBASE5_r);
               FileClose(fileBASE6_r);
               FileClose(fileBASE7_r);
               FileClose(fileBASE8_r);
               FileClose(fileBASE9_r);
               FileClose(fileBASE10_r);

               if (localNewsTime == base1 || localNewsTime == base2 || localNewsTime == base3 || localNewsTime == base4 || localNewsTime == base5 || localNewsTime == base6 || localNewsTime == base7 || localNewsTime == base8 || localNewsTime == base9 || localNewsTime == base10) {
                  // if (!FileIsExist(filenameNewsOn) && isNewsOn != "ONLINE") {
                  //    if (!OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), Slippage)) {
                  //       Print("Order Not Close with Error! ", GetLastError());
                  //    }
                  // }

                  if (FileIsExist(filenameNewsOn)) {
                     int filenameNewsOn_r = FileOpen(filenameNewsOn, FILE_READ|FILE_TXT);
                     isNewsOn = FileReadString(filenameNewsOn_r);
                     FileClose(filenameNewsOn_r);

                     int filenameNewsOn_w = FileOpen(filenameNewsOn, FILE_WRITE|FILE_TXT);
                     FileWriteString(filenameNewsOn_w, "ONLINE");
                     FileClose(filenameNewsOn_w);
                  } else {
                     int filenameNewsOn_w = FileOpen(filenameNewsOn, FILE_WRITE|FILE_TXT);
                     FileWriteString(filenameNewsOn_w, "ONLINE");
                     FileClose(filenameNewsOn_w);
                  }

                  // stopTrade = true;
                  orderDanger = true;

                  break;
               }
            }

            if (FileIsExist(fileQUOTE1) || FileIsExist(fileQUOTE2) || FileIsExist(fileQUOTE3) || FileIsExist(fileQUOTE4) || FileIsExist(fileQUOTE5) || FileIsExist(fileQUOTE6) || FileIsExist(fileQUOTE7) || FileIsExist(fileQUOTE8) || FileIsExist(fileQUOTE9) || FileIsExist(fileQUOTE10)) {
               int fileQUOTE1_r = FileOpen(fileQUOTE1, FILE_READ|FILE_TXT);
               int fileQUOTE2_r = FileOpen(fileQUOTE2, FILE_READ|FILE_TXT);
               int fileQUOTE3_r = FileOpen(fileQUOTE3, FILE_READ|FILE_TXT);
               int fileQUOTE4_r = FileOpen(fileQUOTE4, FILE_READ|FILE_TXT);
               int fileQUOTE5_r = FileOpen(fileQUOTE5, FILE_READ|FILE_TXT);
               int fileQUOTE6_r = FileOpen(fileQUOTE6, FILE_READ|FILE_TXT);
               int fileQUOTE7_r = FileOpen(fileQUOTE7, FILE_READ|FILE_TXT);
               int fileQUOTE8_r = FileOpen(fileQUOTE8, FILE_READ|FILE_TXT);
               int fileQUOTE9_r = FileOpen(fileQUOTE9, FILE_READ|FILE_TXT);
               int fileQUOTE10_r = FileOpen(fileQUOTE10, FILE_READ|FILE_TXT);

               string quote1 = FileReadString(fileQUOTE1_r);
               string quote2 = FileReadString(fileQUOTE2_r);
               string quote3 = FileReadString(fileQUOTE3_r);
               string quote4 = FileReadString(fileQUOTE4_r);
               string quote5 = FileReadString(fileQUOTE5_r);
               string quote6 = FileReadString(fileQUOTE6_r);
               string quote7 = FileReadString(fileQUOTE7_r);
               string quote8 = FileReadString(fileQUOTE8_r);
               string quote9 = FileReadString(fileQUOTE9_r);
               string quote10 = FileReadString(fileQUOTE10_r);

               FileClose(fileQUOTE1_r);
               FileClose(fileQUOTE2_r);
               FileClose(fileQUOTE3_r);
               FileClose(fileQUOTE4_r);
               FileClose(fileQUOTE5_r);
               FileClose(fileQUOTE6_r);
               FileClose(fileQUOTE7_r);
               FileClose(fileQUOTE8_r);
               FileClose(fileQUOTE9_r);
               FileClose(fileQUOTE10_r);

               if (localNewsTime == quote1 || localNewsTime == quote2 || localNewsTime == quote3 || localNewsTime == quote4 || localNewsTime == quote5 || localNewsTime == quote6 || localNewsTime == quote7 || localNewsTime == quote8 || localNewsTime == quote9 || localNewsTime == quote10) {
                  // if (!FileIsExist(filenameNewsOn) && isNewsOn != "ONLINE") {
                  //    if (!OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), Slippage)) {
                  //       Print("Order Not Close with Error! ", GetLastError());
                  //    }
                  // }

                  if (FileIsExist(filenameNewsOn)) {
                     int filenameNewsOn_r = FileOpen(filenameNewsOn, FILE_READ|FILE_TXT);
                     isNewsOn = FileReadString(filenameNewsOn_r);
                     FileClose(filenameNewsOn_r);

                     int filenameNewsOn_w = FileOpen(filenameNewsOn, FILE_WRITE|FILE_TXT);
                     FileWriteString(filenameNewsOn_w, "ONLINE");
                     FileClose(filenameNewsOn_w);
                  } else {
                     int filenameNewsOn_w = FileOpen(filenameNewsOn, FILE_WRITE|FILE_TXT);
                     FileWriteString(filenameNewsOn_w, "ONLINE");
                     FileClose(filenameNewsOn_w);
                  }

                  // stopTrade = true;
                  orderDanger = true;

                  break;
               }
            }
         }
      }
   }

   if (!orderDanger) {
      FileDelete(filenameNewsOn);
      isNewsOn = NULL;
      newsOrder = false;
   }

   return orderDanger;
}

// void TradeNews() {
//    Print("+++ Trading News Now +++");
   
//    double buyTP = 0; double sellTP = 0;
//    double buySL = MarketInfo(Symbol(), MODE_ASK) - (Point() * 50);
//    double sellSL = MarketInfo(Symbol(), MODE_BID) + (Point() * 50);
   
//    if (currencyTotalOrders == 0) {
//       Print("Fully Hedged!!! ");

//       int ticketBuy = OrderSend(Symbol(), OP_BUY, VolumeSize, MarketInfo(Symbol(), MODE_ASK), Slippage, buySL, buyTP, symbol_str + period + " EH-NEWS_v9.6 " + timeStamp, MagicNumber, 0, clrBlue);

//       Print("**** NEWS BUYING NOW!!! ");
//       Print("Price +-----> ", MarketInfo(Symbol(), MODE_ASK));
//       Print("SL +-----> ", buySL);
//       Print("TP +-----> ", buyTP);

//       int ticketSell = OrderSend(Symbol(), OP_SELL, VolumeSize, MarketInfo(Symbol(), MODE_BID), Slippage, sellSL, sellTP, symbol_str + period + " EH-NEWS_v9.6 " + timeStamp, MagicNumber, 0, clrRed);

//       Print("**** NEWS SELLING NOW!!! ");
//       Print("Price +-----> ", MarketInfo(Symbol(), MODE_BID));
//       Print("SL +-----> ", sellSL);
//       Print("TP +-----> ", sellTP);
//    } else {

//       if (currencyBuyCount == 0 && currencySellCount != 0) {
//          int ticketBuy = OrderSend(Symbol(), OP_BUY, VolumeSize, MarketInfo(Symbol(), MODE_ASK), Slippage, buySL, buyTP, symbol_str + period + " EH-NEWS_v9.6 " + timeStamp, MagicNumber, 0, clrBlue);

//          Print("**** NEWS BUYING NOW!!! ");
//          Print("Price +-----> ", MarketInfo(Symbol(), MODE_ASK));
//          Print("SL +-----> ", buySL);
//          Print("TP +-----> ", buyTP);
//       }

//       if (currencySellCount == 0 && currencyBuyCount != 0) {
//          int ticketSell = OrderSend(Symbol(), OP_SELL, VolumeSize, MarketInfo(Symbol(), MODE_BID), Slippage, sellSL, sellTP, symbol_str + period + " EH-NEWS_v9.6 " + timeStamp, MagicNumber, 0, clrRed);

//          Print("**** NEWS SELLING NOW!!! ");
//          Print("Price +-----> ", MarketInfo(Symbol(), MODE_BID));
//          Print("SL +-----> ", sellSL);
//          Print("TP +-----> ", sellTP);
//       }
//    }

//    setNews = true;
// }

double ATRCheck() {
   double atr = iATR(Symbol(), Period(), 14, 1);

   return atr;
}

string MegaTrendCheck() {
   double megeTrend = iCustom(Symbol(), Period(), "\\Custom\\HKD MegaTrend", "", false, false, false, false, "alert.wav", "current", true, 0);
   megaTrendCheck = NULL;

   Print("Mega Trend: ", megeTrend);

   if (megeTrend > 0) {
      megaTrendCheck = "buy" ;
   }

   if (megeTrend < 0) {
      megaTrendCheck = "sell" ;
   }

   return megaTrendCheck;
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

string TimeTo12HourFormat(string _time, bool _showsec) {
   datetime dtValue = StringToTime(_time);
   MqlDateTime timeStruct;
   TimeToStruct(dtValue, timeStruct);

   int hour = timeStruct.hour;
   int minute = timeStruct.min;
   int second = timeStruct.sec;
   string ampm = "am";

   if (hour >= 12) {
      ampm = "pm";
      if (hour > 12) hour -= 12;
      else if (hour == 0) hour = 12;
   }

   if (!_showsec) return StringFormat("%02d:%02d%s", hour, minute, ampm);
   else return StringFormat("%02d:%02d:%02d%s", hour, minute, second, ampm);
}

string RemoveTrailingSigns(string _symbol) {
    int len = StringLen(_symbol);

    if (len > 6) _symbol = StringSubstr(_symbol, 0, len - 1);

    return _symbol;
}

string PeriodToString(int _period) {
   switch(_period) {
      case PERIOD_M1:   return "M1";
      case PERIOD_M5:   return "M5";
      case PERIOD_M15:  return "M15";
      case PERIOD_M30:  return "M30";
      case PERIOD_H1:   return "H1";
      case PERIOD_H4:   return "H4";
      case PERIOD_D1:   return "D1";
      case PERIOD_W1:   return "W1";
      case PERIOD_MN1:  return "MN1";
      default:          return "??";
   }
}

string ToUpper(string text) { 
   StringToUpper(text);
   return text; 
}
