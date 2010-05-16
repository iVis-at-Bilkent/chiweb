package ivis.ui
{
	import __AS3__.vec.Vector;
	
	import flash.events.Event;
	import flash.filters.DropShadowFilter;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import gs.TweenMax;
	import gs.easing.Elastic;
	
	import ivis.model.Node;
	
	import mx.core.UIComponentCachePolicy;
	import mx.events.MoveEvent;
	import mx.events.ResizeEvent;

	/**
	 * 
	 * @author Ebrahim
	 */
	public class NodeComponent extends Component
	{
		/**
		 * 
		 * @default 
		 */
		public const DEFAULT_MARGIN: Number = 10;
		
		/**
		 * 
		 * @default 
		 */
		public static const DEFAULT_WIDTH: Number = 80;
		/**
		 * 
		 * @default 
		 */
		public static const DEFAULT_HEIGHT: Number = 60;

		/**
		 * 
		 * @default 
		 */
		private var _clusterId: uint = 0;
		
		/**
		 * 
		 * @default 
		 */
		private var _margin: Number;

		/**
		 * 
		 * @default 
		 */
		protected var _renderer: INodeRenderer;
		
		/**
		 * 
		 * @default 
		 */
		protected var _parentComponent: Object;
		
		/**
		 * 
		 * @default 
		 */
		private var _shaodw: Boolean;
		
		internal var _incidentEdges: Vector.<EdgeComponent>;
		
		/**
		 * 
		 */
		public function NodeComponent(id: String = null)
		{
			super(new Node(id));

			this.initializeComponent();			
		}
		
		//
		// getters and setters
		//
		
		/**
		 * 
		 * @return 
		 */
		public function get clusterId(): uint
		{
			return this._clusterId;
		}
		
		/**
		 * 
		 * @param cid
		 */
		public function set clusterId(cid: uint): void
		{
			this._clusterId = cid;
		}
		
		/**
		 * 
		 * @return 
		 */
		public function get margin(): Number
		{
			return this._margin;
		}
		
		/**
		 * 
		 * @param m
		 * @return 
		 */
		public function set margin(m: Number): void
		{
			this._margin = m;
			
			//this.invalidateDisplayList();
		}
		
		/**
		 * 
		 * @return 
		 */
		public function get renderer(): INodeRenderer
		{
			return this._renderer;
		}
		
		/**
		 * 
		 * @param r
		 */
		public function set renderer(r: INodeRenderer): void
		{
			this._renderer = r;
			r.node = this;
		}
		
		/**
		 * 
		 * @return 
		 */
		public function get center(): Point
		{
			return new Point(this.x + this.width / 2, this.y + this.height / 2);
		}
		
		/**
		 * 
		 * @return 
		 */
		public function get shadow(): Boolean
		{
			return this._shaodw;
		}
		
		/**
		 * 
		 * @param b
		 */
		public function set shadow(b: Boolean): void
		{
			if(this._shaodw == b)
				return;
				
			this._shaodw = b;
			
			if(this._shaodw)
				this.filters = [ new DropShadowFilter(2, 45, 0, .65, 6, 6) ];
			else
				this.filters = [];	

		}
		
		/**
		 * 
		 * @return 
		 */
		public function get parentComponent(): Object
		{
			return this._parentComponent;
		}
		
		public function set parentComponent(p: Object): void
		{
			this._parentComponent = p;
		}
		
		//
		// public methods
		//

		/**
		 * 
		 * @return 
		 */
		public function isCompound(): Boolean
		{
			return false;
		}

		public function translate(dx: Number, dy: Number): void
		{
			this.x += dx;
			this.y += dy;
		}
				
		/**
		 * 
		 * @param xmlNode
		 */
		public function animateToNewPositon(xmlNode: XML): void
		{
			var tm: TweenMax = TweenMax.to(this, 1.0, 
				{ 
					x: Number(xmlNode.bounds.@x),
				  	y: Number(xmlNode.bounds.@y),
				  	ease: gs.easing.Elastic.easeOut,
				  	//paused: true,
				  	overwrite: 2
				})
		}

		/**
		 * 
		 * @return 
		 */
		override public function clone(): Component
		{
			var result: NodeComponent = new NodeComponent;
			result.model = this.model;
			
			// TOOD: clone the renderer?
			//result.renderer = this.renderer;
			
			return result;
		}

		/**
		 * 
		 * @return 
		 */
		override public function asXML(): XML
		{
			return XML('<node id="' + this.model.id + '" ' + 
					'clusterID="' + clusterId + '">' + 
					'<bounds height="' + this.height + 
					'" width="' + this.width + 
					'" x="' + this.x + 
					'" y="' + this.y + 
					'" />' + 
					'</node>')
		}
		
		/**
		 * 
		 * @return 
		 */
		override public function get bounds(): Rectangle
		{
			return new Rectangle(this.x, this.y, this.width, this.height);
		}
		
		//
		// protected methods
		//
		
		/**
		 * 
		 * @param unscaledWidth
		 * @param unscaledHeight
		 */
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number): void
		{
			super.updateDisplayList(unscaledWidth, unscaledHeight);

			this._renderer.draw(this.graphics);
		}
		
		protected function initializeComponent(): void
		{
			this.width = DEFAULT_WIDTH;
			this.height = DEFAULT_HEIGHT;
			this.margin = DEFAULT_MARGIN;

			this.renderer = new ShapeNodeRenderer;
			this.mouseAdapter = new NodeMouseAdapter;
			this.parentComponent = null;
		
			this._incidentEdges = new Vector.<EdgeComponent>;
			
			this.cacheHeuristic = true;
			this.cachePolicy = UIComponentCachePolicy.AUTO;
			
			this.shadow = true;
			
			this.registerEventHandlers();
		}
		
		protected function registerEventHandlers(): void
		{
			this.addEventListener(MoveEvent.MOVE, this.onGeometryChanged);
			this.addEventListener(ResizeEvent.RESIZE, this.onGeometryChanged);
		}
				
		protected function onGeometryChanged(e: Event): void
		{
			if(this.parentComponent is CompoundNodeComponent) {
				this.parentComponent.invalidateBounds();
			}
			
			this._incidentEdges.forEach(function (item: EdgeComponent, i: int, v: Vector.<EdgeComponent>): void {
				item.invalidateDisplayList();
			});
		}
	}
}