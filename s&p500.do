*(c)2020 @btconometrics *
*PayNyms: PM8TJM21BotU4qbspoYeUABiH1GqvNeD3fgAQLb9DtR5ouUqrPWeCnRzx4N6S4VenX7wWYMA7NhnCu1SJpCXTFp97HTF4oodKEqtPDEeL4amCuq3Z4VC
*written with stata 14*

*get daily data from coinmetrics and yahoo finance*
import delimited "https://query1.finance.yahoo.com/v7/finance/download/%5EGSPC?period1=-1325635200&period2=1586563200&interval=1d&events=history", clear

*fix date formats and tsset the data*
gen d = date(date, "YMD")
drop date
rename d date
format %td date
tsset date

tempfile sp500
save `sp500'

import delimited "https://coinmetrics.io/newdata/btc.csv", clear
gen d = date(date, "YMD")
drop date
rename d date
format %td date
tsset date
replace date = 17900 + _n-1 if date == .
replace  blkcnt = 6*24 if blkcnt == .

gen long sum_blocks = sum(blkcnt)
gen long hp_blocks = mod(sum_blocks, 210001)

gen hindicator = 0
replace hindicator = 1 if hp_blocks <200 & hp_blocks[_n-1]>209000

gen long hperiod =sum(hindicator) -1

gen double reward = 50/(2^hperiod)
 
gen double daily_reward = blkcnt * reward
gen double tsupply = sum(daily_reward)
tsset date
gen double flow = tsupply[_n+365]-tsupply[_n]
gen double s2f = tsupply/flow
gen lns2f = ln(s2f)
gen lnprice = ln(priceusd)

keep lnprice lns2f date diffmean
merge 1:1 date using `sp500'
gen lnclose = ln(close)
reg lnprice lnclose
estat bgod
prais lnprice lnclose
zandrews lnprice
zandrews lnclose
zandrews d.lnprice
zandrews d.lnclose
ardl lnprice lnclose, ec
estat ectest
prais lnprice lnclose lns2f
predict yhat
tsline yhat lnprice if date>d(1jan2010)

