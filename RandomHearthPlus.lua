--[[
======================================================================================================================================================
Random Hearthstone Plus（随机炉石增强版）
======================================================================================================================================================
原作者 JamienAU 的 Random Hearthstone 增强版本。
新增功能：
  - 传送玩具支持（Teleport Toys）
  - 修饰键绑定（Shift / Ctrl / Alt × 左键 / 右键 / 中键，共 9 种组合）
  - 完整兼容 WoW 12.0.5 API

如果有新的炉石玩具或传送玩具发布，只需将其 ItemID 添加到下方的 rhToys 列表中即可。
ItemID 可以从 Wowhead.com 物品页面的 URL 中获取（例如 item=123456 → 123456）。

注意：Weary Spirit Binding（ID: 163206）似乎并未在游戏中实装。添加到列表中可能会导致错误！

GitHub: https://github.com/davidchangok/RandomHearthPlus
======================================================================================================================================================
]]

----------------------------------------------------------------------------------------------------------------------
-- 玩具数据库（Toy Database）
-- 所有可用的炉石玩具和传送玩具的 ItemID 列表
-- 如需添加新玩具，只需在此列表末尾追加即可
----------------------------------------------------------------------------------------------------------------------
local rhToys = {
    -- ========== 炉石玩具（Hearthstone Toys）==========
    184353, -- 格里恩炉石（Kyrian Hearthstone）
    183716, -- 温西尔罪碑（Venthyr Sinstone）
    180290, -- 法夜炉石（Night Fae Hearthstone）
    182773, -- 通灵领主炉石（Necrolord Hearthstone）
    54452,  -- 虚灵之门（Ethereal Portal）
    64488,  -- 旅店老板的女儿（The Innkeeper's Daughter）
    93672,  -- 黑暗之门（Dark Portal）
    142542, -- 城镇传送之书（Tome of Town Portal）
    162973, -- 冬幕节炉石（Greatfather Winter's Hearthstone）
    163045, -- 无头骑士炉石（Headless Horseman's Hearthstone）
    165669, -- 春节炉石（Lunar Elder's Hearthstone）
    165670, -- 情人节炉石（Peddlefeet's Lovely Hearthstone）
    165802, -- 贵族花园炉石（Noble Gardener's Hearthstone）
    166746, -- 火焰节炉石（Fire Eater's Hearthstone）
    166747, -- 美酒节炉石（Brewfest Reveler's Hearthstone）
    168907, -- 全息数字化炉石（Holographic Digitalization Hearthstone）
    172179, -- 永恒旅者炉石（Eternal Traveler's Hearthstone）
    193588, -- 时光行者炉石（Timewalker's Hearthstone）
    188952, -- 统御炉石（Dominated Hearthstone）
    200630, -- 欧恩伊尔风语者炉石（Ohn'ir Windsage's Hearthstone）
    190237, -- 经纪人传送矩阵（Broker Translocation Matrix）
    190196, -- 开悟者炉石（Enlightened Hearthstone）
    209035, -- 烈焰炉石（Hearthstone of the Flame）
    208704, -- 深居者土灵炉石（Deepdweller's Earthen Hearthstone）
    206195, -- 纳鲁之路（Path of the Naaru）
    212337, -- 炉石之石（Stone of the Hearth）
    210455, -- 德莱尼全息宝石（Draenic Hologem）
    228940, -- 恶名线束炉石（Notorious Thread's Hearthstone）
    235016, -- 重新部署模块（Redeployment Module）
    236687, -- 爆炸炉石（Explosive Hearthstone）
    245970, -- P.O.S.T 大师快递炉石（P.O.S.T Master's Express Hearthstone）
    246565, -- 宇宙炉石（Cosmic Hearthstone）
    263489, -- 纳鲁之拥（Naaru's Enfold）
    257736, -- 光召炉石（Lightcalled Hearthstone）
    265100, -- 核心守望者炉石（Corewarden's Hearthstone）
    263933, -- 掠猎物者炉石（Preyseeker's Hearthstone）

    -- ========== 传送玩具（Teleport Toys）— 新增 ==========
    253629, -- 奥秘私钥（Private Key of the Arcanum）
    243056, -- 探索者的虚灵跃迁门（Delver's Ethereal Warp Gate）
    230850, -- 探索者的机器人 7001（Delver's Robot 7001）
}

----------------------------------------------------------------------------------------------------------------------
-- 以下代码请勿修改
-- （除非你真的想改，我又不是你老板）
----------------------------------------------------------------------------------------------------------------------

-- ========== 全局状态变量 ==========
-- rhpList: 当前可用的玩具ID列表（用于随机抽取）
-- macroIcon: 宏图标ID
-- macroToyName: 当前选中的玩具名称（用于宏的 #showtooltip）
-- macroTimer: 防止宏重复更新的计时器标志
-- waitTimer: 宏名称输入防抖计时器
-- pendingMacroUpdate: 是否存在待处理的宏更新（战斗中延迟执行）
local rhpList, macroIcon, macroToyName, macroTimer, waitTimer, pendingMacroUpdate

-- rhpCheckButtons: 存储每个玩具ID对应的选项面板复选框引用
-- wait: 是否正在等待物品数据加载完成
-- lastRnd: 上一次随机选中的玩具ID（避免连续两次选中同一个）
-- loginMsg: 用于追踪首次/版本升级时显示登录消息的版本标识
local rhpCheckButtons, wait, lastRnd, loginMsg = {}, false, 0, "rhp1.0.0"

-- 获取玩家职业ID（德鲁伊=11，需要特殊处理 /cancelform）
local playerClass = select(3, UnitClass("player"))

-- 插件加载入口变量
-- addon: 插件名称 "RandomHearthPlus"
-- RHP: 插件全局表（包含 Localisation 本地化表）
local addon, RHP = ...
local L = RHP.Localisation

-- ========== 修饰键常量定义 ==========
-- MOD_KEYS: 三个修饰键的枚举顺序（用于遍历 modBinds 存储和 UI 下拉菜单）
-- BTN_KEYS: 三个鼠标按键编号（1=左键, 2=右键, 3=中键）
local MOD_KEYS = { "SHIFT", "CTRL", "ALT" }
local BTN_KEYS = { "1", "2", "3" }

-- ========== 修饰键下拉菜单选项标识符 ==========
-- 用于判断当前选中的是哪个绑定选项
local DROPDOWN_RANDOM    = "RANDOM"     -- 随机（跟随主行为）
local DROPDOWN_HEARTH    = "HEARTHSTONE" -- 普通炉石（item:6948）
local DROPDOWN_DALARAN   = "DALARAN"     -- 达拉然炉石（item:140192）
local DROPDOWN_GARRISON  = "GARRISON"    -- 要塞炉石（item:110560）

-- ========== 修饰键绑定值 → 显示名称解析函数 ==========
-- 根据存储的绑定值（nil / item字符串 / 数字ItemID）返回对应的本地化显示文本
local function getModBindDisplayName(value)
    if value == nil then
        -- nil 表示"随机"，即不绑定特定物品，跟随默认行为
        return L["RANDOM"]
    elseif value == "item:6948" then
        -- 绑定到普通炉石
        return L["HEARTHSTONE"]
    elseif value == "item:140192" then
        -- 绑定到达拉然炉石
        return L["DALARAN_HEARTH"]
    elseif value == "item:110560" then
        -- 绑定到要塞炉石
        return L["GARRISON_HEARTH"]
    elseif type(value) == "number" and rhpDB and rhpDB.L and rhpDB.L.tList[value] then
        -- 绑定到某个具体玩具（数字ItemID），从数据库获取玩具名称
        return rhpDB.L.tList[value]["name"]
    else
        -- 兜底：未知值 → 显示"随机"
        return L["RANDOM"]
    end
