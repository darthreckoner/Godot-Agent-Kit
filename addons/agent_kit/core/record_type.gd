class_name KitRecordType
extends Resource
@export var id: StringName
@export var description: String
## Field names -> float/int/string/bool/array/dictionary; dictionaries are numeric maps.
@export var fields: Dictionary = {}
## Field -> {min, max_field, aggregate}. Games define resource/capacity rules here.
@export var limits: Dictionary = {}
## Optional array lengths; games may declare coordinates or other fixed-size data.
@export var array_lengths: Dictionary = {}
