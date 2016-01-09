library(car)
library(lmtest)
setwd(dir = "~/research/nikete/Comunity-Structure-Extremely-Speculative-Asset-Dynamics/data")
data = read.csv(file = "joined_price_network_usd.csv", header = TRUE, sep = ",")
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

# remove btc if present
data = data[data$symbol != "BTC",]

data_size = nrow(data)
# 60% train
train_size = floor(0.60 * data_size)
# reporoducible partition?
set.seed(19870209)
train_indices = sample(seq(data_size), size = train_size)

train_data = data[train_indices, ]
test_data = data[-train_indices, ]

independent_vars =  c("user1_num_posts",
                      "user1_num_subjects",
                      "user1_days_since_first_post",
                      "user1_degree_incoming",
                      "user1_degree_outgoing",
                      "user1_clustering_coefficient",
                      "user1_closeness_centrality_weighted",
                      "user1_betweenness_centrality_weighted",
                      "user1_satoshi_distance",
                      "user1_satoshi_distance_inf",
                      "user1_satoshi_pagerank_weighted",
                      "user1_pagerank_weighted")
dependent_var = "log_severity_to_average_after_max_volume_weighted"
lm_formula = paste(dependent_var, "~", paste(independent_vars, collapse=" + "))
lmfit = lm(as.formula(lm_formula), train_data)
summary(lmfit)
plot(lmfit, which=1, ask=F)
plot(lmfit, which=2, ask=F)
plot(lmfit, which=3, ask=F)
plot(lmfit, which=4, ask=F)
plot(lmfit, which=5, ask=F)

# get outlier points
train_data[which(cooks.distance(lmfit) > 30/nrow(train_data)), independent_vars]
which(cooks.distance(lmfit) > 30/nrow(train_data))
plot(cooks.distance(lmfit))
influencePlot(lmfit)

# test for heteroskedasticity
bptest(lmfit)

# remove highly influential points
remove = -c(144,335)
train_data = train_data[remove,]
remove = -c(14)
train_data = train_data[remove,]
remove = -c(121)
train_data = train_data[remove,]

# test
predictions = predict.lm(lmfit, test_data)
plot(predictions, test_data[,dependent_var], xlim=c(0,10), ylim=c(0,10), ylab="actual", xlab="predicted")
abline(a=0, b=1)
