#Requires AutoHotkey v2.0+
#SingleInstance Force

global MyGui           := ""
global BtnOpen         := ""
global FoundFiles      := Map()
global CurrentFilePath := ""
global CurrentFileName := ""
global SettingsFile    := A_ScriptDir . "\FileDropSpider_v1.ini"


; --- UI 构建 ---
MyGui := Gui("+Resize +MinSize720x500", "FileDropSpider v1")
MyGui.SetFont("s9", "Microsoft YaHei")

; 第一部分：同名文件目录
Grp1 := MyGui.Add("GroupBox", "x10 y10 w700 h80", "同名文件目录（每行一个路径）")
EditSearchDirs := MyGui.Add("Edit", "vSearchDirs x20 y28 w680 h55 Multi Wrap VScroll")

; 第二部分：文件名列表（完整路径）
global Grp2 := MyGui.Add("GroupBox", "x10 y100 w700 h110", "文件名列表 (完整路径，每行一个)")
EditFileNames := MyGui.Add("Edit", "vFileNames x20 y118 w680 h85 Multi Wrap VScroll")
EditFileNames.OnEvent("Change", UpdateFileNameCount) ; 绑定自动统计

; 第三部分：选项
Grp3 := MyGui.Add("GroupBox", "x10 y215 w700 h50", "移动选项")
ChkOverwrite := MyGui.Add("CheckBox", "vOverwrite x20 y235", "覆盖同名文件（不询问）")

; 第四部分：结果列表
Grp4 := MyGui.Add("GroupBox", "x10 y270 w700 h270", "移动结果")
LV := MyGui.Add("ListView", "vResults x20 y288 w680 h240 ReadOnly Grid", ["序号", "源文件", "目标文件夹", "状态"])

; 分隔线
SplitLine := MyGui.Add("Text", "x10 y528 w700 h2 0x10")

; 第五部分：底部按钮区
BtnSearchSame := MyGui.Add("Button", "w120 h30", "搜索同名文件")
BtnSearchSame.OnEvent("Click", SearchSameFiles)

BtnMoveToSame := MyGui.Add("Button", "w180 h30", "移动到同名文件所在文件夹")
BtnMoveToSame.OnEvent("Click", MoveToSameDir)

SB := MyGui.Add("StatusBar", "vStatus", "就绪 | 输入同名目录→搜索同名文件→移动")

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

DefaultNames := "C:\path\to\file1.mp3`n"
DefaultNames .= "C:\path\to\file2.mp3"

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

; 读取来自 FileDrag 的预置结果
if (A_Args.Length >= 1) {
    TransferFile := A_Args[1]
    if (FileExist(TransferFile))
        LoadTransferResults(TransferFile)
}

; 显示窗口
MyGui.Show("w720 h620")

; --- 新增统计函数 ---
UpdateFileNameCount(GuiCtrlObj, *) {
    global Grp2
    Count := 0
    Loop parse, GuiCtrlObj.Value, "`n", "`r"
    {
        if (Trim(A_LoopField) != "")
            Count++
    }
    Grp2.Text := "文件名列表 (当前待移: " . Count . " 个)"
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
    global SettingsFile, DefaultSearchDirs, DefaultNames, MyGui, EditSearchDirs, EditFileNames

    if !FileExist(SettingsFile)
        return false

    SearchDirs := IniRead(SettingsFile, "Inputs", "SearchDirs", EscapeIniValue(DefaultSearchDirs))
    FileNames := IniRead(SettingsFile, "Inputs", "FileNames", EscapeIniValue(DefaultNames))
    OverwriteValue := IniRead(SettingsFile, "Options", "Overwrite", 0)

    EditSearchDirs.Value := UnescapeIniValue(SearchDirs)
    EditFileNames.Value := UnescapeIniValue(FileNames)
    MyGui["Overwrite"].Value := OverwriteValue

    return true
}

SaveSettings() {
    global SettingsFile, MyGui, EditSearchDirs, EditFileNames

    IniWrite(EscapeIniValue(EditSearchDirs.Value), SettingsFile, "Inputs", "SearchDirs")
    IniWrite(EscapeIniValue(EditFileNames.Value), SettingsFile, "Inputs", "FileNames")
    IniWrite(MyGui["Overwrite"].Value, SettingsFile, "Options", "Overwrite")
}

LoadTransferResults(FilePath) {
    global MyGui

    Text := FileRead(FilePath)
    if (Text = "")
        return

    NewText := ""
    Loop parse, Text, "`n", "`r" {
        Line := Trim(A_LoopField)
        if (Line = "")
            continue
        if (NewText != "")
            NewText .= "`n"
        NewText .= Line
    }

    if (NewText != "") {
        EditFileNames.Value := NewText
        UpdateFileNameCount(EditFileNames)
        MyGui["Status"].SetText("已导入 " . StrSplit(NewText, "`n").Length . " 条来自 FileDrag 的路径")
    }

    FileDelete(FilePath)
}

; ════════════ 核心功能：搜索同名文件 ════════════

