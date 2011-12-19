package ivis.view
{
	import flare.vis.Visualization;
	import flare.vis.data.DataSprite;
	
	import flash.display.DisplayObject;
	import flash.filters.GlowFilter;
	
	import ivis.model.Edge;
	import ivis.model.Graph;
	import ivis.model.Node;
	import ivis.util.GeneralUtils;
	import ivis.util.Groups;
	
	import mx.core.UIComponent;

	/**
	 * This class is designed to represent the view of the graph.
	 * 
	 * @author Selcuk Onur Sumer
	 */
	public class GraphView extends UIComponent
	{
		protected var _vis:GraphVisualization;
		protected var _graph:Graph;
		
		//--------------------------- ACCESSORS --------------------------------
		
		/**
		 * Visualization instance for this graph.
		 */
		public function get vis():GraphVisualization
		{
			return _vis;
		}

		// TODO it may be better to make graph inaccessible outside GraphView
		/**
		 * Graph model.
		 */
		public function get graph():Graph
		{
			return _graph;
		}
		
		public function set graph(graph:Graph):void
		{
			_graph = graph;
		}
		
		
		//------------------------- CONSTRUCTOR --------------------------------
		
		public function GraphView(graph:Graph)
		{
			this.graph = graph;
			this._vis = new GraphVisualization(this.graph.graphData);
			this.addChild(this.vis);
			
			// TODO props.labelText as default?
			this.vis.nodeLabeler = new NodeLabeler("props.labelText");
			this.vis.compoundLabeler = new CompoundNodeLabeler("props.labelText");
			this.vis.edgeLabeler = new EdgeLabeler("props.labelText");
		}
		
		//---------------------- PUBLIC FUNCTIONS ------------------------------
		
		/**
		 * Updates the view.
		 */
		public function update():void
		{
			this.vis.update();
		}
		
		/**
		 * Removes the given label from the view.
		 * 
		 * @param label	label to be removed
		 */
		public function removeLabel(label:DisplayObject):void
		{
			this.vis.labels.removeChild(label);
		}
		
		/**
		 * Updates labels for the given data group.
		 * 
		 * @param group	name of the data group
		 */
		public function updateLabels(group:String):void
		{
			this.vis.updateLabels(group);
		}
		
		/**
		 * Updates bounds of all compound nodes.
		 */
		public function updateAllCompoundBounds():void
		{
			this.vis.updateAllCompoundBounds();
		}
		
		/**
		 * Updates the bounds of the given compound node.
		 * 
		 * @param compound	compound node to be updated
		 */
		public function updateCompoundBounds(compound:Node):void
		{
			this.vis.updateCompoundBounds(compound);
		}
		
		/**
		 * If the given graph element (node or edge) is not selected, selects it
		 * by setting corresponding flags and adding the element to the
		 * corresponding data group. If the graph element is already selected,
		 * unselects it by resetting flags and removing element from the
		 * corresponding data group.
		 * 
		 * @param eventTarget	target object to be selected/unselected
		 * @return				true if successful, false otherwise
		 */
		public function toggleSelect(eventTarget:Object):Boolean
		{
			var result:Boolean = false;
			
			if (eventTarget is DataSprite)
			{
				// deselect the node
				if ((eventTarget as DataSprite).props.$selected)
				{
					result = this.deselectElement(eventTarget);
				}
				// select the node
				else
				{
					result = this.selectElement(eventTarget);
				}
			}
			
			return result;
		}
		
		/**
		 * If the given graph element (node or edge) is not selected, selects it
		 * by setting corresponding flags and adding the element to the
		 * corresponding data group.
		 * 
		 * @param eventTarget	target object to be selected
		 * @return				true if successful, false otherwise
		 */
		public function selectElement(eventTarget:Object):Boolean
		{
			var result:Boolean = false;
			
			if (eventTarget is DataSprite)
			{
				trace("[GraphView.selectElement] " + 
					(eventTarget as DataSprite).data.id + " is selected");
				
				if (eventTarget is Node)
				{
					this.selectNode(eventTarget as Node);
				}
				else if (eventTarget is Edge)
				{
					this.selectEdge(eventTarget as Edge);
				}
				
				result = true;
			}
			
			return result;
		}
		
		/**
		 * If the given graph element (node or edge) is selected, deselects it
		 * by resetting corresponding flags and removing the element from the
		 * corresponding data group.
		 * 
		 * @param eventTarget	target object to be selected
		 * @return				true if successful, false otherwise
		 */
		public function deselectElement(eventTarget:Object):Boolean
		{
			var result:Boolean = false;
			
			if (eventTarget is DataSprite)
			{
				trace("[GraphView.deselectElement] " + 
					(eventTarget as DataSprite).data.id + " is deselected");
				
				if (eventTarget is Node)
				{
					this.deselectNode(eventTarget as Node);
				}
				else if (eventTarget is Edge)
				{
					this.deselectEdge(eventTarget as Edge);
				}
				
				result = true;
			}
			
			return result;
		}
		
		/**
		 * Highlights the given target Node or Edge by adding a GlowFilter to
		 * the sprite. If the eventTarget is not an Node or Edge instance,
		 * it is not highlighted.
		 * 
		 * @param eventTarget	target object to be highlighted
		 * @return				highlighted DataSprite if successful, null o.w.
		 */
		public function highlight(eventTarget:Object):DataSprite
		{
			var ds:DataSprite = null;
			
			var filter:GlowFilter;
			var alpha:Number;
			var blur:Number;
			var strength:Number;
			var color:uint;
			
			// TODO other selection properties? 
			/*
				selectionLineColor: "#8888ff",
				selectionLineOpacity: 0.8,
				selectionLineWidth: 1,
				selectionFillColor: "#8888ff",
				selectionFillOpacity: 0.1
			*/
			
			if (eventTarget is DataSprite)
			{
				ds = eventTarget as DataSprite;
				
				alpha = ds.props.selectionGlowAlpha;
				blur = ds.props.selectionGlowBlur;
				strength = ds.props.selectionGlowStrength; 
				
				if (alpha > 0 &&
					blur > 0 &&
					strength > 0)
				{
					color = ds.props.selectionGlowColor;
					filter = new GlowFilter(color, alpha, blur, blur, strength);
					
					// add new filter to the sprite's filter list
					var filters:Array = ds.filters;
					
					// just calling ds.filters.push() does not update view!
					// ds.filter should be reset explicitly
					ds.props.$glowFilter = filter;
					filters.push(filter);
					ds.filters = filters;
				}
			}
			
			return ds;
		}
		
		// TODO may need to move to Node and Edge classes...
		public function removeFilter(ds:DataSprite, filter:*) : void
		{
			// remove the given filter from the filter array of sprite
			var idx:int = ds.filters.indexOf(filter);
			
			if (idx != -1)
			{
				ds.filters = ds.filters.slice(0, idx).concat(
					ds.filters.slice(idx+1));
			}
			
			// TODO workaround, above code does not work yet... 
			ds.filters = null;
		}
		
		//---------------------- PROTECTED FUNCTIONS ---------------------------
		
		/**
		 * Selects the specified node by highlighting it.
		 * 
		 * @param node	node to be selected
		 */
		protected function selectNode(node:Node):void
		{
			if (!node.props.$selected)
			{
				// mark node as selected
				node.props.$selected = true;
				
				// add node to the corresponding data group
				this.graph.addToGroup(Groups.SELECTED_NODES, node);
				
				// highlight selected node
				this.highlight(node);
			}
		}
		
		/**
		 * Selects the specified edge by highlighting the edge itself and
		 * child components (bend points and segments) if necessary.
		 * 
		 * @param edge	edge to be selected
		 */
		protected function selectEdge(edge:Edge):void
		{
			var parent:Edge = edge;
			
			if (!edge.props.$selected)
			{
				// edge is a segment, so select other segments of the
				// parent edge
				if (edge.isSegment)
				{
					for each (var segment:Edge in edge.parentE.getSegments())
					{
						segment.props.$selected = true;
						
						this.graph.addToGroup(Groups.SELECTED_EDGES, segment);
						
						this.highlight(segment);
					}
					
					parent = edge.parentE;
				}
				
				// select the parent edge
				parent.props.$selected = true;
				this.graph.addToGroup(Groups.SELECTED_EDGES, parent);			
				
				// highligh edge if it is visible 
				if (parent == edge)
				{
					this.highlight(parent);
				}
			}
		}
		
		/**
		 * Removes the selection of the specified node.
		 * 
		 * @param node	node to be deselected
		 */ 
		protected function deselectNode(node:Node):void
		{
			if (node.props.$selected)
			{
				// mark node as unselected
				node.props.$selected = false;
				
				// remove node from the corresponding data group
				this.graph.removeFromGroup(Groups.SELECTED_NODES, node);
				
				// remove highlight of the node (remove glow filter)
				this.removeFilter(node, node.props.$glowFilter);
			}
		}
		
		/**
		 * Removes the selection of the specified edge.
		 * 
		 * @param edge	edge to be deselected
		 */
		protected function deselectEdge(edge:Edge):void
		{
			var parent:Edge = edge;
			var idx:int;
			
			if (edge.props.$selected)
			{
				// edge is a segment, so deselect other segments of the
				// parent edge
				if (edge.isSegment)
				{
					for each (var segment:Edge in edge.parentE.getSegments())
					{
						// mark segment as unselected
						segment.props.$selected = false;
						
						// remove segment from corresponding data group
						this.graph.removeFromGroup(Groups.SELECTED_EDGES,
							segment);
						
						// remove highlight of the segment (remove glow filter)
						this.removeFilter(segment, segment.props.$glowFilter);
						
					}
					
					parent = edge.parentE;
				}
				
				// unselect the parent edge
				parent.props.$selected = false;
				
				this.graph.removeFromGroup(Groups.SELECTED_EDGES, parent);
				
				// remove highlight of the parent (remove glow filter)
				this.removeFilter(parent, parent.props.$glowFilter);
			}
		}
	}
}