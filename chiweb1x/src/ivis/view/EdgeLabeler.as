package ivis.view
{
	import flare.display.TextSprite;
	import flare.vis.data.DataSprite;
	
	import flash.geom.Point;
	import flash.text.TextFormat;
	
	import ivis.model.Edge;
	import ivis.model.Node;
	import ivis.model.util.Edges;
	import ivis.util.Groups;
	import ivis.util.Labels;
	
	/**
	 * Labeler for edge sprites. This labeler is designed to render edges
	 * in the REGULAR_EDGES data group by default.
	 * 
	 * @author Selcuk Onur Sumer 
	 */
	public class EdgeLabeler extends NodeLabeler
	{
		public static const SOURCE:String = "source";
		public static const TARGET:String = "target";
		public static const MIDDLE:String = "middle";
		
		public static const PERCENT_DISTANCE:String = "percent";
		public static const FIXED_DISTANCE:String = "fixed";
		
		//------------------------- CONSTRUCTOR --------------------------------
		
		/**
		 * Instantiates a labeler for edges. To enable labels also for segment
		 * edges, pass Groups.EDGES instead of Groups.REGULAR_EDGES as the group
		 * parameter. 
		 * 
		 * @param source	source property of the label text
		 * 					(default value is "data.label")
		 * @param access	target property to store edge's label
		 * 					(default value is "props.$label")
		 * @param group		the data group
		 * 					(default value is Groups.REGULAR_EDGES)
		 * @param format	optional text formatting information
		 * @param filter	function determining which edges to be labelled
		 */
		public function EdgeLabeler(source:* = Labels.DEFAULT_TEXT_SOURCE,
			access:String = Labels.DEFAULT_LABEL_ACCESS,
			group:String = Groups.REGULAR_EDGES,
			format:TextFormat = null,
			filter:* = null)
		{
			super(source, access, group, format, filter);
		}
		
		//---------------------- PROTECTED FUNCTIONS ---------------------------
		
		/** @inheritDoc */
		protected override function process(d:DataSprite):void
		{
			var label:TextSprite = null;
			
			// process only Edge instances
			// (since this labeler is not compatible with other data sprites)
			if (d is Edge)
			{
				label = this.getLabel(d, true);
			}
			
			// continue only if label can be obtained successfully
			if (label != null)
			{
				label.filters = null; // filters(d); TODO get filters
				label.alpha = d.alpha;
				label.visible = d.visible;
			
				this.updateLabelPosition(label, d);
				label.render();
			}
		}
		
		/**
		 * Finds the correct segment or the bendpoint where the label to be
		 * placed. If the given edge has no segments, then the clipping points
		 * of the edge is returned. If the edge has odd number of segments,
		 * then the clipping points of the central segment is returned. If the
		 * number of segments is even, then the both points in the array are
		 * identical to the central bendpoint.
		 * 
		 * @param d	the edge
		 * @return	an array of end points
		 */
		protected function endPoints(d:DataSprite):Array
		{
			var startPoint:Point = d.props.$startPoint;
			var endPoint:Point = d.props.$endPoint;
			var adjacentToSrc:Edge;
			var adjacentToTgt:Edge;
			
			// if edge has bendpoints, find the correct segment (or bend point)
			// to place the label
			if ((d as Edge).hasBendPoints())
			{
				// get the segment adjacent to the source node
				adjacentToSrc = Edges.segmentAdjacentToSource(d as Edge);
				
				// get the segment adjacent to the target node
				adjacentToTgt = Edges.segmentAdjacentToTarget(d as Edge);
				
				// take the segment adjacent to the source node
				if (d.props.labelPos == EdgeLabeler.SOURCE)
				{
					startPoint = adjacentToSrc.props.$startPoint;
					endPoint = adjacentToSrc.props.$endPoint;
				}
					// take the segment adjacent to the target node
				else if (d.props.labelPos == EdgeLabeler.TARGET)
				{
					startPoint = adjacentToTgt.props.$startPoint;
					endPoint = adjacentToTgt.props.$endPoint;
				}
					// default case is center 
				else
				{
					var segment:Edge;
					var bendNode:Node;
					var bendPoint:Point;
					
					// find the central segment or the central bendpoint
					if ((d as Edge).getBendNodes().length % 2 == 0)
					{
						segment = Edges.centralSegment(d as Edge);
						startPoint = segment.props.$startPoint;
						endPoint = segment.props.$endPoint;
					}
					else
					{
						bendNode = Edges.centralBendPoint(d as Edge);
						bendPoint = new Point(bendNode.x,
							bendNode.y);
						
						startPoint = bendPoint;
						endPoint = bendPoint;
					}
				}
			}
			
			var points:Array = null;
			
			if (startPoint != null &&
				endPoint != null)
			{
				points = [startPoint, endPoint]
			}
			
			return points;
		}
		
		/** @inheritDoc */
		protected override function updateLabelPosition(label:TextSprite,
			d:DataSprite):void
		{
			if (label == null)
			{
				// cannot update label position
				return;
			}
			
			var endPoints:Array = this.endPoints(d);
			
			if (endPoints != null)
			{
				var startPoint:Point = endPoints[0] as Point;
				var endPoint:Point = endPoints[1] as Point;
			}
			else
			{
				// cannot update label position
				return;
			}
			
			// label coordinates
			var x:Number;
			var y:Number;
			var distance:Number;
			
			// distance calculation type (percent or fixed)
			var distType:String = d.props.labelDistanceCalculation;
			
			// desired percentage or fixed distance of the label from the node
			// (ignored if label position is EdgeLabeler.CENTER)
			
			if (distType == EdgeLabeler.FIXED_DISTANCE)
			{
				// fixed distance; take the value as it is
				distance = d.props.labelDistanceFromNode;
			}
			else
			{
				// percent distance; divide by 100
				distance = d.props.labelDistanceFromNode / 100;
			}
			
			var dist:Number;
			
			if (d.props.labelPos == EdgeLabeler.SOURCE)
			{
				if (distType == EdgeLabeler.FIXED_DISTANCE)
				{
					// distance between clipping points of the edge
					dist = Point.distance(startPoint, endPoint);
					
					// place the label next to the source 
					// (with a fixed distance away from the clipping point)
					
					x = startPoint.x +
						(distance / dist) * (endPoint.x - startPoint.x);
					y = startPoint.y +
						(distance / dist) * (endPoint.y - startPoint.y);
					
					// (alternative distance calculation with polar angles)
					//slopeAngle = GeometryUtils.slopeAngle(startPoint, endPoint);
					//loc = Point.polar(distance, slopeAngle);
				}
				else
				{
					// place the label next to the source 
					// (with a desired percent away from the clipping point)
					
					x = startPoint.x + distance * (endPoint.x - startPoint.x);
					y = startPoint.y + distance * (endPoint.y - startPoint.y);
				}
			}
			else if (d.props.labelPos == EdgeLabeler.TARGET)
			{
				if (distType == EdgeLabeler.FIXED_DISTANCE)
				{
					// distance between clipping points of the edge
					dist = Point.distance(startPoint, endPoint);
				
					// place the label next to the target 
					// (with a fixed distance away from the clipping point)
					
					x = endPoint.x +
						(distance / dist) * (startPoint.x - endPoint.x);
					y = endPoint.y +
						(distance / dist) * (startPoint.y - endPoint.y);
				}
				else
				{
					// place the label next to the target
					// (with a desired percent away from the clipping point)				
					
					x = endPoint.x + distance * (startPoint.x - endPoint.x);
					y = endPoint.y + distance * (startPoint.y - endPoint.y);
				}
			}
			else
			{
				// place the label to the center of the edge (or the segment)
				x = (startPoint.x + endPoint.x) / 2;
				y = (startPoint.y + endPoint.y) / 2;
			}
			
			// apply offset values
			label.x = x + d.props.labelOffsetX;
			label.y = y + d.props.labelOffsetY;
		}
	}
}