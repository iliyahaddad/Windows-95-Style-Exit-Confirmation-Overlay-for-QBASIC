' ============================================================
' Windows 95 Style Exit Confirmation Overlay
' QBASIC / QuickBASIC
'
' SCREEN 0 - 80x25 text mode
'
' Features:
'   - Windows 95 style exit confirmation dialog
'   - Modal keyboard input
'   - ESC / Q opens exit dialog
'   - Y / N / Enter / Arrow keys supported
'   - Exact text-mode screen save
'   - Exact screen restore through B800 video memory
'   - No screen rebuild during restore
'
' ============================================================

' ------------------------------------------------------------
' Constants
' ------------------------------------------------------------

CONST TRUE = -1
CONST FALSE = 0

CONST SCREEN_ROWS = 25
CONST SCREEN_COLS = 80
CONST VIDEO_SEG = &HB800

' ------------------------------------------------------------
' Application state
' ------------------------------------------------------------

DIM SHARED appScreen AS INTEGER
DIM SHARED appMessage AS STRING * 50
DIM SHARED appCounter AS LONG

DIM SHARED dialogActive AS INTEGER
DIM SHARED dialogSelected AS INTEGER

' ------------------------------------------------------------
' Saved screen
'
' SCREEN 0 has:
'   80 x 25 = 2000 character cells
'
' Each cell:
'   byte 0 = character
'   byte 1 = attribute
'
' ------------------------------------------------------------

DIM SHARED savedChar(1 TO SCREEN_ROWS, 1 TO SCREEN_COLS) AS INTEGER
DIM SHARED savedAttr(1 TO SCREEN_ROWS, 1 TO SCREEN_COLS) AS INTEGER

' ------------------------------------------------------------
' Color scheme
' ------------------------------------------------------------

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

' Segment containing normal BASIC variables.
' Used to restore DEF SEG after accessing video memory.
DIM SHARED dataSeg AS INTEGER


' ============================================================
' Initialize color scheme
' ============================================================

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


' ============================================================
' Program entry
' ============================================================

SCREEN 0, 0, 0
WIDTH 80, 25

appScreen = 1
appMessage = "Welcome! Press 1, 2, 3 to navigate."
appCounter = 0

dialogActive = FALSE
dialogSelected = 0

GOSUB DrawApplication


' ============================================================
' Main loop
' ============================================================

DO

    ' --------------------------------------------------------
    ' Flush all pending keyboard input.
    ' This prevents buffered keys from accidentally
    ' activating the dialog.
    ' --------------------------------------------------------

    DO WHILE INKEY$ <> ""
    LOOP

    key$ = INKEY$

    ' --------------------------------------------------------
    ' Modal state
    ' --------------------------------------------------------

    IF dialogActive THEN

        GOSUB HandleDialogInput

    ELSE

        GOSUB HandleAppInput

        ' Update application counter only while
        ' the dialog is not active.

        appCounter = appCounter + 1

        IF appCounter MOD 10 = 0 THEN

            LOCATE 25, 70
            PRINT STRING$(10, " ");

            LOCATE 25, 70
            PRINT appCounter;

        END IF

    END IF

    ' Small delay.
    FOR t = 1 TO 100
    NEXT t

LOOP

END


' ============================================================
' Application input handler
' ============================================================

HandleAppInput:

    ' --------------------------------------------------------
    ' Open exit dialog
    ' --------------------------------------------------------

    IF key$ = CHR$(27) OR key$ = "q" OR key$ = "Q" THEN

        dialogSelected = 0
        dialogActive = TRUE

        GOSUB SaveScreen
        GOSUB DarkenScreen
        GOSUB DrawDialog

    ' --------------------------------------------------------
    ' Screen 1
    ' --------------------------------------------------------

    ELSEIF key$ = "1" THEN

        appScreen = 1
        appMessage = "Screen 1: Main Menu"
        appCounter = 0

        GOSUB DrawApplication

    ' --------------------------------------------------------
    ' Screen 2
    ' --------------------------------------------------------

    ELSEIF key$ = "2" THEN

        appScreen = 2
        appMessage = "Screen 2: Settings"
        appCounter = 0

        GOSUB DrawApplication

    ' --------------------------------------------------------
    ' Screen 3
    ' --------------------------------------------------------

    ELSEIF key$ = "3" THEN

        appScreen = 3
        appMessage = "Screen 3: About"
        appCounter = 0

        GOSUB DrawApplication

    END IF

