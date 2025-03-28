#!/usr/bin/env Rscript

# Following the query_collection.R script developed by Ava Hoffman from the AnVIL_Collection:
# https://github.com/fhdsl/AnVIL_Collection/blob/main/scripts/query_collection.R

library(optparse)
library(httr)
library(jsonlite)
library(dplyr)
library(readr)
library(tidyr)
library(stringr)


# -------- Get the GitHub Token -----------

option_list <- list(
  optparse::make_option(
    c("--git_pat"),
    type = "character",
    default = NULL,
    help = "GitHub personal access token",
  )
)

# Read the GH_PAT argument
opt_parser <- optparse::OptionParser(option_list = option_list)
opt <- optparse::parse_args(opt_parser)
git_pat <- opt$git_pat

#the (?=//)) asserts that there is a parentheses immediately following the URL -- a noncapturing group
get_linkOI <- function(relevant_data, pattern_to_search, url_pattern = "http[s]?://(?:[a-zA-Z]|[0-9]|[$-_@.&+]|[!*\\(\\),]|(?:%[0-9a-fA-F][0-9a-fA-F]))+(?=\\))"){
  if(sum(grepl(pattern_to_search, relevant_data)) >= 1){
    relevant_lines <- grep(pattern_to_search, relevant_data)
    data_of_interest <- relevant_data[relevant_lines][grepl("https", relevant_data[relevant_lines])] #select only lines with a URL ... word may be mentioned without a URL
    extracted_string <- unlist(str_extract_all(data_of_interest, url_pattern))
    if (length(extracted_string) > 1){
      return(extracted_string[grep(tolower(pattern_to_search), extracted_string)]) #multiple URLs, selecting relevant one
    } else if (length(extracted_string) == 1){
      return(extracted_string)
    } else { return(NA_character_)} #empty link (e.g., commented out in the code)
  } else { return(NA_character_) } #pattern wasn't found in data
}

# ----------- Function to get book info -------------

get_book_info <- function(df){
  # Create dummy columns
  df$CourseName <- ""
  df$CourseraLink <- ""
  df$LeanpubLink <- ""
  
  if (nrow(df) >=1){
    for (i in 1:nrow(df)) {
      # Make raw content url
      base_url <-
        str_replace(df[i,]$html_url,
                    "github.com",
                    "raw.githubusercontent.com")

      # Determine if the index.Rmd file can be read
      try_url <- try(readLines(paste0(base_url, "/main/index.Rmd")), silent = TRUE)

      # If try was ok, continue reading index file -- we'll get course formats from these
      if (class(try_url) != "try-error") {
        index_data <- readLines(paste0(base_url, "/main/index.Rmd"))

        # Get book metadata
        metadata_lines <- grep("---", index_data)
        book_metadata <-
          index_data[(metadata_lines[1] + 1):(metadata_lines[2] - 1)]

        # Extract title
        CourseName <-
          book_metadata[grep("^title:",  book_metadata)]

        # Strip extra characters
        CourseName <- str_replace(CourseName, 'title: \"', '')
        CourseName <- str_replace(CourseName, '\"', '')

        # Append
        df$CourseName[i] <- CourseName
        
        print(CourseName)

        # Get Available Course Format Links
        
        df$CourseraLink[i] <- get_linkOI("Coursera", index_data)
        df$LeanpubLink[i] <- get_linkOI("Leanpub", index_data)
        
      } else { #if try-error for `index.Rmd`, assume quarto course
        # Determine if the _quarto.yml file can be read
        try_url_quartoTitle <- try(readLines(paste0(base_url, "/main/_quarto.yml")), silent = TRUE)

        if (class(try_url_quartoTitle) != "try-error") {
          yml_data <- readLines(paste0(base_url, "/main/_quarto.yml"))

          #get title from _quarto.yml and strip extra characters
          CourseName <-
            str_trim(str_replace(yml_data[grep("title:",  yml_data)], "title:", ''))

          # Append
          df$CourseName[i] <- CourseName

        } else {
          message("No course title added to this last chunk after checking `index.Rmd` and `_quarto.yml`")
        }
        # Determine if the _index.qmd file can be read
        try_url_indexqmd <- try(readLines(paste0(base_url, "/main/index.qmd")), silent = TRUE)

        if (class(try_url_indexqmd) != "try-error") {
          index_qmd_data <- readLines(paste0(base_url, "/main/index.qmd"))

          # Get Available Course Format Links
         df$CourseraLink[i] <- get_linkOI("Coursera", index_qmd_data)
         df$LeanpubLink[i] <- get_linkOI("Leanpub", index_qmd_data)

        } else {
          message("No available course information added to this last chunk after checking `index.Rmd` and `index.qmd`")
        }
      } #end trying to find quarto information
    } #end for loop
  } else { message("No relevant resources, so no data added")} #end if not at least one row
  return(df)
}


