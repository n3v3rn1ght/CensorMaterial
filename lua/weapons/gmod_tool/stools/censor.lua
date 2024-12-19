TOOL.Category = "Render"
TOOL.Name = "#tool.censor.name"
TOOL.Command = nil
TOOL.ConfigName = ""

if CLIENT then
    local lang = GetConVar("gmod_language"):GetString()

    if lang == "ru" then
        language.Add("tool.censor.name", "Инструмент цензуры")
        language.Add("tool.censor.desc", "Применяет цензуру к объектам")
        language.Add("tool.censor.0", "ЛКМ по объекту: включить/выключить цензуру")
        
        local qualityLabel = "Качество (меньшее число - сильнее пикселизация)"
        local modeLabel = "Черный квадрат вместо пикселизации"
    else
        language.Add("tool.censor.name", "Censor Tool")
        language.Add("tool.censor.desc", "Applies censorship to objects")
        language.Add("tool.censor.0", "Left-click on an object to toggle censorship")
        
        local qualityLabel = "Quality (lower = more pixelation)"
        local modeLabel = "Black square instead of pixelation"
    end

    function TOOL.BuildCPanel(panel)
        panel:AddControl("Header", { Description = "#tool.censor.desc" })

        panel:AddControl("Slider", {
            Label = (lang == "ru") and "Качество (меньшее число - сильнее пикселизация)" or "Quality (lower = more pixelation)",
            Type = "Float",
            Min = "4",
            Max = "64",
            Command = "censor_quality"
        })

        panel:AddControl("Checkbox", {
            Label = (lang == "ru") and "Черный квадрат вместо пикселизации" or "Black square instead of pixelation",
            Command = "censor_mode"
        })
    end
end

if SERVER then
    function TOOL:LeftClick(trace)
        if not trace.Entity or not IsValid(trace.Entity) then return false end
        local ent = trace.Entity
        local censored = not ent:GetNWBool("Censor", false)
        ent:SetNWBool("Censor", censored)
        return true
    end
end
