package ivis.view.ui
{
	import flare.util.Shapes;
	

	/**
	 * Manager class for custom edge UIs. In order to use an implementation of
	 * an IEdgeUI interface to render custom edges, its singleton instance
	 * should be registered by invoking the registerUI function of this manager
	 * class.
	 * 
	 * LinearEdgeUI instance is registered by default.
	 * 
	 * @author Selcuk Onur Sumer
	 */
	public class EdgeUIManager
	{
		//------------------------CONSTANTS-------------------------------------
		
		// default shapes provided by chiWeb
		public static const LINE:String = Shapes.LINE;
		
		//------------------------VARIABLES-------------------------------------
		
		// shape object with the default shape registered
		private static var _uiMap:Object = {
			line: LinearEdgeUI.instance};
		
		//-----------------------CONSTRUCTOR------------------------------------
		
		public function EdgeUIManager()
		{
			throw new Error("EdgeUIManager is an abstract class.");
		}
		
		//-----------------------PUBLIC FUNCTIONS-------------------------------
		
		/**
		 * Registers the given edge UI by adding its instance to the UI map
		 * with the provided name.
		 * 
		 * @param name		name of the UI (used as a map key)
		 * @param edgeUI	edge UI instance corresponding to the given name
		 */
		public static function registerUI(name:String,
			edgeUI:IEdgeUI):void
		{
			_uiMap[name] = edgeUI;
		}
		
		/**
		 * Unregisters the given edge UI by removing corresponding instance from
		 * the UI map.
		 * 
		 * @param name		name of the UI (used as a map key)
		 */
		public static function unregisterUI(name:String):IEdgeUI
		{
			var ui:IEdgeUI = _uiMap[name];
			
			delete _uiMap[name];
			
			return ui;
		}
		
		/**
		 * Retrieves the edge UI instance corresponding to the given name.
		 * 
		 * @param name	name of the UI
		 * @return		UI instance corresponding to the given name
		 */
		public static function getUI(name:String):IEdgeUI
		{
			return _uiMap[name];
		}
	}
}