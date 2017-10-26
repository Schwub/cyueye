import pstats, cProfile

import test

cProfile.runctx("test", globals(), locals(), "Profile.prof")
s=pstats.Stats("Profile.prof")
s.strip_dirs().sort_stats("time").print_stats()
