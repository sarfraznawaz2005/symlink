#Requires AutoHotkey v2.0+
#SingleInstance Force
#Warn
#NoTrayIcon

; Main Application - GUI for managing pre-defined names and context menu

#Include ini_manager.ahk
#Include registry_manager.ahk

; Set taskbar/window icon (shortcut/link icon from shell32.dll)
TraySetIcon("shell32.dll", 147)

; Auto-elevate to admin if not already running as admin
if not A_IsAdmin {
    try {
        Run('*RunAs "' A_AhkPath '" "' A_ScriptFullPath '"')
    } catch as err7 {
        MsgBox("Failed to elevate to administrator privileges. Some features may not work.`n`nError: " err7.Message, "Symlink Creator", "Icon!")
    }
    ExitApp()
}

; Global logging
LOG_DEBUG := A_ScriptDir "\debug.log"

; Delete debug.log at startup
try FileDelete(LOG_DEBUG)

LogDebug(msg) {
    ;FileAppend(Format("[{1}] DEBUG: {2}`n", A_Now, msg), LOG_DEBUG)
}

; Initialize and show main GUI
Main() {
    global MainGui, LVNames, EditNewName, BtnAdd, BtnDelete, BtnToggleMenu, TxtStatus
    
    LogDebug("Main app started (Admin: " A_IsAdmin ")")
    
    ; Create main GUI
    MainGui := Gui("", "Symlink Creator - Configuration")
    MainGui.SetFont("s10", "Segoe UI")
    MainGui.BackColor := "FFFFFF"
    
    ; Title with explicit height to prevent cutting off
    MainGui.AddText("xm ym w500 h30 Center", "Symlink Creator").SetFont("s16 Bold")
    MainGui.AddText("xm y+10 w500 h20 Center", "Create symbolic links via right-click context menu").SetFont("s9 cGray")
    
    ; Pre-defined names section
    MainGui.AddGroupBox("xm y+20 w500 h340", "Pre-defined File Names")
    
    ; ListView for pre-defined names
    MainGui.AddText("xp+10 yp+25", "Saved names for quick symlink creation:")
    LVNames := MainGui.AddListView("xp y+5 w470 h170", ["Pre-defined Names"])
    LVNames.ModifyCol(1, 450)
    
    ; Add new name section - both edit and button on same line inside frame
    MainGui.AddText("xp y+10", "Add new pre-defined name:")
    EditNewName := MainGui.AddEdit("xp y+5 w350 h30 vNewName Section")
    BtnAdd := MainGui.AddButton("x+10 yp w100 h30", "➕ Add")
    BtnAdd.OnEvent("Click", OnAddClick)

    ; Delete button - positioned inside the GroupBox frame, aligned left
    BtnDelete := MainGui.AddButton("xs y+8 w120 Disabled", "🗑️ Delete")
    BtnDelete.OnEvent("Click", OnDeleteClick)
    
    ; Enable delete button when item selected in ListView
    LVNames.OnEvent("ItemSelect", OnItemSelect)
    
    ; Context menu section
    MainGui.AddGroupBox("xm y+30 w500 h120", "Context Menu")
    
    ; Status text
    isRegistered := IsContextMenuRegistered()
    statusText := isRegistered ? "Status: Registered" : "Status: Not Registered"
    statusColor := isRegistered ? "cGreen" : "cRed"
    TxtStatus := MainGui.AddText("xp+10 yp+25 w480", statusText)
    TxtStatus.SetFont("s10 Bold " statusColor)
    
    ; Info text
    MainGui.AddText("xp y+10 w480", "Right-click on files or folders to see 'Symlink File' option")

    ; Register/Unregister toggle button
    toggleText := isRegistered ? "➖ Unregister Menu" : "➕ Register Menu"
    BtnToggleMenu := MainGui.AddButton("xp y+10 w180", toggleText)
    BtnToggleMenu.OnEvent("Click", OnToggleMenuClick)
    
    ; Load pre-defined names
    RefreshListView()
    
    ; Show GUI
    MainGui.Show("AutoSize Center")
    LogDebug("Main GUI displayed")
}

