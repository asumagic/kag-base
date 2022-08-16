// Draw a flame sprite layer

#include "FireParticle.as";
#include "FireCommon.as";

void onInit(CSprite@ this)
{
	//init flame layer
	CSpriteLayer@ fire = this.addSpriteLayer("fire_animation_large", "Entities/Effects/Sprites/LargeFire.png", 16, 16, -1, -1);

	if (fire !is null)
	{
		{
			Animation@ anim = fire.addAnimation("bigfire", 3, true);
			anim.AddFrame(1);
			anim.AddFrame(2);
			anim.AddFrame(3);
		}
		{
			Animation@ anim = fire.addAnimation("smallfire", 3, true);
			anim.AddFrame(4);
			anim.AddFrame(5);
			anim.AddFrame(6);
		}
		fire.SetVisible(false);
		fire.SetRelativeZ(10);
	}
	this.getCurrentScript().tickFrequency = 24;
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

CParticle@ MakeFirePixelParticle(CBlob@ blob)
{
	Random r;

	CParticle@ p = ParticlePixel(
		blob.getPosition() + getRandomVelocity(0, blob.getRadius(), 360.0f),
		Vec2f(0.0f, -1.5f) + Vec2f(blob.getVelocity().x * 0.2f, blob.getVelocity().y * 0.2f) + getRandomVelocity(0, 0.1f, 360.0f),
		SColor(255, 255, 50 + XORRandom(120), 0),
		true);

	if (p is null) { return null; }

	p.gravity = Vec2f_zero;
	p.timeout = 40;
	p.deadeffect = -1;
	p.diesonanimate = false;
	p.mass = 1.0f;
	p.collides = true;
	p.fadeout = true;
	p.fadeoutmod = 0.97f;

	return @p;
}

void onTick(CSprite@ this)
{
	this.getCurrentScript().tickFrequency = 24; // opt
	CBlob@ blob = this.getBlob();
	CSpriteLayer@ fire = this.getSpriteLayer("fire_animation_large");
	if (fire !is null)
	{
		//if we're burning
		if (blob.hasTag(burning_tag))
		{
			this.getCurrentScript().tickFrequency = 4;

			fire.SetVisible(true);

			//TODO: draw the fire layer with varying sizes based on var - may need sync spam :/
			//fire.SetAnimation( "bigfire" );
			fire.SetAnimation("smallfire");

			//set the "on fire" animation if it exists (eg wave arms around)
			if (this.getAnimation("on_fire") !is null && !blob.hasTag("dead"))
			{
				this.SetAnimation("on_fire");
			}

			//if (XORRandom(2) == 0)
			{
				MakeFireLightParticle(@blob);
			}

			/*if (XORRandom(3) == 0)
			{
				MakeFirePixelParticle(@blob);
			}*/
		}
		else
		{
			if (fire.isVisible())
			{
				this.PlaySound("/ExtinguishFire.ogg");
			}
			fire.SetVisible(false);
		}
	}
}
