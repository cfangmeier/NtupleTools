# AutoTwopler
## Instructions
* If you want to use the Twiki utilities on the dashboard, make a `~/.twikipw` file that contains only your Twiki password. Of course, you should `chmod 600` it.
* If beginning a new campaign, make sure to update JECs, CMSSW release, pset names, etc. inside `params.py`, otherwise, don't need to touch this
* `source setup.sh` will set up your environment and make the dashboard
* Use the dashboard to create an `instructions.txt` file (or make it manually following the format of `instructions_test.txt`
* At this point, I prefer to start a screen and then make sure to `source setup.sh` (maybe a couple of times until it doesn't complain).
* `python run.py instructions.txt`
* Sit quack and relax

## TODO:
- [x] Check that nothing happened to the files after copying (don't need to do full blown checkCMS3, just check event counts or something)
- [x] Parse checkCMS3 output and remake stuff appropriately
- [x] Be able to change xsec, kfact, efact before post-processing (through an updated instructions.txt)
- [x] Copy metadata (AND json) to backup directory (right now, it's copied only to the final directory)
- [x] If merged files are already in the final directory, either warn users or mark job as done
- [ ] Be able to nuke and resubmit job from dashboard
- [x] Resubmit crab task if been bootstrapped or some other thing for longer than x minutes
- [x] Don't wait on last x% of MC samples to finish up in crab (put a mask on the job number)
- [ ] Have Condor submission possibility for certain jobs that misbehave
- [x] Make postprocessing part of sample show all jobs done when in done state
- [x] If user enters full twiki name into the dashboard, automatically strip the beginning part to get only the end
- [x] Re-read instructions.txt file every iteration to pull in new information/samples
- [x] If crab status hasn't run yet, we'll have 0 running / 0 total, so monitor page shows NaN%. Force this to 0%.
- [ ] Make tester class
- [x] Add example instructions.txt
- [ ] Grep condor logfiles to get timing statistics for merging/branchadding/copying
- [x] Handle odd hadoop mappings
- [x] Use time_stats key in data to make plot of crab jobs over time
- [ ] Deal with CRAB HTTP exceptions elegantly
- [ ] Don't rely on CRAB status codes. Use our own. In particular. isComplete = (nComplete == nTot) is all one needs.
