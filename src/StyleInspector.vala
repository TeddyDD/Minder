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

public enum StyleAffects {
  ALL = 0,         // Applies changes to all nodes and connections
  SEP0,            // Indicates a separator (not a value)
  CURRENT,         // Applies changes to the current node/connection
  CURRTREE,        // Applies changes to the current tree
  CURRSUBTREE,     // Applies changes to the current nodes and all descendants
  SEP1,            // Indicates a separator (not a value)
  LEVEL0,          // Applies changes to all root nodes
  LEVEL1,          // Applies changes to all level-1 nodes
  LEVEL2,          // Applies changes to all level-2 nodes
  LEVEL3,          // Applies changes to all level-2 nodes
  LEVEL4,          // Applies changes to all level-2 nodes
  LEVEL5,          // Applies changes to all level-2 nodes
  LEVEL6,          // Applies changes to all level-2 nodes
  LEVEL7,          // Applies changes to all level-2 nodes
  LEVEL8,          // Applies changes to all level-2 nodes
  LEVEL9;          // Applies changes to all level-2 nodes

  /* Displays the label to display for this enumerated value */
  public string label() {
    switch( this ) {
      case ALL         :  return( _( "All" ) );
      case CURRENT     :  return( _( "Current" ) );
      case CURRTREE    :  return( _( "Current Tree" ) );
      case CURRSUBTREE :  return( _( "Current Node + Descendants" ) );
      case LEVEL0      :  return( _( "Root Nodes" ) );
      case LEVEL1      :  return( _( "Level 1 Nodes" ) );
      case LEVEL2      :  return( _( "Level 2 Nodes" ) );
      case LEVEL3      :  return( _( "Level 3 Nodes" ) );
      case LEVEL4      :  return( _( "Level 4 Nodes" ) );
      case LEVEL5      :  return( _( "Level 5 Nodes" ) );
      case LEVEL6      :  return( _( "Level 6 Nodes" ) );
      case LEVEL7      :  return( _( "Level 7 Nodes" ) );
      case LEVEL8      :  return( _( "Level 8 Nodes" ) );
      case LEVEL9      :  return( _( "Level 9 Nodes" ) );
    }
    return( "Unknown" );
  }

  /* Returns true if this is a separator */
  public bool is_separator() {
    return( (this == SEP0) || (this == SEP1) );
  }

  /* Returns the level associated with this value */
  public uint level() {
    return( (uint)this - (uint)LEVEL0 );
  }

}

public class StyleInspector : Box {

  private DrawArea                   _da;
  private Granite.Widgets.ModeButton _link_types;
  private Scale                      _link_width;
  private Switch                     _link_arrow;
  private Image                      _link_dash;
  private Granite.Widgets.ModeButton _node_borders;
  private Scale                      _node_borderwidth;
  private Switch                     _node_fill;
  private Scale                      _node_margin;
  private Scale                      _node_padding;
  private FontButton                 _font_chooser;
  private Switch                     _node_markup;
  private Image                      _conn_dash;
  private Image                      _conn_arrow;
  private Scale                      _conn_width;
  private Style                      _current_style;
  private StyleAffects               _affects;
  private Array<Gtk.MenuItem>        _affect_items;
  private Label                      _affects_label;
  private Box                        _branch_group;
  private Box                        _link_group;
  private Box                        _node_group;
  private Box                        _conn_group;

  public static Styles styles = new Styles();

  public StyleInspector( DrawArea da ) {

    Object( orientation:Orientation.VERTICAL, spacing:20 );

    _da            = da;
    _current_style = new Style.templated();

    /* Initialize the affects */
    _affects = StyleAffects.ALL;

    /* Create the UI for nodes */
    var affect = create_affect_ui();
    var box    = new Box( Orientation.VERTICAL, 0 );
    var sw     = new ScrolledWindow( null, null );
    var vp     = new Viewport( null, null );
    vp.set_size_request( 200, 600 );
    vp.add( box );
    sw.add( vp );

    _branch_group = create_branch_ui();
    _link_group   = create_link_ui();
    _node_group   = create_node_ui();
    _conn_group   = create_connection_ui();

    /* Pack the scrollwindow */
    box.pack_start( _branch_group, false, true );
    box.pack_start( _link_group,   false, true );
    box.pack_start( _node_group,   false, true );
    // box.pack_start( _conn_group,   false, true );

    /* Pack the elements into this widget */
    pack_start( affect, false, true );
    pack_start( sw,     true,  true, 10 );

    /* Listen for changes to the current node and connection */
    _da.node_changed.connect( handle_node_changed );
    _da.connection_changed.connect( handle_connection_changed );

    /* Update the UI */
    handle_ui_changed();

  }

