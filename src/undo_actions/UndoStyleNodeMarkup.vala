/*
* Copyright (c) 2018 (https://github.com/phase1geo/Minder)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 2 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*
* Authored by: Trevor Williams <phase1geo@gmail.com>
*/

using Gtk;

public class UndoStyleNodeMarkup : UndoStyleChange {

  Array<bool> _values;

  /* Constructor for a node name change */
  public UndoStyleNodeMarkup( StyleAffects affects, bool node_markup, DrawArea da ) {
    base( affects, da );
    _values = new Array<bool>();
    _values.append_val( node_markup );
    load_styles( da );
  }

  protected override void load_style_value( Style style ) {
    _values.append_val( style.node_markup );
  }

  protected override void store_style_value( Style style, int index ) {
    style.node_markup = _values.index( index );
  }

}