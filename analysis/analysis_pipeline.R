library(glmnet)
library(MASS)
library(sandwich)
library(lmtest)
setwd(dir = "~/research/nikete/Comunity-Structure-Extremely-Speculative-Asset-Dynamics/")
source("analysis/elastic_net.R")
setwd(dir = "data")
#data = read.csv(file = "joined_with_fallback.csv", header = TRUE, sep = ",")
data = read.csv(file = "joined_with_fallback_d200.csv", header = TRUE, sep = ",")
#data = read.csv(file = "joined_with_fallback_d100.csv", header = TRUE, sep = ",")
data$network_date = as.character(data$network_date, format = "%Y-%m-%d")
data$earliest_trade_date = as.character(data$earliest_trade_date, format = "%Y-%m-%d")
data$log_severity_to_average_after_max_volume_weighted = log(data$severity_to_average_after_max_volume_weighted)
# add interaction terms
data$user1_clustering_coefficient_nontrivial = data$user1_clustering_coefficient * data$nontrivial
data$user1_closeness_centrality_weighted_nontrivial = data$user1_closeness_centrality_weighted * data$nontrivial
data$user1_betweenness_centrality_weighted_nontrivial = data$user1_betweenness_centrality_weighted * data$nontrivial
data$user1_satoshi_pagerank_weighted_nontrivial = data$user1_satoshi_pagerank_weighted * data$nontrivial
data$user1_pagerank_weighted_nontrivial = data$user1_pagerank_weighted * data$nontrivial
# fix infinite satoshi distance
data$user1_satoshi_distance_inf = data$user1_satoshi_distance>7
data$user1_satoshi_distance[data$user1_satoshi_distance_inf] = 7


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
                          "user1_clustering_coefficient_nontrivial",
                          "user1_closeness_centrality_weighted",
                          "user1_closeness_centrality_weighted_nontrivial",
                          "user1_betweenness_centrality_weighted",
                          "user1_betweenness_centrality_weighted_nontrivial",
                          "user1_satoshi_pagerank_weighted",
                          "user1_satoshi_pagerank_weighted_nontrivial",
                          "user1_pagerank_weighted",
                          "user1_pagerank_weighted_nontrivial",
                          "nontrivial")
cor(train_data[,good_independent_vars])>0.9
dependent_var = "log_severity_to_average_after_max_volume_weighted"
x = data.matrix(train_data[,good_independent_vars])
y = train_data[,dependent_var]


# Initial exploration, using all vars. No specific model
# find the best elastic net model config and get nonzero coefficients on best alpha 
alphas=seq(1,1,by=0.05)
best_model = cross_validate_alphas(x, y, alphas)
best_alpha = best_model[2]
nonzero_coefs = extract_nonzero_coefs(best_model$coefs)
# plot the cross validated alpha results
cvfit = cv.glmnet(x, y, nfolds=5, type.measure="mse", standardize=T, alpha=best_alpha)
plot(cvfit)
cvfit$lambda.min
coef(cvfit, s="lambda.min")

# Run simple ols
lm_formula = paste(dependent_var, "~", paste(nonzero_coefs, collapse=" + "))
lmfit = lm(as.formula(lm_formula), train_data)
summary(lmfit)

# investigate the assumption of ols
oldpar = par(mfrow = c(2,2))
plot(lmfit, las=1)
par(oldpar)
train_data[which(cooks.distance(lmfit) > 30/nrow(train_data)), c("coin_name", dependent_var, nonzero_coefs)]

# get robust standard errors
robust_se = diag(vcovHC(lmfit, type="HC"))^0.5
coeftest(lmfit, vcov=vcovHC(lmfit, "HC0"))
coeftest(lmfit, vcov=vcovHC(lmfit, "HC2"))
coeftest(lmfit, vcov=vcovHC(lmfit, "HC3"))



# run robust regression using iterated re-weighted least square
rlmfit = rlm(as.formula(lm_formula), train_data, psi="psi.huber", method="M", model=T)
summary = summary(rlmfit)
dd = data.frame(summary$coefficients)
dd$p.value = 2*pt(abs(dd$t.value), summary$df[2], lower.tail=FALSE)
dd
# above uses the psi.huber penalty function. but below we simply use mse.
# the results are similar nevertheless.
wlmfit = lm(as.formula(lm_formula), train_data, weights=rlmfit$w)
summary(wlmfit)

# check the weights assigned to each coin
weights = data.frame(coin=train_data[,"coin_name"], log_severity=train_data[,dependent_var], residual=rlmfit$residuals, weight = rlmfit$w)
weights_ordered = weights[order(rlmfit$w),]
weights_ordered[1:15,]