RETURN


' ============================================================
' Dialog input handler
' ============================================================

HandleDialogInput:

    ' --------------------------------------------------------
    ' Y = Yes
    ' --------------------------------------------------------

    IF key$ = "y" OR key$ = "Y" THEN

        dialogActive = FALSE

        SYSTEM

    ' --------------------------------------------------------
    ' N / Q / ESC = No
    ' --------------------------------------------------------

    ELSEIF key$ = "n" OR key$ = "N" OR _
           key$ = "q" OR key$ = "Q" OR _
           key$ = CHR$(27) THEN

        dialogActive = FALSE

        GOSUB RestoreScreen

    ' --------------------------------------------------------
    ' ENTER
    ' --------------------------------------------------------

    ELSEIF key$ = CHR$(13) THEN

        IF dialogSelected = 1 THEN

            dialogActive = FALSE

            SYSTEM

        ELSE

            dialogActive = FALSE

            GOSUB RestoreScreen

        END IF

    ' --------------------------------------------------------
    ' LEFT ARROW
    ' --------------------------------------------------------

    ELSEIF key$ = CHR$(0) + "K" THEN

        dialogSelected = 0

        GOSUB DrawDialog

    ' --------------------------------------------------------
    ' RIGHT ARROW
    ' --------------------------------------------------------

    ELSEIF key$ = CHR$(0) + "M" THEN

        dialogSelected = 1

        GOSUB DrawDialog

    END IF

RETURN


' ============================================================
' Save screen
'
' Saves the COMPLETE SCREEN 0 character + attribute data.
'
' Video memory layout:
'
'   offset = ((row - 1) * 80 + (col - 1)) * 2
'
'   offset     = character
'   offset + 1 = attribute
'
' ============================================================

SaveScreen:

    DEF SEG = VIDEO_SEG

    FOR row = 1 TO SCREEN_ROWS

        FOR col = 1 TO SCREEN_COLS

            offset = ((row - 1) * SCREEN_COLS + (col - 1)) * 2

            savedChar(row, col) = PEEK(offset)
            savedAttr(row, col) = PEEK(offset + 1)

        NEXT col

    NEXT row

    DEF SEG = dataSeg

RETURN


' ============================================================
' Restore screen
'
' IMPORTANT:
'
' This version does NOT use:
'
'   LOCATE
'   COLOR
'   PRINT
'
' Instead it restores the original character and attribute
' bytes directly to B800.
'
' Therefore the saved screen is restored at the byte level.
'
' ============================================================

RestoreScreen:

    DEF SEG = VIDEO_SEG

    FOR row = 1 TO SCREEN_ROWS

        FOR col = 1 TO SCREEN_COLS

            offset = ((row - 1) * SCREEN_COLS + (col - 1)) * 2

            POKE offset, savedChar(row, col)
            POKE offset + 1, savedAttr(row, col)

        NEXT col

    NEXT row

    DEF SEG = dataSeg

RETURN


' ============================================================
' Darken screen
'
' The original screen remains in savedChar/savedAttr.
'
' Only the visible video memory is modified.
'
' Character:
'   preserved
'
' Foreground:
'   original low 3 bits
'
' Background:
'   black
'
' This creates the visual effect of a disabled/darkened
' background without destroying the saved screen.
'
' ============================================================

DarkenScreen:

    DEF SEG = VIDEO_SEG

    FOR row = 1 TO SCREEN_ROWS

        FOR col = 1 TO SCREEN_COLS

            offset = ((row - 1) * SCREEN_COLS + (col - 1)) * 2

            ' Preserve original character.
            POKE offset, savedChar(row, col)

            ' Preserve basic foreground color.
            attr = savedAttr(row, col)

            fg = attr AND &H07

            newAttr = fg + (colDarkBg * 16)

            POKE offset + 1, newAttr

        NEXT col

    NEXT row

    DEF SEG = dataSeg

