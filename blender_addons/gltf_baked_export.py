bl_info = {
    'name': 'gLTF (Baked Vertex Color) Exporter',
    'author': 'Donitz',
    'version': (1, 0, 0),
    'blender': (4, 5, 0),
    'location': 'File > Export > gLTF (Baked Vertex Color)',
    'description': 'Export meshes with baked vertex color attributes',
    'warning': '',
    'category': 'Import-Export',
}

import bpy
import bmesh
import json
import os
import shutil

from bpy_extras.io_utils import ExportHelper

def bake_object(obj):
    # Copy the object
    obj_copy = obj.copy()
    obj_copy.data = bpy.data.meshes.new_from_object(obj)
    if obj_copy.animation_data:
        obj_copy.animation_data.action = obj_copy.animation_data.action.copy()
    bpy.context.collection.objects.link(obj_copy)

    # Ensure there are two UV maps
    if len(obj_copy.data.uv_layers) == 0:
        obj_copy.data.uv_layers.new(name='UVMap')
    elif len(obj_copy.data.uv_layers) > 1:
        for uv_layer in list(obj_copy.data.uv_layers):
            if not uv_layer.active:
                obj_copy.data.uv_layers.remove(uv_layer)
    if 'EmissionRoughness' not in obj_copy.data.uv_layers:
        obj_copy.data.uv_layers.new(name='EmissionRoughness')

    # Create a custom color attribute
    if 'AlbedoEmission' not in obj_copy.data.color_attributes:
        obj_copy.data.color_attributes.new('AlbedoEmission', 'BYTE_COLOR', 'CORNER')

    # Select the copy
    bpy.ops.object.select_all(action='DESELECT')
    bpy.context.view_layer.objects.active = obj_copy
    obj_copy.select_set(True)

    # Split copy by material
    bpy.ops.object.mode_set(mode='EDIT')
    bpy.ops.mesh.separate(type='MATERIAL')
    bpy.ops.object.mode_set(mode='OBJECT')

    for o in bpy.context.selected_objects:
        mesh = o.data

        # Get BSDF material
        mat = o.active_material
        if not mat or not mat.node_tree:
            continue
        bsdf = next((n for n in mat.node_tree.nodes if n.type == 'BSDF_PRINCIPLED'), None)
        if not bsdf:
            continue

        # Do not replace image materials
        has_image = any(n.type == 'TEX_IMAGE' for n in mat.node_tree.nodes)
        if has_image:
            continue

        # Get color, emission and roughness and alpha from material
        base_color = bsdf.inputs['Base Color'].default_value
        emission_color = bsdf.inputs['Emission Color'].default_value
        emission_strength = bsdf.inputs['Emission Strength'].default_value
        metallic = bsdf.inputs['Metallic'].default_value
        roughness = bsdf.inputs['Roughness'].default_value
        alpha = bsdf.inputs['Alpha'].default_value

        # Save color to vertices
        color_layer = mesh.color_attributes['AlbedoEmission']
        color = emission_color if emission_strength > 1e-3 else base_color
        for i in range(len(color_layer.data)):
            color_layer.data[i].color = (*color[:3], alpha)

        # Save specular, metallic, emission and roughness to UV
        custom_emission_layer = mesh.uv_layers[0]
        metallic_roughness_layer = mesh.uv_layers[1]
        for i in range(len(custom_emission_layer.data)):
            custom_emission_layer.data[i].uv = (0.0, emission_strength)
        for i in range(len(metallic_roughness_layer.data)):
            metallic_roughness_layer.data[i].uv = (metallic, roughness)

        # Clear materials
        o.data.materials.clear()

    # Re-merge split object
    bpy.ops.object.join()

    return obj_copy

def export(path):
    if bpy.context.scene.objects:
        bpy.context.view_layer.objects.active = bpy.context.scene.objects[0]
    bpy.ops.object.mode_set(mode='OBJECT')

    # Get a list of all the original meshes in the scene
    original_meshes = [o for o in bpy.context.scene.objects if o.type == 'MESH']

    # Bake objects
    baked_objects = []
    for obj in original_meshes:
        baked_objects.append(bake_object(obj))

    # Select only the baked objects
    bpy.ops.object.select_all(action='DESELECT')
    for baked in baked_objects:
        baked.select_set(True)

    # Export GLTF
    bpy.ops.export_scene.gltf(
        check_existing=False,
        use_selection=True,
        filepath=path,
        export_apply=True,
        export_bake_animation=False,
        export_force_sampling=False,
        export_tangents=True,
        export_vertex_color='NAME',
        export_vertex_color_name='AlbedoEmission'
    )

    # Delete the copied objects
    bpy.ops.object.select_all(action='DESELECT')
    for baked in baked_objects:
        baked.select_set(True)
    bpy.ops.object.delete()

class GLTFBakedExport(bpy.types.Operator, ExportHelper):
    bl_idname = 'export_scene.gltf_baked'
    bl_label = 'Export gLTF (Baked Vertex Color)'

    filename_ext = '.glb'

    def execute(self, context):
        export(self.filepath)
        return { 'FINISHED' }

def menu_func(self, context):
    self.layout.operator(GLTFBakedExport.bl_idname, text='gLTF (Baked Vertex Color)')

def register():
    bpy.utils.register_class(GLTFBakedExport)
    bpy.types.TOPBAR_MT_file_export.append(menu_func)

def unregister():
    bpy.utils.unregister_class(GLTFBakedExport)
    bpy.types.TOPBAR_MT_file_export.remove(menu_func)

if __name__ == '__main__':
    register()
