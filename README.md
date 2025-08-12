# ITN_course_search

```{r echo=FALSE}
library(ottrpal)
```

A auto-generating searchable table for ITN courses. The collection of information about the courses is programmatically queried from GitHub and processed..

## About

ITN_course_search uses the Github API to gather jhudsl and fhdsl organization repositories, specifically ITN courses, that we have worked on. It renders the table in a markdown-readable format. This repo has workflows that trigger collection building and table rendering once a week.

The table only includes repositories that meet the following **required** criteria:

1. Repository within the `jhudsl` or `fhdsl` organizations
1. Have a homepage listed
1. Have a description listed
1. Have "itn" and "course" as part of the repository tags (e.g., "itn-course", or "itn" and "course") (`str_detect(topics, "itn")` & `str_detect(topics, "course")`)
1. Aren't template per the tags (`!str_detect(topics, "template ")` -- using a space because we want repos with tags of "templates" if the repo is providing templates, e.g., [the Overleaf/LaTex Course](https://github.com/fhdsl/Overleaf_and_LaTeX_for_Scientific_Articles))
1. Has a repository tag for launch date specified by `launched-monYEAR` (e.g., `launched-aug2025` or `launched-dec2023`)

```{r, echo=FALSE, fig.alt="Shows the seven required criteria for including a course in the search table using the Overleaf course GitHub page as an example"}
ottrpal::include_slide("https://docs.google.com/presentation/d/15e_r5bth-eEp98ruq7c0nNpOU6f0D00003gT8vcrCtw/edit?slide=id.p#slide=id.p")
```

### Interested in adding a course to the table?

