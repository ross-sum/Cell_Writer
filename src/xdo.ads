-- Generated using gcc -c -fdump-ada-spec -C ./cfo.h in the src/xdotool-c/ 
-- directory.  Details on how this file is generated are contained at
-- https://gcc.gnu.org/onlinedocs/gnat_ugn/Running-the-Binding-Generator.html
-- The xdotool application is sourced from https://github.com/jordansissel/xdotool
-- This is the libxdo file that provides an interface to the tool set in xdotool.
pragma Ada_2012;
pragma Style_Checks (Off);

with Interfaces.C; use Interfaces.C;
-- with stddef_h;
-- with X11_X_h;
-- limited with X11_Xlib_h;
with Interfaces.C.Strings;
-- with unistd_h;
with System;

package xdo is

   package C renames Interfaces.C;
   
   SIZE_USEHINTS : constant := (2 ** 0);  --  ./xdo.h:41
   SIZE_USEHINTS_X : constant := (2 ** 1);  --  ./xdo.h:42
   SIZE_USEHINTS_Y : constant := (2 ** 2);  --  ./xdo.h:43

   CURRENTWINDOW : constant := (0);  --  ./xdo.h:53

   SEARCH_TITLE : constant := (2 ** 0);  --  ./xdo.h:120

   SEARCH_CLASS : constant := (2 ** 1);  --  ./xdo.h:126

   SEARCH_NAME : constant := (2 ** 2);  --  ./xdo.h:132

   SEARCH_PID : constant := (2 ** 3);  --  ./xdo.h:138

   SEARCH_ONLYVISIBLE : constant := (2 ** 4);  --  ./xdo.h:144

   SEARCH_SCREEN : constant := (2 ** 5);  --  ./xdo.h:151

   SEARCH_CLASSNAME : constant := (2 ** 6);  --  ./xdo.h:157

   SEARCH_DESKTOP : constant := (2 ** 7);  --  ./xdo.h:164

   SEARCH_ROLE : constant := (2 ** 8);  --  ./xdo.h:170

   XDO_ERROR : constant := 1;  --  ./xdo.h:205
   XDO_SUCCESS : constant := 0;  --  ./xdo.h:206

   SIZE_TO : constant := 0;  --  ./xdo.h:439
   SIZE_FROM : constant := 1;  --  ./xdo.h:440

   XDO_FIND_PARENTS : constant := (0);  --  ./xdo.h:864

   XDO_FIND_CHILDREN : constant := (1);  --  ./xdo.h:869

  -- @file xdo.h
  --
  -- @mainpage
  --
  -- libxdo helps you send fake mouse and keyboard input, search for windows,
  -- perform various window management tasks such as desktop changes, window
  -- movement, etc.
  --
  -- For examples on libxdo usage, the xdotool source code is a good reference.
  --
  -- @see xdo.h
  -- @see xdo_new
  --  
  -- When issuing a window size change, giving this flag will make the size
  -- change be relative to the size hints of the window.  For terminals, this
  -- generally means that the window size will be relative to the font size,
  -- allowing you to change window sizes based on character rows and columns
  -- instead of pixels.
  --  
  -- CURRENTWINDOW is a special identify for xdo input faking (mouse and
  -- keyboard) functions like xdo_send_keysequence_window that indicate we should target the
  -- current window, not a specific window.
  -- 
  -- Generally, this means we will use XTEST instead of XSendEvent when sending
  -- events.
  --
  -- @internal
  -- Map character to whatever information we need to be able to send
  -- this key (keycode, modifiers, group, etc)
   subtype wchar_t is wide_character;
   subtype XID is unsigned_long;  -- /usr/include/X11/X.h:66
   subtype Window is XID;  -- /usr/include/X11/X.h:96
   subtype KeySym is XID;  -- /usr/include/X11/X.h:106
   subtype KeyCode is unsigned_char;  -- /usr/include/X11/X.h:108
  --  
  -- the letter for this key, like 'a'  
   type charcodemap is record
         key : aliased wchar_t;  -- ./xdo.h:61
         -- the keycode that this key is on  
         code : aliased KeyCode;  -- ./xdo.h:62
         -- the symbol representing this key  
         symbol : aliased KeySym;  -- ./xdo.h:63
         -- the keyboard group that has this key in it  
         group : aliased int;  -- ./xdo.h:64
         -- the modifiers to apply when sending this key  
         modmask : aliased int;  -- ./xdo.h:65
         -- if this key needs to be bound at runtime because it does not
         -- exist in the current keymap, this will be set to 1.  
         needs_binding : aliased int;  -- ./xdo.h:68
      end record;
   Pragma Convention (C_Pass_By_Copy, charcodemap);  -- ./xdo.h:60


   subtype charcodemap_t is charcodemap;  -- ./xdo.h:69
   type charcodemap_t_access is access charcodemap_t;

  -- Is XTest available?  
   type XDO_FEATURES is 
     (XDO_FEATURE_XTEST);
   pragma Convention (C, XDO_FEATURES);  -- ./xdo.h:73

  --  The main context.
  --  
  -- Forward declare before use for C++  
   type u_XDisplay is null record;   -- incomplete struct
   subtype Display is u_XDisplay;  -- /usr/include/X11/Xlib.h:487
   type Display_accsss is access Display;

  -- The Display for Xlib  
   type xdo is record
         xdpy : Display_accsss;  -- ./xdo.h:81
         -- The display name, if any. NULL if not specified.  
         display_name : C.Strings.chars_ptr;  -- ./xdo.h:84
         -- @internal Array of known keys/characters  
         charcodes : charcodemap_t_access;  -- ./xdo.h:87
         -- @internal Length of charcodes array  
         charcodes_len : aliased int;  -- ./xdo.h:90
         -- highest and lowest keycodes used by this X server
         --  @internal highest keycode value  
         keycode_high : aliased int;  -- ./xdo.h:93
         --  @internal lowest keycode value  
         keycode_low : aliased int;  -- ./xdo.h:96
         -- @internal number of keysyms per keycode  
         keysyms_per_keycode : aliased int;  -- ./xdo.h:99
         -- Should we close the display when calling xdo_free?  
         close_display_when_freed : aliased int;  -- ./xdo.h:102
         -- Be extra quiet? (omits some error/message output)  
         quiet : aliased int;  -- ./xdo.h:105
         -- Enable debug output?  
         debug : aliased int;  -- ./xdo.h:108
         -- Feature flags, such as XDO_FEATURE_XTEST, etc...  
         features_mask : aliased int;  -- ./xdo.h:111
      end record;
   pragma Convention (C_Pass_By_Copy, xdo);  -- ./xdo.h:78

   subtype xdo_t is xdo;  -- ./xdo.h:113

   type xdo_t_access is access xdo_t;
   type xdo_t_const_access is access constant xdo_t;
   
  --*
  -- * Search only window title. DEPRECATED - Use SEARCH_NAME
  -- * @see xdo_search_windows
  --  
  --*
  -- * Search only window class.
  -- * @see xdo_search_windows
  --  
  --*
  -- * Search only window name.
  -- * @see xdo_search_windows
  --  
  --*
  -- * Search only window pid.
  -- * @see xdo_search_windows
  --  
  --*
  -- * Search only visible windows.
  -- * @see xdo_search_windows
  --  
  --*
  -- * Search only a specific screen. 
  -- * @see xdo_search.screen
  -- * @see xdo_search_windows
  --  
  --*
  -- * Search only window class name.
  -- * @see xdo_search
  --  
  --*
  -- * Search a specific desktop
  -- * @see xdo_search.screen
  -- * @see xdo_search_windows
  --  
  --*
  -- * Search only window role.
  -- * @see xdo_search
  --  
  --*
  -- * The window search query structure.
  -- *
  -- * @see xdo_search_windows
  --  

  --* Should the tests be 'and' or 'or' ? If 'and', any failure will skip the
  --   * window. If 'or', any success will keep the window in search results.  

   type anon2228_enum2229 is 
     (SEARCH_ANY,
      SEARCH_ALL);
   pragma Convention (C, anon2228_enum2229);
   type xdo_search is record
         -- pattern to test against a window title  
         title : C.Strings.chars_ptr;  -- ./xdo.h:178
         -- pattern to test against a window class  
         winclass : C.Strings.chars_ptr;  -- ./xdo.h:179
         -- pattern to test against a window class  
         winclassname : C.Strings.chars_ptr;  -- ./xdo.h:180
         -- pattern to test against a window name  
         winname : C.Strings.chars_ptr;  -- ./xdo.h:181
         -- pattern to test against a window role  
         winrole : C.Strings.chars_ptr;  -- ./xdo.h:182
         -- window pid (From window atom _NET_WM_PID)  
         pid : aliased int;  -- ./xdo.h:183
         -- depth of search. 1 means only toplevel windows  
         max_depth : aliased long;  -- ./xdo.h:184
         -- boolean; set true to search only visible windows  
         only_visible : aliased int;  -- ./xdo.h:185
         -- what screen to search, if any. If none given, search all screens
         screen : aliased int;  -- ./xdo.h:186
         require : anon2228_enum2229;  -- ./xdo.h:191
         searchmask : aliased unsigned;  -- ./xdo.h:196
         desktop : aliased long;  -- ./xdo.h:199
         limit : aliased unsigned;  -- ./xdo.h:202
      end record;
   pragma Convention (C_Pass_By_Copy, xdo_search);  -- ./xdo.h:177

  --* bitmask of things you are searching for, such as SEARCH_NAME, etc.
  --   * @see SEARCH_NAME, SEARCH_CLASS, SEARCH_PID, SEARCH_CLASSNAME, etc
  --    

  --* What desktop to search, if any. If none given, search all screens.  
  --* How many results to return? If 0, return all.  
   subtype xdo_search_t is xdo_search;  -- ./xdo.h:203
   type xdo_search_t_access is access constant xdo_search_t;

  -- Create a new xdo_t instance.
  -- @param display the string display name, such as ":0". If null, uses the
  -- environment variable DISPLAY just like XOpenDisplay(NULL).
  -- @return Pointer to a new xdo_t or NULL on failure
   function xdo_new (display : C.Strings.chars_ptr) return xdo_t_access;  -- ./xdo.h:216
   pragma Import (C, xdo_new, "xdo_new");

    -- Create a new xdo_t instance with an existing X11 Display instance.
   function xdo_new_with_opened_display
      -- @param xdpy the Display pointer given by a previous XOpenDisplay()
     (xdpy : Display_accsss;
      -- @param display the string display name
      display : C.Strings.chars_ptr;
      -- @param close_display_when_freed If true, we will close the display when
      -- xdo_free is called. Otherwise, we leave it open.
      close_display_when_freed : int) return xdo_t_access;  -- ./xdo.h:226
   pragma Import (C, xdo_new_with_opened_display, "xdo_new_with_opened_display");

  -- Return a string representing the version of this library
   function xdo_version return C.Strings.chars_ptr;  -- ./xdo.h:232
   pragma Import (C, xdo_version, "xdo_version");

    -- Free and destroy an xdo_t instance.
    -- If close_display_when_freed is set, then we will also close the Display.
   procedure xdo_free (xdo : xdo_t_access);  -- ./xdo.h:239
   pragma Import (C, xdo_free, "xdo_free");

  -- Move the mouse to a specific location.
   function xdo_move_mouse
     (xdo : xdo_t_const_access;
      --  @param x the target X coordinate on the screen in pixels.
      x : int;
      --  @param y the target Y coordinate on the screen in pixels.
      y : int;
      --  @param screen the screen (number) you want to move on.
      screen : int) return int;  -- ./xdo.h:248
   pragma Import (C, xdo_move_mouse, "xdo_move_mouse");

  -- Move the mouse to a specific location relative to the top-left corner
  -- of a window.
   function xdo_move_mouse_relative_to_window
     (xdo : xdo_t_const_access;
      the_window : Window;
      --  @param x the target X coordinate on the screen in pixels.
      x : int;
      --  @param y the target Y coordinate on the screen in pixels.
      y : int) return int;  -- ./xdo.h:257
   pragma Import (C, xdo_move_mouse_relative_to_window, 
                     "xdo_move_mouse_relative_to_window");

  -- Move the mouse relative to it's current position.
   function xdo_move_mouse_relative
     (xdo : xdo_t_const_access;
      --  @param x the distance in pixels to move on the X axis.
      x : int;
      --  @param y the distance in pixels to move on the Y axis.
      y : int) return int;  -- ./xdo.h:265
   pragma Import (C, xdo_move_mouse_relative, "xdo_move_mouse_relative");

    -- Send a mouse press (aka mouse down) for a given button at the current mouse
    -- location.
   function xdo_mouse_down
     (xdo : xdo_t_const_access;
      --  @param window The window you want to send the event to or CURRENTWINDOW
      the_window : Window;
      --  @param button The mouse button. Generally, 1 is left, 2 is middle, 3
      --  is right, 4 is wheel up, 5 is wheel down.
      button : int) return int;  -- ./xdo.h:275
   pragma Import (C, xdo_mouse_down, "xdo_mouse_down");

  --*
  -- * Send a mouse release (aka mouse up) for a given button at the current mouse
  -- * location.
  -- *
  -- * @param window The window you want to send the event to or CURRENTWINDOW
  -- * @param button The mouse button. Generally, 1 is left, 2 is middle, 3 is
  -- *    right, 4 is wheel up, 5 is wheel down.
  --  
   function xdo_mouse_up
     (xdo : xdo_t_const_access;
      the_window : Window;
      button : int) return int;  -- ./xdo.h:285
   pragma Import (C, xdo_mouse_up, "xdo_mouse_up");

  --*
  -- * Get the current mouse location (coordinates and screen number).
  -- *
  -- * @param x integer pointer where the X coordinate will be stored
  -- * @param y integer pointer where the Y coordinate will be stored
  -- * @param screen_num integer pointer where the screen number will be stored
  --  
   function xdo_get_mouse_location
     (xdo : xdo_t_const_access;
      x : access int;
      y : access int;
      screen_num : access int) return int;  -- ./xdo.h:294
   pragma Import (C, xdo_get_mouse_location, "xdo_get_mouse_location");

  --*
  -- * Get the window the mouse is currently over
  -- *
  -- * @param window_ret Window pointer where the window will be stored.
  --  
   function xdo_get_window_at_mouse (xdo : xdo_t_const_access; 
                                     window_ret : access Window) return int;  -- ./xdo.h:301
   pragma Import (C, xdo_get_window_at_mouse, "xdo_get_window_at_mouse");

  --*
  -- * Get all mouse location-related data.
  -- *
  -- * If null is passed for any parameter, we simply do not store it.
  -- * Useful if you only want the 'y' coordinate, for example.
  -- *
  -- * @param x integer pointer where the X coordinate will be stored
  -- * @param y integer pointer where the Y coordinate will be stored
  -- * @param screen_num integer pointer where the screen number will be stored
  -- * @param window Window pointer where the window/client the mouse is over
  -- *   will be stored.
  --  
   function xdo_get_mouse_location2
     (xdo : xdo_t_const_access;
      x_ret : access int;
      y_ret : access int;
      screen_num_ret : access int;
      window_ret : access Window) return int;  -- ./xdo.h:315
   pragma Import (C, xdo_get_mouse_location2, "xdo_get_mouse_location2");

  --*
  -- * Wait for the mouse to move from a location. This function will block
  -- * until the condition has been satisfied.
  -- *
  -- * @param origin_x the X position you expect the mouse to move from
  -- * @param origin_y the Y position you expect the mouse to move from
  --  
   function xdo_wait_for_mouse_move_from
     (xdo : xdo_t_const_access;
      origin_x : int;
      origin_y : int) return int;  -- ./xdo.h:325
   pragma Import (C, xdo_wait_for_mouse_move_from, 
                     "xdo_wait_for_mouse_move_from");

  --*
  -- * Wait for the mouse to move to a location. This function will block
  -- * until the condition has been satisfied.
  -- *
  -- * @param dest_x the X position you expect the mouse to move to
  -- * @param dest_y the Y position you expect the mouse to move to
  --  
   function xdo_wait_for_mouse_move_to
     (xdo : xdo_t_const_access;
      dest_x : int;
      dest_y : int) return int;  -- ./xdo.h:334
   pragma Import (C, xdo_wait_for_mouse_move_to, "xdo_wait_for_mouse_move_to");

  --*
  -- * Send a click for a specific mouse button at the current mouse location.
  -- *
  -- * @param window The window you want to send the event to or CURRENTWINDOW
  -- * @param button The mouse button. Generally, 1 is left, 2 is middle, 3 is
  -- *    right, 4 is wheel up, 5 is wheel down.
  --  
   function xdo_click_window
     (xdo : xdo_t_const_access;
      the_window : Window;
      button : int) return int;  -- ./xdo.h:343
   pragma Import (C, xdo_click_window, "xdo_click_window");

  --*
  -- * Send a one or more clicks for a specific mouse button at the current mouse
  -- * location.
  -- *
  -- * @param window The window you want to send the event to or CURRENTWINDOW
  -- * @param button The mouse button. Generally, 1 is left, 2 is middle, 3 is
  -- *    right, 4 is wheel up, 5 is wheel down.
  --  
  -- Count of microseconds.   
   subtype uu_useconds_t is unsigned;  -- /usr/include/x86_64-linux-gnu/bits/types.h:161
   subtype useconds_t is uu_useconds_t;  -- /usr/include/unistd.h:255
   function xdo_click_window_multiple
     (xdo : xdo_t_const_access;
      the_window : Window;
      button : int;
      repeat : int;
      c_delay : useconds_t) return int;  -- ./xdo.h:353
   pragma Import (C, xdo_click_window_multiple, "xdo_click_window_multiple");

  -- Type a string to the specified window.
  -- If you want to send a specific key or key sequence, such as "alt+l", you
  -- want instead xdo_send_keysequence_window(...).
  --   @param window The window you want to send keystrokes to or CURRENTWINDOW
  --   @param string The string to type, like "Hello world!"
  --   @param delay The delay between keystrokes in microseconds. 12000 is a
  --                decent choice if you don't have other plans.
   function Xdo_Enter_Text_Window (xdo : xdo_t_const_access;
                                   the_window : Window;
                                   string : C.Strings.chars_ptr;
                                   c_delay : useconds_t) return int;
                                   -- ./xdo.h:367
   pragma Import (C, Xdo_Enter_Text_Window, "xdo_enter_text_window");

  -- Send a keysequence to the specified window.
  -- This allows you to send keysequences by symbol name. Any combination
  -- of X11 KeySym names separated by '+' are valid. Single KeySym names
  -- are valid, too.
  -- Examples:
  --    "l"
  --    "semicolon"
  --    "alt+Return"
  --    "Alt_L+Tab"
  -- If you want to type a string, such as "Hello world." you want to instead
  -- use Xdo_Enter_Text_Window.
  -- @param window The window you want to send the keysequence to or
  --   CURRENTWINDOW
  -- @param keysequence The string keysequence to send.
  -- @param delay The delay between keystrokes in microseconds.
   function Xdo_Send_KeySequence_Window(xdo : xdo_t_const_access;
                                        the_window  : Window;
                                        keysequence : C.Strings.chars_ptr;
                                        c_delay : useconds_t) return int;
                                        -- ./xdo.h:390
   pragma Import (C, Xdo_Send_KeySequence_Window, "xdo_send_keysequence_window");

  --*
  -- * Send key release (up) events for the given key sequence.
  -- *
  -- * @see xdo_send_keysequence_window
  --  
   function xdo_send_keysequence_window_up
     (xdo : xdo_t_const_access;
      the_window : Window;
      keysequence : C.Strings.chars_ptr;
      c_delay : useconds_t) return int;  -- ./xdo.h:398
   pragma Import (C, xdo_send_keysequence_window_up, 
                     "xdo_send_keysequence_window_up");

  --*
  -- * Send key press (down) events for the given key sequence.
  -- *
  -- * @see xdo_send_keysequence_window
  --  
   function xdo_send_keysequence_window_down
     (xdo : xdo_t_const_access;
      the_window : Window;
      keysequence : C.Strings.chars_ptr;
      c_delay : useconds_t) return int;  -- ./xdo.h:406
   pragma Import (C, xdo_send_keysequence_window_down, 
                     "xdo_send_keysequence_window_down");

  --*
  -- * Send a series of keystrokes.
  -- *
  -- * @param window The window to send events to or CURRENTWINDOW
  -- * @param keys The array of charcodemap_t entities to send.
  -- * @param nkeys The length of the keys parameter
  -- * @param pressed 1 for key press, 0 for key release.
  -- * @param modifier Pointer to integer to record the modifiers activated by
  -- *   the keys being pressed. If NULL, we don't save the modifiers.
  -- * @param delay The delay between keystrokes in microseconds.
  --  
   function xdo_send_keysequence_window_list_do
     (xdo : xdo_t_const_access;
      the_window : Window;
      keys : charcodemap_t_access;
      nkeys : int;
      pressed : int;
      modifier : access int;
      c_delay : useconds_t) return int;  -- ./xdo.h:420
   pragma Import (C, xdo_send_keysequence_window_list_do, 
                     "xdo_send_keysequence_window_list_do");

  --*
  -- * Wait for a window to have a specific map state.
  -- *
  -- * State possibilities:
  -- *   IsUnmapped - window is not displayed.
  -- *   IsViewable - window is mapped and shown (though may be clipped by windows
  -- *     on top of it)
  -- *   IsUnviewable - window is mapped but a parent window is unmapped.
  -- *
  -- * @param wid the window you want to wait for.
  -- * @param map_state the state to wait for.
  --  
   function xdo_wait_for_window_map_state
     (xdo : xdo_t_const_access;
      wid : Window;
      map_state : int) return int;  -- ./xdo.h:437
   pragma Import (C, xdo_wait_for_window_map_state, 
                     "xdo_wait_for_window_map_state");

   function xdo_wait_for_window_size
     (xdo : xdo_t_const_access;
      the_window : Window;
      width : unsigned;
      height : unsigned;
      flags : int;
      to_or_from : int) return int;  -- ./xdo.h:441
   pragma Import (C, xdo_wait_for_window_size, "xdo_wait_for_window_size");

  --*
  -- * Move a window to a specific location.
  -- *
  -- * The top left corner of the window will be moved to the x,y coordinate.
  -- *
  -- * @param wid the window to move
  -- * @param x the X coordinate to move to.
  -- * @param y the Y coordinate to move to.
  --  
   function xdo_move_window
     (xdo : xdo_t_const_access;
      wid : Window;
      x : int;
      y : int) return int;  -- ./xdo.h:454
   pragma Import (C, xdo_move_window, "xdo_move_window");

  --*
  -- * Apply a window's sizing hints (if any) to a given width and height.
  -- *
  -- * This function wraps XGetWMNormalHints() and applies any 
  -- * resize increment and base size to your given width and height values.
  -- *
  -- * @param window the window to use
  -- * @param width the unit width you want to translate
  -- * @param height the unit height you want to translate
  -- * @param width_ret the return location of the translated width
  -- * @param height_ret the return location of the translated height
  --  
   function xdo_translate_window_with_sizehint
     (xdo : xdo_t_const_access;
      the_window : Window;
      width : unsigned;
      height : unsigned;
      width_ret : access unsigned;
      height_ret : access unsigned) return int;  -- ./xdo.h:468
   pragma Import (C, xdo_translate_window_with_sizehint, 
                     "xdo_translate_window_with_sizehint");

  --*
  -- * Change the window size.
  -- *
  -- * @param wid the window to resize
  -- * @param w the new desired width
  -- * @param h the new desired height
  -- * @param flags if 0, use pixels for units. If SIZE_USEHINTS, then
  -- *   the units will be relative to the window size hints.
  --  
   function xdo_set_window_size
     (xdo : xdo_t_const_access;
      wid : Window;
      w : int;
      h : int;
      flags : int) return int;  -- ./xdo.h:481
   pragma Import (C, xdo_set_window_size, "xdo_set_window_size");

  --*
  -- * Change a window property.
  -- *
  -- * Example properties you can change are WM_NAME, WM_ICON_NAME, etc.
  -- *
  -- * @param wid The window to change a property of.
  -- * @param property the string name of the property.
  -- * @param value the string value of the property.
  --  
   function xdo_set_window_property
     (xdo : xdo_t_const_access;
      wid : Window;
      property : C.Strings.chars_ptr;
      value : C.Strings.chars_ptr) return int;  -- ./xdo.h:492
   pragma Import (C, xdo_set_window_property, "xdo_set_window_property");

  --*
  -- * Change the window's classname and or class.
  -- *
  -- * @param name The new class name. If NULL, no change.
  -- * @param _class The new class. If NULL, no change.
  --  
   function xdo_set_window_class
     (xdo : xdo_t_const_access;
      wid : Window;
      name : C.Strings.chars_ptr;
      u_class : C.Strings.chars_ptr) return int;  -- ./xdo.h:501
   pragma Import (C, xdo_set_window_class, "xdo_set_window_class");

  --*
  -- * Sets the urgency hint for a window.
  --  
   function xdo_set_window_urgency
     (xdo : xdo_t_const_access;
      wid : Window;
      urgency : int) return int;  -- ./xdo.h:507
   pragma Import (C, xdo_set_window_urgency, "xdo_set_window_urgency");

  --*
  -- * Set the override_redirect value for a window. This generally means
  -- * whether or not a window manager will manage this window.
  -- *
  -- * If you set it to 1, the window manager will usually not draw borders on the
  -- * window, etc. If you set it to 0, the window manager will see it like a
  -- * normal application window.
  -- *
  --  
   function xdo_set_window_override_redirect
     (xdo : xdo_t_const_access;
      wid : Window;
      override_redirect : int) return int;  -- ./xdo.h:518
   pragma Import (C, xdo_set_window_override_redirect, 
                     "xdo_set_window_override_redirect");

  --*
  -- * Focus a window.
  -- *
  -- * @see xdo_activate_window
  -- * @param wid the window to focus.
  --  
   function xdo_focus_window (xdo : xdo_t_const_access; wid : Window) return int;  -- ./xdo.h:527
   pragma Import (C, xdo_focus_window, "xdo_focus_window");

  --*
  -- * Raise a window to the top of the window stack. This is also sometimes
  -- * termed as bringing the window forward.
  -- *
  -- * @param wid The window to raise.
  --  

   function xdo_raise_window (xdo : xdo_t_const_access; wid : Window) return int;  -- ./xdo.h:535
   pragma Import (C, xdo_raise_window, "xdo_raise_window");

  --*
  -- * Get the window currently having focus.
  -- *
  -- * @param window_ret Pointer to a window where the currently-focused window
  -- *   will be stored.
  --  

   function xdo_get_focused_window (xdo : xdo_t_const_access; window_ret : access Window) return int; -- ./xdo.h:543
   pragma Import (C, xdo_get_focused_window, "xdo_get_focused_window");

  --*
  -- * Wait for a window to have or lose focus.
  -- *
  -- * @param window The window to wait on
  -- * @param want_focus If 1, wait for focus. If 0, wait for loss of focus.
  --  
   function xdo_wait_for_window_focus
     (xdo : xdo_t_const_access;
      the_window : Window;
      want_focus : int) return int;  -- ./xdo.h:551
   pragma Import (C, xdo_wait_for_window_focus, "xdo_wait_for_window_focus");

  --*
  -- * Get the PID owning a window. Not all applications support this.
  -- * It looks at the _NET_WM_PID property of the window.
  -- *
  -- * @param window the window to query.
  -- * @return the process id or 0 if no pid found.
  --  
   function xdo_get_pid_window (xdo : xdo_t_const_access; the_window : Window) return int;  -- ./xdo.h:560
   pragma Import (C, xdo_get_pid_window, "xdo_get_pid_window");

  --*
  -- * Like xdo_get_focused_window, but return the first ancestor-or-self window *
  -- * having a property of WM_CLASS. This allows you to get the "real" or
  -- * top-level-ish window having focus rather than something you may not expect
  -- * to be the window having focused.
  -- *
  -- * @param window_ret Pointer to a window where the currently-focused window
  -- *   will be stored.
  --  
   function xdo_get_focused_window_sane (xdo : xdo_t_const_access; 
                                         window_ret : access Window) return int;  -- ./xdo.h:571
   pragma Import (C, xdo_get_focused_window_sane, "xdo_get_focused_window_sane");

  --*
  -- * Activate a window. This is generally a better choice than xdo_focus_window
  -- * for a variety of reasons, but it requires window manager support:
  -- *   - If the window is on another desktop, that desktop is switched to.
  -- *   - It moves the window forward rather than simply focusing it
  -- *
  -- * Requires your window manager to support this.
  -- * Uses _NET_ACTIVE_WINDOW from the EWMH spec.
  -- *
  -- * @param wid the window to activate
  --  
   function xdo_activate_window (xdo : xdo_t_const_access; wid : Window) return int;  -- ./xdo.h:584
   pragma Import (C, xdo_activate_window, "xdo_activate_window");

  --*
  -- * Wait for a window to be active or not active.
  -- *
  -- * Requires your window manager to support this.
  -- * Uses _NET_ACTIVE_WINDOW from the EWMH spec.
  -- *
  -- * @param window the window to wait on
  -- * @param active If 1, wait for active. If 0, wait for inactive.
  --  
   function xdo_wait_for_window_active
     (xdo : xdo_t_const_access;
      the_window : Window;
      active : int) return int;  -- ./xdo.h:595
   pragma Import (C, xdo_wait_for_window_active, "xdo_wait_for_window_active");

  --*
  -- * Map a window. This mostly means to make the window visible if it is
  -- * not currently mapped.
  -- *
  -- * @param wid the window to map.
  --  
   function xdo_map_window (xdo : xdo_t_const_access; wid : Window) return int;  -- ./xdo.h:603
   pragma Import (C, xdo_map_window, "xdo_map_window");

  --*
  -- * Unmap a window
  -- *
  -- * @param wid the window to unmap
  --  
   function xdo_unmap_window (xdo : xdo_t_const_access; wid : Window) return int;  -- ./xdo.h:610
   pragma Import (C, xdo_unmap_window, "xdo_unmap_window");

  --*
  -- * Minimise a window.
  --  
   function xdo_minimise_window (xdo : xdo_t_const_access; wid : Window) return int;  -- ./xdo.h:615
   pragma Import (C, xdo_minimise_window, "xdo_minimize_window");

  --*
  -- * Get window classname
  -- * @param window the window
  -- * @param class_ret Pointer to the window classname WM_CLASS
  --  
   function xdo_get_window_classname
     (xdo : xdo_t_const_access;
      the_window : Window;
      class_ret : System.Address) return int;  -- ./xdo.h:626
   pragma Import (C, xdo_get_window_classname, "xdo_get_window_classname");

  --*
  -- * Change window state
  -- * @param action the _NET_WM_STATE action
  --  
   function xdo_window_state
     (xdo : xdo_t_access;
      the_window : Window;
      action : unsigned_long;
      property : C.Strings.chars_ptr) return int;  -- ./xdo.h:632
   pragma Import (C, xdo_window_state, "xdo_window_state");

  --* 
  -- * Reparents a window
  -- *
  -- * @param wid_source the window to reparent
  -- * @param wid_target the new parent window
  --  
   function xdo_reparent_window
     (xdo : xdo_t_const_access;
      wid_source : Window;
      wid_target : Window) return int;  -- ./xdo.h:640
   pragma Import (C, xdo_reparent_window, "xdo_reparent_window");

  --*
  -- * Get a window's location.
  -- *
  -- * @param wid the window to query
  -- * @param x_ret pointer to int where the X location is stored. If NULL, X is
  -- *   ignored.
  -- * @param y_ret pointer to int where the Y location is stored. If NULL, X is
  -- *   ignored.
  -- * @param screen_ret Pointer to Screen* where the Screen* the window on is
  -- *   stored. If NULL, this parameter is ignored.
  --  
   function xdo_get_window_location
     (xdo : xdo_t_const_access;
      wid : Window;
      x_ret : access int;
      y_ret : access int;
      screen_ret : System.Address) return int;  -- ./xdo.h:653
   pragma Import (C, xdo_get_window_location, "xdo_get_window_location");

  --*
  -- * Get a window's size.
  -- *
  -- * @param wid the window to query
  -- * @param width_ret pointer to unsigned int where the width is stored.
  -- * @param height_ret pointer to unsigned int where the height is stored.
  --  
   function xdo_get_window_size
     (xdo : xdo_t_const_access;
      wid : Window;
      width_ret : access unsigned;
      height_ret : access unsigned) return int;  -- ./xdo.h:663
   pragma Import (C, xdo_get_window_size, "xdo_get_window_size");

  -- pager-like behaviours  
  --*
  -- * Get the currently-active window.
  -- * Requires your window manager to support this.
  -- * Uses _NET_ACTIVE_WINDOW from the EWMH spec.
  -- *
  -- * @param window_ret Pointer to Window where the active window is stored.
  --  
   function xdo_get_active_window (xdo : xdo_t_const_access; 
                                   window_ret : access Window) return int;  -- ./xdo.h:675
   pragma Import (C, xdo_get_active_window, "xdo_get_active_window");

  --*
  -- * Get a window ID by clicking on it. This function blocks until a selection
  -- * is made.
  -- *
  -- * @param window_ret Pointer to Window where the selected window is stored.
  --  
   function xdo_select_window_with_click (xdo : xdo_t_const_access; window_ret : access Window) return int;  -- ./xdo.h:683
   pragma Import (C, xdo_select_window_with_click, "xdo_select_window_with_click");

  --*
  -- * Set the number of desktops.
  -- * Uses _NET_NUMBER_OF_DESKTOPS of the EWMH spec.
  -- *
  -- * @param ndesktops the new number of desktops to set.
  --  
   function xdo_set_number_of_desktops (xdo : xdo_t_const_access; 
                                        ndesktops : long) return int;  -- ./xdo.h:691
   pragma Import (C, xdo_set_number_of_desktops, "xdo_set_number_of_desktops");

  --*
  -- * Get the current number of desktops.
  -- * Uses _NET_NUMBER_OF_DESKTOPS of the EWMH spec.
  -- *
  -- * @param ndesktops pointer to long where the current number of desktops is
  -- *   stored
  --  
   function xdo_get_number_of_desktops (xdo : xdo_t_const_access; 
                                        ndesktops : access long) return int;  -- ./xdo.h:700
   pragma Import (C, xdo_get_number_of_desktops, "xdo_get_number_of_desktops");

  --*
  -- * Switch to another desktop.
  -- * Uses _NET_CURRENT_DESKTOP of the EWMH spec.
  -- *
  -- * @param desktop The desktop number to switch to.
  --  
   function xdo_set_current_desktop (xdo : xdo_t_const_access; 
                                     desktop : long) return int;  -- ./xdo.h:708
   pragma Import (C, xdo_set_current_desktop, "xdo_set_current_desktop");

  --*
  -- * Get the current desktop.
  -- * Uses _NET_CURRENT_DESKTOP of the EWMH spec.
  -- *
  -- * @param desktop pointer to long where the current desktop number is stored.
  --  
   function xdo_get_current_desktop (xdo : xdo_t_const_access; 
                                     desktop : access long) return int;  -- ./xdo.h:716
   pragma Import (C, xdo_get_current_desktop, "xdo_get_current_desktop");

  --*
  -- * Move a window to another desktop
  -- * Uses _NET_WM_DESKTOP of the EWMH spec.
  -- *
  -- * @param wid the window to move
  -- * @param desktop the desktop destination for the window
  --  

   function xdo_set_desktop_for_window
     (xdo : xdo_t_const_access;
      wid : Window;
      desktop : long) return int;  -- ./xdo.h:725
   pragma Import (C, xdo_set_desktop_for_window, "xdo_set_desktop_for_window");

  --*
  -- * Get the desktop a window is on.
  -- * Uses _NET_WM_DESKTOP of the EWMH spec.
  -- *
  -- * If your desktop does not support _NET_WM_DESKTOP, then '*desktop' remains
  -- * unmodified.
  -- *
  -- * @param wid the window to query
  -- * @param deskto pointer to long where the desktop of the window is stored
  --  
   function xdo_get_desktop_for_window
     (xdo : xdo_t_const_access;
      wid : Window;
      desktop : access long) return int;  -- ./xdo.h:737
   pragma Import (C, xdo_get_desktop_for_window, "xdo_get_desktop_for_window");

  --*
  -- * Search for windows.
  -- *
  -- * @param search the search query.
  -- * @param windowlist_ret the list of matching windows to return
  -- * @param nwindows_ret the number of windows (length of windowlist_ret)
  -- * @see xdo_search_t
  --  
   function xdo_search_windows
     (xdo : xdo_t_const_access;
      search : xdo_search_t_access;
      windowlist_ret : System.Address;
      nwindows_ret : access unsigned) return int;  -- ./xdo.h:747
   pragma Import (C, xdo_search_windows, "xdo_search_windows");

  --*
  -- * Generic property fetch.
  -- *
  -- * @param window the window to query
  -- * @param atom the Atom to request
  -- * @param nitems the number of items 
  -- * @param type the type of the return
  -- * @param size the size of the type
  -- * @return data consisting of 'nitems' items of size 'size' and type 'type'
  -- *   will need to be cast to the type before using.
   subtype Atom is unsigned_long;  -- /usr/include/X11/X.h:74
   type unsigned_char_access is access unsigned_char;

   function xdo_get_window_property_by_atom
     (xdo : xdo_t_const_access;
      the_window : Window;
      the_atom : Atom;
      nitems : access long;
      c_type : access Atom;
      size : access int) return unsigned_char_access;  -- ./xdo.h:761
   pragma Import (C, xdo_get_window_property_by_atom, 
                     "xdo_get_window_property_by_atom");

  --*
  -- * Get property of window by name of atom.
  -- *
  -- * @param window the window to query
  -- * @param property the name of the atom
  -- * @param nitems the number of items 
  -- * @param type the type of the return
  -- * @param size the size of the type
  -- * @return data consisting of 'nitems' items of size 'size' and type 'type'
  -- *   will need to be cast to the type before using.
  --  
   function xdo_get_window_property
     (xdo : xdo_t_const_access;
      the_window : Window;
      property : C.Strings.chars_ptr;
      value : System.Address;
      nitems : access long;
      c_type : access Atom;
      size : access int) return int;  -- ./xdo.h:775
   pragma Import (C, xdo_get_window_property, "xdo_get_window_property");

  --*
  -- * Get the current input state. This is a mask value containing any of the
  -- * following: ShiftMask, LockMask, ControlMask, Mod1Mask, Mod2Mask, Mod3Mask,
  -- * Mod4Mask, or Mod5Mask.
  -- *
  -- * @return the input mask
  --  
   function xdo_get_input_state (xdo : xdo_t_const_access) return unsigned;  -- ./xdo.h:785
   pragma Import (C, xdo_get_input_state, "xdo_get_input_state");

  --*
  -- * If you need the symbol map, use this method.
  -- *
  -- * The symbol map is an array of string pairs mapping common tokens to X Keysym
  -- * strings, such as "alt" to "Alt_L"
  -- *
  -- * @returns array of strings.
  --  
   function xdo_get_symbol_map return System.Address;  -- ./xdo.h:795
   pragma Import (C, xdo_get_symbol_map, "xdo_get_symbol_map");

  -- active modifiers stuff  
  --*
  -- * Get a list of active keys. Uses XQueryKeymap.
  -- *
  -- * @param keys Pointer to the array of charcodemap_t that will be allocated
  -- *    by this function.
  -- * @param nkeys Pointer to integer where the number of keys will be stored.
  --  
   function xdo_get_active_modifiers
     (xdo : xdo_t_const_access;
      keys : System.Address;
      nkeys : access int) return int;  -- ./xdo.h:806
   pragma Import (C, xdo_get_active_modifiers, "xdo_get_active_modifiers");

  --*
  -- * Send any events necessary to clear the active modifiers.
  -- * For example, if you are holding 'alt' when xdo_get_active_modifiers is 
  -- * called, then this method will send a key-up for 'alt'
  --  
   function xdo_clear_active_modifiers
     (xdo : xdo_t_const_access;
      the_window : Window;
      active_mods : charcodemap_t_access;
      active_mods_n : int) return int;  -- ./xdo.h:814
   pragma Import (C, xdo_clear_active_modifiers, "xdo_clear_active_modifiers");

  --*
  -- * Send any events necessary to make these modifiers active.
  -- * This is useful if you just cleared the active modifiers and then wish
  -- * to restore them after.
  --  
   function xdo_set_active_modifiers
     (xdo : xdo_t_const_access;
      the_window : Window;
      active_mods : charcodemap_t_access;
      active_mods_n : int) return int;  -- ./xdo.h:823
   pragma Import (C, xdo_set_active_modifiers, "xdo_set_active_modifiers");

  --*
  -- * Get the position of the current viewport.
  -- *
  -- * This is only relevant if your window manager supports
  -- * _NET_DESKTOP_VIEWPORT 
  --  
   function xdo_get_desktop_viewport
     (xdo : xdo_t_const_access;
      x_ret : access int;
      y_ret : access int) return int;  -- ./xdo.h:833
   pragma Import (C, xdo_get_desktop_viewport, "xdo_get_desktop_viewport");

  --*
  -- * Set the position of the current viewport.
  -- *
  -- * This is only relevant if your window manager supports
  -- * _NET_DESKTOP_VIEWPORT
  --  
   function xdo_set_desktop_viewport
     (xdo : xdo_t_const_access;
      x : int;
      y : int) return int;  -- ./xdo.h:841
   pragma Import (C, xdo_set_desktop_viewport, "xdo_set_desktop_viewport");

  --*
  -- * Kill a window and the client owning it.
  -- *
  --  
   function xdo_kill_window (xdo : xdo_t_const_access; 
                             the_window : Window) return int;  -- ./xdo.h:847
   pragma Import (C, xdo_kill_window, "xdo_kill_window");

  --*
  -- * Close a window without trying to kill the client.
  -- *
  --  
   function xdo_close_window (xdo : xdo_t_const_access; 
                              the_window : Window) return int;  -- ./xdo.h:853
   pragma Import (C, xdo_close_window, "xdo_close_window");

  --*
  -- * Request that a window close, gracefully.
  -- *
  --  
   function xdo_quit_window (xdo : xdo_t_const_access; 
                             the_window : Window) return int;  -- ./xdo.h:859
   pragma Import (C, xdo_quit_window, "xdo_quit_window");

  --*
  -- * Find a client window that is a parent of the window given
  --  

  --*
  -- * Find a client window (child) in a given window. Useful if you get the
  -- * window manager's decorator window rather than the client window.
  --  
   function xdo_find_window_client
     (xdo : xdo_t_const_access;
      the_window : Window;
      window_ret : access Window;
      direction : int) return int;  -- ./xdo.h:875
   pragma Import (C, xdo_find_window_client, "xdo_find_window_client");

  --*
  -- * Get a window's name, if any.
  -- *
  -- * @param window window to get the name of.
  -- * @param name_ret character pointer pointer where the address of the window name will be stored.
  -- * @param name_len_ret integer pointer where the length of the window name will be stored.
  -- * @param name_type integer pointer where the type (atom) of the window name will be stored.
  --  
   function xdo_get_window_name
     (xdo : xdo_t_const_access;
      the_window : Window;
      name_ret : System.Address;
      name_len_ret : access int;
      name_type : access int) return int;  -- ./xdo.h:886
   pragma Import (C, xdo_get_window_name, "xdo_get_window_name");

  --*
  -- * Disable an xdo feature.
  -- *
  -- * This function is mainly used by libxdo itself, however, you may find it useful
  -- * in your own applications.
  -- * 
  -- * @see XDO_FEATURES
  --  
   procedure xdo_disable_feature (xdo : xdo_t_access; feature : int);  -- ./xdo.h:898
   pragma Import (C, xdo_disable_feature, "xdo_disable_feature");

  --*
  -- * Enable an xdo feature.
  -- *
  -- * This function is mainly used by libxdo itself, however, you may find it useful
  -- * in your own applications.
  -- * 
  -- * @see XDO_FEATURES
  --  
   procedure xdo_enable_feature (xdo : xdo_t_access; feature : int);  -- ./xdo.h:908
   pragma Import (C, xdo_enable_feature, "xdo_enable_feature");

  --*
  -- * Check if a feature is enabled.
  -- *
  -- * This function is mainly used by libxdo itself, however, you may find it useful
  -- * in your own applications.
  -- * 
  -- * @see XDO_FEATURES
  --  
   function xdo_has_feature (xdo : xdo_t_access; feature : int) return int;  -- ./xdo.h:918
   pragma Import (C, xdo_has_feature, "xdo_has_feature");

  --*
  -- * Query the viewport (your display) dimensions
  -- *
  -- * If Xinerama is active and supported, that api internally is used.
  -- * If Xineram is disabled, we will report the root window's dimensions
  -- * for the given screen.
  --  
   function xdo_get_viewport_dimensions
     (xdo : xdo_t_access;
      width : access unsigned;
      height : access unsigned;
      screen : int) return int;  -- ./xdo.h:927
   pragma Import (C, xdo_get_viewport_dimensions, "xdo_get_viewport_dimensions");

  -- extern "C"  
end xdo;
