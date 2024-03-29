import Control.Monad (join, when)
import qualified Data.Map as M
import Data.Maybe (maybeToList)
import Data.Monoid ()
import Graphics.X11.ExtraTypes.XF86 (xF86XK_AudioLowerVolume, xF86XK_AudioMute, xF86XK_AudioNext, xF86XK_AudioPlay, xF86XK_AudioPrev, xF86XK_AudioRaiseVolume, xF86XK_MonBrightnessDown, xF86XK_MonBrightnessUp)
import System.Exit ()
import XMonad
  ( Atom,
    Button,
    ChangeLayout (NextLayout),
    Default (def),
    Dimension,
    Full (Full),
    IncMasterN (IncMasterN),
    KeyMask,
    KeySym,
    Layout,
    ManageHook,
    Mirror (Mirror),
    MonadIO (..),
    Resize (Expand, Shrink),
    Tall (Tall),
    Window,
    X,
    XConf (theRoot),
    XConfig
      ( XConfig,
        borderWidth,
        clickJustFocuses,
        focusFollowsMouse,
        focusedBorderColor,
        handleEventHook,
        keys,
        layoutHook,
        logHook,
        manageHook,
        modMask,
        mouseBindings,
        normalBorderColor,
        startupHook,
        terminal,
        workspaces
      ),
    asks,
    button1,
    button2,
    button3,
    changeProperty32,
    className,
    composeAll,
    controlMask,
    doFloat,
    doIgnore,
    doShift,
    focus,
    getAtom,
    getWindowProperty32,
    kill,
    mod4Mask,
    mouseMoveWindow,
    mouseResizeWindow,
    propModeAppend,
    refresh,
    resource,
    screenWorkspace,
    sendMessage,
    setLayout,
    shiftMask,
    spawn,
    whenJust,
    windows,
    withDisplay,
    withFocused,
    xK_1,
    xK_9,
    xK_Print,
    xK_Return,
    xK_Tab,
    xK_a,
    xK_b,
    xK_c,
    xK_comma,
    xK_e,
    xK_g,
    xK_h,
    xK_i,
    xK_j,
    xK_k,
    xK_l,
    xK_m,
    xK_n,
    xK_o,
    xK_period,
    xK_q,
    xK_r,
    xK_slash,
    xK_space,
    xK_t,
    xK_u,
    xK_w,
    xK_y,
    xK_z,
    xmonad,
    (-->),
    (.|.),
    (<+>),
    (=?),
    (|||),
  )
import XMonad.Actions.SpawnOn ()
import XMonad.Hooks.EwmhDesktops (ewmh)
import XMonad.Hooks.ManageDocks
  ( Direction2D (D, L, R, U),
    avoidStruts,
    docks,
    manageDocks,
  )
import XMonad.Hooks.ManageHelpers (doFullFloat, isFullscreen)
import XMonad.Layout.Fullscreen
  ( fullscreenEventHook,
    fullscreenFull,
    fullscreenManageHook,
    fullscreenSupport, fullscreenFloat,
  )
import XMonad.Layout.Gaps
  ( Direction2D (D, L, R, U),
    GapMessage (DecGap, IncGap, ToggleGaps),
    gaps,
    setGaps,
  )
import XMonad.Layout.NoBorders (smartBorders)
import XMonad.Layout.ResizableTile (MirrorResize (MirrorExpand, MirrorShrink), ResizableTall (ResizableTall))
import XMonad.Layout.Spacing (Border (Border), spacingRaw)
import qualified XMonad.StackSet as W
import XMonad.Util.SpawnOnce (spawnOnce)

-- The preferred terminal program, which is used in a binding below and by
-- certain contrib modules.
--
myTerminal :: String
myTerminal = "kitty"

-- Whether focus follows the mouse pointer.
myFocusFollowsMouse :: Bool
myFocusFollowsMouse = True

-- Whether clicking on a window to focus also passes the click to the window
myClickJustFocuses :: Bool
myClickJustFocuses = False

-- Width of the window border in pixels.
--
myBorderWidth :: Dimension
myBorderWidth = 3

-- modMask lets you specify which modkey you want to use. The default
-- is mod1Mask ("left alt").  You may also consider using mod3Mask
-- ("right alt"), which does not conflict with emacs keybindings. The
-- "windows key" is usually mod4Mask.
--
myModMask :: KeyMask
myModMask = mod4Mask

-- The default number of workspaces (virtual screens) and their names.
-- By default we use numeric strings, but any string may be used as a
-- workspace name. The number of workspaces is determined by the length
-- of this list.
--
-- A tagging example:
--
-- > workspaces = ["web", "irc", "code" ] ++ map show [4..9]
myWorkspaces :: [String]
myWorkspaces = ["terminal", "web", "files", "games", "chat", "other0", "other1", "other2", "spotify"]

