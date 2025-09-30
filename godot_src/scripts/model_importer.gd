@tool
extends EditorScenePostImport

var _materials:Array

func _post_import(scene:Node) -> Object:
    _iterate(scene, scene)

    print('Models imported')

    return scene

func _iterate(scene:Node, node:Node) -> void:
    # Skip import of this object
    if node.has_meta('no_import'):
        node.get_parent().remove_child(node)
        node.owner = null
        return

    if node is MeshInstance3D:
        # Disable shadows
        if node.has_meta('no_shadow'):
            node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

        # For each material
        for i in node.get_surface_override_material_count():
            var old_material:Material = node.get_active_material(i)
            var is_textured: bool =\
                old_material.albedo_texture != null or\
                old_material.emission_texture != null or\
                old_material.normal_texture != null

            # Create
            var shader_name:String = node.get_meta('shader',
                'textured_standard' if is_textured else 'vertex_standard')

            # Look for an existing material
            var new_material:Material
            for material in _materials:
                # Check if the old material is identical to the new material
                if material.get_meta('shader_name', null) == shader_name and\
                    old_material.albedo_texture == material.get_shader_parameter('albedo') and\
                    old_material.emission_texture == material.get_shader_parameter('emission') and\
                    old_material.normal_texture == material.get_shader_parameter('normal_map') and\
                    old_material.metallic == material.get_shader_parameter('metallic') and\
                    old_material.roughness == material.get_shader_parameter('roughness'):
                    new_material = material
                    break

            if new_material == null:
                # Create a new material
                new_material = ShaderMaterial.new()
                new_material.shader = load('res://shaders/%s.gdshader' % shader_name)
                new_material.set_meta('shader_name', shader_name)

                # Assign textures (if used)
                new_material.set_shader_parameter('albedo', old_material.albedo_texture)
                new_material.set_shader_parameter('emission', old_material.emission_texture)
                new_material.set_shader_parameter('normal_map', old_material.normal_texture)
                new_material.set_shader_parameter('metallic', old_material.metallic)
                new_material.set_shader_parameter('roughness', old_material.roughness)

                print('Created new material for mesh "%s" ("%s")' % [node.name, shader_name])

                # Don't share the material if the object has the "instanced_material" meta tag
                if not node.has_meta('instanced_material'):
                    _materials.push_back(new_material)

            node.set_surface_override_material(i, new_material)

    # Iterate children
    for child in node.get_children():
        _iterate(scene, child)
