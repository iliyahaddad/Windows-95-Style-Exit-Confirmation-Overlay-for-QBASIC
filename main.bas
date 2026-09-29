' ============================================
' Windows 95 Style Exit Confirmation Overlay
' QBASIC Text Mode Demo
' SCREEN 0, 80x25
' ============================================

' Constants
CONST TRUE = -1
CONST FALSE = 0

' Application state variables
DIM SHARED appScreen AS INTEGER
DIM SHARED appMessage AS STRING * 50
DIM SHARED appCounter AS LONG
DIM SHARED dialogActive AS INTEGER
DIM SHARED dialogSelected AS INTEGER

' Screen save buffers (SCREEN 0: 80x25 = 2000 cells)
DIM SHARED savedChar(1 TO 25, 1 TO 80) AS INTEGER
DIM SHARED savedAttr(1 TO 25, 1 TO 80) AS INTEGER

' Color scheme variables (allows easy theming)
DIM SHARED colTitleFg AS INTEGER
DIM SHARED colTitleBg AS INTEGER
DIM SHARED colDialogFg AS INTEGER
DIM SHARED colDialogBg AS INTEGER
DIM SHARED colBorder AS INTEGER
DIM SHARED colBtnSelFg AS INTEGER
DIM SHARED colBtnSelBg AS INTEGER
DIM SHARED colBtnNormFg AS INTEGER
DIM SHARED colBtnNormBg AS INTEGER
DIM SHARED colDarkFg AS INTEGER
DIM SHARED colDarkBg AS INTEGER
DIM SHARED colAppFg AS INTEGER
DIM SHARED colAppBg AS INTEGER
DIM SHARED colAppTitleFg AS INTEGER
DIM SHARED colAppTitleBg AS INTEGER
DIM SHARED colStatus AS INTEGER
DIM SHARED dataSeg AS INTEGER

' ============================================
' Initialize Color Scheme
' ============================================
colTitleFg = 15
colTitleBg = 1
colDialogFg = 0
colDialogBg = 7
colBorder = 8
colBtnSelFg = 15
colBtnSelBg = 1
colBtnNormFg = 0
colBtnNormBg = 7
colDarkFg = 0
colDarkBg = 0
colAppFg = 7
colAppBg = 0
colAppTitleFg = 15
colAppTitleBg = 1
colStatus = 8

dataSeg = VARSEG(appScreen)

' ============================================
' Program Entry Point
' ============================================
SCREEN 0, 0, 0
WIDTH 80, 25

appScreen = 1
appMessage = "Welcome! Press 1, 2, 3 to navigate."
appCounter = 0
dialogActive = FALSE
dialogSelected = 0

GOSUB DrawApplication

DO
  DO WHILE INKEY$ <> ""
  LOOP
  
  key$ = INKEY$
  
  IF dialogActive THEN
    GOSUB HandleDialogInput
  ELSE
    GOSUB HandleAppInput
    
    appCounter = appCounter + 1
    IF appCounter MOD 10 = 0 THEN
      LOCATE 25, 70
      PRINT STRING$(10, " ");
      LOCATE 25, 70
      PRINT appCounter;
    END IF
  END IF
  
  FOR t = 1 TO 100: NEXT t
LOOP

END

' ============================================
' Application Input Handler
' ============================================
HandleAppInput:
  IF key$ = CHR$(27) OR key$ = "q" OR key$ = "Q" THEN
    dialogSelected = 0
    dialogActive = TRUE
    GOSUB SaveScreen
    GOSUB DarkenScreen
    GOSUB DrawDialog
  ELSEIF key$ = "1" THEN
    appScreen = 1
    appMessage = "Screen 1: Main Menu"
    appCounter = 0
    GOSUB DrawApplication
  ELSEIF key$ = "2" THEN
    appScreen = 2
    appMessage = "Screen 2: Settings"
    appCounter = 0
    GOSUB DrawApplication
  ELSEIF key$ = "3" THEN
    appScreen = 3
    appMessage = "Screen 3: About"
    appCounter = 0
    GOSUB DrawApplication
  END IF
RETURN

' ============================================
' Dialog Input Handler
' ============================================
HandleDialogInput:
  IF key$ = "y" OR key$ = "Y" THEN
    dialogActive = FALSE
    SYSTEM
  ELSEIF key$ = "n" OR key$ = "N" OR key$ = "q" OR key$ = "Q" OR key$ = CHR$(27) THEN
    dialogActive = FALSE
    GOSUB RestoreScreen
  ELSEIF key$ = CHR$(13) THEN
    IF dialogSelected = 1 THEN
      dialogActive = FALSE
      SYSTEM
    ELSE
      dialogActive = FALSE
      GOSUB RestoreScreen
    END IF
  ELSEIF key$ = CHR$(0) + "K" THEN
    dialogSelected = 0
    GOSUB DrawDialog
  ELSEIF key$ = CHR$(0) + "M" THEN
    dialogSelected = 1
    GOSUB DrawDialog
  END IF
