:: USER OPTIONS:

:: Path to folder containing all your downloaded csv files. You must edit this!
set INPUT_DIRECTORY=C:\Users\bensm\Downloads

:: Path to folder where you want your result csv files to go. You must edit this!
set OUTPUT_DIRECTORY=C:\Users\bensm\Desktop

:: Maximum points for each assignment. Can be a number, or "NUM_QUESTIONS" which
:: means 1 point per question in assignment. Default: 10
set MAX_POINTS=10

:: Proportion of credit students get for completing a question, but answer is incorrect.
:: Default: 0.5 (half credit)
set INCORRECT_CREDIT=0.5

:: Proportion of points students are allowed to miss and still get full credit.
:: For example, if GRACE is 0.05, then the final grading step is to divide
:: all scores by (0.95*MAX_POINTS), so 95% becomes 100%. But 0% is still 0%.
:: Scores over 100% are brought down to 100%.
:: Default: 0.05
set GRACE=0.05

:: Do not mess with anything below.
Rscript.exe ./ck_grader.r %INPUT_DIRECTORY% %OUTPUT_DIRECTORY% %MAX_POINTS% %INCORRECT_CREDIT% %GRACE%
pause
