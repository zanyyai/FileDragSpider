#Requires AutoHotkey v2.0+
#SingleInstance Force

global MyGui           := ""
global BtnOpen         := ""
global FoundFiles      := Map()
global CurrentFilePath := ""
global CurrentFileName := ""
global TempDir         := ""
global SettingsFile    := A_ScriptDir . "\FileDragSpider_v1.ini"


; --- UI 构建 ---
MyGui := Gui("+Resize +MinSize720x760", "FileDragSpider v1")
MyGui.SetFont("s9", "Microsoft YaHei")

; 第一部分：搜索目录
Grp1 := MyGui.Add("GroupBox", "x10 y10 w700 h80", "搜索目录（每行一个路径）")
EditSearchDirs := MyGui.Add("Edit", "vSearchDirs x20 y28 w680 h55 Multi Wrap VScroll")

; 第二部分：文件名列表
global Grp2 := MyGui.Add("GroupBox", "x10 y100 w700 h110", "文件名列表 (统计中...)")
EditFileNames := MyGui.Add("Edit", "vFileNames x20 y118 w680 h85 Multi Wrap VScroll")
EditFileNames.OnEvent("Change", UpdateFileNameCount) ; 绑定自动统计

; 第三部分：同名文件目录
Grp5 := MyGui.Add("GroupBox", "x10 y220 w700 h80", "同名文件目录（每行一个路径）")
EditSameDirs := MyGui.Add("Edit", "vSameDirs x20 y238 w680 h55 Multi Wrap VScroll")

; 第四部分：选项
Grp3 := MyGui.Add("GroupBox", "x10 y305 w700 h50", "搜索选项")
ChkCase  := MyGui.Add("CheckBox", "vCaseSensitive x20 y325", "区分大小写")
ChkExact := MyGui.Add("CheckBox", "vExactMatch x160 y325", "精确匹配（完整文件名）")

; 第五部分：结果列表
Grp4 := MyGui.Add("GroupBox", "x10 y360 w700 h270", "搜索结果（勾选需要处理的文件）")
LV := MyGui.Add("ListView", "vResults x20 y378 w680 h240 ReadOnly Grid Checked", ["序号", "搜索文件名", "文件名", "大小", "路径", "同名文件路径"])

; 分隔线
SplitLine := MyGui.Add("Text", "x10 y640 w700 h2 0x10") ; 分隔线

; 第六部分：底部按钮区
BtnSearch := MyGui.Add("Button", "w90 h30", "搜索")
BtnSearch.OnEvent("Click", SearchFiles)

BtnAll := MyGui.Add("Button", "w70 h30", "全选")
BtnAll.OnEvent("Click", SelectAll)

BtnInv := MyGui.Add("Button", "w70 h30", "反选")
BtnInv.OnEvent("Click", InvertSelection)

BtnClr := MyGui.Add("Button", "w70 h30", "清除")
BtnClr.OnEvent("Click", ClearSelection)

BtnLink := MyGui.Add("Button", "w200 h30", "集中到临时文件夹(硬链接)")
BtnLink.OnEvent("Click", LinkToTemp)

BtnOpen := MyGui.Add("Button", "w162 h30", "打开临时文件夹")
BtnOpen.OnEvent("Click", OpenTemp)
BtnOpen.Enabled := false

BtnSwitch := MyGui.Add("Button", "w120 h30", "打开 FileDrop")
BtnSwitch.OnEvent("Click", SwitchToFileDrop)
BtnSwitch.Enabled := false

; 新增按钮
BtnSearchSame := MyGui.Add("Button", "w120 h30", "搜索同名文件")
BtnSearchSame.OnEvent("Click", SearchSameFiles)

BtnMoveToSame := MyGui.Add("Button", "w180 h30", "移动到同名文件所在文件夹")
BtnMoveToSame.OnEvent("Click", MoveToSameDir)