end

----------------------------------------------------------------------------------------------------------------------
-- 界面框架（Frames）— 创建所有 UI 控件
-- 注意：RegisterCanvasLayoutCategory 必须在设置面板布局代码之前调用
----------------------------------------------------------------------------------------------------------------------

-- rhpOptionsPanel: 设置面板的主框架（Canvas）
-- rhpCategory: 设置分类注册对象，用于将面板注册到游戏的"选项 → 插件"界面
local rhpOptionsPanel = CreateFrame("Frame")
local rhpCategory = Settings.RegisterCanvasLayoutCategory(rhpOptionsPanel, "Random Hearthstone Plus")

-- rhpTitle: 设置面板标题 "Random Hearthstone Plus"
local rhpTitle = CreateFrame("Frame", nil, rhpOptionsPanel)
-- rhpDesc: 设置面板描述文字
local rhpDesc = CreateFrame("Frame", nil, rhpOptionsPanel)
-- rhpOptionsScroll: 玩具列表滚动区域（只含玩具复选框 + 修饰键绑定区域）
local rhpOptionsScroll = CreateFrame("ScrollFrame", nil, rhpOptionsPanel, "UIPanelScrollFrameTemplate")
-- rhpDivider: 滚动区域下方的分割线（分隔玩具列表与底部控制按钮）
local rhpDivider = rhpOptionsScroll:CreateLine()
-- rhpScrollChild: 滚动区域的子框架，玩具复选框 + 修饰键绑定挂载在此
local rhpScrollChild = CreateFrame("Frame")
-- rhpSelectAll / rhpDeselectAll: "全选"和"全部取消"按钮（滚动区域外部，始终可见）
local rhpSelectAll = CreateFrame("Button", nil, rhpOptionsScroll, "UIPanelButtonTemplate")
local rhpDeselectAll = CreateFrame("Button", nil, rhpOptionsScroll, "UIPanelButtonTemplate")
-- rhpOverride: "仅允许当前盟约炉石"复选框（滚动区域外部）
local rhpOverride = CreateFrame("CheckButton", nil, rhpOptionsScroll, "UICheckButtonTemplate")
-- rhpListener: 事件监听框架
local rhpListener = CreateFrame("Frame")
-- rhpBtn: SecureActionButton，全局名称 "rhpB"
local rhpBtn = CreateFrame("Button", "rhpB", nil, "SecureActionButtonTemplate")
-- rhpDropdown: 宏图标选择下拉菜单（面板固定右下区域）
local rhpDropdown = CreateFrame("DropdownButton", nil, rhpOptionsPanel, "WowStyle1DropdownTemplate")
-- rhpDalHearth: "右键 → 达拉然炉石"（面板固定底部）
local rhpDalHearth = CreateFrame("CheckButton", nil, rhpOptionsPanel, "UICheckButtonTemplate")
-- rhpGarHearth: "中键 → 要塞炉石"（面板固定底部）
local rhpGarHearth = CreateFrame("CheckButton", nil, rhpOptionsPanel, "UICheckButtonTemplate")
-- rhpMacroName: 自定义宏名称输入框（面板固定底部）
local rhpMacroName = CreateFrame("EditBox", nil, rhpOptionsPanel, "InputBoxTemplate")

-- ========== 修饰键绑定区域（3×3 下拉菜单网格，在滚动区域内）==========
local rhpModDropdowns = {}
local rhpModSectionLabel = CreateFrame("Frame", nil, rhpScrollChild)
local rhpModHeaders = {}
local rhpModRowLabels = {}

----------------------------------------------------------------------------------------------------------------------
-- 功能函数（Functions）
----------------------------------------------------------------------------------------------------------------------

-- ========== 战斗状态检测 ==========
-- 如果玩家处于战斗中，返回 true —— 此时禁止修改宏和 SecureActionButton 属性
-- WoW API 安全限制：战斗中无法修改受保护的 UI 元素
local function combatCheck()
    if (InCombatLockdown() or UnitAffectingCombat("player") or UnitAffectingCombat("pet")) then
        return true
    end
end

-- ========== 延迟宏更新 ==========
-- 如果当前处于战斗中，注册 PLAYER_REGEN_ENABLED 事件
-- 在脱离战斗后立即触发挂起的宏更新
local function deferMacroUpdate()
    if not pendingMacroUpdate then
        pendingMacroUpdate = true
        rhpListener:RegisterEvent("PLAYER_REGEN_ENABLED")
    end
end

-- ========== 根据修饰键和按键动态设置按钮动作（PreClick 模式）==========
-- 核心问题：/click 命令不会将修饰键状态传递给 SecureActionButton 的属性系统
-- /click [mod:shift,btn:1]rhpB 1 中的 [mod:shift] 只决定是否执行 /click，
-- rhpB 收到的仍是普通左键点击，shift-type1/shift-toy1 属性永远不会被触发
--
-- 解决方案：使用 PreClick 脚本动态修改 type/toy/item 属性
-- 在点击发生前，根据当前按下的修饰键和按键，设置对应的动作类型和参数
-- 这样 rhpB 始终使用 "type"/"toy"/"item" 属性，但值每次动态切换
local function rhpPreClick(self, button, isDown)
    -- 判断当前按下的修饰键
    local heldMod = nil
    if IsShiftKeyDown() then
        heldMod = "SHIFT"
    elseif IsControlKeyDown() then
        heldMod = "CTRL"
    elseif IsAltKeyDown() then
        heldMod = "ALT"
    end

    -- 将 SecureActionButton 的按钮标识（"1"/"2"/"3" 或 "LeftButton" 等）统一为 "1"/"2"/"3"
    local btnKey
    if button == "LeftButton" or button == "1" then
        btnKey = "1"
    elseif button == "RightButton" or button == "2" then
        btnKey = "2"
    elseif button == "MiddleButton" or button == "3" then
        btnKey = "3"
    else
        btnKey = "1"  -- 默认按左键处理
    end

    -- 优先检查：修饰键 + 按键的自定义绑定
    if heldMod then
        local bindValue = rhpDB.settings.modBinds[heldMod][btnKey]
        if bindValue then
            if type(bindValue) == "number" then
                -- 绑定到玩具 ItemID
                self:SetAttribute("type", "toy")
                self:SetAttribute("toy", bindValue)
                return
            elseif type(bindValue) == "string" then
                -- 绑定到物品 "item:XXXXX"
                self:SetAttribute("type", "item")
                self:SetAttribute("item", bindValue)
                return
            end
        end
    end

    -- 次优先：无修饰键时，右键/中键的特殊处理
    if not heldMod then
        if (btnKey == "2") and rhpDB.settings.dalOpt then
            -- 右键无修饰键 → 达拉然炉石
            self:SetAttribute("type", "toy")
            self:SetAttribute("toy", rhpDB.L.dalaran)
            return
        elseif (btnKey == "3") and rhpDB.settings.garOpt then
            -- 中键无修饰键 → 要塞炉石
            self:SetAttribute("type", "toy")
            self:SetAttribute("toy", rhpDB.L.garrison)
            return
        end
    end

    -- 默认：使用当前随机选中的炉石玩具
    self:SetAttribute("type", "toy")
    self:SetAttribute("toy", macroToyName)
