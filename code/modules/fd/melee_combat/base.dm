#define STRIKE_MULT_DMG_LIGHT 0.6
#define STRIKE_MULT_DMG_MEDIUM 0.8
#define STRIKE_MULT_DMG_STANDARD 1
#define STRIKE_MULT_DMG_HEAVY 1.2
#define STRIKE_MULT_DMG_SUPERHEAVY 2

#define STRIKE_MULT_SPEED_FAST 0.6
#define STRIKE_MULT_SPEED_MEDIUM 0.8
#define STRIKE_MULT_SPEED_STANDARD 1
#define STRIKE_MULT_SPEED_SLOW 1.3
#define STRIKE_MULT_SPEED_SUPERSLOW 1.5

/obj/item
	var/have_stances = FALSE
	var/list/melee_strikes = null //���� ���� ������� ������ � ��������
	var/datum/melee_strike/melee_strike = null

/obj/item/New()
	if(melee_strikes)
		melee_strikes += null
		for(var/type in melee_strikes)
			if(isnull(type))
				continue
			var/strike = new type
			melee_strikes -= type
			melee_strikes += strike
	. = ..()

/obj/item/proc/has_melee_strike(var/mob/user)
	if(isnull(melee_strikes))
		return null
	if(isnull(melee_strike))
		melee_strike = melee_strikes[1]
		if(!isnull(melee_strike))
			melee_strike.strike_active(user)

	return melee_strike

/obj/item/attack_self(mob/living/carbon/user)
	. = ..()

	if(have_stances)
		swap_stances(user)

/*/obj/item/proc/verb_swap_stances()
	set name = "�������� ������"
	set category = "Object"
	var/mob/living/carbon/human/user = usr
	if(!istype(user)) return
	if(user.stat) return*/

/obj/item/proc/swap_stances(var/mob/user)
	if(!melee_strikes || melee_strikes.len == 1)
//		verbs -= /obj/item/proc/verb_swap_stances
		return
	var/datum/melee_strike/stance_curr = melee_strikes[1]
	melee_strikes -= stance_curr
	melee_strikes += stance_curr
	stance_curr = melee_strikes[1]
	melee_strike = stance_curr
	if(stance_curr == null)
		to_chat(user,"<span class = 'danger'>�� ������� ����������� ������ ��� ������ ������</span>")
		return
	stance_curr.strike_active(user)

/*/obj/item/equipped(var/mob/living/carbon/human/user)
	. = ..()
	if(src in list(user.l_hand,user.r_hand) && has_melee_strike(user))
		verbs |= /obj/item/proc/verb_swap_stances
	else
		verbs -= /obj/item/proc/verb_swap_stances

/obj/item/dropped(mob/user as mob)
	. = ..()
	if(src in list(user.l_hand,user.r_hand) && has_melee_strike(user))
		verbs |= /obj/item/proc/verb_swap_stances
	else
		verbs -= /obj/item/proc/verb_swap_stances*/

/////////////////////////////////////////////////////////////////

/datum/melee_strike
	var/list/strike_verbs = null //���������, ������� ������� ���������� ����� ��� �������������
	var/strike_dmg = 1 //��������� ������
	var/strike_speed = 1 //��������� ��������, ��� ���� - ��� ������ ����� ����� �������
	var/strike_range = 1 //���������� ��� ���������� ����� � ������, ����� ������ ������ ���� ����� ������������ � afterattack() - ������ ����� � ��� �����
	var/strike_switch_text = "�� ������ � ���."

	//���� ��������� ����������� �����. ����� ������������ ��� �������� ���������� �� ���������� ������ ������ � ����. ���� �� ��������� - �� ������ ���������� ������ � ��� ������� ������
	var/next_strike = null
	//����� ��� ���������� �����. ���� ������ ������, � ���� �� ���������� - ���������� ������ � ������� ������
	var/chain_timeframe = 2 SECONDS
	var/chain_expire_at = 0
	var/chain_base_strike = null

/datum/melee_strike/proc/strike_active(var/mob/user)
	if(strike_switch_text)
		to_chat(user,"<span class = 'danger'>[strike_switch_text]</span>")

/datum/melee_strike/proc/strike_invalid_target(var/mob/user,var/obj/item/striker)
	to_chat(user,"<span class = 'danger'>[user] ��������� �������������� �����, ��������� [striker]</span>")
	user.setClickCooldown(striker.attack_cooldown)