  /* Creates the menubutton that changes the affect */
  private Box create_affect_ui() {

    var box  = new Box( Orientation.HORIZONTAL, 10 );
    var lbl  = new Label( _( "<b>Changes affect:</b>" ) );
    var mb   = new MenuButton();
    var menu = new Gtk.Menu();

    _affects_label = new Label( "" );

    lbl.use_markup = true;

    mb.add( _affects_label );
    mb.popup = menu;

    /* Allocate memory for menu items */
    _affect_items = new Array<Gtk.MenuItem>();

    /* Add all of the enumerations */
    EnumClass eclass = (EnumClass)typeof( StyleAffects ).class_ref();
    for( int i=0; i<eclass.n_values; i++ ) {
      var affect = (StyleAffects)eclass.get_value( i ).value;
      if( affect.is_separator() ) {
        var mi = new Gtk.SeparatorMenuItem();
        menu.add( mi );
        _affect_items.append_val( mi );
      } else {
        var mi = new Gtk.MenuItem.with_label( affect.label() );
        menu.add( mi );
        mi.activate.connect(() => { set_affects( affect ); });
        _affect_items.append_val( mi );
      }
    }
    menu.show_all();

    /* Pack the menubutton box */
    box.pack_start( lbl, false, false );
    box.pack_start( mb,  true,  true );

    return( box );

  }

  /* Adds the options to manipulate line options */
  private Box create_branch_ui() {

    var box = new Box( Orientation.VERTICAL, 0 );
    var sep = new Separator( Orientation.HORIZONTAL );

    var lbl = new Label( _( "<b>Branch Options</b>" ) );
    lbl.use_markup = true;
    lbl.xalign = (float)0;

    var cbox = new Box( Orientation.VERTICAL, 10 );
    cbox.border_width = 10;

    var branch_type = create_branch_type_ui();

    cbox.pack_start( branch_type, false, true );

    box.pack_start( lbl,  false, true );
    box.pack_start( cbox, false, true );
    box.pack_start( sep,  false, true, 10 );

    return( box );

  }

  /* Create the branch type UI */
  private Box create_branch_type_ui() {

    var box = new Box( Orientation.HORIZONTAL, 0 );
    box.homogeneous = true;

    var lbl = new Label( _( "Branch Style" ) );
    lbl.xalign = (float)0;

    /* Create the line types mode button */
    _link_types = new Granite.Widgets.ModeButton();
    _link_types.has_tooltip = true;
    _link_types.button_release_event.connect( branch_type_changed );
    _link_types.query_tooltip.connect( branch_type_show_tooltip );

    var link_types = styles.get_link_types();
    for( int i=0; i<link_types.length; i++ ) {
      _link_types.append_icon( link_types.index( i ).icon_name(), IconSize.SMALL_TOOLBAR );
    }

    box.pack_start( lbl,         false, true );
    box.pack_end(   _link_types, false, true );

    return( box );

  }

  /* Called whenever the user changes the current layout */
  private bool branch_type_changed( Gdk.EventButton e ) {
    var link_types = styles.get_link_types();
    if( _link_types.selected < link_types.length ) {
      _da.undo_buffer.add_item( new UndoStyleLinkType( _affects, link_types.index( _link_types.selected ), _da ) );
      apply_changes();
    }
    return( false );
  }

  /* Called whenever the tooltip needs to be displayed for the layout selector */
  private bool branch_type_show_tooltip( int x, int y, bool keyboard, Tooltip tooltip ) {
    if( keyboard ) {
      return( false );
    }
    var link_types = styles.get_link_types();
    int button_width = (int)(_link_types.get_allocated_width() / link_types.length);
    if( (x / button_width) < link_types.length ) {
      tooltip.set_text( link_types.index( x / button_width ).display_name() );
      return( true );
    }
    return( false );
  }

