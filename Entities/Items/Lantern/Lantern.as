// Lantern script

void onInit(CBlob@ this)
{
	this.SetLight(true);
	this.SetLightRadius(64.0f);
	this.addCommandID("light on");
	this.addCommandID("light off");
	AddIconToken("$lantern on$", "Lantern.png", Vec2f(8, 8), 0);
	AddIconToken("$lantern off$", "Lantern.png", Vec2f(8, 8), 3);

	this.Tag("dont deactivate");
	this.Tag("fire source");
	this.Tag("ignore_arrow");
	this.Tag("ignore fall");
}

void onRender(CSprite@ sprite)
{
	CSpriteLayer@ lightLayer = sprite.getOrCreateLightLayer();
	LightParams@ params = lightLayer.getLightParams();
	params.castsShadow = true;
	params.castBoxOrigin = sprite.getBlob().getInterpolatedPosition();
	params.castBoxWidth = sprite.getBlob().getLightRadius() * 2 - 8; // workaround needed for now..
	this.getCurrentScript().runFlags |= Script::tick_inwater;
}

void onTick(CBlob@ this)
{
	if (this.isLight() && this.isInWater())
	{
		Light(this, false);
	}

	this.SetLightColor(SColor(255, 255, 210 + XORRandom(10), 120));
}

void Light(CBlob@ this, bool on)
{
	if (!on)
	{
		this.SetLight(false);
		this.getSprite().SetAnimation("nofire");
	}
	else
	{
		this.SetLight(true);
		this.getSprite().SetAnimation("fire");
	}
	this.getSprite().PlaySound("SparkleShort.ogg");
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("activate"))
	{
		if (this.isInWater()) return;
		
		Light(this, !this.isLight());
	}

}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
    return blob.getShape().isStatic();
}