/datum/melee_strike/proc/do_pre_strike(var/mob/user,var/atom/target,var/obj/item/striker,var/click_params)
	var/datum/melee_strike/strike_use = src
	if(chain_base_strike)
		if(chain_expire_at == 0)
			chain_expire_at = world.time + chain_timeframe
		else if(world.time >= chain_expire_at) //���� ����� �� �������� ���� ���� ������� - ���������� �� � ��������� ������
			chain_expire_at = 0
			strike_use = create_new_strike(user,striker,chain_base_strike)
			strike_use.strike_active(user)

	//���������� ������� �����
	var/list/old_verbs = striker.attack_verb
	var/old_dmg = striker.force
	var/old_speed = striker.attack_cooldown
	if(strike_verbs)
		old_verbs = old_verbs.Copy()
		striker.attack_verb = strike_verbs
	if(strike_dmg != 1)
		striker.force *= strike_dmg
	if(strike_speed != 1)
		striker.attack_cooldown *= strike_speed


	if(!strike_use.do_strike(user,target,striker,click_params))
		strike_invalid_target(user,striker)
	strike_use.post_strike(user,target,striker,click_params)

	striker.attack_verb = old_verbs
	striker.force = old_dmg
	striker.attack_cooldown = old_speed
	return 1

/datum/melee_strike/proc/do_strike_targ(var/mob/user,var/mob/living/m,var/obj/item/striker,var/click_params)
	m.attackby(striker, user, click_params)

/datum/melee_strike/proc/do_strike(var/mob/user,var/atom/target,var/obj/item/striker,var/click_params)

/datum/melee_strike/proc/post_strike(var/mob/user,var/atom/target,var/obj/item/striker,var/click_params)
	if(next_strike)
		var/datum/melee_strike/strike = create_new_strike(user,striker,next_strike)
		strike.strike_active(user)

/datum/melee_strike/proc/create_new_strike(var/mob/user,var/obj/item/striker,var/new_path)
	var/datum/melee_strike/new_strike = new new_path ()
	striker.melee_strike = new_strike
	new_strike.chain_expire_at = world.time + chain_timeframe
	new_strike.chain_base_strike = chain_base_strike
	if(chain_base_strike && type != chain_base_strike)
		qdel(src)
	return new_strike

//������� �����//

/datum/melee_strike/precise_strike/do_strike(var/mob/user,var/turf/target,var/obj/item/striker,var/click_params)
	if(istype(target))
		var/list/turf_mobs = list()
		for(var/mob/living/m in target.contents)
			turf_mobs += m
		if(turf_mobs.len != 0)
			target = pick(turf_mobs)
		else
			return 0

	if(ismob(target) && target != user)
		do_strike_targ(user,target,striker,click_params)

	return 1

/datum/melee_strike/swipe_strike/do_strike(var/mob/user,var/turf/target,var/obj/item/striker,var/click_params)
	var/list/targets = list()
	var/turf/targ_turf = get_turf(target)
	if(istype(targ_turf))
		var/list/turfs_search = list(targ_turf)
		var/attack_dir = get_dir(user,targ_turf)
		turfs_search += list( get_step(targ_turf,turn(attack_dir,90)),get_step(targ_turf,turn(attack_dir,-90)) )
		for(var/turf/search in turfs_search)
			for(var/mob/living/m in search.contents)
				targets += m

	if(targets.len != 0)
		for(var/mob in targets)
			if(user == mob)
				continue
			do_strike_targ(user,mob,striker,click_params)
	else
		return 0

	return 1

//���� � ������ �������� �������

//��� ������� ������, �������������� ������ ������
/datum/melee_strike/precise_strike/fast_attacks
	strike_switch_text = "�� ������������� � ���������� ���������� ����������� ����..."
	strike_dmg = STRIKE_MULT_DMG_LIGHT
	strike_speed = STRIKE_MULT_SPEED_MEDIUM
	strike_verbs = list("slashed","sliced","cut")
	next_strike = /datum/melee_strike/precise_strike/fast_attacks/c1
	chain_base_strike = /datum/melee_strike/precise_strike/fast_attacks

/datum/melee_strike/precise_strike/fast_attacks/c1
	strike_switch_text = null
	next_strike = /datum/melee_strike/precise_strike/fast_attacks/c2

