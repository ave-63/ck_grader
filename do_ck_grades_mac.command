DIRNAME=`dirname $0`

## USER OPTIONS:

## Path to folder containing all your downloaded csv files. You must edit this!
## Note the format: No spaces, and make sure it ends with /
INPUT_DIRECTORY=/home/ben/Downloads/csv_stuff/

## Path to folder where you want your result csv files to go. You must edit this!
## Note the format: No spaces, and make sure it ends with /
OUTPUT_DIRECTORY=/home/ben/Dropbox/Courses/227/

## Maximum points for each assignment. Can be a number, or "NUM_QUESTIONS" which
## means 1 point per question in assignment. Default: 10
MAX_POINTS=10

## Proportion of credit students get for completing a question, but answer is incorrect.
## Default: 0.5 (half credit)
INCORRECT_CREDIT=0.5

## Proportion of points students are allowed to miss and still get full credit.
## For example, if GRACE is 0.05, then the final grading step is to divide
## all scores by (0.95*MAX_POINTS), so 95% becomes 100%. But 0% is still 0%.
## Scores over 100% are brought down to 100%.
## Default: 0.05
GRACE=0.05

Rscript $DIRNAME/ck_grader.r $INPUT_DIRECTORY $OUTPUT_DIRECTORY $MAX_POINTS $INCORRECT_CREDIT $GRACE
read -p "All done! Press [Enter] to quit."
