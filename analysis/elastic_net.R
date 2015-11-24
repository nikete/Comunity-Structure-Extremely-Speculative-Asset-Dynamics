library(glmnet)

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
      coefs=coef(cur_cvfit, s="lambda.min"),
      cv_low=cur_cvfit$cvlo[min_index], 
      cv=cur_cvfit$cvm[min_index], 
      cv_up=cur_cvfit$cvup[min_index])
  })
  
  #step 3: find the overall optimum
  optimum_index = which.min(optimum_per_alpha["cv",])
  return(c(lambda=optimum_per_alpha[["lambda", optimum_index]],
           alpha=optimum_per_alpha[["alpha",optimum_index]],
           non_zero_coefs=optimum_per_alpha[["non_zero_coefs",optimum_index]],
           coefs=optimum_per_alpha[["coefs", optimum_index]],
           cv_low=optimum_per_alpha[["cv_low",optimum_index]],
           cv=optimum_per_alpha[["cv",optimum_index]],
           cv_up=optimum_per_alpha[["cv_up",optimum_index]]))
}

extract_nonzero_coefs = function(coefs){
  nonzero_coefs = rownames(coefs)[which(coefs != 0)]
  return(nonzero_coefs[nonzero_coefs != "(Intercept)"])
}