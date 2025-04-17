# ITN_search
A searchable table for ITN courses

## Important files

`scripts/query_collection.R`: gathers information (audience, funding, topics, etc.) about ITCR courses from their GitHub repos
`resources/collection.tsv`: where the collection from `query_collection.R` is stored.
`scripts/format-tables.R`: functions to wrangle course data and format course table
`testProgrammatic.Rmd`: drives building each course specific html page and the overall course table
`chunks/*Rmd` or `chunks/#.md`: chunks that we'll borrow using `ottrpal::borrow_chapter` (from the `base_ottr:dev` container specified in `config_automation.yml`) and fill in {SPECIFIC INFO} for course (following the example of our cheatsheets repo)
`*_template.Rmd`: the template for driving course specific pages. There's one for general courses `single_course_template.Rmd` and one for AI for Decision Makers `ai_course_template.Rmd`
`*_coursePage.html`: the output course specific html