  /* Adds the options to manipulate line options */
  private Box create_link_ui() {

    var box = new Box( Orientation.VERTICAL, 0 );
    var sep = new Separator( Orientation.HORIZONTAL );

    var lbl = new Label( _( "<b>Link Options</b>" ) );
    lbl.use_markup = true;
    lbl.xalign = (float)0;

    var cbox = new Box( Orientation.VERTICAL, 10 );
    cbox.border_width = 10;

    var link_dash  = create_link_dash_ui();
    var link_width = create_link_width_ui();
    var link_arrow = create_link_arrow_ui();

    cbox.pack_start( link_dash,  false, true );
    cbox.pack_start( link_width, false, true );
    cbox.pack_start( link_arrow, false, true );

    box.pack_start( lbl,  false, true );
    box.pack_start( cbox, false, true );
    box.pack_start( sep,  false, true, 10 );

    return( box );

  }

  /* Create the link dash widget */
  private Box create_link_dash_ui() {

    var box = new Box( Orientation.HORIZONTAL, 0 );
    box.homogeneous = true;

    var lbl = new Label( _( "Line Dash" ) );
    lbl.xalign = (float)0;

    var menu   = new Gtk.Menu();
    var dashes = styles.get_link_dashes();

    _link_dash = new Image.from_surface( dashes.index( 0 ).make_icon() );

    for( int i=0; i<dashes.length; i++ ) {
      var dash = dashes.index( i );
      var img  = new Image.from_surface( dash.make_icon() );
      var mi   = new Gtk.MenuItem();
      mi.activate.connect(() => {
        _da.undo_buffer.add_item( new UndoStyleLinkDash( _affects, dash, _da ) );
        _link_dash.surface = img.surface;
        apply_changes();
      });
      mi.add( img );
      menu.add( mi );
    }

    menu.show_all();

    var mb = new MenuButton();
    mb.add( _link_dash );
    mb.popup = menu;

    box.pack_start( lbl, false, true );
    box.pack_end(   mb,  false, true );

    return( box );

  }

  /* Create widget for handling the width of a link */
  private Box create_link_width_ui() {

    var box = new Box( Orientation.HORIZONTAL, 0 );
    box.homogeneous = true;

    var lbl = new Label( _( "Line Width" ) );
    lbl.xalign = (float)0;

    _link_width = new Scale.with_range( Orientation.HORIZONTAL, 2, 8, 1 );
    _link_width.draw_value = false;

    for( int i=2; i<=8; i++ ) {
      if( (i % 2) == 0 ) {
        _link_width.add_mark( i, PositionType.BOTTOM, "%d".printf( i ) );
      } else {
        _link_width.add_mark( i, PositionType.BOTTOM, null );
      }
    }

    _link_width.change_value.connect( link_width_changed );

    box.pack_start( lbl,         false, true );
    box.pack_end(   _link_width, false, true );

    return( box );

  }

  /* Called whenever the user changes the link width value */
  private bool link_width_changed( ScrollType scroll, double value ) {
    if( value > 8 ) value = 8;
    _da.undo_buffer.add_item( new UndoStyleLinkWidth( _affects, (int)value, _da ) );
    apply_changes();
    return( false );
  }

  /* Creates the link arrow UI element */
  private Box create_link_arrow_ui() {

    var box = new Box( Orientation.HORIZONTAL, 5 );
    var lbl = new Label( _( "Link Arrow" ) );

    _link_arrow = new Switch();
    _link_arrow.set_active( false );  /* TBD */
    _link_arrow.button_release_event.connect( link_arrow_changed );

    box.pack_start( lbl,       false, false );
    box.pack_end( _link_arrow, false, false );

    return( box );

  }

  /* Called when the user clicks on the link arrow switch */
  private bool link_arrow_changed( Gdk.EventButton e ) {
    _da.undo_buffer.add_item( new UndoStyleLinkArrow( _affects, !_link_arrow.get_active(), _da ) );
    apply_changes();
    return( false );
  }

