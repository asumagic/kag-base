/*
 * convertible if enemy outnumbers friends in radius
 */

const string counter_prop = "capture ticks";
const string raid_tag = "under raid";
const int capture_half_seconds = 30;
const int short_capture_half_seconds = 10;
const int capture_radius = 80;

const string friendly_prop = "capture friendly count";
const string enemy_prop = "capture enemy count";

const string short_raid_tag = "short raid time";

void onInit(CBlob@ this)
{
	this.getCurrentScript().tickFrequency = 15;
	this.getCurrentScript().runFlags |= Script::tick_not_attached;
	
	if (isServer())
	{
		ResetProperties(this);
		SyncProperties(this);
	}
}

void ResetProperties(CBlob@ this)
{
	this.set_u16(friendly_prop, 0);
	this.set_u16(enemy_prop, 0);
	this.set_u16(counter_prop, GetCaptureTime(this));
	this.Untag(raid_tag);
}

void SyncProperties(CBlob@ this)
{
	this.Sync(friendly_prop, true);
	this.Sync(enemy_prop, true);
	this.Sync(counter_prop, true);
	this.Sync(raid_tag, true);
}

int GetCaptureTime(CBlob@ blob)
{
	if (blob.hasTag(short_raid_tag))
	{
		return short_capture_half_seconds;
	}
	return capture_half_seconds;
}

void onAttach(CBlob@ this, CBlob@ attached, AttachmentPoint @attachedPoint)
{
	if (!isServer()) return;

	if (this.isAttached() && this.hasTag(raid_tag))
	{
		ResetProperties(this);
		SyncProperties(this);
	}

	if (this.hasTag("convert on sit") && 
			attachedPoint.socket &&
	        attached.getTeamNum() != this.getTeamNum() &&
	        attached.hasTag("player"))
	{
		this.server_setTeamNum(attached.getTeamNum());
	}
}

void onTick(CBlob@ this)
{
	if (!isServer()) return;

	u16 attackersCount = 0;
	u16 friendlyCount = 0;
	u8 attackerTeam = 255;

	CBlob@[] blobsInRadius;
	if (getMap().getBlobsInRadius(this.getPosition(), capture_radius, @blobsInRadius))
	{
		// count friendlies and enemies
		for (uint i = 0; i < blobsInRadius.length; i++)
		{
			CBlob@ b = blobsInRadius[i];
			if (b !is this && b.hasTag("player") && !b.hasTag("dead"))
			{
				if (b.getTeamNum() != this.getTeamNum())
				{
					Vec2f bpos = b.getPosition();
					if (bpos.x > pos.x - this.getWidth() / 1.0f && bpos.x < pos.x + this.getWidth() / 1.0f &&
					        bpos.y < pos.y + this.getHeight() / 1.0f && bpos.y > pos.y - this.getHeight() / 1.0f)
					{
						attackersCount++;
						attackerTeam = b.getTeamNum();
					}
				}
				else
				{
					friendlyCount++;
				}
			}
		}
	}

	int ticks = this.get_u16(counter_prop);

	if (attackersCount > 0 || this.hasTag(raid_tag))
	{
		//convert
		if (attackersCount > friendlyCount)
		{
			ticks--;
		}
		//un-convert gradually
		else if (attackersCount < friendlyCount || attackersCount == 0)
		{
			ticks = Maths::Min(ticks + 1, GetCaptureTime(this));
		}

		this.set_u16(counter_prop, ticks);
		this.Tag(raid_tag);

		if (ticks <= 0)
		{
			this.server_setTeamNum(attackerTeam);
			ResetProperties(this);
		}
		else
		{
			this.set_u16(friendly_prop, friendlyCount);
			this.set_u16(enemy_prop, attackersCount);
			
			if (attackersCount == 0 && ticks >= GetCaptureTime(this))
			{
				this.Untag(raid_tag);
			}
		}

		SyncProperties(this);
	}
}

void onChangeTeam(CBlob@ this, const int oldTeam)
{
	ConvertPoints(this, "VEHICLE,BOW,DOOR");

	if (this.getTeamNum() < 10)
	{
		CSprite@ sprite = this.getSprite();
		if (sprite !is null)
		{
			sprite.PlaySound("/VehicleCapture");
		}
	}
}

void ConvertPoints(CBlob@ this, const string pointNames)
{
	if (!isServer()) return;

	AttachmentPoint@[] aps;
	if (!this.getAttachmentPoints(@aps)) return;

	for (u8 i = 0; i < aps.length; i++)
	{
		AttachmentPoint@ point = aps[i];
		CBlob@ blob = point.getOccupied();
		if (blob is null) continue;
		
		if (pointNames.find(point.name) == -1) continue;
		
		blob.server_setTeamNum(this.getTeamNum());
	}
}

// alert and capture progress bar

void onRender(CSprite@ this)
{
	if (g_videorecording)
		return;

	CBlob@ blob = this.getBlob();
	CCamera@ camera = getCamera();
	if (blob is null || !blob.hasTag(raid_tag))
		return;

	Vec2f pos2d = getDriver().getScreenPosFromWorldPos(blob.getPosition());

	const u16 friendlyCount = blob.get_u16(friendly_prop);
	const u16 enemyCount = blob.get_u16(enemy_prop);
	const f32 captureTime = blob.get_u16(counter_prop);

	const f32 hwidth = 45 + Maths::Max(0, Maths::Max(friendlyCount, enemyCount) - 3) * 8;
	const f32 hheight = 30;

	if (camera.targetDistance > 0.9) 			//draw bigger capture bar if zoomed in
	{
		pos2d.y -= 40;
	 	const f32 padding = 4.0f;
	 	const f32 shift = 29.0f;
	 	const f32 progress = (1.1f - captureTime / float(GetCaptureTime(blob)))*(hwidth*2-13); //13 is a magic number used to perfectly align progress
	 	GUI::DrawPane(Vec2f(pos2d.x - hwidth + padding, pos2d.y + hheight - shift - padding),
	 		      Vec2f(pos2d.x + hwidth - padding, pos2d.y + hheight - padding),
			      SColor(175,200,207,197)); 				//draw capture bar background
		if (progress >= float(8)) 					//draw progress if capture can start
		{
	 		GUI::DrawPane(Vec2f(pos2d.x - hwidth + padding, pos2d.y + hheight - shift - padding),
			      	      Vec2f((pos2d.x - hwidth + padding) + progress, pos2d.y + hheight - padding),
				      SColor(175,200,207,197));
		}
		//draw balance of power
		for (int i = 1; i <= friendlyCount; i++)
	 		GUI::DrawIcon("VehicleConvertIcon.png", 0, Vec2f(8, 16), pos2d + Vec2f(i * 8 - 8, -4), 0.9f, blob.getTeamNum());
	 	for (int i = 1; i <= enemyCount; i++)
	 		GUI::DrawIcon("VehicleConvertIcon.png", 1, Vec2f(8, 16), pos2d + Vec2f(i * -8 - 8, -4), 0.9f);
	}
	else
	{
		//draw smaller capture bar if zoom is farthest
		pos2d.y -= 37;
		const f32 padding = 2.0f;
 		GUI::DrawProgressBar(Vec2f(pos2d.x - hwidth * 0.5f, pos2d.y + hheight - 14 - padding),
 	                      	     Vec2f(pos2d.x + hwidth * 0.5f, pos2d.y + hheight - padding),
 	                      	     1.0f - captureTime / float(GetCaptureTime(blob)));
	}
}