SB := MyGui.Add("StatusBar", "vStatus", "就绪 | 搜索→勾选→集中→拖入目标软件")

; --- 初始赋值 ---
DefaultSearchDirs := 
(
"
E:\证据和法规\电子证据
E:\证据和法规\电子证据\录音
E:\证据和法规\电子证据\video
E:\证据和法规\电子证据\录像
"
)

DefaultNames := "20260126152755.mp3`n"
DefaultNames .= "20260126105753.mp3`n"
DefaultNames .= "20260126103936.mp3`n"
DefaultNames .= "20260126091940.mp3`n"
DefaultNames .= "20260126091201.mp3`n"
DefaultNames .= "20260122164849.mp3"

if !LoadSettings() {
    EditSearchDirs.Value := DefaultSearchDirs
    EditFileNames.Value := DefaultNames
}

; 初始化统计一次
UpdateFileNameCount(EditFileNames)

; --- 事件绑定 ---
LV.OnEvent("DoubleClick", ResultsDoubleClick)
LV.OnEvent("ContextMenu", ResultsContextMenu)
MyGui.OnEvent("Close", GuiClose)
MyGui.OnEvent("Size", GuiSize)

; 显示窗口
MyGui.Show("w720 h760")

; --- 新增统计函数 ---
UpdateFileNameCount(GuiCtrlObj, *) {
    global Grp2
    Count := 0
    Loop parse, GuiCtrlObj.Value, "`n", "`r"
    {
        if (Trim(A_LoopField) != "")
            Count++
    }
    Grp2.Text := "文件名列表 (当前待搜: " . Count . " 个)"
}

EscapeIniValue(Value) {
    ; 将实际换行编码为显式 \n 标记，避免 INI 单行值被截断
    Value := StrReplace(Value, "`r`n", "\\n")
    Value := StrReplace(Value, "`n", "\\n")
    return Value
}

UnescapeIniValue(Value) {
    return StrReplace(Value, "\\n", "`n")
}

LoadSettings() {
    global SettingsFile, DefaultSearchDirs, DefaultNames, MyGui, EditSearchDirs, EditFileNames, EditSameDirs

    if !FileExist(SettingsFile)
        return false

    SearchDirs := IniRead(SettingsFile, "Inputs", "SearchDirs", EscapeIniValue(DefaultSearchDirs))
    FileNames := IniRead(SettingsFile, "Inputs", "FileNames", EscapeIniValue(DefaultNames))
    SameDirs := IniRead(SettingsFile, "Inputs", "SameDirs", "")
    CaseValue := IniRead(SettingsFile, "Options", "CaseSensitive", 0)
    ExactValue := IniRead(SettingsFile, "Options", "ExactMatch", 0)

    EditSearchDirs.Value := UnescapeIniValue(SearchDirs)
    EditFileNames.Value := UnescapeIniValue(FileNames)
    EditSameDirs.Value := UnescapeIniValue(SameDirs)
    MyGui["CaseSensitive"].Value := CaseValue
    MyGui["ExactMatch"].Value := ExactValue

    return true
}

SaveSettings() {
    global SettingsFile, MyGui, EditSearchDirs, EditFileNames, EditSameDirs

    IniWrite(EscapeIniValue(EditSearchDirs.Value), SettingsFile, "Inputs", "SearchDirs")
    IniWrite(EscapeIniValue(EditFileNames.Value), SettingsFile, "Inputs", "FileNames")
    IniWrite(EscapeIniValue(EditSameDirs.Value), SettingsFile, "Inputs", "SameDirs")
    IniWrite(MyGui["CaseSensitive"].Value, SettingsFile, "Options", "CaseSensitive")
    IniWrite(MyGui["ExactMatch"].Value, SettingsFile, "Options", "ExactMatch")
}

; ════════════ 核心优化：布局自适应 ════════════