  /* Creates the options to manipulate node options */
  private Box create_node_ui() {

    var box = new Box( Orientation.VERTICAL, 5 );
    var sep = new Separator( Orientation.HORIZONTAL );

    var lbl = new Label( _( "<b>Node Options</b>" ) );
    lbl.use_markup = true;
    lbl.xalign     = (float)0;

    var cbox = new Box( Orientation.VERTICAL, 10 );
    cbox.border_width = 10;

    var node_border      = create_node_border_ui();
    var node_borderwidth = create_node_borderwidth_ui();
    var node_fill        = create_node_fill_ui();
    var node_margin      = create_node_margin_ui();
    var node_padding     = create_node_padding_ui();
    var node_font        = create_node_font_ui();
    var node_markup      = create_node_markup_ui();

    cbox.pack_start( node_border,      false, true );
    cbox.pack_start( node_borderwidth, false, true );
    cbox.pack_start( node_fill,        false, true );
    cbox.pack_start( node_margin,      false, true );
    cbox.pack_start( node_padding,     false, true );
    cbox.pack_start( node_font,        false, true );
    cbox.pack_start( node_markup,      false, true );

    box.pack_start( lbl,  false, true );
    box.pack_start( cbox, false, true );
    box.pack_start( sep,  false, true, 10 );

    return( box );

  }

  /* Creates the node border panel */
  private Box create_node_border_ui() {

    var box = new Box( Orientation.HORIZONTAL, 0 );
    var lbl = new Label( _( "Border Style" ) );

    /* Create the line types mode button */
    _node_borders = new Granite.Widgets.ModeButton();
    _node_borders.has_tooltip = true;
    _node_borders.button_release_event.connect( node_border_changed );
    _node_borders.query_tooltip.connect( node_border_show_tooltip );

    var node_borders = styles.get_node_borders();
    for( int i=0; i<node_borders.length; i++ ) {
      _node_borders.append_icon( node_borders.index( i ).icon_name(), IconSize.SMALL_TOOLBAR );
    }

    box.pack_start( lbl,           false, false );
    box.pack_end(   _node_borders, false, false );

    return( box );

  }

  /* Called whenever the user changes the current layout */
  private bool node_border_changed( Gdk.EventButton e ) {
    var node_borders = styles.get_node_borders();
    if( _node_borders.selected < node_borders.length ) {
      _da.undo_buffer.add_item( new UndoStyleNodeBorder( _affects, node_borders.index( _node_borders.selected ), _da ) );
    }
    return( false );
  }

  /* Called whenever the tooltip needs to be displayed for the layout selector */
  private bool node_border_show_tooltip( int x, int y, bool keyboard, Tooltip tooltip ) {
    if( keyboard ) {
      return( false );
    }
    var node_borders = styles.get_node_borders();
    int button_width = (int)(_node_borders.get_allocated_width() / node_borders.length);
    if( (x / button_width) < node_borders.length ) {
      tooltip.set_text( node_borders.index( x / button_width ).display_name() );
      return( true );
    }
    return( false );
  }

  /* Create widget for handling the width of a link */
  private Box create_node_borderwidth_ui() {

    var box = new Box( Orientation.HORIZONTAL, 0 );
    box.homogeneous = true;

    var lbl = new Label( _( "Border Width" ) );
    lbl.xalign = (float)0;

    _node_borderwidth = new Scale.with_range( Orientation.HORIZONTAL, 2, 8, 1 );
    _node_borderwidth.draw_value = false;

    for( int i=2; i<=8; i++ ) {
      if( (i % 2) == 0 ) {
        _node_borderwidth.add_mark( i, PositionType.BOTTOM, "%d".printf( i ) );
      } else {
        _node_borderwidth.add_mark( i, PositionType.BOTTOM, null );
      }
    }

    _node_borderwidth.change_value.connect( node_borderwidth_changed );

    box.pack_start( lbl,               false, true );
    box.pack_end(   _node_borderwidth, false, true );

    return( box );

  }

  /* Called whenever the user changes the link width value */
  private bool node_borderwidth_changed( ScrollType scroll, double value ) {
    _da.undo_buffer.add_item( new UndoStyleNodeBorderwidth( _affects, (int)value, _da ) );
    return( false );
  }

  /* Create the node fill UI */
  private Box create_node_fill_ui() {

    var box = new Box( Orientation.HORIZONTAL, 0 );
    var lbl = new Label( _( "Fill With Link Color") );
    lbl.xalign = (float)0;

    _node_fill = new Switch();
    _node_fill.button_release_event.connect( node_fill_changed );

    box.pack_start( lbl,        false, true );
    box.pack_end(   _node_fill, false, true );

    return( box );

  }

