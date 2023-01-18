/obj/machinery/computer/ship/autocannon/harpoon/fire(mob/user)
	if(!link_parts())
		return FALSE //no disperser, no service
	if(!front.powered() || !middle.powered() || !back.powered())
		return FALSE //no power, no boom boom
	var/atomcharge_ammo = get_ammo()
	if(atomcharge_ammo <= 0)
		return FALSE

	var/turf/start = front
	var/direction = front.dir

	var/distance = 0
	for(var/turf/T in getline(get_step(front,front.dir),get_target_turf(start, direction)))
		distance++
		if(T.density)
			if(distance < danger_zone)
				explosion(T,1,2,2)
				continue
			else
				T.ex_act(1)
		for(var/atom/A in T)
			if(A.density)
				if(distance < danger_zone)
					explosion(A,1,2,2)
					break
				else
					A.ex_act(1)

	var/list/relevant_z = GetConnectedZlevels(start.z)
	for(var/mob/M in GLOB.player_list)
		var/turf/T = get_turf(M)
		if(!T || !(T.z in relevant_z))
			continue
		shake_camera(M, 8)
		if(!isdeaf(M))
			sound_to(M, sound('sound/effects/explosionfar.ogg', volume=10))

	if(front) //Meanwhile front might have exploded
		front.layer = ABOVE_OBJ_LAYER //So the beam goes below us. Looks a lot better
	playsound(start, fire_sound, 250, 1)
	handle_muzzle(start, direction)
	handle_overbeam()

	//Success, but we missed.
	if(prob(100 - cal_accuracy()))
		return TRUE

	var/turf/overmaptarget = get_step(get_step(linked, overmapdir), overmapdir)
	var/list/candidates = list()

	//Next we see if there are any ships around. Logically they are between us and the sector if one exists.
	if(!length(candidates))
		for(var/obj/effect/overmap/visitable/ship/S in overmaptarget)
			if(S == linked)
				continue //Why are you shooting yourself?
			candidates += S

	if(!length(candidates))
		for(var/obj/effect/overmap/visitable/O in overmaptarget)
			if(O == linked)
				continue //Why are you shooting yourself?
			candidates += O

	//Way to waste a charge
	if(!length(candidates))
		return TRUE

/obj/machinery/computer/ship/autocannon/harpoon/fire_at_sector(var/z_level, var/target_fore_dir, var/target_dir)
	log_and_message_admins("[z_level] just got harpooned (<A HREF='?_src_=holder;adminplayerobservecoodjump=1;X=[world.maxx/2];Y=[world.maxy/2];Z=[z_level]'>JMP</a>)")



/obj/machinery/computer/ship/autocannon/harpoon/handle_overbeam()
	set waitfor = FALSE
	linked.Beam(get_step(linked, overmapdir), overmap_icon, time = 2, maxdistance = world.maxx)