package ivis.model
{
	import flare.vis.data.NodeSprite;
	
	import flash.geom.Rectangle;
	
	/**
	 * This class represents simple (regular) nodes, compound nodes and bend
	 * nodes (bend points).
	 * 
	 * A simple (regular) node is the basic node with no nested structure. 
	 *  
	 * A compound node has its child nodes, bounds and padding values.
	 * A compound node can contain any other node (both simple node and 
	 * compound node)as its child.
	 * 
	 * A bend node is a special kind of node that is used to create bend points
	 * for edges.
	 * 
	 * @author Selcuk Onur Sumer
	 */ 
	public class Node extends NodeSprite
	{
		// ==================== [ PRIVATE PROPERTIES ] =========================
		
		/**
		 * Contains child nodes of this compound node as a map of NodeSprite
		 * objects.
		 */
		private var _nodesMap:Object;
		
		private var _parentN:Node;
		private var _parentE:Edge;
		private var _bounds:Rectangle;
		private var _paddingLeft:Number;
		private var _paddingRight:Number;
		private var _paddingTop:Number;
		private var _paddingBottom:Number;
		
		// -------------------------- ACCESSORS --------------------------------
		
		/**
		 * Bounds enclosing children of the compound node.
		 */
		public function get bounds():Rectangle
		{
			return _bounds;
		}
		
		public function set bounds(rect:Rectangle):void
		{
			_bounds = rect;
		}
		
		/**
		 * Width of the right padding of the compound node
		 */
		public function get paddingRight():Number
		{
			return _paddingRight;
		}
		
		public function set paddingRight(value:Number):void
		{
			_paddingRight = value;
		}
		
		/**
		 * Height of the top padding of the compound node
		 */
		public function get paddingTop():Number
		{
			return _paddingTop;
		}
		
		public function set paddingTop(value:Number):void
		{
			_paddingTop = value;
		}
		
		/**
		 * Height of the bottom padding of the compound node
		 */
		public function get paddingBottom():Number
		{
			return _paddingBottom;
		}
		
		public function set paddingBottom(value:Number):void
		{
			_paddingBottom = value;
		}
		
		/**
		 * Width of the left padding of the compound node
		 */
		public function get paddingLeft():Number
		{
			return _paddingLeft;
		}
		
		public function set paddingLeft(value:Number):void
		{
			_paddingLeft = value;
		}
		
		/**
		 * Leftmost x coordinate of the node
		 */ 
		public function get left():Number
		{
			var left:Number = this.x - (this.width / 2);
			
			return left;
		}
		
		/**
		 * Rightmost x coordinate of the node
		 */ 
		public function get right():Number
		{
			var right:Number = this.x + (this.width / 2);
			
			return right;
		}
		
		/**
		 * Topmost y coordinate of the node
		 */ 
		public function get top():Number
		{
			var top:Number = this.y - (this.height / 2);
			
			return top;
		}
		
		/**
		 * Bottommost y coordinate of the node
		 */
		public function get bottom():Number
		{
			var bottom:Number = this.y + (this.height / 2);
			
			return bottom;
		}
		
		/**
		 * Parent node containing this node sprite. Both simple and compound
		 * nodes can have a parent. However, a bend node should not have a
		 * parent.
		 */
		public function get parentN():Node
		{
			return _parentN;
		}
		
		public function set parentN(value:Node):void
		{
			_parentN = value;
		}
		
		/**
		 * Parent edge containing this node sprite. Only a bend node (bend
		 * point) should have a parent edge.
		 */
		public function get parentE():Edge
		{
			return _parentE;
		}
		
		public function set parentE(value:Edge):void
		{
			_parentE = value;
		}
		
		/**
		 * Indicates whether this node is a bend node (bend point) or not
		 */
		public function get isBendNode():Boolean
		{
			return (_parentE != null);
		}
		
		
		// ------------------------- CONSTRUCTOR -------------------------------
		
		/**
		 * Creates a Node instance. 
		 */
		public function Node()
		{
			this._nodesMap = null;
			this._bounds = null;
			this._parentN = null;
			this._parentE = null;
		}
		
		// ------------------------ PUBLIC FUNCTIONS ---------------------------
		
		/**
		 * Initializes the map of children for this compound node.
		 */
		public function initialize() : void
		{
			this._nodesMap = new Object();
		}
		
		/**
		 * Indicates whether the children map is initialized for this node.
		 */
		public function isInitialized() : Boolean
		{
			var initialized:Boolean;
			
			if (this._nodesMap == null)
			{
				initialized = false;
			}
			else
			{
				initialized = true;
			}
			
			return initialized;
		}
		
		
		/**
		 * Adds the given node sprite to the child map of the compound node.
		 * This function assumes that the given node sprite has an id in its
		 * data field.
		 * 
		 * @param node	child node to be added
		 */
		public function addNode(node:Node) : void
		{
			// check if the node is initialized
			if (!this.isInitialized())
			{
				// initialize the node
				this.initialize();
			}
			
			// add the node to the child node list of this node
			this._nodesMap[node.data.id] = node;
			
			// set the parent of the added node
			node.parentN = this;
		}
		
		/**
		 * Removes the given node sprite from the child list of the compound
		 * node.
		 * 
		 * @param node	child node sprite to be removed
		 */ 
		public function removeNode(node:Node) : void
		{
			// check if given node is a child of this compound
			if (this._nodesMap != null &&
				node.parentN == this)
			{
				// reset the parent id of the removed node
				node.parentN = null;
				
				// remove the node from the list of child nodes 
				delete this._nodesMap[node.data.id];
			}
		}
		
		/**
		 * Returns (one-level) child nodes of this compound node. If the map
		 * of children is not initialized, then returns an empty array.
		 */
		public function getNodes() : Array
		{
			var nodeList:Array = new Array();
			
			if (this._nodesMap != null)
			{
				for each (var ns:NodeSprite in this._nodesMap)
				{
					nodeList.push(ns);
				}
			}
			
			return nodeList;
		}
		
		/**
		 * Updates the bounds of this node with respect to the given bounds.
		 * This function is designed to update the bounds of a compound node
		 * and it has no effect on simple and bend nodes.
		 */
		public function updateBounds(bounds:Rectangle) : void
		{
			// extend bounds by adding padding width & height
			bounds.x -= this.paddingLeft;
			bounds.y -= this.paddingTop;
			bounds.height += this.paddingTop + this.paddingBottom;
			bounds.width += this.paddingLeft + this.paddingRight;
			
			// set bounds
			_bounds = bounds;
			
			// also update x & y coordinates of the compound node by using
			// the new bounds
			this.x = bounds.x + (bounds.width / 2);
			this.y = bounds.y + (bounds.height / 2);
		}
		
		/**
		 * Resets the compound bounds.
		 */
		public function resetBounds() : void
		{
			_bounds = null;
		}
		
		public override function toString():String
		{
			var parentNode:String = "N/A";
			var parentEdge:String = "N/A";
			var children:String = "[";
			
			if (this.parentE != null)
			{
				parentEdge = this.parentE.data.id;
			}
			
			if (this.parentN != null)
			{
				parentNode = this.parentN.data.id;
			}
			
			for each (var child:Node in this.getNodes())
			{
				children += " " + child.data.id; 
			}
			
			children += "]"
			
			var str:String = "id:" + this.data.id +
				" parentN:" + parentNode +
				" parentE:" + parentEdge +
				" x:" + this.x +
				" y:" + this.y +
				" w:" + this.width +
				" h:" + this.height +
				" children:" + children;
			
			return str;
		}
		
		
		// ---------------------- PRIVATE FUNCTIONS ----------------------------
	}
}