  /* Called whenever the node fill status changes */
  private bool node_fill_changed( Gdk.EventButton e ) {
    _da.undo_buffer.add_item( new UndoStyleNodeFill( _affects, !_node_fill.get_active(), _da ) );
    return( false );
  }

  /* Allows the user to change the node margin */
  private Box create_node_margin_ui() {

    var box = new Box( Orientation.HORIZONTAL, 0 );
    box.homogeneous = true;

    var lbl = new Label( _( "Margin" ) );
    lbl.xalign = (float)0;

    _node_margin = new Scale.with_range( Orientation.HORIZONTAL, 5, 20, 1 );
    _node_margin.draw_value = true;
    _node_margin.change_value.connect( node_margin_changed );

    box.pack_start( lbl,          false, true );
    box.pack_end(   _node_margin, false, true );

    return( box );

  }

  /* Called whenever the node margin value is changed */
  private bool node_margin_changed( ScrollType scroll, double value ) {
    if( (int)value > 20 ) {
      return( false );
    }
    _da.undo_buffer.add_item( new UndoStyleNodeMargin( _affects, (int)value, _da ) );
    return( false );
  }

  /* Allows the user to change the node padding */
  private Box create_node_padding_ui() {

    var box = new Box( Orientation.HORIZONTAL, 0 );
    box.homogeneous = true;

    var lbl = new Label( _( "Padding" ) );
    lbl.xalign = (float)0;

    _node_padding = new Scale.with_range( Orientation.HORIZONTAL, 5, 20, 2 );
    _node_padding.draw_value = true;
    _node_padding.change_value.connect( node_padding_changed );

    box.pack_start( lbl,           false, true );
    box.pack_end(   _node_padding, false, true );

    return( box );

  }

  /* Called whenever the node margin value is changed */
  private bool node_padding_changed( ScrollType scroll, double value ) {
    if( (int) value > 20 ) {
      return( false );
    }
    _da.undo_buffer.add_item( new UndoStyleNodePadding( _affects, (int)value, _da ) );
    apply_changes();
    return( false );
  }

  /* Creates the node font selector */
  private Box create_node_font_ui() {

    var box = new Box( Orientation.HORIZONTAL, 0 );
    var lbl = new Label( _( "Font" ) );
    lbl.xalign = (float)0;

    _font_chooser = new FontButton();
    _font_chooser.use_font = true;
    _font_chooser.font_set.connect(() => {
      var family = _font_chooser.get_font_family().get_name();
      var size   = _font_chooser.get_font_size();
      _da.undo_buffer.add_item( new UndoStyleNodeFont( _affects, family, size, _da ) );
    });

    box.pack_start( lbl,         false, true );
    box.pack_end( _font_chooser, false, true );

    return( box );

  }

  private Box create_node_markup_ui() {

    var box = new Box( Orientation.HORIZONTAL, 0 );
    var lbl = new Label( _( "Enable Markup" ) );
    lbl.xalign = (float)0;

    _node_markup = new Switch();
    _node_markup.button_release_event.connect( node_markup_changed );

    box.pack_start( lbl,        false, true );
    box.pack_end( _node_markup, false, true );

    return( box );

  }

  /* Called whenever the node fill status changes */
  private bool node_markup_changed( Gdk.EventButton e ) {
    _da.undo_buffer.add_item( new UndoStyleNodeMarkup( _affects, !_node_markup.get_active(), _da ) );
    return( false );
  }

  /* Creates the connection style UI */
  private Box create_connection_ui() {

    var box = new Box( Orientation.VERTICAL, 0 );
    var sep = new Separator( Orientation.HORIZONTAL );

    var lbl = new Label( _( "<b>Connection Options</b>" ) );
    lbl.use_markup = true;
    lbl.xalign = (float)0;

    var cbox = new Box( Orientation.VERTICAL, 10 );
    cbox.border_width = 10;

    var conn_dash  = create_connection_dash_ui();
    var conn_arrow = create_connection_arrow_ui();
    var conn_width = create_connection_width_ui();

    cbox.pack_start( conn_dash,  false, true );
    cbox.pack_start( conn_arrow, false, true );
    cbox.pack_start( conn_width, false, true );

    box.pack_start( lbl,  false, true );
    box.pack_start( cbox, false, true );
    box.pack_start( sep,  false, true, 10 );

    return( box );

  }

