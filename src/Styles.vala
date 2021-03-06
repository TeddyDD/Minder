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

public class Styles {

  private static Array<LinkType>   _link_types;
  private static Array<LinkDash>   _link_dashes;
  private static Array<NodeBorder> _node_borders;
  private        Array<Style>      _styles;

  /* Default constructor */
  public Styles() {

    /* Create the link types */
    var lt_straight = new LinkTypeStraight();
    var lt_squared  = new LinkTypeSquared();
    var lt_curved   = new LinkTypeCurved();

    /* Add the link types to the list */
    _link_types = new Array<LinkType>();
    _link_types.append_val( lt_straight );
    _link_types.append_val( lt_squared );
    _link_types.append_val( lt_curved );

    /* Create the link dashes */
    var ld_solid  = new LinkDash( "solid",     _( "Solid" ),      {} );
    var ld_dotted = new LinkDash( "dotted",    _( "Dotted" ),     {2, 6} );
    var ld_sdash  = new LinkDash( "shortdash", _( "Short Dash" ), {6, 6} );
    var ld_ldash  = new LinkDash( "longdash",  _( "Long Dash" ),  {20, 6} );

    /* Add the link dashes to the list */
    _link_dashes = new Array<LinkDash>();
    _link_dashes.append_val( ld_solid );
    _link_dashes.append_val( ld_dotted );
    _link_dashes.append_val( ld_sdash );
    _link_dashes.append_val( ld_ldash );

    /* Create the node borders */
    var nb_none       = new NodeBorderNone();
    var nb_underlined = new NodeBorderUnderlined();
    var nb_bracketed  = new NodeBorderBracket();
    var nb_squared    = new NodeBorderSquared();
    var nb_rounded    = new NodeBorderRounded();
    var nb_pilled     = new NodeBorderPill();

    /* Add the node borders to the list */
    _node_borders = new Array<NodeBorder>();
    _node_borders.append_val( nb_none );
    _node_borders.append_val( nb_underlined );
    _node_borders.append_val( nb_bracketed );
    _node_borders.append_val( nb_squared );
    _node_borders.append_val( nb_rounded );
    _node_borders.append_val( nb_pilled );

    /* Allocate styles for each level */
    _styles = new Array<Style>();
    for( int i=0; i<=10; i++ ) {
      var style = new Style();
      style.link_type  = lt_straight;
      style.link_width = 4;
      style.link_arrow = false;
      style.link_dash  = ld_solid;
      if( i == 0 ) {
        style.node_border = nb_rounded;
      } else {
        style.node_border = nb_underlined;
      }
      style.node_width       = 200;
      style.node_borderwidth = 4;
      style.node_fill        = false;
      style.node_margin      = 8;
      style.node_padding     = 6;
      style.node_markup      = true;
      style.connection_dash  = ld_dotted;
      style.connection_width = 2;
      style.connection_arrow = "fromto";
      _styles.append_val( style );
    }

  }

  /* Loads the contents of the style templates */
  public void load( Xml.Node* n ) {

    for( Xml.Node* it = n->children; it != null; it = it->next ) {
      if( it->type == Xml.ElementType.ELEMENT_NODE ) {
        if( it->name == "style" ) {
          string? l = it->get_prop( "level" );
          if( l != null ) {
            int level = int.parse( l );
            _styles.index( level ).load_node( it );
            _styles.index( level ).load_connection( it );
          }
        }
      }
    }

  }

  /* Saves the style template information */
  public void save( Xml.Node* parent ) {

    Xml.Node* node = new Xml.Node( null, "styles" );
    for( int i=0; i<_styles.length; i++ ) {
      Xml.Node* n = new Xml.Node( null, "style" );
      n->set_prop( "level", i.to_string() );
      _styles.index( i ).save_node_in_node( n );
      _styles.index( i ).save_connection_in_node( n );
      node->add_child( n );
    }

    parent->add_child( node );

  }

  /* Sets all nodes in the mind-map to the given link style */
  public void set_all_nodes_to_style( Array<Node> nodes, Style style ) {
    for( int i=0; i<=10; i++ ) {
      _styles.index( i ).copy( style );
    }
    set_all_nodes_to_style_helper( nodes, style );
  }

  /* Updates the nodes */
  private void set_all_nodes_to_style_helper( Array<Node> nodes, Style style ) {
    for( int i=0; i<nodes.length; i++ ) {
      nodes.index( i ).style = style;
      set_all_nodes_to_style_helper( nodes.index( i ).children(), style );
    }
  }

  /* Sets all of the connections to the given style */
  public void set_all_connections_to_style( Connections conns, Style style ) {
    _styles.index( 10 ).copy( style );
    conns.set_all_connections_to_style( style );
  }

  /* Sets the given tree/subtree to the given style */
  public void set_tree_to_style( Node parent, Style style ) {
    parent.style = style;
    var children = parent.children();
    for( int i=0; i<children.length; i++ ) {
      set_tree_to_style( children.index( i ), style );
    }
  }

  /* Sets all nodes at the specified levels to the given link style */
  public void set_levels_to_style( Array<Node> nodes, int levels, Style style ) {
    for( int i=0; i<10; i++ ) {
      if( (levels & (1 << i)) != 0 ) {
        _styles.index( i ).copy( style );
      }
    }
    set_levels_to_style_helper( nodes, levels, style, 0 );
  }

  /* Helper function for the set_levels_to_style */
  private void set_levels_to_style_helper( Array<Node> nodes, int levels, Style style, int level ) {
    for( int i=0; i<nodes.length; i++ ) {
      if( (levels & (1 << level)) != 0 ) {
        nodes.index( i ).style = style;
      }
      set_levels_to_style_helper( nodes.index( i ).children(), levels, style, ((level == 9) ? 9 : (level + 1)) );
    }
  }

  /* Returns the link type with the given name */
  public LinkType? get_link_type( string name ) {
    for( int i=0; i<_link_types.length; i++ ) {
      var link_type = _link_types.index( i );
      if( link_type.name() == name ) {
        return( link_type );
      }
    }
    return( null );
  }

  /* Returns the list of available link types */
  public Array<LinkType> get_link_types() {
    return( _link_types );
  }

  /* Returns the link dash with the given name */
  public LinkDash? get_link_dash( string name ) {
    for( int i=0; i<_link_dashes.length; i++ ) {
      var link_dash = _link_dashes.index( i );
      if( link_dash.name == name ) {
        return( link_dash );
      }
    }
    return( null );
  }

  /* Returns the list of available link dashes */
  public Array<LinkDash> get_link_dashes() {
    return( _link_dashes );
  }

  /* Returns the node border with the given name */
  public NodeBorder? get_node_border( string name ) {
    for( int i=0; i<_node_borders.length; i++ ) {
      var node_border = _node_borders.index( i );
      if( node_border.name() == name ) {
        return( node_border );
      }
    }
    return( null );
  }

  /* Return the list of available node borders */
  public Array<NodeBorder> get_node_borders() {
    return( _node_borders );
  }

  /* Returns the style for the given level */
  public Style get_style_for_level( uint level ) {
    return( _styles.index( (level > 9) ? 9 : level ) );
  }

  /* Returns the global style */
  public Style get_global_style() {
    return( _styles.index( 10 ) );
  }

}
