/***
Author Tank <Charlie Simmons>ttnnkkrr@gmail.com
Date 11/30/2020
Git Repo https://github.com/ttnnkkrr/ADSI/
/*

sUserName := "AHK"
sPassword := "1234!!as"

Progress, Off
Global ProgressCounter := 0
Progress, B2 R0-10 T W500, Get Command Line , Permissions Check, Add User
sleep 500

full_command_line := DllCall("GetCommandLine", "str")
Progress,% ++ProgressCounter, Command Line %full_command_line%
sleep 500

if not (A_IsAdmin or RegExMatch(full_command_line, " /restart(?!\S)"))
{
    Progress,% ++ProgressCounter, Must run as Admin, Restarting as Admin
    sleep 2000
    try
    {
        if A_IsCompiled
            Run *RunAs "%A_ScriptFullPath%" /restart
        else
            Run *RunAs "%A_AhkPath%" /restart "%A_ScriptFullPath%"
    }
    ExitApp
}

Progress,% ++ProgressCounter, You have Admin Privilege!!
sleep 500

Global ErrorMessage := ""
IfWinExist, User Accounts ahk_exe Netplwiz.exe
    {
    Progress,% ++ProgressCounter, Previous Instance of User Accounts Open, Closing ..
    sleep 500

    WinClose, User Accounts ahk_exe Netplwiz.exe
    }

msgbox % AddUser(sUserName, sPassword) 
            ? "User Added"                          ;; Success !!
            : "it went real bad`n" ErrorMessage     ;; Failure

run netplwiz ;; Windows user accounts management

AddUser(sUserName, sPassword, sDescription="User added by AHK", sGroup="Users") {
    try {

        oNetwork := ComObjGet("WinNT://.")                              ;; AHK gets the current PC name for you
                    ;; ComObjCreate("WScript.Network").Computername     ;; using A_ComputerName would work as well
        
        ;; the act of actually creating the user account
        Progress,% ++ProgressCounter, Adding User .., Creating %sUserName%
        sleep 500
        oNewUser := oNetwork.Create("user", sUserName)                          
        
        ;; Set a password
        Progress,% ++ProgressCounter, Setting Password ..
        sleep 500
        oNewUser.SetPassword(sPassword)

        ;; set a description
        Progress,% ++ProgressCounter, Adding Description ..
        sleep 500
        oNewUser.Description := sDescription

        ;; save the user
        Progress,% ++ProgressCounter, Saving ..
        sleep 500
        oNewUser.SetInfo()

        ;; Add as a standard user
        Add2Group(sUserName, sGroup)
        }
    Catch, err {
        /*
        This object(err) contains the following properties:
        •Message: An error message or ErrorLevel value.
        •What: The name of the command, function or label which was executing or about to execute when the error occurred.
        •Extra: Additional information about the error, if available.
        •File: Set automatically to the full path of the script file which contains the line at which the error occurred.
        •Line: Set automatically to the line number at which the error occurred.

        */
        switch A_LastError 
        {
            Case "-2147352567":
            
                if (instr(err.Message, "The account already exists."))
                    ;;The account already exists.
                    ErrorMessage = The definition of insanaty is doing the same thing over and over
                
                else
                    ;; blocked maybe permission
                    ErrorMessage :=  "Fuck off" 
                        . err.Message "`n"
                        . "LastError [" A_LastError "]`n"
                        . "ErrorLevel [" ErrorLevel "]"

            default:
                ErrorMessage :=  err.What " Encountered a critical error`n"
                        . err.Message "`n"
                        . "LastError [" A_LastError "]`n"
                        . "ErrorLevel [" ErrorLevel "]"
        }
        Progress, Off
        return false
    }
    Progress, Off
    return true
}

Add2Group(sUserName, sGroup="Users"){
   
    Progress,% ++ProgressCounter, Adding as %sGroup% .., Group ..
    oGroup := ComObjGet("WinNT://" A_ComputerName "/" sGroup ",group")
    oUser := ComObjGet("WinNT://" A_ComputerName "/" sUserName ",user")

    If Not oGroup.IsMember(oUser.AdsPath) 
        oGroup.Add(oUser.AdsPath)
    sleep 500
}
