# ITN_course_search
A auto-generating searchable table for ITN courses. The collection of information about the courses is programmatically queried from GitHub and processed..

## About

ITN_course_search uses the Github API to gather jhudsl and fhdsl organization repositories, specifically ITN courses, that we have worked on. It renders the table in a markdown-readable format. This repo has workflows that trigger collection building and table rendering once a week.

The table only includes repositories that meet the following criteria:
- Are public
- Have a homepage listed
- Have a description listed
- Have "itn" and "course" as part of the tags (e.g., "itn-course", or "itn" and "course") (`str_detect(topics, "itn")` & `str_detect(topics, "course")`)
- Aren't template per the tags (`!str_detect(topics, "template ")` -- using a space because we want repos with tags of "templates" if the repo is providing templates)

### Interested in adding a course to the table?

- Make sure the above required criteria are met (public, homepage, description, itn-course tag, isn't a template)
- Verify that the title is in the index.Rmd (or _quarto.yml for quarto book) file, following the convention of being listed between `---` with `title:` at the front of the line with the title
- Verify that available course formats are listed in index.Rmd (or index.qmd for quarto book) file, specifically for Coursera and Leanpub if applicable
- Verify that the `01-intro.Rmd` file has identifiers for code blocks grabbing relevant google slide images. If it's not that file, you'll need to edit the `get_slide_info()` function within the `query_collection.R` file.
  - LOs: `learning_objectives`
  - Audience: `for_individuals_who`
  - Topics covered: `topics_covered`
  - Pre-reqs (if applicable): `prereqs`
- Add repo tags for audience (at least one of the following):
  - `audience-software-developers`
  - `audience-researchers`
  - `audience-leaders`
- Add repo tags for category (only one of the following):
  - `category-best-practices`
  - `category-software-dev`
  - `category-fundamentals-tools-resources`

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
  - pre-requisites: `prereqsCourse.Rmd` with "{PREREQ_SLIDE_LINK}" and "{GITHUB_LINK}" tags to be provided/replaced
- `*_template.Rmd`: the template for driving course specific pages.
  - `single_course_template.Rmd`: layout for building general course pages
  - `ai_course_template.Rmd`: layout for AI for Decision Makers course page
- `*_coursePage.html`: the output course specific html pages
