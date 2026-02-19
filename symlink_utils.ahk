#Requires AutoHotkey v2.0+
#SingleInstance Force
#Warn

; Symlink Utilities Module - Handles symbolic link creation

global LOG_DEBUG := A_ScriptDir "\debug.log"

LogDebug(msg) {
    ;FileAppend(Format("[{1}] DEBUG: {2}`n", A_Now, msg), LOG_DEBUG)
}

; Create symbolic link using Windows API
; targetPath: The existing file/folder to link to
; linkPath: The new symlink to create
; Returns: true on success, false on failure
CreateSymlink(targetPath, linkPath) {
    ; Validate target exists
    if (!FileExist(targetPath) && !DirExist(targetPath)) {
        LogDebug("Target does not exist: " targetPath)
        return {success: false, error: "Target file/folder does not exist"}
    }
    
    ; Check if link already exists
    if (FileExist(linkPath) || DirExist(linkPath)) {
        LogDebug("Link path already exists: " linkPath)
        return {success: false, error: "A file or folder with that name already exists"}
    }
    
    ; Determine if target is directory
    isDirectory := DirExist(targetPath) ? true : false
    
    ; Use mklink command via cmd
    ; mklink requires admin privileges for file symlinks (unless Developer Mode is enabled)
    try {
        if (isDirectory) {
            ; Directory symlink
            cmd := 'cmd /c mklink /D "' linkPath '" "' targetPath '"'
        } else {
            ; File symlink
            cmd := 'cmd /c mklink "' linkPath '" "' targetPath '"'
        }
        
        LogDebug("Executing: " cmd)
        
        ; Run command and capture output
        shell := ComObject("WScript.Shell")
        exec := shell.Exec(cmd)
        output := exec.StdOut.ReadAll()
        errors := exec.StdErr.ReadAll()
        
        LogDebug("Command output: " output)
        LogDebug("Command errors: " errors)
        
        ; Wait for completion
        while (exec.Status == 0) {
            Sleep(100)
        }
        
        if (FileExist(linkPath) || DirExist(linkPath)) {
            LogDebug("Symlink created successfully: " linkPath " -> " targetPath)
            return {success: true, error: ""}
        } else {
            errorMsg := errors != "" ? errors : "Unknown error creating symlink"
            LogDebug("Failed to create symlink: " errorMsg)
            return {success: false, error: errorMsg}
        }
    } catch as err10 {
        LogDebug("Exception creating symlink: " err10.Message)
        return {success: false, error: err10.Message}
    }
}

; Get directory from full path
GetDirectory(path) {
    SplitPath(path,, &dir)
    return dir
}

; Get filename from full path
GetFileName(path) {
    SplitPath(path, &filename)
    return filename
}

; Validate filename (no invalid characters)
IsValidFileName(name) {
    invalidChars := '<>"/\|?*'
    Loop Parse, invalidChars {
        if InStr(name, A_LoopField) {
            return false
        }
    }
    return true
}
