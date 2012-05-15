#!/usr/bin/env ruby
# 
# Copyright © 2011 Chris Riddoch
# This software is licensed under the LGPL 2.1

require 'rubygems'
require 'ffi'

module XDo
  extend FFI::Library
  ffi_lib 'xdo'

  # a Window, (X11/X.h typedefs Window to XID, and XID is typedef'd as a CARD32,
  #            X11/Xmd.h typedefs CARD32 to an unsigned 32-bit value)
  typedef :uint32, :xid
  typedef :xid, :window

  # an atom is also typedefed as a CARD32. 
  typedef :xid, :atom

  # Same as tv_usec
  typedef :int32, :useconds_t

  # Um... yeah.  Please tell me if this is wrong on your platform.
  # Or a better way to define this.
  typedef :int, :wchar_t

  class XDo < FFI::Struct
    layout :xdpy, :pointer, # Display *
           :display_name, :string,
           :charcodes, :pointer, # CharCodeMap *
           :charcodes_len, :int,
           :modmap, :pointer, # XModifierKeymap *
           :keymap, :pointer, # KeySym *
           :keycode_high, :int,
           :keycode_low, :int,
           :keysyms_per_keycode, :int,
           :close_display_when_freed, :int,
           :quiet, :int,
           :debug, :int,
           :features_mask, :int
  end

  typedef :uchar, :keycode
  typedef :xid, :keysym

  class KeysymCharmap < FFI::Struct
    layout :keysym, :string,
           :key, :wchar_t
  end

  class CharcodeMap < FFI::Struct
    layout :key, :wchar_t, # the letter for this key, like 'a'
           :code, :keycode, # the keycode that this key is on
           :symbol, :keysym, # the symbol representing this key
           :index, :int,    # the index in the keysym-per-keycode list that is this key
           :modmask, :int,  # the modifiers activated by this key.
           :needs_binding, :int  # if this key need to be bound at runtime because it does not
                                 # exist in the current keymap, this will be set to 1.
  end

  class ActiveMods < FFI::Struct
    layout :keymods, :pointer, # charcodemap_t *
           :nkeymods, :int,
           :input_state, :uint
  end

  SearchRequire = enum(:any, :all)

  class Search < FFI::Struct
    layout :title, :string,
           :winclass, :string,
           :winclassname, :string,
           :winname, :string,
           :pid, :int,
           :max_depth, :long,
           :only_visible, :int,
           :screen, :int,
           :require, SearchRequire,
           :searchmask, :uint,
           :desktop, :long,
           :limit, :uint
  end


  attach_function 'xdo_version', [], :string

  attach_function 'xdo_new', [:string], :pointer
  attach_function 'xdo_free', [:pointer], :void
  
  # Params: a pointer to Display, given by previous XOpenDisplay
  #         a string, the display name
  #         an int, if 1, the display will be closed when xdo_free is called.  Otherwise it's left open.
  attach_function 'xdo_new_with_opened_display', [:pointer, :string, :int], :pointer

  # Params:
  #  xdo pointer
  #  x
  #  y
  #  screen number
  attach_function 'xdo_mousemove', [:pointer, :int, :int, :int], :int

  # Params:
  #  xdo pointer
  #  window
  #  x
  #  y
  attach_function 'xdo_mousemove_relative_to_window', [:pointer, :window, :int, :int], :int

  attach_function 'xdo_mousemove_relative', [:pointer, :int, :int], :int

  # Params:
  # xdo pointer
  # window
  # button - normally, 1 = left, 2 = middle, 3 = right, 4 = wheel up, 5 = wheel down
  attach_function 'xdo_mousedown', [:pointer, :window, :int], :int
  attach_function 'xdo_mouseup', [:pointer, :window, :int], :int

  # Params:
  # xdo pointer
  # pointer to int where x coord will be stored
  # pointer to int where y coord will be stored
  # pointer to int where screen number will be stored
  attach_function 'xdo_mouselocation', [:pointer, :pointer, :pointer, :pointer], :int

  # Params:
  # xdo pointer
  # pointer to a window where the window will be stored
  attach_function 'xdo_mousewindow', [:pointer, :pointer], :int

  # Params:
  # xdo pointer
  # pointer to int where x coord will be stored
  # pointer to int where y coord will be stored
  # pointer to int where screen number will be stored
  # pointer to a window where the window will be stored
  attach_function 'xdo_mouselocation2', [:pointer, :pointer, :pointer, :pointer, :pointer], :int

  # Params
  # xdo pointer
  # the X position you expect the mouse to move from/to
  # the Y position you expect the mouse to move from/to
  attach_function 'xdo_mouse_wait_for_move_from', [:pointer, :int, :int], :int
  attach_function 'xdo_mouse_wait_for_move_to', [:pointer, :int, :int], :int

  # Params
  # xdo pointer
  # The window you want to send the event to or CURRENTWINDOW
  # the button to click
  attach_function 'xdo_click', [:pointer, :window, :int], :int

  # Params
  # 1st 3 like xdo_click
  # 4: number of times.  'repeat'
  # 5: delay between clicks.
  attach_function 'xdo_click_multiple', [:pointer, :window, :int, :int, :useconds_t], :int

  # Params
  # xdo pointer
  # window to send to
  # text to type
  # delay between keystrokes in microseconds (12000 is a decent choice if you don't have other plans.)
  attach_function 'xdo_type', [:pointer, :window, :string, :useconds_t], :int

  # Params are like xdo_type, except the string sends a by symbol name.
  # e.g. "l", "semicolon", "alt+Return", "Alt_L+Tab"
  attach_function 'xdo_keysequence', [:pointer, :window, :string, :useconds_t], :int
  attach_function 'xdo_keysequence_down', [:pointer, :window, :string, :useconds_t], :int
  attach_function 'xdo_keysequence_up', [:pointer, :window, :string, :useconds_t], :int

  # Params:
  # xdo pointer, window to send to,
  # keys: pointer to the array of charcodemap_t entities to send
  # nkeys: length of keys parameter
  # pressed: 1 for key press, 0 for key release.
  # modifier: pointer to integer to record the modifiers activated by the keys being pressed. If NULL, we don't save the modifiers.
  # delay: between keystrokes in microseconds.
  attach_function 'xdo_keysequence_list_do', [:pointer, :window, :pointer, :int, :int, :pointer, :useconds_t], :int

  # Params:
  # xdo pointer
  # keys: pointer to array of charcodemap_t that will be allocated by this function.
  # nkeys: Pointer to integer where the number of keys will be stored
  attach_function 'xdo_active_keys_to_keycode_list', [:pointer, :pointer, :pointer], :int

  # Params:
  # xdo pointer, window,
  # map_state
  attach_function 'xdo_window_wait_for_map_state', [:pointer, :window, :int], :int

  # Params
  # xdo pointer, window, width, height, flags, to_or_from (0 or 1, respectively)
  attach_function 'xdo_window_wait_for_size', [:pointer, :window, :uint, :uint, :int, :int], :int

  # Params
  # xdo pointer, window, x coord, y coord (to move to)
  attach_function 'xdo_window_move', [:pointer, :window, :int, :int], :int

  # Params
  # xdo pointer, window, width, height, 
  # width_ret: pointer to int, the return location of the translated width
  # height_ret: pointer to int, the return location of the translated height
  attach_function 'xdo_window_translate_with_sizehint', [:pointer, :window, :int, :int, :pointer, :pointer], :int

  # Params
  # xdo pointer, window,
  # width: new width
  # height: new height
  # flags: if 0, use pixels for units. If SIZE_USEHINTS, then the units will be relative to the window size hints.
  attach_function 'xdo_window_setsize', [:pointer, :window, :int, :int, :int], :int

  # Params
  # xdo pointer, window,
  # property - string
  # value - string
  attach_function 'xdo_window_setprop', [:pointer, :window, :string, :string], :int

  # Params
  # xdo pointer, window,
  # name: string, The new class name. If NULL, no change.
  # class: string, The new class. If NULL, no change
  attach_function 'xdo_window_setclass', [:pointer, :window, :string, :string], :int

  # Params
  # xdo pointer, window,
  # urgency
  attach_function 'xdo_window_seturgency', [:pointer, :window, :int], :int

  # Params
  # xdo pointer, window,
  # override_redirect:
  #   0: the window manager will see it like a normal application window.
  #   1: the window manager will usually not draw borders on the window, etc.
  attach_function 'xdo_window_set_override_redirect', [:pointer, :window, :int], :int

  
  attach_function 'xdo_window_focus', [:pointer, :window], :int
  attach_function 'xdo_window_raise', [:pointer, :window], :int
  
  # Params
  # xdo pointer
  # Pointer to a window where the currently-focused window will be stored.
  attach_function 'xdo_window_get_focus', [:pointer, :pointer], :int

  # Params
  # xdo pointer, window
  # want_focus: If 1, wait for focus. If 0, wait for loss of focus.
  attach_function 'xdo_window_wait_for_focus', [:pointer, :window, :int], :int

  # Params
  # xdo pointer, window.
  # Return value is PID or 0 if no pid found
  attach_function 'xdo_window_get_pid', [:pointer, :window], :int

  # Params, xdo pointer, pointer to window where the currently focused window will be stored
  #
  # Like xdo_window_get_focus, but return the first ancestor-or-self window *
  # having a property of WM_CLASS. This allows you to get the "real" or
  # top-level-ish window having focus rather than something you may not expect
  # to be the window having focused.
  attach_function 'xdo_window_sane_get_focus', [:pointer, :pointer], :int

  # Params
  # xdo pointer, window
  attach_function 'xdo_window_activate', [:pointer, :window], :int
  attach_function 'xdo_window_wait_for_active', [:pointer, :window, :int], :int
  
  # Map a window. This mostly means to make the window visible if it is not currently mapped. 
  attach_function 'xdo_window_map', [:pointer, :window], :int
  attach_function 'xdo_window_unmap', [:pointer, :window], :int

  # Params
  # xdo pointer, window
  attach_function 'xdo_window_minimize', [:pointer, :window], :int

  # Params:
  # xdo pointer
  # source, target
  attach_function 'xdo_window_reparent', [:pointer, :window, :window], :int

  # Params
  # xdo pointer, window
  # pointer to int where x location is stored
  # pointer to int where y location is stored
  # pointer to pointer to Screen - where the Screen* the window on is stored. If NULL, this parameter is ignored.
  attach_function 'xdo_get_window_location', [:pointer, :window, :pointer, :pointer, :pointer], :int
  
  # Params
  # xdo pointer, window
  # pointer to unsigned int where the width is stored.
  # pointer to unsigned int where the height is stored.
  attach_function 'xdo_get_window_size', [:pointer, :window, :pointer, :pointer], :int

  # Params
  # xdo pointer, window pointer
  attach_function 'xdo_window_get_active', [:pointer, :pointer], :int
 
  # Params
  # xdo pointer, window pointer
  attach_function 'xdo_window_select_with_click', [:pointer, :pointer], :int

  # Params
  # xdo pointer
  # number of desktops
  attach_function 'xdo_set_number_of_desktops', [:pointer, :long], :int
  attach_function 'xdo_get_number_of_desktops', [:pointer, :pointer], :int

  # Params
  # xdo pointer
  # desktop number
  attach_function 'xdo_set_current_desktop', [:pointer, :long], :int
  attach_function 'xdo_get_current_desktop', [:pointer, :pointer], :int

  # Params
  # xdo pointer, window
  # desktop number
  attach_function 'xdo_set_desktop_for_window', [:pointer, :window, :long], :int
  attach_function 'xdo_get_desktop_for_window', [:pointer, :window, :pointer], :int
  
  # Params
  # xdo pointer,
  # pointer to a xdo_search_t (XDo::Search class, here)
  # pointer to a pointer of window - list of matching windows to return.
  # pointer to int - number of windows matched
  attach_function 'xdo_window_search', [:pointer, :pointer, :pointer, :pointer], :int

  # Params
  # xdo pointer
  # window to query
  # atom to fetch
  # pointer to long - the number of items
  # pointer to atom - the type of the return
  # pointer to int - size
  # Return value: data consisting of 'nitems' items of size 'size' and type 'type',
  #    will need to be cast to the type before using.
  attach_function 'xdo_getwinprop', [:pointer, :window, :atom, :pointer, :pointer, :pointer], :string

  # Params
  # xdo pointer
  # Return value: a mask value containing any of the following:
  # ShiftMask, LockMask, ControlMask, Mod1Mask, Mod2Mask, Mod3Mask, Mod4Mask, or Mod5Mask
  attach_function 'xdo_get_input_state', [:pointer], :uint

  # Return value: pointer to a keysym_charmap_t
  # If you need the keysym-to-character map, you can fetch it using this method.
  attach_function 'xdo_keysym_charmap', [:void], :pointer
  
  # Return value: Array of strings (const char **)
  # If you need the symbol map, use this method.
  # The symbol map is an array of string pairs mapping common tokens to X Keysym strings
  # e.g. "alt" to "Alt_L"
  attach_function 'xdo_symbol_map', [:void], :pointer
  
  # Parameters: xdo pointer
  # Returns: pointer to xdo_active_mods_t
  attach_function 'xdo_get_active_modifiers', [:pointer], :pointer
  
  # Parameters:
  # xdo pointer, window
  # pointer to xdo_active_mods_t
  # Send any events necesary to clear the the active modifiers.
  # For example, if you are holding 'alt' when xdo_get_active_modifiers is called, then this method will send a key-up for 'alt'
  attach_function 'xdo_clear_active_modifiers', [:pointer, :window, :pointer], :int
  
  # Parameters
  # xdo pointer, window
  # pointer to xdo_active_mods_t
  # Send any events necessary to make these modifiers active.
  # This is useful if you just cleared the active modifiers and then wish to restore them after.
  attach_function 'xdo_set_active_modifiers', [:pointer, :window, :pointer], :int
  
  # Parameters:
  # pointer to xdo_active_mods_t
  # Free the data allocated by xdo_get_active_modifiers.
  attach_function 'xdo_free_active_modifiers', [:pointer], :void
  
  # Parameters:
  # pointer to int: x
  # pointer to int: y
  attach_function 'xdo_get_desktop_viewport', [:pointer, :pointer, :pointer], :int
  attach_function 'xdo_set_desktop_viewport', [:pointer, :int, :int], :int
  
  # Parameters:
  # xdo pointer, window
  attach_function 'xdo_window_kill', [:pointer, :window], :int
  
  # Parameters:
  # xdo pointer, window
  # pointer to a window
  # int - direction:
  #   0: Find a client window that is a parent of the window given
  #   1: Find a client window that is a child of the window given
  # Find a client window (child) in a given window. Useful if you get the
  # window manager's decorator window rather than the client window.
  attach_function 'xdo_window_find_client', [:pointer, :window, :pointer, :int], :int
  
  # Parameters:
  # xdo pointer, window
  # name_ret: pointer to pointer to char (list of strings)
  # name_len_ret: pointer to int
  # name_type: pointer to int
  # Get a window name, if any (undocumented upstream)
  attach_function 'xdo_get_window_name', [:pointer, :window, :pointer, :pointer, :pointer], :int
  
  # Parameters:
  # xdo pointer
  # feature: int
  attach_function 'xdo_disable_feature', [:pointer, :int], :void
  attach_function 'xdo_enable_feature', [:pointer, :int], :void
  attach_function 'xdo_has_feature', [:pointer, :int], :int

  # Parameters:
  # xdo pointer
  # width: pointer to uint
  # height: pointer to uint
  # screen: int
  attach_function 'xdo_get_viewport_dimensions', [:pointer, :pointer, :pointer, :int], :int

end


class XDoRuby
  def initialize()
    display = ""
    @xptr = XDo.xdo_new(display)
    if @xptr.nil?
      error "Couldn't get an xdo structure from xdo_new..."
    end
  end

  def library_version()
    XDo.xdo_version()
  end
  
  def use_active_window() 
    wptr = FFI::MemoryPointer.new(XDo::find_type(:window))
    r = XDo.xdo_window_get_active(@xptr, wptr)
    if r != 0
      error "Ack. Something went wrong."
    end
    @window = wptr.get_uint32(0)
  end

  def type(text, delay)
    XDo.xdo_type(@xptr, @window, text, delay)
  end

  def close()
    XDo.xdo_free(@xptr)
  end
end


x = XDoRuby.new()
puts "The version of Xdo is: #{x.library_version}"
x.use_active_window()
x.type("ls -l\n", 250)
x.close()


