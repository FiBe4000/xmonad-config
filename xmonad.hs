import XMonad
import XMonad.Config.Xfce
import XMonad.Hooks.DynamicLog
import XMonad.Hooks.FadeInactive
import XMonad.Hooks.ManageDocks
import XMonad.Hooks.ManageHelpers
import XMonad.Hooks.EwmhDesktops
import XMonad.Hooks.DynamicLog
import XMonad.Util.Run(spawnPipe)
import XMonad.Util.EZConfig(additionalKeys)
import XMonad.Util.WindowProperties
import Graphics.X11.ExtraTypes.XF86
import XMonad.Layout.PerWorkspace (onWorkspace, onWorkspaces)
import XMonad.Layout.LimitWindows
import XMonad.Layout.GridVariants
import XMonad.Layout.NoBorders
import XMonad.Layout.MultiColumns
import XMonad.Layout.Spacing
import System.IO
import System.Exit

import qualified XMonad.Layout.Fullscreen as F
import qualified Data.Map as M
import qualified XMonad.StackSet as W
import qualified DBus as D
import qualified DBus.Client as D
import qualified Codec.Binary.UTF8.String as UTF8

myModMask :: KeyMask
myModMask = mod1Mask

myTerminal = "urxvtc"

myNormalBorderColor  = "#233427"
myFocusedBorderColor = "#54656f"
myBorderWidth        = 3

-- Workspaces
myWorkspaces = ["1 - Web", "2 - Terminals", "3 - Code", "4 - Mail", "5 - Chat", "6 - Music", "7 - VM", "8 - Etc1", "9 - Etc2"]

-- Define the workspace an app goes to
myManageHook = composeAll . concat $
  [
      [resource  =? "stalonetray"   --> doIgnore]
    , [className =? "Firefox"       --> doShift "1 - Web"]
    , [className =? "Google-chrome" --> doShift "1 - Web"]
    , [className =? "Evolution"     --> doShift "4 - Mail"]
    , [className =? "Pidgin"        --> doShift "5 - Chat"]
    , [className =? "Slack"         --> doShift "5 - Chat"]
    , [className =? "yakyak"        --> doShift "5 - Chat"]
    , [className =? "discord"       --> doShift "5 - Chat"]
    , [className =? "Kodi"          --> doShift "8 - Etc"]
    , [className =? "Kodi"          --> doFullFloat]
    , [className =? "Xmessage"      --> doCenterFloat]
    , [isFullscreen --> (doF W.focusUp <+> doFullFloat)]
  ]

myLayout     =  avoidStruts $ smartBorders $ spacingRaw False (Border 0 5 5 5) False (Border 5 5 5 5) False  $
                onWorkspaces ["1- Web", "3 - Code", "4 - Mail", "6 - Music", "8 - Etc1", "9 - Etc2"] customLayout $
                onWorkspaces ["2 - Terminals"] terminalLayout $
                onWorkspaces ["5 - Chat"] chatLayout $
                onWorkspaces ["7 - VM"] mediaLayout $
                customLayout

customLayout    = layoutHook defaultConfig
terminalLayout  = TallGrid 2 2 (2/3) (16/10) (5/100) ||| customLayout
chatLayout      = customLayout ||| multiCol [1] 2 (3/100) (1/5) ||| Tall 1 (3/100) (1/5)
mediaLayout     = F.fullscreenFull Full

myLogHook :: D.Client -> PP
myLogHook dbus = def
 { ppOutput  = dbusOutput dbus
  , ppCurrent = wrap ("%{F" ++ xmobarWSColor ++ "} ") " %{F-}"
  , ppTitle   = wrap ("%{F" ++ xmobarTitleColor ++ "} ") " %{F-}" . shorten 100
  , ppSep     = " \57521 "
  }

-- Emit a DBus signal on log updates
dbusOutput :: D.Client -> String -> IO ()
dbusOutput dbus str = do
    let signal = (D.signal objectPath interfaceName memberName) {
            D.signalBody = [D.toVariant $ UTF8.decodeString str]
        }
    D.emit dbus signal
  where
    objectPath = D.objectPath_ "/org/xmonad/Log"
    interfaceName = D.interfaceName_ "org.xmonad.Log"
    memberName = D.memberName_ "Update"

