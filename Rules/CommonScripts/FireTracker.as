#define CLIENT_ONLY

#include "FireParticle.as"

uint[] active_positions;

CParticle@ MakeFireLightParticle(Vec2f position)
{
	Random r;

	CParticle@ p = ParticleAnimated(
		"light.png",
		position + getRandomVelocity(0, 32.0f, 360.0f),
		Vec2f(0.0f, -0.8f) + getRandomVelocity(0, 0.1f, 360.0f),
		0.0f,
		0.05f + r.NextFloat() * 0.1f,
		0,
		0,
		Vec2f(256, 256),
		0,
		0.0f,
		false);

	if (p is null) { return null; }

	p.timeout = 30;
	p.deadeffect = -1;
	p.growth = 0.02;
	p.diesonanimate = false;
	p.colour = SColor(255, 255, 50, 0);
	p.fadeout = true;
	p.fadeoutmod = 0.92f;
	p.setRenderStyle(RenderStyle::light, false, true);

	return @p;
}

Vec2f offsetToWorldspace(uint offset) {
    CMap@ map = @getMap();
    int X = offset % map.tilemapwidth;
	int Y = offset / map.tilemapwidth;

	Vec2f pos = Vec2f(X, Y);
	float ts = map.tilesize;

    return pos * ts;
}

void CalculateMinimapColour( CMap@ map, u32 offset, TileType tile, SColor &out col)
{
    if (map.isInFire(offsetToWorldspace(offset)))
	{
        if (active_positions.find(offset) >= 0)
        {
            return;
        }

        print("fiyah");

        active_positions.insertLast(offset);
	}
    else
    {
        int index = active_positions.find(offset);
        if (index > 0)
        {
            active_positions.removeAt(index);
        }

        print("i slep");
    }

    col = col;
}

void onReload(CRules@ rules)
{
    active_positions.clear();
    getMap().AddScript("firetracker");
}

void onInit(CRules@ rules)
{
    onReload(@rules);
}

void onTick(CRules@ rules)
{
    print(""+active_positions.length);
    for (int i = 0; i < active_positions.length; ++i)
    {
        if (XORRandom(3) == 0)
        {
            MakeFireLightParticle(offsetToWorldspace(active_positions[i]));
        }
    }
}