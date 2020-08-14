#pragma semicolon 1

#include <sourcemod>
#include <cstrike>
#include <sdktools>

#pragma newdecls required

#define COLORED_SMOKE_PARTICLE "particles/colored_smoke.pcf"

#define PLUGIN_VERSION "1.0.0"

enum struct CEffectData
{
    float m_vOrigin[3];
    float m_vStart[3];
    float m_vNormal[3];
    float m_vAngles[3];
    int m_fFlags;
    int m_nEntIndex;
    float m_flScale;
    float m_flMagnitude;
    float m_flRadius;
    int m_nAttachmentIndex;
    int m_nSurfaceProp;
    int m_nMaterial;
    int m_nDamageType;
    int m_nHitBox;
    int m_nOtherEntIndex;
    int m_nColor;
    bool m_bPositionsAreRelativeToEntity;
    int m_iEffectName;
}

ConVar  g_CVarEnable,
        g_CVarMode,
        g_CVarTColor,
        g_CVarCTColor,
        g_CVarSaturation,
        g_CVarBrightness;

public Plugin myinfo = 
{
    name = "[CS:GO] Colored Smoke",
    author = "vanz",
    version = PLUGIN_VERSION
};

public void OnPluginStart()
{
    CreateConVar("sm_colored_smoke_version", PLUGIN_VERSION, "Plugin version", FCVAR_NOTIFY|FCVAR_DONTRECORD);
    
    g_CVarEnable        = CreateConVar("sm_colored_smoke_enable",       "1",        "Enable/disable plugin", _, true, 0.0, true, 1.0);
    g_CVarMode          = CreateConVar("sm_colored_smoke_mode",         "1",        "0 = Team, 1 = Random", _, true, 0.0, true, 1.0);
    g_CVarTColor        = CreateConVar("sm_colored_smoke_t_color",      "255 0 0",  "Smoke color of T team");
    g_CVarCTColor       = CreateConVar("sm_colored_smoke_ct_color",     "0 0 255",  "Smoke color of CT team");
    g_CVarSaturation    = CreateConVar("sm_colored_smoke_saturation",   "1.0",      "Smoke color saturation", _, true, 0.0, true, 1.0);
    g_CVarBrightness    = CreateConVar("sm_colored_smoke_brightness",   "1.0",      "Smoke color brightness", _, true, 0.0, true, 1.0);
    
    HookEvent("smokegrenade_detonate", Event_SmokeDetonate);
    
    AutoExecConfig(true, "colored_smoke");
}

public void OnMapStart()
{
    AddFileToDownloadsTable(COLORED_SMOKE_PARTICLE);
    PrecacheGeneric(COLORED_SMOKE_PARTICLE, true);
}

public void Event_SmokeDetonate(Event event, const char[] name, bool dontBroadcast)
{
    if (!g_CVarEnable.BoolValue)
        return;

    StopParticleEffect(0, "explosion_smokegrenade_fallback");

    float xyz[3];
    xyz[0] = event.GetFloat("x");
    xyz[1] = event.GetFloat("y");
    xyz[2] = event.GetFloat("z");
    
    int client = GetClientOfUserId(event.GetInt("userid"));

    StartSmokeEffect("explosion_smokegrenade_colored", xyz, client);
}

void StartSmokeEffect(const char[] smokeParticle, const float origin[3], int client)
{
    CEffectData data;
    
    data.m_vOrigin[0] = origin[0];
    data.m_vOrigin[1] = origin[1];
    data.m_vOrigin[2] = origin[2];
    
    float r = 90.0, g = 90.0, b = 90.0;
    
    if (g_CVarMode.IntValue == 1)
    {
        HSV2RGB(GetRandomFloat(0.0, 360.0), g_CVarSaturation.FloatValue, g_CVarBrightness.FloatValue, r, g, b);
        r *= 255.0, g *= 255.0, b *= 255.0;
    }
    else
    {
        if (IsValidClient(client))
        {
            switch (GetClientTeam(client))
            {
                case CS_TEAM_T:  GetCVarRGB(g_CVarTColor, r, g, b);
                case CS_TEAM_CT: GetCVarRGB(g_CVarCTColor, r, g, b);
            }
        }
    }
    
    data.m_vStart[0] = r;
    data.m_vStart[1] = g;
    data.m_vStart[2] = b;
    
    data.m_nHitBox = GetParticleSystemIndex(smokeParticle);

    DispatchEffect("ParticleEffect", data);
}

