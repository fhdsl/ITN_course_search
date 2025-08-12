<!DOCTYPE html>

<html>

<head>

<meta charset="utf-8" />
<meta name="generator" content="pandoc" />
<meta http-equiv="X-UA-Compatible" content="IE=EDGE" />




<title>README.knit</title>

<script src="site_libs/header-attrs-2.29/header-attrs.js"></script>
<script src="site_libs/jquery-3.6.0/jquery-3.6.0.min.js"></script>
<meta name="viewport" content="width=device-width, initial-scale=1" />
<link href="site_libs/bootstrap-3.3.5/css/cosmo.min.css" rel="stylesheet" />
<script src="site_libs/bootstrap-3.3.5/js/bootstrap.min.js"></script>
<script src="site_libs/bootstrap-3.3.5/shim/html5shiv.min.js"></script>
<script src="site_libs/bootstrap-3.3.5/shim/respond.min.js"></script>
<style>h1 {font-size: 34px;}
       h1.title {font-size: 38px;}
       h2 {font-size: 30px;}
       h3 {font-size: 24px;}
       h4 {font-size: 18px;}
       h5 {font-size: 16px;}
       h6 {font-size: 12px;}
       code {color: inherit; background-color: rgba(0, 0, 0, 0.04);}
       pre:not([class]) { background-color: white }</style>
<script src="site_libs/navigation-1.1/tabsets.js"></script>
<link href="site_libs/highlightjs-9.12.0/textmate.css" rel="stylesheet" />
<script src="site_libs/highlightjs-9.12.0/highlight.js"></script>
<link rel="shortcut icon" href="resources/images/ITN_favicon.ico" />
 <!--- go to https://favicon.io/favicon-converter/ to upload an image to make a new favicon.io. You will need to replace the current favicon.io image with the one in the downloaded directory from the website. The current image is in the resources/images/ directory --->

<style type="text/css">
  code{white-space: pre-wrap;}
  span.smallcaps{font-variant: small-caps;}
  span.underline{text-decoration: underline;}
  div.column{display: inline-block; vertical-align: top; width: 50%;}
  div.hanging-indent{margin-left: 1.5em; text-indent: -1.5em;}
  ul.task-list{list-style: none;}
    </style>

<style type="text/css">code{white-space: pre;}</style>
<script type="text/javascript">
if (window.hljs) {
  hljs.configure({languages: []});
  hljs.initHighlightingOnLoad();
  if (document.readyState && document.readyState === "complete") {
    window.setTimeout(function() { hljs.initHighlighting(); }, 0);
  }
}
</script>






<link rel="stylesheet" href="styles.css" type="text/css" />



<style type = "text/css">
.main-container {
  max-width: 940px;
  margin-left: auto;
  margin-right: auto;
}
img {
  max-width:100%;
}
.tabbed-pane {
  padding-top: 12px;
}
.html-widget {
  margin-bottom: 20px;
}
button.code-folding-btn:focus {
  outline: none;
}
summary {
  display: list-item;
}
details > summary > p:only-child {
  display: inline;
}
pre code {
  padding: 0;
}
</style>



<!-- tabsets -->

<style type="text/css">
.tabset-dropdown > .nav-tabs {
  display: inline-table;
  max-height: 500px;
  min-height: 44px;
  overflow-y: auto;
  border: 1px solid #ddd;
  border-radius: 4px;
}

.tabset-dropdown > .nav-tabs > li.active:before, .tabset-dropdown > .nav-tabs.nav-tabs-open:before {
  content: "\e259";
  font-family: 'Glyphicons Halflings';
  display: inline-block;
  padding: 10px;
  border-right: 1px solid #ddd;
}

.tabset-dropdown > .nav-tabs.nav-tabs-open > li.active:before {
  content: "\e258";
  font-family: 'Glyphicons Halflings';
  border: none;
}

.tabset-dropdown > .nav-tabs > li.active {
  display: block;
}

.tabset-dropdown > .nav-tabs > li > a,
.tabset-dropdown > .nav-tabs > li > a:focus,
.tabset-dropdown > .nav-tabs > li > a:hover {
  border: none;
  display: inline-block;
  border-radius: 4px;
  background-color: transparent;
}

.tabset-dropdown > .nav-tabs.nav-tabs-open > li {
  display: block;
  float: none;
}

.tabset-dropdown > .nav-tabs > li {
  display: none;
}
</style>

<!-- code folding -->




</head>

<body>


<div class="container-fluid main-container">




