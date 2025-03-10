AddCSLuaFile()
include("voices.lua")
ENT.Base 			= "npc_iv04_base"
ENT.StartHealth = 5
ENT.Models  = {"models/halo_reach/characters/other/flood_infection_form.mdl"}
ENT.Relationship = 4
ENT.MeleeDamage = 5
ENT.WanderAnim = {ACT_RUN}
ENT.SightType = 1
ENT.BehaviourType = 1
ENT.Faction = "FACTION_FLOOD"
--ENT.MeleeSound = { "doom_3/zombie2/zombie_attack1.ogg", "doom_3/zombie2/zombie_attack2.ogg", "doom_3/zombie2/zombie_attack3.ogg" }
ENT.MoveSpeed = 200
ENT.MoveSpeedMultiplier = 1 -- When running, the move speed will be x times faster
ENT.PrintName = "Flood Infection Form"
ENT.OnMove = { "halo_reach/characters/flood/infection/move/infector sound 10.ogg", "halo_reach/characters/flood/infection/move/infector sound 12.ogg",
			"halo_reach/characters/flood/infection/move/infector sound 14.ogg", "halo_reach/characters/flood/infection/move/infector sound 16.ogg",
			"halo_reach/characters/flood/infection/move/infector sound 18.ogg", "halo_reach/characters/flood/infection/move/infector sound 2.ogg",
			"halo_reach/characters/flood/infection/move/infector sound 21.ogg", "halo_reach/characters/flood/infection/move/infector sound 21.ogg",
			"halo_reach/characters/flood/infection/move/infector sound 25.ogg", "halo_reach/characters/flood/infection/move/infector sound 27.ogg",
			"halo_reach/characters/flood/infection/move/infector sound 29.ogg", "halo_reach/characters/flood/infection/move/infector sound 30.ogg",
			"halo_reach/characters/flood/infection/move/infector sound 5.ogg", "halo_reach/characters/flood/infection/move/infector sound 7.ogg",
			"halo_reach/characters/flood/infection/move/infector sound 9.ogg" }
ENT.MeleeRange = 200

ENT.IdleSoundDelay = 8

ENT.NPSound = 0

ENT.NISound = 0

ENT.VJ_NPC_Class = {"CLASS_HALO_FLOOD","CLASS_FLOOD","CLASS_PARASITE"}

ENT.UseLineOfSight = false

ENT.SearchJustAsSpawned = true

ENT.VJ_EnhancedFlood = true

ENT.LoseEnemyDistance = 15000

ENT.VoiceType = "Flood_Infection"

function ENT:CustomRelationshipsSetUp()
end