void StopParticleEffect(int entity, const char[] particleName)
{
    CEffectData data;

    data.m_nEntIndex = entity;
    data.m_nHitBox = GetParticleSystemIndex(particleName);

    DispatchEffect("ParticleEffectStop", data);
}

void DispatchEffect(const char[] effectName, CEffectData data)
{
    data.m_iEffectName = GetEffectIndex(effectName);

    TE_SetupEffectDispatch(data);
    TE_SendToAll();
}

int GetEffectIndex(const char[] effectName)
{
    static int table = INVALID_STRING_TABLE;
    
    if (table == INVALID_STRING_TABLE)
        table = FindStringTable("EffectDispatch");
    
    int index = FindStringIndex(table, effectName);
    
    if (index != INVALID_STRING_INDEX)
        return index;

    return 0;
}

int GetParticleSystemIndex(const char[] effectName)
{
    static int table = INVALID_STRING_TABLE;
    
    if (table == INVALID_STRING_TABLE)
        table = FindStringTable("ParticleEffectNames");
    
    int index = FindStringIndex(table, effectName);
    
    if (index != INVALID_STRING_INDEX)
        return index;

    return 0;
}

void TE_SetupEffectDispatch(CEffectData data)
{
    TE_Start("EffectDispatch");
    TE_WriteFloatArray("m_vOrigin.x", data.m_vOrigin, 3);
    TE_WriteFloatArray("m_vStart.x", data.m_vStart, 3);
    TE_WriteAngles("m_vAngles", data.m_vAngles);
    TE_WriteVector("m_vNormal", data.m_vNormal);
    TE_WriteNum("m_fFlags", data.m_fFlags);
    TE_WriteFloat("m_flMagnitude", data.m_flMagnitude);
    TE_WriteFloat("m_flScale", data.m_flScale);
    TE_WriteNum("m_nAttachmentIndex", data.m_nAttachmentIndex);
    TE_WriteNum("m_nSurfaceProp", data.m_nSurfaceProp);
    TE_WriteNum("m_iEffectName", data.m_iEffectName);
    TE_WriteNum("m_nMaterial", data.m_nMaterial);
    TE_WriteNum("m_nDamageType", data.m_nDamageType);
    TE_WriteNum("m_nHitBox", data.m_nHitBox);
    TE_WriteNum("entindex", data.m_nEntIndex);
    TE_WriteNum("m_nOtherEntIndex", data.m_nOtherEntIndex);
    TE_WriteNum("m_nColor", data.m_nColor);
    TE_WriteFloat("m_flRadius", data.m_flRadius);
    TE_WriteNum("m_bPositionsAreRelativeToEntity", data.m_bPositionsAreRelativeToEntity);
}

void HSV2RGB(float h, float s, float v, float& r, float& g, float& b)
{
    if (s == 0.0)
    {
        r = v, g = v, b = v;
        return;
    }
    
    if (h == 360.0) 
        h = 0.0;

    int   hi = RoundToFloor(h / 60.0);
    float f  = (h / 60.0) - hi;
    float p  = v * (1.0 - s);
    float q  = v * (1.0 - s * f);
    float t  = v * (1.0 - s * (1.0 - f));

    switch (hi)
    {
        case 0: r = v, g = t, b = p;
        case 1: r = q, g = v, b = p;
        case 2: r = p, g = v, b = t;
        case 3: r = p, g = q, b = v;
        case 4: r = t, g = p, b = v;
        default: r = v, g = p, b = q;
    }
}

void GetCVarRGB(ConVar convar, float& r, float& g, float& b)
{
    char str[64];
    convar.GetString(str, sizeof(str));

    char split[3][16];  
    ExplodeString(str, " ", split, sizeof(split), sizeof(split[]));
    
    r = StringToFloat(split[0]);
    g = StringToFloat(split[1]);
    b = StringToFloat(split[2]);
}

bool IsValidClient(int client)
{
    return (client > 0 && client <= MaxClients && IsClientInGame(client));
}