RETURN


' ============================================================
' Draw main application screen
' ============================================================

DrawApplication:

    CLS

    ' --------------------------------------------------------
    ' Application title bar
    ' --------------------------------------------------------

    COLOR colAppTitleFg, colAppTitleBg

    LOCATE 1, 1
    PRINT STRING$(80, " ");

    LOCATE 1, 32
    PRINT "QBASIC DEMO APP";


    ' --------------------------------------------------------
    ' Main content
    ' --------------------------------------------------------

    COLOR colAppFg, colAppBg

    LOCATE 3, 1
    PRINT "Current Screen: "; appScreen

    PRINT "Message: "; appMessage

    PRINT "Counter: "; appCounter

    PRINT

    PRINT "Press 1, 2, or 3 to switch screens"
    PRINT "Press ESC or Q to exit"


    ' --------------------------------------------------------
    ' Status bar
    ' --------------------------------------------------------

    COLOR colStatus, colAppBg

    LOCATE 25, 1
    PRINT "Counter: ";

    LOCATE 25, 70
    PRINT appCounter;

RETURN


' ============================================================
' Draw Windows 95 style dialog
' ============================================================

DrawDialog:

    ' --------------------------------------------------------
    ' Dialog geometry
    ' --------------------------------------------------------

    row1 = 8
    col1 = 25

    row2 = 18
    col2 = 55

    w = col2 - col1 - 1


    ' --------------------------------------------------------
    ' Top border
    ' --------------------------------------------------------

    LOCATE row1, col1

    COLOR colBorder, colAppBg

    PRINT "+" + STRING$(w, "-") + "+"


    ' --------------------------------------------------------
    ' Title bar
    ' --------------------------------------------------------

    LOCATE row1 + 1, col1

    COLOR colTitleFg, colTitleBg

    PRINT "|" + STRING$(w, " ") + "|"

    LOCATE row1 + 1, col1 + 2

    PRINT "Exit Program";


    ' --------------------------------------------------------
    ' Separator
    ' --------------------------------------------------------

    LOCATE row1 + 2, col1

    COLOR colBorder, colAppBg

    PRINT "+" + STRING$(w, "-") + "+"


    ' --------------------------------------------------------
    ' Message area
    ' --------------------------------------------------------

    FOR r = row1 + 3 TO row2 - 3

        LOCATE r, col1

        COLOR colDialogFg, colDialogBg

        PRINT "|" + STRING$(w, " ") + "|"

    NEXT r


    ' --------------------------------------------------------
    ' Message
    ' --------------------------------------------------------

    LOCATE row1 + 5, col1 + 3

    COLOR colDialogFg, colDialogBg

    PRINT "Are you sure you want to"

    LOCATE row1 + 6, col1 + 3

    PRINT "exit the program?"


    ' --------------------------------------------------------
    ' Bottom border
    ' --------------------------------------------------------

    LOCATE row2, col1

    COLOR colBorder, colAppBg

    PRINT "+" + STRING$(w, "-") + "+"


    ' --------------------------------------------------------
    ' Button background
    ' --------------------------------------------------------

    LOCATE row2 - 1, col1

    COLOR colDialogFg, colDialogBg

    PRINT "|" + STRING$(w, " ") + "|"


    ' --------------------------------------------------------
    ' Buttons
    ' --------------------------------------------------------

    LOCATE row2 - 1, col1 + 8


    IF dialogSelected = 0 THEN

        ' NO selected

        COLOR colBtnSelFg, colBtnSelBg

        PRINT "[ No ]";

        COLOR colBtnNormFg, colBtnNormBg

        PRINT " [ Yes ] ";

    ELSE

        ' YES selected

        COLOR colBtnNormFg, colBtnNormBg

        PRINT " [ No ] ";

        COLOR colBtnSelFg, colBtnSelBg

        PRINT "[ Yes ]";

    END IF

RETURN
