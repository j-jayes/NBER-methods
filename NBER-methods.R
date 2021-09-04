#' ---
#' title: "NBER-methods"
#' author: "JJayes"
#' date: "04/09/2021"
#' output: html_document
#' ---
#' 
## ----setup, include=FALSE-----------------------------------------------------
knitr::opts_chunk$set(echo = TRUE)

library(tidyverse)
library(rvest)
library(nberwp)
library(glue)

#' 
#' ## Planning
#' 
#' Try out Ben Davies package and see if I can access the text of the abstracts.
#' 
#' ## NBER papers package
#' 
## -----------------------------------------------------------------------------
papers <- nberwp::papers
papers

#' 
#' Nice! Now we have a list of papers - we can construct the URL based on the paper number
#' 
#' ### Try scraping?
#' 
## -----------------------------------------------------------------------------

# url <- "https://www.nber.org/papers/w8001"
# 
# text <- read_html(url) %>% 
#     html_node("p") %>% 
#     html_text() %>% 
#     str_squish()

#' 
#' Would actually be really cool to look at the different topics popularity over time, like "Kuznets curve" etc. Other interesting words might be, "case studies" or "paradox"
#' 
#' Make a function to scrape the abstract:
#' 
## -----------------------------------------------------------------------------
get_abstract <- function(paper){
    
    url <- glue("https://www.nber.org/papers/", paper)
    
    message(glue("Getting abstract from Working Paper {paper}"))
    
    text <- read_html(url) %>% 
    html_node("p") %>% 
    html_text() %>% 
    str_squish()
    
    text
}

#' 
#' Use function
#' 
## -----------------------------------------------------------------------------
df <- papers %>% 
    mutate(row_num = row_number()) %>% 
    filter(between(row_num, 0, 12)) %>%
    mutate(abstract = map(paper, possibly(get_abstract, "failed")))

#' 
#' 
## -----------------------------------------------------------------------------
df %>% write_rds("data/abstracts_df.rds")


#' 
#' Purl it to .R file.
#' 
## -----------------------------------------------------------------------------
# knitr::purl("code/NBER-methods.Rmd", documentation = 2)

#' 
