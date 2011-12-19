package ivis.view
{
	import flare.vis.data.DataList;
	import flare.vis.data.DataSprite;
	import flare.vis.data.EdgeSprite;
	import flare.vis.data.NodeSprite;
	
	import flash.geom.Point;
	
	import ivis.event.DataChangeEvent;
	import ivis.event.StyleChangeEvent;
	import ivis.model.Edge;
	import ivis.model.Graph;
	import ivis.model.IStyleAttachable;
	import ivis.model.Node;
	import ivis.model.Style;
	import ivis.model.util.Nodes;
	import ivis.model.util.Styles;
	import ivis.util.GeneralUtils;
	import ivis.util.Groups;

	/**
	 * This class is designed to handle changes in graph topology, graph
	 * geometry, and visual styles.
	 * 
	 * @author Selcuk Onur Sumer
	 */
	public class GraphManager
	{
		protected var _graph:Graph;
		
		protected var _view:GraphView;
		
		protected var _styleManager:GraphStyleManager;
		
		/**
		 *  Source node used for the edge creating process.
		 */
		protected var _sourceNode:Node;
		
		//--------------------------- ACCESSORS --------------------------------
		
		/**
		 * Style manager for shared visual styles.
		 */
		public function get graphStyleManager():GraphStyleManager
		{
			return _styleManager;
		}
		
		/**
		 * Graph view.
		 */
		public function get view():GraphView
		{
			return _view;
		}
		
		public function set view(view:GraphView):void
		{
			_view = view;
		}
		
		// TODO it may be better to make graph inaccessible outside GraphManager
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
		
		public function GraphManager(graph:Graph = null)
		{
			if (this.graph == null)
			{
				this.graph = new Graph();
			}
			else
			{
				this.graph = graph;
			}
			
			this.view = new GraphView(this.graph);
			
			this._styleManager = new GraphStyleManager();
			this._sourceNode = null;
			
			this.initListeners();
		}
		
		//---------------------- PUBLIC FUNCTIONS ------------------------------
		
		/**
		 * Creates a new Node instance and adds it to the location specified by
		 * x and y coordinates. If the event target is another node, the new 
		 * node will be added into the target node as a child.
		 * 
		 * @param x				x coordinate of the event
		 * @param y				y coordinate of the event
		 * @param eventTarget	target object of the event
		 * @param data			(optional) data to be associated with the node
		 * @return				newly created node as a DataSprite
		 */
		public function addNode(x:Number, y:Number,
								eventTarget:Object = null,
								data:Object = null):DataSprite
		{
			// add node to the graph
			var node:Node = this.graph.addNode(data);
			var compound:Node;
			
			// update node position
			node.x = x;
			node.y = y;
			
			// initialize visual properties (size, shape, etc) of node
			// TODO render the node before updating compound bounds?
			this._styleManager.initNodeStyle(node);
			//node.props.labelText = node.data.id;
			
			Styles.reApplyStyles(node);
			
			// update node renderer
			node.renderer = NodeRenderer.instance;
			
			// if event target is a compound node, add node to the compound as
			// a child and update compound bounds.
			if (eventTarget is Node &&
				!(eventTarget as Node).isBendNode)
			{
				compound = eventTarget as Node;
				
				if (!compound.isInitialized())
				{
					// initialize visual properties of compound
					this._styleManager.initCompoundStyle(compound);
					
					// add node to the group of compound nodes
					this.graph.addToGroup(Groups.COMPOUND_NODES, compound);
					
					Styles.reApplyStyles(compound);
					
					//compound.props.labelText = compound.data.id;
					
					// update node renderer
					compound.renderer = CompoundNodeRenderer.instance;
					
				}
				
				// add the node as a child
				compound.addNode(node);
				
				// update bounds of the target compound node up to the root
				
				while (compound != null)
				{
					// update the bounds of the compound node
					this.view.updateCompoundBounds(compound);
					
					// render the compound node with new bounds
					compound.render();
					
					// advance to the next parent node
					compound = compound.parentN;
				}
			}
			
			// update the visualization
			this.view.update();
			
			return node;
		}
		
		/**
		 * Creates a new Edge instance and adds it to the graph data. The data
		 * to be associated with the edge should be provided with valid source
		 * and target values.
		 * 
		 * @param data	data to be associated with the edge
		 * @return		newly created edge as a DataSprite
		 */
		public function addEdge(data:Object):DataSprite
		{
			var edge:Edge = this.graph.addEdge(data);
			
			// initialize visual properties of the edge
			this._styleManager.initEdgeStyle(edge);
			Styles.reApplyStyles(edge);
			
			// update edge renderer
			edge.renderer = EdgeRenderer.instance;
			
			// edge.props.labelText = edge.data.id;
			
			// bring the new edge to the front
			GeneralUtils.bringToFront(edge);
			
			return edge;
		}
		
		/**
		 * If the event target is a simple or compound node (but not a bend
		 * node) and if the source node is set, this function adds and edge
		 * between the target node and the source node. If no source is set yet,
		 * then this function sets the source node as the event target. 
		 * 
		 * @param eventTarget	target object of the event
		 * @return				newly added edge if successful, null otherwise
		 */
		public function addEdgeFor(eventTarget:Object):DataSprite
		{
			var node:Node = null;
			var edge:DataSprite = null;
			var data:Object;
			
			if ((eventTarget is Node)
				&& !(eventTarget as Node).isBendNode)
			{
				node = eventTarget as Node;
			}
			
			if (node == null)
			{
				edge = null;
			}
			else if (this._sourceNode == null)
			{
				// event target will be the source of the edge
				this._sourceNode = node;
			}
			else
			{
				// source is set, so event target will be target of the edge
				data = new Object();
				data.sourceId = this._sourceNode.data.id;
				data.targetId = node.data.id;
				
				edge = addEdge(data);
				
				// add the edge to the group of regular edges
				this.graph.addToGroup(Groups.REGULAR_EDGES, edge);
				
				// reset source node
				this._sourceNode = null;
			}
			
			// update the visualization
			this.view.update();
			
			return edge;
		}
		
		/**
		 * Creates a bendpoint as a Node instance and adds it to the given
		 * target edge. If eventTarget is not an edge, no bendpoint is added.
		 * 
		 * @param eventTarget	target object of event
		 * @return				newly created bendpoint as a DataSprite
		 */
		public function addBendPoint(eventTarget:Object):DataSprite
		{
			var edge:Edge;
			
			if (eventTarget is Edge)
			{
				edge = eventTarget as Edge;
			}
			else
			{
				return null;
			}
			
			var source:NodeSprite = edge.source;
			var target:NodeSprite = edge.target;
			
			var edgeData:Object;
			var parent:Edge;
			
			// check if target edge is an actual edge or a segment
			if (edge.isSegment)
			{
				// edge is a segment
				parent = edge.parentE;
			}
			else
			{
				// edge is an actual edge
				parent = edge;
			}
			
			// create bend node to represent bendpoint
			var bendNode:Node = this.addBendNode(edge);
			parent.addBendNode(bendNode);
			
			// create first segment
			edgeData = new Object();
			edgeData.sourceId = source.data.id;
			edgeData.targetId = bendNode.data.id;
			var segment1:DataSprite = this.addEdge(edgeData);
			parent.addSegment(segment1 as Edge);
			
			// create second segment
			edgeData = new Object();
			edgeData.sourceId = bendNode.data.id;
			edgeData.targetId = target.data.id;
			var segment2:DataSprite = this.addEdge(edgeData);
			parent.addSegment(segment2 as Edge);
			
			// target edge is a segment
			if (edge.isSegment)
			{
				// remove the (old) segment from the graph
				this.graph.removeEdge(edge);
			}
				// target edge is an actual edge
			else
			{
				// in order to hide the actual edge, it should be marked dirty
				edge.dirty();
			}
			
			// bring new segments to the front
			bendNode.visitEdges(GeneralUtils.bringToFront);
			
			// bring new bendpoint to the front
			GeneralUtils.bringToFront(bendNode);
			
			// update the visualization
			this.view.update();
			
			return bendNode;
		}
		
		/**
		 * Removes the specified element (node or edge) from the graph. If the
		 * update flag is set, updates the bounds of all compound nodes, if
		 * the remove operation is succesful.
		 * 
		 * @param eventTarget	target element to be deleted 
		 * @param update		flag that indicates compound bound update,
		 * 						default value is true.
		 * @return				true if successful, false otherwise
		 */
		public function removeElement(eventTarget:Object,
									  update:Boolean = true):Boolean
		{
			var result:Boolean = false;
			
			var edge:Edge;
			var node:Node;
			
			if (eventTarget is Node)
			{
				node = eventTarget as Node;
				
				// for a bendpoint (bend node), remove the bend node and two
				// incident edges, and add one new segment between the two
				// neighbor bend nodes.
				if (node.isBendNode)
				{
					result = this.removeBendNode(node);
				}
					// for a node, remove all children & all incident edges
					// (with their bendpoints and segments)
				else
				{
					result = this.removeNode(node);
				}
			}
				// for an edge, remove all segments & bendpoints
			else if (eventTarget is Edge)
			{
				edge = eventTarget as Edge;
				
				result = this.removeEdge(edge);
			}
			
			if (result && update)
			{
				this.view.updateAllCompoundBounds();
				this.view.update();
			}
			
			return result;
		}
		
		/**
		 * Resets all the selected graph elements (nodes and edges) by setting
		 * corresponding flag to false, and clearing corresponding data groups.
		 */ 
		public function resetSelected():void
		{
			trace("all selections are cleared");
			
			var idx:int
			
			for each (var node:NodeSprite in this.graph.selectedNodes)
			{
				node.props.$selected = false;
				
				// remove glow filter
				this.view.removeFilter(node, node.props.$glowFilter);
				
			}
			
			for each (var edge:EdgeSprite in this.graph.selectedEdges)
			{
				edge.props.$selected = false;
				
				// remove glow filter
				this.view.removeFilter(edge, edge.props.$glowFilter);
			}
			
			this.graph.clearGroup(Groups.SELECTED_NODES);
			this.graph.clearGroup(Groups.SELECTED_EDGES);
		}
		
		/**
		 * Removes all of the selected elements from the graph.
		 */
		public function deleteSelected():void
		{
			var deleted:Boolean = false;
			
			for each (var node:NodeSprite in this.graph.selectedNodes)
			{
				// remove node, but not update bounds
				deleted = this.removeElement(node, false);
			}
			
			for each (var edge:EdgeSprite in this.graph.selectedEdges)
			{
				// remove node, but not update bounds
				deleted = this.removeElement(edge, false) || deleted;
			}
			
			// if delete operation is successful, update all compound bounds
			if (deleted)
			{
				this.view.updateAllCompoundBounds();
				this.view.update();
			}
		}
		
		/**
		 * Resets the missing children list.
		 */
		public function resetMissingChildren():void
		{
			this.graph.resetMissingChildren();
		}
		
		/**
		 * Retrieves an array of missing children.
		 */
		public function getMissingChildren():Array
		{
			return this.graph.missingChildren;
		}
		
		/**
		 * Retrieves an array of currently selected nodes.
		 */
		public function getSelectedNodes():Array
		{
			return this.graph.selectedNodes;
		}
		
		//---------------------- PROTECTED FUNCTIONS ---------------------------
		
		/**
		 * Creates a Node instance and initializes its position according to the
		 * start&end points of the target edge. Also, initializes visual
		 * properties of the bend node.
		 * 
		 * @param edge		the target edge
		 * @return			newly created bendpoint as a Node
		 */
		protected function addBendNode(edge:Edge):Node
		{
			var bendNode:Node = this.graph.addNode();
			
			// set the position of the bendpoint as the mid-point of
			// the start&end points of the target edge
			
			if (edge.props.$startPoint == null ||
				edge.props.$endPoint == null)
			{
				// if no start or end point defined for the edge, use source
				// and target node poistions
				bendNode.x = (edge.source.x + edge.target.x) / 2;
				bendNode.y = (edge.source.y + edge.target.y) / 2;
			}
			else
			{
				// use start&end points of the edge to set new
				var startPoint:Point = (edge.props.$startPoint as Point);
				var endPoint:Point = (edge.props.$endPoint as Point);
				
				bendNode.x = (startPoint.x + endPoint.x) / 2;
				bendNode.y = (startPoint.y + endPoint.y) / 2;
			}
			
			// TODO default style for bend nodes?
			
			// add node to the data group
			this.graph.addToGroup(Groups.BEND_NODES, bendNode);
			
			// update bend node renderer
			bendNode.renderer = NodeRenderer.instance;
			
			return bendNode;
		}
		
		/**
		 * Removes the bend node (bendpoint) from its parent edge and removes  
		 * the two incident edges of the bend node from the graph. Also,
		 * adds one new segment between the two neighbors of the bend node, if
		 * required.
		 * 
		 * @param node	bend node to be removed
		 * @return		true if successfully removed, false otherwise
		 */
		protected function removeBendNode(node:Node):Boolean
		{
			var result:Boolean = false;
			
			// array of edges to be removed
			var fallenEdges:Array = new Array();
			
			// array of nodes to be removed
			var fallenNodes:Array = new Array();
			
			// add the bendpoint to the list of nodes to be removed
			fallenNodes.push(node);
			
			var edge:Edge;
			var edgeData:Object = new Object();
			
			for each (edge in Nodes.incidentEdges(node))
			{
				// add incident edges to the list of edged to be removed
				fallenEdges.push(edge);
				
				// obtain source and target ids for a new segment
				
				if (edgeData.sourceId == null)
				{
					if (edge.source == node)
					{
						edgeData.sourceId = edge.target.data.id;
					}
					else
					{
						edgeData.sourceId = edge.source.data.id;
					}
				}
				else if (edgeData.targetId == null)
				{
					if (edge.source == node)
					{
						edgeData.targetId = edge.target.data.id;
					}
					else
					{
						edgeData.targetId = edge.source.data.id;
					}
				}
			}
			
			// add a new segment to the parent edge, if necessary
			
			if (node.parentE.getBendNodes().length > 1)
			{
				var ds:DataSprite = this.addEdge(edgeData);
				node.parentE.addSegment(ds as Edge);
			}
			
			// remove required nodes from the graph 
			
			for each (node in fallenNodes)
			{
				// remove node
				result = this.graph.removeNode(node) || result;
				
				// remove its label
				if (node.props.label != null)
				{
					this.view.removeLabel(node.props.label);
					node.props.label = null;
				}
				
			}
			
			// remove required edges from the graph
			
			for each (edge in fallenEdges)
			{
				// remove edge
				result = this.graph.removeEdge(edge) || result;
				
				// remove its label
				if (edge.props.label != null)
				{
					this.view.removeLabel(edge.props.label);
					edge.props.label = null;
				}
			}
			
			// check if parent has any more bendpoints
			
			if (!node.parentE.hasBendPoints())
			{
				// it is required to mark the actual edge dirty
				// if all bendpoints are removed from the edge
				node.parentE.dirty();
			}
			
			return result;
		}
		
		/**
		 * Removes the specified node from the graph. Also, removes the node 
		 * from its parent's child list, removes all (direct and indirect)
		 * children of the node and the edges (together with their bendpoints
		 * and segments) incident with the node and all its children from 
		 * the graph.
		 * 
		 * @param node	node to be removed
		 * @return		true if successfully removed, false otherwise
		 */
		protected function removeNode(node:Node):Boolean
		{
			var result:Boolean = false;
			
			// array of edges to be removed
			var fallenEdges:Array = new Array();
			
			// array of nodes to be removed
			var fallenNodes:Array = new Array();
			
			// collect all children of the node to be deleted
			var children:Array = Nodes.getChildren(node);
			
			// collect incident edges of node to be deleted
			var edges:Array = Nodes.incidentEdges(node);
			
			// collect all incident edges of child nodes
			for each(var child:Node in children)
			{
				edges = edges.concat(Nodes.incidentEdges(child));
			}
			
			var edge:Edge;
			
			// collect all bendpoints and segments on all incident edges
			for each(edge in edges)
			{
				// add bendpoints of the current edge to the list
				fallenNodes = fallenNodes.concat(edge.getBendNodes());
				// add segments of the current edge to the list
				fallenEdges = fallenEdges.concat(edge.getSegments());
			}
			
			// add incident edges to the list
			fallenEdges = fallenEdges.concat(edges);
			// add child nodes to the list
			fallenNodes = fallenNodes.concat(children);
			// add the node itself
			fallenNodes.push(node);
			
			// remove required nodes from the graph 
			for each (node in fallenNodes)
			{
				// remove node
				result = this.graph.removeNode(node) || result;
				
				// remove its label
				if (node.props.label != null)
				{
					this.view.removeLabel(node.props.label);
					node.props.label = null;
				}
			}
			
			// remove required edges from the graph
			for each (edge in fallenEdges)
			{
				// remove edge
				result = this.graph.removeEdge(edge) || result;
				
				// remove its label
				if (edge.props.label != null)
				{
					this.view.removeLabel(edge.props.label);
					edge.props.label = null;
				}
			}
			
			return result;
		}
		
		/**
		 * If the specified edge is an actual edge, removes the edge from 
		 * the graph. Also, removes the edge from its parent's child list, 
		 * removes all segments and bendpoints of the edge from the graph.
		 * If the specified edge is a segment, no remove operation is performed,
		 * since segments cannot be removed separately.
		 * 
		 * @param edge	edge to be removed
		 * @return		true if successfully removed, false otherwise
		 */
		protected function removeEdge(edge:Edge):Boolean
		{
			var result:Boolean = false;
			
			// array of edges to be removed
			var fallenEdges:Array = new Array();
			
			// array of nodes to be removed
			var fallenNodes:Array = new Array();
			
			// a segment cannot be removed by itself, so only process
			// actual edges
			if (!edge.isSegment)
			{
				fallenNodes = fallenNodes.concat(edge.getBendNodes());
				fallenEdges = fallenEdges.concat(edge.getSegments());
				fallenEdges.push(edge);
				
				// remove required nodes from the graph 
				for each (var node:Node in fallenNodes)
				{
					// remove node
					result = this.graph.removeNode(node) || result;
					
					// remove its label
					if (node.props.label != null)
					{
						this.view.removeLabel(node.props.label);
						node.props.label = null;
					}
				}
				
				// remove required edges from the graph
				for each (edge in fallenEdges)
				{
					// remove edge
					result = this.graph.removeEdge(edge) || result;
					
					// remove its label
					if (edge.props.label != null)
					{
						this.view.removeLabel(edge.props.label);
						edge.props.label = null;
					}
				}
			}
			
			return result;
		}
		
		/**
		 * Initializes event listeners.
		 */
		protected function initListeners() : void
		{
			// register listener for graph data changes
			this.graph.dispatcher.addEventListener(
				DataChangeEvent.REMOVED_GROUP,
				onRemoveGroup);
			
			this.graph.dispatcher.addEventListener(
				DataChangeEvent.DS_ADDED_TO_GROUP,
				onAddToGroup);
			
			this.graph.dispatcher.addEventListener(
				DataChangeEvent.DS_REMOVED_FROM_GROUP,
				onRemoveFromGroup);
			
			// register listener visual settings data changes
			
			this._styleManager.addEventListener(
				DataChangeEvent.ADDED_GROUP_STYLE,
				onAddGroupStyle);
			
			this._styleManager.addEventListener(
				DataChangeEvent.REMOVED_GROUP_STYLE,
				onRemoveGroupStyle);
		}
		
		/**
		 * This function is designed as a listener for the action
		 * DataChangeEvent.REMOVED_GROUP and to be called whenever a
		 * data group is removed from the graph.
		 * 
		 * This function updates the style of all nodes or edges in the data
		 * group by re-applying styles of nodes and edges.
		 * 
		 * @param event	DataChangeEvent triggered the action
		 */
		protected function onRemoveGroup(event:DataChangeEvent) : void
		{
			var group:String = event.info.group;
			var elements:DataList = event.info.elements;
			var style:Style = this._styleManager.getGroupStyle(group);
			
			if (style != null)
			{
				// visit all data sprites in the group
				for each (var ds:DataSprite in elements)
				{
					if (ds is IStyleAttachable)
					{
						var element:IStyleAttachable = ds as IStyleAttachable;
						
						// detach group style from the element
						element.detachStyle(event.info.group);
						
						// re-apply visual style of the element
						Styles.reApplyStyles(element);
					}
				}
				
				this.view.update();
				this.view.updateAllCompoundBounds();
			}
		}
		
		/**
		 * This function is designed as a listener for the action
		 * DataChangeEvent.DS_ADDED_TO_GROUP and to be called whenever a
		 * node or an edge is added to a data group.
		 * 
		 * This function updates the style of the node or edge by applying
		 * the corresponding style defined for the data group. 
		 * 
		 * @param event	DataChangeEvent triggered the action
		 */
		protected function onAddToGroup(event:DataChangeEvent) : void
		{
			var ds:DataSprite = event.info.ds;
			var group:String = event.info.group;
			var style:Style = _styleManager.getGroupStyle(group);
			
			if (ds is IStyleAttachable &&
				style != null)
			{
				var element:IStyleAttachable = (ds as IStyleAttachable);
				
				// attach new group style
				element.attachStyle(group, style);
				
				// apply new style to the element
				// TODO consider style priorities.. may need to call reApply
				Styles.applyNewStyle(element, style);
				
				this.view.update();
				this.view.updateAllCompoundBounds();
			}
			
		}
		
		/**
		 * This function is designed as a listener for the action
		 * DataChangeEvent.DS_REMOVED_FROM_GROUP and to be called whenever a
		 * node or an edge is removed from a data group.
		 * 
		 * This function updates the style of the node or edge by applying
		 * the corresponding style defined for the data group. 
		 * 
		 * @param event	DataChangeEvent triggered the action
		 */
		protected function onRemoveFromGroup(event:DataChangeEvent) : void
		{
			var ds:DataSprite = event.info.ds;
			var group:String = event.info.group;
			
			var style:Style = 
				this._styleManager.getGroupStyle(group);
			
			// reset & apply styles
			if (style != null &&
				ds is IStyleAttachable)
			{
				var element:IStyleAttachable = ds as IStyleAttachable;
				
				// detach group style from the element
				element.detachStyle(group);
				
				// re-apply visual style of the element
				Styles.reApplyStyles(element);
				
				this.view.update();
				this.view.updateAllCompoundBounds();
			}
		}
		
		/**
		 * This function is designed as a listener for the action
		 * DataChangeEvent.ADDED_GROUP_STYLE and to be called whenever a
		 * new style added for a data group.
		 * 
		 * This function updates the style of all nodes or edges in the data
		 * group by applying the corresponding style defined for the group. 
		 * 
		 * @param event	DataChangeEvent triggered the action
		 */
		protected function onAddGroupStyle(event:DataChangeEvent) : void
		{
			var group:DataList = this.graph.graphData.group(event.info.group);
			var style:Style = this._styleManager.getGroupStyle(
				event.info.group);
			
			if (group != null &&
				style != null)
			{
				// visit all data sprites in the group to apply new style
				for each (var ds:DataSprite in group)
				{	
					if (ds is IStyleAttachable)
					{
						// attach style to the sprite
						(ds as IStyleAttachable).attachStyle(event.info.group,
							style);
						
						// apply new style to the element
						Styles.applyNewStyle(ds as IStyleAttachable,
							style);
					}
				}
				
				// add event listeners with a low priority
				
				style.addEventListener(StyleChangeEvent.ADDED_STYLE_PROP,
					onStyleChange,
					false,
					StyleChangeEvent.LOW_PRIORITY);
				
				style.addEventListener(StyleChangeEvent.REMOVED_STYLE_PROP,
					onStyleChange,
					false,
					StyleChangeEvent.LOW_PRIORITY);
				
				this.view.update();
				this.view.updateAllCompoundBounds();
			}
		}
		
		/**
		 * This function is designed as a listener for the action
		 * DataChangeEvent.REMOVED_GROUP_STYLE and to be called whenever a
		 * style for a data group is removed.
		 * 
		 * This function updates the style of all nodes or edges in the data
		 * group by re-applying styles of nodes and edges. 
		 * 
		 * @param event	DataChangeEvent triggered the action
		 */
		protected function onRemoveGroupStyle(event:DataChangeEvent) : void
		{
			var group:DataList = this.graph.graphData.group(event.info.group);
			var style:Style = event.info.style as Style;
			
			if (group != null)
			{
				// visit all data sprites in the group
				for each (var ds:DataSprite in group)
				{
					if (ds is IStyleAttachable)
					{
						var element:IStyleAttachable = ds as IStyleAttachable;
						
						// detach group style from the element
						element.detachStyle(event.info.group);
						
						// re-apply visual style of the element
						Styles.reApplyStyles(element);
					}
				}
				
				style.removeEventListener(StyleChangeEvent.ADDED_STYLE_PROP,
					onStyleChange);
				
				style.removeEventListener(StyleChangeEvent.REMOVED_STYLE_PROP,
					onStyleChange);
				
				this.view.update();
				this.view.updateAllCompoundBounds();
			}
		}
		
		/**
		 * This function is designed as a (low priority) listener for
		 * the actions StyleChangeEvent.ADDED_STYLE_PROP and 
		 * StyleChangeEvent.REMOVED_STYLE_PROP.
		 * 
		 * This function is called whenever a property of a style is changed,
		 * and it calls the vis.update() function to apply style changes
		 * to the visual elements.
		 * 
		 * @param event	StyleChangeEvent triggered the action
		 */
		protected function onStyleChange(event:StyleChangeEvent) : void
		{
			this.view.update();
			this.view.updateAllCompoundBounds();
		}
	}
}