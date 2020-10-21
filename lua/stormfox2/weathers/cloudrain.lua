-- Rain and cloud is nearly the same.
local cloudy = StormFox.Weather.Add( "Cloud" )
local rain = StormFox.Weather.Add( "Rain", "Cloud" )

-- Cloud icon
do
	-- Icon
	local m_def = Material("stormfox2/hud/w_cloudy.png")
	local m_night = Material("stormfox2/hud/w_cloudy_night.png")
	local m_windy = Material("stormfox2/hud/w_cloudy_windy.png")
	local m_thunder = Material("stormfox2/hud/w_cloudy_thunder.png")
	function cloudy.GetSymbol( nTime ) -- What the menu should show
		return m_def
	end
	function cloudy.GetIcon( nTime, nTemp, nWind, bThunder, nFraction) -- What symbol the weather should show
		local b_day = StormFox.Time.IsDay(nTime)
		local b_cold = nTemp < -2
		local b_windy = StormFox.Wind.GetBeaufort(nWind) >= 3
		local b_H = nFraction > 0.5
		if bThunder then
			return m_thunder
		elseif b_windy then
			return m_windy
		elseif b_H or b_day then
			return m_def
		else
			return m_night
		end
	end
end

-- Rain icon
do
	-- Icon
	local m_def = Material("stormfox2/hud/w_raining.png")
	local m_thunder = Material("stormfox2/hud/w_raining_thunder.png")
	local m_windy = Material("stormfox2/hud/w_raining_windy.png")
	local m_snow = Material("stormfox2/hud/w_snowing.png")
	local m_sleet = Material("stormfox2/hud/w_sleet.png")
	function rain.GetSymbol( nTime, nTemp ) -- What the menu should show
		if nTemp < -4 then
			return m_snow
		end
		return m_def
	end
	function rain.GetIcon( _, nTemp, nWind, bThunder, nFraction) -- What symbol the weather should show
		local b_windy = StormFox.Wind.GetBeaufort(nWind) >= 3
		if bThunder then
			return m_thunder
		elseif b_windy and nTemp > -4 then
			return m_windy
		elseif nTemp > 0 then
			return m_def
		elseif nTemp <= -4 then
			return m_snow
		else
			return m_sleet
		end
	end
	function rain.LogicRelay()
		if StormFox.Temperature.Get() < -1 then
			return "snow"
		end
		return "rain"
	end
end

-- Sky and default weather variables
do
	-- Day
		cloudy:SetSunStamp("topColor",Color(3.0, 2.9, 3.5),		SF_SKY_DAY)
		cloudy:SetSunStamp("bottomColor",Color(42.9 * .5,44.4 * .5,45.6 * .5),	SF_SKY_DAY)
		cloudy:SetSunStamp("duskColor",Color(3, 2.9, 3.5),		SF_SKY_DAY)
		cloudy:SetSunStamp("duskScale",1,						SF_SKY_DAY)
		cloudy:SetSunStamp("HDRScale",0.33,						SF_SKY_DAY)
	-- Night
		cloudy:SetSunStamp("topColor",Color(0.4, 0.2, 0.54),	SF_SKY_NIGHT)
		cloudy:SetSunStamp("bottomColor",Color(2.25, 2.25,2.25),SF_SKY_NIGHT)
		--cloudy:SetSunStamp("bottomColor",Color(14.3* 0.5,14.8* 0.5,15.2* 0.5),	SF_SKY_NIGHT)
		cloudy:SetSunStamp("duskColor",Color(.4, .2, .54),		SF_SKY_NIGHT)
		cloudy:SetSunStamp("duskScale",0,						SF_SKY_NIGHT)
		cloudy:SetSunStamp("HDRScale",0.1,						SF_SKY_NIGHT)
	-- Sunset/rise
		cloudy:SetSunStamp("duskScale",0.26,	SF_SKY_SUNSET)
		cloudy:SetSunStamp("duskScale",0.26,	SF_SKY_SUNRISE)

	cloudy:Set("starFade",0)
	cloudy:Set("mapDayLight",0.25)
	cloudy:Set("skyVisibility",0)
	cloudy:Set("clouds",1)
	cloudy:Set("enableThunder",  true)

	rain:Set("mapDayLight",0)
	rain:Set("gauge",10)
	rain:SetSunStamp("fogEnd",1500,SF_SKY_DAY)
	rain:SetSunStamp("fogEnd",1500,SF_SKY_SUNRISE)
	rain:SetSunStamp("fogEnd",2000,SF_SKY_NIGHT)
	rain:SetSunStamp("fogEnd",2000,SF_SKY_BLUE_HOUR)
	rain:Set("fogDensity",1,SF_SKY_BLUE_HOUR)
	rain:Set("fogStart",0)
