/datum/controller
	var/name
	var/tmp/atom/movable/clickable_stat/stat_line

	/// The next time we should do work updating statLine
	var/statNext = 0

/datum/controller/proc/Initialize()


/// cleanup actions
/datum/controller/proc/Shutdown()


/// when we enter dmm_suite.load_map
/datum/controller/proc/StartLoadingMap()


/// when we exit dmm_suite.load_map
/datum/controller/proc/StopLoadingMap()


/datum/controller/proc/Recover()


/datum/controller/proc/stat_entry()


/// The last time stat_entry was called
/datum/controller/var/tmp/stat_last = 0

/// The next time we should do work updating the stat entry
/datum/controller/var/tmp/stat_next = 0

/// Convenience define to use in stat_entry to avoid extra work. Signature requires a 'force' var if used.
#define IF_UPDATE_STAT if ((force && (stat_next = (REALTIMEOFDAY + 1 SECOND))) || (stat_next < (stat_last = REALTIMEOFDAY) ? (stat_next = (stat_last + 1 SECOND)) : FALSE))

/datum/controller/proc/UpdateStat(text)
	if (!stat_line)
		stat_line = new (null, src)
	if (istext(text))
		stat_line.name = text
	stat(name, stat_line)


/datum/controller/proc/PreventUpdateStat(time)
	if (!isnum(time))
		time = REALTIMEOFDAY
	if (time < statNext)
		return TRUE
	statNext = time + 1 SECONDS
	return FALSE