#####################################
# Model 1: Use only simple user stats
good_independent_vars =  c("user1_num_posts",
                          "user1_num_subjects",
                          "user1_days_since_first_post",
                          "user1_degree_incoming",
                          "user1_degree_outgoing")
dependent_var = "log_severity_to_average_after_max_volume_weighted"
x = data.matrix(train_data[,good_independent_vars])
y = train_data[,dependent_var]

# find the best elastic net model config and get nonzero coefficients on best alpha 
alphas=seq(1,1,by=0.05)
best_model = cross_validate_alphas(x, y, alphas)
best_alpha = best_model[2]
nonzero_coefs = extract_nonzero_coefs(best_model$coefs)

# Run simple ols
lm_formula = paste(dependent_var, "~", paste(nonzero_coefs, collapse=" + "))
model1_lmfit = lm(as.formula(lm_formula), train_data)
summary(model1_lmfit)

# investigate the assumption of ols
oldpar = par(mfrow = c(2,2))
plot(model1_lmfit, las=1)
par(oldpar)
train_data[which(cooks.distance(lmfit) > 30/nrow(train_data)), c("coin_name", dependent_var, nonzero_coefs)]

# run robust regression using iterated re-weighted least square
model1_rlmfit = rlm(as.formula(lm_formula), train_data, psi="psi.huber", method="M", model=T)
summary = summary(model1_rlmfit)
dd = data.frame(summary$coefficients)
dd$p.value = 2*pt(abs(dd$t.value), summary$df[2], lower.tail=FALSE)
dd
# above uses the psi.huber penalty function. but below we simply use mse.
# the results are similar nevertheless.
model1_wlmfit = lm(as.formula(lm_formula), train_data, weights=model1_rlmfit$w)
summary(model1_wlmfit)




#####################################
# Model 2: Use only nontrivialness
good_independent_vars =  c("nontrivial")
dependent_var = "log_severity_to_average_after_max_volume_weighted"
x = data.matrix(train_data[,good_independent_vars])
y = train_data[,dependent_var]
nonzero_coefs = good_independent_vars

# Run simple ols
lm_formula = paste(dependent_var, "~", paste(nonzero_coefs, collapse=" + "))
model2_lmfit = lm(as.formula(lm_formula), train_data)
summary(model2_lmfit)

# investigate the assumption of ols
oldpar = par(mfrow = c(2,2))
plot(model2_lmfit, las=1)
par(oldpar)
train_data[which(cooks.distance(lmfit) > 30/nrow(train_data)), c("coin_name", dependent_var, nonzero_coefs)]

# run robust regression using iterated re-weighted least square
model2_rlmfit = rlm(as.formula(lm_formula), train_data, psi="psi.huber", method="M", model=T)
summary = summary(model2_rlmfit)
dd = data.frame(summary$coefficients)
dd$p.value = 2*pt(abs(dd$t.value), summary$df[2], lower.tail=FALSE)
dd
# above uses the psi.huber penalty function. but below we simply use mse.
# the results are similar nevertheless.
model2_wlmfit = lm(as.formula(lm_formula), train_data, weights=model2_rlmfit$w)
summary(model2_wlmfit)



#####################################
# Model 3: Use only vars relative to satoshi
good_independent_vars =  c("user1_satoshi_pagerank_weighted",
                           "user1_satoshi_distance",
                           "user1_satoshi_distance_inf")
dependent_var = "log_severity_to_average_after_max_volume_weighted"
x = data.matrix(train_data[,good_independent_vars])
y = train_data[,dependent_var]

# find the best elastic net model config and get nonzero coefficients on best alpha 
alphas=seq(1,1,by=0.05)
best_model = cross_validate_alphas(x, y, alphas)
best_alpha = best_model[2]
nonzero_coefs = extract_nonzero_coefs(best_model$coefs)

# Run simple ols
lm_formula = paste(dependent_var, "~", paste(nonzero_coefs, collapse=" + "))
model3_lmfit = lm(as.formula(lm_formula), train_data)
summary(model3_lmfit)

# investigate the assumption of ols
oldpar = par(mfrow = c(2,2))
plot(model3_lmfit, las=1)
par(oldpar)
train_data[which(cooks.distance(lmfit) > 30/nrow(train_data)), c("coin_name", dependent_var, nonzero_coefs)]

