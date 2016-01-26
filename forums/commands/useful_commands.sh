sort -k1 -t, general_network_metrics.csv > 1_sorted

sort -k4 -t, all_introducer_metrics_without_general_network_metrics.csv  > ../2_sorted

join -1 1 -2 4 -t , 1_sorted 2_sorted > joined

wc -l joined general_network_metrics.csv ./introducers/all_introducer_metrics_without_general_network_metrics.csv



awk -F',' -v OFS=',' '{print $9,$10,$11,$1,$2,$3,$4,$5,$6,$7,$8,$12,$13,$14,$15,$16,$17,$18,$19,$20,$21,$22,$23,$24,$25,$26,$27,$28,$29,$30,$31,$32}' joined > 1

mv 1 ./introducers/all_introducer_metrics.csv

../analysis/join_data.py -d 1000 -t nontrivial.csv coin_measures_usd.csv ./introducers/all_introducer_metrics.csv ./joined_price_network_trivialness_usd.csv
../analysis/join_data.py -d 1000 -t nontrivial.csv coin_measures_btc.csv ./introducers/all_introducer_metrics.csv ./joined_price_network_trivialness_btc.csv
../analysis/join_data.py -d 1000 coin_measures_usd.csv ./introducers/all_introducer_metrics.csv ./joined_price_network_usd.csv
../analysis/join_data.py -d 1000 coin_measures_btc.csv ./introducers/all_introducer_metrics.csv ./joined_price_network_btc.csv
 