end

-- ========== 创建或更新全局宏 ==========
-- 生成简单的 /click 宏，仅按鼠标按键类型（左/右/中）路由到 rhpB 安全按钮
-- 修饰键（Shift/Ctrl/Alt）由 rhpB 的 PreClick 脚本实时检测并动态路由
--   [btn:2]rhpB 2 → 右键（PreClick 判断 Dalaran 或修饰键绑定）
--   [btn:3]rhpB 3 → 中键（PreClick 判断 Garrison 或修饰键绑定）
--   rhpB       → 默认左键（PreClick 判断随机玩具或修饰键绑定）
-- 德鲁伊特殊处理：自动在宏中加入 /cancelform 以取消变形形态
local function updateMacro()
    if not combatCheck() then
        local macroText
        if #rhpList == 0 then
            -- 没有可用的炉石玩具 → 显示警告并使用普通炉石兜底
            if rhpDB.settings.warnMsg ~= true then
                rhpDB.settings.warnMsg = true
                print(L["NO_VALID_CHOSEN"])
            end
            macroText = "#showtooltip " .. macroToyName .. "\n/use " .. macroToyName
        else
            -- 构建宏文本
            -- /click 只按鼠标按键路由到 rhpB，修饰键由 PreClick 脚本动态检测
            -- [btn:2] → 右键（路由到 PreClick 判断是 Dalaran 还是修饰键绑定）
            -- [btn:3] → 中键（路由到 PreClick 判断是 Garrison 还是修饰键绑定）
            -- rhpB   → 默认左键（路由到 PreClick 判断是随机玩具还是修饰键绑定）
            if playerClass == 11 then
                -- 德鲁伊：需要 /cancelform 来在施放炉石前取消变形形态
                macroText = "#showtooltip " .. macroToyName
                    .. "\n/cancelform"
                    .. "\n/stopcasting"
                    .. "\n/click [btn:2]rhpB 2;[btn:3]rhpB 3;rhpB"
            else
                -- 非德鲁伊：只需要 /stopcasting
                macroText = "#showtooltip " .. macroToyName
                    .. "\n/stopcasting"
                    .. "\n/click [btn:2]rhpB 2;[btn:3]rhpB 3;rhpB"
            end
        end

        -- 使用计时器防抖，避免短时间内重复创建/编辑宏
        if macroTimer ~= true then
            macroTimer = true
            C_Timer.After(0.1, function()
                -- 延迟回调中再次检查战斗状态
                if combatCheck() then
                    macroTimer = false
                    deferMacroUpdate()
                    return
                end
                -- 查找宏是否已存在
                local macroIndex = GetMacroIndexByName(rhpDB.settings.macroName)
                if macroIndex == 0 then
                    -- 宏不存在 → 创建新宏
                    print(L["MACRO_NOT_FOUND"], rhpDB.settings.macroName, "'")
                    CreateMacro(rhpDB.settings.macroName, macroIcon, macroText, nil)
                    rhpMacroName:SetText(rhpDB.settings.macroName)
                else
                    -- 宏已存在 → 更新其图标和内容
                    EditMacro(macroIndex, nil, macroIcon, macroText)
                end
                macroTimer = false
            end)
        end
    end
end

-- ========== 更新宏名称 ==========
-- 用户修改宏名称输入框后调用，重命名已有宏或创建新宏
local function updateMacroName()
    if not combatCheck() then
        local name = rhpMacroName:GetText()
        local macroIndex = GetMacroIndexByName(rhpDB.settings.macroName)
        if macroIndex == 0 then
            -- 旧名称的宏已不存在，重新创建
            updateMacro()
        else
            -- 重命名现有宏并保存到设置
            EditMacro(macroIndex, name)
            rhpDB.settings.macroName = name
            print(L["UPDATE_MACRO_NAME"], name, "'")
        end
    end
end

-- ========== 检查宏名称有效性 ==========
-- 在输入框失去焦点或按回车时调用
-- 如果新名称未被占用且非空，则执行重命名
local function checkMacroName()
    if not combatCheck() then
        local name = rhpMacroName:GetText()
        -- 名称未变化或为空 → 不做处理
        if name == rhpDB.settings.macroName or string.len(name) == 0 then return end
        -- 新名称未被其他宏占用 → 隐藏确认图标，执行重命名
        if GetMacroIndexByName(name) == 0 then
            rhpMacroName.Icon:Hide()
            updateMacroName()
        end
    end
end