# run robust regression using iterated re-weighted least square
model3_rlmfit = rlm(as.formula(lm_formula), train_data, psi="psi.huber", method="M", model=T)
summary = summary(model3_rlmfit)
dd = data.frame(summary$coefficients)
dd$p.value = 2*pt(abs(dd$t.value), summary$df[2], lower.tail=FALSE)
dd
# above uses the psi.huber penalty function. but below we simply use mse.
# the results are similar nevertheless.
model3_wlmfit = lm(as.formula(lm_formula), train_data, weights=model3_rlmfit$w)
summary(model3_wlmfit)



#####################################
# Model 4: Use network measures
good_independent_vars =  c("user1_clustering_coefficient",
                           "user1_closeness_centrality_weighted",
                           "user1_betweenness_centrality_weighted",
                           "user1_pagerank_weighted")
cor(train_data[,good_independent_vars])>0.9
dependent_var = "log_severity_to_average_after_max_volume_weighted"
x = data.matrix(train_data[,good_independent_vars])
y = train_data[,dependent_var]

# find the best elastic net model config and get nonzero coefficients on best alpha 
alphas=seq(1,1,by=0.05)
best_model = cross_validate_alphas(x, y, alphas)
best_alpha = best_model[2]
nonzero_coefs = extract_nonzero_coefs(best_model$coefs)

# Run simple ols
lm_formula = paste(dependent_var, "~", paste(nonzero_coefs, collapse=" + "))
model4_lmfit = lm(as.formula(lm_formula), train_data)
summary(model4_lmfit)

# investigate the assumption of ols
oldpar = par(mfrow = c(2,2))
plot(model4_lmfit, las=1)
par(oldpar)
train_data[which(cooks.distance(lmfit) > 30/nrow(train_data)), c("coin_name", dependent_var, nonzero_coefs)]

# run robust regression using iterated re-weighted least square
model4_rlmfit = rlm(as.formula(lm_formula), train_data, psi="psi.huber", method="M", model=T)
summary = summary(model4_rlmfit)
dd = data.frame(summary$coefficients)
dd$p.value = 2*pt(abs(dd$t.value), summary$df[2], lower.tail=FALSE)
dd
# above uses the psi.huber penalty function. but below we simply use mse.
# the results are similar nevertheless.
model4_wlmfit = lm(as.formula(lm_formula), train_data, weights=model4_rlmfit$w)
summary(model4_wlmfit)




#####################################
# Model 5: Use network measures, satoshi measures with nontrivial interaction term
good_independent_vars =  c("user1_clustering_coefficient",
                           "user1_clustering_coefficient_nontrivial",
                           "user1_closeness_centrality_weighted",
                           "user1_closeness_centrality_weighted_nontrivial",
                           "user1_betweenness_centrality_weighted",
                           "user1_betweenness_centrality_weighted_nontrivial",
                           "user1_satoshi_pagerank_weighted",
                           "user1_satoshi_pagerank_weighted_nontrivial",
                           "user1_pagerank_weighted",
                           "user1_pagerank_weighted_nontrivial")
cor(train_data[,good_independent_vars])>0.9
dependent_var = "log_severity_to_average_after_max_volume_weighted"
x = data.matrix(train_data[,good_independent_vars])
y = train_data[,dependent_var]

# find the best elastic net model config and get nonzero coefficients on best alpha 
alphas=seq(1,1,by=0.05)
best_model = cross_validate_alphas(x, y, alphas)
best_alpha = best_model[2]
nonzero_coefs = extract_nonzero_coefs(best_model$coefs)

# Run simple ols
lm_formula = paste(dependent_var, "~", paste(nonzero_coefs, collapse=" + "))
model5_lmfit = lm(as.formula(lm_formula), train_data)
summary(model5_lmfit)

# investigate the assumption of ols
oldpar = par(mfrow = c(2,2))
plot(model5_lmfit, las=1)
par(oldpar)
train_data[which(cooks.distance(lmfit) > 30/nrow(train_data)), c("coin_name", dependent_var, nonzero_coefs)]

# run robust regression using iterated re-weighted least square
model5_rlmfit = rlm(as.formula(lm_formula), train_data, psi="psi.huber", method="M", model=T)
summary = summary(model5_rlmfit)
dd = data.frame(summary$coefficients)
dd$p.value = 2*pt(abs(dd$t.value), summary$df[2], lower.tail=FALSE)
dd
# above uses the psi.huber penalty function. but below we simply use mse.
# the results are similar nevertheless.
model5_wlmfit = lm(as.formula(lm_formula), train_data, weights=model5_rlmfit$w)
summary(model5_wlmfit)


