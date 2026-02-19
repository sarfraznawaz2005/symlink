#Requires AutoHotkey v2.0+
#SingleInstance Force
#Warn
#NoTrayIcon

; Context Menu Handler - Called when user right-clicks and selects "Symlink File"

; Set taskbar/window icon (same as main app)
TraySetIcon("shell32.dll", 147)

global LOG_DEBUG := A_ScriptDir "\debug.log"

; Delete debug.log at startup
try FileDelete(LOG_DEBUG)

LogDebug(msg) {
    ;FileAppend(Format("[{1}] DEBUG: {2}`n", A_Now, msg), LOG_DEBUG)
}

; Main entry point - called with target path as argument
Main() {
    LogDebug("Context menu handler started")
    
    ; Get target path from command line
    if (A_Args.Length < 1) {
        LogDebug("No target path provided")
        MsgBox("Error: No target path provided", "Symlink Creator", "Icon!")
        return
    }
    
    targetPath := A_Args[1]
    LogDebug("Target path: " targetPath)
    
    ; Validate target exists
    if (!FileExist(targetPath) && !DirExist(targetPath)) {
        LogDebug("Target does not exist: " targetPath)
        MsgBox("Error: Target file or folder does not exist", "Symlink Creator", "Icon!")
        return
    }
    
    ; Get directory of target
    SplitPath(targetPath,, &targetDir)
    SplitPath(targetPath, &targetName)
    
    LogDebug("Target directory: " targetDir)
    LogDebug("Target name: " targetName)
    
    ; Load pre-defined names
    predefinedNames := LoadPredefinedNames()
    
    ; Show dialog for new filename
    newName := ShowSymlinkDialog(targetName, predefinedNames)
    
    if (newName == "") {
        LogDebug("User cancelled")
        return
    }
    
    ; Validate new name
    if (!IsValidFileName(newName)) {
        LogDebug("Invalid filename: " newName)
        MsgBox("Error: Invalid filename. Cannot contain: < > : `" / \ | ? *", "Symlink Creator", "Icon!")
        return
    }
    
    ; Build full path for new symlink
    linkPath := targetDir "\" newName
    
    LogDebug("Creating symlink: " linkPath " -> " targetPath)
    
    ; Create the symlink
    result := CreateSymlink(targetPath, linkPath)
    
    if (result.success) {
        MsgBox("Symlink created successfully!`n`n" linkPath " -> " targetName, "Symlink Creator", "Iconi")
    } else {
        if InStr(result.error, "privilege") || InStr(result.error, "administrator") {
            MsgBox("Failed to create symlink.`n`nYou may need to enable Developer Mode in Windows Settings, or run as administrator.`n`nError: " result.error, "Symlink Creator", "Icon!")
        } else {
            MsgBox("Failed to create symlink.`n`nError: " result.error, "Symlink Creator", "Icon!")
        }
    }
}

; Show dialog for entering new filename with pre-defined options
ShowSymlinkDialog(targetName, predefinedNames) {
    dialog := Gui("+AlwaysOnTop +Owner", "Create Symlink")
    dialog.SetFont("s10", "Segoe UI")
    dialog.result := ""

    ; Add description
    dialog.AddText("xm ym w400", "Target: " targetName)
    dialog.AddText("xm y+10 w400", "Enter new filename for the symlink:")

    ; Add edit field
    editName := dialog.AddEdit("xm y+5 w400 vNewName", targetName)

    ; Add pre-defined names section if any exist
    if (predefinedNames.Length > 0) {
        dialog.AddText("xm y+15 w400", "Or select a pre-defined name:")

        ; Create dropdown with pre-defined names
        ddlNames := dialog.AddDropDownList("xm y+5 w400 vSelectedName", predefinedNames)
        ddlNames.OnEvent("Change", (*) => editName.Value := ddlNames.Text)
    }

    ; Add buttons
    OnCreate(*) {
        dialog.result := editName.Value
        dialog.Destroy()
    }
    dialog.AddButton("xm y+20 w100 Default", "Create").OnEvent("Click", OnCreate)
    dialog.AddButton("x+10 w100", "Cancel").OnEvent("Click", (*) => dialog.Destroy())

    ; Center dialog
    dialog.Show("AutoSize Center")
    hwnd := dialog.Hwnd

    dialog.OnEvent("Close", (*) => dialog.Destroy())
    dialog.OnEvent("Escape", (*) => dialog.Destroy())

    ; Modal loop
    while (WinExist("ahk_id " hwnd)) {
        Sleep(100)
    }

    return dialog.result
}

; Load pre-defined names from INI
LoadPredefinedNames() {
    configFile := A_AppData "\SymlinkCreator\config.ini"
    names := []
    
    try {
        section := IniRead(configFile, "PredefinedNames")
        if (section != "") {
            Loop Parse, section, "`n" {
                if (A_LoopField != "") {
                    keyVal := StrSplit(A_LoopField, "=",, 2)
                    if (keyVal.Length >= 2) {
                        names.Push(keyVal[2])
                    }
                }
            }
        }
        LogDebug("Loaded " names.Length " predefined names")
    } catch as err8 {
        LogDebug("No predefined names found: " err8.Message)
    }
    
    return names
}

; Validate filename
IsValidFileName(name) {
    invalidChars := '<>"/\|?*'
    Loop Parse, invalidChars {
        if InStr(name, A_LoopField) {
            return false
        }
    }
    return name != ""
}

; Create symlink
CreateSymlink(targetPath, linkPath) {
    if (!FileExist(targetPath) && !DirExist(targetPath)) {
        return {success: false, error: "Target does not exist"}
    }
    
    if (FileExist(linkPath) || DirExist(linkPath)) {
        return {success: false, error: "File or folder already exists at destination"}
    }
    
    isDirectory := DirExist(targetPath) ? true : false
    
    try {
        if (isDirectory) {
            cmd := 'cmd /c mklink /D "' linkPath '" "' targetPath '"'
        } else {
            cmd := 'cmd /c mklink "' linkPath '" "' targetPath '"'
        }
        
        LogDebug("Executing: " cmd)
        
        shell := ComObject("WScript.Shell")
        exec := shell.Exec(cmd)
        
        ; Wait for completion
        while (exec.Status == 0) {
            Sleep(100)
        }
        
        output := exec.StdOut.ReadAll()
        errors := exec.StdErr.ReadAll()
        
        LogDebug("Output: " output)
        LogDebug("Errors: " errors)
        
        if (FileExist(linkPath) || DirExist(linkPath)) {
            return {success: true, error: ""}
        } else {
            errorMsg := errors != "" ? errors : "Failed to create symlink"
            return {success: false, error: errorMsg}
        }
    } catch as err9 {
        return {success: false, error: err9.Message}
    }
}

; Run main function
Main()