/datum/melee_strike/precise_strike/fast_attacks/c2
	strike_switch_text = null
	strike_speed = STRIKE_MULT_SPEED_SUPERSLOW //��������� ����� ����� ������ ������������, ��� ��� ����� ����� ���� ������ ����������� ���� �� ��
	next_strike = /datum/melee_strike/precise_strike/fast_attacks/finalone

/datum/melee_strike/precise_strike/fast_attacks/finalone
	strike_dmg = STRIKE_MULT_DMG_SUPERHEAVY
	strike_speed = STRIKE_MULT_SPEED_MEDIUM
	strike_verbs = list("shanked","stabbed","pierced")
	strike_switch_text = "�� ���������� ��������� ���� ����!"
	//��������� ��������� ������ ����� �� �������������, ���� ������ ��������. 28 ������ �����, �� ���������� ���������?
	next_strike = /datum/melee_strike/precise_strike/fast_attacks

//���� �����

/datum/melee_strike/swipe_strike/harrying_strike
	strike_dmg = STRIKE_MULT_DMG_LIGHT
	strike_speed = STRIKE_MULT_SPEED_MEDIUM
	strike_verbs = list("shallowly cut","lacerated")
	strike_switch_text = "�� ������������� ��� ���������� ������ �������� ������..."

//���� � ������ ������� �������

//��������� �����

/datum/melee_strike/swipe_strike/mixed_combo
	strike_dmg = STRIKE_MULT_DMG_LIGHT
	strike_verbs = list("shallowly slashed","shallowly cut")
	strike_switch_text = "�� ����������� � �����, �������� ��������� ����� �� ������� ������� ������..."
	next_strike = /datum/melee_strike/precise_strike/mixed_combo
	chain_base_strike = /datum/melee_strike/swipe_strike/mixed_combo

/datum/melee_strike/precise_strike/mixed_combo
	strike_dmg = STRIKE_MULT_DMG_STANDARD
	strike_speed = STRIKE_MULT_SPEED_MEDIUM
	strike_verbs = list("hewed","chopped")
	strike_switch_text = null
	next_strike = /datum/melee_strike/precise_strike/mixed_combo/c1
	chain_base_strike = /datum/melee_strike/swipe_strike/mixed_combo

/datum/melee_strike/precise_strike/mixed_combo/c1
	next_strike = /datum/melee_strike/swipe_strike/mixed_combo

//��� ������ �����

/datum/melee_strike/swipe_strike/sword_slashes
	strike_dmg = STRIKE_MULT_DMG_MEDIUM
	strike_verbs = list("shallowly slashed","shallowly cut")
	strike_switch_text = "�� ���������� ��������� ��������� ���������������� ������ �������..."
	next_strike = /datum/melee_strike/swipe_strike/sword_slashes/slow
	chain_base_strike = /datum/melee_strike/swipe_strike/sword_slashes

/datum/melee_strike/swipe_strike/sword_slashes/slow
	strike_dmg = STRIKE_MULT_DMG_STANDARD
	strike_speed = STRIKE_MULT_SPEED_SLOW
	strike_verbs = list("shallowly slashed","shallowly cut")
	strike_switch_text = null
	next_strike = /datum/melee_strike/swipe_strike/sword_slashes
	chain_base_strike = /datum/melee_strike/swipe_strike/sword_slashes

//��������� ������

//��������� �����

/datum/melee_strike/swipe_strike/polearm_mixed
	strike_dmg = STRIKE_MULT_DMG_STANDARD
	strike_speed = STRIKE_MULT_SPEED_SLOW
	strike_verbs = list("slashed","cut","lacerated")
	strike_switch_text = "�� ���������� �� ��� ������ ���������, �������� � ���������� ���������� ������� � ������� ����..."
	next_strike = /datum/melee_strike/precise_strike/polearm_mixed
	chain_base_strike = /datum/melee_strike/swipe_strike/polearm_mixed

/datum/melee_strike/precise_strike/polearm_mixed
	strike_dmg = STRIKE_MULT_DMG_STANDARD
	strike_speed = STRIKE_MULT_SPEED_STANDARD
	strike_verbs = list("stabbed","impaled")
	strike_range = 2
	strike_switch_text = null
	next_strike = /datum/melee_strike/precise_strike/polearm_mixed/c1
	chain_base_strike = /datum/melee_strike/swipe_strike/polearm_mixed