#####################################
# Model 6: Use network measures, satoshi measures and user simple stats without any nontrivial measure
good_independent_vars =  c("user1_num_posts",
                          "user1_num_subjects",
                          "user1_days_since_first_post",
                          "user1_degree_incoming",
                          "user1_degree_outgoing",
                          "user1_clustering_coefficient",
                          "user1_closeness_centrality_weighted",
                          "user1_betweenness_centrality_weighted",
                          "user1_satoshi_pagerank_weighted",
                          "user1_pagerank_weighted")
cor(train_data[,good_independent_vars])>0.9
dependent_var = "log_severity_to_average_after_max_volume_weighted"
x = data.matrix(train_data[,good_independent_vars])
y = train_data[,dependent_var]

# find the best elastic net model config and get nonzero coefficients on best alpha 
alphas=seq(1,1,by=0.05)
best_model = cross_validate_alphas(x, y, alphas)
best_alpha = best_model[2]
nonzero_coefs = extract_nonzero_coefs(best_model$coefs)

# Run simple ols
lm_formula = paste(dependent_var, "~", paste(nonzero_coefs, collapse=" + "))
model6_lmfit = lm(as.formula(lm_formula), train_data)
summary(model6_lmfit)

# investigate the assumption of ols
oldpar = par(mfrow = c(2,2))
plot(model6_lmfit, las=1)
par(oldpar)
train_data[which(cooks.distance(lmfit) > 30/nrow(train_data)), c("coin_name", dependent_var, nonzero_coefs)]

# run robust regression using iterated re-weighted least square
model6_rlmfit = rlm(as.formula(lm_formula), train_data, psi="psi.huber", method="M", model=T)
summary = summary(model6_rlmfit)
dd = data.frame(summary$coefficients)
dd$p.value = 2*pt(abs(dd$t.value), summary$df[2], lower.tail=FALSE)
dd
# above uses the psi.huber penalty function. but below we simply use mse.
# the results are similar nevertheless.
model6_wlmfit = lm(as.formula(lm_formula), train_data, weights=model6_rlmfit$w)
summary(model6_wlmfit)



#####################################
# Model 7: Use all metrics
good_independent_vars =  c("user1_num_posts",
                          "user1_num_subjects",
                          "user1_days_since_first_post",
                          "user1_degree_incoming",
                          "user1_degree_outgoing",
                          "user1_clustering_coefficient",
                          "user1_clustering_coefficient_nontrivial",
                          "user1_closeness_centrality_weighted",
                          "user1_closeness_centrality_weighted_nontrivial",
                          "user1_betweenness_centrality_weighted",
                          "user1_betweenness_centrality_weighted_nontrivial",
                          "user1_satoshi_pagerank_weighted",
                          "user1_satoshi_pagerank_weighted_nontrivial",
                          "user1_pagerank_weighted",
                          "user1_pagerank_weighted_nontrivial",
                          "nontrivial")
cor(train_data[,good_independent_vars])>0.9
dependent_var = "log_severity_to_average_after_max_volume_weighted"
x = data.matrix(train_data[,good_independent_vars])
y = train_data[,dependent_var]

# find the best elastic net model config and get nonzero coefficients on best alpha 
alphas=seq(1,1,by=0.05)
best_model = cross_validate_alphas(x, y, alphas)
best_alpha = best_model[2]
nonzero_coefs = extract_nonzero_coefs(best_model$coefs)

# Run simple ols
lm_formula = paste(dependent_var, "~", paste(nonzero_coefs, collapse=" + "))
model7_lmfit = lm(as.formula(lm_formula), train_data)
summary(model7_lmfit)

# investigate the assumption of ols
oldpar = par(mfrow = c(2,2))
plot(model7_lmfit, las=1)
par(oldpar)
train_data[which(cooks.distance(lmfit) > 30/nrow(train_data)), c("coin_name", dependent_var, nonzero_coefs)]

# run robust regression using iterated re-weighted least square
model7_rlmfit = rlm(as.formula(lm_formula), train_data, psi="psi.huber", method="M", model=T)
summary = summary(model7_rlmfit)
dd = data.frame(summary$coefficients)
dd$p.value = 2*pt(abs(dd$t.value), summary$df[2], lower.tail=FALSE)
dd
# above uses the psi.huber penalty function. but below we simply use mse.
# the results are similar nevertheless.
model7_wlmfit = lm(as.formula(lm_formula), train_data, weights=model7_rlmfit$w)
summary(model7_wlmfit)