find_line_of_interest <- function(char_vec, line_with_tag, first_url_replacement = 'ottrpal::include_slide\\(\"', second_url_replacement = '\"\\)'){
  data_of_interest <- char_vec[(line_with_tag+1):(line_with_tag+2)]
  str_replace_doi <- str_replace(data_of_interest, first_url_replacement, "")
  str_replace_doi <- str_replace(str_replace_doi, second_url_replacement, "")
  
  return(grep("http", str_replace_doi)) #should return a 1 or 2, expecting 1 for nearly every course expect for Computing for Cancer Informatics
}
# -------- Function to get slide URL info ----------

get_slide_info <- function(df){
  
  first_url_replacement <- 'ottrpal::include_slide\\(\"'
  second_url_replacement <- '\"\\)'
  
  df$concepts_slide <- ""
  df$lo_slide <- ""
  df$for_slide <- ""
  df$prereq_slide <- ""
  
  if (nrow(df) >=1){
    for (i in 1:nrow(df)) {
      if (!(df$CourseName[i] %in% c("AI for Decision Makers", "Data Management and Sharing for NIH Proposals", "AI for Efficient Programming"))){
        # Make raw content url
        base_url <-
          str_replace(df[i,]$html_url,
                      "github.com",
                      "raw.githubusercontent.com")
      
        # Determine if the index.Rmd file can be read
        try_url <- try(readLines(paste0(base_url, "/main/01-intro.Rmd")), silent = TRUE)
      
        # If try was ok, continue reading index file -- we'll get slide URLs from these
        if (class(try_url) != "try-error") {
          intro_data <- readLines(paste0(base_url, "/main/01-intro.Rmd"))
        } else { #if 01-intro.Rmd doesn't exist
          try_urlQmd <- try(readlines(paste0(base_url, "/main/01-intro.qmd")), silent = TRUE) #try 01-intro.qmd (for Containers course)
            
          if (class(try_urlQmd) != "try-error") {
            intro_data <- readlines(paste0(base_url, "/main/01-intro.qmd"))
          } else {
            intro_data <- ""
            message("No available course information added to this last chunk after checking `01-intro.Rmd`, `index.Rmd` and `01-intro.qmd`")
          }
        }
        
        if (sum(intro_data != "") > 1) { #if blank data, don't check it
        
          if(sum(grepl("topics_covered", intro_data)) >= 1){ #some data not on main yet
            concepts_lines <- grep("topics_covered", intro_data)
            concepts_data <- str_replace(intro_data[concepts_lines+find_line_of_interest(intro_data, concepts_lines)], first_url_replacement, "")
            df$concepts_slide[i] <- str_replace(concepts_data, second_url_replacement, "")
          } else {df$concepts_slide[i] <- NA_character_}
        
          if(sum(grepl("learning_objectives", intro_data)) >= 1){ #some data not on main yet
            lo_lines <- grep("learning_objectives", intro_data)
            lo_data <- str_replace(intro_data[lo_lines+find_line_of_interest(intro_data, lo_lines)], first_url_replacement, "")
            df$lo_slide[i] <- str_replace(lo_data, second_url_replacement, "")
          } else(df$lo_slide[i] <- NA_character_)
        
          if(sum(grepl("for_individuals_who", intro_data)) >=1){ #some data not on main yet
            for_lines <- grep("for_individuals_who", intro_data)
            for_data <- str_replace(intro_data[for_lines+find_line_of_interest(intro_data, for_lines)], first_url_replacement, "")
            df$for_slide[i] <- str_replace(for_data, second_url_replacement, "")
          } else(df$for_slide[i] <- NA_character_)
           
          if(sum(grepl("prereqs", intro_data)) >= 1){ #some data not on main yet
            prereq_lines <- grep("prereqs", intro_data)
            prereq_data <- str_replace(intro_data[prereq_lines+find_line_of_interest(intro_data, prereq_lines)], first_url_replacement, "")
            df$prereq_slide[i] <- str_replace(prereq_data, second_url_replacement, "")
          } else{df$prereq_slide[i] <- NA_character_}
        } #close if of making sure intro data has things to grep from
      } else { 
        message("This will be filled in later with branch and file specific grabbing of slides.") #check AI for Decision Makers branches, NIH specific files, Efficient specific files
        #try_urlIndex <- try(readLines(paste0(base_url, "/main/index.Rmd")), silent = TRUE) #try index.Rmd
    
        #if (class(try_urlIndex) != "try-error") {
          #intro_data <- readLines(paste0(base_url, "/main/index.Rmd"))
      
          #try_urlLO <- try(readlines(paste0(base_url, "/main/LearningObjectives.Rmd")), silent = TRUE) #try LearningObjectives.Rmd
      
          #add in an if for LO link
      } #end else looking at specific courses 
    } #end for loop  
  } else { message("No relevant resources, so no data added")} #end if not at least one row
  return(df)
}


# --------- Set url and token ---------

message(paste("Querying Github API..."))

# Request search results specific to jhudsl + fhdsl organizations
# Also allows us to pull in repos forked into these organizations
url <-
  "https://api.github.com/search/repositories?q=user:jhudsl+user:fhdsl+fork:true&per_page=50"

