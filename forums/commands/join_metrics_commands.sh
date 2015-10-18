# change both headers to network_date

sort -t, -k1 directed_networks_unlimited_0.995decay_by_date_metrics.csv > ./directed_networks_unlimited_0.995decay_by_date_metrics_sorted.csv

sort -t, -k2 directed_networks_unlimited_0.995decay_metrics_without_general_network.csv > ./directed_networks_unlimited_0.995decay_metrics_without_general_network_sorted.csv

join -t, -a 2 -1 1 -2 2 ./directed_networks_unlimited_0.995decay_by_date_metrics_sorted.csv ./directed_networks_unlimited_0.995decay_metrics_without_general_network_sorted.csv > tmp

# move header to top
# remove ^Ms:
sed -i -e 's/CTRL-V+M//g' tmp

# remove dup columnns
cut -d, -f1-11,15- ./tmp > ./directed_networks_unlimited_0.995decay_metrics.csv

rm tmp
