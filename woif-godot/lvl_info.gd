extends Resource
class_name LevelInfo

var folder_path: String = "demo"
var full_name: String = "Track Name"
var artist_name: String = "Artist Name"
#  for sorting purposes. should be lowercase alphanumerical.
# if name is in another language tranliterate it appropriately
# (eg 考え = kangae, キージェンコア = keygencore)
var phonetic_name: String = "_"
var thumbnail: Texture2D
var preview_offset: float = 0.0
var highest_scores: Dictionary = {}
#  this is technically not necessary but it allows us to order difficulties
# without having to open their respective files
var difficulties = ["No difficulties"]
var audio_stream

static func order_name_alph(a: LevelInfo, b: LevelInfo):
	return a.phonetic_name.to_lower() < b.phonetic_name.to_lower()

static func order_artist_alph(a: LevelInfo, b: LevelInfo):
	return a.artist_name.to_lower() < b.artist_name.to_lower()
