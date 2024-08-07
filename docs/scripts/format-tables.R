#!/usr/bin/env Rscript

library(magrittr)
library(tidyverse)
library(DT)
library(here)

#' Format the tibble/table to bold names, link links, add icons, and rearrange/select columns
#' 
#' @description This function uses the CourseName, Funding, CurrentOrFuture, GithubLink, BookdownLink, CourseraLink, and LeanpubLink columns in order to make the first two columns
#' of the outputdf. For the first column of outputdf: CourseName input column value is bolded and icons are added below the name to denote the funding source(s) based on the values in the Funding input column.
#' For the second column of outputdf: If the course is a current course, GithubLink, BookdownLink, CourseraLink, and LeanpubLink are linked to corresponding icons. If either CourseraLink or LeanpubLink are NA values, then those icons/links are not added
#' If the course is a future course, the second column of outputdf instead has an under construction icon.
#' For the third and fourth columns of outputdf: we select the WebsiteDescription and BroadAudience columns. 
#' 
#' @param inputdf the input data frame or tibble
#' @param current a boolean; if TRUE (default), works with current courses; if FALSE, works with future courses by filtering on values in the CurrentOrFuture column
#' @param keep_category a boolean; if FALSE (default), it won't keep the Category or Concepts columns. If TRUE, the Category column is kept after Links but before WebsiteDescription and the Concepts column is kept at the end
#' @return outputdf the formatted table 
 

