
df_btc = read.csv('../data/joined_price_network_btc.csv', stringsAsFactors = F)
df_usd = read.csv('../data/joined_price_network_usd.csv', stringsAsFactors = F)
data = read.csv('../data/introducers/all_introducer_metrics.csv', stringsAsFactors = F)

data$earliest_mention_date_str = as.character(data$earliest_mention_date, format = "%Y-%m-%d")
data$earliest_mention_date_date = as.Date(data$earliest_mention_date)
data$network_date_str = as.character(data$network_date, format = "%Y-%m-%d")
data$network_date_date = as.Date(data$network_date)
data$earliest_trade_date_str = as.character(data$earliest_trade_date, format = "%Y-%m-%d")
data$earliest_trade_date_date = as.Date(data$earliest_trade_date)
  data$date_control = as.integer(data$earliest_trade_date_date - min(data$earliest_trade_date_date))

data$user1_closeness_centrality_weighted = data$user1_closeness_centrality_weighted * data$unweighted_average_path_length




#cutoff = max(data[data$user1_closeness_centrality_weighted > 95,'network_date_date'])
#sub = data[(data$network_date_date <= cutoff) & (data$coin != "BTC"),]

#cutoff = min(data[data$user1_closeness_centrality_weighted < 70,'network_date_date'])
#sub = data[(data$network_date_date > cutoff) & (data$coin != "BTC"),]

sub = data[data$coin != "BTC",]

sub$usd_severity = NA
sub$usd_volume = NA
sub$btc_severity = NA
sub$btc_volume = NA

for(i in 1:nrow(sub)) {
  ind = df_btc['symbol'] == sub$coin[i]
  if(sum(ind) > 0) {
    #sub$severity[i] = df[ind,'max_price']
    #sub$volume[i] = df[ind,'total_volume']
    sub$usd_severity[i] = df_usd[ind,'severity_to_average_after_max']
    sub$usd_volume[i] = df_usd[ind,'normalized_total_volume_before_max']
    sub$btc_severity[i] = df_btc[ind,'severity_to_average_after_max']
    sub$btc_volume[i] = df_btc[ind,'normalized_total_volume_before_max']
  }
}

#plot(sub$network_date_date, sub$user1_closeness_centrality_weighted)

pdf('../images/severity-usd.pdf',3,3)
par(oma = c(0,0,0,0) + 0.1,
    mar = c(3.5,3.5,1,1) + 0.1)
plot(sub$network_date_date, log(sub$usd_severity), pch = 20, cex = 0.5, xlab = '', ylab = '')
title(xlab="Date", line=2.2, cex.lab=1.2, family="Times")
title(ylab="Severity (USD)", line=2.2, cex.lab=1.2, family="Times")
dev.off()

pdf('../images/magnitude-usd.pdf',3,3)
par(oma = c(0,0,0,0) + 0.1,
    mar = c(3.5,3.5,1,1) + 0.1)
plot(sub$network_date_date, log(sub$usd_volume), pch = 20, cex = 0.5, xlab = '', ylab = '')
title(xlab="Date", line=2.2, cex.lab=1.2, family="Times")
title(ylab="Magnitude (USD)", line=2.2, cex.lab=1.2, family="Times")
dev.off()

pdf('../images/severity-btc.pdf',3,3)
par(oma = c(0,0,0,0) + 0.1,
    mar = c(3.5,3.5,1,1) + 0.1)
plot(sub$network_date_date, log(sub$btc_severity), pch = 20, cex = 0.5, xlab = '', ylab = '')
title(xlab="Date", line=2.2, cex.lab=1.2, family="Times")
title(ylab="Severity (BTC)", line=2.2, cex.lab=1.2, family="Times")
dev.off()

pdf('../images/magnitude-btc.pdf',3,3)
par(oma = c(0,0,0,0) + 0.1,
    mar = c(3.5,3.5,1,1) + 0.1)
plot(sub$network_date_date, log(sub$btc_volume), pch = 20, cex = 0.5, xlab = '', ylab = '')
title(xlab="Date", line=2.2, cex.lab=1.2, family="Times")
title(ylab="Magnitude (BTC)", line=2.2, cex.lab=1.2, family="Times")
dev.off()


#plot(sub$user1_closeness_centrality_weighted, log(sub$severity))
#plot(sub$user1_closeness_centrality_weighted, log(sub$volume))

