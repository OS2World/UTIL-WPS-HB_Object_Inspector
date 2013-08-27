/*:VRX         Main
*/
/*  Main
*/
Main:
/*  Process the arguments.
    Get the parent window.
*/
    parse source . calledAs .
    parent = ""
    argCount = arg()
    argOff = 0
    if( calledAs \= "COMMAND" )then do
        if argCount >= 1 then do
            parent = arg(1)
            argCount = argCount - 1
            argOff = 1
        end
    end; else do
        call VROptions 'ImplicitNames'
        call VROptions 'NoEchoQuit'
    end
    InitArgs.0 = argCount
    if( argCount > 0 )then do i = 1 to argCount
        InitArgs.i = arg( i + argOff )
    end
    drop calledAs argCount argOff

/*  Load the windows
*/
    call VRInit
    parse source . . spec
    _VREPrimaryWindowPath = ,
        VRParseFileName( spec, "dpn" ) || ".VRW"
    _VREPrimaryWindow = ,
        VRLoad( parent, _VREPrimaryWindowPath )
    drop parent spec
    if( _VREPrimaryWindow == "" )then do
        call VRMessage "", "Cannot load window:" VRError(), ,
            "Error!"
        _VREReturnValue = 32000
        signal _VRELeaveMain
    end

/*  Process events
*/
    call Init
    signal on halt
    do while( \ VRGet( _VREPrimaryWindow, "Shutdown" ) )
        _VREEvent = VREvent()
        interpret _VREEvent
    end
_VREHalt:
    _VREReturnValue = Fini()
    call VRDestroy _VREPrimaryWindow
_VRELeaveMain:
    call VRFini
exit _VREReturnValue

VRLoadSecondary:
    __vrlsWait = abbrev( 'WAIT', translate(arg(2)), 1 )
    if __vrlsWait then do
        call VRFlush
    end
    __vrlsHWnd = VRLoad( VRWindow(), VRWindowPath(), arg(1) )
    if __vrlsHWnd = '' then signal __vrlsDone
    if __vrlsWait \= 1 then signal __vrlsDone
    call VRSet __vrlsHWnd, 'WindowMode', 'Modal' 
    __vrlsTmp = __vrlsWindows.0
    if( DataType(__vrlsTmp) \= 'NUM' ) then do
        __vrlsTmp = 1
    end
    else do
        __vrlsTmp = __vrlsTmp + 1
    end
    __vrlsWindows.__vrlsTmp = VRWindow( __vrlsHWnd )
    __vrlsWindows.0 = __vrlsTmp
    do while( VRIsValidObject( VRWindow() ) = 1 )
        __vrlsEvent = VREvent()
        interpret __vrlsEvent
    end
    __vrlsTmp = __vrlsWindows.0
    __vrlsWindows.0 = __vrlsTmp - 1
    call VRWindow __vrlsWindows.__vrlsTmp 
    __vrlsHWnd = ''
__vrlsDone:
return __vrlsHWnd

/*:VRX         _CreateChildren
*/
_CreateChildren: 
    ok = WPToolsFolderContent(VRGet("EF_ObjectID","value"), "ObjList.")
    if ObjList.0 > 0 Then do
      do I = 1 to Objlist.0
        ok = WPToolsQueryObject(ObjList.I,"ObjClass","ObjTitle","ObjSetup","ObjLocation")
        call lineout Scriptfile, '  CREATEOBJECT="'ObjClass'|'ObjTitle'|'VRGet("EF_ObjectID","value")'|'OBjSetup'"'
      end
    end
return

/*:VRX         _GetObjectID
*/
_GetObjectID: procedure expose SetupString
    if pos('OBJECTID',SetupString) > 0 then do
        IdPos = pos('OBJECTID',SetupString)+9
        IdEndPos = pos(';',substr(SetupString,IdPos))-1
        ObjectID = substr(SetupString,IdPos,IdEndPos)
        SetupString = DelStr(SetupString,IdPos-9,IdEndPos+9+1)
    end    
    else ObjectID = '(none)'
return ObjectID