GuiSize(GuiObj, MinMax, Width, Height, *) {
    ; 1. 将 If 语句改为标准块格式，严禁写在同一行
    if (MinMax = -1) {
        return
    }
    
    ; 2. 确保 global 关键字后面没有非法字符
    global MyGui, BtnSearch, BtnAll, BtnInv, BtnClr, BtnLink, BtnOpen, BtnSwitch, BtnSearchSame, BtnMoveToSame
    global Grp1, Grp2, Grp3, Grp4, Grp5, SplitLine

    ; 3. 这里的 W_Margin 等变量建议直接计算，避开全角空格隐患
    local W_Margin := Width - 20
    local W_Inner  := Width - 40

    try {
        Grp1.Move(,, W_Margin)
        MyGui["SearchDirs"].Move(,, W_Inner)
        Grp2.Move(10, 100, W_Margin)
        MyGui["FileNames"].Move(20, 118, W_Inner)
        Grp5.Move(10, 220, W_Margin)
        MyGui["SameDirs"].Move(20, 238, W_Inner)
        Grp3.Move(10, 305, W_Margin)
    }

    ; 计算 ListView 高度：固定为240
    local LV_Height := 240

    try {
        ; 移动前关闭重绘，防止“拉花”
        Grp4.Opt("-Redraw")
        MyGui["Results"].Opt("-Redraw")
        
        Grp4.Move(10, 360, W_Margin, 270)
        MyGui["Results"].Move(20, 378, W_Inner, LV_Height)
        
        Grp4.Opt("+Redraw")
        MyGui["Results"].Opt("+Redraw")
    }

    ; 底部锁定
    local LineY := 640
    local BtnY  := 650
    local BtnY2 := 690

    try {
        SplitLine.Move(10, LineY, W_Margin)
        BtnSearch.Move(10, BtnY)
        BtnAll.Move(108, BtnY)
        BtnInv.Move(185, BtnY)
        BtnClr.Move(262, BtnY)
        BtnLink.Move(340, BtnY)
        BtnOpen.Move(550, BtnY)
        BtnSwitch.Move(10, BtnY2)
        BtnSearchSame.Move(140, BtnY2)
        BtnMoveToSame.Move(270, BtnY2)
    }
    
    ; 4. 强制刷新，防止按钮变花
    DllCall("InvalidateRect", "ptr", GuiObj.Hwnd, "ptr", 0, "int", 1)
}


; ════════════ 后续功能函数 (保持不变) ════════════

GetCheckedPaths() {
    global MyGui
    LV    := MyGui["Results"]
    Paths := []
    Row   := 0
    loop {
        Row := LV.GetNext(Row, "Checked")
        if !Row
            break
        Paths.Push(LV.GetText(Row, 5))
    }
    return Paths
}

