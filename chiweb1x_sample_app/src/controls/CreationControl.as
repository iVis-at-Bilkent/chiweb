package controls
{
	
	import flash.display.DisplayObjectContainer;
	import flash.display.Graphics;
	import flash.display.InteractiveObject;
	import flash.display.Shape;
	import flash.events.MouseEvent;
	
	import ivis.controls.EventControl;
	import ivis.event.ControlEvent;
	import ivis.model.Edge;
	import ivis.model.Node;
	import ivis.model.Style;
	import ivis.model.util.Styles;
	
	import util.Constants;

	/**
	 * This class is designed as an EventControl class to manage node and edge
	 * creation. Attaches required styles to the created node or edge according
	 * to the selection.
	 * 
	 * @author Selcuk Onur Sumer
	 */
	public class CreationControl extends EventControl
	{		
		/**
		 * Shape to animate edge adding process.
		 */
		protected var _previewEdge:Shape;
		
		//-------------------------- CONSTRUCTOR -------------------------------
		
		public function CreationControl()
		{
			super();
			
			this._previewEdge = new Shape();
		}
		
		//----------------------- PUBLIC FUNCTIONS -----------------------------
		
		/** @inheritDoc */
		public override function attach(obj:InteractiveObject):void
		{
			if (obj == null)
			{
				detach();
				return;
			}
			
			super.attach(obj);
			
			if (obj != null)
			{
				obj.addEventListener(ControlEvent.ADDED_NODE, onAddNode);
				obj.addEventListener(ControlEvent.ADDED_EDGE, onAddEdge);
				obj.addEventListener(ControlEvent.ADDING_EDGE, onAddingEdge);
			}
		}
		
		/** @inheritDoc */
		public override function detach():InteractiveObject
		{
			if (this.object != null)
			{
				this.object.removeEventListener(ControlEvent.ADDED_NODE,
					onAddNode);
				
				this.object.removeEventListener(ControlEvent.ADDED_EDGE,
					onAddEdge);
			}
			
			return super.detach();
		}
		
		//----------------------- PROTECTED FUNCTIONS --------------------------
		
		/**
		 * Listener function for ADDED_NODE event. Sets the style of the new
		 * node according to the selection (state of a clicked button).
		 * 
		 * @param evt	ControlEvent that triggered the action 
		 */
		protected function onAddNode(evt:ControlEvent):void
		{
			var node:Node = evt.info.sprite as Node;
			
			if (this.stateManager.checkState(Constants.ADD_GRADIENT))
			{
				trace ("[AddNodeControl.onAddNode] gradient: " +
					node.data.id);
				
				// adds the node to the corresponding group
				this.graphManager.graph.addToGroup(Constants.GRADIENT_RECT,
					node);
			}
			else if (this.stateManager.checkState(Constants.ADD_CIRCULAR_NODE))
			{
				trace ("[AddNodeControl.onAddNode] dashed triangle: " +
					node.data.id);
				
				// adds the node to the corresponding group
				this.graphManager.graph.addToGroup(Constants.CIRCULAR_NODE,
					node);
			}
			else if (this.stateManager.checkState(Constants.ADD_IMAGE_NODE))
			{
				trace ("[AddNodeControl.onAddNode] image node: " +
					node.data.id);
				
				// adds the node to the corresponding group
				this.graphManager.graph.addToGroup(Constants.IMAGE_NODE,
					node);
			}
			
			
			// this style is actually to define a node-specific label using
			// its id property as label text
			var style:Object = {labelText: node.data.id};
			
			// attach node-specific style to this node
			node.attachStyle(Styles.SPECIFIC_STYLE, new Style(style));
			
			// re-apply styles for the node to reflect the changes
			Styles.reApplyStyles(node);
			this.graphManager.view.update();
		}
		
		/**
		 * Listener function for ADDED_EDGE event. Sets the style of the new
		 * edge according to the selection (state of a clicked button).
		 * 
		 * @param evt	ControlEvent that triggered the action 
		 */
		protected function onAddEdge(evt:ControlEvent):void
		{
			var edge:Edge = evt.info.sprite as Edge;
			
			if (this.object != null &&
				this.object is DisplayObjectContainer)
			{
				// remove listener (for the animation of preview edge)
				
				this.object.removeEventListener(MouseEvent.MOUSE_MOVE,
					onMouseMove);
				
				// disable preview edge
				
				this._previewEdge.graphics.clear();
				
				(this.object as DisplayObjectContainer).removeChild(
					this._previewEdge);
			}
			
			if (this.stateManager.checkState(Constants.ADD_DASHED_EDGE))
			{
				trace ("[AddNodeControl.onAddEdge] dashed: " + edge.data.id);
				
				// adds the edge to the corresponding group
				this.graphManager.graph.addToGroup(Constants.DASHED_EDGE,
					edge);
			}
			
			// this style is actually to define an edge-specific label using
			// its id property as label text
			var style:Object = {labelText: edge.data.id};
			
			// attach node-specific style to this node
			edge.attachStyle(Styles.SPECIFIC_STYLE, new Style(style));
			
			// re-apply styles for the node to reflect the changes
			Styles.reApplyStyles(edge);
			this.graphManager.view.update();
		}
		
		/**
		 * Listener function for ADDING_EDGE event. Adds listener for MOUSE_MOVE
		 * event to enable preview of the edge between two clicks of edge 
		 * adding process.
		 * 
		 * @param evt	ControlEvent that triggered the action
		 */
		protected function onAddingEdge(evt:ControlEvent):void
		{
			if (this.object != null &&
				this.object is DisplayObjectContainer)
			{
				// add listener for the animation of preview edge
				
				this.object.addEventListener(MouseEvent.MOUSE_MOVE,
					onMouseMove);
				
				// enable preview edge
				
				(this.object as DisplayObjectContainer).addChild(
					this._previewEdge);
			}
		}
		
		/**
		 * Listener function for MOUSE_MOVE event. Renders a preview edge
		 * from the center of the source node to the current location of the
		 * mouse.
		 * 
		 * @param evt	MouseEvent that triggered the action  
		 */
		protected function onMouseMove(evt:MouseEvent):void
		{
			var g:Graphics = this._previewEdge.graphics;
			
			var startX:Number = this.graphManager.sourceNode.x;
			var startY:Number = this.graphManager.sourceNode.y;
			
			var endX:Number = this.object.mouseX;
			var endY:Number = this.object.mouseY;
			
			g.clear();
			
			// TODO also customize preview edge with global configuration?
			g.lineStyle(1, 0xff222222, 0.5);
			//g.lineStyle(lineWidth, color, lineAlpha, 
			//	pixelHinting, scaleMode, caps, joints, miterLimit);
			
			g.moveTo(startX, startY);
			g.lineTo(endX, endY);
		}
	}
}