/*:VRX         _GetParent
*/
_GetParent: procedure
    FileString = arg(1)
    NewFile = strip(Filespec('D',FileString)||Filespec('P',FileString),'T','\')
return NewFile

/*:VRX         _GetTitle
*/
_GetTitle: procedure expose SetupString
    if pos('TITLE',SetupString) > 0 then do
        IdPos = pos('TITLE',SetupString)+6
        IdEndPos = pos(';',substr(SetupString,IdPos))-1
        Title = substr(SetupString,IdPos,IdEndpos)
        SetupString = DelStr(SetupString,IdPos-6,IdEndPos+6+1)
    end
    else Title = '(none)'
return Title

/*:VRX         _GUI2SetupStr
*/
_GUI2SetupStr: procedure
    SetupString = arg(1)
    OpString    = arg(2)
    OpGuiObj    = arg(3)
    OpStringLen = length(OpString)
    SetupString = strip(SetupString,'T',';')
    if VRGet(OpGUIObj,"set") 
        then Status = 'NO'
        else Status = 'YES'
    SetupString = SetupString||';'||OpString||'='Status';'
return SetupString

/*:VRX         _LoadOtherFuncs
*/
_LoadOtherFuncs: 
    call RxFuncAdd 'WPToolsLoadFuncs', 'WPTOOLS', 'WPToolsLoadFuncs'
    call WPToolsLoadFuncs 
    call RxFuncAdd 'SysLoadFuncs', 'RexxUtil', 'SysLoadFuncs'
    call SysLoadFuncs
return

/*:VRX         _ProcessFolder
*/
_ProcessFolder: 
    ok = WPToolsQueryObject(File,"FldClass","FldTitle","FldSetup","FldLocation")
    ok = VRSet("EF_Class","Value",FldClass)
    FldSetup = _SetupStringBreakup(FldSetup)  
    ok = VRSet("MLE_SetupStrings","Value",FldSetup)
    Parent = _GetParent(File)
    ok = WPToolsQueryObject(Parent,"ParClass","ParTitle","ParSetup","ParLocation")
    SetupString = ParSetup
    ok = VRset("EF_ParentID","Value",_GetOBjectID())
    drop Icon0
    drop Icon1
    ok = SysGetEA(File,".ICON",Icon0)
    IsIcon0 = (length(Icon0) > 500)
    if IsIcon0
        then ok = VRSet("EF_Icon0Data","Value","(DATA: "length(Icon0)-4")") /* first 4 byte no no !*/
        else ok = VRSet("EF_Icon0Data","Value","Icon 0 not found.")
    ok = SysGetEA(File,".ICON1",Icon1)
    IsIcon1 = (length(Icon1) > 500)
    if IsIcon1
        then ok = VRSet("EF_Icon1Data","Value","(DATA: "length(Icon1)-4")") /* first 4 byte no no !*/
        else ok = VRSet("EF_Icon1Data","Value","Icon 1 not found.")
return
/*:VRX         _ProcessObject
*/
_ProcessObject: 
    FileTitle = Filespec('N',File)
    Parent = _GetParent(File)
    ok = WPToolsQueryObject(Parent,"ParClass","ParTitle","ParSetup","ParLocation")
    SetupString = ParSetup
    ok = VRset("EF_ParentID","Value",_GetObjectID())
    ObjList.0 = 0
    ok = WPToolsFolderContent(Parent, "ObjList.")
    do I = 1 to Objlist.0
        ok = WPToolsQueryObject(ObjList.I,"ObjClass","ObjTitle","ObjSetup","ObjLocation")
        if ObjTitle = FileTitle then do
            ok = VRSet("EF_Class","Value",ObjClass)
            ObjSetup = _SetupStringBreakUp(ObjSetup)  
            ok = VRSet("MLE_SetupStrings","Value",ObjSetup)
        end
    end
return

/*:VRX         _ReplCRLFbySc
*/
_ReplCRLFbySc: procedure
    SetupString = arg(1)
    CRLF = d2c(13)||d2c(10)
    ScPos = pos(CRLF,SetupString)
    do while ScPos <> 0
        SetupString = DelStr(SetupString,ScPos,2)
        SetupString = insert(';',SetupString,ScPos-1)
        ScPos = pos(CRLF,SetupString, ScPos+2)
    end
return SetupString

/*:VRX         _ReplScByCRLF
*/
_ReplScByCRLF: procedure
    SetupString = arg(1)
    CRLF = d2c(13)||d2c(10)
    ScPos = pos(';',SetupString)
    do while ScPos <> 0
        SetupString = DelStr(SetupString,ScPos,1)
        SetupString = insert(CRLF,SetupString,ScPos-1)
        ScPos = pos(';',SetupString, ScPos+1)
    end
return SetupString

/*:VRX         _ResetGui
*/
_ResetGui: 
    ok = VRSet("EF_ObjectID","Value","")
    ok = VRSet("EF_Class","Value","")
    ok = VRSet("EF_ParentID","Value","")
    ok = VRSet("EF_Icon0Data","Value","")
    ok = VRSet("EF_Icon1Data","Value","")
    ok = VRSet("MLE_SetupStrings","Value","")
    ok = VRSet('CB_Delete','Set',0)
    ok = VRSet('CB_Print','Set',0)
    ok = VRSet('CB_Copy','Set',0)
    ok = VRSet('CB_Move','Set',0)
    ok = VRSet('CB_Shadow','Set',0)
    ok = VRSet('CB_Drag','Set',0)
    ok = VRSet('CB_Drop','Set',0)
    ok = VRSet('CB_Rename','Set',0)
    ok = VRSet('CB_Settings','Set',0)
    ok = VRSet('CB_Visible','Set',0)

    ok = VRSet('CB_Delete','enabled',0)
    ok = VRSet('CB_Print','enabled',0)
    ok = VRSet('CB_Copy','enabled',0)
    ok = VRSet('CB_Move','enabled',0)
    ok = VRSet('CB_Shadow','enabled',0)
    ok = VRSet('CB_Drag','enabled',0)
    ok = VRSet('CB_Drop','enabled',0)
    ok = VRSet('CB_Rename','enabled',0)
    ok = VRSet('CB_Settings','enabled',0)
    ok = VRSet('CB_Visible','enabled',0)
return

/*:VRX         _RexxBreakUpSetup
*/
_RexxBreakUpSetup: 
    I=1;J=1
    Mx = 500
    IsOBJECTID = 0
    IsSHADOWID = 0
    call charout RexxScriptFileName,"          "
    if szClass = "WPFolder" then do
        if IsIcon0 = 0 then do
            call lineout RexxScriptFileName,"'ICONFILE='BaseDir'\"Icon0name";'||,"
            call charout RexxScriptFileName,"          "
        end
    /*  else call lineout RexxScriptFileName,"      'ICONFILE=E:\ICONS\FLDICO\FLDR.ICO;'||," */
        if IsIcon1 = 0 then do
            call lineout RexxScriptFileName,"'ICONNFILE=1,'BaseDir'\"Icon1name";'||,"
            call charout RexxScriptFileName,"          "
        end
    /*  else call lineout RexxScriptFileName,"      'ICONNFILE=1,E:\ICONS\FLDICO\FLDROP.ICO;'||," */
    end
    
    I=pos(";",szSetupString,J)
    do while I \= 0
        if J > 1 then call charout RexxScriptFileName,"          "
        setupsect = substr(szSetupString,J,I-J+1)
        call charout RexxScriptFileName,"'"strip(setupsect,,";")
        IsOBJECTID = (left(setupsect,8) = "OBJECTID")|IsOBJECTID
        IsSHADOWID = (left(setupsect,8) = "SHADOWID")|IsSHADOWID
        J=I+1
        I=pos(";",szSetupString,J)
        if I \= 0 then call lineout RexxScriptFileName, ";'||," /* Es gibt noch weitere */
        if (I = 0)&(IsSHADOWID|IsOBJECTID) 
            then call lineout RexxScriptFileName, "',," /* Wir haben Shadow oder ObjId */
        Mx = Mx + 20
    end
    if (IsSHADOWID = 0) & (IsOBJECTID = 0) then do /* Weder  Shadow noch ObjID */
        call lineout  RexxScriptFileName, ";'||,"
        NewId_Title = translate(szTitle,'AOUaouS_!____P!!','éôöÑîÅ· ^",.-+/\')
        NewId = "<"NewId_Title">"
        if szClass = 'WPFolder' then NewLoc = NewId                 
        call lineout RexxScriptFileName, "          'OBJECTID="NewId"',,"                   
    end
    call lineout RexxScriptFileName, "      CreateCollision )"
    call lineout RexxScriptFileName, ""
    Mx = 10
return
/*:VRX         _REXXScriptBuilder
*/
_REXXScriptBuilder: 
    NewLoc = ''
    FolderID = VRGet("EF_ObjectID","Value")

    RexxScriptFileName = translate(left(VRGet("EF_Title","Value"),min(length(VRGet("EF_Title","Value")),8)))
    RexxScriptFileName = translate(RexxScriptFileName)
    RexxScriptFileName = translate(RexxScriptFileName, 'AOUAOUS_','éôöÑîÅ· ')
    RexxScriptFileName = VRFileDialog( VRWindow(), "Choose filename and path", "Save", RexxScriptFileName'.CMD', , ,  )
    if RexxScriptFileName = '' then return
    
    if right(RexxScriptFileName,4) \= '.CMD' then RexxScriptFileName=RexxScriptFileName'.CMD'

    'if exist 'RexxScriptFileName' copy 'RexxScriptFileName' 'left(RexxScriptFileName,length(RexxScriptFileName)-4)'.BAK >NUL'
    call SysFileDelete(RexxScriptFileName)
    
    /* Check if exists */
    Iretco = WPToolsFolderContent(FolderID, "list.")
    if Iretco = 0 Then Do 
       call Writeln FolderID' could not be queried.'
       return
    End 

    /* Write header */
    call lineout RexxScriptFileName, "/* Recreate '"substr(FolderID,lastpos("\",FolderID)+1)"' objects. Build "date("E")", "time()"."
    call lineout RexxScriptFileName, " *"
    call lineout RexxScriptFileName, " * Generated by WPS Assistent Ver. "Version", WPTools Ver. "WPTVer
    call lineout RexxScriptFileName, " */"
    call lineout RexxScriptFileName, ""
    call lineout RexxScriptFileName, "/* Register with REXX API extensions. */"
    call lineout RexxScriptFileName, "Call RxFuncAdd 'SysLoadFuncs', 'RexxUtil', 'SysLoadFuncs'"
    call lineout RexxScriptFileName, "Call SysLoadFuncs"
    call lineout RexxScriptFileName, ""
    call lineout RexxScriptFileName, "/* Set Creation Disposition */"
    call lineout RexxScriptFileName, "CreateCollision = 'Update'"
    call lineout RexxScriptFileName, " "
    call lineout RexxScriptFileName, "/* Script and icons have to reside in this directory */"
    call lineout RexxScriptFileName, "BaseDir=strip(Directory(),'T','\')"
    call lineout RexxScriptFileName, " "
    call lineout RexxScriptFileName, " "
    call lineout RexxScriptFileName, ""
    call lineout RexxScriptFileName, "Call RegisterClasses"
    call lineout RexxScriptFileName, "Call CreateObjects"
    call lineout RexxScriptFileName, "Exit"
    call lineout RexxScriptFileName, ""
    call lineout RexxScriptFileName, "CreateObject: procedure"
    call lineout RexxScriptFileName, "    Parse Arg Class, Title, Location, Setup, Collision"
    call lineout RexxScriptFileName, "    Say 'Creating ['Title']'"
    call lineout RexxScriptFileName, "    rc = SysCreateObject( Class, Title, Location, Setup, Collision )"
    call lineout RexxScriptFileName, "    If rc <> 1 Then"
    call lineout RexxScriptFileName, "         ' > failed to create ['Title' | 'Class'] at location ['Location']'"
    call lineout RexxScriptFileName, "    return rc"
    call lineout RexxScriptFileName, ""
    call lineout RexxScriptFileName, "CreateObjects:"
    call lineout RexxScriptFileName, ""
    
    AllClasses = ''
    
    /* Create Folder script */
    call Writeln "Creating script '"RexxScriptFileName"' for"
    Iretco=WPToolsQueryObject(FolderID, 'szclass', 'sztitle', 'szsetupstring', 'szlocation')
    if Iretco Then do
       drop icon0
       drop icon1
       call lineout RexxScriptFileName, "  rc = CreateObject( '"szClass"',,"
       if pos(szClass,AllClasses) = 0 then AllClasses = AllClasses'     'szClass
       call lineout RexxScriptFileName, "      '"szTitle"',,"
       call lineout RexxScriptFileName, "      '"szLocation"',,"
       call Writeln szClass": "szTitle" "
       Icon0name=left(RexxScriptFileName,min(7,length(RexxScriptFileName)-4))"0.ICO"
       Icon1name=left(RexxScriptFileName,min(7,length(RexxScriptFileName)-4))"1.ICO"
       call SysFileDelete(Icon0name)
       call SysFileDelete(Icon1name)
       rc = SysGetEA(FolderID,".ICON",Icon0)
       IsIcon0 = (length(Icon0) < 500)
       if IsIcon0 = 0 
           then call charout Icon0name, substr(Icon0,5)
           else call Writeln " Icon 0 not found."
       rc = SysGetEA(FolderID,".ICON1",Icon1)
       IsIcon1 = (length(Icon1) < 500)   
       if IsIcon1 = 0 
           then call charout Icon1name, substr(Icon1,5)
           else call Writeln " Icon 1 not found."
       Call _RexxBreakUpSetup
    end
    
    /* Create script for Folder content */
    do iObject = 1 to list.0
      Iretco=WPToolsQueryObject(list.Iobject, 'szclass', 'sztitle', 'szsetupstring', 'szlocation')
      if Iretco Then do 
         call lineout RexxScriptFileName, "  rc = CreateObject( '"szClass"',,"
         if pos(szClass,AllClasses) = 0 then AllClasses = Allclasses'     'szClass
         call lineout RexxScriptFileName, "      '"szTitle"',,"
         if NewLoc \= "" then szLocation=NewLoc
         call lineout RexxScriptFileName, "      '"szLocation"',,"
         Call _RexxBreakUpSetup
      end 
    end 
    
    /* Create object building script */
    call Writeln " "
    call Writeln "Completing script..."
    call lineout RexxScriptFileName, "return"
    call lineout RexxScriptFileName, ""
    call lineout RexxScriptFileName, "RegisterClasses:"
    call lineout RexxScriptFileName, ""
    call lineout RexxScriptFileName, "say "
    call lineout RexxScriptFileName, "say 'WPS classes to register....'"
    call lineout RexxScriptFileName, "say "
    call lineout RexxScriptFileName, "say 'The following classes have to be registered in order to make this script work:'"
    call lineout RexxScriptFileName, "say "
    call lineout RexxScriptFileName, "say '"AllClasses"'"
    call lineout RexxScriptFileName, "say"
    call lineout RexxScriptFileName, "say 'Press enter to continue,'"
    call lineout RexxScriptFileName, "call charout,'or type any other key and enter to abort: '"
    call lineout RexxScriptFileName, ""
    call lineout RexxScriptFileName, "Parse Pull Answer"
    call lineout RexxScriptFileName, "If Answer <> '' Then Exit"
    call lineout RexxScriptFileName, " "
    call lineout RexxScriptFileName, "Return"
    call lineout RexxScriptFileName
    Buttons.1 = "OK"
    Buttons.0 = 1
    id = VRMessageStem( VRWindow(), "Writeline.", "Object Inspector REXX script builder", "Information", "Buttons.", buttons.1, buttons.1 )
return

/*:VRX         _SetObjectID
*/
_SetObjectID: procedure
    SetupString = arg(1)
    SetupString = strip(SetupString,'T',';')
    CRLF = d2c(13)||d2c(10)
    if VRGet("EF_OBjectID","Value") = '(none)' | VRGet("EF_OBjectID","Value") = '' then do
        nop
    end
    else do
        SetupString = SetupString||';OBJECTID='VRGet("EF_OBjectID","Value")';'
    end
return SetupString

/*:VRX         _SetTitle
*/
_SetTitle: procedure
    SetupString = arg(1)
    SetupString = strip(SetupString,'T',';')
    CRLF = d2c(13)||d2c(10)
    if VRGet("EF_Title","Value") = '(none)' | VRGet("EF_Title","Value") = '' then do
        nop
    end
    else do
        SetupString = SetupString||';TITLE='VRGet("EF_Title","Value")';'
    end
return SetupString

/*:VRX         _SetupStr2GUI
*/
_SetupStr2GUI: procedure
    SetupString = arg(1)
    OpString    = arg(2)
    OpGuiObj    = arg(3)
    OpStringLen = length(OpString)
    ok = VRSet(OpGUIObj,"enabled",1)
    if pos(OpString,SetupString) > 0 then do
        IdPos = pos(OpString,SetupString)+OpStringLen
        IdEndPos = pos(';',substr(SetupString,IdPos))-1
        ok = VRSet(OpGUIObj,"set",0)
        SetupString = DelStr(SetupString,IdPos-OpStringLen,IdEndPos+OpStringLen+1)
    end
    else do
        ok = VRSet(OpGUIObj,"set",1)
    end
return SetupString
/*:VRX         _SetupStringBreakup
*/
_SetupStringBreakup: 
    SetupString = arg(1) 
    ok = VRSet("EF_ObjectID","Value",_GetObjectID())
    ok = VRSet("EF_Title","Value",_GetTitle())
    SetupString = _SetupStr2GUI(SetupString,'NODELETE=YES',  'CB_Delete')
    SetupString = _SetupStr2GUI(SetupString,'NOPRINT=YES',   'CB_Print')
    SetupString = _SetupStr2GUI(SetupString,'NOCOPY=YES',    'CB_Copy')
    SetupString = _SetupStr2GUI(SetupString,'NOMOVE=YES',    'CB_Move')
    SetupString = _SetupStr2GUI(SetupString,'NOSHADOW=YES',  'CB_Shadow')
    SetupString = _SetupStr2GUI(SetupString,'NODRAG=YES',    'CB_Drag')
    SetupString = _SetupStr2GUI(SetupString,'NODROP=YES',    'CB_Drop')
    SetupString = _SetupStr2GUI(SetupString,'NORENAME=YES',  'CB_Rename')
    SetupString = _SetupStr2GUI(SetupString,'NOSETTINGS=YES','CB_Settings')
    SetupString = _SetupStr2GUI(SetupString,'NOTVISIBLE=YES','CB_Visible')
/*  SetupString = _SetupStr2GUI(SetupString,'STATUSBAR=YES', 'CB_Statusbar') */
return _ReplScByCRLF(SetupString)
/*:VRX         _SetupStringBuild
*/
_SetupStringBuild: 

return

/*:VRX         EF_Title_Change
*/
EF_Title_Change: 
    if Analysing then return
    Analysing = 1
    File = VRget("EF_Title","Value")
    if File = '' then return
    call _ResetGUI
    ok = SysFileTree(File,Dirs.,'DO')
    if Dirs.0 = 1 
        then ObjectIsFolder = 1
        else ObjectIsFolder = 0
    ok = VRSet("PB_REXX","Enabled",OBjectIsFolder)
    if ObjectIsFolder
        then call _ProcessFolder
        else call _ProcessObject
    ok = VRset("TM_Allow","Enabled",1)
return

/*:VRX         Fini
*/
Fini:
    window = VRWindow()
    call VRSet window, "Visible", 0
    drop window
return 0

/*:VRX         Halt
*/
Halt:
    signal _VREHalt
return

/*:VRX         HBInspectMain_Close
*/
HBInspectMain_Close:
    call Quit
return

/*:VRX         HBInspectMain_Create
*/
HBInspectMain_Create: 
    call _LoadOtherFuncs
    Analysing = 0
    Version = '0.5.0b'
    VerDate = '31-03-2003'
    WPTVer = WPToolsVersion()
    ok = VRset("HBInspectMain","Caption","Object Inspector Version "Version)
    /* last action in here... */
    if VRGet("Application","Commandline") <> "" then do
        ok = VRset("EF_Title","Value",strip(VRGet("Application","Commandline"),"B",'"'))
    end
return

/*:VRX         HBInspectMain_DragDrop
*/
HBInspectMain_DragDrop: 
    ok = VRSet("EF_Title","Value", VRINfo("SourceFile"))
return

/*:VRX         Init
*/
Init:
    window = VRWindow()
    call VRMethod window, "CenterWindow"
    call VRSet window, "Visible", 1
    call VRMethod window, "Activate"
    drop window
return

/*:VRX         PB_Change_Click
*/
PB_Change_Click:
    ObjSetupString = _ReplCRLFBySc(VRGet("MLE_SetupStrings","Value"))
    ObjSetupString = _SetObjectID(ObjSetupString)
    ObjSetupString = _SetTitle(ObjSetupString)
    ObjSetupString =_GUI2SetupStr(ObjSetupString,'NODELETE',  'CB_Delete')
    ObjSetupString =_GUI2SetupStr(ObjSetupString,'NOPRINT',   'CB_Print')
    ObjSetupString =_GUI2SetupStr(ObjSetupString,'NOCOPY',    'CB_Copy')
    ObjSetupString =_GUI2SetupStr(ObjSetupString,'NOMOVE',    'CB_Move')
    ObjSetupString =_GUI2SetupStr(ObjSetupString,'NOSHADOW',  'CB_Shadow')
    ObjSetupString =_GUI2SetupStr(ObjSetupString,'NODRAG',    'CB_Drag')
    ObjSetupString =_GUI2SetupStr(ObjSetupString,'NODROP',    'CB_Drop')
    ObjSetupString =_GUI2SetupStr(ObjSetupString,'NORENAME',  'CB_Rename')
    ObjSetupString =_GUI2SetupStr(ObjSetupString,'NOSETTINGS','CB_Settings')
    ObjSetupString =_GUI2SetupStr(ObjSetupString,'NOTVISIBLE','CB_Visible')
/*  ObjSetupString =_GUI2SetupStr(ObjSetupString,'STATUSBAR', 'CB_Statusbar') */
    ok = SysSetObjectData(VRget("EF_ObjectID","Value"),ObjSetupString)
    Buttons.1 = "OK"
    Buttons.0 = 1
    if ok then do
        id = VRMessage( VRWindow(), "Object "VRGet("EF_ObjectID","Value")" changed successfully!", "Result", "Information", "Buttons.", buttons.1, buttons.1 )
    end
    else do
        id = VRMessage( VRWindow(), "Object "VRGet("EF_ObjectID","Value")" could not be changed!", "Result", "Error", "Buttons.", buttons.1, buttons.1 )
    end
return

/*:VRX         PB_Delete_Click
*/
PB_Delete_Click: 
    Buttons.1 = "OK"
    Buttons.0 = 1
    ok = SysDestroyObject(VRget("EF_ObjectID","Value"))
    if ok then do
        id = VRMessage( VRWindow(), "Object "VRGet("EF_ObjectID","Value")" destroyed  successfully!", "Result", "Information", "Buttons.", buttons.1, buttons.1 )
    end
    else do
        id = VRMessage( VRWindow(), "Object "VRGet("EF_ObjectID","Value")" could not be destroyed!", "Result", "Error", "Buttons.", buttons.1, buttons.1 )
    end
return

/*:VRX         PB_Exit_Click
*/
PB_Exit_Click: 
    call Quit
return

/*:VRX         PB_REXX_Click
*/
PB_REXX_Click: 
    call _RexxScriptBuilder
return

/*:VRX         PB_WPI_Click
*/
PB_WPI_Click: 
    TargetPath = ''
    ScriptName = translate(strip(left(VRGet("EF_TITLE","Value"),8),'B',' '))
    ScriptName = translate(ScriptName, 'AOUAOUS_!_','éôöÑîÅ· /.')
    PackageFile = TargetPath||ScriptName||'.WPI'
    PackageFile = VRFileDialog( VRWindow(), "Choose filename and path", "Save", PackageFile, , ,  )
    if PackageFile = '' then return
    ScriptFile = VRParseFileName(PackageFile,'DPN')||'.WIS'
    TargetPath = VRParseFileName(PackageFile,'DP')
    DummyFile = 'Dummy'
    WPISetupString = _ReplCRLFbySc(VRGet("MLE_SetupStrings","Value"))
    WPISetupString = _SetObjectID(WPISetupString)
    ok = SysFileDelete(ScriptFile)
    ok = SysFileDelete(PackageFile)
    ok = SysFileDelete(DummyFile)
    call lineout ScriptFile, '<WARPIN>'
    call lineout ScriptFile, '<HEAD>'
    call lineout ScriptFile, '<PCK INDEX=1'
    call lineout ScriptFile, '  PACKAGEID="HBInspect\'VRGet("EF_Title","Value")'\'VRGet("EF_Title","Value")'\0\0\0"'
    call lineout ScriptFile, '  TARGET="?:\OS2\INSTALL" FIXED'
    call lineout ScriptFile, '  TITLE="'VRGet("EF_Title","Value")'"'
    call lineout Scriptfile, '  CREATEOBJECT="'VRGet("EF_Class","Value")'|'VRGet("EF_Title","Value")'|'VRGet("EF_ParentID","Value")'|'WPISetupString'"'
    if ObjectIsFolder then call _CreateChildren
    call lineout Scriptfile, '>'VRGet("EF_Title","Value")  
    call lineout ScriptFile, '</PCK>'
    call lineout ScriptFile, '</HEAD>'
    call lineout ScriptFile, '<BODY>'
    call lineout ScriptFile, '<PAGE INDEX=1 TYPE=TEXT>'
    call lineout ScriptFile, '<NEXTBUTTON TARGET=2>~Next</NEXTBUTTON>'
    call lineout ScriptFile, '<TEXT>'
    call lineout ScriptFile, 'This package was automatically created by HBInspect 'Version
    call lineout ScriptFile, 'from "'VRGet("EF_Title","Value")'" ("'VRGet("EF_OBjectID","Value")'")'
    if ObjectIsFolder then call lineout ScriptFile, 'and its children.'
    call lineout ScriptFile, '</TEXT>'
    call lineout ScriptFile, '</PAGE>'
    call lineout ScriptFile, '<PAGE INDEX=2 TYPE=CONTAINER>'
    call lineout ScriptFile, '<NEXTBUTTON TARGET=0>I~nstall</NEXTBUTTON>'
    call lineout ScriptFile, '<TEXT>'
    call lineout ScriptFile, 'Select or deselect package, then press "Install" to install this archive.'
    call lineout ScriptFile, '</TEXT>'
    call lineout ScriptFile, '</PAGE>'
    call lineout ScriptFile, '</BODY>'
    call lineout ScriptFile, '</WARPIN>'
    call lineout ScriptFile 
    call lineout DummyFile,'HBInspect 0.0.1 'VRGet("EF_Title","Value")
    call lineout DummyFile
    OutPut = value("TEMP",,"OS2ENVIRONMENT")'\Output'
    'wic 'PackageFile' -s 'ScriptFile' -a 1 'DummyFile' >'Output
    ok = SysFileDelete(ScriptFile)
    ok = SysFileDelete(DummyFile)
    I = 1
    do until lines(Output) = 0
        Lines.I = translate(linein(Output),' ',d2c(27))
        if pos('ompres',Lines.I) = 0 & pos('ummy',Lines.I) = 0 & pos('ollec',Lines.I) = 0 then do
           I = I + 1
        end
    end
    Lines.0 = I - 1
    call lineout OutPut
    ok = SysFileDelete(OutPut)
    Buttons.1 = "OK"
    Buttons.0 = 1
    id = VRMessageStem( VRWindow(), "Lines.", "Object Inspector WPI package builder", "Information", "Buttons.", buttons.1, buttons.1 )
return
/*:VRX         Quit
*/
Quit:
    window = VRWindow()
    call VRSet window, "Shutdown", 1
    drop window
return

/*:VRX         TM_Allow_Trigger
*/
TM_Allow_Trigger: 
    Analysing = 0
    ok = VRSet("TM_Allow","Enabled", 0)
    call beep 1600, 10
return

/*:VRX         Writeln
*/
Writeln: 
    if YYY = 'YYY' then YYY = 0
    YYY = YYY + 1
    Writeline.YYY = arg(1)
    Writeline.0 = YYY
return

