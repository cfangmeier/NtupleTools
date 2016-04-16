import Samples, params
import utils as u
import time
import pprint
import datetime
import json
import sys
import traceback
import os
import logging

data_json = "data.json"
instructions = ""

if len(sys.argv) > 1:
    instructions = sys.argv[1]
else:
    print ">>> python %s INSTRUCTIONS_FILE" % __file__
    sys.exit()

if not os.path.isfile(instructions):
    print ">>> %s does not exist" % instructions
    sys.exit()

if u.proxy_hours_left() < 60:
    print ">>> Proxy near end of lifetime, renewing."
    u.proxy_renew()

u.copy_jecs()
logger_name = u.setup_logger()
logger = logging.getLogger(logger_name)


time_stats = []
if os.path.isfile(data_json):
    with open(data_json, "r") as fhin:
        data = json.load(fhin)
        if "time_stats" in data: time_stats = data["time_stats"]

all_samples = []
for i in range(5000):

    data = { "samples": [], "last_updated": None, "time_stats": time_stats }

    # read instructions file. if new sample found, add it to list
    # for existing samples, try to update params (xsec, kfact, etc.)
    for samp in u.read_samples(instructions):
        if samp not in all_samples:
            s = Samples.Sample(**samp) 
            all_samples.append(s)
        else:
            all_samples[all_samples.index(samp)].update_params(samp)

    # for isample, s in enumerate(all_samples):
    #     s.nuke()
    # sys.exit()

    for isample, s in enumerate(all_samples):

        try:
            stat = s.get_status()

            # grab actions from a text file and act on them, consuming (removing) them if successful
            actions = u.get_actions(dataset_name=s["dataset"])
            if actions:
                for dataset_name, action in actions:
                    if s.handle_action(action): u.consume_actions(dataset_name=s["dataset"])

            if not s.pass_tsa_prechecks(): continue

            if stat == "new":
                s.crab_submit()
            elif stat == "crab":
                s.crab_parse_status()
                if s.is_crab_done():
                    s.make_miniaod_map(force=True)
                    s.make_merging_chunks(force=True)
                    s.submit_merge_jobs()
            elif stat == "postprocessing":
                if s.is_merging_done():
                    if s.check_output():
                        s.make_metadata()
                        s.copy_files()
                else:
                    s.submit_merge_jobs()
            elif stat == "done":
                pass

            s.save()
            data["samples"].append( s.get_slimmed_dict() )

        except Exception, err:
            logger.info( "send an (angry?) email to Nick with the Traceback below!!")
            logger.info( traceback.format_exc() )

    tot_crab_breakdown = u.sum_dicts([samp["crab"]["breakdown"] for samp in data["samples"] if "crab" in samp and "breakdown" in samp["crab"]])
    data["last_updated"] = u.get_timestamp()
    data["time_stats"].append( (u.get_timestamp(), tot_crab_breakdown) )
    data["log"] = u.get_last_n_lines(fname=params.log_file, N=100)
    with open(data_json, "w") as fhout:
        json.dump(data, fhout, sort_keys = True, indent = 4)
    u.copy_json()

    sleep_time = 5 if i < 2 else 600
    logger.debug("sleeping for %i seconds..." % sleep_time)
    time.sleep(sleep_time)

