library(car)
library(lmtest)
setwd(dir = "~/research/nikete/Comunity-Structure-Extremely-Speculative-Asset-Dynamics/data")
data = read.csv(file = "joined_with_fallback.csv", header = TRUE, sep = ",")
data = read.csv(file = "joined_with_fallback_d200.csv", header = TRUE, sep = ",")
data = read.csv(file = "joined_with_fallback_d100.csv", header = TRUE, sep = ",")
data$network_date = as.character(data$network_date, format = "%Y-%m-%d")
data$earliest_trade_date = as.character(data$earliest_trade_date, format = "%Y-%m-%d")
data$log_severity_to_average_after_max_volume_weighted = log(data$severity_to_average_after_max_volume_weighted)

data_size = nrow(data)
# 60% train
train_size = floor(0.60 * data_size)
# reporoducible partition?
set.seed(19870209)
train_indices = sample(seq(data_size), size = train_size)

train_data = data[train_indices, ]
test_data = data[-train_indices, ]

lmfit = lm(log_severity_to_average_after_max_volume_weighted ~
           #user1_num_mentions +
           user1_num_posts +
           user1_num_subjects +
           user1_days_since_first_post +
           user1_degree_total +
           user1_degree_incoming +
           #user1_degree_outgoing +
           user1_clustering_coefficient +
           #user1_closeness_centrality_unweighted + 
           user1_closeness_centrality_weighted + 
           #user1_closeness_centrality_incoming_unweighted + 
           #user1_closeness_centrality_outgoing_unweighted + 
           #user1_closeness_centrality_incoming_weighted + 
           #user1_closeness_centrality_outgoing_weighted +
           user1_betweenness_centrality_weighted +
           #user1_satoshi_distance +
           #user1_satoshi_pagerank_unweighted +
           user1_satoshi_pagerank_weighted +
           #user1_pagerank_unweighted +
           user1_pagerank_weighted +
           nontrivial +
           nontrivial*user1_closeness_centrality_weighted,
           train_data)
summary(lmfit)
plot(lmfit, which=1, ask=F)
plot(lmfit, which=2, ask=F)
plot(lmfit, which=3, ask=F)
plot(lmfit, which=4, ask=F)
plot(lmfit, which=5, ask=F)

vars =  c("log_severity_to_average_after_max_volume_weighted",
          "user1_num_posts",
          "user1_num_subjects",
          "user1_days_since_first_post",
          "user1_degree_incoming",
          "user1_degree_outgoing",
          "user1_clustering_coefficient",
          "user1_closeness_centrality_unweighted",
          "user1_closeness_centrality_weighted",
          "user1_closeness_centrality_incoming_unweighted",
          "user1_closeness_centrality_outgoing_unweighted",
          "user1_closeness_centrality_incoming_weighted",
          "user1_closeness_centrality_outgoing_weighted",
          "user1_betweenness_centrality_weighted",
          "user1_satoshi_distance",
          "user1_satoshi_pagerank_unweighted",
          "user1_satoshi_pagerank_weighted",
          "user1_pagerank_unweighted",
          "user1_pagerank_weighted",
          "nontrivial")

# get outlier points
train_data[which(cooks.distance(lmfit) > 50/nrow(train_data)), vars]
which(cooks.distance(lmfit) > 50/nrow(train_data))
plot(cooks.distance(lmfit))
influencePlot(lmfit)

# test for heteroskedasticity
bptest(lmfit)

# remove highly influential points
remove = -c(44,115)
train_data = train_data[remove,]
remove = -c(135)
train_data = train_data[remove,]

# test
predictions = predict.lm(lmfit, test_data)
plot(predictions, test_data$severity_to_average_after_max_volume_weighted, xlim=c(0,5), ylim=c(0,5))