prep_table <- function(inputdf, current=TRUE, keep_category = FALSE){
  if (current){
    outputdf <- inputdf %>%
      filter(CurrentOrFuture == "Current") %>%
      mutate(Links =
               case_when(
                 (!is.na(LeanpubLink) & !is.na(CourseraLink)) ~ paste0('<a href="', BookdownLink ,'"style="color: #0000FF"',' target="_blank"','<div title="Bookdown Website Link"> </div>','<img src="resources/images/website_icon.png"  height="30"> </img><p class=\"image-name\">Website</p>', '</a>', '<br></br>',
                                                                       '<a href="', CourseraLink ,'"style="color: #0000FF"',' target="_blank"','<div title="Coursera Link"></div>','<img src="resources/images/courseralogo.png" height="30"> </img>', "</a>", '<br></br>',
                                                                       '<a href="', LeanpubLink ,'"style="color: #0000FF"',' target="_blank"','<div title="Leanpub Link"> </div>','<img src="resources/images/leanpublogo.png"  height="30"> </img><p class=\"image-name\">Leanpub</p>', '</a>', '<br></br>',
                                                                       '<a href="', GithubLink ,'"style="color: #0000FF"',' target="_blank"','<div title="Github Source Material Link"> </div>','<img src="resources/images/githublogo.png"  height="30"> </img><p class=\"image-name\">Source material</p>', '</a>'
                 ), #Fill in all 4 logos and links
                 (!is.na(LeanpubLink) & is.na(CourseraLink)) ~ paste0('<a href="', BookdownLink ,'"style="color: #0000FF"',' target="_blank"','<div title="Bookdown Website Link"> </div>','<img src="resources/images/website_icon.png"  height="30"> </img><p class=\"image-name\">Website</p>', '</a>', '<br></br>',
                                                                      '<a href="', LeanpubLink ,'"style="color: #0000FF"',' target="_blank"','<div title="Leanpub Link"> </div>','<img src="resources/images/leanpublogo.png"  height="30"> </img><p class=\"image-name\">Leanpub</p>', '</a>', '<br></br>',
                                                                      '<a href="', GithubLink ,'"style="color: #0000FF"',' target="_blank"','<div title="Github Source Material Link"> </div>','<img src="resources/images/githublogo.png"  height="30"> </img><p class=\"image-name\">Source material</p>', '</a>'
                 ), #Fill in Leanpub, Bookdown, and github logos and links
                 (is.na(LeanpubLink) & !is.na(CourseraLink)) ~ paste0('<a href="', BookdownLink ,'"style="color: #0000FF"',' target="_blank"','<div title="Bookdown Website Link"> </div>','<img src="resources/images/website_icon.png"  height="30"> </img><p class=\"image-name\">Website</p>', '</a>', '<br></br>',
                                                                      '<a href="', CourseraLink ,'"style="color: #0000FF"',' target="_blank"','<div title="Coursera Link"></div>','<img src="resources/images/courseralogo.png" height="30"> </img>', "</a>", '<br></br>',
                                                                      '<a href="', GithubLink ,'"style="color: #0000FF"',' target="_blank"','<div title="Github Source Material Link"> </div>','<img src="resources/images/githublogo.png"  height="30"> </img><p class=\"image-name\">Source material</p>', '</a>'
                 ) #Fill in Coursera, Bookdown, and github logos and links
               )
              )
  } else{
    outputdf <- inputdf %>%
      filter(CurrentOrFuture == "Future") %>% #select just future classes
      mutate(Links = '<img src="resources/images/underconstruction.png" height="40"></img>')
  }
  
  outputdf %<>% 
    mutate(CourseName = paste0("<b>", CourseName, "</b>")) %>% #mutate the name to be bolded
    mutate(CourseName = #add logos for funding and link to appropriate about pages
             case_when(
               Funding == "ITN" ~ paste0(CourseName, '<br></br><a href=\"https://itcr.cancer.gov/\"style=\"color:#0000FF\" target=\"_blank\"<div title =\"About ITCR\"></div><img src=\"resources/images/ITCRLogo.png\" height=\"40\"></img></a>'),
               Funding == "ITN; Hutch" ~ paste0(CourseName, '<br></br><a href=\"https://itcr.cancer.gov/\"style=\"color:#0000FF\" target=\"_blank\"<div title =\"About ITCR\"></div><img src=\"resources/images/ITCRLogo.png\" height=\"40\"></img></a><br></br>
                                                  <a href =\"https://www.fredhutch.org/en/about/about-the-hutch.html"style="color:#0000FF\" target=\"_blank\"<div title =\"About Fred Hutch\"></div><img src=\"resources/images/fhlogo.png\" height=\"40\"></img><p class=\"image-name\">Fred Hutch</p></a>')
             )
    ) %>% #Make the concepts bulletted instead of separated by semi-colons
    mutate(Concepts = paste0("- ", Concepts)) %>%
    mutate(Concepts = str_replace_all(Concepts, ";", "<br></br>- ")) %>%
    mutate(BroadAudience = str_replace_all(BroadAudience, ";", "<br></br>")) %>%
    #Replace the broad audiences with logos
    mutate(BroadAudience = str_replace(BroadAudience, "Software developers", "<img src=\"resources/images/SoftwareDeveloper.png\" alt=\"Software developers\" height=\"40\"></img><p class=\"image-name\">Software developers</p>")) %>%
    mutate(BroadAudience = str_replace(BroadAudience, "Researchers", "<img src=\"resources/images/NewToDataScience.png\" alt =\"Researchers\" height=\"40\"></img><p class=\"image-name\">Researchers</p>")) %>%
    mutate(BroadAudience = str_replace(BroadAudience, "Leaders", "<img src=\"resources/images/leader_avataaars.png\" alt=\"Leaders\" height=\"40\"></img><p class=\"image-name\">Leaders</p>")) %>%
    #Replace the categories with logos
    mutate(Category = str_replace(Category, "Software Development", "<img src=\"resources/images/keyboard-1405.png\" alt=\"Software development\" height=\"20\"></img><p class=\"image-name\">Software development</p>")) %>%
    mutate(Category = str_replace(Category, "Best Practices", "<img src=\"resources/images/golden-cup-7825.png\" alt=\"Best practices\" height=\"20\"></img><p class=\"image-name\">Best practices</p>")) %>%
    mutate(Category = str_replace(Category, "Tools & Resources", "<img src=\"resources/images/tool-box-9520.png\" alt=\"Fundamentals, tools, & resources\" height=\"20\"></img><p class=\"image-name\">Fundamentals, tools & resources</p>"))
  
  
  if ((keep_category) & (current)) { #select appropriate columns 
    outputdf %<>% select(c(CourseName, BroadAudience, Links, WebsiteDescription, Category, Concepts)) %>%
      `colnames<-`(c("Course Name", "Broad Audience", "Relevant Links", "Description", "Category", "Concepts Discussed"))
  } else if ((keep_category) & !(current)){
    outputdf %<>% select(c(CourseName, BroadAudience, Links, WebsiteDescription, Category)) %>%
      `colnames<-`(c("Course Name", "Broad Audience", "Relevant Links", "Description", "Category"))
  } else{
    outputdf %<>% select(c(CourseName, BroadAudience, Links, WebsiteDescription, Concepts)) %>%
      `colnames<-`(c("Course Name", "Broad Audience", "Relevant Links", "Description", "Concepts Discussed"))
  }
  return(outputdf)
}


#' A function to setup the DT datatable
#' 
#' @description
#' A short description...
#' 
#' 
#' @param inputdf input dataframe or tibble to be displayed with the DT library
#' @param some_caption a caption describing the table
#' 
#' @return output_table the DT datatable ready to display version of the inputdf
#' 

setup_table <- function(inputdf, some_caption, columnDefsListOfLists=NULL){
  if (is.null(columnDefsListOfLists)){
    columnDefsListOfLists <- list(list(className = "dt-center", targets = "_all"))
  }
  output_table <- inputdf %>%
    DT::datatable(
      style = 'default',
      width="100%",
      rownames = FALSE,
      escape = FALSE,
      caption = some_caption,
      filter = "top",
      options = list(scrollX = TRUE, autoWidth = TRUE, pageLength = 10,
                     scrollCollapse = TRUE, fillContainer = TRUE,
                     order = (list(0, 'asc')),
                     columnDefs = columnDefsListOfLists,
                     initComplete = JS(
                       "function(settings, json) {",
                       #"$('body').css({'font-family': 'Calibri'});",
                       "$(this.api().table().header()).css({'backgroundColor': '#3f546f'});",
                       "$(this.api().table().header()).css({'color': '#fff'});",
                       "}"))
    )
  return(output_table)
}
