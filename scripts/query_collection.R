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


make_raw_content_url <- function(github_link){
  return(str_replace(github_link,
                      "github.com",
                      "raw.githubusercontent.com"))
}

#the (?=//)) asserts that there is a parentheses immediately following the URL -- a noncapturing group
get_linkOI <- function(pattern_to_search, relevant_data, url_pattern = "http[s]?://(?:[a-zA-Z]|[0-9]|[$-_@.&+]|[!*\\(\\),]|(?:%[0-9a-fA-F][0-9a-fA-F]))+(?=\\))"){
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
      base_url <- make_raw_content_url(df[i,]$html_url)

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

extract_slide_url <- function(tag_of_interest, char_vec, first_url_replacement = 'ottrpal::include_slide\\(\"', second_url_replacement = '\"\\)'){
  if(sum(grepl(tag_of_interest, char_vec)) >= 1){ #some data not on main yet
    relevant_lines <- grep(tag_of_interest, char_vec)
    data_of_interest <- str_replace(char_vec[relevant_lines+find_line_of_interest(char_vec, relevant_lines)], first_url_replacement, "")
    return(str_replace(data_of_interest, second_url_replacement, ""))
  } else {return(NA_character_)}
}

# -------- Function to get slide URL info ----------

get_slide_info <- function(df){
  
  df$concepts_slide <- ""
  df$lo_slide <- ""
  df$for_slide <- ""
  df$prereq_slide <- ""
  
  if (nrow(df) >=1){
    for (i in 1:nrow(df)) {
      # Make raw content url
      message(paste0("Slides for ", df$CourseName[i]))
      base_url <- make_raw_content_url(df[i,]$html_url)
      if (!(df$CourseName[i] %in% c("AI for Decision Makers", "Data Management and Sharing for NIH Proposals", "AI for Efficient Programming"))){
        
        # Determine if the index.Rmd file can be read
        try_url <- try(readLines(paste0(base_url, "/main/01-intro.Rmd")), silent = TRUE)
      
        # If try was ok, continue reading index file -- we'll get slide URLs from these
        if (class(try_url) != "try-error") {
          intro_data <- readLines(paste0(base_url, "/main/01-intro.Rmd"))
        } else { #if 01-intro.Rmd doesn't exist
          #try_urlQmd <- try(readlLnes(paste0(base_url, "/main/01-intro.qmd")), silent = TRUE) #try 01-intro.qmd (for Containers course)
          try_urlQmd <- try(readLines(make_branch_file_url(base_url, "01-intro.qmd", branch = "kweav-patch-1/")), silent = TRUE)
          
          if (class(try_urlQmd) != "try-error") {
            #intro_data <- readLines(paste0(base_url, "/main/01-intro.qmd"))
            intro_data <- readLines(make_branch_file_url(base_url, "01-intro.qmd", branch = "kweav-patch-1/"))
          } else {
            intro_data <- ""
            message("No available course information added to this last chunk after checking `01-intro.Rmd` and `01-intro.qmd`")
          }
        }
        
        if (sum(intro_data != "") > 1) { #if blank data, don't check it
        
          df$concepts_slide[i] <- extract_slide_url("topics_covered" , intro_data)
          df$lo_slide[i] <- extract_slide_url("learning_objectives", intro_data)
          df$for_slide[i] <- extract_slide_url("for_individuals_who", intro_data)
          df$prereq_slide[i] <- extract_slide_url("prereqs", intro_data)
           
        } else {
          df$concepts_slide[i] <- NA_character_
          df$lo_slide[i] <- NA_character_
          df$for_slide[i] <- NA_character_
          df$prereq_slide[i] <- NA_character_
          
          }#close if of making sure intro data has things to grep from
      } else { 
        message("Employing alternative checking methods")
        #check NIH specific files, Efficient specific files
        if (df$CourseName[i] == "AI for Efficient Programming"){
        
          try_urlIndex <- try(readLines(paste0(base_url, "/main/index.Rmd")), silent = TRUE) #try index.Rmd
          
          if (class(try_urlIndex) != "try-error") {
            intro_data <- readLines(paste0(base_url, "/main/index.Rmd"))
            df$concepts_slide[i] <- extract_slide_url("topics_covered" , intro_data)
            df$lo_slide[i] <- extract_slide_url("learning_objectives", intro_data)
            df$for_slide[i] <- extract_slide_url("for_individuals_who", intro_data)
            df$prereq_slide[i] <- extract_slide_url("prereqs", intro_data)
          } else {
            message(paste0("No slide data found for ", df$CourseName[i]))
            df$concepts_slide[i] <- NA_character_
            df$lo_slide[i] <- NA_character_
            df$for_slide[i] <- NA_character_
            df$prereq_slide[i] <- NA_character_
          }
        } else if (df$CourseName[i] == "AI for Decision Makers"){
          message("Handling this course in another function that will add in rows")
          df$concepts_slide[i] <- NA_character_
          df$lo_slide[i] <- NA_character_
          df$for_slide[i] <- NA_character_
          df$prereq_slide[i] <- NA_character_
        } else { #NIH for Data Sharing course
          try_urlIndex <- try(readLines(paste0(base_url, "/main/index.Rmd")), silent = TRUE) #try index.Rmd
          try_urlLO <- try(readLines(paste0(base_url, "/main/Learning_objectives.Rmd")), silent = TRUE) #try LearningObjectives.Rmd
          
          if((class(try_urlIndex) != "try-error") & (class(try_urlLO) != "try-error")){
            intro_data <- c(readLines(paste0(base_url, "/main/index.Rmd")), readLines(paste0(base_url, "/main/Learning_objectives.Rmd")))
            df$concepts_slide[i] <- extract_slide_url("topics_covered" , intro_data)
            df$lo_slide[i] <- extract_slide_url("learning_objectives", intro_data)
            df$for_slide[i] <- extract_slide_url("for_individuals_who", intro_data)
            df$prereq_slide[i] <- extract_slide_url("prereqs", intro_data)
          } else {
            message(paste0("No slide data found for ", df$CourseName[i]))
            df$concepts_slide[i] <- NA_character_
            df$lo_slide[i] <- NA_character_
            df$for_slide[i] <- NA_character_
            df$prereq_slide[i] <- NA_character_
          } 
        } #end the if else if and else chain for the specific coursers
      } #end else looking at specific courses 
    } #end for loop  
  } else { message("No relevant resources, so no data added")} #end if not at least one row
  return(df)
}

make_branch_file_url <- function(base_url, filename, branch = "/main/"){
  return(paste0(base_url, "/refs/heads/", branch, filename))
}

add_rows_with_slides_AIDM <- function(df){
  base_url <- make_raw_content_url(df[which(df$CourseName == "AI for Decision Makers"),]$html_url)
  to_bind_df <- data.frame(CourseName = c("AI for Decision Makers: Exploring AI Possibilities",
                                          "AI for Decision Makers: Avoiding AI Harm",
                                          "AI for Decision Makers: Determining AI Needs",
                                          "AI for Decision Makers: Developing AI Policy"),
                            lo_slide = c("", "", "", ""),
                            for_slide = c("", "", "", ""),
                            concepts_slide = c("", "", "", ""),
                            prereq_slide = NA_character_
                            )
    
  #Exploring AI Possibilities: https://raw.githubusercontent.com/fhdsl/AI_for_Decision_Makers/refs/heads/ah/add-slides/01a-AI_Possibilities-intro.Rmd
  branch_file1 <- make_branch_file_url(base_url, "01a-AI_Possibilities-intro.Rmd", branch = "ah/add-slides/")
  try_AI_url1 <- try(readLines(branch_file1), silent = TRUE)
    
  if(class(try_AI_url1) != "try-error") {
    intro_data <- readLines(branch_file1)
    to_bind_df[1,]$lo_slide <- extract_slide_url("learning_objectives", intro_data)
    to_bind_df[1,]$for_slide <- extract_slide_url("for_individuals_who", intro_data)
    to_bind_df[1,]$concepts_slide <- extract_slide_url("topics_covered", intro_data)
  } else{
    to_bind_df[1,]$lo_slide <- NA_character_
    to_bind_df[1,]$for_slide <- NA_character_
    to_bind_df[1,]$concepts_slide <- NA_character_
  }
    
  #Avoiding AI Harm: https://raw.githubusercontent.com/fhdsl/AI_for_Decision_Makers/refs/heads/cw_add_slides/02a-Avoiding_Harm-intro.Rmd
  branch_file2 <- make_branch_file_url(base_url, "02a-Avoiding_Harm-intro.Rmd", branch = "cw_add_slides/")
  try_AI_url2 <- try(readLines(branch_file2), silent = TRUE)
  
  if(class(try_AI_url2) != "try-error") {
    intro_data <- readLines(branch_file2)
    to_bind_df[2,]$lo_slide <- extract_slide_url("learning_objectives", intro_data)
    to_bind_df[2,]$for_slide <- extract_slide_url("for_individuals_who", intro_data)
    to_bind_df[2,]$concepts_slide <- extract_slide_url("topics_covered", intro_data)
  } else{
    to_bind_df[2,]$lo_slide <- NA_character_
    to_bind_df[2,]$for_slide <- NA_character_
    to_bind_df[2,]$concepts_slide <- NA_character_
  }
    
  #Determining AI Needs:
  ## To fill in
    
  #Developing AI Policy:
  ## To fill in
    
  df <- rbind(df, to_bind_df, fill = TRUE)
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
    filter(str_detect(launch_date, "launched-")) %>%
    mutate(launch_date = str_replace(launch_date, "launched-", "")) %>%
    mutate(launch_date = str_to_title(str_replace(launch_date, pattern = "(.{3})(.*)", replacement = "\\1 \\2"))) %>%

    get_book_info() %>%
    get_slide_info()
    

    full_repo_df <- rbind(full_repo_df, repo_df)
}

full_repo_df <- full_repo_df %>%
  #add_rows_with_slides_AIDM() %>%
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
