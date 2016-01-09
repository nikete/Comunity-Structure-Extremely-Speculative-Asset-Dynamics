read_data = function(input_filename, remove_zero_volume) {
  data = read.csv(file = input_filename, header = TRUE, sep = ",")
  data$earliest_mention_date_str = as.character(data$earliest_mention_date, format = "%Y-%m-%d")
  data$earliest_mention_date_date = as.Date(data$earliest_mention_date)
  data$network_date_str = as.character(data$network_date, format = "%Y-%m-%d")
  data$network_date_date = as.Date(data$network_date)
  data$earliest_trade_date_str = as.character(data$earliest_trade_date, format = "%Y-%m-%d")
  data$earliest_trade_date_date = as.Date(data$earliest_trade_date)
  data$date_control = as.integer(data$earliest_trade_date_date - min(data$earliest_trade_date_date))
  
  data$log_severity_to_average_after_max_volume_weighted = log(data$severity_to_average_after_max_volume_weighted)
  data$magnitude = data$normalized_total_volume_before_max / data$normalized_total_volume
  data$log_magnitude = log(data$magnitude)
  data$magnitude_orig = data$normalized_total_volume_orig_before_max / data$normalized_total_volume_orig
  data$log_magnitude_orig = log(data$magnitude_orig)
  # fix infinite satoshi distance
  data$user1_satoshi_distance_inf = data$user1_satoshi_distance>7
  data$user1_satoshi_distance[data$user1_satoshi_distance_inf] = 7
  
  if (remove_zero_volume) {
    data = data[data$magnitude!=0,]
  }
  
  # remove btc if present
  data = data[data$symbol != "BTC",]
  return(data)
}