end
-- Window render
do
	local raindrops = {}
	local raindrops_mat = {(Material("stormfox2/effects/window/raindrop_normal")),(Material("stormfox2/effects/window/raindrop_normal2")),(Material("stormfox2/effects/window/raindrop_normal3"))}
	local s = 2
	local function RenderRain(w, h)
		if StormFox.Temperature.Get() < -1 then return false end
		local QT = StormFox.Client.GetQualityNumber()
		local P = StormFox.Weather.GetProcent()
		-- Base
		surface.SetMaterial(Material("stormfox2/effects/window/rain_normal"))
		local c = (-SysTime() / 1000) % 1
		surface.SetDrawColor(Color(255,255,255,255 * P))
		surface.DrawTexturedRectUV(0,0, w, h, 0, c, s, c + s )
		-- Create raindrop
		if #raindrops < math.Clamp(QT * 10, 5 ,65 * P) and math.random(100) <= 90 then
			local s = math.random(6,10)
			local x,y = math.random(s, w - s * 2), math.random(s, h * 0.8)
			local sp = math.random(10, 50)
			local lif = CurTime() + math.random(3,5)
			local m = table.Random(raindrops_mat)
			table.insert(raindrops, {x,y,s,m,sp,lif})
		end
		-- Render raindrop
		local r = {}
		for i,v in ipairs(raindrops) do
			local lif = (v[6] - CurTime()) * 10
			local a_n = h - v[2] - v[3]
			local a = math.min(25.5,math.min(a_n,lif)) * 10
			if a > 0 then
				surface.SetMaterial(v[4])
				surface.SetDrawColor(Color(255,255,255,a))
				surface.DrawTexturedRect(v[1],v[2],v[3],v[3])
				v[2] = v[2] + FrameTime() * v[5]
			else
				table.insert(r, i)
			end
		end
		-- Remove raindrop
		for i = #r,1,-1 do
			table.remove(raindrops, r[i])
		end
	end
	rain:RenderWindowRefract64x64(RenderRain)