/datum/melee_strike/precise_strike/polearm_mixed/c1
	strike_dmg = STRIKE_MULT_DMG_LIGHT
	strike_speed = STRIKE_MULT_SPEED_MEDIUM
	strike_verbs = list("grazingly stabbed","grazingly jabbed")
	strike_switch_text = null
	next_strike = /datum/melee_strike/swipe_strike/polearm_mixed/finale
	chain_base_strike = /datum/melee_strike/swipe_strike/polearm_mixed

/datum/melee_strike/swipe_strike/polearm_mixed/finale
	strike_dmg = STRIKE_MULT_DMG_SUPERHEAVY
	strike_speed = STRIKE_MULT_SPEED_SLOW
	strike_verbs = list("slashed","cut","lacerated")
	strike_switch_text = null
	next_strike = /datum/melee_strike/swipe_strike/polearm_mixed
	chain_base_strike = /datum/melee_strike/swipe_strike/polearm_mixed

//�������� ������

/datum/melee_strike/swipe_strike/polearm_slash
	strike_dmg = STRIKE_MULT_DMG_STANDARD
	strike_speed = STRIKE_MULT_SPEED_SLOW
	strike_range = 2
	strike_verbs = list("slashed","cut","lacerated")
	strike_switch_text = "�� ������������� � ���������� ��������� �������� �����..."
	next_strike = /datum/melee_strike/swipe_strike/polearm_slash/slow
	chain_base_strike = /datum/melee_strike/swipe_strike/polearm_slash

/datum/melee_strike/swipe_strike/polearm_slash/slow
	strike_dmg = STRIKE_MULT_DMG_STANDARD
	strike_speed = STRIKE_MULT_SPEED_SUPERSLOW
	strike_verbs = list("slashed","cut","lacerated")
	strike_switch_text = null
	next_strike = /datum/melee_strike/swipe_strike/polearm_slash
	chain_base_strike = /datum/melee_strike/swipe_strike/polearm_slash

//������

//� �����, �� �� �� �����, ��� � � ����������, �� � ����� ������ ������

/datum/melee_strike/swipe_strike/polearm_mixed/hammer
	strike_verbs = list("smashed","crushed","whacked")
	next_strike = /datum/melee_strike/precise_strike/polearm_mixed/hammer
	chain_base_strike = /datum/melee_strike/swipe_strike/polearm_mixed/hammer

/datum/melee_strike/precise_strike/polearm_mixed/hammer
	strike_verbs = list("jabbed","poked")
	next_strike = /datum/melee_strike/precise_strike/polearm_mixed/c1/hammer
	chain_base_strike = /datum/melee_strike/swipe_strike/polearm_mixed/hammer

/datum/melee_strike/precise_strike/polearm_mixed/c1/hammer
	strike_verbs = list("grazingly jabbed","grazingly poked")
	next_strike = /datum/melee_strike/swipe_strike/polearm_mixed/finale/hammer
	chain_base_strike = /datum/melee_strike/swipe_strike/polearm_mixed/hammer

/datum/melee_strike/swipe_strike/polearm_mixed/finale/hammer
	strike_verbs = list("smashed","crushed","whacked")
	next_strike = /datum/melee_strike/swipe_strike/polearm_mixed/hammer
	chain_base_strike = /datum/melee_strike/swipe_strike/polearm_mixed/hammer

//����������� �����

/datum/melee_strike/swipe_strike/polearm_slash/hammer
	strike_verbs = list("smashed","crushed","whacked")
	next_strike = /datum/melee_strike/swipe_strike/polearm_slash/slow/hammer
	chain_base_strike = /datum/melee_strike/swipe_strike/polearm_slash/hammer

/datum/melee_strike/swipe_strike/polearm_slash/slow/hammer
	strike_verbs = list("smashed","crushed","whacked")
	next_strike = /datum/melee_strike/swipe_strike/polearm_slash/hammer
	chain_base_strike = /datum/melee_strike/swipe_strike/polearm_slash/hammer

#undef STRIKE_MULT_DMG_LIGHT
#undef STRIKE_MULT_DMG_MEDIUM
#undef STRIKE_MULT_DMG_STANDARD
#undef STRIKE_MULT_DMG_HEAVY
#undef STRIKE_MULT_DMG_SUPERHEAVY

#undef STRIKE_MULT_SPEED_FAST
#undef STRIKE_MULT_SPEED_MEDIUM
#undef STRIKE_MULT_SPEED_STANDARD
#undef STRIKE_MULT_SPEED_SLOW
#undef STRIKE_MULT_SPEED_SUPERSLOW