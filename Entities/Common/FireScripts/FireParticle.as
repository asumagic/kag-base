//spawning a generic fire particle

void makeFireParticle(Vec2f pos, int smokeRandom = 1)
{
	string texture;

	switch (XORRandom(XORRandom(smokeRandom) == 0 ? 4 : 2))
	{
		case 0: texture = "Entities/Effects/Sprites/SmallFire1.png"; break;

		case 1: texture = "Entities/Effects/Sprites/SmallFire2.png"; break;

		case 2: texture = "Entities/Effects/Sprites/SmallSmoke1.png"; break;

		case 3: texture = "Entities/Effects/Sprites/SmallSmoke2.png"; break;
	}

	ParticleAnimated(texture, pos, Vec2f(0, 0), 0.0f, 1.0f, 5, -0.1, true);
}

void makeSmokeParticle(Vec2f pos, f32 gravity = -0.06f)
{
	string texture;

	switch (XORRandom(2))
	{
		case 0: texture = "Entities/Effects/Sprites/SmallSmoke1.png"; break;

		case 1: texture = "Entities/Effects/Sprites/SmallSmoke2.png"; break;
	}

	ParticleAnimated(texture, pos, Vec2f(0, 0), 0.0f, 1.0f, 5, gravity, true);
}

CParticle@ MakeFireLightParticle(CBlob@ blob)
{
	Random r;

	CParticle@ p = ParticleAnimated(
		"light.png",
		blob.getPosition() + getRandomVelocity(0, blob.getRadius(), 360.0f),
		Vec2f(0.0f, -0.8f) + Vec2f(blob.getVelocity().x * 0.8f, blob.getVelocity().y * 0.8f) + getRandomVelocity(0, 0.1f, 360.0f),
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