-- ========== 随机选择炉石玩具 ==========
-- 从可用玩具列表 rhpList 中随机抽取一个
-- 如果列表中有多个玩具，确保不会连续两次选中同一个
-- 如果列表为空，兜底使用普通炉石（item:6948）
local function setRandom()
    if not combatCheck() then
        if #rhpList > 0 then
            -- 从可用列表中随机选取
            local rnd = rhpList[math.random(1, #rhpList)]
            if #rhpList > 1 then
                -- 列表中有多个玩具时，避免连续两次选同一个
                while rnd == lastRnd do
                    rnd = rhpList[math.random(1, #rhpList)]
                end
                lastRnd = rnd
            end
            -- 设置宏显示的玩具名称
            macroToyName = rhpDB.L.tList[rnd]["name"]
            -- 确定宏图标：如果用户选择了"随机"图标 → 使用当前玩具的图标；否则使用用户指定的图标
            if rhpDB.iconOverride.name == L["RANDOM"] then
                macroIcon = rhpDB.L.tList[rnd]["icon"]
            else
                macroIcon = rhpDB.iconOverride.icon
            end
        else
            -- 没有可用玩具 → 兜底使用普通炉石（图标 134414）
            macroToyName = "item:6948"
            macroIcon = 134414
        end
        -- PreClick 根据修饰键动态设置按钮属性，此处只需更新宏
        updateMacro()
    end
end

-- ========== 生成可用玩具列表 ==========
-- 遍历所有注册的玩具，检查以下条件：
--   1. 用户在选项中已勾选启用（status == true）
--   2. 玩家确实拥有该玩具（PlayerHasToy）
--   3. 盟约炉石限制：如果不是当前盟约且不满足解锁条件，排除
--   4. 德莱尼全息宝石（210455）：仅限德莱尼/光铸德莱尼种族
-- 最终生成 rhpList 用于随机抽取
local function listGenerate()
    rhpList = {}

    -- allCovenant 标志：是否解锁了所有盟约炉石（成就 15241）
    local allCovenant
    -- 盟约炉石列表：{ 成就条件索引, 盟约ID, 玩具ItemID, 是否已通过成就解锁 }
    local covenantHearths = {
        { 1, 1, 184353, false }, -- 格里恩（Kyrian）
        { 4, 2, 183716, false }, -- 温西尔（Venthyr）
        { 3, 3, 180290, false }, -- 法夜（Night Fae）
        { 2, 4, 182773, false }, -- 通灵领主（Necrolord）
    }

    -- 检查每个盟约炉石是否通过声望成就解锁（成就 15646）
    for i, v in pairs(covenantHearths) do
        if select(3, GetAchievementCriteriaInfo(15646, v[1])) == true then
            -- 已解锁 → 标记为可用
            covenantHearths[i][4] = true
        elseif C_Covenants.GetActiveCovenantID() ~= v[2] then
            -- 未解锁且不是当前盟约 → 在复选框中显示"声望锁定"提示
            if rhpDB.L.tList[v[3]] ~= nil and rhpCheckButtons[v[3]] then
                rhpCheckButtons[v[3]].Extratext = rhpCheckButtons[v[3]]:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                rhpCheckButtons[v[3]].Extratext:SetText("|cff777777(" .. L["RENOWN_LOCKED"] .. ")|r")
                rhpCheckButtons[v[3]].Extratext:SetPoint("LEFT", rhpCheckButtons[v[3]].Text, "RIGHT", 10, 0)
            end
        end
    end

    -- 检查是否有允许所有盟约炉石的成就（成就 15241）
    if select(4, GetAchievementInfo(15241)) == true then
        if rhpDB.settings.covOverride == true then
            -- 用户勾选了"仅允许当前盟约" → 覆盖成就
            allCovenant = false
        else
            allCovenant = true
        end
    end

    -- 遍历所有玩具，筛选可用的加入 rhpList
    for i, v in pairs(rhpDB.L.tList) do
        if v["status"] == true then  -- 用户在选项中启用了此玩具
            if PlayerHasToy(i) then   -- 玩家确实拥有此玩具
                local addToy = true

                -- 盟约炉石检查
                for _, k in pairs(covenantHearths) do
                    if i == k[3] then
                        if k[4] == false and C_Covenants.GetActiveCovenantID() ~= k[2] then
                            -- 未通过声望解锁且不是当前盟约 → 排除
                            addToy = false
                        elseif allCovenant == false and C_Covenants.GetActiveCovenantID() ~= k[2] then
                            -- 用户限制了仅当前盟约且不是当前盟约 → 排除
                            addToy = false
                            break
                        end
                    end
                end

                -- 德莱尼种族检查：德莱尼全息宝石（210455）仅限德莱尼（11）和光铸德莱尼（30）
                if i == 210455 then
                    local _, _, raceID = UnitRace("player")
                    if not (raceID == 11 or raceID == 30) then
                        addToy = false
                    end
                end

                -- 通过所有检查 → 加入可用列表
                if addToy == true then
                    table.insert(rhpList, i)
                end
            end
        end
    end

    -- 进行一次随机选择
    setRandom()

    -- 刷新所有修饰键下拉菜单的显示文本（玩具名称可能在物品加载完成后才可用）
    for _, mod in ipairs(MOD_KEYS) do
        for _, btn in ipairs(BTN_KEYS) do
            rhpModDropdowns[mod][btn]:SetText(getModBindDisplayName(rhpDB.settings.modBinds[mod][btn]))
        end
    end
end

-- ========== 设置面板确认回调 ==========
-- 当用户关闭设置面板时调用，保存所有选项到 rhpDB
local function rhpOptionsOkay()
    -- 保存每个玩具的启用/禁用状态
    for i, v in pairs(rhpDB.L.tList) do
        if rhpCheckButtons[i] then
            v["status"] = rhpCheckButtons[i]:GetChecked()
        end
    end
    -- 保存设置选项
    rhpDB.settings.covOverride = rhpOverride:GetChecked()
    rhpDB.settings.dalOpt = rhpDalHearth:GetChecked()
    rhpDB.settings.garOpt = rhpGarHearth:GetChecked()
    rhpDB.settings.warnMsg = false  -- 重置警告消息标志，下次无可用玩具时会再次提示
    -- 重新生成可用列表并刷新宏
    listGenerate()
end

-- ========== 宏图标选择 ==========
-- arg1: "Random" → 使用当前随机玩具的图标（动态图标）
-- arg1: "Hearthstone" → 固定使用普通炉石图标
-- arg1: 数字 ItemID → 固定使用指定玩具的图标
local function rhpSelectIcon(arg1)
    if arg1 == "Random" then
        rhpDB.iconOverride.name = L["RANDOM"]
        rhpDB.iconOverride.icon = 134400
        rhpDB.iconOverride.id = nil
    elseif arg1 == "Hearthstone" then
        rhpDB.iconOverride.name = L["HEARTHSTONE"]
        rhpDB.iconOverride.icon = 134414
        rhpDB.iconOverride.id = 6948
    else
        -- 使用指定玩具的名称和图标
        rhpDB.iconOverride.name = rhpDB.L.tList[arg1]["name"]
        rhpDB.iconOverride.icon = rhpDB.L.tList[arg1]["icon"]
        rhpDB.iconOverride.id = arg1
    end
    -- 更新下拉菜单的显示
    rhpDropdown:SetText(rhpDB.iconOverride.name)
    rhpDropdown.Texture:SetTexture(rhpDB.iconOverride.icon)
end

-- ========== 宏图标下拉菜单生成器 ==========
-- 为 WowStyle1DropdownTemplate 提供菜单项
-- 菜单选项：随机 → 普通炉石 → 所有已注册的玩具
local function rhpDropdownGenerator(dropdown, rootDescription)
    -- IsSelected: 判断某个值是否是当前选中的图标选项
    local function IsSelected(value)
        if value == "Random" then return rhpDB.iconOverride.name == L["RANDOM"] end
        if value == "Hearthstone" then return rhpDB.iconOverride.name == L["HEARTHSTONE"] end
        return rhpDB.iconOverride.id == value
    end

    -- 创建两个特殊选项："随机"和"普通炉石"
    rootDescription:CreateRadio(L["RANDOM"], IsSelected, function() rhpSelectIcon("Random") end, "Random")
    rootDescription:CreateRadio(L["HEARTHSTONE"], IsSelected, function() rhpSelectIcon("Hearthstone") end, "Hearthstone")

    -- 为每个已注册的玩具创建一个菜单项
    for i = 1, #rhToys do
        if rhpDB.L.tList[rhToys[i]] ~= nil then
            rootDescription:CreateRadio(rhpDB.L.tList[rhToys[i]]["name"], IsSelected, function() rhpSelectIcon(rhToys[i]) end, rhToys[i])
        end
    end
end

-- ========== 修饰键绑定下拉菜单生成器 ==========
-- 为修饰键区域的每个下拉菜单提供选项：
--   随机 → 普通炉石 → 达拉然炉石 → 要塞炉石 → 所有已注册的玩具
-- dropdown.modKey 和 dropdown.btnKey 用于标识此菜单属于哪个修饰键+按键组合
local function rhpModDropdownGenerator(dropdown, rootDescription)
    local mod = dropdown.modKey  -- "SHIFT" / "CTRL" / "ALT"
    local btn = dropdown.btnKey  -- "1" / "2" / "3"

    -- IsSelected: 判断某个值是否是当前绑定的选项
    local function IsSelected(value)
        local current = rhpDB.settings.modBinds[mod][btn]
        if value == DROPDOWN_RANDOM then
            return current == nil  -- nil 表示"随机"
        elseif value == DROPDOWN_HEARTH then
            return current == "item:6948"
        elseif value == DROPDOWN_DALARAN then
            return current == "item:140192"
        elseif value == DROPDOWN_GARRISON then
            return current == "item:110560"
        else
            return current == tonumber(value)  -- 数字 ItemID 格式
        end
    end

    -- OnSelect: 用户选择菜单项时的处理
    local function OnSelect(value)
        if value == DROPDOWN_RANDOM then
            rhpDB.settings.modBinds[mod][btn] = nil  -- nil = 随机/不绑定
        elseif value == DROPDOWN_HEARTH then
            rhpDB.settings.modBinds[mod][btn] = "item:6948"
        elseif value == DROPDOWN_DALARAN then
            rhpDB.settings.modBinds[mod][btn] = "item:140192"
        elseif value == DROPDOWN_GARRISON then
            rhpDB.settings.modBinds[mod][btn] = "item:110560"
        else
            rhpDB.settings.modBinds[mod][btn] = tonumber(value)  -- 存储为数字 ItemID
        end
        -- 更新下拉菜单显示文本
        dropdown:SetText(getModBindDisplayName(rhpDB.settings.modBinds[mod][btn]))
    end

    -- 创建四个特殊选项
    rootDescription:CreateRadio(L["RANDOM"], IsSelected, function() OnSelect(DROPDOWN_RANDOM) end, DROPDOWN_RANDOM)
    rootDescription:CreateRadio(L["HEARTHSTONE"], IsSelected, function() OnSelect(DROPDOWN_HEARTH) end, DROPDOWN_HEARTH)
    rootDescription:CreateRadio(L["DALARAN_HEARTH"], IsSelected, function() OnSelect(DROPDOWN_DALARAN) end, DROPDOWN_DALARAN)
    rootDescription:CreateRadio(L["GARRISON_HEARTH"], IsSelected, function() OnSelect(DROPDOWN_GARRISON) end, DROPDOWN_GARRISON)

    -- 为每个已注册的玩具创建一个菜单项
    for i = 1, #rhToys do
        if rhpDB.L.tList[rhToys[i]] ~= nil then
            rootDescription:CreateRadio(rhpDB.L.tList[rhToys[i]]["name"], IsSelected, function() OnSelect(tostring(rhToys[i])) end, tostring(rhToys[i]))
        end
    end
end

-- ========== 保存变量初始化辅助函数 ==========
-- 安全地向表中添加项：如果项已存在则跳过，否则添加
-- table: 目标表
-- item: 键（key）或值
-- value: 可选，如果提供则作为键值对 table[item] = value，否则 table.insert(table, item)
local function rhpInitDB(table, item, value)
    local isTable = type(value) == "table"
    local exists = false
    -- 检查项是否已存在于表中
    for k, v in pairs(table) do
        if k == item or (type(v) == "table" and isTable and v == value) then
            exists = true
            break
        end
    end
    -- 不存在则添加
    if not exists then
        if value ~= nil then
            table[item] = value  -- 键值对形式添加
        else
            table.insert(table, item)  -- 列表形式追加
        end
    end
end

-- ========== 恢复默认设置 ==========
-- 将所有选项重置为插件的出厂默认值
local function rhpResetDefaults()
    -- 所有玩具复选框 → 启用
    for i, v in pairs(rhpCheckButtons) do
        v:SetChecked(true)
    end
    -- 设置复选框 → 默认值
    rhpOverride:SetChecked(false)   -- 不禁用非当前盟约
    rhpDalHearth:SetChecked(true)   -- 右键 → 达拉然炉石
    rhpGarHearth:SetChecked(true)   -- 中键 → 要塞炉石
    -- 宏名称 → 默认 "Random Hearth"（或其本地化版本）
    rhpMacroName:SetText(L["MACRO_NAME"])
    -- 宏图标 → "随机"（动态显示当前玩具图标）
    rhpSelectIcon("Random")
    -- 所有修饰键绑定 → "随机"（清除所有自定义绑定）
    for _, mod in ipairs(MOD_KEYS) do
        for _, btn in ipairs(BTN_KEYS) do
            rhpDB.settings.modBinds[mod][btn] = nil
            rhpModDropdowns[mod][btn]:SetText(L["RANDOM"])
        end
    end
    print(L["DEFAULT_RESTORED"])
end

----------------------------------------------------------------------------------------------------------------------
-- SecureActionButton（rhpB）— 安全动作按钮的配置
--
-- 这是整个插件的核心交互机制：
--   - rhpB 是一个受 WoW 安全系统保护的按钮，可以在战斗中响应点击
--   - 宏通过 /click rhpB [按键编号] 将点击路由到此按钮
--   - PreClick 脚本在点击前运行，根据当前修饰键和按键动态设置 type/toy/item
--   - PostClick 脚本在点击后运行，用于重新随机选择下一个玩具
--   - 不使用静态的 shift-/ctrl-/alt- 前缀属性，因为 /click 不传递修饰键状态
----------------------------------------------------------------------------------------------------------------------

-- RegisterForClicks("AnyDown"): 响应所有鼠标按键（左/右/中）的按下事件
rhpBtn:RegisterForClicks("AnyDown")
-- pressAndHoldAction = true: 允许按住按钮持续施放（类似原版炉石行为）
rhpBtn:SetAttribute("pressAndHoldAction", true)
rhpBtn:SetAttribute("typerelease", "toy")

-- PreClick 脚本：点击前触发，根据修饰键和按键动态设置动作
rhpBtn:SetScript("PreClick", rhpPreClick)

-- PostClick 脚本：点击后触发，仅在左键无修饰键时重新随机选择下一个玩具
rhpBtn:SetScript("PostClick", function(self, button)
    if not combatCheck() then
        -- 仅在左键无修饰键时重新随机
        -- 修饰键+右键/中键不应触发随机重选
        if button == "LeftButton" or button == "1" then
            if not IsShiftKeyDown() and not IsControlKeyDown() and not IsAltKeyDown() then
                setRandom()
            end
        end
    end
end)

----------------------------------------------------------------------------------------------------------------------
-- 设置面板（Options Panel）— 布局和控件配置
--
-- 布局结构（复刻原始 RandomHearth 的锚定模式）：
--   顶部区（rhpOptionsPanel，不滚动）：
--     - 标题、描述、致谢文字
--   滚动区（rhpOptionsScroll → rhpScrollChild）：
--     - 玩具复选框列表
--     - 修饰键绑定 3×3 网格
--   底部区（rhpOptionsScroll / rhpOptionsPanel，挂在滚动框外部，始终可见）：
--     - 分割线
--     - 全选 / 全部取消按钮
--     - 盟约复选框 + 宏图标下拉菜单（同行）
--     - 达拉然炉石复选框
--     - 要塞炉石复选框
--     - 宏名称输入框
----------------------------------------------------------------------------------------------------------------------
rhpOptionsPanel.name = "Random Hearthstone Plus"
rhpOptionsPanel.OnCommit = function() rhpOptionsOkay(); end
rhpOptionsPanel.OnDefault = function() rhpResetDefaults(); end
rhpOptionsPanel.OnRefresh = function() end
Settings.RegisterAddOnCategory(rhpCategory)

-- ========== 标题栏（面板顶部，不滚动）==========
rhpTitle:SetPoint("TOPLEFT", 10, -10)
rhpTitle:SetWidth(SettingsPanel.Container:GetWidth() - 35)
rhpTitle:SetHeight(1)
rhpTitle.Text = rhpTitle:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
rhpTitle.Text:SetPoint("TOPLEFT", rhpTitle, 0, 0)
rhpTitle.Text:SetText(L["ADDON_NAME"])

-- ========== 致谢文字（右上角）==========
rhpOptionsPanel.Thanks = rhpOptionsPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
rhpOptionsPanel.Thanks:SetPoint("TOPRIGHT", rhpOptionsPanel, "TOPRIGHT", -5, -5)
rhpOptionsPanel.Thanks:SetTextColor(1, 1, 1, 0.5)
rhpOptionsPanel.Thanks:SetText(L["THANKS"] .. " :)\nOriginal by JamienAU | Enhanced by David W Zhang")
rhpOptionsPanel.Thanks:SetJustifyH("RIGHT")

-- ========== 描述文字 ==========
rhpDesc:SetPoint("TOPLEFT", 20, -40)
rhpDesc:SetWidth(SettingsPanel.Container:GetWidth() - 35)
rhpDesc:SetHeight(1)
rhpDesc.Text = rhpDesc:CreateFontString(nil, "OVERLAY", "GameFontNormal")
rhpDesc.Text:SetPoint("TOPLEFT", rhpDesc, 0, 0)
rhpDesc.Text:SetText(L["DESCRIPTION"])

-- ========== 滚动框架（玩具列表 + 修饰键绑定）==========
-- 底部留空 240px，容纳底部固定控件（分割线 / 按钮 / 复选框 / 宏名称 / 下拉菜单）
rhpOptionsScroll:SetPoint("TOPLEFT", 5, -60)
rhpOptionsScroll:SetPoint("BOTTOMRIGHT", -25, 240)

-- ========== 分割线（分隔滚动区和底部固定控件区）==========
rhpDivider:SetStartPoint("BOTTOMLEFT", rhpDivider:GetParent(), 20, -10)
rhpDivider:SetEndPoint("BOTTOMRIGHT", rhpDivider:GetParent(), 0, -10)
rhpDivider:SetColorTexture(0.25, 0.25, 0.25, 1)
rhpDivider:SetThickness(1.2)

-- ========== 滚动子框架 ==========
rhpOptionsScroll:SetScrollChild(rhpScrollChild)
rhpScrollChild:SetWidth(SettingsPanel.Container:GetWidth() - 35)
rhpScrollChild:SetHeight(1)

-- ========== 玩具复选框列表（滚动内容）==========
local chkOffset = 0
for i = 1, #rhToys do
    if i > 1 then
        chkOffset = chkOffset + -26
    end
    rhpCheckButtons[rhToys[i]] = CreateFrame("CheckButton", nil, rhpScrollChild, "UICheckButtonTemplate")
    rhpCheckButtons[rhToys[i]]:SetPoint("TOPLEFT", 15, chkOffset)
    rhpCheckButtons[rhToys[i]]:SetSize(25, 25)
    rhpCheckButtons[rhToys[i]].Text = rhpCheckButtons[rhToys[i]]:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    local item = Item:CreateFromItemID(rhToys[i])
    item:ContinueOnItemLoad(function()
        if rhpCheckButtons[rhToys[i]] then
            rhpCheckButtons[rhToys[i]].Text:SetText(item:GetItemName())
        end
    end)
    rhpCheckButtons[rhToys[i]].Text:SetTextColor(1, 1, 1, 1)
    rhpCheckButtons[rhToys[i]].Text:SetPoint("LEFT", 28, 0)
end

-- ========== 修饰键绑定区域（滚动内容，位于玩具列表下方）==========
-- 计算区域起始 Y 位置：最后一个复选框下方 30px
local modSectionY = chkOffset - 30

-- 区域标题
rhpModSectionLabel:SetPoint("TOPLEFT", rhpScrollChild, "TOPLEFT", 15, modSectionY)
rhpModSectionLabel:SetWidth(SettingsPanel.Container:GetWidth() - 35)
rhpModSectionLabel:SetHeight(1)
rhpModSectionLabel.Text = rhpModSectionLabel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
rhpModSectionLabel.Text:SetPoint("TOPLEFT", rhpModSectionLabel, 0, 0)
rhpModSectionLabel.Text:SetText(L["MOD_BINDINGS"])

-- 列标题：左键 | 右键 | 中键
local headerLabels = { L["MOD_LEFT_CLICK"], L["MOD_RIGHT_CLICK"], L["MOD_MIDDLE_CLICK"] }
local headerStartX = 125
local headerSpacing = 160
for i, label in ipairs(headerLabels) do
    local hdr = CreateFrame("Frame", nil, rhpScrollChild)
    hdr:SetPoint("TOPLEFT", rhpModSectionLabel, "TOPLEFT", headerStartX + (i - 1) * headerSpacing, -25)
    hdr:SetWidth(140)
    hdr:SetHeight(1)
    hdr.Text = hdr:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    hdr.Text:SetPoint("TOPLEFT", hdr, 0, 0)
    hdr.Text:SetText(label)
    hdr.Text:SetTextColor(1, 0.82, 0, 1)
    rhpModHeaders[i] = hdr
end

-- 行标签和下拉菜单：Shift / Ctrl / Alt
local rowLabels = { L["MOD_SHIFT"], L["MOD_CTRL"], L["MOD_ALT"] }
local rowStartY = -50
local rowSpacing = -30
for modIdx, mod in ipairs(MOD_KEYS) do
    rhpModDropdowns[mod] = {}
    local rowLabel = CreateFrame("Frame", nil, rhpScrollChild)
    rowLabel:SetPoint("TOPLEFT", rhpModSectionLabel, "TOPLEFT", 5, rowStartY + (modIdx - 1) * rowSpacing)
    rowLabel:SetWidth(110)
    rowLabel:SetHeight(1)
    rowLabel.Text = rowLabel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    rowLabel.Text:SetPoint("TOPLEFT", rowLabel, 0, -7)
    rowLabel.Text:SetText(rowLabels[modIdx])
    rowLabel.Text:SetTextColor(1, 1, 1, 1)
    rhpModRowLabels[mod] = rowLabel
    for btnIdx, btn in ipairs(BTN_KEYS) do
        local dd = CreateFrame("DropdownButton", nil, rhpScrollChild, "WowStyle1DropdownTemplate")
        dd:SetPoint("TOPLEFT", rhpModSectionLabel, "TOPLEFT", headerStartX + (btnIdx - 1) * headerSpacing, rowStartY + (modIdx - 1) * rowSpacing)
        dd:SetWidth(140)
        dd:SetDefaultText(L["RANDOM"])
        dd.modKey = mod
        dd.btnKey = btn
        dd:SetupMenu(rhpModDropdownGenerator)
        rhpModDropdowns[mod][btn] = dd
    end
end

-- 设置滚动子框架高度（玩具列表 + 修饰键区域总高）
local scrollChildHeight = (-modSectionY) + 160
rhpScrollChild:SetHeight(scrollChildHeight)

-- ========== 以下为滚动区域外部的固定控件 ==========
-- 所有控件锚定到 rhpOptionsScroll 的 BOTTOMLEFT / BOTTOMRIGHT
-- 原始 RandomHearth 的锚定模式：TOPLEFT parent BOTTOMLEFT (x, -y)

-- "全选"按钮（距滚动框底部 20px）
rhpSelectAll:SetPoint("TOPLEFT", rhpSelectAll:GetParent(), "BOTTOMLEFT", 20, -20)
rhpSelectAll:SetSize(100, 25)
rhpSelectAll:SetText(L["SELECT_ALL"])
rhpSelectAll:SetScript("OnClick", function(self)
    for i, v in pairs(rhpCheckButtons) do
        v:SetChecked(true)
    end
end)

-- "全部取消"按钮（与全选同行）
rhpDeselectAll:SetPoint("TOPLEFT", rhpDeselectAll:GetParent(), "BOTTOMLEFT", 135, -20)
rhpDeselectAll:SetSize(100, 25)
rhpDeselectAll:SetText(L["DESELECT_ALL"])
rhpDeselectAll:SetScript("OnClick", function(self)
    for i, v in pairs(rhpCheckButtons) do
        v:SetChecked(false)
    end
end)

-- "仅允许当前盟约炉石"复选框（距滚动框底部 50px）
rhpOverride:SetPoint("TOPLEFT", rhpOverride:GetParent(), "BOTTOMLEFT", 15, -50)
rhpOverride:SetSize(25, 25)
rhpOverride.Text:SetJustifyH("LEFT")
rhpOverride.Text:SetText(" " .. L["COV_ONLY"])
rhpOverride.Text:SetTextColor(1, 1, 1, 1)

-- 宏图标下拉菜单（右侧，与盟约复选框同行）
rhpDropdown:SetPoint("TOPRIGHT", rhpOverride:GetParent(), "BOTTOMRIGHT", -20, -35)
rhpDropdown:SetWidth(200)
rhpDropdown:SetDefaultText(L["RANDOM"])
rhpDropdown.Texture = rhpDropdown:CreateTexture(nil, "OVERLAY")
rhpDropdown.Texture:SetSize(24, 24)
rhpDropdown.Texture:SetPoint("LEFT", rhpDropdown, "RIGHT", 5, 0)
rhpDropdown.Extratext = rhpDropdown:CreateFontString(nil, "OVERLAY", "GameFontNormal")
rhpDropdown.Extratext:SetText(L["OPT_MACRO_ICON"])
rhpDropdown.Extratext:SetPoint("BOTTOMLEFT", rhpDropdown, "TOPLEFT", 0, 5)

-- "右键 → 达拉然炉石"（锚定到盟约复选框下方）
rhpDalHearth:SetPoint("TOPLEFT", rhpOverride, "BOTTOMLEFT", 0, 0)
rhpDalHearth:SetSize(25, 25)
rhpDalHearth.Text:SetJustifyH("LEFT")
rhpDalHearth.Text:SetText(" " .. L["DAL_R_CLICK"])
rhpDalHearth.Text:SetTextColor(1, 1, 1, 1)

-- "中键 → 要塞炉石"（锚定到达拉然复选框下方）
rhpGarHearth:SetPoint("TOPLEFT", rhpDalHearth, "BOTTOMLEFT", 0, 0)
rhpGarHearth:SetSize(25, 25)
rhpGarHearth.Text:SetJustifyH("LEFT")
rhpGarHearth.Text:SetText(" " .. L["GAR_M_CLICK"])
rhpGarHearth.Text:SetTextColor(1, 1, 1, 1)

-- 自定义宏名称输入框（锚定到下拉菜单下方）
rhpMacroName:SetPoint("TOPLEFT", rhpDropdown, "BOTTOMLEFT", 25, -15)
rhpMacroName:SetAutoFocus(false)
rhpMacroName:SetSize(208, 20)
rhpMacroName:SetFontObject("GameFontNormal")
rhpMacroName:SetTextColor(1, 1, 1, 1)
rhpMacroName:SetMaxLetters(16)
-- 输入框上方的标签
rhpMacroName.Text = rhpMacroName:CreateFontString(nil, "OVERLAY", "GameFontNormal")
rhpMacroName.Text:SetText(L["OPT_MACRO_NAME"])
rhpMacroName.Text:SetPoint("BOTTOMLEFT", rhpMacroName, "TOPLEFT", 0, 5)
-- 输入框下方的错误提示（名称已被占用时显示）
rhpMacroName.Exist = rhpMacroName:CreateFontString(nil, "OVERLAY", "GameFontNormal")
rhpMacroName.Exist:SetTextColor(1, 0, 0, 1)  -- 红色
rhpMacroName.Exist:SetJustifyH("LEFT")
rhpMacroName.Exist:SetPoint("TOPLEFT", rhpMacroName, "BOTTOMLEFT", 0, -5)
rhpMacroName.Exist:SetText(L["UNIQUE_NAME_ERROR"])
rhpMacroName.Exist:Hide()  -- 初始隐藏
-- 输入框右侧的状态图标（✓ 或 ✗）
rhpMacroName.Icon = rhpMacroName:CreateTexture(nil, "OVERLAY")
rhpMacroName.Icon:SetPoint("LEFT", rhpMacroName, "RIGHT", 5, 0)
rhpMacroName.Icon:SetTexture("Interface/COMMON/CommonIcons.PNG")
rhpMacroName.Icon:SetSize(24, 24)

-- OnShow: 输入框显示时初始化内容和隐藏状态图标
rhpMacroName:SetScript("OnShow", function()
    rhpMacroName.Exist:Hide()
    rhpMacroName.Icon:Hide()
    rhpMacroName:SetText(rhpDB.settings.macroName)
end)

-- OnTextChanged: 输入框文本变化时实时检查名称是否可用
-- 使用 0.5 秒防抖计时器，避免每次按键都触发检查
rhpMacroName:SetScript("OnTextChanged", function(self, userInput)
    if userInput == true then
        if waitTimer ~= true then
            waitTimer = true
            C_Timer.After(0.5, function()
                local name = rhpMacroName:GetText()
                if name ~= rhpDB.settings.macroName and GetMacroIndexByName(name) ~= 0 then
                    -- 名称已被其他宏占用 → 显示红色叉号
                    rhpMacroName.Exist:Show()
                    rhpMacroName.Icon:SetTexCoord(0.25, 0.38, 0, 0.26)  -- 叉号纹理坐标
                    rhpMacroName.Icon:Show()
                elseif string.len(name) == 0 then
                    -- 名称为空 → 隐藏图标
                    rhpMacroName.Icon:Hide()
                else
                    -- 名称可用 → 显示绿色勾号
                    rhpMacroName.Exist:Hide()
                    rhpMacroName.Icon:SetTexCoord(0, 0.13, 0.51, 0.75)  -- 勾号纹理坐标
                    rhpMacroName.Icon:Show()
                end
                waitTimer = false
            end)
        end
    end
end)
-- OnEditFocusLost: 输入框失去焦点 → 检查并保存名称
rhpMacroName:SetScript("OnEditFocusLost", function() checkMacroName() end)
-- OnEnterPressed: 按回车 → 检查并保存名称
rhpMacroName:SetScript("OnEnterPressed", function() checkMacroName() end)

----------------------------------------------------------------------------------------------------------------------
-- 事件监听器（Event Listener）— 插件生命周期管理
--
-- 监听三个关键事件：
--   ADDON_LOADED        → 初始化保存变量、物品数据库、选项面板状态
--   PLAYER_ENTERING_WORLD → 物品数据加载完成后生成可用玩具列表
--   PLAYER_REGEN_ENABLED  → 战斗中挂起的宏更新在脱离战斗后执行
----------------------------------------------------------------------------------------------------------------------

rhpListener:RegisterEvent("ADDON_LOADED")
rhpListener:RegisterEvent("PLAYER_ENTERING_WORLD")
rhpListener:SetScript("OnEvent", function(self, event, arg1)
    -- ========== PLAYER_REGEN_ENABLED：脱离战斗 ==========
    -- 如果之前在战斗中挂起了宏更新，现在执行
    if event == "PLAYER_REGEN_ENABLED" and pendingMacroUpdate then
        pendingMacroUpdate = false
        self:UnregisterEvent("PLAYER_REGEN_ENABLED")
        updateMacro()
        return
    end

    -- ========== ADDON_LOADED：插件加载 ==========
    if event == "ADDON_LOADED" and arg1 == addon then
        -- 首次加载提示
        if rhpDB == nil then
            print(L["SETUP_1"])
            print(L["SETUP_2"])
            print(L["SETUP_3"])
            rhpDB = {}  -- 初始化保存变量表
        end

        -- 使用 rhpInitDB 安全地初始化所有保存变量，保留已有值
        rhpInitDB(rhpDB, "settings", {})
        rhpInitDB(rhpDB.settings, "covOverride", false)
        rhpInitDB(rhpDB.settings, "dalOpt", true)
        rhpInitDB(rhpDB.settings, "garOpt", true)
        rhpInitDB(rhpDB.settings, "macroName", L["MACRO_NAME"])
        rhpInitDB(rhpDB.settings, "loginMsg", "")
        rhpInitDB(rhpDB.settings, "warnMsg", false)
        rhpInitDB(rhpDB, "iconOverride", { name = "Random", icon = 134400 })
        rhpInitDB(rhpDB, "L", {})
        rhpInitDB(rhpDB.L, "locale", GetLocale())

        -- 初始化修饰键绑定存储结构
        -- 结构：rhpDB.settings.modBinds[修饰键][按键编号] = nil / "item:XXXXX" / ItemID数字
        rhpInitDB(rhpDB.settings, "modBinds", {})
        for _, mod in ipairs(MOD_KEYS) do
            if rhpDB.settings.modBinds[mod] == nil then
                rhpDB.settings.modBinds[mod] = {}
            end
            for _, btn in ipairs(BTN_KEYS) do
                if rhpDB.settings.modBinds[mod][btn] == nil then
                    rhpDB.settings.modBinds[mod][btn] = nil  -- nil = 默认随机行为
                end
            end
        end

        -- 首次加载时构建物品数据库（从 rhToys 列表异步加载名称和图标）
        if rhpDB.L.tList == nil then
            wait = true  -- 标记正在等待物品数据加载
            rhpDB.L.tList = {}
            for i = 1, #rhToys do
                local item = Item:CreateFromItemID(rhToys[i])
                item:ContinueOnItemLoad(function()
                    rhpDB.L.tList[rhToys[i]] = {
                        name = item:GetItemName(),
                        icon = item:GetItemIcon(),
                        status = true  -- 默认启用
                    }
                end)
            end
        end

        -- 清除旧的 chkStatus 字段（向后兼容）
        rhpDB.chkStatus = nil

        -- 清理：移除数据库中已不存在于 rhToys 列表的旧物品
        for i, v in pairs(rhpDB.L.tList) do
            local exists = 0
            for l = 1, #rhToys do
                if i == rhToys[l] then
                    exists = 1
                end
            end
            if exists == 0 then
                rhpDB.L.tList[i] = nil
            end
        end

        -- 添加 rhToys 中有但数据库中不存在的新物品（例如插件更新后新增的玩具）
        for i = 1, #rhToys do
            if not rhpDB.L.tList[rhToys[i]] then
                wait = true
                local item = Item:CreateFromItemID(rhToys[i])
                item:ContinueOnItemLoad(function()
                    rhpDB.L.tList[rhToys[i]] = {
                        name = item:GetItemName(),
                        icon = item:GetItemIcon(),
                        status = true  -- 新玩具默认启用
                    }
                    if rhpCheckButtons[rhToys[i]] then
                        rhpCheckButtons[rhToys[i]]:SetChecked(true)
                    end
                    -- 如果是最后一个新物品，触发列表生成
                    if i == #rhToys then
                        listGenerate()
                    end
                end)
            end
        end

        -- 语言环境变更处理：如果玩家切换了客户端语言，更新所有物品名称
        if rhpDB.L.locale ~= GetLocale() then
            -- 更新主列表中的物品名称
            for i, v in pairs(rhpDB.L.tList) do
                local item = Item:CreateFromItemID(i)
                item:ContinueOnItemLoad(function()
                    rhpDB.L.tList[i]["name"] = item:GetItemName()
                end)
            end

            -- 更新图标覆写（如果用户选择了特定玩具图标）
            if rhpDB.iconOverride.id ~= nil then
                local item = Item:CreateFromItemID(rhpDB.iconOverride.id)
                item:ContinueOnItemLoad(function()
                    rhpDB.iconOverride.name = item:GetItemName()
                    rhpDropdown:SetText(rhpDB.iconOverride.name)
                end)
            end

            rhpDB.L.locale = GetLocale()
        end

        -- 根据保存的状态设置所有复选框的初始勾选状态
        for i, v in pairs(rhpDB.L.tList) do
            if rhpCheckButtons[i] then
                rhpCheckButtons[i]:SetChecked(v["status"])
            end
        end

        -- 异步加载达拉然炉石（140192）和要塞炉石（110560）的本地化名称
        -- 这些名称用于 SecureActionButton 的 PreClick 动态物品切换
        local tmp = { { "dalaran", 140192 }, { "garrison", 110560 } }
        for _, v in pairs(tmp) do
            local item = Item:CreateFromItemID(v[2])
            item:ContinueOnItemLoad(function()
                rhpDB.L[v[1]] = item:GetItemName()
            end)
        end

        -- 恢复所有选项控件的显示状态
        rhpOverride:SetChecked(rhpDB.settings.covOverride)
        rhpDalHearth:SetChecked(rhpDB.settings.dalOpt)
        rhpGarHearth:SetChecked(rhpDB.settings.garOpt)
        rhpDropdown.Texture:SetTexture(rhpDB.iconOverride.icon)
        rhpDropdown:SetText(rhpDB.iconOverride.name)
        rhpDropdown:SetupMenu(rhpDropdownGenerator)

        -- 初始化所有修饰键下拉菜单的显示文本
        for _, mod in ipairs(MOD_KEYS) do
            for _, btn in ipairs(BTN_KEYS) do
                rhpModDropdowns[mod][btn]:SetText(getModBindDisplayName(rhpDB.settings.modBinds[mod][btn]))
            end
        end

        -- 注销 ADDON_LOADED 事件，后续不再处理
        self:UnregisterEvent("ADDON_LOADED")
    end

    -- ========== 登录提示消息 ==========
    -- 首次安装或版本升级时显示欢迎信息（仅显示一次）
    if rhpDB and rhpDB.settings.loginMsg ~= loginMsg then
        rhpDB.settings.loginMsg = loginMsg
        print(L["LOGIN_MESSAGE_1"])
        print(L["LOGIN_MESSAGE_2"])
    end

    -- ========== PLAYER_ENTERING_WORLD：进入世界 ==========
    -- 此时物品数据已完全加载，如果不在等待状态则生成可用玩具列表
    if event == "PLAYER_ENTERING_WORLD" then
        if not wait then
            listGenerate()
        end
    end
end)

----------------------------------------------------------------------------------------------------------------------
-- 斜杠命令（Slash Command）— /rhp 打开设置面板
----------------------------------------------------------------------------------------------------------------------
SLASH_RandomHearthstonePlus1 = "/rhp"
function SlashCmdList.RandomHearthstonePlus(msg, editbox)
    Settings.OpenToCategory(rhpCategory:GetID())
end

--[[
    备忘：当 Blizz 再次破坏 API 时参考此文件
    /Interface/SharedXML/Settings/Blizzard_Settings.lua
]]
