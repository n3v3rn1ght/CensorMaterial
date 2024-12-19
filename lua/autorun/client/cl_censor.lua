if CLIENT then
    CreateClientConVar("censor_quality", "8", true, false, "Чем больше число, тем меньше пикселизация (качество).")
    CreateClientConVar("censor_mode", "0", true, false, "0 - пикселизация, 1 - чёрный квадрат")

    local function IsEntityCensored(ent)
        return ent:GetNWBool("Censor", false)
    end

    local function GetCensorMode()
        return GetConVar("censor_mode"):GetInt()
    end

    local function GetCensorScale()
        local cvar = GetConVar("censor_quality")
        local quality = cvar and cvar:GetInt() or 8
        if quality < 1 then quality = 1 end
        return ScrH() / quality
    end

    local dscale = GetCensorScale()
    local tex = GetRenderTarget("Censor_RT_"..dscale, dscale * ScrW() / ScrH(), dscale)
    local mat = CreateMaterial("Censor_RT_"..dscale, "UnlitGeneric", {
        ["$basetexture"] = tex:GetName()
    })
    local function UpdateCensorMaterial()
        dscale = GetCensorScale()
        tex = GetRenderTarget("Censor_RT_"..dscale, dscale * ScrW() / ScrH(), dscale)
        mat = CreateMaterial("Censor_RT_"..dscale, "UnlitGeneric", {
            ["$basetexture"] = tex:GetName()
        })
    end

    cvars.AddChangeCallback("censor_quality", function(convar, oldValue, newValue)
        UpdateCensorMaterial()
    end)

    local function DrawCensorOnProp(ent)
        local mode = GetCensorMode()

        local mins, maxs = ent:OBBMins(), ent:OBBMaxs()

        local corners = {
            Vector(mins.x, mins.y, mins.z),
            Vector(mins.x, mins.y, maxs.z),
            Vector(mins.x, maxs.y, mins.z),
            Vector(mins.x, maxs.y, maxs.z),
            Vector(maxs.x, mins.y, mins.z),
            Vector(maxs.x, mins.y, maxs.z),
            Vector(maxs.x, maxs.y, mins.z),
            Vector(maxs.x, maxs.y, maxs.z),
        }

        for i = 1, #corners do
            corners[i] = ent:LocalToWorld(corners[i])
        end

        local screenPoints = {}
        for _, corner in ipairs(corners) do
            local scrPos = corner:ToScreen()
            if scrPos.visible then
                table.insert(screenPoints, scrPos)
            end
        end

        if #screenPoints == 0 then return end

        local minX, minY = math.huge, math.huge
        local maxX, maxY = -math.huge, -math.huge
        for _, p in ipairs(screenPoints) do
            if p.x < minX then minX = p.x end
            if p.y < minY then minY = p.y end
            if p.x > maxX then maxX = p.x end
            if p.y > maxY then maxY = p.y end
        end

        if mode == 1 then
            cam.Start2D()
                draw.RoundedBox(0, minX, minY, maxX - minX, maxY - minY, Color(0,0,0))
            cam.End2D()
            return
        end

        render.CopyRenderTargetToTexture(tex)
        cam.Start2D()
            render.SetStencilWriteMask(0xFF)
            render.SetStencilTestMask(0xFF)
            render.SetStencilReferenceValue(1)
            render.SetStencilPassOperation(STENCIL_KEEP)
            render.SetStencilZFailOperation(STENCIL_KEEP)
            render.ClearStencil()
            render.SetStencilCompareFunction(STENCIL_NEVER)
            render.SetStencilFailOperation(STENCIL_REPLACE)
            render.SetStencilEnable(true)

                draw.RoundedBox(0, minX, minY, maxX - minX, maxY - minY, Color(0,0,0))

                render.SetStencilCompareFunction(STENCIL_EQUAL)
                render.SetStencilFailOperation(STENCIL_REPLACE)

                render.PushFilterMin(1)
                render.PushFilterMag(1)
                    render.DrawTextureToScreen(tex)
                render.PopFilterMin()
                render.PopFilterMag()

            render.SetStencilEnable(false)
        cam.End2D()
    end

    hook.Add("PostDrawTranslucentRenderables", "CensorProps", function()
        for _, ent in ipairs(ents.GetAll()) do
            if ent ~= LocalPlayer() and IsEntityCensored(ent) and not ent:IsPlayer() then
                DrawCensorOnProp(ent)
            end
        end
    end)
end