; Refresh ListView with pre-defined names
RefreshListView() {
    global LVNames
    LVNames.Delete()
    names := LoadPredefinedNames()
    for name in names {
        LVNames.Add(, name)
    }
    LogDebug("Refreshed ListView with " names.Length " names")
}

; Update status text and toggle button
UpdateStatus() {
    global TxtStatus, BtnToggleMenu
    isRegistered := IsContextMenuRegistered()
    if (isRegistered) {
        TxtStatus.Value := "Status: Registered"
        TxtStatus.SetFont("cGreen")
        BtnToggleMenu.Text := "➖ Unregister Menu"
    } else {
        TxtStatus.Value := "Status: Not Registered"
        TxtStatus.SetFont("cRed")
        BtnToggleMenu.Text := "➕ Register Menu"
    }
}

; Handle ListView item selection - enable/disable delete button
OnItemSelect(LV, RowNum, *) {
    global BtnDelete
    if (RowNum > 0) {
        BtnDelete.Enabled := true
    } else {
        BtnDelete.Enabled := false
    }
}

; Add button click handler
OnAddClick(*) {
    global EditNewName
    name := EditNewName.Value
    
    if (name == "") {
        MsgBox("Please enter a name", "Symlink Creator", "Icon!")
        return
    }
    
    ; Validate name
    if (!IsValidFileName(name)) {
        MsgBox("Invalid filename. Cannot contain: < > : `" / \ | ? *", "Symlink Creator", "Icon!")
        return
    }
    
    ; Check if already exists
    names := LoadPredefinedNames()
    for existing in names {
        if (existing == name) {
            MsgBox("This name already exists", "Symlink Creator", "Icon!")
            return
        }
    }
    
    ; Add to INI
    if (AddPredefinedName(name)) {
        EditNewName.Value := ""
        RefreshListView()
        LogDebug("Added new pre-defined name: " name)
    } else {
        MsgBox("Failed to add name", "Symlink Creator", "Icon!")
    }
}

; Delete button click handler
OnDeleteClick(*) {
    global LVNames, BtnDelete
    row := LVNames.GetNext()
    if (row == 0) {
        MsgBox("Please select a name to delete", "Symlink Creator", "Icon!")
        return
    }

    name := LVNames.GetText(row, 1)

    result := MsgBox("Are you sure you want to delete '" name "'?", "Confirm Delete", "Icon? YesNo")
    if (result == "Yes") {
        if (DeletePredefinedName(name)) {
            RefreshListView()
            BtnDelete.Enabled := false  ; Disable after deletion
            LogDebug("Deleted pre-defined name: " name)
        } else {
            MsgBox("Failed to delete name", "Symlink Creator", "Icon!")
        }
    }
}

; Toggle context menu registration
OnToggleMenuClick(*) {
    if (IsContextMenuRegistered()) {
        LogDebug("Unregistering context menu")
        result := UnregisterContextMenu()
        if (result.success) {
            MsgBox("Context menu unregistered successfully!", "Symlink Creator", "Iconi")
            UpdateStatus()
        } else {
            MsgBox("Failed to unregister context menu.`n`n" result.error "`n`nPlease run as administrator.", "Symlink Creator", "Icon!")
        }
    } else {
        LogDebug("Registering context menu")
        result := RegisterContextMenu()
        if (result.success) {
            MsgBox("Context menu registered successfully!`n`nYou can now right-click on files and folders to create symlinks.", "Symlink Creator", "Iconi")
            UpdateStatus()
        } else {
            MsgBox("Failed to register context menu.`n`n" result.error "`n`nPlease run as administrator.", "Symlink Creator", "Icon!")
        }
    }
}

; Validate filename
IsValidFileName(name) {
    invalidChars := '<>"/\|?*'
    Loop Parse, invalidChars {
        if InStr(name, A_LoopField) {
            return false
        }
    }
    return true
}

; Run main function
Main()