- [ ] Make sure the above required criteria (1-7) are met (jhudsl/fhdsl organization, public, homepage, description, itn-course tag, isn't a template, launch date tag).

#### Course title specification

Course title specification is **within the course material files**, usually the `index.Rmd` (or `_quarto.yml` for quarto book) file.

- [ ] Verify that the title is in the `index.Rmd` (or `_quarto.yml` for quarto book) file.
  - For Rmarkdown courses, need to follow the convention of being listed between `---` with `title:` at the front of the line
  - [Quarto books just replaces `title: ` to extract the title.](https://github.com/fhdsl/ITN_course_search/blob/e389cbd43d2923649e5422c17189d53a812bfb13/scripts/query_collection.R#L149)

```{r, echo=FALSE}
ottrpal::include_slide("https://docs.google.com/presentation/d/15e_r5bth-eEp98ruq7c0nNpOU6f0D00003gT8vcrCtw/edit?slide=id.g371dc0bfdb3_0_63#slide=id.g371dc0bfdb3_0_63")
```

```{r, echo=FALSE}
ottrpal::include_slide("https://docs.google.com/presentation/d/15e_r5bth-eEp98ruq7c0nNpOU6f0D00003gT8vcrCtw/edit?slide=id.g371dc0bfdb3_0_69#slide=id.g371dc0bfdb3_0_69")
```

#### Available course formats specification

Available course formats specification is **within the course material files**, usually the `index.Rmd` (or `index.qmd` for quarto book) file.

- [ ] Verify that available course formats are listed in `index.Rmd` (or `index.qmd` for quarto book) file, specifically for Coursera and Leanpub if applicable. (The GitHub source material and GitHub pages homepage information for the course table will be taken from the API call rather than this information, but it's good practice to have both included within this chunk too)

```{r, echo=FALSE, fig.alt = "Available Course Formats are listed in the index.Rmd file for the Overleaf course as an example for Rmarkdown courses"}
ottrpal::include_slide("https://docs.google.com/presentation/d/15e_r5bth-eEp98ruq7c0nNpOU6f0D00003gT8vcrCtw/edit?slide=id.g371dc0bfdb3_0_86#slide=id.g371dc0bfdb3_0_86")
```

```{r, echo = FALSE, fig.alt = "Available Course Formats are listed in the index.qmd file for the example quarto book from the Containers for Scientists example course"}
ottrpal::include_slide("https://docs.google.com/presentation/d/15e_r5bth-eEp98ruq7c0nNpOU6f0D00003gT8vcrCtw/edit?slide=id.g371dc0bfdb3_0_81#slide=id.g371dc0bfdb3_0_81")
```

<details><summary>What the code is looking for exactly</summary>

```{r echo=FALSE, fig.alt = "Available course formats do not need to be listed or enumerated in a bulleted or ordered list in order for the process to extract the information as seen with the NIH for Data Sharing course"}
ottrpal::include_slide("https://docs.google.com/presentation/d/15e_r5bth-eEp98ruq7c0nNpOU6f0D00003gT8vcrCtw/edit?slide=id.g371dc0bfdb3_0_91#slide=id.g371dc0bfdb3_0_91")
```

</details>

#### Necessary background information and learning objectives specification

Necessary background information and learning objectives are typically specified as images (Google Slides grabbed with `ottrpal::include_slide()` function) **within the course material files**, usually the `01-intro.Rmd` (or `01-intro.qmd` for quarto book) file. The code blocks where these are specified need to have specific identifiers.

- [ ] Verify that the `01-intro.Rmd` (or `01-intro.qmd` file for quarto courses, [ex: Containers for Scientists](https://github.com/fhdsl/Containers_for_Scientists/blob/main/01-intro.qmd)) file has identifiers for code blocks grabbing relevant google slide images. If it's not that file, you'll need to edit the `get_slide_info()` function within the `query_collection.R` file.
  - LOs: `learning_objectives`
  - Audience: `for_individuals_who`
  - Topics covered: `topics_covered`
  - Pre-reqs (if applicable): `prereqs`

```{r, echo=FALSE, fig.alt = "Example of learning objectives, audience, and topics covered code blocks from the Overleaf Course"}
ottrpal::include_slide("https://docs.google.com/presentation/d/15e_r5bth-eEp98ruq7c0nNpOU6f0D00003gT8vcrCtw/edit?slide=id.g371dc0bfdb3_0_42#slide=id.g371dc0bfdb3_0_42")
```

```{r, echo=FALSE, fig.alt = "Example of a prereqs code block from the GitHub Automation for Scientists Course"}
ottrpal::include_slide("https://docs.google.com/presentation/d/15e_r5bth-eEp98ruq7c0nNpOU6f0D00003gT8vcrCtw/edit?slide=id.g371dc0bfdb3_0_54#slide=id.g371dc0bfdb3_0_54")
```

<details><summary>Examples where these blocks aren't in the expected files include</summary>

- AI for Efficient Programming: They're in [index.Rmd](https://github.com/fhdsl/AI_for_Efficient_Programming/blob/main/index.Rmd) instead.
- NIH for Data Sharing:
  - LOs are in their own file (and the chunk is commented out, but still accessible to this table building) [Learning_objectives.Rmd](https://github.com/fhdsl/NIH_Data_Sharing/blob/main/Learning_objectives.Rmd) instead.
  - Audience and Topics covered are in [index.Rmd](https://github.com/fhdsl/NIH_Data_Sharing/blob/main/index.Rmd)
- AI for Decision Makers: They're in 4 different files on 4 difference branches -- one for each sub-course.

If your course's introductory material isn't located within the expected `01-intro.Rmd` or `01-intro.qmd` file locations, [add the course name here within query_collection.R](https://github.com/fhdsl/ITN_course_search/blob/e389cbd43d2923649e5422c17189d53a812bfb13/scripts/query_collection.R#L245) and then [add the checking with the alternative file(s) for your course within this `else`](https://github.com/fhdsl/ITN_course_search/blob/e389cbd43d2923649e5422c17189d53a812bfb13/scripts/query_collection.R#L278), following the example of AI for Efficient Programming and NIH for Data Sharing, unless your course has sub-courses within the main repo (that aren't in the table and will need new rows) or information on branches in which case, you'll want to [follow the example used for AI for Decision Makers](https://github.com/fhdsl/ITN_course_search/blob/e389cbd43d2923649e5422c17189d53a812bfb13/scripts/query_collection.R#L528) and use a [similar special function](https://github.com/fhdsl/ITN_course_search/blob/e389cbd43d2923649e5422c17189d53a812bfb13/scripts/query_collection.R#L383)

</details>

####

- Add repo tags for audience (at least one of the following):
  - `audience-software-developers`
  - `audience-researchers`
  - `audience-leaders`

```{r, echo=FALSE}
ottrpal::include_slide("https://docs.google.com/presentation/d/15e_r5bth-eEp98ruq7c0nNpOU6f0D00003gT8vcrCtw/edit?slide=id.g371dc0bfdb3_0_16#slide=id.g371dc0bfdb3_0_16")
```

- Add repo tags for category (only one of the following):
  - `category-best-practices`
  - `category-software-dev`
  - `category-fundamentals-tools-resources`
  - `category-hands-on-practice`

  ```{r, echo=FALSE}
ottrpal::include_slide("https://docs.google.com/presentation/d/15e_r5bth-eEp98ruq7c0nNpOU6f0D00003gT8vcrCtw/edit?slide=id.g371dc0bfdb3_0_35#slide=id.g371dc0bfdb3_0_35")
  ```

<details><summary>What the code is looking for exactly</summary>

</details>

## Important files

- `scripts/query_collection.R`: gathers information (audience, funding, topics, etc.) about ITN courses from their GitHub repos
- `resources/collection.tsv`: where the collection from `query_collection.R` is stored.
- `scripts/format-tables.R`: functions to wrangle course data and format course table
- `index.Rmd`: drives building each course specific html page and the overall course table
- `chunks/*Rmd` or `chunks/#.md`: chunks that we'll borrow using `ottrpal::borrow_chapter` (from the `base_ottr:dev` container specified in `config_automation.yml`) and fill in {SPECIFIC INFO} for course (following the example of our cheatsheets repo). Because of this approach, a chunk will only inherit specific information if we pass it as a tag replacement. In other words, not every piece of information in each row/about a specific course will be available to the chunks, only the information we specify as a tag replacement).
  - about: `aboutCourse.md` with "{COURSE_DESCRIPTION}", "{COURSE_CATEGORY}", and "{COURSE_LAUNCH}" to be provided/replaced
  - audience: `audienceCourse.Rmd` with "{FOR_SLIDE_LINK}" and "{COURSE_AUDIENCE}" to be provided/replaced
  - format: `formatFullCourse.Rmd` with "{BOOKDOWN_LINK}", "{GITHUB_LINK}", "{COURSERA_LINK}", and "{LEANPUB_LINK}" to be filled in
  - funding: `fundingFullCourse.Rmd` with "{hutch_funded}" to be filled in
  - LOs: `loCourse.Rmd` with "{LO_SLIDE_LINK}" to be provided/replaced
  - concepts discussed: `conceptsCourse.Rmd` with "{CONCEPTS_SLIDE_LINK}" tag to be provided/replaced
  - pre-requisites: `prereqsCourse.Rmd` with "{PREREQ_SLIDE_LINK}" and "{GITHUB_LINK}" tags to be provided/replaced. If there are pre-requisites for a course, and you want to add a direct link to them, look at or add to the conditionals in this particular `.Rmd`
- `*_template.Rmd`: the template for driving course specific pages.
  - `single_course_template.Rmd`: layout for building general course pages
  - `ai_course_template.Rmd`: layout for AI for Decision Makers course page
- `*_coursePage.html`: the output course specific html pages
