#include "register_types.hpp"

#include "identifier.hpp"
#include "dynamic_asset_indexer.hpp"
#include "data_cache_manager.hpp"

#include <gdextension_interface.h>
#include <godot_cpp/core/defs.hpp>
#include <godot_cpp/godot.hpp>
#include <godot_cpp/classes/engine.hpp>

using namespace godot;


void register_openchamp_types() {
	ClassDB::register_class<Identifier>();
	ClassDB::register_class<DynamicAssetIndexer>();
	ClassDB::register_class<DataCacheManager>();
}

void initialize_openchamp_module(ModuleInitializationLevel p_level) {
	if (p_level == MODULE_INITIALIZATION_LEVEL_CORE) {
		register_openchamp_types();
	}

	if (p_level != MODULE_INITIALIZATION_LEVEL_SCENE) {
		return;
	}

	//register_openchamp_types();

	Engine::get_singleton()->register_singleton("AssetIndexer", DynamicAssetIndexer::get_singleton());
	Engine::get_singleton()->register_singleton("DataCache", DataCacheManager::get_singleton());
}


void uninitialize_openchamp_module(ModuleInitializationLevel p_level) {
	if (p_level != MODULE_INITIALIZATION_LEVEL_SCENE) {
		return;
	}

	Engine::get_singleton()->unregister_singleton("AssetIndexer");
	DynamicAssetIndexer::destory_singleton();

	Engine::get_singleton()->unregister_singleton("DataCache");
	DataCacheManager::destory_singleton();
}


extern "C" {
// Initialization.
GDExtensionBool GDE_EXPORT openchamp_library_init(GDExtensionInterfaceGetProcAddress p_get_proc_address, const GDExtensionClassLibraryPtr p_library, GDExtensionInitialization *r_initialization) {
	godot::GDExtensionBinding::InitObject init_obj(p_get_proc_address, p_library, r_initialization);

	init_obj.register_initializer(initialize_openchamp_module);
	init_obj.register_terminator(uninitialize_openchamp_module);
	init_obj.set_minimum_library_initialization_level(MODULE_INITIALIZATION_LEVEL_CORE);

	return init_obj.init();
}
}
