library(glmnet)
library(MASS)
library(sandwich)
library(lmtest)
library(stargazer)
setwd(dir = "~/research/nikete/Comunity-Structure-Extremely-Speculative-Asset-Dynamics/")
source("analysis/elastic_net.R")
setwd(dir = "data")
data = read.csv(file = "joined_price_network_trivialness_usd.csv", header = TRUE, sep = ",")
data$earliest_mention_date = as.character(data$earliest_mention_date, format = "%Y-%m-%d")
data$network_date = as.character(data$network_date, format = "%Y-%m-%d")
data$earliest_trade_date = as.character(data$earliest_trade_date, format = "%Y-%m-%d")
data$log_severity_to_average_after_max_volume_weighted = log(data$severity_to_average_after_max_volume_weighted)
data$magnitude = data$normalized_total_volume_before_max / data$normalized_total_volume
# add interaction terms
data$user1_clustering_coefficient_nontrivial = data$user1_clustering_coefficient * data$nontrivial
data$user1_closeness_centrality_weighted_nontrivial = data$user1_closeness_centrality_weighted * data$nontrivial
data$user1_betweenness_centrality_weighted_nontrivial = data$user1_betweenness_centrality_weighted * data$nontrivial
data$user1_satoshi_pagerank_weighted_nontrivial = data$user1_satoshi_pagerank_weighted * data$nontrivial
data$user1_pagerank_weighted_nontrivial = data$user1_pagerank_weighted * data$nontrivial
data$user1_degree_incoming_nontrivial = data$user1_degree_incoming * data$nontrivial
data$user1_degree_outgoing_nontrivial = data$user1_degree_outgoing * data$nontrivial
# fix infinite satoshi distance
data$user1_satoshi_distance_inf = data$user1_satoshi_distance>7
data$user1_satoshi_distance[data$user1_satoshi_distance_inf] = 7

data = data[data$symbol != "BTC",]

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
cor(train_data[,all_independent_vars])>0.9


