## ART (aligned rank transformed) Linear Mixed Effects Modeling Functions
## 02-24-2025

####### NOTES #######
# another alternative to a two-way non-parametric ANOVA: aligned rank transform (ART)
# how to include repeated measures term??:
#   - can use Error(subject_id) in the formula but this means the model will be stratified by subject_id and implies that the data MUST be balanced, 
#     especially if you have more than two strata (which I do)
#   - can use (1|subject_id) to run a linear mixed effects model while taking into account multiple samples from the same subject 
#   - partial eta squared tells us how large of an effect the independent variable(s) (RHS) have on the dependent variable (LHS)
# 
# contrasts analysis pointers:
#   - can specify one of the variables to see multiple comparisons (i.e. 'visit_num' or 'treatment_group' individually)
#   - can also get all comparisons for the combinations of the variables (i.e. 'visit_num:treatment_group')
#####################

## needed libraries
library(tidyverse)
library(magrittr)
library(broom)
library(rstatix)
library(ARTool)
library(car)

####### FUNCTIONS!! #######

## allows you to run an aligned rank transformed linear mixed effects model on your data
## note: all RHS variables need to be factors or else it will error out!!
## helpful to run an overall model on your data/not stratified, use the function below if you wish to 
## run stratified analysis 
art_lmer_notStrat <- function(input_table,
                              formula_left,
                              formula_right,
                              contrast_run_by){
  ## putting together align rank transformed model formula
  funky_formula <- paste(formula_left, formula_right, sep = "~")
  
  art_model <- art(as.formula(funky_formula), 
                   data = input_table)
  ## running the align rank transformed linear mixed effects model 
  art_lmer_res <- anova(art_model) %>% 
    as_tibble() %>% 
    mutate(signif = as.character(symnum(`Pr(>F)`,
                                        cutpoints = c(0, 0.0001, 0.001, 0.01, 0.05, 1),
                                        symbols = c("****", "***", "**", "*", "ns"),
                                        abbr.colnames = FALSE,
                                        na = "")))
  
  ## running post hoc tests on the model 'contrasts' and renaming the test group columns 
  art_lmer_contrast <- art.con(art_model, contrast_run_by) %>% 
    as_tibble() %>%
    separate_wider_delim(cols = 'contrast',
                         delim = ' - ',
                         names = c('group1',
                                   'group2')) %>% 
    mutate(signif = as.character(symnum(p.value,
                                        cutpoints = c(0, 0.0001, 0.001, 0.01, 0.05, 1),
                                        symbols = c("****", "***", "**", "*", "ns"),
                                        abbr.colnames = FALSE,
                                        na = "")))
  ## creating named list of outputs 
  my_list <- list(ARTResults = art_lmer_res,
                  ARTContrast = art_lmer_contrast)
  
  return(my_list)
}


## allows you to run an aligned rank transform linear mixed effects model stratified by a variable in the data
## uses function above, but just runs it individually for each variable in the column input under 'strat_variable'
## note: need to convert signif column created by symnum to a character class for bind_rows() to work!!
art_lmer_strat <- function(input_table,
                           strat_variable,
                           model_formula_left,
                           model_formula_right,
                           model_contrast_run_by){
  strat_art_res <- tibble()
  strat_art_contrast <- tibble()
  
  for (variable_group in unique(unlist(input_table[strat_variable]))) {
    strat_filt_table <- input_table %>% 
      filter(.data[[strat_variable]] == variable_group)
    
    art_lmer <- art_lmer_notStrat(input_table = strat_filt_table,
                                  formula_left = model_formula_left,
                                  formula_right = model_formula_right,
                                  contrast_run_by = model_contrast_run_by)
    
    art_res <- art_lmer$ARTResults %>% 
      mutate("{strat_variable}" := paste(variable_group)) %>% 
      select(all_of(strat_variable), everything())
    
    art_contrast <- art_lmer$ARTContrast %>% 
      mutate("{strat_variable}" := paste(variable_group)) %>% 
      select(all_of(strat_variable), everything())
    
    
    strat_art_res <- bind_rows(strat_art_res, art_res)
    
    strat_art_contrast <- bind_rows(strat_art_contrast, art_contrast)
  }
  
  my_list <- list(ARTResults = strat_art_res,
                  ARTContrast = strat_art_contrast)
  return(my_list)
}


## double nested for loop - for when you want to stratify by two variables 
## does the same as the function above but uses a nested for loop to stratify by two variables instead of one 
art_lmer_doubleStrat <- function(input_table,
                                 strat_variable1,
                                 strat_variable2,
                                 model_formula_left,
                                 model_formula_right,
                                 model_contrast_run_by){
  strat_art_res <- tibble()
  strat_art_contrast <- tibble()
  
  for (variable_group1 in unique(unlist(input_table[strat_variable1]))) {
    for (variable_group2 in unique(unlist(input_table[strat_variable2]))) {
      strat_variable_list <- c(strat_variable1, strat_variable2)
      
      strat_filt_table <- input_table %>% 
        filter(.data[[strat_variable1]] == variable_group1,
               .data[[strat_variable2]] == variable_group2)
      
      art_lmer <- art_lmer_notStrat(input_table = strat_filt_table,
                                    formula_left = model_formula_left,
                                    formula_right = model_formula_right,
                                    contrast_run_by = model_contrast_run_by)
      
      art_res <- art_lmer$ARTResults %>% 
        mutate("{strat_variable1}" := paste(variable_group1),
               "{strat_variable2}" := paste(variable_group2)) %>% 
        select(all_of(strat_variable_list), everything())
      
      art_contrast <- art_lmer$ARTContrast %>% 
        mutate("{strat_variable1}" := paste(variable_group1),
               "{strat_variable2}" := paste(variable_group2)) %>% 
        select(all_of(strat_variable_list), everything())
      
      
      strat_art_res <- bind_rows(strat_art_res, art_res)
      
      strat_art_contrast <- bind_rows(strat_art_contrast, art_contrast)
    }
  }
  
  my_list <- list(ARTResults = strat_art_res,
                  ARTContrast = strat_art_contrast)
  return(my_list)
}