myStartupHook = do
  ewmhDesktopsStartup
  spawn "$HOME/.dotfiles/scripts/polybar.sh"
  return ()

myEventHook = ewmhDesktopsEventHook <+> fullscreenEventHook <+> docksEventHook

myKeys conf@(XConfig {XMonad.modMask = modMask}) = M.fromList $
  [
    -- launch a terminal
      ((modMask .|. shiftMask, xK_Return), spawn $ XMonad.terminal conf)

    -- toggle struts
    , ((modMask,               xK_b     ), sendMessage ToggleStruts)

    -- launch dmenu
    , ((modMask,               xK_p     ), spawn "rofi -show drun")

    -- close focused window
    , ((modMask .|. shiftMask, xK_c     ), kill)

     -- Rotate through the available layout algorithms
    , ((modMask,               xK_space ), sendMessage NextLayout)

    --  Reset the layouts on the current workspace to default
    , ((modMask .|. shiftMask, xK_space ), setLayout $ XMonad.layoutHook conf)

    -- Resize viewed windows to the correct size
    , ((modMask,               xK_n     ), refresh)

    -- Move focus to the next window
    , ((modMask,               xK_Tab   ), windows W.focusDown)

    -- Move focus to the next window
    , ((modMask,               xK_j     ), windows W.focusDown)

    -- Move focus to the previous window
    , ((modMask,               xK_k     ), windows W.focusUp  )

    -- Move focus to the master window
    , ((modMask,               xK_m     ), windows W.focusMaster  )

    -- Swap the focused window and the master window
    , ((modMask,               xK_Return), windows W.swapMaster)

    -- Swap the focused window with the next window
    , ((modMask .|. shiftMask, xK_j     ), windows W.swapDown  )

    -- Swap the focused window with the previous window
    , ((modMask .|. shiftMask, xK_k     ), windows W.swapUp    )

    -- Shrink the master area
    , ((modMask,               xK_h     ), sendMessage Shrink)

    -- Expand the master area
    , ((modMask,               xK_l     ), sendMessage Expand)

    -- Push window back into tiling
    , ((modMask,               xK_t     ), withFocused $ windows . W.sink)

    -- Increment the number of windows in the master area
    , ((modMask,               xK_comma ), sendMessage (IncMasterN 1))

    -- Decrement the number of windows in the master area
    , ((modMask,               xK_period), sendMessage (IncMasterN (-1)))

    -- Increment window spacing
    , ((modMask .|. shiftMask, xK_l),      incWindowSpacing 1)

    -- Decrement window spacing
    , ((modMask .|. shiftMask, xK_h),      decWindowSpacing 1)

    -- Toggle window spacing
    , ((myModMask .|. shiftMask, xK_s),      toggleWindowSpacingEnabled)

    -- toggle the status bar gap
    --, ((modMask              , xK_b     ),
    --      modifyGap (\i n -> let x = (XMonad.defaultGaps conf ++ repeat (0,0,0,0)) !! i
     --                        in if n == x then (0,0,0,0) else x))

    -- Quit xmonad
    , ((modMask .|. shiftMask, xK_q     ), io (exitWith ExitSuccess))

    -- Restart xmonad
    , ((modMask              , xK_q     ),
          broadcastMessage ReleaseResources >> restart "xmonad" True)
  ]
    ++

    --
    -- mod-[1..9], Switch to workspace N
    -- mod-shift-[1..9], Move client to workspace N
    --
    [((m .|. modMask, k), windows $ f i)
        | (i, k) <- zip (XMonad.workspaces conf) [xK_1 .. xK_9]
        , (f, m) <- [(W.greedyView, 0), (W.shift, shiftMask)]]
    ++

    --
    -- mod-{w,e,r}, Switch to physical/Xinerama screens 1, 2, or 3
    -- mod-shift-{w,e,r}, Move client to screen 1, 2, or 3
    --
    [((m .|. modMask, key), screenWorkspace sc >>= flip whenJust (windows . f))
        | (key, sc) <- zip [xK_w, xK_e, xK_r] [2,0,1]
        , (f, m) <- [(W.view, 0), (W.shift, shiftMask)]]
    ++

   -- Additional bindings
   [
    ((modMask .|. controlMask , xK_l),               spawn "sxlock -f \"-misc-fixed-medium-r-semicondensed--13-120-75-75-c-60-iso8859-1\""),
    ((modMask .|. controlMask .|. shiftMask , xK_q), spawn "systemctl poweroff"),
    ((modMask .|. controlMask .|. shiftMask , xK_r), spawn "systemctl reboot"),
    ((modMask .|. controlMask .|. shiftMask , xK_w), spawn "wpg -m"),
    ((shiftMask , xF86XK_MonBrightnessDown),         spawn "xbacklight -dec 5 -time 200 -steps 10"),
    ((shiftMask , xF86XK_MonBrightnessUp),           spawn "xbacklight -inc 5 -time 200 -steps 10"),
    ((0 , xF86XK_MonBrightnessDown),                 spawn "xbacklight -dec 10 -time 200 -steps 10"),
    ((0 , xF86XK_MonBrightnessUp),                   spawn "xbacklight -inc 10 -time 200 -steps 10"),
    ((0 , xF86XK_KbdBrightnessDown),                 spawn "asus-kbd-backlight down"),
    ((0 , xF86XK_KbdBrightnessUp),                   spawn "asus-kbd-backlight up"),
    ((0 , xF86XK_AudioLowerVolume),                  spawn "/usr/bin/pulseaudio-ctl down"),--"amixer set Master on && amixer set Headphone on && amixer set Master 2-"),
    ((0 , xF86XK_AudioRaiseVolume),                  spawn "/usr/bin/pulseaudio-ctl up"),--"amixer set Master on && amixer set Headphone on && amixer set Master 2+"),
    ((0 , xF86XK_AudioMute),                         spawn "/usr/bin/pulseaudio-ctl mute"),--"amixer set Master toggle && amixer set Headphone on && amixer set Speaker on"),
    ((mod4Mask , xK_space),                          spawn "/home/filip/.xmonad/scripts/switchpowgov.sh"),
    ((0 , xK_Print),                                 spawn "scrot"),
    ((modMask , xK_f),                               spawn "spacefm")
  ]
