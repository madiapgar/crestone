## Runs Basic R Tests for Normality of a Dataset
## 02-24-2025

## needed libraries
library(tidyverse)
library(magrittr)
library(broom)
library(rstatix)
library(car)

####### FUNCTION!! #######

test_normality <- function(input_table,
                           formula_left,
                           formula_right,
                           group_by_vars = NULL,
                           facet_by = NULL){
  ## checking for normality in the data, its not normal
  funky_formula <- paste(formula_left, formula_right, sep = "~")
  
  mod <- aov(as.formula(funky_formula),
             data = input_table)
  
  ## all points DO NOT fall along the line and in the confidence interval 
  notFacet_qqplot <- qqPlot(mod$residuals, id = FALSE)
  
  ## histogram distribution DOES NOT appear normal
  histogram <- hist(mod$residuals)
  
  ## p value for the shapiro test is very significant meaning that the data is NOT normal 
  ## NOTE: can a log transform the data to see if that creates normality 
  notGrouped_shapiro_res <- shapiro.test(mod$residuals)
  
  if (is.character(facet_by)) {
    var.list <- syms(names(input_table[formula_left]))
    
    grouped_shapiro_res <- input_table %>% 
      group_by(across(all_of(group_by_vars))) %>% 
      shapiro_test(vars = var.list)
    
    faceted_qqplot <- ggqqplot(input_table, formula_left, facet.by = facet_by)
    
    my_list <- list(QQPlot = notFacet_qqplot,
                    FacetedQQPlot = faceted_qqplot,
                    Histogram = histogram,
                    ShapiroTest = notGrouped_shapiro_res,
                    GroupedShapiroTest = grouped_shapiro_res)
  } else {
    my_list <- list(QQPlot = notFacet_qqplot,
                    Histogram = histogram,
                    ShapiroTest = notGrouped_shapiro_res)
  }
  
  return(my_list)
}