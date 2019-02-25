-------------------------------------------------------------------------

ENT.BoomTime = 1					--Time before turtle goes BOOM!
ENT.Range = 200						--Range before activating
ENT.ExplosionRange = 300			--Range of explosion
ENT.ExplosionDamage = 600			--Damage

-------------------------------------------------------------------------

if SERVER then AddCSLuaFile("shared.lua") end

ENT.Type = "anim"
ENT.Model = Model("models/props/de_tides/vending_turtle.mdl")

AccessorFunc(ENT, "placer", "Placer")

function ENT:Initialize()
   self:SetModel(self.Model)

   self:PhysicsInit(SOLID_VPHYSICS)
   self:SetMoveType(MOVETYPE_VPHYSICS)
   self:SetSolid(SOLID_BBOX)

   local b = 11
   self:SetCollisionBounds(Vector(-b, -b, -b), Vector(b,b,b))

   self:SetCollisionGroup(COLLISION_GROUP_WEAPON)
   if SERVER then
      self:SetMaxHealth(20)

      local phys = self:GetPhysicsObject()
      if IsValid(phys) then
         phys:SetMass(50)
      end

   end
   self:SetHealth(20)

end

ENT.Dying = 0

function ENT:OnTakeDamage(dmginfo)
   self:TakePhysicsDamage(dmginfo)

   self:SetHealth(self:Health() - dmginfo:GetDamage())

   if self:Health() < 0 and self.Dying == 0 then
	self:Explode()
   end
end


function ENT:Explode()
	if not IsValid(self) then return end
	self.Dying = 1
	local pos = self:GetPos()
	local radius = self.ExplosionRange
	local damage = self.ExplosionDamage
	
	util.BlastDamage( self, self:GetPlacer(), pos, radius, damage )
	local effect = EffectData()
		effect:SetStart(pos)
		effect:SetOrigin(pos)
		effect:SetScale(radius)
		effect:SetRadius(radius)
		effect:SetMagnitude(damage)
	util.Effect("Explosion", effect, true, true)
	util.Effect("HelicopterMegaBomb", effect, true, true)
	self:Remove()
	
	local spos = self:GetPos()
	local trs = util.TraceLine({start=spos + Vector(0,0,64), endpos=spos + Vector(0,0,-128), filter=self})
	util.Decal("Scorch", trs.HitPos + trs.HitNormal, trs.HitPos - trs.HitNormal)
end

ENT.Ready = 0
ENT.Warmup = 15
ENT.armed = 0
ENT.armtime = 1

local activatedsound = Sound("weapons/mineturtle/hellomineturtle.wav")

if SERVER then

resource.AddFile("sound/weapons/mineturtle/hellomineturtle.wav")
resource.AddFile("sound/weapons/mineturtle/hello.wav")
resource.AddFile("sound/weapons/mineturtle/click.wav")

end

local active = Sound("weapons/mineturtle/click.wav")
local hello = Sound("weapons/mineturtle/hello.wav")
local boom = Sound("c4.explode")



if SERVER then
   function ENT:Think()	
	local playersnear = 0
	
			for _,ent in ipairs(ents.FindInSphere(self:GetPos(), self.Range)) do
			if (ent:IsPlayer()) then
			local victimpos = ent:GetPos()
			local targetpos = self:GetPos()
			local distance = victimpos:Distance( targetpos )
			local tr = util.TraceLine({
					start = self:GetPos() + Vector(0, 0, 32),
					endpos = ent:GetPos() + Vector(0, 0, 32),
					filter = self
				})
				if (!tr.HitWorld and distance < (self.Range) and !ent:IsGhost() and ent:Alive()) then
					playersnear = playersnear + 1
					end
					if (playersnear == 1 and self.armed > 1) then
						self.Ready = self.Ready + 1
						if self.Ready == 1 then
						sound.Play(hello, self:GetPos(), 100, 100)
						timer.Simple(self.BoomTime, function()
						self:Explode()
						sound.Play(boom, self:GetPos(), 100, 100)
						end)
						end
					end
				
				end
			end
			if playersnear == 0 and self.armed == 0 then
				timer.Simple(0.8, function()
				self.armed = self.armed + 1
				end)
			end
			if self.armed == 1 then
			sound.Play(active, self:GetPos(), 123, 100)
			end
		end
	
   end
   
hook.Add( "PreDrawHalos", "TurtleHalo", function()
  if LocalPlayer():Alive() then
	if LocalPlayer():GetRole() == ROLE_TRAITOR then
	  halo.Add( ents.FindByClass("ttt_mineturtle"), Color( math.random(1,255), math.random(1,255), math.random(1,255) ), 3, 3, 1, true, true )
	end
  end
end )
