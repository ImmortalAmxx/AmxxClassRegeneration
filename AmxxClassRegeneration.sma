#include <AmxModX>
#include <ZombiePlague>
//#tryinclude <ReApi> //закомментируйте если не используйте ReAPI

#if !defined _reapi_included
	#include <HamSandWich>
	#include <FakeMeta>
#endif

new const szPlInf[][] = {
	"[ZP 4.3] ZClass: Regeneration",
	"1.0",
	"ImmortalAmxx"
};

new const ZclassInfo[][] = {
	"Умный",
	"Регенерация",
	"Ironmaiden_frk_14",
	"v_creep.mdl",
	"10000",
	"320",
	"1.0",
	"1.0"
};

enum {
	TASKID_REGEN_START = 4444,
	TASKID_REGEN = 777
};

enum _:Cvars {
	DURATION,
	Float:HEALTH_COUNT,
	Float:START_TIME
};

new g_pCvars[Cvars],g_iClassID;

public plugin_init() {
	register_plugin(
		.plugin_name = szPlInf[0], 
		.version = szPlInf[1], 
		.author = szPlInf[2]
	);

	UTIL_Hook();
	UTIL_Cvars();
}

public plugin_precache() {
	g_iClassID = zp_register_zombie_class(
		.name = ZclassInfo[0],
		.info = ZclassInfo[1],
		.model = ZclassInfo[2],
		.clawmodel = ZclassInfo[3],
		.hp = str_to_num(ZclassInfo[4]),
		.speed = str_to_num(ZclassInfo[5]),
		.gravity = str_to_float(ZclassInfo[6]),
		.knockback = str_to_float(ZclassInfo[7])
	);
}

public UTIL_Hook() {
	#if defined _reapi_included
		RegisterHookChain(RG_CBasePlayer_TakeDamage, "CBase_Player_TakeDamage_Post", .post = true);
	#else
		RegisterHam(Ham_TakeDamage, "player", "CBase_Player_TakeDamage_Post", .Post = true);
	#endif
}

public UTIL_Cvars() {
	bind_pcvar_num(create_cvar(
		.name = "zp43_zclass_regen_duration",
		.string = "5.0",
		.description = "Время регенерации.",
		.has_min = true,
		.min_val = 1.0
	), g_pCvars[DURATION]);

	bind_pcvar_float(create_cvar(
		.name = "zp43_zclass_regen_health_count",
		.string = "5.0",
		.description = "По сколько ХП регенерировать?",
		.has_min = true,
		.min_val = 1.0
	), g_pCvars[HEALTH_COUNT]);

	bind_pcvar_float(create_cvar(
		.name = "zp43_zclass_regen_after_damage",
		.string = "5.0",
		.description = "Через сколько секунд после последнего полученного урона начать регенерировать хп?",
		.has_min = true,
		.min_val = 1.0
	), g_pCvars[START_TIME]);

	AutoExecConfig(.autoCreate = true, .name = "AmxxClassRegeneration", .folder = "ImmortalAmxx"); 
}

public CBase_Player_TakeDamage_Post(iPlayer) {
	if(
		!is_user_connected(iPlayer) || 
		!zp_get_user_zombie(iPlayer) ||
		zp_get_user_nemesis(iPlayer) ||
		zp_get_user_zombie_class(iPlayer) != g_iClassID
	)
		return;

	if(task_exists(iPlayer + TASKID_REGEN)) 
		remove_task(iPlayer + TASKID_REGEN);

	if(task_exists(iPlayer + TASKID_REGEN_START)) 
		remove_task(iPlayer + TASKID_REGEN_START);
		
	set_task(g_pCvars[START_TIME], "CTask_RegenStart", iPlayer + TASKID_REGEN_START);
}

public CTask_RegenStart(iPlayer) {
	iPlayer -= TASKID_REGEN_START;

	if(!is_user_connected(iPlayer))
		return;

	set_task(1.0, "CTask_Regeneration", iPlayer + TASKID_REGEN, .flags = "a", .repeat = g_pCvars[DURATION]);
}

public CTask_Regeneration(iPlayer) {
	iPlayer -= TASKID_REGEN;

	if(!is_user_connected(iPlayer))
		return;
	
	#if defined _reapi_included
		new Float:fHp = floatclamp((Float:get_entvar(iPlayer,var_health) + g_pCvars[HEALTH_COUNT]),1.0,str_to_float(ZclassInfo[4]));
		set_entvar(iPlayer, var_health, fHp);
	#else
		new Float:fHp = floatclamp((pev(iPlayer,pev_health) + g_pCvars[HEALTH_COUNT]), 1.0, str_to_float(ZclassInfo[4]));
		set_pev(iPlayer, pev_health, fHp);
	#endif
}
