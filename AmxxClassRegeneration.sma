/*
	changelog: 
		- v1.0 - Релиз.
		- v1.1: 
			- Добавлен квар "zp43_zclass_regen_nemesis" (Регенерация для немезиды); 
			- Поправлен и переработан квар "zp43_zclass_regen_duration" (Возможность бесконечной регенерации);
		- v1.2:
			- Попавлен квар "zp43_zclass_regen_nemesis" - (Выставляло хп зомби класса);
			- Теперь, после того, как игрок стал человеком или вышел - регенерация убирается (Ранее этого не было предусмотренно);

	gratitude:
		b0t. - За помощь в реализации.
*/

#include <AmxModX>
#include <ZombiePlague>
//#tryinclude <ReApi> //закомментируйте если не используйте ReAPI

#if !defined _reapi_included
	#include <HamSandWich>
	#include <FakeMeta>
#endif

new const szPlInf[][] = {
	"[ZP 4.3] ZClass: Regeneration",
	"1.1",
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
	Float:START_TIME,
	NEMESIS,
	Float:MAX_REGEN_HEALTH
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

public client_disconnected(pPlayer)
	RemoveRegeneration(pPlayer);

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
		.string = "5",
		.description = "Время регенерации. 0 - Бесконечно",
		.has_min = true,
		.min_val = 0.0
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
	
	bind_pcvar_num(create_cvar(
		.name = "zp43_zclass_regen_nemesis",
		.string = "1",
		.description = "Давать регенерацию немезиде? 0 - Нет, 1 - Да.",
		.has_min = true,
		.min_val = 0.0,
		.has_max = true,
		.max_val = 1.0
	), g_pCvars[NEMESIS]);	

	AutoExecConfig(.autoCreate = true, .name = "AmxxClassRegeneration", .folder = "ImmortalAmxx"); 
}

public CBase_Player_TakeDamage_Post(pPlayer) {
	if(
		!is_user_connected(pPlayer) || 
		!zp_get_user_zombie(pPlayer) ||
		zp_get_user_zombie_class(pPlayer) != g_iClassID
	)
		return;
		
	if(!g_pCvars[NEMESIS]) {
		if(zp_get_user_nemesis(pPlayer))
			return;
	}

	RemoveRegeneration(pPlayer);
		
	set_task(g_pCvars[START_TIME], "CTask_RegenStart", pPlayer + TASKID_REGEN_START);
}

public CTask_RegenStart(pPlayer) {
	pPlayer -= TASKID_REGEN_START;

	if(!is_user_connected(pPlayer))
		return;
	
	if(!g_pCvars[DURATION])
		set_task(1.0, "CTask_Regeneration", pPlayer + TASKID_REGEN, .flags = "b");
	else
		set_task(1.0, "CTask_Regeneration", pPlayer + TASKID_REGEN, .flags = "a", .repeat = g_pCvars[DURATION]);
}

public CTask_Regeneration(pPlayer) {
	pPlayer -= TASKID_REGEN;

	if(!is_user_connected(pPlayer))
		return;
	
	new pCvar = get_cvar_num("zp_nem_health");

	#if defined _reapi_included
		new Float:fHp = floatclamp((Float:get_entvar(pPlayer,var_health) + g_pCvars[HEALTH_COUNT]), 1.0, zp_get_user_nemesis(pPlayer) ? float(pCvar) : str_to_float(ZclassInfo[4]));
		set_entvar(pPlayer, var_health, fHp);
	#else
		new Float:fHp = floatclamp((pev(pPlayer,pev_health) + g_pCvars[HEALTH_COUNT]), 1.0, zp_get_user_nemesis(pPlayer) ? float(pCvar) : str_to_float(ZclassInfo[4]));
		set_pev(pPlayer, pev_health, fHp);
	#endif
}

public zp_user_humanized_post(pPlayer) 
	RemoveRegeneration(pPlayer);

public RemoveRegeneration(pPlayer) {
	if(task_exists(pPlayer + TASKID_REGEN)) 
		remove_task(pPlayer + TASKID_REGEN);

	if(task_exists(pPlayer + TASKID_REGEN_START)) 
		remove_task(pPlayer + TASKID_REGEN_START);	
}
