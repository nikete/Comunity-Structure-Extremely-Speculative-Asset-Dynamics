library(glmnet)

setwd(dir = "~/Desktop/bitcoin-paper/Comunity-Structure-Extremely-Speculative-Asset-Dynamics/")
setwd(dir = "data/")
#data = read.csv(file = "joined_with_fallback.csv", header = TRUE, sep = ",")
data = read.csv(file = "joined_with_fallback_d200.csv", header = TRUE, sep = ",")
#data = read.csv(file = "joined_with_fallback_d100.csv", header = TRUE, sep = ",")
data$network_date = as.character(data$network_date, format = "%Y-%m-%d")
data$earliest_trade_date = as.character(data$earliest_trade_date, format = "%Y-%m-%d")
data$log_severity_to_average_after_max_volume_weighted = log(data$severity_to_average_after_max_volume_weighted)

data_size = nrow(data)
# 70% train
train_size = floor(0.70 * data_size)
# reporoducible partition?
set.seed(19870209)
train_indices = sample(seq(data_size), size = train_size)

train_data = data[train_indices, ]
test_data = data[-train_indices, ]

all_independent_vars =  c("user1_num_mentions",
                          "user1_num_posts",
                          "user1_num_subjects",
                          "user1_days_since_first_post",
                          "user1_degree_total",
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
                          #"user1_satoshi_distance",
                          "user1_satoshi_pagerank_unweighted",
                          "user1_satoshi_pagerank_weighted",
                          "user1_pagerank_unweighted",
                          "user1_pagerank_weighted",
                          "nontrivial")
dependent_var = "log_severity_to_average_after_max_volume_weighted"

x = data.matrix(train_data[,all_independent_vars])
y = train_data[,dependent_var]

cvfit = cv.glmnet(x, y, nfolds=5, type.measure="mse", standardize=T, alpha=0.1)
plot(cvfit)
cvfit$lambda.min
coef(cvfit, s="lambda.min")
cvfit$lambda.1se
coef(cvfit, s="lambda.1se")

# function to perform cross validation on both alpha and lambda parameters of GLM
# returns best alpha and lambda plus other info on the best model
cross_validate_alphas = function(x, y, alphas) {
  #step 1: do all crossvalidations for each alpha
  cvfits = lapply(alphas, function(cur_alpha){
    cvfit = cv.glmnet(x, y, nfolds=5, type.measure="mse", standardize=T, alpha=cur_alpha)
  })
  #step 2: collect the optimum lambda for each alpha
  optimum_per_alpha = sapply(seq_along(alphas), function(cur_i){
    cur_cvfit = cvfits[[cur_i]]
    cur_alpha = alphas[cur_i]
    min_index = match(cur_cvfit$lambda.min, cur_cvfit$lambda)
    c(lambda=cur_cvfit$lambda[min_index], alpha=cur_alpha,
      non_zero_coefs = cur_cvfit$nzero[[min_index]],
      cv_low=cur_cvfit$cvlo[min_index], 
      cv=cur_cvfit$cvm[min_index], 
      cv_up=cur_cvfit$cvup[min_index])
  })
  
  #step 3: find the overall optimum
  optimum_index = which.min(optimum_per_alpha["cv",])
  return(c(lambda=optimum_per_alpha[["lambda", optimum_index]],
           alpha=optimum_per_alpha[["alpha",optimum_index]],
           non_zero_coefs=optimum_per_alpha[["non_zero_coefs",optimum_index]],
           cv_low=optimum_per_alpha[["cv_low",optimum_index]],
           cv=optimum_per_alpha[["cv",optimum_index]],
           cv_up=optimum_per_alpha[["cv_up",optimum_index]]))
}
# find the best model config
best_model = cross_validate_alphas(x, y, alphas = seq(0,1,by=0.01))
best_model
best_alpha = best_model[2]
# get nonzero coefficients on best alpha 
cvfit = cv.glmnet(x, y, nfolds=5, type.measure="mse", standardize=T, alpha=best_alpha)
plot(cvfit)
cvfit$lambda.min
coef(cvfit, s="lambda.min")