RETURN

' ============================================
' Screen Save/Restore
' ============================================
SaveScreen:
  FOR row = 1 TO 25
    FOR col = 1 TO 80
      savedChar(row, col) = SCREEN(row, col)
    NEXT col
  NEXT row
  
  DEF SEG = &HB800
  FOR row = 1 TO 25
    FOR col = 1 TO 80
      savedAttr(row, col) = PEEK((row - 1) * 160 + (col - 1) * 2 + 1)
    NEXT col
  NEXT row
  DEF SEG = dataSeg
RETURN

RestoreScreen:
  FOR row = 1 TO 25
    FOR col = 1 TO 80
      attr = savedAttr(row, col)
      fg = attr AND &H0F
      bg = (attr \ 16) AND &H07
      LOCATE row, col
      COLOR fg, bg
      PRINT CHR$(savedChar(row, col));
    NEXT col
  NEXT row
RETURN

' ============================================
' Dark Overlay - Uses color variables for theming
' ============================================
DarkenScreen:
  FOR row = 1 TO 25
    FOR col = 1 TO 80
      attr = savedAttr(row, col)
      fg = attr AND &H07
      LOCATE row, col
      COLOR fg, colDarkBg
      PRINT CHR$(savedChar(row, col));
    NEXT col
  NEXT row
RETURN

' ============================================
' Draw Main Application Screen
' ============================================
DrawApplication:
  CLS
  COLOR colAppTitleFg, colAppTitleBg
  LOCATE 1, 1
  PRINT STRING$(80, " ");
  LOCATE 1, 32
  PRINT "QBASIC DEMO APP";
  
  COLOR colAppFg, colAppBg
  LOCATE 3, 1
  PRINT "Current Screen: "; appScreen
  PRINT "Message: "; appMessage
  PRINT "Counter: "; appCounter
  PRINT
  PRINT "Press 1, 2, or 3 to switch screens"
  PRINT "Press ESC or Q to exit"
  
  COLOR colStatus, colAppBg
  LOCATE 25, 1
  PRINT "Counter: ";
  LOCATE 25, 70
  PRINT appCounter;
RETURN

' ============================================
' Draw Windows 95 Style Dialog
' ============================================
DrawDialog:
  row1 = 8
  col1 = 25
  row2 = 18
  col2 = 55
  w = col2 - col1 - 1
  
  ' Top border
  LOCATE row1, col1
  COLOR colBorder, colAppBg
  PRINT "+" + STRING$(w, "-") + "+"
  
  ' Title bar row
  LOCATE row1 + 1, col1
  COLOR colTitleFg, colTitleBg
  PRINT "|" + STRING$(w, " ") + "|"
  LOCATE row1 + 1, col1 + 2
  PRINT "Exit Program";
  
  ' Separator
  LOCATE row1 + 2, col1
  COLOR colBorder, colAppBg
  PRINT "+" + STRING$(w, "-") + "+"
  
  ' Message area
  FOR r = row1 + 3 TO row2 - 3
    LOCATE r, col1
    COLOR colDialogFg, colDialogBg
    PRINT "|" + STRING$(w, " ") + "|"
  NEXT r
  
  ' Message text
  LOCATE row1 + 5, col1 + 3
  PRINT "Are you sure you want to"
  LOCATE row1 + 6, col1 + 3
  PRINT "exit the program?"
  
  ' Bottom border
  LOCATE row2, col1
  COLOR colBorder, colAppBg
  PRINT "+" + STRING$(w, "-") + "+"
  
  ' Buttons row
  LOCATE row2 - 1, col1
  COLOR colDialogFg, colDialogBg
  PRINT "|" + STRING$(w, " ") + "|"
  
  ' Draw buttons using color variables
  LOCATE row2 - 1, col1 + 8
  IF dialogSelected = 0 THEN
    COLOR colBtnSelFg, colBtnSelBg
    PRINT "[ No ]";
    COLOR colBtnNormFg, colBtnNormBg
    PRINT "     [ Yes ] ";
  ELSE
    COLOR colBtnNormFg, colBtnNormBg
    PRINT "  [ No ]  ";
    COLOR colBtnSelFg, colBtnSelBg
    PRINT "[ Yes ]";
  END IF
RETURN