package ivis.model
{
	import flare.vis.data.Data;
	import flare.vis.data.DataList;
	import flare.vis.data.EdgeSprite;
	import flare.vis.data.NodeSprite;
	
	import ivis.util.Groups;
	import ivis.util.Nodes;

	/**
	 * This class represents the graph model. 
	 * 
	 * @author Selcuk Onur Sumer
	 */
	public class Graph
	{
		/**
		 * Array of non-selected child nodes of selected compound nodes.
		 */
		private var _missingChildren:Array;
		
		private var _graphData:Data;
		
		/**
		 * Node map for quick access to nodes by their ids.
		 */
		private var _nodeMap:Object;
		
		/**
		 * Edge map for quick access to edges by their ids.
		 */
		private var _edgeMap:Object;
		
		/**
		 * Object used to generate ids for nodes and edges. 
		 */
		private var _idGen:Object;
		
		//---------------------------- ACCESSORS -------------------------------
		
		/**
		 * Graph data that consists of nodes and edges.
		 */
		public function get graphData():Data
		{
			return _graphData;
		}
		
		/**
		 * Retrieves the selected nodes from the graph data and returns an array
		 * containing all of the selected nodes. 
		 */
		public function get selectedNodes():Array
		{
			var nodes:Array = new Array();
			var list:DataList = this.graphData.group(Groups.SELECTED_NODES);
			
			for each (var n:NodeSprite in list)
			{
				nodes.push(n);
			}
			
			return nodes;
		}
		
		/**
		 * Retrieves the selected edges from the graph data and returns an array
		 * containing all of the selected edges. 
		 */
		public function get selectedEdges():Array
		{
			var edges:Array = new Array();
			var list:DataList = this.graphData.group(Groups.SELECTED_EDGES);
			
			for each (var n:EdgeSprite in list)
			{
				edges.push(n);
			}
			
			return edges;
		}
		
		/**
		 * Finds non-selected children of the compound nodes in the given
		 * node array, and returns the collected children in an array of nodes.
		 * 
		 * @return		array of selected nodes
		 */
		public function get missingChildren() : Array
		{
			// this map is used to avoid duplicates
			var childMap:Object;
			var children:Array;
			var nodes:Array = this.selectedNodes;
			var node:NodeSprite;
			
			// if missing children is set before, just return the
			// previously collected children
			if (_missingChildren != null)
			{
				children = _missingChildren;
			}
			// collect non-selected children of all selected compound nodes
			else
			{
				childMap = new Object();
				
				// for each node sprite in the selected nodes, search for
				// missing children
				
				for each (var ns:Node in nodes)
				{
					// get non-selected children of the current compound
					children = Nodes.getChildren(ns, Nodes.NON_SELECTED);
					
					// get non-selected inner bends
					children = children.concat(
						Nodes.innerBends(ns, Nodes.NON_SELECTED));
					
					// concat the new children with the map
					for each (node in children)
					{
						// assuming the node.data.id is not null
						childMap[node.data.id] = node;
					}
				}
				
				// convert child map to an array
				children = new Array();
				
				for each (node in childMap)
				{
					children.push(node);
				}
				
				// update missing children array
				_missingChildren = children;
			}
			
			return children;
		}
		
		//-------------------------- CONSTRUCTOR -------------------------------
		
		/**
		 * Creates a new Graph instance with the given graph data.
		 * 
		 * @param data	data to be associated with this graph 
		 */
		public function Graph(data:Data = null)
		{
			this._nodeMap = new Object();
			this._edgeMap = new Object();
			this._idGen = new Object();
			
			// initialize the graph data
			if (data == null)
			{
				this.initData(new Data());
			}
			else
			{
				this.initData(data);
			}
		}

		//----------------------- PUBLIC FUNCTIONS -----------------------------
		
		/**
		 * Creates a new Node instance for the given node data and adds the
		 * new Node to the graph data.
		 * 
		 * @param data	data to be associated with the new Node instance
		 * @return		newly created Node
		 */
		public function addNode(data:Object = null) : Node
		{
			// check id for null & duplicate values
			
			if (data == null)
			{
				data = new Object();
			}
			
			if (data.id == null)
			{
				// generate next id
				data.id = nextId(Groups.NODES);
			}
			else if (_nodeMap[data.id] != null)
			{
				// duplicate id!
				throw new Error("Duplicate node id: "+ data.id);
			}
			
			var node:Node = new Node();
			node.data = data;
			
			this.graphData.addNode(node);
			_nodeMap[data.id] = node;
			
			return node;
		}
		
		/**
		 * Creates a new Edge instance for the given edge data and adds the
		 * new Edge to the graph data. The edge data should contain sourceId
		 * and targetId fields for the source and target nodes of the edge
		 * to be added. If sourceId or targetId is invalid, no edge will be
		 * added.
		 * 
		 * @param data	data to be associated with the new Edge instance
		 * @return		newly created Edge if successful, null otherwise
		 */
		public function addEdge(data:Object) : Edge
		{
			// check id for null & duplicate values
			
			if (data == null)
			{
				data = new Object();
			}
			
			if (data.id == null)
			{
				// generate next id
				data.id = nextId(Groups.EDGES);
			}
			else if (_edgeMap[data.id] != null)
			{
				// duplicate id!
				throw new Error("Duplicate edge id: "+ data.id);
			}
			
			var edge:Edge;
			var source:Node;
			var target:Node;
			
			if ((data.sourceId == null) || (data.targetId == null))
			{
				// invalid source id or target id
				edge = null;
			}
			else
			{
				edge = new Edge();
				edge.data = data;
				
				source = _nodeMap[data.sourceId];
				target = _nodeMap[data.targetId];
				
				if ((source == null) || (target == null))
				{
					// invalid source id or target id
					edge = null
				}
				else
				{
					edge.source = source; 
					edge.target = target;
					
					edge.source.addOutEdge(edge);
					edge.target.addInEdge(edge);
					
					this.graphData.addEdge(edge);
					this._edgeMap[data.id] = edge;
				}
			}
			
			return edge;
		}
		
		/**
		 * Removes the given edge from the graph. If the edge is a segment,
		 * it is also removed from its parent's list. This function does not
		 * remove child segments or bendpoints of the edge. It removes exactly
		 * one edge, which is the given edge, from the graph. 
		 * 
		 * @param edge	edge to be removed
		 * @return		true if successfully removed, false otherwise
		 */
		public function removeEdge(edge:Edge):Boolean
		{
			// remove edge from its parent's list			
			if (edge.isSegment)
			{
				edge.parentE.removeSegment(edge);
			}
			
			// remove edge from all data groups
			this.graphData.group(Groups.SELECTED_EDGES).remove(edge);
			this.graphData.group(Groups.REGULAR_EDGES).remove(edge);
			
			// remove edge from graph data
			return this.graphData.remove(edge);
		}
		
		/**
		 * Removes the given node from the graph. If the node is a bendpoint or
		 * it is contained in a compound node, it is also removed from its 
		 * parent's list. This function does not remove children of the node.  
		 * It removes exactly one node, which is the given node, from the graph. 
		 * 
		 * @param node	node to be removed
		 * @return		true if successfully removed, false otherwise
		 */
		public function removeNode(node:Node):Boolean
		{
			if (node.isBendNode)
			{
				// remove node from its parent edge's list
				node.parentE.removeBendNode(node);
			}
			else
			{
				// remove node from its parent node's list
				if (node.parentN != null)
				{
					node.parentN.removeNode(node);
				}
				
				// reset parent's of all children
				for each (var child:Node in node.getNodes())
				{
					child.parentN = null;
				}
			}
			
			// remove node from all data groups
			this.graphData.group(Groups.SELECTED_NODES).remove(node);
			this.graphData.group(Groups.BEND_NODES).remove(node);
			this.graphData.group(Groups.COMPOUND_NODES).remove(node);
			
			// remove edge from graph data
			return this.graphData.remove(node);
		}
		
		/**
		 * Resets the missing children array in order to enable re-calculation
		 * of missing child nodes in the getter method of missingChildren.
		 */ 
		public function resetMissingChildren() : void
		{
			_missingChildren = null;
		}
		
		//---------------------- PRIVATE FUNCTIONS -----------------------------
		
		/**
		 * Initializes and set the graph data.
		 * 
		 * @param data	graph data to be initialized and set 
		 */
		protected function initData(data:Data):void
		{
			// set graph data
			_graphData = data;
			
			// initialize data groups
			
			this.graphData.addGroup(Groups.COMPOUND_NODES);
			this.graphData.addGroup(Groups.BEND_NODES);
			this.graphData.addGroup(Groups.SELECTED_NODES);
			this.graphData.addGroup(Groups.SELECTED_EDGES);
			this.graphData.addGroup(Groups.REGULAR_EDGES);
			
			// reset and populate node map
			
			_nodeMap = new Object();
			
			for each(var node:NodeSprite in this.graphData.nodes)
			{
				_nodeMap[node.data.id] = node;
			}
		}
		
		/**
		 * Generates and retrieves the next id for the given data group.
		 * 
		 * @param group	type of the data group, available types are:
		 * 				Groups.NODES and Groups.EDGES
		 * @return		generated id as a string
		 */
		protected function nextId(group:String):String
		{
			var prefix:String;
			
			if (group === Groups.NODES)
			{
				prefix = "n";
			}
			else if (group === Groups.EDGES)
			{
				prefix = "e";
			}
			else
			{
				prefix = "x";
			}
			
			// initialize the group id if not initialized
			
			if (this._idGen[group] === undefined)
			{
				this._idGen[group] = 1;
			}
			
			var id:int = this._idGen[group];
			
			// check for duplicates
			
			while(this.hasId(prefix + id))
			{
				this._idGen[group] += 1;
				id = this._idGen[group];
			}
			
			return prefix + id;
		}
		
		/**
		 * Checks whether the graph has an element with the given id. Returns
		 * true if such an element is found, returns false otherwise. 
		 * 
		 * @param id	id to be checked
		 * @return		true if an element found, false otherwise
		 */
		protected function hasId(id:String):Boolean
		{
			var result:Boolean = false;
			
			if (this._nodeMap[id] != null)
			{
				result = true;
			}
			else if (this._edgeMap[id] != null)
			{
				result = true;
			}
			
			return result;
		}
		
		//------------------------- DEBUG FUNCTIONS ----------------------------
		
		
		public function printGraph():void
		{
			var node:Node;
			var edge:Edge;
			
			trace ("===== Compound Nodes =====");
			
			for each (node in this.graphData.group(Groups.COMPOUND_NODES))
			{
				trace(node.toString());
			}
			
			trace ("===== Bend Nodes =====");
			
			for each (node in this.graphData.group(Groups.BEND_NODES))
			{
				trace(node.toString());
			}
			
			trace ("===== Selected Nodes =====");
			
			for each (node in this.graphData.group(Groups.SELECTED_NODES))
			{
				trace(node.toString());
			}
			
			trace ("===== Regular Edges =====");
			
			for each (edge in this.graphData.group(Groups.REGULAR_EDGES))
			{
				trace(edge.toString());
			}
			
			trace ("===== Selected Edges =====");
			
			for each (edge in this.graphData.group(Groups.SELECTED_EDGES))
			{
				trace(edge.toString());
			}
		}
		
	}
}