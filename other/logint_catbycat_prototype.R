# Vanessa's prototype function for logint_catbycat
logint_catbycat <- function(formula, variable1, variable2, data, sigfig = 4) {

  model <- glm(formula, data = data, family = binomial)
  outcome <- as.character(attr(model$terms, "variables")[-c(1)][1])
  coefficients <- coef(model)

  if (any(is.na(coefficients))) {
    na_variables <- names(coefficients)[is.na(coefficients)]
    warning(paste0(na_variables," has(have) NA estimates. \n Action Required: Consider re-specifying the model or re-examining interaction terms for meaningfulness. \n"))
  }

  levels1 <- levels(as.factor(model$model[[variable1]]))
  levels2 <- levels(as.factor(model$model[[variable2]]))

  ref_level1 <- levels1[1]
  ref_level2 <- levels2[1]

  coef_model <- coef(summary(model))
  beta_intercept <- coefficients[1]

  sentences <- c()

  for (i in levels1[-1]) {
    for (j in levels2[-1]) {
      main1 <- paste0(variable1, i)
      main2 <- paste0(variable2, j)
      interaction_term <- paste0(variable1, i, ":", variable2, j)

      beta_main1 <- ifelse(main1 %in% rownames(coef_model), coef_model[main1, "Estimate"], 0)
      beta_main2 <- ifelse(main1 %in% rownames(coef_model), coef_model[main2, "Estimate"], 0)
      beta_interaction <- ifelse(interaction_term %in% rownames(coef_model),
                                 coef_model[interaction_term, "Estimate"], 0)
      log_odds <- beta_intercept + beta_main1 + beta_main2 + beta_interaction
      odds_ratio <- exp(log_odds)
      vcov_m <- vcov(model)

      se_combined <- sqrt(
        ifelse(main1 %in% rownames(vcov_m), vcov_m[main1, main1], 0) +
          ifelse(main2 %in% rownames(vcov_m), vcov_m[main2, main2], 0) +
          ifelse(interaction_term %in% rownames(vcov_m), vcov_m[interaction_term, interaction_term], 0) +
          2 * (ifelse(main1 %in% rownames(vcov_m) & main2 %in% rownames(vcov_m), vcov_m[main1, main2], 0) +
                 ifelse(main1 %in% rownames(vcov_m) & interaction_term %in% rownames(vcov_m), vcov_m[main1, interaction_term], 0) +
                 ifelse(main2 %in% rownames(vcov_m) & interaction_term %in% rownames(vcov_m), vcov_m[main2, interaction_term], 0))
      )

      lower_CI <- exp(log_odds - 1.96 * se_combined)
      upper_CI <- exp(log_odds + 1.96 * se_combined)

      sentences <- c(
        sentences,
        paste0(
          "The odds ratio for the outcome '", outcome, "' when comparing the group ",
          variable1," level '", i, "' with the reference level, (",
          ref_level1, ") in the context of ", variable2, " level '",
          j,"' is ", signif(odds_ratio, sigfig), "."
        ),
        paste0(
          "The 95% CI for this odds ratio is: [", signif(lower_CI, sigfig),
          ", ", signif(upper_CI, sigfig),"].\n"
        )
      )
    }
  }
  return(cat(sentences, sep = "\n"))
}