function ENT:Wander()
	if self.IsControlled then return end
	if self.IsFollowingPlayer and IsValid(self.FollowingPlayer) then
		local dist = self:GetRangeSquaredTo(self.FollowingPlayer)
		if dist > 300^2 then
			local goal = self.FollowingPlayer:GetPos() + Vector( math.Rand( -1, 1 ), math.Rand( -1, 1 ), 0 ) * 300
			local navs = navmesh.Find(goal,256,100,20)
			local nav = navs[math.random(#navs)]
			local pos = goal
			if nav then pos = nav:GetRandomPoint() end
			self:WanderToPosition( (pos), self.RunAnim[math.random(#self.RunAnim)], self.MoveSpeed*self.MoveSpeedMultiplier )
		else
			for i = 1, 3 do
				timer.Simple( 0.5*i, function()
					if IsValid(self) and !IsValid(self.Enemy) then
						self:SearchEnemy()
					end
				end )
				if !IsValid(self.Enemy) then
					coroutine.wait(0.5)
				end
			end
		end
	else
		if self.Alerted then
			timer.Simple( 15, function()
				if IsValid(self) and !IsValid(self.Enemy) then
					self.Alerted = false
					self.SpokeSearch = false
				end
			end )
			if !self.SpokeSearch then
				self:Speak("OnInvestigate")
				for id, v in ipairs(self:LocalAllies()) do
					if !v.SpokeSearch then
						v.SpokeSearch = true
						v.NeedsToReport = true
					end
				end
			end
			self:WanderToPosition( ((self.LastSeenEnemyPos or self:GetPos()) + Vector( math.Rand( -1, 1 ), math.Rand( -1, 1 ), 0 ) * 200), self.WanderAnim[math.random(1,#self.WanderAnim)], self.MoveSpeed )
			coroutine.wait(1)
		else
			--if self:GetActivity() != self.IdleCalmAnim[1] then
			--	self:StartActivity(self.IdleCalmAnim[1])
			--end
			if  math.random(1,3) == 1 then
				self:WanderToPosition( ((self:GetPos()) + Vector( math.Rand( -1, 1 ), math.Rand( -1, 1 ), 0 ) * 200), self.WanderAnim[math.random(1,#self.WanderAnim)], self.MoveSpeed )
			else
				for i = 1, 3 do
					timer.Simple( 0.5*i, function()
						if IsValid(self) and !IsValid(self.Enemy) then
							self:SearchEnemy()
						end
					end )
					if !IsValid(self.Enemy) then
						coroutine.wait(0.5)
					end
				end
			end
			if !self.SpokeIdle then
				self:Speak("OnIdle")
				self.SpokeIdle = true
				timer.Simple( math.random(45,60), function()
					if IsValid(self) then
						self.SpokeIdle = false
					end
				end )
			end
		end
	end
	--self:WanderToPosition( (self:GetPos() + Vector( math.Rand( -1, 1 ), math.Rand( -1, 1 ), 0 ) * self.WanderDistance), self.WanderAnim[math.random(1,#self.WanderAnim)], self.MoveSpeed )
end

function ENT:Speak(voice)
	local character = self.Voices[self.VoiceType]
	if self.CurrentSound then self.CurrentSound:Stop() end
	if character[voice] and istable(character[voice]) then
		local sound = table.Random(character[voice])
		self.CurrentSound = CreateSound(self,sound)
		self.CurrentSound:SetSoundLevel(100)
		self.CurrentSound:Play()
	end
end


function ENT:OnInitialize()
	if !self.FromCarrier then
		self:SetCollisionBounds(Vector(8,8,15),Vector(-8,-8,0))
		self:SetSolidMask(MASK_NPCSOLID)
	end
	self.DoClimb = GetConVar("halo_reach_nextbots_ai_flood_infection_climb"):GetInt() == 1
	self:SetBloodColor(DONT_BLEED)
end

function ENT:BeforeThink()
	if self.NISound < CurTime() then
		self.NISound = CurTime()+20
		-- self:Speak("OnMove")
		-- self:EmitSound( self.OnMove[math.random(1,#self.OnMove)] )
	end
end

function ENT:OnHaveEnemy(ent)

end

function ENT:OnInjured(dmg)
	local rel = self:CheckRelationships(dmg:GetAttacker())
	if rel == "friend" and !dmg:GetAttacker():IsPlayer() then
		dmg:ScaleDamage(0)
		return 
	end
end

function ENT:FireAnimationEvent(pos,ang,event,name)
	--[[print(pos)
	print(ang)
	print(event)
	print(name)]]
end

function ENT:OnOtherKilled( victim, info )
	if !IsValid(victim) then return end -- Check if the victim is valid
	if self:Health() <= 0 then return end		
	if self.Enemy == victim then
		
		-- On killed enemy
		local found = false
		if !istable(self.temptbl) then self.temptbl = {} end
		for i=1, #self.temptbl do
			local v = self.temptbl[i]
			if istable(v) then
				local ent = v.ent
				if IsValid(ent) then
					if ent:Health() < 1 then
						self.temptbl[v] = nil
						self:SetEnemy(nil)
					end
					if IsValid(ent) and ent != victim then
						found = true
						self:SetEnemy(ent)
						break
					end
				else
					self.temptbl[i] = nil
				end
			end
		end
	end
end

function ENT:HandleAnimEvent(event,eventTime,cycle,type,options)
	--[[print(event)
	print(eventTime)
	print(cycle)
	print(type)
	print(options)]]
	--if options == self.MeleeEvent then
		--self:DoMeleeDamage()
	--end
end

function ENT:DoMeleeDamage()
	local victim = self:GetOwner()
	victim:TakeDamage( self.MeleeDamage, self, self )
	
end

ENT.NextBite = 0

if SERVER then

	function ENT:Think()
		if self.Latched and IsValid(self:GetOwner()) then
			if self.NextBite < CurTime() then
				self:DoMeleeDamage()
				self.NextBite = CurTime()+1
				self:Speak("OnFeed")
			end
			self.DirToEnemy = (self:GetOwner():NearestPoint(self:GetPos())-self:GetPos()):Angle()
			self:SetAngles(Angle(90,self.DirToEnemy.y,0))
			self:SetPos(self.LPos+self:GetOwner():GetPos())
		end
	end

end

function ENT:DoKilled( info )

end

function ENT:Melee(damage) -- This section is really cancerous and a mess, if you want a nice melee I suggest you look at the oddworld stranger's wrath ones
	if self.DoingMelee == true then return end
	if !damage then damage = self.MeleeDamage end
	if IsValid(self.Enemy) then
		for i = 1, 30 do
			self.loco:FaceTowards( self.Enemy:GetPos() )
		end
		self.loco:JumpAcrossGap( self.Enemy:GetPos()+self.Enemy:OBBCenter(), self:GetForward() )
	end
	self.loco:SetDesiredSpeed(0)
	self:ResetSequence( "Leap" )
end

function ENT:OnLeaveGround( ent )
	self.DoingMelee = true
end


function ENT:JumpTo(ent)
	local dir = self:GetAimVector()*200
	self.loco:JumpAcrossGap(self:GetPos()+dir,self:GetForward())
	self:StartActivity( self:GetSequenceActivity(self:LookupSequence("Leap")) )
	local func = function()
		while (!self.loco:IsOnGround() and !IsValid(self:GetOwner())) do
			coroutine.wait(0.01)
		end
	end
	table.insert(self.StuffToRunInCoroutine,func)
	self:ResetAI()
end

function ENT:OnContact( ent )
	if ent == game.GetWorld() then return end
	
	local tbl = {
		HitPos = self:NearestPoint(ent:GetPos()),
		HitEntity = self,
		OurOldVelocity = ent:GetVelocity(),
		DeltaTime = 0,
		TheirOldVelocity = self.loco:GetVelocity(),
		HitNormal = self:NearestPoint(ent:GetPos()):GetNormalized(),
		Speed = ent:GetVelocity().x,
		HitObject = self:GetPhysicsObject(),
		PhysObject = self:GetPhysicsObject()
	}
	if ent.DoDamageCode then
		ent:DoDamageCode(tbl,self:GetPhysicsObject())
	elseif ent.PhysicsCollide then 
		ent:PhysicsCollide(tbl,self:GetPhysicsObject())
	end
	if (ent.IsVJBaseSNPC == true or ent.CPTBase_NPC == true or ent.IsSLVBaseNPC == true or ent:GetNWBool( "bZelusSNPC" ) == true) or (ent:IsNPC() && ent:GetClass() != "npc_bullseye" && ent:Health() > 0 ) or (ent:IsPlayer() and ent:Alive()) or ((ent:IsNextBot()) and ent != self ) then
		if self.DoingMelee and !self.Latched and !self.HasLatched and self:CheckRelationships(ent) == "foe" then
			self.DoingMelee = false
			self.Latched = true
			self.HasLatched = true
			self:SetOwner(ent)
			self.LPos = ent:WorldToLocal(self:GetPos())
			local stop = false
			timer.Simple( 5, function()
				if IsValid(self) then
					stop = true
					self:SetOwner(nil)
					self.LPos = nil
					self.Latched = false
				end
			end )
			local func = function()
				self:Speak("OnLatchBite")
				self:ResetSequence("Wrestle")
				while (self.Latched and IsValid(self.Enemy)) and !stop do
					if self:GetCycle() >= 0.9 then
						self:ResetSequence("Wrestle")
					end
					coroutine.wait(0.01)
				end
				self.Latched = false
				self:SetAngles(Angle(0,self:GetAngles().y,0))
				timer.Simple( 2, function()
					if IsValid(self) then
						self.HasLatched = false
					end
				end )
				self.loco:SetVelocity(self.DirToEnemy:Forward()*-200)
				--self:MoveToPosition(self:GetPos()+self:GetForward()*-300,self.RunAnim[math.random(#self.RunAnim)],self.MoveSpeed)
			end
			table.insert(self.StuffToRunInCoroutine,func)
		else
			local d = self:GetPos()-ent:GetPos()
			self.loco:SetVelocity(d*1)
		end
	end
end

ENT.MeleeCheckDelay = 0.5

function ENT:ComputeAPath(ent,path)
	if !IsValid(ent) then return end
	path:Compute( self, ent:GetPos(), function( area, fromArea, ladder, elevator, length )
	if ( !IsValid( fromArea ) ) then

		-- first area in path, no cost
		return 0
	
	else
	
		if ( !self.loco:IsAreaTraversable( area ) ) then
			-- our locomotor says we can't move here
			return -1
		end

		-- compute distance traveled along path so far
		local dist = 0

		if ( IsValid( ladder ) ) then
			dist = ladder:GetLength()
		elseif ( length > 0 ) then
			-- optimization to avoid recomputing length
			dist = length
		else
			dist = ( area:GetCenter() - fromArea:GetCenter() ):Length()
		end

		local cost = dist + fromArea:GetCostSoFar()
		
		local deltaZ = fromArea:ComputeAdjacentConnectionHeightChange( area )
		if ( !self.DoClimb and deltaZ >= self.loco:GetStepHeight() ) then
			return -1
		end

		return cost
	end
end )
end

ENT.DisDelay = 0.3

ENT.ClimbAbleStuff = {
	["prop_physics"] = true,
	["prop_ragdoll"] = true,
	["worldspawn"] = true
}

function ENT:CanClimb()
	local tr = util.TraceLine( {
		start = self:WorldSpaceCenter()+self:GetUp()*20,
		endpos = self:WorldSpaceCenter()+self:GetUp()*20+self:GetForward()*40,
		filter = function(ent)
			if self.ClimbAbleStuff[ent:GetClass()] then
				return true
			else
				return false
			end
		end
	} )
	if tr.Hit then
		self:SetPos(self:GetPos()+self:GetForward()*(tr.Fraction/40))
	end
	return tr.Hit and (!tr.Entity:IsNextBot() and !tr.Entity:IsPlayer() and !tr.Entity:IsNPC())
end

function ENT:Climb(path)
	self.SavedGravity = self.loco:GetGravity()
	self.loco:SetGravity(0)
	self:SetAngles(self:GetAngles()+Angle(-90,0,0))
	self:SetPos(self:GetPos()+self:GetForward()*20)
	local stop = false
	self:StartActivity(self.RunAnim[math.random(#self.RunAnim)])
	--local dx = true
--	local vel
	--print(path:GetCurrentGoal().distanceFromStart)
	local p = self:GetPos()
	while (!stop) do
		if !self.DTr then
			self.DTr = true
			timer.Simple( 0.3, function()
				if IsValid(self) then
					self.DTr = false
				end
			end )
			local tr = util.TraceLine( {
				start = self:WorldSpaceCenter(),
				endpos = self:WorldSpaceCenter()+self:GetUp()*-40,
				filter = function(ent)
					if self.ClimbAbleStuff[ent:GetClass()] or game.GetWorld() == ent and !ent:IsNextBot() then
						return true
					else
						return false
					end
				end
			} )
			stop = !tr.Hit
		end
		--vel = path:GetCurrentGoal().forward*100 --(self:GetUp()*-10)+(Vector(0,0,1)*self.MoveSpeed)
		--if dx then
			--vel = vel+(self:GetUp()*-100)
		--end
	--	self.loco:SetVelocity(vel)
		--if self.loco:GetVelocity().x < 11 then dx = false end
		self:SetPos(p+Vector(0,0,3))
		p = self:GetPos()
		--print(self.loco:GetVelocity())
		coroutine.wait(0.01)
	end
	self:SetAngles(self:GetAngles()+Angle(90,0,0))
	self:SetPos(self:GetPos()+self:GetForward()*40)
	self.loco:SetGravity(600)
end

function ENT:FootstepSound()
	local character = self.Voices[self.VoiceType]
	if character["OnMove"] and istable(character["OnMove"]) then
		local sound = table.Random(character["OnMove"])
		self:EmitSound(sound,60)
	end
end

function ENT:BodyUpdate()
	local act = self:GetActivity()
	if act == self.RunAnim[1] then
		self:BodyMoveXY()
		
	end
	if !self.loco:GetVelocity():IsZero() and self.loco:IsOnGround() then
	if !self.LMove then
			self.LMove = CurTime()+0.4
		else
			if self.LMove < CurTime() then
				self:FootstepSound()
				self.LMove = CurTime()+0.4
			end
		end
	end
	self:FrameAdvance()
end

function ENT:ChaseEnt(ent) -- Modified MoveToPos to integrate some stuff
	if !self.loco:IsOnGround() then return end
	if !ent:IsOnGround() then return end
	local path = Path( "Follow" )
	path:SetMinLookAheadDistance( self.PathMinLookAheadDistance )
	path:SetGoalTolerance( self.PathGoalTolerance )
	if !IsValid(ent) then return end
	self:ComputeAPath(ent,path)
	local goal
	local dis
	while ( IsValid(ent) and IsValid(path) ) do
		if GetConVar( "ai_disabled" ):GetInt() == 1 then
			self:StartActivity( self.IdleAnim[math.random(1,#self.IdleAnim)] )
			return "Disabled thinking"
		end
		if self.NextMeleeCheck < CurTime() then
			self.NextMeleeCheck = CurTime()+self.MeleeCheckDelay
			if self.loco:GetVelocity():IsZero() and self.loco:IsAttemptingToMove() then
				-- We are stuck, don't bother
				return "Give up"
			end
			local dist = self:GetPos():DistToSqr(ent:GetPos())
			if dist > self.LoseEnemyDistance^2 then 
				self:OnLoseEnemy()
				self:SetEnemy(nil)
				self.State = "Idle"
				return "Lost Enemy"
			end
			if dist < self.MeleeRange^2 and !self.HasLatched then
				return self:Melee(self.MeleeDamage)
			end
			if !self.Jumped then
				self.Jumped = true
				timer.Simple( math.random(5,10), function()
					if IsValid(self) then
						self.Jumped = false
					end
				end )
				if dist > 300^2 then
					return self:JumpTo(ent)
				end
			end
		end
		if self.DoClimb and	!self.DoneDis then
			self.DoneDis = true
			timer.Simple( self.DisDelay, function()
				if IsValid(self) then
					self.DoneDis = false
				end
			end )
			goal = path:GetCurrentGoal().pos
			dis = math.abs(self:GetPos().x-goal.x)+math.abs(self:GetPos().y-goal.y)
			--print(dis,self.loco:GetVelocity().x,path:GetCurrentGoal().type)
			local climb = self:CanClimb()
			--print(climb)
			if climb then
				self:Climb(path)
			end
		end
		if ent:IsPlayer() then
			if GetConVar( "ai_ignoreplayers" ):GetInt() == 1 or !ent:Alive() then	
				self:SetEnemy(nil)
				return "Ignore players on"
			end
		end
		if path:GetAge() > self.RebuildPathTime then
			self:ComputeAPath(ent,path)
			self:OnRebuiltPath()
		end
		path:Update( self )
		if self.loco:IsStuck() then
			self:OnStuck()
			return "Stuck"
		end
		coroutine.yield()
	end
	coroutine.wait(1)
	return "ok"
end

function ENT:OnKilled(dmginfo)
	hook.Call( "OnNPCKilled", GAMEMODE, self, dmginfo:GetAttacker(), dmginfo:GetInflictor() )
	ParticleEffect("iv04_halo_reach_flood_infection_form_gib", self:WorldSpaceCenter(), self:GetAngles(), nil )
	self:Speak("OnDeath")
	self:Remove()
end

list.Set( "NPC", "npc_iv04_hr_flood_infection_form", {
	Name = "Flood Infection Form",
	Class = "npc_iv04_hr_flood_infection_form",
	Category = "Halo Reach Aftermath"
} )