-- Border colors for unfocused and focused windows, respectively.
myNormalBorderColor :: String
myNormalBorderColor = "#3b4252"

myFocusedBorderColor :: String
myFocusedBorderColor = "#82AAFF"

addNETSupported :: Atom -> X ()
addNETSupported x = withDisplay $ \dpy -> do
  r <- asks theRoot
  a_NET_SUPPORTED <- getAtom "_NET_SUPPORTED"
  a <- getAtom "ATOM"
  liftIO $ do
    sup <- (join . maybeToList) <$> getWindowProperty32 dpy a_NET_SUPPORTED r
    when (fromIntegral x `notElem` sup) $
      changeProperty32 dpy r a_NET_SUPPORTED a propModeAppend [fromIntegral x]

addEWMHFullscreen :: X ()
addEWMHFullscreen = do
  wms <- getAtom "_NET_WM_STATE"
  wfs <- getAtom "_NET_WM_STATE_FULLSCREEN"
  mapM_ addNETSupported [wms, wfs]

------------------------------------------------------------------------
-- Key bindings. Add, modify or remove key bindings here.
--
clipboardy :: MonadIO m => m ()
clipboardy = spawn "rofi -modi \"\63053 :greenclip print\" -show \"\63053 \" -run-command '{cmd}' -theme ~/.config/rofi/launcher/style.rasi"

-- maimcopy = spawn "maim -s | xclip -selection clipboard -t image/png && notify-send \"Screenshot\" \"Copied to Clipboard\" -i flameshot"
maimcopy :: X ()
maimcopy = spawn "flameshot gui"

maimsave :: X ()
maimsave = spawn "maim -s ~/Desktop/$(date +%Y-%m-%d_%H-%M-%S).png && notify-send \"Screenshot\" \"Saved to Desktop\" -i flameshot"

rofi_launcher :: X ()
rofi_launcher = spawn "rofi -no-lazy-grab -show drun -modi run,drun,window -theme $HOME/.config/rofi/launcher/style -drun-icon-theme \"candy-icons\" "