SearchSameFiles(*) {
    global MyGui
    MyGui["Status"].SetText("正在搜索同名文件...")

    ; 预处理输入
    Dirs := []
    for d in StrSplit(MyGui["SearchDirs"].Value, "`n", "`r") {
        if (Trim(d) != "")
            Dirs.Push(Trim(d))
    }

    FilePaths := []
    for p in StrSplit(MyGui["FileNames"].Value, "`n", "`r") {
        if (Trim(p) != "")
            FilePaths.Push(Trim(p))
    }

    if (Dirs.Length = 0 || FilePaths.Length = 0) {
        MyGui["Status"].SetText("就绪 | 请输入同名文件目录和文件路径")
        return
    }

    LV := MyGui["Results"]
    LV.Opt("-Redraw")
    LV.Delete()

    Index := 1, FoundCount := 0, MissedCount := 0

    for FilePath in FilePaths {
        if !FileExist(FilePath) {
            LV.Add("", Index, FilePath, "", "源文件不存在")
            Index++
            continue
        }

        SplitPath FilePath, &FileName
        SplitPath FileName, , , &Ext, &NameNoExt
        TargetFolder := ""
        Found := false

        for DirPath in Dirs {
            if !DirExist(DirPath)
                continue

            Loop Files, DirPath . "\*.*", "R" {
                SplitPath A_LoopFileName, , , &TargetExt, &TargetNameNoExt
                if (TargetNameNoExt = NameNoExt) {
                    TargetFolder := A_LoopFileDir
                    Found := true
                    break
                }
            }
            if Found
                break
        }

        if Found {
            LV.Add("", Index, FilePath, TargetFolder, "已找到")
            FoundCount++
        } else {
            LV.Add("", Index, FilePath, "", "未找到匹配目标")
            MissedCount++
        }

        Index++
    }

    LV.Opt("+Redraw")
    MyGui["Status"].SetText("搜索完成：找到 " . FoundCount . " 个，未找到 " . MissedCount . " 个")
}

MoveToSameDir(*) {
    global MyGui
    MyGui["Status"].SetText("正在移动到同名文件所在文件夹...")

    Overwrite := MyGui["Overwrite"].Value
    LV := MyGui["Results"]

    Moved := 0, Skipped := 0, Failed := 0

    Loop LV.GetCount() {
        Row := A_Index
        SourcePath := LV.GetText(Row, 2)
        TargetFolder := LV.GetText(Row, 3)
        StatusText := LV.GetText(Row, 4)

        if (SourcePath = "") || (TargetFolder = "") {
            continue
        }

        SplitPath SourcePath, &FileName
        DestPath := TargetFolder . "\" . FileName

        if FileExist(DestPath) {
            if !Overwrite {
                LV.Modify(Row, "Col4", "跳过（目标存在）")
                Skipped++
                continue
            }
        }

        try {
            FileMove(SourcePath, DestPath)
            LV.Modify(Row, "Col4", "已移动")
            Moved++
        } catch Error as e {
            LV.Modify(Row, "Col4", "移动失败: " . e.Message)
            Failed++
        }
    }

    MyGui["Status"].SetText("移动完成：成功 " . Moved . " 个，跳过 " . Skipped . " 个，失败 " . Failed . " 个")
}

; ════════════ 布局自适应 ════════════

GuiSize(GuiObj, MinMax, Width, Height, *) {
    if (MinMax = -1) {
        return
    }

    global MyGui, Grp1, Grp2, Grp3, Grp4, SplitLine

    local W_Margin := Width - 20
    local W_Inner  := Width - 40

    try {
        Grp1.Move(,, W_Margin)
        MyGui["SearchDirs"].Move(,, W_Inner)
        Grp2.Move(,, W_Margin)
        MyGui["FileNames"].Move(,, W_Inner)
        Grp3.Move(,, W_Margin)
    }

    local LV_Height := Height - 330 - 90
    if (LV_Height < 100) {
        LV_Height := 100
    }

    try {
        Grp4.Opt("-Redraw")
        MyGui["Results"].Opt("-Redraw")

        Grp4.Move(10, 270, W_Margin, LV_Height + 40)
        MyGui["Results"].Move(20, 290, W_Inner, LV_Height)

        Grp4.Opt("+Redraw")
        MyGui["Results"].Opt("+Redraw")
    }

    local LineY := Height - 80
    local BtnY  := Height - 70

    try {
        SplitLine.Move(10, LineY, W_Margin)
        BtnSearchSame.Move(10, BtnY)
        BtnMoveToSame.Move(138, BtnY)
    }

    DllCall("InvalidateRect", "ptr", GuiObj.Hwnd, "ptr", 0, "int", 1)
}

; ════════════ 其他函数 ════════════

ResultsDoubleClick(LV, Row, *) {
    if (Row > 0) {
        Path := LV.GetText(Row, 2)
        if FileExist(Path)
            Run('explorer /select,"' . Path . '"')
        else {
            Dir := LV.GetText(Row, 3)
            if DirExist(Dir)
                Run('explorer "' . Dir . '"')
        }
    }
}

ResultsContextMenu(LV, Row, X, Y, *) {
    if (Row > 0) {
        Path := LV.GetText(Row, 2)
        Dir := LV.GetText(Row, 3)
        CtxMenu := Menu()
        if FileExist(Path) {
            CtxMenu.Add("打开源文件", (*) => Run('"' . Path . '"'))
            CtxMenu.Add("在资源管理器定位源文件", (*) => Run('explorer /select,"' . Path . '"'))
        }
        if DirExist(Dir) {
            CtxMenu.Add("打开目标文件夹", (*) => Run('explorer "' . Dir . '"'))
        }
        CtxMenu.Add("复制源路径", (*) => A_Clipboard := Path)
        CtxMenu.Add("复制目标路径", (*) => A_Clipboard := Dir)
        CtxMenu.Show()
    }
}

GuiClose(*) {
    SaveSettings()
    ExitApp()
}