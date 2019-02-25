if SERVER then
   AddCSLuaFile( "shared.lua" )
end

if CLIENT then
   SWEP.EquipMenuData = {
      type  = "item_weapon",
      name  = "Mine Turtle",
      desc  = "HELLO!"
   };
SWEP.Icon 					= "vgui/ttt/icon_mine_turtle"
end

SWEP.Base 					= "weapon_tttbase"
SWEP.PrintName				= "Mine Turtle"
SWEP.HoldType				= "slam"
SWEP.Slot					= 6
SWEP.Kind 					= WEAPON_EQUIP
SWEP.CanBuy 				= {ROLE_TRAITOR}
SWEP.WeaponID 				= AMMO_C4
SWEP.LimitedStock 			= true
SWEP.AllowDrop 				= false


SWEP.UseHands				= true
SWEP.ViewModelFlip			= true
SWEP.ViewModelFOV			= 54
SWEP.ViewModel  			= Model("models/weapons/cstrike/c_c4.mdl")
SWEP.WorldModel 			= Model("models/weapons/w_c4.mdl")

SWEP.DrawCrosshair      	= false
SWEP.ViewModelFlip      	= false
SWEP.Primary.ClipSize       = -1
SWEP.Primary.DefaultClip    = -1
SWEP.Primary.Automatic      = true
SWEP.Primary.Ammo       	= "none"
SWEP.Primary.Delay 			= 2.0

SWEP.Secondary.ClipSize     = -1
SWEP.Secondary.DefaultClip  = -1
SWEP.Secondary.Automatic    = true
SWEP.Secondary.Ammo     	= "none"
SWEP.Secondary.Delay 		= 1.0

SWEP.NoSights = true

function SWEP:PrimaryAttack()
   self.Weapon:SetNextPrimaryFire( CurTime() + self.Primary.Delay )
   self:BombDrop()
end
function SWEP:SecondaryAttack()
   self.Weapon:SetNextSecondaryFire( CurTime() + self.Secondary.Delay )
   self:BombStick()
end


function SWEP:BombStick()
   if SERVER then

      local ply = self.Owner
	  
      if not IsValid(ply) then return end

      if self.Planted then return end

      local ignore = {ply, self.Weapon}
      local spos = ply:GetShootPos()
      local epos = spos + ply:GetAimVector() * 80
      local tr = util.TraceLine({start=spos, endpos=epos, filter=ignore, mask=MASK_SOLID})

      if tr.HitWorld then
         local bomb = ents.Create("ttt_mineturtle")
         if IsValid(bomb) then
            bomb:PointAtEntity(ply)

            local tr_ent = util.TraceEntity({start=spos, endpos=epos, filter=ignore, mask=MASK_SOLID}, bomb)

            if tr_ent.HitWorld then

               local ang = tr_ent.HitNormal:Angle()
               ang:RotateAroundAxis(ang:Right(), -90)
               ang:RotateAroundAxis(ang:Up(), 180)

               bomb:SetPos(tr_ent.HitPos)
               bomb:SetAngles(ang)
               bomb:SetPlacer(ply)
               bomb:Spawn()
               
               local phys = bomb:GetPhysicsObject()
               if IsValid(phys) then
                  phys:EnableMotion(false)
               end

               bomb.IsOnWall = true

               self:Remove()
				 	ply:EmitSound("weapons/mineturtle/hellomineturtle.wav", 50)
               self.Planted = true
			   
            end
         end

		ply:SetAnimation( PLAYER_ATTACK1 )    
      end

   end

end

local throwsound = Sound( "weapons/mineturtle/hellomineturtle.wav" )

function SWEP:BombDrop()
   if SERVER then

      local ply = self.Owner
      if not IsValid(ply) then return end

      if self.Planted then return end

      local vsrc = ply:GetShootPos()
      local vang = ply:GetAimVector()
      local vvel = ply:GetVelocity()

      local vthrow = vvel + vang * 200

      local bomb = ents.Create("ttt_mineturtle")
      if IsValid(bomb) then
         bomb:SetPos(vsrc + vang * 10)
         bomb:SetOwner(ply)
         bomb:SetPlacer(ply)
         bomb:Spawn()

         bomb:PointAtEntity(ply)

         local ang = bomb:GetAngles()
         ang:RotateAroundAxis(ang:Up(), 180)
         bomb:SetAngles(ang)

         bomb:PhysWake()
         local phys = bomb:GetPhysicsObject()
         if IsValid(phys) then
            phys:SetVelocity(vthrow)
         end
         self:Remove()

         self.Planted = true
      end

      ply:SetAnimation( PLAYER_ATTACK1 )

   end

   self:EmitSound(throwsound, 50)
end

if CLIENT then	
	local targetText = "You have no target!"
	local hudtxt = {
		{text="Primary fire to drop", font="TabLarge", xalign=TEXT_ALIGN_RIGHT},
		{text="Secondary fire to stick", font="TabLarge", xalign=TEXT_ALIGN_RIGHT},
	}
	
		function SWEP:DrawHUD()
		local x = ScrW() - 80
		hudtxt[1].pos = {x, ScrH() - 40}
		draw.TextShadow(hudtxt[1], 2)
		hudtxt[2].pos = {x, ScrH() - 80}
		draw.TextShadow(hudtxt[2], 2)
	end
end

function SWEP:Reload()
   return false
end


function SWEP:OnRemove()
   if CLIENT and IsValid(self.Owner) and self.Owner == LocalPlayer() and self.Owner:Alive() then
      RunConsoleCommand("lastinv")
   end
end