#####################################
# Model 0: Initial exploration, using all vars. No specific model
# find the best elastic net model config and get nonzero coefficients on best alpha 
good_independent_vars =  c("user1_num_posts",
                           "user1_num_subjects",
                           "user1_days_since_first_post",
                           "user1_degree_incoming",
                           "user1_degree_incoming_nontrivial",
                           "user1_degree_outgoing",
                           "user1_degree_outgoing_nontrivial",
                           "user1_clustering_coefficient",
                           "user1_clustering_coefficient_nontrivial",
                           "user1_closeness_centrality_weighted",
                           "user1_closeness_centrality_weighted_nontrivial",
                           "user1_betweenness_centrality_weighted",
                           "user1_betweenness_centrality_weighted_nontrivial",
                           "user1_satoshi_pagerank_weighted",
                           "user1_satoshi_pagerank_weighted_nontrivial",
                           "user1_satoshi_distance",
                           "user1_satoshi_distance_inf",
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
train_data[which(cooks.distance(lmfit) > 30/nrow(train_data)), c("coin_name", "symbol", dependent_var, nonzero_coefs)]

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
model1_lm_sum = summary(model1_lmfit)
model1_lm_sum

# investigate the assumption of ols
oldpar = par(mfrow = c(2,2))
plot(model1_lmfit, las=1)
par(oldpar)
train_data[which(cooks.distance(model1_lmfit) > 30/nrow(train_data)), c("coin_name", dependent_var, nonzero_coefs)]

# Get summary with robust standard errors
model1_rlm_sum = model1_lm_sum
model1_rlm_sum$coefficients = unclass(coeftest(model1_lmfit, vcov=vcovHC(model1_lmfit, "HC0")))
model1_rlm_sum

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
model2_lm_sum = summary(model2_lmfit)
model2_lm_sum

# investigate the assumption of ols
oldpar = par(mfrow = c(2,2))
plot(model2_lmfit, las=1)
par(oldpar)
train_data[which(cooks.distance(model2_lmfit) > 30/nrow(train_data)), c("coin_name", dependent_var, nonzero_coefs)]

# Get summary with robust standard errors
model2_rlm_sum = model2_lm_sum
model2_rlm_sum$coefficients = unclass(coeftest(model2_lmfit, vcov=vcovHC(model2_lmfit, "HC0")))
model2_rlm_sum

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
model3_lm_sum = summary(model3_lmfit)
model3_lm_sum

# investigate the assumption of ols
oldpar = par(mfrow = c(2,2))
plot(model3_lmfit, las=1)
par(oldpar)
train_data[which(cooks.distance(model3_lmfit) > 30/nrow(train_data)), c("coin_name", dependent_var, nonzero_coefs)]

# Get summary with robust standard errors
model3_rlm_sum = model3_lm_sum
model3_rlm_sum$coefficients = unclass(coeftest(model3_lmfit, vcov=vcovHC(model3_lmfit, "HC0")))
model3_rlm_sum

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
model4_lm_sum = summary(model4_lmfit)
model4_lm_sum

# investigate the assumption of ols
oldpar = par(mfrow = c(2,2))
plot(model4_lmfit, las=1)
par(oldpar)
train_data[which(cooks.distance(model4_lmfit) > 30/nrow(train_data)), c("coin_name", dependent_var, nonzero_coefs)]

# Get summary with robust standard errors
model4_rlm_sum = model4_lm_sum
model4_rlm_sum$coefficients = unclass(coeftest(model4_lmfit, vcov=vcovHC(model4_lmfit, "HC0")))
model4_rlm_sum

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
good_independent_vars =  c("user1_clustering_coefficient_nontrivial",
                           "user1_closeness_centrality_weighted_nontrivial",
                           "user1_betweenness_centrality_weighted_nontrivial",
                           "user1_satoshi_pagerank_weighted_nontrivial",
                           "user1_pagerank_weighted_nontrivial",
                           "user1_degree_incoming_nontrivial",
                           "user1_degree_outgoing_nontrivial")
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
model5_lm_sum = summary(model5_lmfit)
model5_lm_sum

# investigate the assumption of ols
oldpar = par(mfrow = c(2,2))
plot(model5_lmfit, las=1)
par(oldpar)
train_data[which(cooks.distance(model5_lmfit) > 30/nrow(train_data)), c("coin_name", dependent_var, nonzero_coefs)]

# Get summary with robust standard errors
model5_rlm_sum = model5_lm_sum
model5_rlm_sum$coefficients = unclass(coeftest(model5_lmfit, vcov=vcovHC(model5_lmfit, "HC0")))
model5_rlm_sum

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
                           "user1_satoshi_distance",
                           "user1_satoshi_distance_inf",
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
model6_lm_sum = summary(model6_lmfit)
model6_lm_sum

# investigate the assumption of ols
oldpar = par(mfrow = c(2,2))
plot(model6_lmfit, las=1)
par(oldpar)
train_data[which(cooks.distance(model6_lmfit) > 30/nrow(train_data)), c("coin_name", dependent_var, nonzero_coefs)]

# Get summary with robust standard errors
model6_rlm_sum = model6_lm_sum
model6_rlm_sum$coefficients = unclass(coeftest(model6_lmfit, vcov=vcovHC(model6_lmfit, "HC0")))
model6_rlm_sum

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
                           "user1_degree_incoming_nontrivial",
                           "user1_degree_outgoing",
                           "user1_degree_outgoing_nontrivial",
                           "user1_clustering_coefficient",
                           "user1_clustering_coefficient_nontrivial",
                           "user1_closeness_centrality_weighted",
                           "user1_closeness_centrality_weighted_nontrivial",
                           "user1_betweenness_centrality_weighted",
                           "user1_betweenness_centrality_weighted_nontrivial",
                           "user1_satoshi_pagerank_weighted",
                           "user1_satoshi_pagerank_weighted_nontrivial",
                           "user1_satoshi_distance",
                           "user1_satoshi_distance_inf",
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
model7_lm_sum = summary(model7_lmfit)
model7_lm_sum

# investigate the assumption of ols
oldpar = par(mfrow = c(2,2))
plot(model7_lmfit, las=1)
par(oldpar)
train_data[which(cooks.distance(model7_lmfit) > 30/nrow(train_data)), c("coin_name", dependent_var, nonzero_coefs)]

# Get summary with robust standard errors
model7_rlm_sum = model7_lm_sum
model7_rlm_sum$coefficients = unclass(coeftest(model7_lmfit, vcov=vcovHC(model7_lmfit, "HC0")))
model7_rlm_sum

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


#####################################
# Model 8: Use all vars without feature selection
good_independent_vars =  c("user1_num_posts",
                           "user1_num_subjects",
                           "user1_days_since_first_post",
                           "user1_degree_incoming",
                           "user1_degree_incoming_nontrivial",
                           "user1_degree_outgoing",
                           "user1_degree_outgoing_nontrivial",
                           "user1_clustering_coefficient",
                           "user1_clustering_coefficient_nontrivial",
                           "user1_closeness_centrality_weighted",
                           "user1_closeness_centrality_weighted_nontrivial",
                           "user1_betweenness_centrality_weighted",
                           "user1_betweenness_centrality_weighted_nontrivial",
                           "user1_satoshi_pagerank_weighted",
                           "user1_satoshi_pagerank_weighted_nontrivial",
                           "user1_satoshi_distance",
                           "user1_satoshi_distance_inf",
                           "user1_pagerank_weighted",
                           "user1_pagerank_weighted_nontrivial",
                           "nontrivial")
cor(train_data[,good_independent_vars])>0.9
dependent_var = "log_severity_to_average_after_max_volume_weighted"
x = data.matrix(train_data[,good_independent_vars])
y = train_data[,dependent_var]

nonzero_coefs = good_independent_vars

# Run simple ols
lm_formula = paste(dependent_var, "~", paste(nonzero_coefs, collapse=" + "))
model8_lmfit = lm(as.formula(lm_formula), train_data)
model8_lm_sum = summary(model8_lmfit)
model8_lm_sum

# investigate the assumption of ols
oldpar = par(mfrow = c(2,2))
plot(model8_lmfit, las=1)
par(oldpar)
train_data[which(cooks.distance(model8_lmfit) > 30/nrow(train_data)), c("coin_name", dependent_var, nonzero_coefs)]

# Get summary with robust standard errors
model8_rlm_sum = model8_lm_sum
model8_rlm_sum$coefficients = unclass(coeftest(model8_lmfit, vcov=vcovHC(model8_lmfit, "HC0")))
model8_rlm_sum

# run robust regression using iterated re-weighted least square
model8_rlmfit = rlm(as.formula(lm_formula), train_data, psi="psi.huber", method="M", model=T)
summary = summary(model8_rlmfit)
dd = data.frame(summary$coefficients)
dd$p.value = 2*pt(abs(dd$t.value), summary$df[2], lower.tail=FALSE)
dd
# above uses the psi.huber penalty function. but below we simply use mse.
# the results are similar nevertheless.
model8_wlmfit = lm(as.formula(lm_formula), train_data, weights=model8_rlmfit$w)
summary(model8_wlmfit)

#####################################
# Print table
order =  c("user1_num_posts",
           "user1_num_subjects",
           "user1_days_since_first_post",
           "user1_degree_incoming",
           "user1_degree_incoming_nontrivial",
           "user1_degree_outgoing",
           "user1_degree_outgoing_nontrivial",
           "user1_clustering_coefficient",
           "user1_clustering_coefficient_nontrivial",
           "user1_closeness_centrality_weighted",
           "user1_closeness_centrality_weighted_nontrivial",
           "user1_betweenness_centrality_weighted",
           "user1_betweenness_centrality_weighted_nontrivial",
           "user1_satoshi_pagerank_weighted",
           "user1_satoshi_pagerank_weighted_nontrivial",
           "user1_satoshi_distance",
           "user1_satoshi_distance_inf",
           "user1_pagerank_weighted",
           "user1_pagerank_weighted_nontrivial",
           "nontrivial")
cov.labels =  c("num posts",
                "num subjects",
                "days since first post",
                "incoming degree",
                "incoming degree * nontrivial",
                "outgoing degree",
                "outgoing degree * nontrivial",
                "clustering coefficient",
                "clustering coefficient * nontrivial",
                "closeness centrality",
                "closeness centrality * nontrivial",
                "betweenness centrality",
                "betweenness centrality* nontrivial",
                "satoshi pagerank",
                "satoshi pagerank * nontrivial",
                "satoshi distance",
                "Infinite satoshi distance",
                "pagerank",
                "pagerank * nontrivial",
                "nontrivial")
depvar.label = c("Severity")
stargazer(model2_wlmfit,
          model3_wlmfit,
          model4_wlmfit,
          model6_wlmfit,
          model7_wlmfit,
          model8_wlmfit,
          dep.var.labels= "",
          column.labels=c("Model2", "Model3", "Model4", "Model6", "Model7", "Model8"),
          column.sep.width = "0pt",
          omit.table.layout = "#",
          df = FALSE,
          title="", align=TRUE,
          no.space=TRUE,
          dep.var.caption = depvar.label,
          order = order,
          covariate.labels = cov.labels,
          float.env = "table*",
          digits = 3,
          out="../tables/log_severity_with_trivialness.tex")