end
-- Snow Terrain and footsteps
do
	local snow = StormFox.Terrain.Create("snow")
	local rain_t = StormFox.Terrain.Create("rain")
	-- Make the snow terrain apply, if temp is low
	rain:SetTerrain( function() 
		if SERVER then
			StormFox.Map.w_CallLogicRelay(rain.LogicRelay())
		end
		return StormFox.Temperature.Get() < -1 and snow or rain_t
	end)

	-- Make the snow stay, until temp is high.
	snow:LockUntil(function()
		return StormFox.Temperature.Get() > -2
	end)

	-- Snow window
	local mat = Material("stormfox2/effects/window/snow")
	local function RenderSnow(w, h)
		if StormFox.Temperature.Get() > -2 then return false end
		local P = 1 - StormFox.Weather.GetProcent()
		surface.SetMaterial(mat)
		local lum = math.max(math.min(25 + StormFox.Weather.GetLuminance(), 255),70)
		surface.SetDrawColor(Color(lum,lum,lum))
		surface.DrawTexturedRect(0,h * 0.12 * P,w,h)
	end
	snow:RenderWindow( RenderSnow )
	-- Footprints
	snow:MakeFootprints({
		"stormfox/footstep/footstep_snow0.ogg",
		"stormfox/footstep/footstep_snow1.ogg",
		"stormfox/footstep/footstep_snow2.ogg",
		"stormfox/footstep/footstep_snow3.ogg",
		"stormfox/footstep/footstep_snow4.ogg",
		"stormfox/footstep/footstep_snow5.ogg",
		"stormfox/footstep/footstep_snow6.ogg",
		"stormfox/footstep/footstep_snow7.ogg",
		"stormfox/footstep/footstep_snow8.ogg",
		"stormfox/footstep/footstep_snow9.ogg"
	},"snow.step")

	snow:SetGroundTexture("nature/snowfloor001a")
	snow:AddTextureSwap("models/buggy/buggy001","stormfox2/textures/buggy001-snow")
	snow:AddTextureSwap("models/vehicle/musclecar_col","stormfox2/textures/musclecar_col-snow")

	-- Other snow textures
	-- DOD
	if IsMounted("dod") then
		snow:AddTextureSwap("models/props_foliage/hedge_128",			"models/props_foliage/hedgesnow_128")
		snow:AddTextureSwap("models/props_fortifications/hedgehog",		"models/props_fortifications/hedgehog_snow")
		snow:AddTextureSwap("models/props_fortifications/sandbags",		"models/props_fortifications/sandbags_snow")
		snow:AddTextureSwap("models/props_fortifications/dragonsteeth",	"models/props_fortifications/dragonsteeth_snow")
		snow:AddTextureSwap("models/props_normandy/logpile",				"models/props_normandy/logpile_snow")
		snow:AddTextureSwap("models/props_urban/light_fixture01",		"models/props_urban/light_fixture01_snow")
		snow:AddTextureSwap("models/props_urban/light_streetlight01",	"models/props_urban/light_streetlight01_snow")
		snow:AddTextureSwap("models/props_urban/light_fixture01_on",		"models/props_urban/light_fixture01_snow_on")
		snow:AddTextureSwap("models/props_urban/light_streetlight01_on",	"models/props_urban/light_streetlight01_snow_on")
	end
	-- TF2
	if IsMounted("tf") then
		snow:AddTextureSwap("models/props_foliage/shrub_03","models/props_foliage/shrub_03_snow")
		snow:AddTextureSwap("models/props_swamp/shrub_03","models/props_foliage/shrub_03_snow")
		snow:AddTextureSwap("models/props_foliage/shrub_03_skin2","models/props_foliage/shrub_03_snow")

		snow:AddTextureSwap("models/props_foliage/grass_02","models/props_foliage/grass_02_snow")
		snow:AddTextureSwap("models/props_foliage/grass_02_dark","models/props_foliage/grass_02_snow")
		snow:AddTextureSwap("nature/blendgrassground001","nature/blendgrasstosnow001")
		snow:AddTextureSwap("nature/blendgrassground002","nature/blendgrasstosnow001")
		snow:AddTextureSwap("nature/blendgrassground007","nature/blendgrasstosnow001")
		snow:AddTextureSwap("detail/detailsprites_2fort","detail/detailsprites_viaduct_event")
		snow:AddTextureSwap("detail/detailsprites_dustbowl","detail/detailsprites_viaduct_event")
		snow:AddTextureSwap("detail/detailsprites_trainyard","detail/detailsprites_viaduct_event")
		snow:AddTextureSwap("models/props_farm/tree_leaves001","models/props_farm/tree_branches001")
		snow:AddTextureSwap("models/props_foliage/tree_pine01","models/props_foliage/tree_pine01_snow")
		for _,v in ipairs({"02","05","06","09","10","10a"}) do
			snow:AddTextureSwap("models/props_forest/cliff_wall_" .. v,"models/props_forest/cliff_wall_" .. v .. "_snow")
		end
		snow:AddTextureSwap("models/props_island/island_tree_leaves02","models/props_island/island_tree_roots01")
		snow:AddTextureSwap("models/props_forest/train_stop","models/props_forest/train_stop_snow")
	end