  /* Create the connection dash widget */
  private Box create_connection_dash_ui() {

    var box = new Box( Orientation.HORIZONTAL, 0 );
    box.homogeneous = true;

    var lbl = new Label( _( "Line Dash" ) );
    lbl.xalign = (float)0;

    var menu   = new Gtk.Menu();
    var dashes = styles.get_link_dashes();

    _conn_dash = new Image.from_surface( dashes.index( 0 ).make_icon() );

    for( int i=0; i<dashes.length; i++ ) {
      var dash = dashes.index( i );
      var img  = new Image.from_surface( dash.make_icon() );
      var mi   = new Gtk.MenuItem();
      mi.activate.connect(() => {
        _current_style.connection_dash = dash;
        _conn_dash.surface             = img.surface;
        apply_changes();
      });
      mi.add( img );
      menu.add( mi );
    }

    menu.show_all();

    var mb = new MenuButton();
    mb.add( _conn_dash );
    mb.popup = menu;

    box.pack_start( lbl, false, true );
    box.pack_end(   mb,  false, true );

    return( box );

  }

  /* Creates the connection arrow position UI */
  private Box create_connection_arrow_ui() {

    var box = new Box( Orientation.HORIZONTAL, 0 );
    box.homogeneous = true;

    var lbl = new Label( _( "Arrows" ) );
    lbl.xalign = (float)0;

    var menu         = new Gtk.Menu();
    string arrows[4] = {"none", "fromto", "tofrom", "both"};

    _conn_arrow = new Image.from_surface( Connection.make_arrow_icon( "fromto" ) );

    foreach (string arrow in arrows) {
      var img = new Image.from_surface( Connection.make_arrow_icon( arrow ) );
      var mi  = new Gtk.MenuItem();
      mi.activate.connect(() => {
        _current_style.connection_arrow = arrow;
        _conn_arrow.surface             = img.surface;
        apply_changes();
      });
      mi.add( img );
      menu.add( mi );
    }

    menu.show_all();

    var mb = new MenuButton();
    mb.add( _conn_arrow );
    mb.popup = menu;

    box.pack_start( lbl, false, true );
    box.pack_end(   mb,  false, true );

    return( box );

  }

  /* Create widget for handling the width of a connection */
  private Box create_connection_width_ui() {

    var box = new Box( Orientation.HORIZONTAL, 0 );
    box.homogeneous = true;

    var lbl = new Label( _( "Line Width" ) );
    lbl.xalign = (float)0;

    _conn_width = new Scale.with_range( Orientation.HORIZONTAL, 2, 8, 1 );
    _conn_width.draw_value = false;

    for( int i=2; i<=8; i++ ) {
      if( (i % 2) == 0 ) {
        _conn_width.add_mark( i, PositionType.BOTTOM, "%d".printf( i ) );
      } else {
        _conn_width.add_mark( i, PositionType.BOTTOM, null );
      }
    }

    _conn_width.change_value.connect( connection_width_changed );

    box.pack_start( lbl,         false, true );
    box.pack_end(   _conn_width, false, true );

    return( box );

  }

  /* Called whenever the user changes the link width value */
  private bool connection_width_changed( ScrollType scroll, double value ) {
    if( value > 8 ) value = 8;
    _current_style.connection_width = (int)value;
    apply_changes();
    return( false );
  }

