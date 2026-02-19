; Registry Manager Module - Handles context menu registration
; This module is meant to be #Included, not run standalone

; Register context menu for files and folders
RegisterContextMenu() {
    try {
        ; Get the path to context_menu.ahk
        contextMenuScript := A_ScriptDir "\context_menu.ahk"
        ahkExe := "C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe"
        
        ; Check if context menu script exists
        if (!FileExist(contextMenuScript)) {
            LogDebug("Context menu script not found: " contextMenuScript)
            return {success: false, error: "Context menu script not found"}
        }
        
        ; Context menu icon
        iconPath := "shell32.dll,146"

        ; Register for files (*)
        RegWrite("Symlink File", "REG_SZ", "HKEY_CLASSES_ROOT\*\shell\SymlinkFile")
        RegWrite(iconPath, "REG_SZ", "HKEY_CLASSES_ROOT\*\shell\SymlinkFile", "Icon")
        RegWrite('"' ahkExe '" "' contextMenuScript '" "%1"', "REG_SZ", "HKEY_CLASSES_ROOT\*\shell\SymlinkFile\command")

        ; Register for folders (Directory)
        RegWrite("Symlink Folder", "REG_SZ", "HKEY_CLASSES_ROOT\Directory\shell\SymlinkFile")
        RegWrite(iconPath, "REG_SZ", "HKEY_CLASSES_ROOT\Directory\shell\SymlinkFile", "Icon")
        RegWrite('"' ahkExe '" "' contextMenuScript '" "%1"', "REG_SZ", "HKEY_CLASSES_ROOT\Directory\shell\SymlinkFile\command")

        ; Register for folders background (right-click in empty space)
        RegWrite("Symlink Folder", "REG_SZ", "HKEY_CLASSES_ROOT\Directory\Background\shell\SymlinkFile")
        RegWrite(iconPath, "REG_SZ", "HKEY_CLASSES_ROOT\Directory\Background\shell\SymlinkFile", "Icon")
        RegWrite('"' ahkExe '" "' contextMenuScript '" "%V"', "REG_SZ", "HKEY_CLASSES_ROOT\Directory\Background\shell\SymlinkFile\command")
        
        LogDebug("Context menu registered successfully")
        return {success: true, error: ""}
    } catch as err5 {
        LogDebug("Failed to register context menu: " err5.Message)
        return {success: false, error: "Failed to register context menu. Try running as administrator. Error: " err5.Message}
    }
}

; Unregister context menu
UnregisterContextMenu() {
    try {
        ; Unregister for files
        try RegDeleteKey("HKEY_CLASSES_ROOT\*\shell\SymlinkFile")
        
        ; Unregister for folders
        try RegDeleteKey("HKEY_CLASSES_ROOT\Directory\shell\SymlinkFile")
        
        ; Unregister for folder background
        try RegDeleteKey("HKEY_CLASSES_ROOT\Directory\Background\shell\SymlinkFile")
        
        LogDebug("Context menu unregistered successfully")
        return {success: true, error: ""}
    } catch as err6 {
        LogDebug("Failed to unregister context menu: " err6.Message)
        return {success: false, error: "Failed to unregister context menu. Try running as administrator. Error: " err6.Message}
    }
}

; Check if running with admin privileges
IsAdmin() {
    try {
        ; Try to write to a protected registry key
        RegWrite("test", "REG_SZ", "HKEY_LOCAL_MACHINE\SOFTWARE\TestAdmin")
        RegDelete("HKEY_LOCAL_MACHINE\SOFTWARE\TestAdmin")
        return true
    } catch {
        return false
    }
}

; Check if context menu is registered
IsContextMenuRegistered() {
    try {
        RegRead("HKEY_CLASSES_ROOT\*\shell\SymlinkFile")
        return true
    } catch {
        return false
    }
}