SearchFiles(*) {
    global MyGui, FoundFiles
    MyGui["Status"].SetText("正在搜索...")
    
    ; 1. 预处理输入：去除空行并修剪空白
    Dirs := []
    for d in StrSplit(MyGui["SearchDirs"].Value, "`n", "`r") {
        if (Trim(d) != "") 
            Dirs.Push(Trim(d))
    }
    
    Names := []
    for n in StrSplit(MyGui["FileNames"].Value, "`n", "`r") {
        if (Trim(n) != "") 
            Names.Push(Trim(n))
    }

    ; 如果输入为空，直接返回
    if (Dirs.Length = 0 || Names.Length = 0) {
        MyGui["Status"].SetText("就绪 | 请输入目录和文件名")
        return
    }

    CaseSensitive := MyGui["CaseSensitive"].Value
    ExactMatch    := MyGui["ExactMatch"].Value
    
    LV := MyGui["Results"]
    LV.Opt("-Redraw") ; 【优化】禁用重绘，防止添加大量数据时闪烁
    LV.Delete()
    FoundFiles.Clear()
    
    Index := 1, Total := 0
    
    for n in Names {
        Found := false
        SearchFileName := n
        SearchNameOnly := n
        SplitPath n, &SearchNameOnly
        if (SearchNameOnly != "")
            SearchFileName := SearchNameOnly
        FoundFileName := ""
        FoundPath := ""
        FoundSize := ""
        
        for DirPath in Dirs {
            if !DirExist(DirPath)
                continue
            
            Loop Files, DirPath . "\*.*", "R" {
                Total++
                fn := A_LoopFileName
                matched := false
                
                if ExactMatch {
                    if (StrCompare(fn, SearchNameOnly, CaseSensitive ? "On" : "Off") = 0)
                        matched := true
                } else {
                    if (InStr(fn, SearchNameOnly, CaseSensitive) > 0)
                        matched := true
                }
                
                if matched {
                    Found := true
                    FoundFileName := fn
                    FoundPath := A_LoopFileFullPath
                    FoundSize := (A_LoopFileSize > 1048576) ? Round(A_LoopFileSize / 1048576, 2) . " MB" : 
                                 (A_LoopFileSize > 1024) ? Round(A_LoopFileSize / 1024, 2) . " KB" : A_LoopFileSize . " B"
                    break
                }
            }
            if Found
                break
        }
        
        if Found {
            row := LV.Add("Check", Index, SearchFileName, FoundFileName, FoundSize, FoundPath)
            FoundFiles[Index] := {path: FoundPath, name: FoundFileName, size: FoundSize}
        } else {
            row := LV.Add("Check", Index, SearchFileName, "", "", "")
        }
        Index++
    }
    
    LV.Opt("+Redraw") ; 【优化】恢复重绘
    BtnSwitch.Enabled := (LV.GetCount() > 0)
    MyGui["Status"].SetText("搜索完成：匹配 " . (Index - 1) . " 条，扫描 " . Total . " 个文件")
}
SelectAll(*) {
    global MyGui
    LV := MyGui["Results"]
    Loop LV.GetCount()
        LV.Modify(A_Index, "Check")
    MyGui["Status"].SetText("已全选")
}

InvertSelection(*) {
    global MyGui
    LV := MyGui["Results"]
    Loop LV.GetCount() {
        if (LV.GetNext(A_Index - 1, "Checked") = A_Index)
            LV.Modify(A_Index, "-Check")
        else
            LV.Modify(A_Index, "Check")
    }
    MyGui["Status"].SetText("已反选")
}

ClearSelection(*) {
    global MyGui
    LV := MyGui["Results"]
    Loop LV.GetCount()
        LV.Modify(A_Index, "-Check")
    MyGui["Status"].SetText("已清除勾选")
}