  /* Sets the affects value and save the change to the settings */
  private void set_affects( StyleAffects affects ) {
    _affects             = affects;
    _affects_label.label = affects.label();
    switch( _affects ) {
      case StyleAffects.ALL     :
        update_ui_with_style( styles.get_global_style() );
        _branch_group.visible = true;
        _link_group.visible   = true;
        _node_group.visible   = true;
        _conn_group.visible   = true;
        break;
      case StyleAffects.LEVEL0  :
      case StyleAffects.LEVEL1  :
      case StyleAffects.LEVEL2  :
      case StyleAffects.LEVEL3  :
      case StyleAffects.LEVEL4  :
      case StyleAffects.LEVEL5  :
      case StyleAffects.LEVEL6  :
      case StyleAffects.LEVEL7  :
      case StyleAffects.LEVEL8  :
      case StyleAffects.LEVEL9  :
        update_ui_with_style( styles.get_style_for_level( _affects.level() ) );
        _branch_group.visible = true;
        _link_group.visible   = (_affects != StyleAffects.LEVEL0);
        _node_group.visible   = true;
        _conn_group.visible   = false;
        break;
      case StyleAffects.CURRENT :
        var node = _da.get_current_node();
        var conn = _da.get_current_connection();
        if( node != null ) {
          update_ui_with_style( node.style );
          _branch_group.visible = true;
          _link_group.visible   = true;
          _node_group.visible   = true;
          _conn_group.visible   = false;
        } else if( conn != null ) {
          update_ui_with_style( conn.style );
          _branch_group.visible = false;
          _link_group.visible   = false;
          _node_group.visible   = false;
          _conn_group.visible   = true;
        }
        break;
      case StyleAffects.CURRTREE :
        update_ui_with_style( _da.get_current_node().get_root().style );
        _branch_group.visible = true;
        _link_group.visible   = true;
        _node_group.visible   = true;
        _conn_group.visible   = false;
        break;
      case StyleAffects.CURRSUBTREE :
        update_ui_with_style( _da.get_current_node().style );
        _branch_group.visible = true;
        _link_group.visible   = true;
        _node_group.visible   = true;
        _conn_group.visible   = false;
        break;
    }
  }

  /* Apply the given style information based on the affects type */
  public static void apply_style_change( DrawArea da, StyleAffects affects, Style style, Node? node, Connection? conn ) {
    switch( affects ) {
      case StyleAffects.ALL     :
        styles.set_all_nodes_to_style( da.get_nodes(), style );
        styles.set_all_connections_to_style( da.get_connections(), style );
        break;
      case StyleAffects.LEVEL0  :
      case StyleAffects.LEVEL1  :
      case StyleAffects.LEVEL2  :
      case StyleAffects.LEVEL3  :
      case StyleAffects.LEVEL4  :
      case StyleAffects.LEVEL5  :
      case StyleAffects.LEVEL6  :
      case StyleAffects.LEVEL7  :
      case StyleAffects.LEVEL8  :
      case StyleAffects.LEVEL9  :
        styles.set_levels_to_style( da.get_nodes(), (1 << (int)affects.level()), style );
        break;
      case StyleAffects.CURRENT :
        if( node != null ) {
          node.style = style;
        } else if( conn != null ) {
          conn.style = style;
        }
        break;
      case StyleAffects.CURRTREE :
        styles.set_tree_to_style( node.get_root(), style );
        break;
      case StyleAffects.CURRSUBTREE :
        styles.set_tree_to_style( node, style );
        break;
    }
  }

  /* Apply the changes */
  private void apply_changes() {
    _da.changed();
    _da.queue_draw();
  }

  /* Checks the nodes in the given tree at the specified level to see if there are any non-leaf nodes */
  private bool check_level_for_branches( Node node, int levels, int level ) {
    if( (levels & (1 << level)) != 0 ) {
      return( !node.is_leaf() );
    } else {
      for( int i=0; i<node.children().length; i++ ) {
        if( check_level_for_branches( node.children().index( i ), levels, ((level == 9) ? 9 : (level + 1)) ) ) {
          return( true );
        }
      }
      return( false );
    }
  }

  /* We need to disable the link types widget if our affected nodes are leaf nodes only */
  private void update_link_types_state() {
    bool sensitive = false;
    switch( _affects ) {
      case StyleAffects.ALL     :
        for( int i=0; i<_da.get_nodes().length; i++ ) {
          if( !_da.get_nodes().index( i ).is_leaf() ) {
            sensitive = true;
            break;
          }
        }
        break;
      case StyleAffects.LEVEL0  :
      case StyleAffects.LEVEL1  :
      case StyleAffects.LEVEL2  :
      case StyleAffects.LEVEL3  :
      case StyleAffects.LEVEL4  :
      case StyleAffects.LEVEL5  :
      case StyleAffects.LEVEL6  :
      case StyleAffects.LEVEL7  :
      case StyleAffects.LEVEL8  :
      case StyleAffects.LEVEL9  :
        for( int i=0; i<_da.get_nodes().length; i++ ) {
          if( check_level_for_branches( _da.get_nodes().index( i ), (1 << (int)_affects.level()), 0 ) ) {
            sensitive = true;
            break;
          }
        }
        break;
      case StyleAffects.CURRENT :
        var node = _da.get_current_node();
        if( node != null ) {
          sensitive = !node.is_leaf();
        }
        break;
      case StyleAffects.CURRTREE :
        sensitive = !_da.get_current_node().get_root().is_leaf();
        break;
      case StyleAffects.CURRSUBTREE :
        sensitive = !_da.get_current_node().is_leaf();
        break;
    }
    _link_types.set_sensitive( sensitive );
  }