# Provide the appropriate GH token & Make the request
req <-
  GET(url = url, config = add_headers(Authorization = paste("token", git_pat)))

if (!(httr::http_error(req))) {
  message(paste("API request successful!"))
} else {
  stop("API request failed!")
}

# --------- Traverse pages ---------

# Pull out the last page number of the request
last <-
  str_extract(req$headers$link, pattern = '.(?=>; rel=\"last\")')

full_repo_df <- tibble()
for (page in 1:last) {
  url <-
    paste0(
      "https://api.github.com/search/repositories?q=user:jhudsl+user:fhdsl+fork:true&per_page=50&page=",
      page
    )
  message(paste("Gathering results from:", url))
  req <-
    GET(url = url, config = add_headers(Authorization = paste("token", git_pat)))
  repo_dat <-
    jsonlite::fromJSON(httr::content(req, as = "text"), flatten = TRUE)
  message(paste("... Gathered", nrow(repo_dat$items), "repositories."))

  repo_df <-
    tibble(repo_dat$items) %>%
    select(full_name, homepage, html_url, description, private) %>%
    separate(full_name, into = c("org", "name"), sep = "/") %>%

    # Collapse topics so they can be printed
    bind_cols(tibble(topics = unlist(
      lapply(repo_dat$items$topics, paste, collapse = ", ")
    ))) %>%

    # Drop private repos and remove org column
    filter(!(private)) %>%
    select(!c(private, org)) %>%

    # Rearrange columns
    relocate(description, .before = topics) %>%

    # Keep only those with homepages and descriptions
    filter(!(is.na(homepage)), homepage != "",!(is.na(description))) %>%

    # Keep only ITN course related content
    # Exclude templates
    mutate(is_itn = str_detect(topics, "itn")) %>%
    mutate(is_course = str_detect(topics, "course")) %>%
    mutate(is_template = str_detect(topics, "template ")) %>% #add a space to the str_detect because a few topic tags are "templates"
    filter(is_itn) %>%
    filter(is_course) %>%
    filter(!is_template) %>%
    mutate(aud_sd = case_when(str_detect(topics, "audience-software-developers") ~ "Software Developers",
                              !str_detect(topics, "audience-software-developers") ~ NA_character_),
           aud_l = case_when(str_detect(topics, "audience-leaders") ~ "Leaders",
                             !str_detect(topics, "audience-leaders") ~ NA_character_),
           aud_r = case_when(str_detect(topics, "audience-researchers") ~ "Researchers",
                             !str_detect(topics, "audience-researchers") ~ NA_character_)
           ) %>%
    tidyr::unite(col = "BroadAudience", starts_with("aud_"), sep = ";", na.rm = TRUE) %>%
    mutate(cat_ftr = case_when(str_detect(topics, "category-fundamentals-") ~ "Tools & Resources",
                               !str_detect(topics, "category-fundamentals-") ~ NA_character_),
           cat_sd = case_when(str_detect(topics, "category-software-dev") ~ "Software Development",
                              !str_detect(topics, "category-software-dev") ~ NA_character_),
           cat_bp = case_when(str_detect(topics, "category-best-practices") ~ "Best Practices",
                              !str_detect(topics, "category-best-practices") ~ NA_character_)
           ) %>%
    tidyr::unite(col = "Category", starts_with("cat_"), sep=";", na.rm = TRUE) %>%
    mutate(hutch_funding = str_detect(topics, "hutch-course")) %>%
    mutate(launch_date = topics) %>%
    tidyr::separate_longer_delim(launch_date, delim = ", ") %>%
    filter(!str_detect(launch_date, "launchdate-")) %>%
    mutate(launch_date = str_replace(launch_date, "launchdate-", "")) %>%
    mutate(launch_date = str_to_title(str_replace(launch_date, pattern = "(.{3})(.*)", replacement = "\\1 \\2"))) %>%

    get_book_info() %>%
    get_slide_info()

    full_repo_df <- rbind(full_repo_df, repo_df)
}

full_repo_df <- full_repo_df %>%
  tidyr::separate_wider_delim(topics, delim=", ", names_sep = "_", too_few = "align_start") %>%
  mutate(across(starts_with("topics_"), ~replace(., str_detect(., "audience-|category-|course|launched-"), NA))) %>%
  tidyr::unite("Concepts", starts_with("topics_"), sep=';', na.rm = TRUE) %>%
  rename(GithubLink = html_url) %>%
  rename(BookdownLink = homepage) #already available from the API calls, so don't need to extract it

# ---------- Save the collection ---------

# Create an artifact file containing the repos, else write an empty file
if (!dir.exists("resources")){
  dir.create("resources")
}
if (nrow(full_repo_df) > 0){
  readr::write_tsv(full_repo_df, file.path('resources', 'collection.tsv'))
} else {
  readr::write_tsv(tibble(), file.path('resources', 'collection.tsv'))
}