LinkToTemp(*) {
    global MyGui, TempDir, BtnOpen
    Paths := GetCheckedPaths()
    if (Paths.Length = 0) {
        MsgBox("请先勾选要处理的文件！", "提示", 48)
        return
    }
    if (TempDir != "") && DirExist(TempDir)
        CleanTempDir()

    TempDir := A_Temp . "\FileCollect_" . FormatTime(, "yyyyMMdd_HHmmss")
    DirCreate(TempDir)
    
    Linked := 0, Copied := 0, Failed := 0, ErrMsg := ""

    for FilePath in Paths {
        ; 使用内置 SplitPath 更加稳健
        SplitPath FilePath, &FileName, , &Ext, &NameNoExt
        Dest := TempDir . "\" . FileName
        
        ; 处理同名文件逻辑（例如不同文件夹下有两个同名录音）
        if FileExist(Dest) {
            n := 2
            while FileExist(TempDir . "\" . NameNoExt . "_" . n . "." . Ext)
                n++
            Dest := TempDir . "\" . NameNoExt . "_" . n . "." . Ext
        }

        ; 尝试硬链接 (mklink /H)
        ExitCode := RunWait('cmd /c mklink /H "' . Dest . '" "' . FilePath . '"', , "Hide")
        
        if (ExitCode = 0) && FileExist(Dest) {
            Linked++
        } else {
            ; 如果硬链接失败（比如跨磁盘分区），则回退到直接复制
            try {
                FileCopy(FilePath, Dest)
                Copied++
            } catch Error as e {
                Failed++
                ErrMsg .= FileName . "`n"
            }
        }
    }

    BtnOpen.Enabled := true
    StatusTxt := "就绪：硬链接 " . Linked . " 个"
    if (Copied > 0) StatusTxt .= "，复制 " . Copied . " 个"
    if (Failed > 0) StatusTxt .= "，失败 " . Failed . " 个"
    
    MyGui["Status"].SetText(StatusTxt)
    Run('explorer "' . TempDir . '"')
    
    Msg := "集中完成！`n`n硬链接（零占空间）：" . Linked . " 个`n"
    if (Copied > 0) Msg .= "复制（跨盘降级）：" . Copied . " 个`n"
    if (Failed > 0) Msg .= "失败：" . Failed . " 个`n失败文件：`n" . ErrMsg
    Msg .= "`n临时文件夹已打开，请直接全选拖入软件。"
    
    MsgBox(Msg, "任务完成", 64)
}

OpenTemp(*) {
    global MyGui, TempDir
    if (TempDir != "") && DirExist(TempDir)
        Run('explorer "' . TempDir . '"')
    else
        MyGui["Status"].SetText("临时文件夹不存在，请重新集中")
}

SwitchToFileDrop(*) {
    global MyGui

    LV := MyGui["Results"]
    if (LV.GetCount() = 0)
        return

    TempFile := A_Temp . "\FileDragSpider_Results_" . FormatTime(, "yyyyMMdd_HHmmss") . ".txt"
    if FileExist(TempFile)
        FileDelete(TempFile)

    Loop LV.GetCount() {
        SourceFile := LV.GetText(A_Index, 5)
        if (Trim(SourceFile) = "")
            continue

        FileAppend(SourceFile . "`n", TempFile)
    }

    if !FileExist(TempFile)
        return

    DropExe := A_ScriptDir . "\FileDropSpider_v1.exe"
    DropAhk := A_ScriptDir . "\FileDropSpider_v1.ahk"

    if FileExist(DropExe) {
        Run('"' . DropExe . '" "' . TempFile . '"')
    } else if FileExist(DropAhk) {
        Run('"' . DropAhk . '" "' . TempFile . '"')
    } else {
        MsgBox("未找到 FileDropSpider_v1.exe 或 FileDropSpider_v1.ahk，请检查文件是否在同一文件夹下。", "错误", 16)
    }
}

SearchSameFiles(*) {
    global MyGui, FoundFiles
    MyGui["Status"].SetText("正在搜索同名文件...")

    ; 获取文件名列表
    Names := []
    for n in StrSplit(MyGui["FileNames"].Value, "`n", "`r") {
        if (Trim(n) != "") {
            SplitPath n, &nameOnly
            if (nameOnly != "")
                Names.Push(nameOnly)
            else
                Names.Push(n)
        }
    }

    ; 获取同名文件目录
    SameDirs := []
    for d in StrSplit(MyGui["SameDirs"].Value, "`n", "`r") {
        if (Trim(d) != "")
            SameDirs.Push(Trim(d))
    }

    if (Names.Length = 0 || SameDirs.Length = 0) {
        MyGui["Status"].SetText("请输入文件名列表和同名文件目录")
        return
    }

    LV := MyGui["Results"]
    LV.Opt("-Redraw")

    ; 遍历结果行，查找同名文件
    Loop LV.GetCount() {
        Row := A_Index
        SearchName := LV.GetText(Row, 2)
        if (SearchName == "")
            continue

        FoundSamePath := ""
        for DirPath in SameDirs {
            if !DirExist(DirPath)
                continue

            Loop Files, DirPath . "\*.*", "R" {
                SplitPath A_LoopFileName, , , , &nameNoExt
                if (nameNoExt == SearchName) {
                    FoundSamePath := A_LoopFilePath
                    break
                }
            }
            if (FoundSamePath != "")
                break
        }

        LV.Modify(Row, "Col6", FoundSamePath)
    }

    LV.Opt("+Redraw")
    BtnSwitch.Enabled := (LV.GetCount() > 0)
    MyGui["Status"].SetText("同名文件搜索完成")
}

MoveToSameDir(*) {
    global MyGui
    Paths := GetCheckedPaths()
    if (Paths.Length = 0) {
        MsgBox("请先勾选要移动的文件！", "提示", 48)
        return
    }

    LV := MyGui["Results"]
    Moved := 0, Failed := 0

    for Path in Paths {
        ; 找到对应行
        Row := 0
        Loop LV.GetCount() {
            if (LV.GetText(A_Index, 5) == Path) {
                Row := A_Index
                break
            }
        }
        if (Row == 0)
            continue

        SamePath := LV.GetText(Row, 6)
        if (SamePath == "") {
            Failed++
            continue
        }

        SplitPath SamePath, &sameFileName, &sameFileDir
        if (sameFileDir == "") {
            Failed++
            continue
        }

        SplitPath Path, &FileName
        DestPath := sameFileDir . "\" . FileName

        if FileExist(DestPath) {
            Ans := MsgBox("目标位置已存在文件：" . DestPath . "`n是否覆盖？", "确认覆盖", "YesNo")
            if (Ans != "Yes") {
                Failed++
                continue
            }
        }

        try {
            FileMove(Path, DestPath)
            Moved++
        } catch Error as e {
            Failed++
        }
    }

    MyGui["Status"].SetText("移动完成：成功 " . Moved . " 个，失败 " . Failed . " 个")
}

ResultsDoubleClick(LV, Row, *) {
    if (Row > 0)
        Run('explorer /select,"' . LV.GetText(Row, 5) . '"')
}

ResultsContextMenu(LV, Row, X, Y, *) {
    global CurrentFilePath, CurrentFileName
    if (Row > 0) {
        CurrentFilePath := LV.GetText(Row, 5)
        CurrentFileName := LV.GetText(Row, 3)
        CtxMenu := Menu()
        CtxMenu.Add("打开文件",        MenuOpenFile)
        CtxMenu.Add("在资源管理器定位", MenuOpenDir)
        CtxMenu.Add("复制完整路径",    MenuCopyPath)
        CtxMenu.Add("复制文件名",      MenuCopyName)
        CtxMenu.Show()
    }
}

MenuOpenFile(*) {
    global CurrentFilePath
    Run('"' . CurrentFilePath . '"')
}
MenuOpenDir(*) {
    global CurrentFilePath
    Run('explorer /select,"' . CurrentFilePath . '"')
}
MenuCopyPath(*) {
    global CurrentFilePath
    A_Clipboard := CurrentFilePath
}
MenuCopyName(*) {
    global CurrentFileName
    A_Clipboard := CurrentFileName
}

GuiClose(*) {
    global TempDir
    SaveSettings()
    if (TempDir != "") && DirExist(TempDir) {
        Ans := MsgBox("是否删除临时文件夹？`n`n" . TempDir . "`n`n（删除不影响原始文件）",
            "关闭确认", "YesNo Icon?")
        if (Ans = "Yes")
            CleanTempDir()
    }
    ExitApp()
}

CleanTempDir() {
    global TempDir, BtnOpen
    if (TempDir = "") || !DirExist(TempDir)
        return
    try {
        Loop Files, TempDir . "\*.*" {
            FileDelete(A_LoopFileFullPath)
        }
        DirDelete(TempDir)
    } catch Error as e {
        ; 静默跳过
    }
    TempDir := ""
    BtnOpen.Enabled := false
}

