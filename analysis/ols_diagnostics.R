#setwd(dir = "~/research/nikete/Comunity-Structure-Extremely-Speculative-Asset-Dynamics/")
setwd(dir = "data/")
data = read.csv(file = "joined_with_fallback_d200.csv", header = TRUE, sep = ",")
#data$network_date = as.Date(data$network_date, format = "%d-%m-%Y")
#data$earliest_trade_date = as.character(data$earliest_trade_date, format = "%Y-%m-%d")
data$network_date = as.character(data$network_date, format = "%Y-%m-%d")
data$earliest_trade_date = as.character(data$earliest_trade_date, format = "%Y-%m-%d")

dates = sort(data$earliest_trade_date)

lmfit = lm(data$severity_to_average_after_max_volume_weighted ~
           data$user1_num_mentions + data$user1_num_posts + data$user1_num_subjects + data$user1_days_since_first_post +
           data$user1_degree_total +
           data$user1_degree_incoming +
           data$user1_degree_outgoing +
           data$user1_clustering_coefficient +
           data$user1_closeness_centrality_unweighted + 
           data$user1_closeness_centrality_weighted + 
           data$user1_closeness_centrality_incoming_unweighted + 
           data$user1_closeness_centrality_outgoing_unweighted + 
           data$user1_closeness_centrality_incoming_weighted + 
           data$user1_closeness_centrality_outgoing_weighted +
           data$user1_betweenness_centrality_weighted +
           #data$user1_satoshi_distance +
           data$user1_satoshi_pagerank_unweighted +
           data$user1_satoshi_pagerank_weighted +
           data$user1_pagerank_unweighted +
           data$user1_pagerank_weighted,
           data)
summary(lmfit)