myKeys :: XConfig Layout -> M.Map (KeyMask, KeySym) (X ())
myKeys conf@(XConfig {XMonad.modMask = modm}) =
  M.fromList $
    -- launch a terminal
    [ ((modm .|. shiftMask, xK_Return), spawn $ XMonad.terminal conf),
      -- launch rofi and dashboard
      ((modm, xK_o), rofi_launcher),
      -- Audio keys
      ((0, xF86XK_AudioPlay), spawn "playerctl play-pause"),
      ((0, xF86XK_AudioPrev), spawn "playerctl previous"),
      ((0, xF86XK_AudioNext), spawn "playerctl next"),
      ((0, xF86XK_AudioRaiseVolume), spawn "pactl set-sink-volume 0 +5%"),
      ((0, xF86XK_AudioLowerVolume), spawn "pactl set-sink-volume 0 -5%"),
      ((0, xF86XK_AudioMute), spawn "pactl set-sink-mute 0 toggle"),
      -- Brightness keys
      ((0, xF86XK_MonBrightnessUp), spawn "brightnessctl s +10%"),
      ((0, xF86XK_MonBrightnessDown), spawn "brightnessctl s 10-%"),
      -- Screenshot
      ((0, xK_Print), maimcopy),
      ((modm, xK_Print), maimsave),
      -- My Stuff
      ((modm, xK_b), spawn "exec ~/bin/bartoggle"),
      ((modm, xK_z), spawn "exec ~/bin/inhibit_activate"),
      ((modm .|. shiftMask, xK_z), spawn "exec ~/bin/inhibit_deactivate"),
      ((modm .|. shiftMask, xK_a), clipboardy),
      -- close focused window
      ((modm .|. shiftMask, xK_c), kill),
      -- GAPS!!!
      ((modm .|. controlMask, xK_g), sendMessage $ ToggleGaps), -- toggle all gaps
      ((modm .|. shiftMask, xK_g), sendMessage $ setGaps [(L, 10), (R, 10), (U, 10), (D, 10)]), -- reset the GapSpec
      ((modm .|. controlMask, xK_t), sendMessage $ IncGap 10 L), -- increment the left-hand gap
      ((modm .|. shiftMask, xK_t), sendMessage $ DecGap 10 L), -- decrement the left-hand gap
      ((modm .|. controlMask, xK_y), sendMessage $ IncGap 10 U), -- increment the top gap
      ((modm .|. shiftMask, xK_y), sendMessage $ DecGap 10 U), -- decrement the top gap
      ((modm .|. controlMask, xK_u), sendMessage $ IncGap 10 D), -- increment the bottom gap
      ((modm .|. shiftMask, xK_u), sendMessage $ DecGap 10 D), -- decrement the bottom gap
      ((modm .|. controlMask, xK_i), sendMessage $ IncGap 10 R), -- increment the right-hand gap
      ((modm .|. shiftMask, xK_i), sendMessage $ DecGap 10 R), -- decrement the right-hand gap
      ((modm .|. shiftMask, xK_h), sendMessage MirrorShrink), -- shrink the master area
      ((modm .|. shiftMask, xK_l), sendMessage MirrorExpand), -- expand the master area
      -- Rotate through the available layout algorithms
      ((modm, xK_space), sendMessage NextLayout),
      --  Reset the layouts on the current workspace to default
      ((modm .|. shiftMask, xK_space), setLayout $ XMonad.layoutHook conf),
      -- Resize viewed windows to the correct size
      ((modm, xK_n), refresh),
      -- Move focus to the next window
      ((modm, xK_Tab), windows W.focusDown),
      -- Move focus to the next window
      ((modm, xK_j), windows W.focusDown),
      -- Move focus to the previous window
      ((modm, xK_k), windows W.focusUp),
      -- Move focus to the master window
      ((modm, xK_m), windows W.focusMaster),
      -- Swap the focused window and the master window
      ((modm, xK_Return), windows W.swapMaster),
      -- Swap the focused window with the next window
      ((modm .|. shiftMask, xK_j), windows W.swapDown),
      -- Swap the focused window with the previous window
      ((modm .|. shiftMask, xK_k), windows W.swapUp),
      -- Shrink the master area
      ((modm, xK_h), sendMessage Shrink),
      -- Expand the master area
      ((modm, xK_l), sendMessage Expand),
      -- Push window back into tiling
      ((modm, xK_t), withFocused $ windows . W.sink),
      -- Increment the number of windows in the master area
      ((modm, xK_comma), sendMessage (IncMasterN 1)),
      -- Deincrement the number of windows in the master area
      ((modm, xK_period), sendMessage (IncMasterN (-1))),
      -- Toggle the status bar gap
      -- Use this binding with avoidStruts from Hooks.ManageDocks.
      -- See also the statusBar function from Hooks.DynamicLog.
      --
      -- , ((modm              , xK_b     ), sendMessage ToggleStruts)

      -- Quit xmonad
      ((modm .|. shiftMask, xK_q), spawn "~/bin/powermenu.sh"),
      -- Restart xmonad
      ((modm, xK_q), spawn "xmonad --recompile; xmonad --restart")
    ]
      ++
      --
      -- mod-[1..9], Switch to workspace N
      -- mod-shift-[1..9], Move client to workspace N
      --
      [ ((m .|. modm, k), windows $ f i)
        | (i, k) <- zip (XMonad.workspaces conf) [xK_1 .. xK_9],
          (f, m) <- [(W.greedyView, 0), (W.shift, shiftMask)]
      ]
      ++
      --
      -- mod-{w,e,r}, Switch to physical/Xinerama screens 1, 2, or 3
      -- mod-shift-{w,e,r}, Move client to screen 1, 2, or 3
      --
      [ ((m .|. modm, key), screenWorkspace sc >>= flip whenJust (windows . f))
        | (key, sc) <- zip [xK_w, xK_e, xK_r] [0 ..],
          (f, m) <- [(W.view, 0), (W.shift, shiftMask)]
      ]

------------------------------------------------------------------------
-- Mouse bindings: default actions bound to mouse events
--
myMouseBindings :: XConfig l -> M.Map (KeyMask, Button) (Window -> X ())
myMouseBindings (XConfig {XMonad.modMask = modm}) =
  M.fromList $
    -- mod-button1, Set the window to floating mode and move by dragging
    [ ( (modm, button1),
        \w ->
          focus w >> mouseMoveWindow w
            >> windows W.shiftMaster
      ),
      -- mod-button2, Raise the window to the top of the stack
      ((modm, button2), \w -> focus w >> windows W.shiftMaster),
      -- mod-button3, Set the window to floating mode and resize by dragging
      ( (modm, button3),
        \w ->
          focus w >> mouseResizeWindow w
            >> windows W.shiftMaster
      )
      -- you may also bind events to the mouse scroll wheel (button4 and button5)
    ]

------------------------------------------------------------------------
-- Layouts:

-- You can specify and transform your layouts by modifying these values.
-- If you change layout bindings be sure to use 'mod-shift-space' after
-- restarting (with 'mod-q') to reset your layout state to the new
-- defaults, as xmonad preserves your old layout settings by default.
--
-- The available layouts.  Note that each layout is separated by |||,
-- which denotes layout choice.
--

