library(glmnet)
library(MASS)
setwd(dir = "~/research/nikete/Comunity-Structure-Extremely-Speculative-Asset-Dynamics/")
source("analysis/elastic_net.R")
setwd(dir = "data")
#data = read.csv(file = "joined_with_fallback.csv", header = TRUE, sep = ",")
data = read.csv(file = "joined_with_fallback_d200.csv", header = TRUE, sep = ",")
#data = read.csv(file = "joined_with_fallback_d100.csv", header = TRUE, sep = ",")
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

all_independent_vars =  c("user1_num_posts",
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
cor(train_data[,all_independent_vars])
cor(train_data[,all_independent_vars])>0.95
good_independent_vars =  c("user1_num_posts",
                          "user1_num_subjects",
                          "user1_days_since_first_post",
                          "user1_degree_incoming",
                          "user1_degree_outgoing",
                          "user1_clustering_coefficient",
                          "user1_closeness_centrality_weighted",
                          "user1_betweenness_centrality_weighted",
                          #"user1_satoshi_distance",
                          "user1_satoshi_pagerank_weighted",
                          "user1_pagerank_weighted",
                          "nontrivial")
dependent_var = "log_severity_to_average_after_max_volume_weighted"
x = data.matrix(train_data[,good_independent_vars])
y = train_data[,dependent_var]

# find the best elastic net model config
alphas=seq(1,1,by=0.05)
best_model = cross_validate_alphas(x, y, alphas)
best_alpha = best_model[2]
nonzero_coefs = extract_nonzero_coefs(best_model$coefs)

lm_formula = paste(dependent_var, "~", paste(nonzero_coefs, collapse=" + "))
lmfit = lm(as.formula(lm_formula), train_data)
summary(lmfit)
# investigate the assumption of ols
oldpar = par(mfrow = c(2,2))
plot(lmfit, las=1)
par(oldpar)
train_data[which(cooks.distance(lmfit) > 30/nrow(train_data)), c("coin_name", dependent_var, nonzero_coefs)]

# get nonzero coefficients on best alpha 
cvfit = cv.glmnet(x, y, nfolds=5, type.measure="mse", standardize=T, alpha=best_alpha)
plot(cvfit)
cvfit$lambda.min
coef(cvfit, s="lambda.min")


# run robust regression using iterated re-weighted least square
rlmfit = rlm(as.formula(lm_formula), train_data)
summary = summary(rlmfit)
dd = data.frame(summary$coefficients)
dd$p.value = 2*pt(abs(dd$t.value), summary$df[2], lower.tail=FALSE)
dd

# check the weights assigned to each coin
weights = data.frame(coin=train_data[,"coin_name"], log_severity=train_data[,dependent_var], residual=rlmfit$residuals, weight = rlmfit$w)
weights_ordered = weights[order(rlmfit$w),]
weights_ordered[1:15,]