  private void update_link_types_with_style( Style style ) {
    var link_types = styles.get_link_types();
    for( int i=0; i<link_types.length; i++ ) {
      if( link_types.index( i ).name() == style.link_type.name() ) {
        _link_types.selected = i;
        break;
      }
    }
    update_link_types_state();
  }

  private void update_link_dashes_with_style( Style style ) {
    var link_dashes = styles.get_link_dashes();
    for( int i=0; i<link_dashes.length; i++ ) {
      if( link_dashes.index( i ).name == style.link_dash.name ) {
        _link_dash.surface = link_dashes.index( i ).make_icon();
        break;
      }
    }
  }

  private void update_node_borders_with_style( Style style ) {
    var node_borders = styles.get_node_borders();
    for( int i=0; i<node_borders.length; i++ ) {
      if( node_borders.index( i ).name() == style.node_border.name() ) {
        _node_borders.selected = i;
        break;
      }
    }
  }

  private void update_conn_dashes_with_style( Style style ) {
    var link_dashes = styles.get_link_dashes();
    for( int i=0; i<link_dashes.length; i++ ) {
      if( link_dashes.index( i ).name == style.connection_dash.name ) {
        _conn_dash.surface = link_dashes.index( i ).make_icon();
        break;
      }
    }
  }

  /* Update the user interface elements to match the selected level */
  private void update_ui_with_style( Style style ) {
    update_link_types_with_style( style );
    update_link_dashes_with_style( style );
    update_node_borders_with_style( style );
    update_conn_dashes_with_style( style );
    _link_width.set_value( (double)style.link_width );
    _link_arrow.set_active( style.link_arrow );
    _node_borderwidth.set_value( (double)style.node_borderwidth );
    _node_fill.set_active( (bool)style.node_fill );
    _node_fill.set_sensitive( style.node_border.is_fillable() );
    _node_margin.set_value( (double)style.node_margin );
    _node_padding.set_value( (double)style.node_padding );
    _font_chooser.set_font( style.node_font.to_string() );
    _node_markup.set_active( (bool)style.node_markup );
    _conn_arrow.surface = Connection.make_arrow_icon( style.connection_arrow );
    _conn_width.set_value( (double)style.connection_width );
  }

  /* Called whenever the current node changes */
  private void handle_node_changed() {
    Node? node = _da.get_current_node();
    if( node != null ) {
      update_ui_with_style( node.style );
    }
    handle_ui_changed();
  }

  /* Called whenever the current connection changes */
  private void handle_connection_changed() {
    Connection? conn = _da.get_current_connection();
    if( conn != null ) {
      update_ui_with_style( conn.style );
    }
    handle_ui_changed();
  }

  /* Called whenever the current node or connection changes */
  private void handle_ui_changed() {
    var curr_is_node = _da.get_current_node() != null;
    var curr_is_conn = _da.get_current_connection() != null;
    for( int i=0; i<_affect_items.length; i++ ) {
      var entry = _affect_items.index( i );
      switch( i ) {
        case StyleAffects.CURRENT     :  entry.visible = curr_is_node || curr_is_conn;  break;
        case StyleAffects.CURRTREE    :
        case StyleAffects.CURRSUBTREE :  entry.visible = curr_is_node;  break;
        case StyleAffects.SEP1        :  entry.visible = curr_is_node || curr_is_conn;  break;
        case StyleAffects.LEVEL0      :
        case StyleAffects.LEVEL1      :
        case StyleAffects.LEVEL2      :
        case StyleAffects.LEVEL3      :
        case StyleAffects.LEVEL4      :
        case StyleAffects.LEVEL5      :
        case StyleAffects.LEVEL6      :
        case StyleAffects.LEVEL7      :
        case StyleAffects.LEVEL8      :
        case StyleAffects.LEVEL9      :  entry.visible = !curr_is_conn;  break;
      }
    }
    if( curr_is_node || curr_is_conn ) {
      set_affects( StyleAffects.CURRENT );
    } else {
      set_affects( StyleAffects.ALL );
    }
  }

}