-- myLayout = avoidStruts (tiled ||| Mirror tiled ||| Full)
--   where
--     -- default tiling algorithm partitions the screen into two panes
--     tiled = ResizableTall nmaster delta ratio

--     -- The default number of windows in the master pane
--     nmaster = 1

--     -- Default proportion of screen occupied by master pane
--     ratio = 1 / 2

--     -- Percent of screen to increment by when resizing panes
--     delta = 3 / 100

myLayout =
  avoidStruts $
    tiled
      ||| Mirror tiled
      ||| Full
  where
    -- The last parameter is fraction to multiply the slave window heights
    -- with. Useless here.
    tiled = ResizableTall nmaster delta ratio []
    -- The default number of windows in the master pane
    nmaster = 1
    -- Default proportion of screen occupied by master pane
    ratio = 1 / 2
    -- Percent of screen to increment by when resizing panes
    delta = 3 / 100

------------------------------------------------------------------------
-- Window rules:

-- Execute arbitrary actions and WindowSet manipulations when managing
-- a new window. You can use this to, for example, always float a
-- particular program, or have a client always appear on a particular
-- workspace.
--
-- To find the property name associated with a program, use
-- > xprop | grep WM_CLASS
-- and click on the client you're interested in.
--
-- To match on the WM_NAME, you can use 'title' in the same way that
-- 'className' and 'resource' are used below.
--
myManageHook :: ManageHook
myManageHook =
  fullscreenManageHook <+> manageDocks
    <+> composeAll
      [ className =? "MPlayer" --> doFloat,
        className =? "Gimp" --> doFloat,
        resource =? "desktop_window" --> doIgnore,
        resource =? "kdesktop" --> doIgnore,
        className =? "Steam" --> doShift "games",
        className =? "discord" --> doShift "chat",
        className =? "telegram-desktop" --> doShift "chat",
        className =? "Spotify" --> doShift "spotify",
        className =? "Glava" --> doFullFloat,
        isFullscreen --> doFullFloat
      ]

------------------------------------------------------------------------
-- Event handling

-- * EwmhDesktops users should change this to ewmhDesktopsEventHook

--
-- Defines a custom handler function for X Events. The function should
-- return (All True) if the default handler is to be run afterwards. To
-- combine event hooks use mappend or mconcat from Data.Monoid.
--
myEventHook = mempty

------------------------------------------------------------------------
-- Status bars and logging

-- Perform an arbitrary action on each internal state change or X event.
-- See the 'XMonad.Hooks.DynamicLog' extension for examples.
--
myLogHook :: X ()
myLogHook = return ()

------------------------------------------------------------------------
-- Startup hook

-- Perform an arbitrary action each time xmonad starts or is restarted
-- with mod-q.  Used by, e.g., XMonad.Layout.PerWorkspace to initialize
-- per-workspace layout choices.
--
-- By default, do nothing.
myStartupHook :: X ()
myStartupHook = do
  spawnOnce "exec glava --desktop --force-mod=circle"
  spawnOnce "exec ~/bin/bartoggle"
  spawnOnce "feh --bg-scale ~/.wallpaper/background.png"
  spawnOnce "picom --experimental-backends"
  spawnOnce "greenclip daemon"
  spawnOnce "dunst"

  spawn "xsetroot -cursor_name left_ptr"

  -- App
  spawn "discord"
  -- spawn "flatpak run com.valvesoftware.Steam"
  spawn "telegram-desktop"
  spawn "firefox"

------------------------------------------------------------------------
-- Now run xmonad with all the defaults we set up.

-- Run xmonad with the settings you specify. No need to modify this.
--
main :: IO ()
main = xmonad $ fullscreenSupport $ docks $ ewmh defaults

-- A structure containing your configuration settings, overriding
-- fields in the default config. Any you don't override, will
-- use the defaults defined in xmonad/XMonad/Config.hs
--
-- No need to modify this.
--
defaults =
  def
    { -- simple stuff
      terminal = myTerminal,
      focusFollowsMouse = myFocusFollowsMouse,
      clickJustFocuses = myClickJustFocuses,
      borderWidth = myBorderWidth,
      modMask = myModMask,
      workspaces = myWorkspaces,
      normalBorderColor = myNormalBorderColor,
      focusedBorderColor = myFocusedBorderColor,
      -- key bindings
      keys = myKeys,
      mouseBindings = myMouseBindings,
      -- hooks, layouts
      manageHook = myManageHook,
      layoutHook = gaps [(L, 10), (R, 10), (U, 10), (D, 10)] $ spacingRaw True (Border 10 10 10 10) False (Border 10 10 10 10) True $ smartBorders myLayout,
      handleEventHook = myEventHook,
      logHook = myLogHook,
      startupHook = myStartupHook >> addEWMHFullscreen
    }
