read_data = function(input_filename, remove_zero_volume, normalize_closeness, interaction_terms) {
  data = read.csv(file = input_filename, header = TRUE, sep = ",")
  data$earliest_mention_date_str = as.character(data$earliest_mention_date, format = "%Y-%m-%d")
  data$earliest_mention_date_date = as.Date(data$earliest_mention_date)
  data$network_date_str = as.character(data$network_date, format = "%Y-%m-%d")
  data$network_date_date = as.Date(data$network_date)
  data$earliest_trade_date_str = as.character(data$earliest_trade_date, format = "%Y-%m-%d")
  data$earliest_trade_date_date = as.Date(data$earliest_trade_date)
  data$date_control = as.integer(data$earliest_trade_date_date - min(data$earliest_trade_date_date))
  
  # normalize centralities by average path length
  if (normalize_closeness) {
    data$user1_closeness_centrality_weighted = data$user1_closeness_centrality_weighted * data$unweighted_average_path_length
    data$user1_closeness_centrality_unweighted = data$user1_closeness_centrality_unweighted * data$unweighted_average_path_length
  }
  data$log_severity_to_average_after_max_volume_weighted = log(data$severity_to_average_after_max_volume_weighted)
  data$magnitude = data$normalized_total_volume_before_max / data$normalized_total_volume
  data$log_magnitude = log(data$magnitude)
  data$magnitude_orig = data$normalized_total_volume_orig_before_max / data$normalized_total_volume_orig
  data$log_magnitude_orig = log(data$magnitude_orig)
  # add interaction terms
  if (interaction_terms) {
    data$user1_clustering_coefficient_nontrivial = data$user1_clustering_coefficient * data$nontrivial
    data$user1_closeness_centrality_weighted_nontrivial = data$user1_closeness_centrality_weighted * data$nontrivial
    data$user1_betweenness_centrality_weighted_nontrivial = data$user1_betweenness_centrality_weighted * data$nontrivial
    data$user1_satoshi_pagerank_weighted_nontrivial = data$user1_satoshi_pagerank_weighted * data$nontrivial
    data$user1_pagerank_weighted_nontrivial = data$user1_pagerank_weighted * data$nontrivial
    data$user1_degree_incoming_nontrivial = data$user1_degree_incoming * data$nontrivial
    data$user1_degree_outgoing_nontrivial = data$user1_degree_outgoing * data$nontrivial
  }
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

# a function for taking the average of a field by the closest points to it in date 
average_sd_by_closest_date = function(df, field) {
  for(i in 1:nrow(df)) {
    row = df[i,]
    indices = which(df$network_date_date > (row["network_date_date"] - 25) &
                    df$network_date_date < (row["network_date_date"] + 25))
    df[i,paste0(field,"_average")] = mean(df[indices, field])
    df[i,paste0(field,"_sd")] = sd(df[indices, field])
  }
  return(df)
}

normalize_by_closest_date = function(df1, field) {
  df = average_sd_by_closest_date(df1, field)
  df[,field] = (df[,field] - df[,paste0(field,"_average")]) / df[,paste0(field,"_sd")]
  df = df[!is.na(df[,field]),]
  return(df)
}