------------------------------------------------------------------------
-- Mouse bindings: default actions bound to mouse events
--
myMouseBindings (XConfig {XMonad.modMask = modMask}) = M.fromList $

    -- mod-button1, Set the window to floating mode and move by dragging
  [
      ((modMask, button1), (\w -> focus w >> mouseMoveWindow w))

    -- mod-button2, Raise the window to the top of the stack
    , ((modMask, button2), (\w -> focus w >> windows W.swapMaster))

    -- mod-button3, Set the window to floating mode and resize by dragging
    , ((modMask, button3), (\w -> focus w >> mouseResizeWindow w))
  ]

-- Xmobar config
xmobarWSColor     = "#808972"
xmobarWSHighlight = ""
xmobarTitleColor  = "#3d5d47"

myBar = "xmobar"

-- Run XMonad
main = do
  dbus <- D.connectSession
  D.requestName dbus (D.busName_ "org.xmonad.Log")
    [D.nameAllowReplacement, D.nameReplaceExisting, D.nameDoNotQueue]

  xmonad
    $ ewmh
    $ docks
    $ myConfig { logHook = dynamicLogWithPP (myLogHook dbus) }

myConfig = defaultConfig
 {
        terminal           = myTerminal
      , workspaces         = myWorkspaces
      , manageHook         = myManageHook
      , layoutHook         = myLayout
      , keys               = myKeys
      , mouseBindings      = myMouseBindings
      , modMask            = myModMask
      , startupHook        = myStartupHook
      , handleEventHook    = myEventHook
      , normalBorderColor  = myNormalBorderColor
      , focusedBorderColor = myFocusedBorderColor
      , borderWidth        = myBorderWidth
  }

