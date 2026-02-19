; INI Manager Module - Handles configuration and pre-defined filenames
; This module is meant to be #Included, not run standalone

; Module-level constants
CONFIG_DIR := A_AppData "\SymlinkCreator"
CONFIG_FILE := CONFIG_DIR "\config.ini"

; Ensure config directory exists
EnsureConfigDir() {
    global CONFIG_DIR
    if !DirExist(CONFIG_DIR) {
        try {
            DirCreate(CONFIG_DIR)
            LogDebug("Created config directory: " CONFIG_DIR)
        } catch as err1 {
            LogDebug("Failed to create config directory: " err1.Message)
            throw err1
        }
    }
}

; Load pre-defined filenames from INI
LoadPredefinedNames() {
    global CONFIG_FILE
    EnsureConfigDir()
    
    names := []
    try {
        ; Read all keys from PredefinedNames section
        section := IniRead(CONFIG_FILE, "PredefinedNames")
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
    } catch as err2 {
        LogDebug("No predefined names found or error reading INI: " err2.Message)
    }
    
    return names
}

; Save pre-defined filename to INI
AddPredefinedName(name) {
    global CONFIG_FILE
    EnsureConfigDir()
    
    try {
        ; Get next index
        names := LoadPredefinedNames()
        index := names.Length + 1
        
        ; Write to INI
        IniWrite(name, CONFIG_FILE, "PredefinedNames", "Name" index)
        LogDebug("Added predefined name: " name " at index " index)
        return true
    } catch as err3 {
        LogDebug("Failed to add predefined name: " err3.Message)
        return false
    }
}

; Delete pre-defined filename from INI
DeletePredefinedName(name) {
    global CONFIG_FILE
    EnsureConfigDir()
    
    try {
        ; Get all names
        names := LoadPredefinedNames()
        newNames := []
        
        ; Rebuild list without deleted name
        for n in names {
            if (n != name) {
                newNames.Push(n)
            }
        }
        
        ; Clear section and rewrite
        IniDelete(CONFIG_FILE, "PredefinedNames")
        
        for i, n in newNames {
            IniWrite(n, CONFIG_FILE, "PredefinedNames", "Name" i)
        }
        
        LogDebug("Deleted predefined name: " name)
        return true
    } catch as err4 {
        LogDebug("Failed to delete predefined name: " err4.Message)
        return false
    }
}