end

-- Rain particles
--[[
		local amo = StormFox.Weather.GetProcent()
		local view = StormFox.util.GetCalcView()]]
if CLIENT then
	-- Create rainparticle
	local m_rain = Material("stormfox/raindrop.png") -- Material("vgui/3735626027.png") or 
	local m_rain_multi = Material("stormfox/raindrop-multi.png","noclamp smooth")
	local m_snow1 = Material("stormfox/effects/snowflake1.png")
	local m_snow2 = Material("stormfox/effects/snowflake2.png")
	local m_snow3 = Material("stormfox/effects/snowflake3.png")
	local t_snow = {m_snow1, m_snow2, m_snow3}
	local m_snowmulti = Material("stormfox/effects/snow-multi.png")

	local rain_template = StormFox.DownFall.CreateTemplate(m_rain, true)
	local rain_template_multi = StormFox.DownFall.CreateTemplate(m_rain_multi, true)
	local snow_template = StormFox.DownFall.CreateTemplate(m_snow1, false)
	local snow_template_multi = StormFox.DownFall.CreateTemplate(m_rain_multi, true)
	
	-- Rain splash
	local rainsplash_w = Material("effects/splashwake3")
	local rainsplash = Material("effects/splash4")
	function rain_template:OnHit( vPos, vNormal, nHitType )
		
		if math.random(3) > 1 then return end -- 33% chance to spawn a splash
		if nHitType == SF_DOWNFALL_HIT_WATER then
			local p = StormFox.DownFall.AddParticle( rainsplash_w, vPos, true )
			p:SetAngles(vNormal:Angle())
			p:SetStartSize(8)
			p:SetEndSize(40)
			p:SetDieTime(1)
			p:SetEndAlpha(0)
			p:SetStartAlpha(5 + math.random(7,10))
		elseif nHitType == SF_DOWNFALL_HIT_GROUND then
			local p = StormFox.DownFall.AddParticle( rainsplash, vPos, false )
			p:SetAngles(vNormal:Angle())
			p:SetStartSize(4)
			p:SetEndSize(5)
			p:SetDieTime(0.2)
			p:SetEndAlpha(0)
			p:SetStartAlpha(10)
		elseif nHitType == SF_DOWNFALL_HIT_GLASS then
			local p = StormFox.DownFall.AddParticle( rainsplash, vPos, false )
			p:SetAngles(vNormal:Angle())
			p:SetStartSize(4)
			p:SetEndSize(5)
			p:SetDieTime(0.2)
			p:SetEndAlpha(0)
			p:SetStartAlpha(10)
		--	local p = StormFox.DownFall.AddParticle( rainsplash, vPos, false )
		--	p:SetAngles(-vNormal:Angle())
		--	p:SetStartSize(8)
		--	p:SetEndSize(10)
		--	p:SetDieTime(0.2)
		--	p:SetEndAlpha(0)
		--	p:SetStartAlpha(10)
		end
	end
	-- Make the distant rain start higer up.
	rain_template_multi:SetRenderHeight( 400 )
	-- Update the rain templates every 10th second
	function rain.Tick10()
		local P = StormFox.Weather.GetProcent()
		-- local L = StormFox.Weather.GetLuminance() TODO: Fiddle with settings
		-- Update rain
		local s = 1.22 + 1.56 * P
		rain_template:SetSpeed( s * 0.8 ) 
		rain_template:SetSize( s , 3.22 + 3.56 * P)
		rain_template:SetAlpha(45 + 15 * P)
		if P > 0.15 then
			rain_template_multi:SetSpeed( s ) 
			rain_template_multi:SetSize( 40 + 50 * P, 400 + 50 * P )
			rain_template_multi:SetAlpha(15 + 4 * P)
		end
	end

	-- Gets called every tick to add rain.
	function rain.Think()
		local P = StormFox.Weather.GetProcent()
		if true or StormFox.Temperature.Get() > math.random(-3, 0) then -- Spawn rain particles
			-- Spawn rain particles
			StormFox.DownFall.SmartTemplate( rain_template, math.random(10,500), 5, vNorm )
			-- Spawn distant rain
			if P > 0.15 and math.random(1,4) > 3 then
				local r_part_multi = StormFox.DownFall.SmartTemplate( rain_template_multi, math.random(500,700), 50, vNorm )
				if r_part_multi then
					r_part_multi:SetSize( 80 + 50 * P , 40 + 50 * P )
				end
			end
		else -- Spawn snow particles
			if P > 0.15 and StormFox.DownFall.CanAddTemplate( snow_template_multi ) then
				StormFox.DownFall.AddTemplate( snow_template_multi, math.random(600,800), 20, vNorm )
			end
			if StormFox.DownFall.CanAddTemplate( snow_template ) then
				local part = StormFox.DownFall.AddTemplate( snow_template, math.random(10,700), 5, vNorm )
				part:SetMaterial( table.Random(t_snow) )
			end
		end
	end

	function rain.HUDPaint()
		surface.SetDrawColor(color_white)
		surface.DrawRect(40,40,200,100)
		surface.SetTextColor(0,0,0)
		surface.SetTextPos(50, 50)
		surface.SetFont("default")
		surface.DrawText("Q: " .. StormFox.Client.GetQualityNumber())
		surface.SetTextPos(50, 70)
		surface.DrawText("Amount: " .. #StormFox.DownFall.DebugList())

		local rT = StormFox.DownFall.CalcTemplateTimer( rain_template )
		surface.SetTextPos(50, 90)
		surface.DrawText("SpawnTime: " .. rT)
		local rTM = StormFox.DownFall.CalcTemplateTimer( rain_template_multi )
		surface.SetTextPos(50, 120)
		surface.DrawText("SpawnTime(Dist): " .. rTM)
	end
end

-- 		if LocalPlayer():WaterLevel() >= 3 then return end -- Don't render under wanter.
--[[
local downfall_rain = StormFox.DownFall.Create("rain")
local downfall_snow = StormFox.DownFall.Create("snow")
do
	
	local rainsplash_w = Material("effects/splashwake3")
	local rainsplash = Material("effects/splash4")
	local ODPR = function( pos, normal, hit_type, CLuaEmitter, CLuaEmitter2D )
		if math.random(3) > 1 then return end
		if hit_type == 1 then -- Water
			local p = CLuaEmitter:Add(rainsplash_w,pos)
			p:SetAngles(normal:Angle())
			p:SetStartSize(8)
			p:SetEndSize(40)
			p:SetDieTime(1)
			p:SetEndAlpha(0)
			p:SetStartAlpha(math.random(7,10))
		else -- Ground / Glass
			local p = CLuaEmitter:Add(rainsplash,pos)
			p:SetAngles(normal:Angle())
			p:SetStartSize(4)
			p:SetEndSize(5)
			p:SetDieTime(0.2)
			p:SetEndAlpha(0)
			p:SetStartAlpha(10)
			if hit_type == 2 then
				local p = CLuaEmitter:Add(rainsplash,pos)
				p:SetAngles(-normal:Angle())
				p:SetStartSize(8)
				p:SetEndSize(10)
				p:SetDieTime(0.2)
				p:SetEndAlpha(0)
				p:SetStartAlpha(10)
			end
		end
	end
	downfall_rain:SetParticlesPrGauge( 14 )

	-- Close rain
	local part = StormFox.DownFall.CreateParticle("rain")
		part:SetAmountPrCykle(60)
		part:SetMateiral(Material("stormfox/raindrop.png"))
		part:SetWeight(1.22 * 100,1.56 * 100)
		part:SetMaxDistance(700)
		part:SetMinDistance(20)
		part:SetWidth(1.22,1.56)
		part:SetHeight(3.22,3.56)
		part:SetAlpha(45, 15)
		part:OnDeathParticle( ODPR )
		local function ExpPart(vPos, vExpoison, nRange, nForce, CLuaemitter2D)
			local a_dis = vPos:Distance(vExpoison)
			local e_dis = nRange - a_dis
			local e_ang = (vPos - vExpoison):Angle():Forward()
			local boost = e_dis * 5
			local p = CLuaemitter2D:Add("effects/splash1",vExpoison + e_ang * math.max(nRange / 2, a_dis))
				p:SetStartSize(math.random(32, 20))
				p:SetEndSize(5)
				p:SetDieTime(2.5)
				p:SetEndAlpha(0)
				p:SetStartAlpha(6)
				p:SetGravity( physenv.GetGravity() * 2 )
				p:SetVelocity( e_ang * nForce *  boost)
				p:SetAirResistance(3)
				p:SetCollide(true)
				p:SetRoll(math.random(360))
				p:SetCollideCallback(function( part )
					part:SetDieTime(0)
				end)
		end
		part:OnExplosion(function(vPos, vExpoison, nRange, nForce, CLuaemitter, CLuaemitter2D)
			ExpPart(vPos, vExpoison, nRange, nForce, CLuaemitter2D)
			-- Make a few more
			for i = 1,(2 + StormFox.Client.GetQualityNumber() / 3) do
				local fPos = vExpoison
					fPos[1] = fPos[1] + math.random(-nForce,nForce)
					fPos[2] = fPos[2] + math.random(-nForce,nForce)
					fPos[3] = fPos[3] + math.random(-nForce,nForce)
				ExpPart(fPos, vExpoison, nRange, nForce, CLuaemitter2D)
			end
		end)
	-- Distant rain
	local part = StormFox.DownFall.CreateParticle("rain")
		part:SetAmountPrCykle(16)
		part:SetMateiral(Material("stormfox/raindrop-multi.png","noclamp smooth"))
		part:SetWeight(1.22 * 100,1.56 * 100)
		part:SetMaxDistance(400)
		part:SetMinDistance(1200)
		part:SetWidth(10,20)
		part:SetHeight(10,20)
		part:SetAlpha(75, 10)
		part:OnDeathParticle( ODPR )
	-- Cloudy rain
	local part = StormFox.DownFall.CreateParticle("rain")
		part:SetAmountPrCykle(1)
		part:SetMaxAmount(10)
		part:SetMateiral(Material("particle/smokesprites_0003"))
		part:SetWeight(3.22 * 70,1.56 * 2)
		part:SetMaxDistance(1000)
		part:SetMinDistance(1200)
		part:SetWidth(400,80)
		part:SetHeight(100,40)
		part:SetAlpha(5, 7)
		part:SetNoBeam(true)
		part:SetFadeOut(true)
		part:SetRenderHeight(400)

	-- Create snow particles
	
	for i = 1,1 do
		local part = StormFox.DownFall.CreateParticle("snow")
			part:SetAmountPrCykle(30)
			part:SetMateiral(Material("stormfox/snowflake" .. i .. ".png"))
			part:SetWeight(1.22 * 10,1.56 * 10)
			part:SetMaxDistance(700)
			part:SetMinDistance(20)
			part:SetWidth(.62,.36)
			part:SetHeight(.62,.36)
			part:SetAlpha(45, 15)
			part:SetNoBeam(true)
	end
	local part = StormFox.DownFall.CreateParticle("snow")
		part:SetAmountPrCykle(5)
		part:SetMateiral(Material("stormfox/snow-multi.png"))
		part:SetWeight(1.22 * 40,1.56 * 10)
		part:SetMaxDistance(600)
		part:SetMinDistance(400)
		part:SetWidth(150,10)
		part:SetHeight(150,10)
		part:SetAlpha(255)
		part:SetFadeOut(true)
		part:SetRenderHeight(200)
end

rain:SetDownFall(downfall_rain,function()
	return StormFox.Data.Get( "Temp", 20 ) < math.random(0,4) and downfall_snow or downfall_rain
end)]]