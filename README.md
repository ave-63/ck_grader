# ck_grader

This is a small R program that makes grading CourseKata textbook homework easy. Suppose you want to grade pages 10.6 to 10.10 for your Monday Wednesday class, which is due May 6. Here's an overview of what you do:

1. Soon after it's due, go to the "My Progress + Jupyter" page. Click "Refresh Data," and then "Download Student Progres." Put the file in the same directory as `ck_grader.r`, and name it `MW_10.6to10.10_5-6.csv`. The name of this *assignment file* tells the program which of your classes the assignment is for (`MW`), the pages to be graded (`10.6to10.10`), and the date it was downloaded (`5-6`).

2. (Optional but recommended) Go to "Modules", and within some or all of the pages 10.6 to 10.10, and click "Download data." Put the files in the same folder as step 1, and call them `MW_10.6_5-6.csv`, `MW_10.7_5-6.csv`, ..., `MW_10.10_5-6.csv`. These *page detail* files have much more detail than the corresponding column in the *assignment file* from step 1.

3. Open a terminal/command prompt in the folder. Type the command `R -s -f ck_grader.r` and press Enter. It will print out some information and maybe warnings, and *voilà!* There is a now a file called `ck_grades_MW.csv` which contains a column with the assignment's grades, labelled `10.6to10.10_5-6`.

4. Repeat the process for every assignment on every due date, keeping everything in the same folder. It will have a ton of csv files, but they don't take up much storage space. To grade late HW, just repeat the process but with a different date label. Every page range/date assignment file will have its own column in the `MW_ck_grades.csv` file.

## Motivation

It is valuable to have HW scores that accurately reflect students' efforts. This is especially true while teaching remotely, as most teachers are making exams count for less and HW count for more of the course grade.

The overview csv files from "My Progress -> Download Student Progress" do not include enough information, in my opinion:

- They only count problems that were completed, with no weight given to correctness. Some students don't read anything, and spend thirty seconds clicking "submit" on all the problems, and it shows up as full credit here.
- Groups of problems that appear in one blue box in the page, with one "Submit" button, only count as one point here. This includes the entirety of each of the two review pages at the end of each chapter. If there are twenty questions in one of these pages, you only see 1 or 0 here.

So, you can go to Module pages to download the individual *page detail* csv files, and copy the columns labelled "completed" and "correct," insert them into the overview file, and write an excel formula to calculate the grades for the assignment. This has some downsides:

- It is extremely tedious. Let's say you have two classes, and in a certain week you have two assignments due, each including four pages. That's sixteen page detail csv's from which you have to copy columns. Then you'll have to write a formula in each of the four assignment csv's. Then later, if you want to give anyone late credit, you have to do it all again. Using `ck_grader.r`, you only have to download the files, but there's no need to open any of them yourself.
- Written answers are not counted as "correct" in the page detail view. If you don't scroll way to the right to see their answers, you will unwittingly be marking them all incorrect.

## Installation

1. Install R on your computer. Go to [https://cran.r-project.org/mirrors.html](https://cran.r-project.org/mirrors.html), choose a nearby mirror, choose `base`, and follow the instructions.

2. Download the `ck_grader.r` file, along with 'README.md' (which you are reading right now.). You could download this github repository, but it might be simpler to [get them from my dropbox](https://www.dropbox.com/sh/jl7t98jy3c28cnn/AABPrtCmk8ZkhCvtKsfBzr8Ga?dl=0). Put them in the same folder you're going to put all of the csv's you download. This could be your Downloads folder for convenience, as long as you don't mind it getting clogged with hundreds of csv files.

3. There are a few options you should customize. Open `ck_grader.r` in any text editor, such as MS Notepad. Near the top, under `## USER OPTIONS`, you can read about and change the values of `MAX_POINTS`, `INCORRECT_CREDIT`, and `GRACE`. If you want, you can also dive in and change the code itself. I recommend keeping your changes to the function `grade_pd` and the final `for` loop unless you know what you're doing.

## File Name Rules

Decide on the `<course_id>` you want to use for each class. This should consist of letters and/or numbers. It can be the days of the week, section numbers, or start times. Some fine examples are: `MW`, `MTWTh`, `800`, `65432`, or `Spam123`. Whatever it is, every csv you download for this class should start with your `<course_id>`.

All *assignment files* you download should fit one of these formats exactly: 

- `<course_id>_2.1to2.5_9-16.csv`-- Using "to" indicates a range, 2.1 through 2.5.
- `<course_id>_5.10and6.9and7.11_9-16.csv`-- Use "and" for a list of any number of named pages.

Some example assignment file names that are OK:

- `227_2.1to2.5_13-456.csv` -- It doesn't actually matter if the date is real or not, as long as it has one or more digits, a dash, and some more digits, and you use the same date with *page detail* files.
- `MTWTh_2.1and2.2and2.3and2.4and2.5and2.6and2.7and2.8and2.9and2.10and2.11and3.1and3.2and3.3_9-16.csv` -- really, any number is OK.
- `935_2.10to2.10_9-16.csv` -- Do this if you only want to include one section in the assignment.

Some example assignment file names that are NOT OK:

- `227 2.1to2.5 9-16.csv` -- Use `_`, not spaces.
- `227_2.1-2.5_9-16.csv` -- Use `to`, not `-` for page ranges.
- `227_2.8to3.2_9-16.csv` -- Page ranges with `to` must be contained in one chapter.
- `227_2.1to2.5and2.10_9-16.csv` -- Don't combine `and` with `to`.
- `227_2.10_9-16.csv` -- This will be interpreted as a *page detail* file. If you only want one section in your assignment, write `2.10to2.10`.
- `227_2.1to2.5_9/16.csv` -- Use `-` for dates, not `/`.
- `227_02.1to02.5_13-456.csv` -- Don't prepend pages with leading zeros.

The above rules also apply to page detail files, except they should just have one page, with no `to` or `and`. If you want a page detail file to count as part of an assignment, make sure it has the exact same `<course_id>`, and date, and the page is in the range of pages in the assignment file name. Note that `02-14` and `2-14` are interpreted as different dates.

** Notes

- Output files (eg `MW_ck_grades.csv`) and input csv files should not be edited. Specifically, edited column names in output will cause problems. Students *must* be in the same row in every input and output file, so don't mess with rows. If you want to mess with stuff, copy a backup file to a different directory, and mess with that. However...

- Note that output file columns are in the order they were graded, and this may not be what you want. It is OK to move around entire columns by cutting and pasting.

- You don't have to download every page detail csv, but it's a good idea. Often, multiple questions in a page are grouped into one blue box with one submit button. These count as multiple points in the page detail csv, but only one point in the course-wide csv. If you don't include a page detail csv, these questions will be under-represented in scores.

- It is a good idea to keep all of your downloaded csv input files here for the whole semester, as well as occasionally back up your output files (eg, ck_grades_MW.csv) to another directory. If something goes wrong, your output file may be erased.

** Formula customization