<div id="header">




</div>


<!-- README.md is generated from README.Rmd. Please edit that file -->
<div id="itn_course_search" class="section level1">
<h1>ITN_course_search</h1>
<p>A auto-generating searchable table for ITN courses. The collection of
information about the courses is programmatically queried from GitHub
and processed..</p>
<div id="about" class="section level2">
<h2>About</h2>
<p>ITN_course_search uses the Github API to gather jhudsl and fhdsl
organization repositories, specifically ITN courses, that we have worked
on. It renders the table in a markdown-readable format. This repo has
workflows that trigger collection building and table rendering once a
week.</p>
<p>The table only includes repositories that meet the following
<strong>required</strong> criteria:</p>
<ol style="list-style-type: decimal">
<li>Repository within the <code>jhudsl</code> or <code>fhdsl</code>
organizations</li>
<li>Public repository</li>
<li>Have a homepage listed</li>
<li>Have a description listed</li>
<li>Have “itn” and “course” as part of the repository tags (e.g.,
“itn-course”, or “itn” and “course”)
(<code>str_detect(topics, "itn")</code> &amp;
<code>str_detect(topics, "course")</code>)</li>
<li>Aren’t template per the tags
(<code>!str_detect(topics, "template ")</code> – using a space because
we want repos with tags of “templates” if the repo is providing
templates, e.g., <a
href="https://github.com/fhdsl/Overleaf_and_LaTeX_for_Scientific_Articles">the
Overleaf/LaTex Course</a>)</li>
<li>Has a repository tag for launch date specified by
<code>launched-monYEAR</code> (e.g., <code>launched-aug2025</code> or
<code>launched-dec2023</code>)</li>
</ol>
<p><a href="https://github.com/fhdsl/Overleaf_and_LaTeX_for_Scientific_Articles" target="_blank"><img src="man/figures/README-/15e_r5bth-eEp98ruq7c0nNpOU6f0D00003gT8vcrCtw_p.png" alt="Shows the seven required criteria for including a course in the search table using the Overleaf course GitHub page as an example" width="100%" /></a></p>
</div>
<div id="interested-in-adding-a-course-to-the-table"
class="section level2">
<h2>Interested in adding a course to the table?</h2>
<p>At the moment, to add a course to the table, either wait for the repo
to fetch the collection data, or open a PR with a trivial change. A
later PR will add a way to manually trigger the workflow but this is not
available yet.</p>
<ul class="task-list">
<li><label><input type="checkbox" />Make sure the above required
criteria (1-7) are met (jhudsl/fhdsl organization, public, homepage,
description, itn-course tag, isn’t a template, launch date
tag).</label></li>
</ul>
<p>Make sure the rest of the information for the table (e.g., title,
access links/available course formats, etc.) is specified (where and
how) the query procedure expects (explained below).</p>
<div id="course-title-specification" class="section level3">
<h3>Course title specification</h3>
<p>Course title specification is <strong>within the course material
files</strong>, usually the <code>index.Rmd</code> (or
<code>_quarto.yml</code> for quarto book) file.</p>
<ul class="task-list">
<li><label><input type="checkbox" />Verify that the title is in the
<code>index.Rmd</code> (or <code>_quarto.yml</code> for quarto book)
file.</label>
<ul>
<li>For Rmarkdown courses, need to follow the convention of being listed
between <code>---</code> with <code>title:</code> at the front of the
line</li>
<li><a
href="https://github.com/fhdsl/ITN_course_search/blob/e389cbd43d2923649e5422c17189d53a812bfb13/scripts/query_collection.R#L149">Quarto
books just replaces <code>title:</code> to extract the title.</a></li>
</ul></li>
</ul>
<p><a href="https://github.com/fhdsl/Overleaf_and_LaTeX_for_Scientific_Articles/blob/main/index.Rmd" target="_blank"><img src="man/figures/README-/15e_r5bth-eEp98ruq7c0nNpOU6f0D00003gT8vcrCtw_g371dc0bfdb3_0_63.png" alt="Rmarkdown courses specify the title in the index.Rmd file in the area between 3 dashes. The code looks for title with a colon at the beginning of the line to distinguish it from the subtitlet" width="100%" /></a></p>
<p>Note that the query procedure looks for an <code>index.Rmd</code>
file first, and if it doesn’t find one in the repository, it then
assumes it could be a quarto course and looks for the
<code>_quarto.yml</code> file next automatically.</p>
<p><a href="https://github.com/fhdsl/Containers_for_Scientists/blob/main/_quarto.yml" target="_blank"><img src="man/figures/README-/15e_r5bth-eEp98ruq7c0nNpOU6f0D00003gT8vcrCtw_g371dc0bfdb3_0_69.png" alt="A quarto course will have the title specified in the _quarto.yml file and replaces the title colon and space with nothing to extract the title." width="100%" /></a></p>
</div>
<div id="available-course-formats-specification" class="section level3">
<h3>Available course formats specification</h3>
<p>Available course formats specification is <strong>within the course
material files</strong>, usually the <code>index.Rmd</code> (or
<code>index.qmd</code> for quarto book) file.</p>
<ul class="task-list">
<li><label><input type="checkbox" />Verify that available course formats
are listed in <code>index.Rmd</code> (or <code>index.qmd</code> for
quarto book) file, specifically for Coursera and Leanpub if applicable.
(The GitHub source material and GitHub pages homepage information for
the course table will be taken from the API call rather than this
information, but it’s good practice to have both included within this
chunk too)</label></li>
</ul>
<p><a href="https://github.com/fhdsl/Overleaf_and_LaTeX_for_Scientific_Articles/blob/main/index.Rmd" target="_blank"><img src="man/figures/README-/15e_r5bth-eEp98ruq7c0nNpOU6f0D00003gT8vcrCtw_g371dc0bfdb3_0_86.png" alt="Available Course Formats are listed in the index.Rmd file for the Overleaf course as an example for Rmarkdown courses" width="100%" /></a></p>
<p>Note that the query procedure looks for an <code>index.Rmd</code>
file first, and if it doesn’t find one in the repository, it then
assumes it could be a quarto course and looks for the
<code>index.qmd</code> file next automatically.</p>
<p><a href="https://github.com/fhdsl/Containers_for_Scientists/blob/main/index.qmd" target="_blank"><img src="man/figures/README-/15e_r5bth-eEp98ruq7c0nNpOU6f0D00003gT8vcrCtw_g371dc0bfdb3_0_81.png" alt="Available Course Formats are listed in the index.qmd file for the example quarto book from the Containers for Scientists example course" width="100%" /></a></p>
<details>
<summary>
What the code is looking for exactly
</summary>
<p>Because the <code>get_linkOI()</code> function is set up to find
line(s) with the course format “pattern” (e.g., “Coursera” or
“Leanpub”), then extract all URLs from those lines, and then subset to
the relevant URL if needed (again using the “pattern”), these available
course formats do not need to be in an ordered, bulleted, or enumerated
list. They could all be mentioned in a notice box or paragraph. As long
as the line with the link says “Coursera” or “Leanpub”, this process
will find and extract the relevant links.</p>
<p><a href="https://github.com/fhdsl/NIH_Data_Sharing/blob/main/index.Rmd" target="_blank"><img src="man/figures/README-/15e_r5bth-eEp98ruq7c0nNpOU6f0D00003gT8vcrCtw_g371dc0bfdb3_0_91.png" alt="Available course formats do not need to be listed or enumerated in a bulleted or ordered list in order for the process to extract the information as seen with the NIH for Data Sharing course" width="100%" /></a></p>
</details>
</div>
<div
id="necessary-background-information-and-learning-objectives-specification"
class="section level3">
<h3>Necessary background information and learning objectives
specification</h3>
<p>Necessary background information and learning objectives are
typically specified as images (Google Slides grabbed with
<code>ottrpal::include_slide()</code> function) <strong>within the
course material files</strong>, usually the <code>01-intro.Rmd</code>
(or <code>01-intro.qmd</code> for quarto book) file. The code blocks
where these are specified need to have specific identifiers.</p>
<ul class="task-list">
<li><label><input type="checkbox" />Verify that the
<code>01-intro.Rmd</code> (or <code>01-intro.qmd</code> file for quarto
courses, <a
href="https://github.com/fhdsl/Containers_for_Scientists/blob/main/01-intro.qmd">ex:
Containers for Scientists</a>) file has identifiers for code blocks
grabbing relevant google slide images.</label>
<ul>
<li>LOs: <code>learning_objectives</code></li>
<li>Audience: <code>for_individuals_who</code></li>
<li>Topics covered: <code>topics_covered</code></li>
<li>Pre-reqs (if applicable): <code>prereqs</code></li>
</ul></li>
</ul>
<details>
<summary>
What the code is looking for exactly
</summary>
<p>The code in the <code>get_slide_info()</code> function within the
<code>query_collection.R</code> file looks for these code block
identifiers exactly</p>
<p>Note that the query procedure first checks the course name to make
sure it’s not part of a special set of courses that don’t follow the
usual convention/location for this information. If the course isn’t in
that list, the procedure checks for the <code>01-intro.Rmd</code> file
first and if that file isn’t found it assumes it could be a quarto
course and looks for <code>01-intro.qmd</code> automatically next.</p>
</details>
<p><a href="https://github.com/fhdsl/Overleaf_and_LaTeX_for_Scientific_Articles/blob/main/01-intro.Rmd" target="_blank"><img src="man/figures/README-/15e_r5bth-eEp98ruq7c0nNpOU6f0D00003gT8vcrCtw_g371dc0bfdb3_0_42.png" alt="Example of learning objectives, audience, and topics covered code blocks from the Overleaf Course" width="100%" /></a></p>
<p><a href="https://github.com/fhdsl/Github_Automation_for_Scientists/blob/main/01-intro.Rmd" target="_blank"><img src="man/figures/README-/15e_r5bth-eEp98ruq7c0nNpOU6f0D00003gT8vcrCtw_g371dc0bfdb3_0_54.png" alt="Example of a prereqs code block from the GitHub Automation for Scientists Course" width="100%" /></a></p>
<p>If a different file contains the information, you’ll need to edit the
<code>get_slide_info()</code> function within the
<code>query_collection.R</code> file.</p>
<details>
<summary>
Examples where these blocks aren’t in the expected files include
</summary>
<ul>
<li>AI for Efficient Programming: They’re in <a
href="https://github.com/fhdsl/AI_for_Efficient_Programming/blob/main/index.Rmd">index.Rmd</a>
instead.</li>
<li>NIH for Data Sharing:
<ul>
<li>LOs are in their own file (and the chunk is commented out, but still
accessible to this table building) <a
href="https://github.com/fhdsl/NIH_Data_Sharing/blob/main/Learning_objectives.Rmd">Learning_objectives.Rmd</a>
instead.</li>
<li>Audience and Topics covered are in <a
href="https://github.com/fhdsl/NIH_Data_Sharing/blob/main/index.Rmd">index.Rmd</a></li>
</ul></li>
<li>AI for Decision Makers: They’re in 4 different files on 4 difference
branches – one for each sub-course.</li>
</ul>
<p>If your course’s introductory material isn’t located within the
expected <code>01-intro.Rmd</code> or <code>01-intro.qmd</code> file
locations, <a
href="https://github.com/fhdsl/ITN_course_search/blob/e389cbd43d2923649e5422c17189d53a812bfb13/scripts/query_collection.R#L245">add
the course name here within query_collection.R</a> and then <a
href="https://github.com/fhdsl/ITN_course_search/blob/e389cbd43d2923649e5422c17189d53a812bfb13/scripts/query_collection.R#L278">add
the checking with the alternative file(s) for your course within this
<code>else</code></a>, following the example of AI for Efficient
Programming and NIH for Data Sharing, unless your course has sub-courses
within the main repo (that aren’t in the table and will need new rows)
or information on branches in which case, you’ll want to <a
href="https://github.com/fhdsl/ITN_course_search/blob/e389cbd43d2923649e5422c17189d53a812bfb13/scripts/query_collection.R#L528">follow
the example used for AI for Decision Makers</a> and use a <a
href="https://github.com/fhdsl/ITN_course_search/blob/e389cbd43d2923649e5422c17189d53a812bfb13/scripts/query_collection.R#L383">similar
special function</a></p>
</details>
</div>
<div id="audience-specification" class="section level3">
<h3>Audience specification</h3>
<p>Audience specification is <strong>not within the course material
files</strong> but instead <strong>is within the repository
settings</strong></p>
<ul class="task-list">
<li><label><input type="checkbox" />Add repo tags for audience (at least
one of the following):</label>
<ul>
<li><code>audience-software-developers</code></li>
<li><code>audience-researchers</code></li>
<li><code>audience-leaders</code></li>
</ul></li>
</ul>
<p><a href="https://github.com/fhdsl/Overleaf_and_LaTeX_for_Scientific_Articles" target="_blank"><img src="man/figures/README-/15e_r5bth-eEp98ruq7c0nNpOU6f0D00003gT8vcrCtw_g371dc0bfdb3_0_16.png" alt="Audience tags are specified in the repository settings and can be any combination of the choices" width="100%" /></a></p>
<details>
<summary>
What the code is looking for exactly
</summary>
<p><a
href="https://github.com/fhdsl/ITN_course_search/blob/e389cbd43d2923649e5422c17189d53a812bfb13/scripts/query_collection.R#L490-L496">The
code in the <code>query_collection.R</code> file that traverses the
pages of the GitHub API request results looks for these tags
exactly.</a></p>
</details>
</div>
<div id="category-specification" class="section level3">
<h3>Category specification</h3>
<p>Category specification is <strong>not within the course material
files</strong> but instead <strong>is within the repository
settings</strong>.</p>
<ul class="task-list">
<li><label><input type="checkbox" />Add repo tags for category (only one
of the following):</label>
<ul>
<li><code>category-best-practices</code></li>
<li><code>category-software-dev</code></li>
<li><code>category-fundamentals-tools-resources</code></li>
<li><code>category-hands-on-practice</code></li>
</ul></li>
</ul>
<p><a href="https://github.com/fhdsl/Overleaf_and_LaTeX_for_Scientific_Articles" target="_blank"><img src="man/figures/README-/15e_r5bth-eEp98ruq7c0nNpOU6f0D00003gT8vcrCtw_g371dc0bfdb3_0_35.png" alt="Category tags are specified in the repository settings and should be only one of the choices. " width="100%" /></a></p>
<details>
<summary>
What the code is looking for exactly
</summary>
<p><a
href="https://github.com/fhdsl/ITN_course_search/blob/8facb2d4ec0a9beca5612a3277457881a2e9bcee/scripts/query_collection.R#L498-L506">The
code in the <code>query_collection.R</code> file that traverses the
pages of the GitHub API request results either looks for these tags
exactly (which is the case for <code>category-software-dev</code> and
<code>category-best-practices</code>), or it looks for the prefix
(<code>category-fundamentals-</code> rather than the full
<code>category-fundamentals-tools-resources</code> and
<code>category-hands-on-</code> rather than the full
<code>category-hands-on-practice</code>).</a></p>
</details>
</div>
<div id="funding" class="section level3">
<h3>Funding</h3>
<p>All courses with an <code>itn-course</code> or just <code>itn</code>
tag are assumed to be ITN funded. Add a <code>hutch-course</code> topic
tag to the repo if it was Hutch funded and should include Hutch branding
as well.</p>
</div>
<div id="cleaning-up-topic-tags-for-display-in-the-table"
class="section level3">
<h3>Cleaning up topic tags for display in the table</h3>
<p>The <code>query_collection.R</code> file does NOT clean the topic
tags data. Very minimal cleaning is done within the
<code>prep_table()</code> function within the
<code>format-tables.R</code> script. This minimal cleaning includes (1)
inserting a line break and a bullet point in place of every semicolon
(which separates the topic tags in the colleciton following querying)
and (2) replacing hyphens with a space. Special cases or substitions of
cleaning are handled within <code>index.Rmd</code> of this
ITN_course_search repo, specifically in the <code>wrangle_data</code>
code chunk.</p>
<p>Within that chunk …</p>
<ol style="list-style-type: decimal">
<li>Use title case on the concepts with the <code>str_to_title()</code>
function because the repo topic tags are all lower case.</li>
<li>Ai –&gt; AI (for the AI for Efficient Programming and AI for
Decision Makers courses)</li>
<li>Ci-Cd –&gt; Continuous Integration/Continuous Deployment (for the
Containers for Scientists Course)</li>
<li>Nih –&gt; NIH (for the Data Management and Sharing for NIH Proposals
course)</li>
<li>Hipaa –&gt; HIPAA (for the Ethical Data Handling for Cancer Research
course)</li>
<li>Llm –&gt; LLM (for the AI for Efficient Programming course)</li>
<li>Phi –&gt; (PHI) (for the Ethical Data Handling for Cancer Research
course)</li>
<li>Pii –&gt; (PII) (for the Ethical Data Handling for Cancer Research
course)</li>
<li>Arxiv –&gt; ArXiv (for the Overleaf and LaTeX course)</li>
<li>Latex –&gt; LaTeX (for the Overleaf and LaTeX course)</li>
<li>And –&gt; &amp; (space saving, used for the Choosing Genomics Tools
course )</li>
<li>Iv –&gt; IV (for the Containers for Scientists course which we
called Reproducibility Series IV)</li>
<li>Iii –&gt; III (for the GitHub Automation for Scientists course which
we called Reproducibility Series III)</li>
<li>Ii –&gt; II (for the Adv Reproducibility course which we called
Reproducibility Series II)</li>
</ol>
<p>Add any additional specific changes to the topic tags for cleaning
within that chunk going forward.</p>
</div>
<div id="adding-icons" class="section level3">
<h3>Adding icons</h3>
<p>Audience (column is <code>BroadAudience</code>), course categories
(column is <code>Category</code>), and funding (column is
<code>Funding</code>) information adds icons to the data while building
the tables. This is done within the <code>prep_table()</code> function
of the <code>format-tables.R</code> file. If you are editing or adding a
category to any of these, you will need to update those
<code>mutate</code> steps there.</p>
</div>
</div>
<div id="important-files" class="section level2">
<h2>Important files</h2>
<ul>
<li><code>scripts/query_collection.R</code>: gathers information
(audience, funding, topics, etc.) about ITN courses from their GitHub
repos</li>
<li><code>resources/collection.tsv</code>: where the collection from
<code>query_collection.R</code> is stored.</li>
<li><code>scripts/format-tables.R</code>: functions to wrangle course
data and format course table</li>
<li><code>index.Rmd</code>: drives building each course specific html
page and the overall course table</li>
<li><code>chunks/*Rmd</code> or <code>chunks/#.md</code>: chunks that
we’ll borrow using <code>ottrpal::borrow_chapter</code> (from the
<code>base_ottr:dev</code> container specified in
<code>config_automation.yml</code>) and fill in {SPECIFIC INFO} for
course (following the example of our cheatsheets repo). Because of this
approach, a chunk will only inherit specific information if we pass it
as a tag replacement. In other words, not every piece of information in
each row/about a specific course will be available to the chunks, only
the information we specify as a tag replacement).
<ul>
<li>about: <code>aboutCourse.md</code> with “{COURSE_DESCRIPTION}”,
“{COURSE_CATEGORY}”, and “{COURSE_LAUNCH}” to be provided/replaced</li>
<li>audience: <code>audienceCourse.Rmd</code> with “{FOR_SLIDE_LINK}”
and “{COURSE_AUDIENCE}” to be provided/replaced</li>
<li>format: <code>formatFullCourse.Rmd</code> with “{BOOKDOWN_LINK}”,
“{GITHUB_LINK}”, “{COURSERA_LINK}”, and “{LEANPUB_LINK}” to be filled
in</li>
<li>funding: <code>fundingFullCourse.Rmd</code> with “{hutch_funded}” to
be filled in</li>
<li>LOs: <code>loCourse.Rmd</code> with “{LO_SLIDE_LINK}” to be
provided/replaced</li>
<li>concepts discussed: <code>conceptsCourse.Rmd</code> with
“{CONCEPTS_SLIDE_LINK}” tag to be provided/replaced</li>
<li>pre-requisites: <code>prereqsCourse.Rmd</code> with
“{PREREQ_SLIDE_LINK}” and “{GITHUB_LINK}” tags to be provided/replaced.
If there are pre-requisites for a course, and you want to add a direct
link to them, look at or add to the conditionals in this particular
<code>.Rmd</code></li>
</ul></li>
<li><code>*_template.Rmd</code>: the template for driving course
specific pages.
<ul>
<li><code>single_course_template.Rmd</code>: layout for building general
course pages</li>
<li><code>ai_course_template.Rmd</code>: layout for AI for Decision
Makers course page</li>
</ul></li>
<li><code>*_coursePage.html</code>: the output course specific html
pages</li>
</ul>
</div>
</div>




</div>

<script>

// add bootstrap table styles to pandoc tables
function bootstrapStylePandocTables() {
  $('tr.odd').parent('tbody').parent('table').addClass('table table-condensed');
}
$(document).ready(function () {
  bootstrapStylePandocTables();
});


</script>

<!-- tabsets -->

<script>
$(document).ready(function () {
  window.buildTabsets("TOC");
});

$(document).ready(function () {
  $('.tabset-dropdown > .nav-tabs > li').click(function () {
    $(this).parent().toggleClass('nav-tabs-open');
  });
});
</script>

<!-- code folding -->


<!-- dynamically load mathjax for compatibility with self-contained -->
<script>
  (function () {
    var script = document.createElement("script");
    script.type = "text/javascript";
    script.src  = "https://mathjax.rstudio.com/latest/MathJax.js?config=TeX-AMS-MML_HTMLorMML";
    document.getElementsByTagName("head")[0].appendChild(script);
  })();
</script>

</body>
</html>
